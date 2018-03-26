### 21-checksum.t #############################################################
# This file tests checksum verification and creation.

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More tests => 6;
use Test::Exception;

use HPCI;

my $cluster = $ENV{HPCI_CLUSTER} || 'uni';

my $dir_path=`pwd`;
chomp($dir_path);

-d 'scratch' or mkdir 'scratch';

my $in  = "scratch/CHECKSUM_IN";
my $out = "scratch/CHECKSUM_OUT";

sub clean {
    unlink
        grep { -e $_ }
        ( $in, $out );
        # map { ( $_, "$_.sum" ) }
        # map { "scratch/$_" }
        # map { ( "${_}_IN", "${_}_OUT" ) }
        # # map { ( $_, "{$_}1", "{$_}2", "{$_}3" ) }
        # map { ( $_, "NO$_" ) }
        # "CHECKSUM"
        # ;
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

    return $ret;
}

my $name = 'inTestNoSum';
my $ret = run_test(
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

like ($ret->{$name}[0]{exit_status}, qr(one or more required input files), "stage should fail because no sum file present");

$name = 'inTestCreateSum';
$ret = run_test(
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

is ($ret->{inTestCreateSum}[0]{exit_status}, 0, "stage should run");
ok ( -e "$in.sum", "  ... and the in file sum file should have been created" );

$name = 'outTestCreateSum';
$ret = run_test(
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

is ($ret->{outTestCreateSum}[0]{exit_status}, 0, "stage should run");
ok ( -e "$out.sum", "  ... and the out file sum file should have been created" );
is (qx(cat "$in.sum"), qx(cat "$out.sum" ), "  ... and the checksums should be the same" );

done_testing();
clean;

1;
