use strict;
use warnings;
use Test::More;
use Lingua::JA::DocumentFrequency::AozoraBunko qw/number_of_documents/;

is( number_of_documents(), 11176 );

done_testing;
