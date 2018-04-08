### 22-file_params.t #############################################################
# This file tests checksum verification and creation using group->file_params.

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More tests => 21;
use Test::Exception;
use Path::Class;

use HPCI;

my $cluster = $ENV{HPCI_CLUSTER} || 'uni';

my $dir_path=`pwd`;
chomp($dir_path);

-d 'scratch' or mkdir 'scratch';

my $in   = file("scratch/CHECKSUM_IN");
my $ins  = "$in.sum";
my $out  = "scratch/CHECKSUM_OUT";
my $outs = "$out.sum";
my $dup  = "$out.dup";
my $dups = "$dup.sum";

sub clean {
    unlink
        grep { -e $_ }
        map { ( $_, "$_.sum" ) }
        ( $out, $dup, @_ );
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

    $group->add_file_params( shift ) if ref($_[0]) eq 'HASH';
    my $stage1 = $group->stage( @_ );

    my $ret = $group->execute();

    return $ret;
}

my $name = 'inTestNoSum';
my $ret = run_test(
    {
        $in  => { sum => 1 },
    },
    name    => $name,
    command => "exit 0",
    files   => {
        in  => {
            req => [
                $in,
            ],
        },
    }
);

like ($ret->{$name}[0]{exit_status}, qr(one or more required input files), "stage should fail because no sum file present");

clean;

$name = 'inTestCreateSum';
$ret = run_test(
    {
        $in  => { sum => 1, sum_generate_in => 1 },
    },
    name    => $name,
    command => "exit 0",
    files   => {
        in  => {
            req => [
                $in,
            ],
        },
    }
);

is ($ret->{inTestCreateSum}[0]{exit_status}, 0, "stage should run");
ok ( -e $ins, "  ... and the in file sum file shoud have been created" );

clean;

$name = 'outTestCreateSum';
$ret = run_test(
    {
        $in  => { sum => 1 },
        $out => { sum => 1 },
    },
    name    => $name,
    command => "cp $in $out",
    files   => {
        in  => {
            req => [
                $in,
            ],
        },
        out => {
            req => [
                $out,
            ],
        },
    }
);

is ($ret->{outTestCreateSum}[0]{exit_status}, 0, "stage should run");
ok ( -e $outs, "  ... and the out file sum file should have been created" );
is (qx(cat $ins), qx(cat $outs ), "  ... and the checksums should be the same" );

clean;

$name = 'deleteWithSumTest';
$ret = run_test(
    {
        $in  => { sum => 1 },
        $out => { sum => 1 },
    },
    name    => $name,
    command => "cp $in $out",
    files   => {
        in  => {
            req => [
                $in,
            ],
        },
        out => {
            req => [
                $out,
            ],
        },
        delete => [ $out ],
    }
);

is ($ret->{deleteWithSumTest}[0]{exit_status}, 0, "stage should run");
ok ( !(-e "$out"), "  ... and the out file should have been deleted" );
ok ( !(-e "$outs"), "  ... ... as wellas the out file sum file" );

clean;

$name = 'deleteTest';
$ret = run_test(
    name    => $name,
    command => "cp $in $out",
    files   => {
        in  => {
            req => [
                $in,
            ],
        },
        out => {
            req => [
                $out,
            ],
        },
        delete => [ $out ],
    }
);

is ($ret->{deleteTest}[0]{exit_status}, 0, "stage should run");
ok ( !(-e "$out"), "  ... and the out file should have been deleted" );

clean;

$name = 'renameTest';
$ret = run_test(
    name    => $name,
    command => "cp $in $out",
    files   => {
        in  => {
            req => [
                $in,
            ],
        },
        out => {
            req => [
                $out,
            ],
        },
        rename => [ [$out, "$dup"] ],
    }
);

is ($ret->{renameTest}[0]{exit_status}, 0, "stage should run");
ok ( !(-e "$out"), "  ... and the out file should have been renamed" );
ok (  (-e "$dup"), "  ... ... to the dup file" );
ok ( !(-e "$outs"), "  ... with no sum file created" );
ok ( !(-e "$dups"), "  ... ... for either" );

clean;

$name = 'renameWithSumTest';
$ret = run_test(
    {
        $in  => { sum => 1 },
        $out => { sum => 1 },
    },
    name    => $name,
    command => "cp $in $out",
    files   => {
        in  => {
            req => [
                $in,
            ],
        },
        out => {
            req => [
                $out,
            ],
        },
        rename => [ [$out, "$dup"] ],
    }
);

is ($ret->{renameWithSumTest}[0]{exit_status}, 0, "stage should run");
ok ( !(-e "$out"), "  ... and the out file should have been renamed" );
ok (  (-e "$dup"), "  ... ... to the dup file" );
ok ( !(-e "$outs"), "  ... with its sum file also renamed" );
ok (  (-e "$dups"), "  ... ... to the dup sum file" );

done_testing();
clean("$in");

1;
