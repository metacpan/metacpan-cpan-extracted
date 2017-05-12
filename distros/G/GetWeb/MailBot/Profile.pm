package MailBot::Profile;

use MailBot::Config;

use Carp;
use strict;

my @gaphGroup = ();

# jfj add database support
# jfj add table support

sub new
{
    my $type = shift;
    my $address = shift;
    chomp($address);

    my $self = {ADDRESS => $address};
    bless($self,$type);

    $self -> setGroupFromAddress($address);
    $self;
}

sub getQuota
{
    my $self = shift;
    my $multiplier = shift;

    my $address = $$self{ADDRESS};
    new MailBot::Quota($address,$multiplier);
}

# jfj add blocking capability

sub tryGroupFromID
{
    my $self = shift;
    my $id = shift;

    my $config = MailBot::Config::current;
    my $group = $config -> getIniVal('map.group',$id);
    
    # sanity check, make sure group is defined in ini-file
    if (defined $group)
    {
	my @aSection = $config -> getIni -> Sections;
	grep($_ eq "profile.$group",@aSection)
	    or die "not found in config file: profile.$group";
    }
    $group;
}

sub setGroupFromAddress
{
    my $self = shift;
    my $address = shift;

    my $group = $self -> addressToGroup($address);
    $$self{GROUP} = $group;
}

sub addressToGroup
{
    my $self = shift;
    my $address = shift;

    my $host = $address;
    $host =~ s/.+\@//;
    $host =~ s/\!.+//;

    my @aTry = ($address, $host);

    my $domain = $host;
    while ($domain =~ s/^[^.]+\.//)
    {
	push(@aTry,$domain);
    }

    my $try;
    while (@aTry)
    {
	$try = shift @aTry;
	my $group = $self -> tryGroupFromID($try);
	return $group if defined $group;
    }
    return "normal";
}

sub getProfileVal
{
    my $self = shift;
    my $param = shift;

    my $group = $$self{GROUP};

    my $config = MailBot::Config::current;

    my $val = $config -> getIniVal("profile.$group",$param);
    return $val if defined $val;
    
    $config -> getIniVal('profile',$param);
}

sub dDie
{
    my $self = shift;
    my $failedAction = shift;

    my $group = $$self{GROUP};

    die "ACCESS DENIED: members of group $group may not $failedAction\n";
}

sub allowRedirect
{
    shift -> getProfileVal('allow_redirect');
}

1;
