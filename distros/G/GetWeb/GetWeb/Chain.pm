package GetWeb::Chain;

use URI::URL;
use GetWeb::SURL;
use strict;

sub d
{
    &MailBot::Util::debug(@_);
}

sub new
{
    my $type = shift;
    my $cwd = shift;

    my $self = {
	CHAIN => [],
	# SURL => new GetWeb::SURL(":"),
        CWD => $cwd
	};

    bless($self,$type);
}

# jfj move HELP into Chain.pm module
sub getFollowList
{
    shift -> {CHAIN};
}

sub follow
{
    my $self = shift;
    my $token = shift;
    
    push(@{$$self{CHAIN}},$token);
}

sub getURL
{
    my $self = shift;
    my $ua = shift;

    my $chain = $$self{CHAIN};

    # jfj put in stingy-quota option

    my $cwd = $$self{CWD};

    # j only look up a given URL once per inbound message

    my $surl = $$self{SURL};
    my $urlString = $surl -> getURLString;
    $urlString eq "" and die "urlString is null";

    my $url;
    if ($urlString eq ':')
    {
	$url = new URI::URL($cwd);
	defined $url or die "could not read legal URL from subject line\n";
    }
    else
    {
	$url = new URI::URL($urlString);
	#$url = new URI::URL($urlString, $cwd);
	if ($url -> abs !~ /^\w+:/)
	{
	    $url = new URI::URL("http://".$urlString);
	}
	defined $url or die "not a legal URL: $urlString\n";
    }
    $url -> abs;
}

sub addParam
{
    shift -> {SURL} -> addParam(@_);
}

sub setSURL
{
    my $self = shift;
    my $surl = shift;

    $$self{SURL} = $surl;

}

1;
