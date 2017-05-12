package GetWeb::Fetcher;

use MailBot::Config;

use MIME::Base64 qw(encode_base64);

use HTML::FormatText;
use HTML::Parse;
use GetWeb::Util;

use LWP::Protocol;
use URI::URL;
use HTML::LinkExtor;
use strict;

&URI::URL::implementor('file','GetWeb::File');

my $pUserAgentCallback = sub {
    my ($data,$response) = @_;

     if (! $$response{"GETWEB_CHECKED_SIZE"}++)
     {
 	my $config = MailBot::Config::current;
 	my $maxLength = $config -> getMaxSize;
    
 	# may create an 'X-Died' header
 	if ($response -> content_length >= $maxLength)
	{
	    my $msg = "file size exceeded $maxLength bytes";
	    $response -> message($msg);
	    $response -> code(500);
 	    die "$msg\n";
	}

     }
    $response -> add_content($data);
};

sub new
{
    my $type = shift;
    my $ua = shift;

    my $self = {UA => $ua,
	        REDIRECT_LIST => []};
    bless($self,$type);

    $self;
}

sub base
{
    my $self = shift;
    my $urlString = shift;
    my $cwd = shift;

    $$self{URL} = $urlString;
    #$$self{REQUEST} = GetWeb::Util::safeRequest($urlString, $cwd);
    $$self{REQUEST} = GetWeb::Util::safeRequest($urlString, " ");
    undef;
}

sub authorizeUser
{
    my ($self, $user) = @_;
    $self -> {USER} = $user;
}

sub authorizePassword
{
    my ($self, $password) = @_;
    $self -> {PASSWORD} = $password;
}

sub setAuthHead
{
    my ($self, $request) = @_;
    
    my $user = $self -> {USER};
    my $password = $self -> {PASSWORD};

    (defined $user or defined $password) or return;

    (defined $user and defined $password) or
	die "UNAVAILABLE: must specify both username and password\n";

    # next 3 lines taken from LWP::UserAgent::request

    my $uidpwd = "$user:$password";

    my $scheme = 'Basic';
    my $header = "$scheme " . encode_base64($uidpwd, '');
    $request->header('Authorization' => $header);
}

# jfj also follow text substrings
# jfj extract links more elegantly

sub follow
{
    my $self = shift;
    my $follow = shift;

    my $paRedirect = $$self{REDIRECT_LIST};

    $follow =~ /^\d+$/
	or die "SYNTAX ERROR: $follow must be a link number";

    my $req = $$self{REQUEST};
    
    $self -> setAuthHead($req);
    my $response = $$self{UA} -> request($req,$pUserAgentCallback);

    push(@$paRedirect,"following link $follow");

    if (! $response -> is_success)
    {
	$$self{RESPONSE} = $response;
	return undef;
    }

    my $baseURL = eval {$response -> base} || $$self{URL};

    my $encoder = new GetWeb::Encoder();
    $encoder -> encode($response -> content, $response -> content_type,
		       $baseURL);

    eval
    {
	$$self{URL} = $response -> base;
    };

    my $pText = $encoder -> getTextRef();

    if ($$pText =~ /^\[$follow\] (\S+:(\\\n|.)+)/m)
    {
	my $urlString = $1;
	$urlString =~ s/\\\n//g;
	$$self{URL} = $urlString;
	$$self{REQUEST} = GetWeb::Util::safeRequest($urlString);
	
	return $response;
    }

    push(@$paRedirect,"could not follow link $follow, sorry");
    die "UNAVAILABLE: could not follow link $follow, no such reference";
    # jfj return a new category of error condition for not following links
    return undef;
}

sub getNoteRef
{
    shift->{REDIRECT_LIST};
}

sub getLinks
{
    my $self = shift;
    my $paLinkType = shift;  # 'a' or 'img'

    my $response = $self -> {RESPONSE};
    return [] unless defined $response;

    my $content = $response -> content;

    my $extor = new HTML::LinkExtor;
    $extor -> parse($content);
    my @links = $extor -> links;

    my $base = $self -> {URL};
    $base -> frag(undef);

    my %hHREF = ();
    my $link;
    foreach $link (@links)
    {
	my $linkType = shift @$link;
	next unless grep($linkType eq $_,@$paLinkType);
	my %attr = @$link;

	my $HREF = $attr{href};
	next unless defined $HREF;

	my $url = new URI::URL($HREF,$base);
	$url -> frag(undef);  # ignore fragments

	my $urlString = $url -> abs;

	# URI::URL::eq is flaky, so also do strcmp:
	next if $url -> eq($base);
	next if $base -> abs eq $urlString;

	my $scheme = $url -> scheme;
	next if grep($scheme eq $_, (qw(mailto telnet news)));

	# jf avoid duplicates like www.foo.com and WWW.FOO.COM
	$hHREF{$urlString} = 1;
    }

    my @aHREF = keys %hHREF;

    \@aHREF;
}

sub fetch
{
    my $self = shift;

    my $response = $$self{RESPONSE};
    return $response if defined $response;

    my $req = $$self{REQUEST};

    $self -> setAuthHead($req);

    #die "about to send request\n";
    $response = $$self{UA} -> request($req,$pUserAgentCallback);

    $$self{RESPONSE} = $response;

    #$self -> getLinks;

    $response;
}

1;
