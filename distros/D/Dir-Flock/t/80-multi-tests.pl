use Test::More;
use strict;
use warnings;

use Data::Dumper;

sub ok_multi {
    my ($fa, $fb) = @_;
    my %fa = multi_test_file_to_hash($fa);
    my %fb = multi_test_file_to_hash($fb);
    ok(scalar keys %fa, "read data from primary process");
    ok(scalar keys %fb, "read data from secondary process");

    ok($fa{name} eq 'primary' && $fb{name} eq 'secondary',
       'read name data from process files');
    if (abs($fa{start}-$fb{start}) > 5) {
        diag "!! start times: ", $fa{start}, "/", $fb{start};
    }
    ok($fa{dir} && $fa{dir} eq $fb{dir},
       "processes were synchronized on common directory")
        or diag $fa{dir}," ",$fb{dir};
    if (abs($fa{save_dir}-$fb{read_dir}) > 5) {
        diag "!! dir communication times: ",
            $fa{save_dir}, "/", $fb{read_dir};
    }

    # primary process acquires lock
    ok($fa{status_ex} != 0, 'primary acquires lock');
    ok($fa{end_ex} - $fa{start_ex} < 2, "primary acquires lock quickly");
    ok($fa{end_sleep1} - $fa{start_sleep1} > 8,
       "primary holds lock for a while");

    # first lock attempt in secondary should fail, fail fast
    ok($fb{status_sh_nb1} == 0, "non-blocking attempt in secondary failed");
    ok($fb{end_sh_nb1}-$fb{start_sh_nb1} < 2,
       "non-blocking attempt in secondary failed fast");
    
    ok($fa{status_unlock1} != 0, 'primary releases lock');
    ok($fa{end_unlock1} - $fa{start_unlock1} < 2, 'primary unlock is fast');
    
    ok($fb{status_sh} != 0, "block attempt in secondary ok");
    ok($fb{end_sh}-$fb{start_sh} > 4,
       "blocking attempt in secondary took time to succeed");

    ok($fa{end_sleep2}-$fa{start_sleep2} >= 4,
       "primary process waits for a little while");
    ok($fb{end_sleep1}-$fb{start_sleep1} >= 4,
       "secondary process holds (shared) lock for a little while");

    # primary non-blocking attempt for exclusive lock should fail, fast
    ok($fa{status_ex_nb} == 0, 'non-blocking exclusive failed for primary');
    ok($fa{end_ex_nb} - $fa{start_ex_nb} < 2, '... and failed fast');
    ok($fa{status_sh_nb} != 0, 'non-block shared lock for primary ok');
    ok($fa{end_sh_nb} - $fa{start_sh_nb} < 2, '... and was acquired fast');
    ok($fa{status_unlock4} != 0, 'primary released shared lock');

    ok($fb{end_sleep1}-$fb{start_sleep1} >= 4,
       'secondary held shared lock for a while');

    # unlock might fail if primary process removes the lock directory ...
    ok($fb{status_unlock2} eq '1 1' || $fb{status_unlock2} eq '0 0',
       'secondary released shared lock');
    
    ok($fb{end_unlock2}-$fb{start_unlock2} <= 2, '... released quickly');

    ok($fa{end_sleep3}-$fa{start_sleep3} >= 4,
       'primary slept for a while before quitting');
}

sub multi_test_file_to_hash {
    my $file = shift;
    my %hash;
    open my $fh, "<", $file;
    while (<$fh>) {
        chomp;
        my ($key, $val) = split /: /, $_, 2;
        $hash{$key} = $val;
    }
    close $fh;
    return %hash;
}

1;
