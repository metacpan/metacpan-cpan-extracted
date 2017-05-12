use strict;
use warnings;

use Test::More qw( no_plan );
use Linux::LVM2::Utils;

# Test translate_lvm_name
{
    my %cmp = (
        '/dev/mapper/vg-lv' => '/dev/vg/lv',
        '/dev/mapper/vg_test--01-lv_test--01' => '/dev/vg_test-01/lv_test-01',
    );
    foreach my $from (keys %cmp) {
        my $to = $cmp{$from};
        my $got = Linux::LVM2::Utils::translate_lvm_name($from,1);
        is($got, $to, 'translate_lvm_name - '.$from.' translates to '.$to);
    }
}
# Test translate_mapper_name
{
    my %cmp = (
        '/dev/vg/lv' => '/dev/mapper/vg-lv',
        '/dev/vg_test-01/lv_test-01' => '/dev/mapper/vg_test--01-lv_test--01',
    );
    foreach my $from (keys %cmp) {
        my $to = $cmp{$from};
        my $got = Linux::LVM2::Utils::translate_mapper_name($from,1);
        is($got, $to, 'translate_mapper_name - '.$from.' translates to '.$to);
    }
}
