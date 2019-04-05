use strict;
use warnings;

use Data::Dumper;
use Test::More;

my $CLASS = 'JavaScript::V8::XS';

sub test_overflow {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my %data = (
        scalar => 3128741604,
        array => [ 3128741604, 3128741605, 3128741606 ],
        hash => { foo => 3128741604, bar => 3128741605, baz => 3128741606 },
    );

    foreach my $type (sort keys %data) {
        my $expected = $data{$type};
        $vm->set($type, $expected);
        my $got = $vm->get($type);
        is_deeply($got, $expected, "there was no overflow for $type");
    }
}

sub main {
    use_ok($CLASS);

    test_overflow();
    done_testing;
    return 0;
}

exit main();
