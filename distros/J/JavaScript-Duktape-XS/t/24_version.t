use strict;
use warnings;

use Data::Dumper;
use Test::More;

my $CLASS = 'JavaScript::Duktape::XS';

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
        optional => $CLASS =~ m/V8/ ? 1 : 0,
        name => 'number',
        rx => qr/^[0-9]+$/,
    },
    build => {
        optional => $CLASS =~ m/Duktape/ ? 1 : 0,
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
        if ($type->{optional}) {
            if (!$info->{$field}) {
                ok(1, sprintf("field %s is optional and absent", $field));
                next;
            }
        }
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
