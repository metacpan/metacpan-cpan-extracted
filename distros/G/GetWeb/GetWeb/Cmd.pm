package GetWeb::Cmd;

use HTML::FormatText;
use HTML::Parse;

use MailBot::Util;
use MailBot::Envelope;
use GetWeb::Util;
use GetWeb::Encoder;
use GetWeb::Chain;
use GetWeb::SURL;
use GetWeb::Fetcher;

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

# my %ghSynonym = (
# 		 GET => ["\n\n"],
# 		 SEND => ["GET"],
# 		 WWW => ["GET"],
# 		 SEARCH => ["ALIAS"],
		 
# 		 RGET => ["GET,TO"],
# 		 RWWW => ["WWW,TO"],
# 		 RSEND => ["SEND,TO"],
# 		 RSOURCE => ["SOURCE,TO"],
# 		 RDEEP => ["DEEP,TO"],
# 		 );

# my @gaKeyword = ( qw( SOURCE SPLIT TO ALIAS FOLLOW NOMIME HELP ), "\n\n"
# 		   );

# jfjf add ENCODING (BASE64, UUE, QP, LATIN) command modifier
# jfjf handle accents better
# jfj make aliases configurable
# jfj configure new search-engines on the fly

my %ghAlias = (
	       # HELP =>
	       # ['file://help.html'],
	       APS97 =>
	       ['http://www.uth.tmc.edu/cgi-bin/apstracts/searchaps.pl',
		'indexfile=/usr/local/www/apstracts/1997/aps1997.swish&searchtags=&maxresults=100&submit=Search&keywords='
		],
	       APS96 =>
	       ['http://www.uth.tmc.edu/cgi-bin/apstracts/searchaps.pl',
		'indexfile=/usr/local/www/apstracts/1996/aps1996.swish&searchtags=&maxresults=100&submit=Search&keywords='
		],
	       APS95 =>
	       ['http://www.uth.tmc.edu/cgi-bin/apstracts/searchaps.pl',
		'indexfile=/usr/local/www/apstracts/1995/aps95.swish&searchtags=&maxresults=100&submit=Search&keywords='
		],
	       ALTAVISTA =>
	       ['http://altavista.digital.com/cgi-bin/query',
		'pg=q&what=web&fmt=.&q='],
	       PROMED =>
	       ['http://www.healthnet.org/cgi-bin/webglimpse/usr/www/htdocs/.promed',
	        'errors=0&age=&maxlines=30&query=',
	        { maxfiles => [ qw( 50 10 30 100 1000 ) ] } ]
	       ,
	       YAHOO =>
	       ['http://search.yahoo.com/bin/search',
		'd=y&g=0&s=a&w=s&n=25&p='],
	       GARBAGE_ENGINE =>
	       ['file://test/not_there',
	        'errors=0&age=&maxfiles=50&query=',
	        { maxlines => [ qw( 30 10 50 500 ) ],
	          is_ok => [ qw( yes no ) ],
	          all_right => [ qw( false true ) ] }
		]
	       ,
	       INFOSEEK =>
	       ['http://guide-p.infoseek.com//Titles',
		'sv=IS&lk=lcd&qt=',
		{ col => [ qw( WW NN CT EM NW FQ ) ] } ]
	       );

# jfj implement LINE, SIZE

sub new
{
    my $type = shift;
    my $cwd = shift;

    # my $state = new GetWeb::CmdState();

    my $self = {
	ENCODER => new GetWeb::Encoder(),
	# STATE => $state,
	CANON => "GET",
	CHAIN => new GetWeb::Chain($cwd),
	ENVELOPE => new MailBot::Envelope(),
	MIME => 1,
	CWD => $cwd
    };

    # allowed states:  CMD TO ALIAS HELP SURL FOLLOW CHAIN
    
    bless($self,$type);
}

sub getEncoder
{
    shift -> {ENCODER};
}

sub getEnvelope
{
    shift -> {ENVELOPE};
}

sub keyTwoHELP
{
    my $self = shift;
    my $param = shift;

    my $upperParam = uc $param;
    push(@{$$self{HELP_LIST}},$upperParam);
}

sub keySlurpALIAS
{
    my $self = shift;
    my $alias = shift;
   
    my $upperAlias = uc $alias;

    my $paAlias = $ghAlias{$upperAlias};
    unless (defined $paAlias)
    {
	my $legal = join(', ',keys %ghAlias);
	$legal =~ s/GARBAGE_ENGINE(, )?//;
	&sDie("not a legal search alias: $alias; legal aliases are: $legal\n");
    }
    
    my $retVal = $self -> appendAlias($paAlias);
    while (@_)
    {
	my $param = shift;
	$self -> appendParam($param);
    }
}

sub keyTwoTO
{
    my $self = shift;
    my $param = shift;

    my $envelope = $self -> {ENVELOPE};
    $envelope -> setRecipientList($param);

    my $ui = MailBot::UI::current;
    my $from = $ui -> getFrom;
    $envelope -> setFrom($from);
}

