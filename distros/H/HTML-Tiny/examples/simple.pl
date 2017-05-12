#!/usr/bin/perl

use strict;
use warnings;
use HTML::Tiny;

$| = 1;

my $h = HTML::Tiny->new;

# Output a simple HTML page
print $h->html(
  [
    $h->head( $h->title( 'Sample page' ) ),
    $h->body(
      [
        $h->h1( { class => 'main' }, 'Sample page' ),
        $h->p( 'Hello, World', { class => 'detail' }, 'Second para' ),
        $h->form(
          { method => 'POST' },
          [
            $h->input( { type => 'text', name => 'q' } ),
            $h->br,
            $h->input( { type => 'submit' } )
          ]
        )
      ]
    )
  ]
 ),
 "\n";
