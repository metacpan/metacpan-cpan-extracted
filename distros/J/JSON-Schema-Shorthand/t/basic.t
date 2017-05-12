use strict;
use warnings;

use Test::More;
use Test::Deep;
use JSON;

use JSON::Schema::Shorthand;

sub shorthand_ok {
    $_[0] = js_shorthand($_[0]);
    cmp_deeply @_ or diag explain \@_;
}

open my $sample_fh, 't/corpus/samples.json';

my @tests = @{ from_json( join '', <$sample_fh> ) };

plan tests => scalar @tests;

shorthand_ok( @$_ ) for @tests;

done_testing;

