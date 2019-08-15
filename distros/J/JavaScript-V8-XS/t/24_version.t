use strict;
use warnings;

use Data::Dumper;
use Test::More;

my $CLASS = 'JavaScript::V8::XS';

my %field_info = (
    major => {
        name => 'number',
        rx => qr/^[0-9]+$/,
    },
    minor => {
        name => 'number',
        rx => qr/^[0-9]+$/,
    },
    patch => {
        name => 'number',
        rx => qr/^[0-9]+$/,
    },
    build => {
        name => 'number',
        rx => qr/^[0-9]+$/,
    },
    version => {
        name => 'version',
        rx => qr/^[0-9.]+$/,
    },
);

sub test_version_info {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $info = $vm->get_version_info();
    ok($info, "got version info");

    foreach my $field (sort keys %field_info) {
        my $type = $field_info{$field};
        like($info->{$field}, $type->{rx},
             sprintf("field %s = %s is a %s", $field, $info->{$field}, $type->{name}));
    }
}

sub main {
    use_ok($CLASS);

    test_version_info();
    done_testing;

    return 0;
}

exit main();
