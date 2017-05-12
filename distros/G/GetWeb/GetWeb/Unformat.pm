use HTTP::Status;

sub HTTP::Status::RC_BAD_REQUEST_CLIENT
{
    400;
}

package GetWeb::Unformat;

use GetWeb::Util;
use MailBot::UI;
use MailBot::Config;
use HTML::Parse;
use URI::Escape;
use strict;

sub refHash
{
    my $type = shift;
    my $scalar = shift;

    my %hRef = {};

    #print STDERR "scalar is $scalar\n";
    
    # parse appended links at bottom of document
    while ($scalar =~ s!^\s*\[(\S+)\]([^\[\]]+)!!)
    {
	my ($key, $action) = ($1,$2);
	$action =~ s/\\\s+//g;
	$hRef{$key} = $action;
    }
    \%hRef;
}

sub splitOffSuffix
{
    my ($type, $pBody, $tag) = @_;

    chomp($tag);
    my $qTag = quotemeta($tag);

    my ($suffix, $err);
    ($$pBody, $suffix, $err) = split(/$qTag(?!.+$qTag)/,$$pBody);
    $err and
	die "tag $tag found more than once. I can only handle one document at a time!\n";

    $suffix =~ /\n\s*\n/ and $suffix = $`;  # chop after double-newline
    #print STDERR "suffix is $suffix\n";
    $suffix =~ s/\n/ /g;
    $suffix;
}

sub processPage
{
    my $type = shift;
    my $incoming = shift;

    my $paBody = $incoming -> body;

    my $origRefLine = &GetWeb::Util::getRefTag;
    my $refLine = $origRefLine;
    chomp($refLine);
    $refLine = quotemeta($refLine);

    my $foundTag = 0;
    my $formTag = 0;
    foreach (@$paBody)
    {
	if (/\<GETWEB: FORM/)
	{
	    $formTag = 1;
	}

	if (/$refLine/)
	{
	    $foundTag = 1;
	    last;
	}
    }

    if (! $foundTag)
    {
	$formTag and
	    die "CORRUPT: You must forward the entire document to GetWeb, not just the form\n";
	return undef;
    }

    my $mainBody = join('',@$paBody);
    $mainBody =~ s/^\>\s*//gm;

    if ($mainBody =~ /Search the entire archive: ProMED-mail/)
    {
	die "The form in the FORMS help document was just an example; to use the real ProMED search form, go to http://www.healthnet.org/programs/promed.html\n";
    }

    my $refList = $type -> splitOffSuffix(\$mainBody,$origRefLine);

    my $formTag = &GetWeb::Util::getFormRefTag;
    my $form = $type -> splitOffSuffix(\$mainBody,$formTag);

    $mainBody =~ s/\n/ /g;

    my $phRef = $type -> refHash($refList);
    undef $refList;

    my $ui = MailBot::UI::current;
    my $profile = $ui -> getProfile;
    if ($profile -> getProfileVal("refuse_check"))
    {
	die "ACCESS DENIED: You cannot return the text of the original message in your e-mail to the\nGetWeb MailBot due to bandwidth limitations.  This means that returning\ndocuments with links checked is disabled.\n\nPlease use the GET command interface instead\n";
    }

    # jfjf solve problem of links within forms: [X]

    my @aRefNum = ();
    foreach (@$paBody)
    {
	# j check against orginal document
	while (s/\[(\d*)X(\d*)\]//i)
        {
	    my $refNum = $1.$2;
	    next if $refNum eq "";
	    push(@aRefNum,$refNum);
	}
    }

    # jfjf modify to get commands, rather than modify text

    my @aRequest = ();

    if (defined $form)
    {
	my $parsed = parse_html($form);
	my $formatter = new GetWeb::UnformatForm(\$mainBody);
	$formatter -> format($parsed);

	my $died = $formatter -> {myDieText};
	die $died if defined $died;

	my $paFilledForm = $formatter -> {paForm};
	defined $paFilledForm or die "CORRUPT: could not read forms";
	my $filledForm;
	foreach $filledForm (@$paFilledForm)
	{
	    next unless $filledForm -> {getweb_submit};

	    my $action = $filledForm -> attr('action');
	    my $method = uc $filledForm -> attr('method');

	    $method eq '' and $method = 'GET';
	    $method eq 'POST' or $method eq 'GET' or
		die "UNAVAILABLE: GetWeb does not support method $method in HTML forms\n";

	    my $orig = $phRef -> {orig};
	    #print "orig is $orig\n";
	    my $url = new URI::URL($action,$orig);
	    
	    $orig ne "" or defined $url -> host or
		die "CORRUPT: Could not find [orig] reference\n";

 	    my $phQuery = $filledForm -> {phQuery};
	    defined $phQuery or die "CORRUPT: no query hash\n";

	    my $urlString = $url -> abs;
	    my $queryURL = new URI::URL($urlString);
	    $queryURL -> query_form(%$phQuery);

	    #print "string is " . $queryURL . "\n";
	    #print "method is $method\n";

	    my $request;
	    if ($method eq 'GET')
	    {
		my $urlString = "$queryURL";
		$urlString = uri_escape($urlString,'+ \(\)\[\]');
		
		$request = &GetWeb::Util::safeRequest ($urlString,
						       0,
						       $method);
	    }
	    else
	    {
		my $equery = $queryURL -> equery;
		my $urlString = $url -> abs;
		$request = &GetWeb::Util::safeRequest ($urlString,
						       0,
						       $method);
		#print "adding return\n";
		#$equery .= "\n";
		#print "content is $equery.\n";

		$request -> header('Content-Length',length $equery);
		$request -> header('Content-Type',
				   'application/x-www-form-urlencoded');
		$request -> content($equery);

	    }

	    push(@aRequest,$request);
	}
	$parsed -> delete;  # avoid memory leak from circular refs
    }

    my $refNum;
    foreach $refNum (@aRefNum)
    {
	$refNum =~ s/\s+//g;
	my $action = $phRef -> {$refNum};
	defined $action or die "SYNTAX ERROR: no such link: $refNum\n";
	$action =~ /not supported/ and
	    die "$action is not supported\n";
	my $request = &GetWeb::Util::safeRequest ($action,
						  0,
						  'GET');
	defined $request or die "linked to invalid URL: $action\n";
	push(@aRequest,$request);
    }
    
    unless (@aRequest)
    {
	die "SYNTAX ERROR: You must check a link or a 'submit' button when you send a document back to GetWeb!\n\nMake sure you forwarded the whole document, including any section marked **Form section (ignore)**\n";
    }
    #$incoming -> body(\@aNewBody);

    my $cmdIter = new GetWeb::CmdIter;
    my $request;
    foreach $request (@aRequest)
    {
	my $fetcher = new GetWeb::Fetcher;
	$fetcher -> {REQUEST} = $request;

	my $cmd = new GetWeb::Cmd;
	$cmd -> {currentFetcher} = $fetcher;
	my $url = $request -> url;
	my $urlString = "$url";
	$cmd -> addCanon("<url:$urlString> #link");

	$cmdIter -> pushCmd($cmd);
    }
    
    $cmdIter;
}

1;
