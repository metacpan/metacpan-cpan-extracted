
use strict;
use Test::More tests => 14;

BEGIN { $^W = 1 }

use_ok('HTML::StripScripts::Parser');

use vars qw($p);

$p = HTML::StripScripts::Parser->new;
isa_ok( $p, 'HTML::StripScripts::Parser' );

my $pp = $p->new;
isa_ok( $pp, 'HTML::StripScripts::Parser' );

test( '',     '',    'empty document' );
test( 'foo',  'foo', 'text only document' );
test( "f\0o", 'f o', 'strip nulls' );

test( '<i><asdfsadf>foo</boink>',
      '<i><!--filtered-->foo<!--filtered--></i>',
      'parse into tags'
);

test( 'x<foo>y',  'x<!--filtered-->y', 'filter start' );
test( 'x</foo>y', 'x<!--filtered-->y', 'filter end' );

test( '<table> </table>', '<table> </table>', 'filter text' );

test( 'x<?xml version="1.0" encoding="utf-8"?>y',
      'x<!--filtered-->y',
      'filter process'
);

test( 'x<!-- foo -->y', 'x<!--filtered-->y', 'filter comment' );

test( 'x<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"' . "\n"
          . '   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">y',
      'x<!--filtered-->y',
      'filter declaration'
);

{

    package MyFilter;
    use base qw(HTML::StripScripts::Parser);

    sub output_end {
        my ( $self, $text ) = @_;

        $self->output( uc $text );
    }
}

$p = MyFilter->new;
test( '<i>foo</i>', '<i>foo</I>', 'subclassing works as expected' );

sub test {
    my ( $in, $out, $name ) = @_;
    is( $p->filter_html($in), $out, $name );
}


