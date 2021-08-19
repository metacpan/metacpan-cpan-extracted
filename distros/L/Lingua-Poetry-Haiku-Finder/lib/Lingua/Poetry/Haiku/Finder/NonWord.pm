use 5.012;
use strict;
use warnings;

package Lingua::Poetry::Haiku::Finder::NonWord;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moo;
use Types::Standard -types;
use namespace::autoclean;

has text => (
	is        => 'ro',
	isa       => Str,
	required  => !!1,
);

sub syllables {
	return 0;
}

sub is_word { !!0 }

with 'Lingua::Poetry::Haiku::Finder::SentencePart';

1;
