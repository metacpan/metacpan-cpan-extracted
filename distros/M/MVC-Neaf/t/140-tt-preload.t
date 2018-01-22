#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::View::TT;

my $view = MVC::Neaf::View::TT->new( CACHE_SIZE => 0 );

my $content;
($content) = eval {
    $view->render( { -template => 'foo', bar => 42 } );
};
like $@, qr/^MVC::Neaf::View::TT->render.*not found/, "Render croaks";
note $@;
diag "rendered as: $content"
    if $content;

$view->preload( foo => 'BAR [% bar %]' );
($content) = eval {
    $view->render( { -template => 'foo', bar => 42 } );
};
is $content, 'BAR 42', "Rendered after preload"
    or diag "Error was: $@";

eval {
    $view->preload( xxx => '[% IF foo %]' );
};
like $@, qr/MVC::Neaf::View::TT->preload.*/, "Preload of invalid tpl failed";
note $@;

done_testing;
