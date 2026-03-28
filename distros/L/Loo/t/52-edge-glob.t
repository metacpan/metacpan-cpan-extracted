use strict;
use warnings;
use Test::More;
use Loo qw(ncDump);

# ── Glob ref ─────────────────────────────────────────────────────
{
    no strict 'refs';
    my $glob = \*STDOUT;
    my $out = ncDump($glob);
    like($out, qr/STDOUT|GLOB/, 'glob ref: STDOUT present');
}

# ── Named glob ──────────────────────────────────────────────────
{
    no strict 'refs';
    my $glob = \*main::STDIN;
    my $out = ncDump($glob);
    like($out, qr/STDIN|GLOB/, 'glob ref: STDIN present');
}

# ── Glob in array ───────────────────────────────────────────────
{
    no strict 'refs';
    my $out = ncDump([\*STDOUT]);
    like($out, qr/STDOUT|GLOB/, 'glob in array');
}

# ── Glob in hash ────────────────────────────────────────────────
{
    no strict 'refs';
    my $dd = Loo->new([{out => \*STDOUT}]);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    like($out, qr/STDOUT|GLOB/, 'glob in hash value');
}

done_testing;
