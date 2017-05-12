use strict;
use warnings;

use Test::More tests => 15;
use Test::NoWarnings;
use Test::Exception;

use Memoize;
use Memoize::HashKey::Ignore;

my $expensive_count = 0;

tie my %scalar_cache => 'Memoize::HashKey::Ignore',
  IGNORE           => sub { return shift == 7; };
tie my %list_cache => 'Memoize::HashKey::Ignore',
  IGNORE           => sub { return shift == 7; };

sub expensive_function {
    my ($arg) = @_;
    $expensive_count++;
    return $arg;
}

Memoize::memoize(
    'expensive_function',
    SCALAR_CACHE => [ HASH => \%scalar_cache ],
    LIST_CACHE   => [ HASH => \%list_cache ],
);

sub do_some_calcs {
    my ($howmany) = @_;
    my $count     = 0;

    $expensive_count = 0;

    for my $iter ( 1 .. $howmany ) {
        $count++ if expensive_function($iter);
    }

    return $count;
}

my $stuff = do_some_calcs(10);

is( $stuff,           10, '10 calcs yield 10 results' );
is( $expensive_count, 10, '...with 10 expensive_functions' );

$stuff = do_some_calcs(10);

is( $stuff,           10, '10 calcs yield 10 results' );
is( $expensive_count, 1,  '...with 1 expensive_functions' );

$stuff = do_some_calcs(15);

is( $stuff,           15, '15 calcs yield 15 results' );
is( $expensive_count, 6,  '...with 6 expensive_functions' );

Memoize::flush_cache('expensive_function');

$stuff = do_some_calcs(6);

is( $stuff,           6, '6 calcs yield 6 results' );
is( $expensive_count, 6, '...with 0 expensive_functions' );

$stuff = do_some_calcs(7);

is( $stuff,           7, '7 calcs yield 7 results' );
is( $expensive_count, 1, '...with 7 expensive_functions' );

$stuff = do_some_calcs(7);

is( $stuff,           7, '7 calcs yield 7 results' );
is( $expensive_count, 1, '...with 1 expensive_functions' );

$stuff = do_some_calcs(8);

is( $stuff,           8, '8 calcs yield 8 results' );
is( $expensive_count, 2, '...with 2 expensive_functions' );


