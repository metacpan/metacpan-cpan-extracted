use strict;
use warnings;
use utf8;  # important for this test!

BEGIN {
    # Need to do this before importing Test::More
    binmode(STDOUT, ":utf8");
    binmode(STDERR, ":utf8");
};

use Data::Dumper;
use Test::More;

my $CLASS = 'JavaScript::Duktape::XS';

sub test_encoding {
    my %data = (
        portuguese => 'Calendário',
        icelandic  => 'fjörð',
    );

    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    foreach my $key (sort keys %data) {
        my $expected = $data{$key};
        $vm->set($key, $expected);

        my $got = $vm->get($key); # should get as UTF-8 always
        is_deeply($got, $expected, "got encoded data $key: $expected => $got");
    }
}

sub test_hash {
    my %expected = (
        'français' => 'français est une langue indo-européenne',
        'español'  => 'español procede del latín hablado',
        'english'  => 'this is easy',
    );
    # print Dumper(\%expected);

    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    $vm->set('perl', \%expected);
    my $got = $vm->get('perl');
    # print Dumper($got);

    is_deeply($got, \%expected, "got UTF-8 data for keys and values in hash");
}

sub main {
    use_ok($CLASS);

    test_encoding();
    test_hash();
    done_testing;

    return 0;
}

exit main();
