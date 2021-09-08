use 5.012;
use strict;
use warnings;

package Lingua::Poetry::Haiku::Finder::Word;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Moo;
use Types::Standard -types;
use Lingua::EN::Syllable 'syllable';
use Lingua::EN::Numbers 'num2en';
use namespace::autoclean;

has text => (
	is        => 'ro',
	isa       => Str,
	required  => !!1,
);

has syllables => (
	is        => 'lazy',
	isa       => Int,
	init_arg  => undef,
);

sub _build_syllables {
	my ( $self ) = ( shift );
	my @parts = split /-/, $self->text;
	my $sum   = 0;
	while ( @parts ) {
		my $part = shift @parts;
		if ( $part =~ /^(16|17|18|19|20)([1-9][0-9])$/ ) {
			# looks like a year
			unshift @parts, $1, $2;
		}
		elsif ( $part =~ /^(16|17|18|19)0([1-9])$/ ) {
			# also looks like a year
			unshift @parts, $1, 'oh', $2;
		}
		elsif ( $part =~ /^[0-9]+$/ ) {
			# numbers in general
			unshift @parts, split / /, num2en( $part );
		}
		else {
			$sum += syllable( $part );
		}
	}
	return $sum;
}

sub is_word { !!1 }

with 'Lingua::Poetry::Haiku::Finder::SentencePart';

1;
