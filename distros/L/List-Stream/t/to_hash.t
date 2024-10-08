use strict;
use warnings;

use Test::More;
use List::Stream;

my @data = (
    { id => 1, name => 'bob' },
    { id => 2, name => 'john' },
    { id => 3, name => 'albert' }
);
my $stream = stream @data;

my %hash = $stream->map( sub { $_->{age} = $_->{id} + 10; $_ } )
  ->to_hash( sub { $_->{'id'} }, sub { $_ } );

is_deeply $hash{1}, { id => 1, age => 11, name => 'bob' },
  'is first value correct?';
is_deeply $hash{2}, { id => 2, age => 12, name => 'john' },
  'is second value correct?';
is_deeply $hash{3}, { id => 3, age => 13, name => 'albert' },
  'is third value correct?';

done_testing;
