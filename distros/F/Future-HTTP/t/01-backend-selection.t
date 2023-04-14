#!perl -w
use strict;
use Test::More;
use Data::Dumper;
use Future::HTTP;

my $ok = eval {
    require Test::Without::Module;
    require Future::HTTP::AnyEvent;
    1;
} || eval {
    require Test::Without::Module;
    require Future::HTTP::Mojo;
    1;
};

if( $ok ) {
    plan( tests => 2 );
} else {
    plan( skip_all => "No backend other than IO::Async available" );
};

Test::Without::Module->import( qw( HTTP::Tiny ) );
isnt( Future::HTTP->best_implementation, 'Future::HTTP::Tiny',
    "We select a different socket backend if HTTP::Tiny is unavailable");

isnt( Future::HTTP->best_implementation, 'Future::HTTP::Tiny',
    "We select a different pipe backend if HTTP::Tiny is unavailable");
