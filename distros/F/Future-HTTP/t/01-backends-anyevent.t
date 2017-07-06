#!perl -w
use strict;
use warnings;
use Test::More;

use Future::HTTP;

is( Future::HTTP->best_implementation(), 'Future::HTTP::Tiny', "The default backend is HTTP::Tiny");

# If we can load a backend, also make sure it can be chosen:
for my $known_implementation (['AnyEvent.pm'    => 'Future::HTTP::AnyEvent']) {
    my( $module_file, $implementation ) = @$known_implementation;
    if( eval { require $module_file; 1 } ) {
        if( eval "require $implementation; 1" ) {
            my $backend = Future::HTTP->best_implementation(
                $known_implementation,
                ['strict.pm' => 'fallback reached'],
            );
            is( $backend, $implementation, "$implementation is chosen and loadable if $module_file is loaded" );
        } else {
            my $err = $@;
            diag "Skipped check for $implementation backend: $err";
        };
    } else {
        my $err = $@;
        diag "Skipped check for $implementation backend: $err";
    };
};

done_testing();