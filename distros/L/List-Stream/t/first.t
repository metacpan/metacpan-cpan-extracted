use strict;
use warnings;

use Test::More;

use List::Stream;

my $stream = stream( 1, 2, 3, 4 );

my $mapped_stream =
  $stream->map( sub { $_ * 2 } )->map( sub { +{ $_ => ( $_ / 2 ) } } )
  ->map( sub { ( keys %$_ )[0] } )->map( sub { $_ * 2 } );

is $mapped_stream->first, 4, 'first is correct?';

done_testing;
