use strict;
use warnings;
use utf8;
use Test::More;
use Lingua::JA::DocumentFrequency::AozoraBunko qw/df aozora_df/;

like(        df('蒼'), qr/^[0-9]{2,}$/ );
like( aozora_df('蒼'), qr/^[0-9]{2,}$/ );

like(        df('走る'), qr/^[0-9]{2,}$/ );
like( aozora_df('走る'), qr/^[0-9]{2,}$/ );

is(          df(''), 0 );
is(   aozora_df(''), 0 );

is(          df('🐶'), 0 );
is(   aozora_df('🐶'), 0 );

is(          df(), undef );
is(   aozora_df(), undef );

is(          df(undef), undef );
is(   aozora_df(undef), undef );

done_testing;
