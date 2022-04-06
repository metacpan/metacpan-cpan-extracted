#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use JavaScript::QuickJS;

my $js = JavaScript::QuickJS->new();

$js->set_globals(
    trouble => sub { die( bless [], 'Trouble' ) },
    nada => sub {},
    bad_perl => sub { bless [], 'WhatWhat' },
    bad_perl_in_array => sub { [ bless [], 'WhatWhat' ] },
    bad_perl_in_hash => sub { { foo => \*STDOUT } },
);

{
    my @w;
    $SIG{__WARN__} = sub { push @w, @_ };

    eval { $js->eval("trouble()") };
    my $err = $@;

    is(0 + @w, 1, '1 warning');
    like($w[0], qr<\ATrouble=ARRAY>, 'expected warning text');

    like($err, qr<Trouble=ARRAY>, 'expected error');
    like($err, qr<JavaScript>i, 'error mentions JS');
}

{
    eval { $js->eval("nada(BigInt(123123))") };
    my $err = $@;
    like($err, qr<big>i, 'BigInt to Perl triggers error');

    eval { $js->eval("nada(123, Symbol(123123))") };
    $err = $@;
    like($err, qr<symbol>i, 'Symbol to Perl triggers error');

    eval { $js->eval("bad_perl()") };
    $err = $@;
    like($err, qr<WhatWhat>i, 'blessed ref from callback triggers error');

    eval { $js->eval("bad_perl_in_array()") };
    $err = $@;
    like($err, qr<WhatWhat>i, 'blessed ref is in array');

    eval { $js->eval("bad_perl_in_hash()") };
    $err = $@;
    like($err, qr<GLOB>i, 'filehandle ref is in hash');
}

done_testing;
