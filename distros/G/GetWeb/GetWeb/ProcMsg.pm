package GetWeb::ProcMsg;

use MailBot::Entity;
use MailBot::Sendable;
use MailBot::MailBot;
use GetWeb::CmdIter;
use GetWeb::Parser;
use GetWeb::UnformatForm;
use GetWeb::Util;
use GetWeb::Unformat;
use MailBot::Util;
#use LWP::Debug qw(+);

$MailBot::Sendable::gBase64Preamble = "For help decoding this encoded binary file,\n send a message with the body:\n\nHELP MIME";

use MIME::Latin1 qw(latin1_to_ascii);
use LWP::UserAgent;
use Carp;
use strict;

sub sDie
{
     croak "SYNTAX ERROR: ". shift;
}

sub d
{
    &MailBot::Util::debug(@_);
}

# jfj support client-side image-maps
# jf let 'help' recognize keywords like 'get'
# jfj pass taint-check
# jfj set max binary-file size different
# jfj check incoming envelope for 'from <>'
# j send as plain-text if OK to send as plain-text
# jf send headings with -----'s and not ====='s

my $gEncoder;

sub new
{
    my $type = shift;
    my $bot = shift;
    my $incoming = shift;

    my $self = {};
    $$self{BOT} = $bot;
    bless($self,$type);

    eval {
	my $subject = $incoming -> head -> get("Subject");
	
	my ($cwd) = ($subject =~ /\<URL:(\S+)\>/);
	# &d("cwd is $cwd");
	$$self{CWD} = $cwd;
	
	# try parsing as a returned web-page
	
	#my $commandIter = $self -> gwParseAsPage($incoming);
	my $commandIter = GetWeb::Unformat -> processPage($incoming);
	
	if (! defined $commandIter)
	{
	    # try parsing as list of commands
	    $commandIter = $self -> gwParseAsCommands($incoming);
	}
	
	$commandIter -> isEmpty and
	    &sDie("no commands specified in message body\n");
	
	$self -> gwProcessCommandList($commandIter);
    };

    if ($@)
    {
	($@ =~ /^SYNTAX ERROR: (.+)/)
	    or die ($@);
	my $error = $1;
	
	$self -> gwSyntaxError($error);
    }
    
    $self;
}

