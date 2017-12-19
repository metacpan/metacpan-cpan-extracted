#!/usr/bin/env perl
# Make sure that we pull in our lookup tables.

use strict;
use warnings;
no warnings 'uninitialized';

use Test::More;
use Test::File::ShareDir -share =>
    { -dist => { 'Lingua-EN-Segment' => 'share' } };

# Pull in the segmenter library.
use_ok('Lingua::EN::Segment');
my $segmenter = Lingua::EN::Segment->new;
isa_ok($segmenter, 'Lingua::EN::Segment');

# We have a list of unigrams.
ok($segmenter->unigrams, 'We have a list of unigrams');
is(ref($segmenter->unigrams), 'HASH', '...a hash');
ok(exists $segmenter->unigrams->{the}, 'the is in the list');
ok(exists $segmenter->unigrams->{baroque}, 'as is baroque');
ok($segmenter->unigrams->{the} > $segmenter->unigrams->{baroque},
	'A common word scores higher than an uncommon word');

# And we're done.
done_testing();