sub keyTwoUSER
{
    my $self = shift;
    $self -> {AUTH_USER} = shift;
}

sub keyTwoPASSWORD
{
    my $self = shift;
    $self -> {AUTH_PASSWORD} = shift;
}

sub keyTwoSPLIT
{
    my $self = shift;
    my $param = shift;

    $$self{ENVELOPE} -> setSplitSize($param);
}

sub keyAppTwoFOLLOW
{
    my $self = shift;
    my $param = shift;

    $self -> follow($param);
}

sub appendAlias
{
    my $self = shift;
    my $paAlias = shift;

    my $surl = new GetWeb::SURL @$paAlias;

    $self -> setSURL($surl);
}

sub setSURL
{
    my $self = shift;
    my $surl = shift;

    $$self{CHAIN} -> setSURL($surl);
}

sub appendParam
{
    my $self = shift;
    my $param = shift;

    my $chain = $$self{CHAIN};
    $chain -> addParam($param);

    0;
}

sub addCanon
{
    my $self = shift;
    my $add = join(' ',@_);

    $self -> {CANON} .= (" " . $add);
}

sub keyOneSOURCE
{
    my $self = shift;
    $$self{ENCODER} -> preferSource;
}

sub keyOneNOMIME
{
    shift -> {ENVELOPE} -> setMIME(0);
}

sub keySlurpHELP
{
    my $self = shift;

    $$self{HELP_LIST} = [ @_ ];
}

sub keyNEW_PAR
{
    return 1 unless shift -> isEmpty();
    0;
}

sub keyOneDEEP
{
    my $self = shift;
    $$self{DEEP} = 1;
}

# jfj change from 'newFetcher' to 'currentFetcher'
sub newFetcher
{
    my $self = shift;
    my $ua = shift;

    my $fetcher = $self -> {currentFetcher};

    if (defined $fetcher)
    {
	$fetcher -> {UA} = $ua;
	$fetcher -> authorizeUser($self -> {AUTH_USER});
	$fetcher -> authorizePassword($self -> {AUTH_PASSWORD});
    }
    else
    {
	$fetcher = new GetWeb::Fetcher($ua);
	$self -> {currentFetcher} = $fetcher;

	$fetcher -> authorizeUser($self -> {AUTH_USER});
	$fetcher -> authorizePassword($self -> {AUTH_PASSWORD});
	
	# jfj hierarchical help
	
	my $chain = $$self{CHAIN};
	
	my $state = $$self{STATE};
	my $urlString;
	my $paHelp = $$self{HELP_LIST};
	if (defined $paHelp)
	{
	    my $ui = MailBot::UI::current;
	    my $file = uc join(' ',@$paHelp);
	    $file =~ /\s/ and &sDie("too many parameters to HELP: $file");
	    $file eq "" and
		$file = $ui -> getServiceParam('help');
	    
	    my $config = MailBot::Config::current;
	    my $pubDir = $config -> getPubDir();
	    my $helpDir = "help";
	    my $helpPath = "$pubDir/$helpDir";
	    if (! -e "$helpPath/$file.html")
	    {
		my @aLegal = <$helpPath/*.html>;
		grep(s/\.html$//,@aLegal);
		grep(s/.+\///,@aLegal);
		my $helpList = "HELP, HELP " . join(', HELP ',@aLegal);
		die "illegal help command: HELP $file.\n  Legal help commands are: $helpList\n";
	    };
	    
	    $urlString = "file://help/$file.html";
	}
	else
	{
	    $urlString = $chain -> getURL($ua);
	}
	
	$$self{ENCODER} -> base($urlString);
	$fetcher -> base($urlString);
	
	&d("full url is $urlString");
	
	my $paFollow = $chain -> getFollowList();
	my $follow;
	foreach $follow (@$paFollow)
	{
	    $fetcher -> follow($follow);
	}
    }

    $fetcher;
}

sub discoveredReq
{
    my $self = shift;

    # jfj add INLINE command

    return undef unless $self -> {DEEP};

    my $paLink = $self -> {currentFetcher} -> getLinks(['a']);

    my $cmdIter = new GetWeb::CmdIter;
    my $link;
    foreach $link (@$paLink)
    {
	# jfj more robust cloning method for commands

	my $cmdText = $self -> asString;
	my $newIter = GetWeb::Parser -> getCmdIter("",[$cmdText]);

	my $cmd = $newIter -> next;
	defined $cmd or die "could not clone $cmdText";
	$newIter -> isEmpty or die "command $cmdText cloned into two commands: first is ", $cmd -> asString, "second is ", $newIter -> next -> asString, "\n";
	
	delete $cmd -> {DEEP};
	$cmd -> setSURL(new GetWeb::SURL($link));
	$cmd -> addCanon("#deep");
	$cmdIter -> pushCmd($cmd);
    }
    $cmdIter;
}

sub follow
{
    my $self = shift;
    my $followToken = shift;
    
    $$self{CHAIN} -> follow($followToken);
}

sub asString
{
    shift -> {CANON};
}

1;
