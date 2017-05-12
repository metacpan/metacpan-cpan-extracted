### 04-memory.t #############################################################################
# This file tests the process retrying to get sufficient memory allocation

### Includes ######################################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::Exception;

use HPCI;

# use Test::More tests => 6;
use Test::More
		(qx(which srun))
		? (tests => 6)
		: (skip_all => "SLURM not available on this system");

my $cluster = 'SLURM';

use FindBin;
$ENV{PATH} = "$FindBin::Bin/../bin:$ENV{PATH}";

my $group = HPCI->group( cluster => 'SLURM', base_dir => 'scratch', name => 'T_Memory' );

ok($group, "Group created.");

my $workdir = "scratch/TEST.MEM.REMOVE.ME";
if ( -e $workdir ) {
	die "file exists where work directory was going to be used ($workdir)"
	  if -f _;
	system("rm -rf $workdir") if -d _;
	die "cannot remove old work directory $workdir" if -d $workdir;
}

mkdir $workdir or die "cannot create directory $workdir: $!";

open my $fd, '>', "$workdir/script" or die "cannot open $workdir/script to write: $!";

print $fd <<'EOF';
print "Creating an array with 100000000 numbers\n";

my @array;

push @array, $_ for 1 .. 100000000;

print "Last one was: $array[-1]\n";

print "Start running system\n";
print `ps -l -p $$`;
print "Done running system: $! \n";
sleep(20);

exit(0);
EOF
close $fd or die "error writing $workdir/script: $!";

my $stage1 = $group->stage(
	name => 'mem1',
	resources_required => {
		mem => '1G'
		},
	retry_resources_required => {
		mem => [ qw( 1G 3G 5G ) ]
		},
	native_args_string => "--acctg-freq=task=1",
	command => "perl $workdir/script",
	);

ok($stage1, "Stage 1 created.");

my $result = $group->execute();

is( ref($result), 'HASH', 'Result must be a hash' );
is_deeply( [ keys %$result ], [ qw(mem1) ], '... with one stage (mem1)' );
my $stats = $result->{mem1};
is( ref($stats), 'ARRAY', '... stats must be an array' );
is( scalar(@$stats), 3, '... with 3 elements' );

1;
