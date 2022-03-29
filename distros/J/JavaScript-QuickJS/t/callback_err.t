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

    eval { $js->eval("nada(Symbol(123123))") };
    $err = $@;
    like($err, qr<symbol>i, 'Symbol to Perl triggers error');
}

done_testing;
