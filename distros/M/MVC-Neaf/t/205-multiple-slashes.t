#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

get '/my/path' => sub { +{-content => $_[0]->postfix} }, path_info_regex => '.*';
get '/my/path/replace' => sub { +{ -content => 'Gotcha' } };

path_ok( '/my/path', 200, '' );
path_ok( '//my//path', 200, '' );
path_ok( '/my/path///', 200, '' );
path_ok( '//my//path//foo//bar', 200, 'foo//bar', "Slashes in postfix preserved" );

path_ok( '/my/pathogen', 404, undef, "No slash after prefix = no go" );

path_ok( '/my/path/replace', 200, 'Gotcha', "Route overrides suffix" );
path_ok( '/my/path/replace////', 200, 'Gotcha', "Route overrides suffix even with trailing slash" );
path_ok( '/my/path/replace/nope', 404, undef, "Not mathing subtree suffix rex" );

done_testing;

sub path_ok {
    my ($path, $status, $content, $note) = @_;

    $note = $note ? ": $note" : '';

    my @got = neaf->run_test( $path );
    is $got[0], $status, "Got $status for '$path'$note";
    is $got[2], $content, "Content is '$content' for '$path'$note"
        if defined $content;
};
