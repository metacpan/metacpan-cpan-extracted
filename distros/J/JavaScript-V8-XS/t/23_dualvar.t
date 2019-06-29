use strict;
use warnings;

use Data::Dumper;
use Scalar::Util qw/ dualvar /;
use JSON::PP;
use Test::More;

my $CLASS = 'JavaScript::V8::XS';

sub test_dualvars {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $dualvar_implicit = "0345";
    $dualvar_implicit == 234 and die;

    my $dualvar_expicit = dualvar(854, 'hi there');

    my %data = (
        scalar => $dualvar_implicit,
        array => [ 'xxx', $dualvar_expicit, $dualvar_implicit ],
        hash => { foo => $dualvar_implicit, bar => $dualvar_expicit, baz => 99 },
    );

    my $j = JSON::PP->new->canonical(1)->allow_nonref(1);

    foreach my $type (sort keys %data) {
        my $expected = $j->encode( $data{$type} );
        $vm->set($type, $data{$type});
        my $got = $j->encode( $vm->get($type) );
        is_deeply($got, $expected, "conversion of dualvars for $type was correct");
    }
}

sub main {
    use_ok($CLASS);

    test_dualvars();
    done_testing;
    return 0;
}

exit main();
