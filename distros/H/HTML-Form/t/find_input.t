#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use HTML::Form ();
use Test::Warnings qw(warning);

my $html = '<html><body><form></form></body></html>';

my $form = HTML::Form->parse( $html, 'http://example.com' );
ok( $form, 'form created' );

ok(
    !eval {
        $form->find_input( 'submit', 'button', 0 );
        1;
    },
    'index 0'
);
like( $@, qr/Invalid index 0/, 'exception text' );

ok(
    !eval {
        $form->find_input( 'submit', 'button', 'a' );
        1;
    },
    'index a'
);
like( $@, qr/Invalid index a/, 'exception text' );

{
    like(
        warning {
            my @inputs = $form->find_input( 'submit', 'input', 1 );
        },
        qr/^find_input called in list context with index specified/,
        'warning text'
    );
}

done_testing;
