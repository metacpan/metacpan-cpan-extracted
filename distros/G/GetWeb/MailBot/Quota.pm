package MailBot::Quota;

use POSIX;
use AnyDBM_File;

use MailBot::Util;
use MailBot::Config;

use strict;

my $QUOTA_PERIOD = 7;
my $QUOTA_QUANTUM = 60 * 60 * 24;

my %ghProfile = (
    other => 14,
    healthnet => 56,
    staff => 140
		 );
	
sub d
{
    &MailBot::Util::debug(@_);
}

sub new
{
    my $type = shift;
    my $user = shift;
    my $multiplier = shift;

    chomp($user);

    my $self = {USER => $user,
	        MULTIPLIER => $multiplier
		};
    bless($self,$type);
}

# jfj consider allowing larger files from software archives

sub bill
{
    my $self = shift;
    my ($quantity, $billType) = @_;

    $quantity *= $$self{MULTIPLIER};

    my $ui = &MailBot::UI::current;
    my $profile = $ui -> getProfile;
    my $profileMultiplier =
	$profile -> getProfileVal("multiplier.quota.$billType");
    $quantity *= $profileMultiplier if defined $profileMultiplier;

    my $user = $$self{USER};

    my $config = MailBot::Config::current;
    $config -> log("charging $user for $quantity $billType counters");

    return if $quantity eq 0;

    my $quotaDir = $config -> getQuotaDir();

    my $quotaFile = "$quotaDir/quota";
    my %hQuota;

# jfj get lock during entire set of database operations

    no strict 'subs';
    tie %hQuota, AnyDBM_File, $quotaFile, O_CREAT|O_RDWR, 0640
	or die "tie to quota database $quotaFile failed: $!";
    use strict 'subs';

    my $id = $user . "." . $billType . ".";


    # synch with time
    my $then = $hQuota{$id."then"};
    if (! defined $then)
    {
	$then = time();
    }
    else
    {
	my $elapsed = time() - $then;
	my $qElapsed;
	{
	    use integer;
	    $qElapsed = $elapsed / $QUOTA_QUANTUM;
	}
	if ($qElapsed > 0)
	{
	    &d("aging quota by $qElapsed");
	    $then += $qElapsed * $QUOTA_QUANTUM;
	    my $slot;
	    foreach $slot (reverse (0..$QUOTA_PERIOD-1))
	    {
		my $newVal = $hQuota{$id.($slot-$qElapsed)};
		if (defined $newVal)
		{
		    &d("setting slot $slot to $newVal");
		    $hQuota{$id.$slot} = $newVal;
		}
		else
		{
		    delete $hQuota{$id.$slot};
		}
	    }
	}
    }
    &d("setting time to $then");
    $hQuota{$id."then"} = $then;

    my $allowed = $profile -> getProfileVal("quota.$billType");
    if ($allowed =~ /(.+)\*(.+)/)
    {
	$allowed = $profile -> getProfileVal("quota.$1") * $2;
    }

    my $total;
    my $slot;
    foreach $slot (0..$QUOTA_PERIOD-1)
    {
	$total += $hQuota{$id.$slot};
    }
    &d("had used quota of $total before request");

    #die "already over quota of $allowed" if $total > $allowed;
    
    if ($total + $quantity > $allowed)
    {
	die "QUOTA: $billType quota is $allowed for $user, already at $total, refused to allow $quantity more.\n";
    }
    $hQuota{$id."0"} += $quantity;
    untie %hQuota or die "untie of quota database failed";
}

1;
