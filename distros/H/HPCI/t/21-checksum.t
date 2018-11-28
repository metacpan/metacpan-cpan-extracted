### 21-checksum.t #############################################################
# This file tests checksum verification and creation.

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More tests => 11;
use Test::Exception;

use HPCI;

my $cluster = $ENV{HPCI_CLUSTER} || 'uni';

my $dir_path=`pwd`;
chomp($dir_path);

-d 'scratch' or mkdir 'scratch';

my $in   = "scratch/CHECKSUM_IN";
my $out  = "scratch/CHECKSUM_OUT";
my $out2 = "scratch/CHECKSUM_OUT2";

sub clean {
    unlink
        grep { -e $_ }
        map { ( $_, "$_.sum" ) }
        ( $in, $out, $out2 );
}

clean;

`echo hi > $in`;
sleep 2;

my $count = 1;

sub run_test {
    my $group = HPCI->group(
        cluster => $cluster,
        base_dir => "$dir_path/scratch",
        file_system_delay => 30,	
        name => "T_Checksum".($count++),
        );

    my $stage1 = $group->stage( @_ );

    my $ret = $group->execute();

    return (values(%$ret))[0][0]{exit_status};
}

my $name = 'inTestNoSum';
my $stat = run_test(
    name    => $name,
    command => "exit 0",
    files   => {
        in  => {
            req => [
                [ $in, sum=>1, ],
            ],
        },
    }
);

like ($stat, qr(one or more required input files), "stage ($name) should fail because no sum file present");

$name = 'inTestCreateSum';
$stat = run_test(
    name    => $name,
    command => "exit 0",
    files   => {
        in  => {
            req => [
                [ $in, sum=>1, sum_generate_in => 1 ],
            ],
        },
    }
);

is ($stat, 0, "stage ($name) should run");
ok ( -e "$in.sum", "  ... and the in file sum file should have been created" );

$name = 'outTestCreateSum';
$stat = run_test(
    name    => $name,
    command => "cp $in $out",
    files   => {
        in  => {
            req => [
                [ $in, sum=>1, ],
            ],
        },
        out => {
            req => [
                [ $out, sum=>1, ],
            ],
        },
    }
);

is ($stat, 0, "stage ($name) should run");
ok ( -e "$out.sum", "  ... and the out file sum file should have been created" );
is (qx(cat "$in.sum"), qx(cat "$out.sum" ), "  ... and the checksums should be the same" );

$name = 'outTestCreate2Sum';
$stat = run_test(
    name    => $name,
    command => "cp $in $out; cp $in $out2",
    files   => {
        in  => {
            req => [
                [ $in, sum=>1, ],
            ],
        },
        out => {
            req => [
                [ $out,  sum=>1, ],
                [ $out2, sum=>1, ],
            ],
        },
    }
);

is ($stat, 0, "stage ($name) should run");
ok ( -e "$out.sum", "  ... and the out file sum file should have been created" );
is (qx(cat "$in.sum"), qx(cat "$out.sum" ), "  ... and the checksums should be the same" );
ok ( -e "$out2.sum", "  ... and the out2 file sum file should have been created" );
is (qx(cat "$in.sum"), qx(cat "$out2.sum" ), "  ... and the checksums should be the same" );

done_testing();
clean;

1;
