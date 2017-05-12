### 06-time.t ##############################
# This file tests the process dealing with timeouts

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;
use Config;


# use Test::More tests => 2;
use Test::More
		(qx(which sbatch))
		? (tests => 2)
		: (skip_all => "SLURM not available on this system");
use Test::Exception;

use HPCI;

die "No sigs?" unless $Config{sig_name} && $Config{sig_num};

my %sig_num;
my @sig_name;

@sig_num{split ' ', $Config{sig_name}} = split ' ', $Config{sig_num};
while (my($k,$v) = each %sig_num) {
	$sig_name[$v] ||= $k;
}

my $cluster = 'SLURM';

use FindBin;
$ENV{PATH} = "$FindBin::Bin/../bin:$ENV{PATH}";

my $workdir = "scratch/TEST.TIME.REMOVE.ME";
if ( -e $workdir ) {
	die "file exists where work directory was going to be used ($workdir)"
	  if -f _;
	system("rm -rf $workdir") if -d _;
	die "cannot remove old work directory $workdir" if -e $workdir;
}

mkdir $workdir or die "cannot create directory $workdir: $!";

open my $fd, '>', "$workdir/script" or die "cannot open $workdir/script to write: $!";

print $fd <<'EOF';

my $exp = 120;
print STDERR "about to sleep: $exp\n";
my $stime = time;

$SIG{USR1} = sub {
	my $sig = shift;
	print STDERR "Caught signal SIG$sig\n";
	};

sleep($exp);
my $etime = time;
my $dur = $etime - $stime;
print STDERR "finished sleep after $dur seconds\n";
if ($dur < $exp) {
	my $rem = $exp - $dur;
	print STDERR "resuming sleep: $rem\n";
	sleep($rem);
	}
print STDERR "finished entire duration, exiting with status 0\n";
exit(0);

EOF
close $fd or die "error writing $workdir/script: $!";

for my $outpair ( (
		[ pass => ZERO => [ h_time => 1000 ] ],
		[ fail => HUP => [ h_time => 1 ] ],
	) ) {

	my ( $type, $sig, $list ) = @$outpair;

	subtest "Test $type timeouts" => sub {
		plan tests => 8;

		my $group = HPCI->group(
			cluster  => $cluster,
			base_dir => 'scratch',
			name     => "T_Time_$type"
		);

		ok($group, " ... group created.");

		my $stagename = "time1_$type";
		my $stage = $group->stage(
			name => $stagename,
			resources_required => { @$list },
			command => "exec perl $workdir/script",
		);

		ok($stage, " ... stage created.");

		my $result = $group->execute();
		is( ref($result), 'HASH', ' ... result must be a hash' );
		is_deeply( [ keys %$result ], [ $stagename ], "... ... with one stage ($stagename)" );

		my $statlist = $result->{$stagename};
		is( ref($statlist), 'ARRAY', '... ... stats must be an array' );
		is( scalar(@$statlist), 1, '... ... with 1 element' );

		my $stats = $statlist->[0];
		is( ref($stats), 'HASH', '... ... a hash' );
		if ($sig eq 'ZERO') {
			is( $stats->{exit_status}, 0, "... ... with exit status zero" );
		}
		else {
			is( $stats->{killed}, $sig, "... ... with status signal $sig" );
		}
	};
}

1;
