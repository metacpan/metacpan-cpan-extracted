#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;
use Data::Dumper;
use Config;

use JavaScript::QuickJS;

my $js = JavaScript::QuickJS->new()->set_globals(
    add1 => sub { $_[0] + 1 },
);

is( $js->eval("add1(23)"), 24, 'JS calls Perl' );

my $is_64bit = $Config{'use64bitint'};

my @roundtrip = (
    "hello",
    "\xe9",
    "\x{100}",
    "\x{101234}",
    -1,
    -1.234,
    0,
    1.234,
    0xffff_ffff,
    -0x8000_0000,

    $js->eval('Number.MAX_SAFE_INTEGER'),
    $js->eval('Number.MIN_SAFE_INTEGER'),

    ($is_64bit
        ? (map { $_, -$_ } 0xffff_ffff << 17)
        : ()
    ),

    [1, 2, 3],
    [],
    {},
    { foo => 'bar' },
    { "\x{100}" => [] },

    # Test magic:
    \%Config,
);

for my $rtval (@roundtrip) {
    my $key = 'rtval';

    $js->set_globals( $key => $rtval );

    my $got = $js->eval($key);

    # Perl’s NV stringification loses precision once we exceed
    # 10^15. To minimize the chance that that will cause a problem,
    # we add 0 to encourage Perl to convert to an IV if possible.
    #
    if ($got =~ m<\A-?[0-9]+(?:\.[0-9]+)\z>) {
        $got += 0;
    }

    local $Data::Dumper::Useqq =1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    my $str = Dumper($rtval);

    my $alt_double_yn = $Config{'uselongdouble'} || $Config{'usequadmath'};

    my $allow_approx = $alt_double_yn ? ($rtval !~ tr<0-9.-><>c) : ($rtval =~ tr<.><>);

    if ($allow_approx) {
        cmp_deeply($got, num($rtval, 0.01), "gave & received: $str" );
    }
    else {
        is_deeply($got, $rtval, "gave & received: $str" );
    }
}

eval { $js->set_globals( regexp => qr/abc/ ) };
my $err = $@;

like($err, qr<abc>, 'error mentions what can’t be converted');
like($err, qr<javascript>i, 'error mentions JS');

#----------------------------------------------------------------------

if ($is_64bit) {
    my @t = (
        [ '> IV_MAX', unpack('Q>', "\x80\0\0\0\0\0\0\0") ],
        [ '<= IV_MAX', unpack('Q>', "\x7f\0\0\0\0\0\0\0") ],
        [ 'negative 64-bit', unpack('q>', "\x80\0\0\0\0\0\0\0") ],
    );

    for my $tt (@t) {
        my ($label, $expect) = @$tt;

        $js->set_globals(
            bignum => $expect,
        );

        my $got = $js->eval('bignum');

        cmp_deeply(
            $got,
            num($expect, 100),
            $label,
        );
    }

}

done_testing;
