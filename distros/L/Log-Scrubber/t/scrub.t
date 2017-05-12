#!/usr/bin/perl
use Carp;

# Test the scrubber method

BEGIN
{
    @crap = (
        "\x1bAll",
        "yo\x1bur",
        "bas\x1be",
        "are\x1b",
        "belong",
        "to\x1b",
        "\x1bus",
        \*STDOUT,
        \*STDIN,
        \&croak,
        \\undef,
        (\substr "abc", 1, 2),
        *STDIN{IO},
        \v5.10.0,
        qr/./,
        '',
    );
};

use Test::More tests => scalar @crap;
use Log::Scrubber qw(scrubber scrubber_init);

tie my $x, 'test_blessed';
$crap[15] = \$x;

scrubber_init( { '\x1b' => '[esc]' } );

my @safe = scrubber @crap;

is($safe[0], '[esc]All');
is($safe[1], 'yo[esc]ur');
is($safe[2], 'bas[esc]e');
is($safe[3], 'are[esc]');
is($safe[4], 'belong');
is($safe[5], 'to[esc]');
is($safe[6], '[esc]us');
is(ref $safe[7], 'GLOB');
is(ref $safe[8], 'GLOB');
is(ref $safe[9], 'CODE');
is(ref $safe[10], 'REF');
is(ref $safe[11], 'LVALUE');
like(ref $safe[12], qr/^IO::/, 'IO');
like(ref $safe[13], qr/VSTRING|SCALAR/, 'SCALAR');
is(ref $safe[14], 'Regexp');
is(ref $safe[15], 'SCALAR');


package test_blessed;

sub TIESCALAR {
return bless [], __PACKAGE__;
}

sub FETCH {
    my ($self) = @_;
    1;
}

sub STORE {
    my ($self, $val) = @_;
    1;
}

1;
