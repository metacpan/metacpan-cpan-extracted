### 09-failure.t ##################################################################################
# This file tests a failed program (division by 0) which will not be retried

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

my $group = HPCI->group( cluster => 'SLURM', base_dir => 'scratch', name => 'T_Failure' );

ok($group, "Group created.");

my $workdir = "scratch/TEST.FAIL.REMOVE.ME";
if ( -e $workdir ) {
	die "file exists where work directory was going to be used ($workdir)"
	  if -f _;
	system("rm -rf $workdir") if -d _;
	die "cannot remove old work directory $workdir" if -d $workdir;
}

mkdir $workdir or die "cannot create directory $workdir: $!";

open my $fd, '>', "$workdir/script" or die "cannot open $workdir/script to write: $!";

print $fd <<'EOF';

my $ans = 1 / 0;
print "$ans \n";

exit(0);
EOF
close $fd or die "error writing $workdir/script: $!";

my $stage1 = $group->stage(
	name => 'stage1',
	resources_required => {
		mem => '1G'
		},
	retry_resources_required => {
		mem => [ qw( 1G 3G 5G ) ]
		},
	command => "perl $workdir/script",
	);

ok($stage1, "Stage 1 created.");

my $result = $group->execute();

is( ref($result), 'HASH', 'Result must be a hash' );
is_deeply( [ keys %$result ], [ qw(stage1) ], '... with one stage (stage1)' );
my $stats = $result->{stage1};
is( ref($stats), 'ARRAY', '... stats must be an array' );
is( scalar(@$stats), 1, '... with 1 element' );

1;
