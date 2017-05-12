#!/usr/bin/perl
# $Id: 04-utf8.t 27 2012-08-30 19:54:25Z andrew $

use strict;
use warnings;

use blib;
use LaTeX::Encode;
use charnames qw();

my %latex_encoding = %LaTeX::Encode::latex_encoding;
my $tests = 8 + scalar(keys %latex_encoding);

warn $tests;

use Test::More;

plan tests => $tests;

ok(int keys %latex_encoding > 300, "encoding table isn\'t empty (has " . int(keys %latex_encoding) . " keys)");

# spot checks

is($latex_encoding{chr(0x0024)}, '\\$',              'encoding for: dollar sign' );
is($latex_encoding{chr(0x00a2)}, '{\\textcent}',     'encoding for: cent sign'   );
is($latex_encoding{chr(0x00a3)}, '{\\textsterling}', 'encoding for: pound sign'  );
is($latex_encoding{chr(0x00a5)}, '{\\textyen}',      'encoding for: yen sign'    );
is($latex_encoding{chr(0x0192)}, '{\\textflorin}',   'encoding for: florin'      );
is($latex_encoding{chr(0x2020)}, '{\\textdagger}',   'encoding for: dagger'      );
is($latex_encoding{chr(0x20ac)}, '{\\texteuro}',     'encoding for: euro sign'   );


# thorough test of all entries in encoding table

foreach my $char (sort keys %latex_encoding) {
    my $encoding = $latex_encoding{$char};
    my $charcode = ord($char);
    my $charname = charnames::viacode($charcode) || '';
    my $comment  = $charname || "unnamed character encoded as '$encoding'";

    warn(sprintf('encoding for charcode U+%04d is undefined', $charcode))
        if !defined $encoding;
    is(latex_encode("$charname: $char."), "$charname: $encoding.",
       sprintf("translating U+%04x (%s)", $charcode, $comment));
}

