package GetWeb::Parser;

use GetWeb::Cmd;
use GetWeb::SURL;
use MailBot::Entity;

use Carp;
use strict;

my $gpaBody;
my $gLine;

sub sDie
{
     croak "SYNTAX ERROR: ". shift;
}

sub d
{
    &MailBot::Util::debug(@_);
}

my %ghSynonym = (
		 GET => ["\n\n"],
		 SEND => ["GET"],
		 GO => ["GET"],
		 WWW => ["GET"],
		 SEARCH => ["ALIAS"],
		 
		 RGET => ["GET","TO"],
		 RWWW => ["WWW","TO"],
		 RSEND => ["SEND","TO"],
		 RSOURCE => ["SOURCE","TO"],
		 RDEEP => ["DEEP","TO"],
		 );

my @gaOneBefore = qw( SOURCE NOMIME DEEP );
my @gaTwoBefore = qw( SPLIT TO USER PASSWORD );
my @gaSlurp = qw( ALIAS HELP );
my @gaTwoAfter = qw( FOLLOW );

my @gaAny =
    (@gaOneBefore, @gaTwoBefore, @gaSlurp, @gaTwoAfter,
    keys %ghSynonym, "\n\n");

sub getCmdIter
{
    my $type = shift;
    my $cwd = shift;
    my $paText = shift;

    $gLine = "";
    my $commandIter = new GetWeb::CmdIter;

    $gpaBody = $paText;

    # do not define these variables inside the eval, since we nest evals
    my $command;
    my $param;
    my @paramList;

    eval
    {
	my $token = $type -> gwNextKey;
	while (defined $token)
	{
	    $command = new GetWeb::Cmd $cwd;
	    my $sawSURL = 0;
	    my $empty = 1;
	    while (defined $token)
	    {
		if ($token eq "\n\n")
		{
		    $token = $type -> gwNextKey;
		    last;
		}
		
		my $upperToken = uc $token;
		if (grep($_ eq $upperToken, @gaOneBefore))
		{
		    last if $sawSURL;
		    my $method = "keyOne" . $upperToken;
		    # print STDERR "executing: " . '$command -> ' . $method;
		    #$command -> addCanon($upperToken);
		    $type -> commandMethod($command,$method,$upperToken);
		    #eval '$command -> ' . $method;
		    #$@ and die $@;
		    $empty = 0;
		    next;
		}
		if (grep($_ eq $upperToken, @gaTwoBefore))
		{
		    last if $sawSURL;
		    my $method = "keyTwo" . $upperToken;
		    $param = $type -> gwNextToken;
		    #$command -> addCanon($upperToken,$param);
		    $type -> commandMethod($command,$method,$upperToken,$param);
		    #eval '$command -> ' . "$method" . '($param)';
		    #$@ and die $@;
		    $empty = 0;
		    next;
		}
		if (grep($_ eq $upperToken, @gaTwoAfter))
		{
		    &sDie("$upperToken must go after URL")
			unless $sawSURL;
		    my $method = "keyAppTwo" . $upperToken;
		    $param = $type -> gwNextToken;
		    #$command -> addCanon($upperToken,$param);
		    $type -> commandMethod($command,$method,$upperToken,$param);
		    #eval '$command -> ' . "$method" . '($param)';
		    #$@ and die $@;
		    $empty = 0;
		    next;
		}
		if (grep($_ eq $upperToken, @gaSlurp))
		{
		    last if $sawSURL;
		    $sawSURL = 1;
		    my $method = "keySlurp" . $upperToken;

		    @paramList = ();
		    while ($token = $type -> gwNextToken)
		    {
			# jfj redo next_token into array
			my $upper = uc $token;
			my $paToken = $ghSynonym{$upper};
			if ($paToken)
			{
			    $gLine = join(' ',@$paToken,$gLine);
			    $token = $type -> gwNextToken;
			    redo;
			}
			my $upperParam = uc $token;
			last if grep($_ eq $upperParam,@gaAny);
			push(@paramList,$token);
		    }
		    #$command -> addCanon($upperToken,@paramList);
		    $type -> commandMethod($command,$method,$upperToken,@paramList);
		    #eval '$command -> ' . "$method" . '(@paramList)';
		    #$@ and die $@;
		    $sawSURL = 1;
		    $empty = 0;
		    redo;  # need to re-use last token
		}
		# must be an URL
		last if $sawSURL;
		$command -> addCanon($token);
		my $surl = new GetWeb::SURL($token);
		$command -> setSURL($surl);
		$sawSURL = 1;
		$empty = 0;
		next;
	    }
	    continue
	    {
		$token = $type -> gwNextKey;
	    }
	    if (! $empty)
	    {
		$sawSURL or &sDie("need to specify URL in command: " .
				  $command -> asString . "\n");
		$commandIter -> pushCmd($command);
	    }
	}
    };
    if ($@)
    {
	($@ =~ /^SYNTAX ERROR: (.+)/)
	    or die ($@);
	$commandIter -> pushError($@);
    }

    $commandIter;
}