sub gwProcessCommandList
{
    my $self = shift;
    my $commandIter = shift;

    my $ua = new LWP::UserAgent;
    $ua -> agent("GetWeb/0.1 " . $ua -> agent);

    my $command;
    while ($command = $commandIter -> next)
    {
	$self -> {BOT} -> log("cmd: ", $command -> asString());
	
	my $fetcher = $command -> newFetcher($ua);
	
	# jfj set 'unavailable' envelope through "command" interface
	
	my $response = $fetcher -> fetch();
	
	my $paNote = $fetcher -> getNoteRef;
	my $ui = MailBot::UI::current;
	$ui -> note(@$paNote);
	
	my ($finalURL, $finalHost, $finalScheme);
	eval {$finalURL = $response -> request -> url;
	      my $url = url $finalURL;
	      $finalScheme = $finalURL -> scheme;
	      my $host = $finalURL -> host;
	      $finalHost = "$finalScheme://$host";
	  };
	
	my $paResource = [$finalURL,$finalScheme,$finalHost];
	
	my $died = $response -> header('X-Died');
	
	my $encoder = $command -> getEncoder();
	
	my $result;
	if (! $response -> is_success)
	{
	    $self -> {BOT} -> setEnvelopeByCondition("UNAVAILABLE");

	    my $text = $response -> error_as_HTML;
	    if ($response -> is_redirect)
	    {
		# unredirectable POST command
		$text .= " Cannot automatically redirect POST requests (see RFC 1945). Manually redirect to: " . $response -> header('Location');
		$text .= $response -> content; # hope it is HTML
	    }

	    if ($text =~ /unauthorized/i)
	    {
		$text .= "<p>You might need to enter a username and password; for more info, send a document to getweb with the body:<p>HELP AUTH";
	    }

	    # enhance some unhelpful ftp libwww error messages
	    if ($text =~ /Data Connection: /)
	    {
		$text .= "<p>This means the data transfer failed because remote ftp server was down.\n"; 
	    }

	    if ($text =~ /\"message\" without a package/)
	    {
		$text .= "<p>This means the data transfer failed because remote ftp host could not be found.\n";
	    }

	    $text =~ s/\(in cleanup\) Not a GLOB reference at \S+ line \d+, \S+ chunk \d+\.//g;

	    $encoder -> encode($text,
			       "text/html");
	    $encoder -> done();
	    my $pText = $encoder -> getTextRef;
	    my $data = "Could not fetch $finalURL\n\n" . $$pText .
		"\n\n...while executing the following command:\n\n" .
		    $command -> asString . "\n";
	    
	    my $entity = build MailBot::Entity (
						Data => $data
						);
	    $entity -> send($paResource);
	}
	else
	{
	    my $title = $response -> title;
	    $title = latin1_to_ascii($title);	    

	    my $subject = "<URL:" .
		$finalURL . "> " . $title;
	    
	    my $envelope = $command -> getEnvelope();
	    $envelope -> setSubject($subject);
	    
	    my $baseURL = eval { $response -> base } || $finalURL;
	    
	    $encoder -> encode($response -> content,
			       $response -> content_type,
			       $baseURL);
	    
	    my $fileName = $finalURL;
	    $fileName =~ s|^.*/||;
	    $fileName =~ s|\?.*||;
	    
	    my $pText = $encoder -> getTextRef;
	    my $type = $encoder -> getContentType;
	    
	    &MailBot::Entity::setEnvelope($envelope);
	    
	    my $entity;
	    if ($type !~ m!^text/!)
	    {
		$entity = build MailBot::Entity (Type => "multipart/mixed"
						 );
		attach $entity (Data => $$pText,
				Type => $type,
				Filename => $fileName);
	    }
	    else
	    {
		$entity = build MailBot::Entity (Data => $$pText,
						 Type => $type,
						 Filename => $fileName);
	    }
	    $entity -> send($paResource);
	}

	# see if we found other links to follow
	my $follow = $command -> discoveredReq();
	$commandIter -> pushIter($follow) if defined $follow;
    }
}

# jfj implement full escapes: "", \", \\

sub gwParseAsCommands
{
    my $self = shift;
    my $message = shift;

    &MailBot::Util::setBeginPattern($message,'(?i)^\s*begin\s*\n');

    &MailBot::Util::setEndPattern($message,'(?i)^\s*end\s*\n');
    &MailBot::Util::setEndPattern($message,'(?i)^\s*regards,\s*\n');
    &MailBot::Util::setEndPattern($message,'(?i)^\s*cheers,\s*\n');
    &MailBot::Util::setEndPattern($message,'(?i)^--- Pegasus');
    #&MailBot::Util::setEndPattern($message,'(?i)^---');
    &MailBot::Util::setEndPattern($message,'(?i)^\s*_____+\s*$');
    &MailBot::Util::setEndPattern($message,'(?i)^\s*=====+\s*$');
    &MailBot::Util::setEndPattern($message,'(?i)^\s*-----+\s*$');
    &MailBot::Util::setEndPattern($message,'(?i)^\s*--\s*\n');
    &MailBot::Util::setEndPattern($message,'(?i)^\*\*\*\*\*\*');

    # jf set NOMIME if you see X-Ftn-Origin

    my $cwd = $$self{CWD};

    GetWeb::Parser -> getCmdIter($cwd,$message -> body);
}

# jf indicate where arguments stopped
# j guess what the error was

# jfj use HTML for print exceptions

sub gwSyntaxError
{
    my $self = shift;
    my $error = shift;

    my $data = <<"EOB";
A syntax error occurred:

   $error

Some or all commands were not executed.

Tips:

* Put commands in the body of the message, not the Subject line.

* Make sure your signature begins with '--'

Still having trouble?

* Try surrounding your body with 'begin' and 'end'

* Place a blank line between each command

* If command takes up two lines, place a '\\' after the first line

For proper usage, send a message containing these three lines:

begin

HELP

end
EOB

    $data .= join('',$self -> {BOT} -> appendOriginalRequest);

    $self -> {BOT} -> setEnvelopeByCondition("SYNTAX ERROR");
    my $entity = build MailBot::Entity (
					Data => $data
					);
    $entity -> send;
}


1;
