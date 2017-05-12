#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {

    eval { require Text::GooglewikiFormat }
        or plan skip_all =>
        'Text::GooglewikiFormat is required for this test';

    plan tests => 3;
}

use Foorum::Formatter qw/filter_format/;

my $text = <<TEXT;
= my interesting text =

ANormalText
[SunDown|let the Sun down]
[http://www.fayland.org/|let the Sun shine]

== my interesting lists ==

  * unordered one
  * unordered two

  # ordered one
  # ordered two

{{{
code one
code two
}}}

The first line of a *normal* paragraph.
The second line of a normal paragraph.  Whee.
such as http://www.cpan.org/
TEXT

my $html = filter_format( $text, { format => 'wiki' } );

like( $html, qr/ol/,        '*,* OK' );
like( $html, qr/ul/,        '1,2 OK' );
like( $html, qr/\<a href=/, 'absolute_links OK' );

#diag($html);
