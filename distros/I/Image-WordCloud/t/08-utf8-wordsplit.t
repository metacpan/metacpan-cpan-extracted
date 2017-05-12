#!perl

use strict;
use warnings;
use Test::More tests => 2;
use Image::WordCloud;

my $words = 'Président Présidents';

my $wc = Image::WordCloud->new()->words($words);

is(scalar(keys %{$wc->{words}}), 2, "Words with accents characters are not being split apart");

$words = 'Président president blah grußer';
$wc = Image::WordCloud->new()->words($words);

is(scalar(keys %{$wc->{words}}), 4, "Words with accents characters are not being split apart");