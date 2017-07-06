### 18-require_output_files.t #############################################################
# This file tests setting the files attribute with required output files
# They are verified to be updated to consider that a stage executed successfully.

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More tests => 5;
use Test::Exception;

use HPCI;

my $cluster = $ENV{HPCI_CLUSTER} || 'uni';

my $dir_path=`pwd`;
chomp($dir_path);

-d 'scratch' or mkdir 'scratch';

sub clean {
    unlink
        grep { -e $_ }
        map { "scratch/$_" }
        qw(NEVER_TOUCHED TOUCH_TOO_SOON TOUCH_JUST_RIGHT)
        ;
}

clean;

my $group = HPCI->group(
    cluster => $cluster,
    base_dir => "$dir_path/scratch",
    name => 'T_Req_Out'
    );

ok($group, "Group created.");

my $stage1 = $group->stage(
    name    => "echoTest",
    command => "echo foo test",
    files   => {
        out => {
            req => 'scratch/NEVER_TOUCHED'
        }
    }
);

ok ($stage1, "Stage 1 created");
my $ret = $group->execute();

ok ($ret->{echoTest}[0]{failure_detected}, "Failure detection should be triggered by output file that doesn't get created");

open my $fd, '>', 'scratch/TOUCH_TOO_SOON';
close $fd;

sleep 2;

$group = HPCI->group(
    cluster => $cluster,
    base_dir => "$dir_path/scratch",
    name => 'T_Req_Out2'
    );

$group->stage(
    name    => "echoTest",
    command => "sleep 2",
    files   => {
        out => {
            req => 'scratch/TOUCH_TOO_SOON'
        }
    }
);
$ret = $group->execute();

ok ($ret->{echoTest}[0]{failure_detected}, "Failure detection should be triggered by output file that was last changed before the stage was executed");

$group = HPCI->group(
    cluster => $cluster,
    base_dir => "$dir_path/scratch",
    name => 'T_Req_Out3'
    );

$group->stage(
    name    => "echoTest",
    command => "touch scratch/TOUCH_JUST_RIGHT",
    files   => {
        out => {
            req => 'scratch/TOUCH_JUST_RIGHT'
        }
    }
);
$ret = $group->execute();

ok (! defined( $ret->{echoTest}[0]{failure_detected} ), "Failure detection should not be triggered by output file that is changed by the stage");

done_testing();
clean;

1;