sub commandMethod
{
    my ($type, $command, $methodName, $commandName, @paramList) = @_;

    $command -> addCanon($commandName,@paramList);

    my $ui = MailBot::UI::current;
    my $profile = $ui -> getProfile;

    my $profileKey = lc "deny.$commandName";
    my $deny = $profile -> getProfileVal($profileKey);
    $deny ne "" and
	die "ACCESS DENIED: '$commandName' command $deny\n";

    my $ret = eval '$command -> ' . "$methodName" . '(@paramList)';
    $@ and die $@;

    $ret;
}

sub gwNextLine
{
    my $self = shift;

    my $paBody = $gpaBody;

    my $line;
    do {$line = shift @$paBody} while
	$line =~ /^\#/;

    while ($line =~ s/\\$//)
    {
	chomp($line);
	$line .= shift @$paBody;
    }
    $gLine = $line;
}

sub gwCurrentLine
{
    $gLine;
}

sub gwNextKey
{
    my $type = shift;
    my $cmd = shift;

    my $token = $type -> gwNextToken;
    return undef unless defined $token;

    my $upperToken = uc $token;

    # check if it is synonym, like "RSEND" which is "GET TO"
    my $paToken = $ghSynonym{$upperToken};
    if ($paToken)
    {
	$gLine = join(' ',@$paToken,$gLine);
	return $type -> gwNextKey($cmd);
    }

    if ($token =~ /^\d+$/)
    {
	$gLine = "GET : FOLLOW $token $gLine";
	return $type -> gwNextKey($cmd);
    }
    $cmd -> addCanon($token) if defined $cmd;
    $token;
}

sub gwNextToken
{
    my $self = shift;
    my $cmd = shift;

    my $ret = $self -> gwNextTokenSilent;
    $cmd -> addCanon($ret) if defined $cmd;
    $ret;
}

sub gwNextTokenSilent
{
    my $self = shift;

    my $paBody = $gpaBody;

    my $line = $self -> gwCurrentLine();
    if (! defined $line)
    {
	 $line = $self -> gwNextLine();
    }

    if ($line =~ s/^(\n\n)//)
    {
	$gLine = $line;
	return $1;
    }

    while (defined $line)
    {
	$line =~ s/^\s+//;

	if ($line =~ s/^\s*\<(url:)?//i)
	{
	    my $buffer = "";

	    # parse enclosed as one token, even if on multiple lines
	    while ($line !~ /[^>]*\>/)
	    {
		$buffer .= $line;
		$line = $self -> gwNextLine();
		&sDie ("unbalanced angle brackets: '<' has no '>'\n") unless defined $line;
	    }
	    $line =~ s/([^>]*)\>//;
	    $buffer .= $1;
	    $buffer =~ s/\s+//g;
	    $buffer =~ s/\n//g;
	    $gLine = $line;
	    &d("buffer is $buffer");
	    return $buffer;
	}

	if ($line =~ s/^(\S+)//)
	{
	    $gLine = $line;
	    return $1;
	}
	$line = $self -> gwNextLine();
	if ($line !~ /\S/)
	{
	    $self -> gwNextLine();
	    return "\n\n";
	}
    }
    undef;
}

1;
