use strict;
use warnings;
use Test::More;
use Lingua::JA::DocumentFrequency::AozoraBunko;

can_ok('Lingua::JA::DocumentFrequency::AozoraBunko', qw/df  aozora_df  number_of_documents/);

done_testing;
