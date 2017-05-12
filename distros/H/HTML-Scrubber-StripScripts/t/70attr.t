
use strict;
use Test::More tests => 6;

BEGIN { $^W = 1 }

use HTML::Scrubber::StripScripts;

use vars qw($s);
$s = HTML::Scrubber::StripScripts->new;

test(  '<font size=15>',   '<font size="15">', 'font with bare valid size' );
test(  '<font size="15">', '<font size="15">', 'font with doublequoted valid size' );
test( q|<font size='15'>|, '<font size="15">', 'font with singlequoted valid size' );

test(  '<font size=foo>',   '<font>', 'font with bare bad size' );
test(  '<font size="foo">', '<font>', 'font with doublequoted bad size' );
test( q|<font size='foo'>|, '<font>', 'font with singlequoted bad size' );

sub test {
    my ($in, $out, $name) = @_;

    is( $s->scrub($in), $out, $name );
}

