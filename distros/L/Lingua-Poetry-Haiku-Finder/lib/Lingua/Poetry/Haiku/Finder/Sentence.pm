use 5.012;
use strict;
use warnings;

package Lingua::Poetry::Haiku::Finder::Sentence;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moo;
use Types::Standard -types;
use List::Util 'sum0';
use namespace::autoclean;

use Lingua::Poetry::Haiku::Finder::SentencePart;
use Lingua::Poetry::Haiku::Finder::Word;
use Lingua::Poetry::Haiku::Finder::NonWord;

has text => (
	is        => 'ro',
	isa       => Str,
	required  => !!1,
);

has parts => (
	is        => 'lazy',
	isa       => ArrayRef[ ConsumerOf[ __PACKAGE__ . 'Part' ] ],
	init_arg  => undef,
);

has syllables => (
	is        => 'lazy',
	isa       => Int,
	init_arg  => undef,
);

sub _build_parts {
	my ( $self ) = ( shift );
	return [ $self->_find_parts( $self->text ) ];
}

{
	( my $class = __PACKAGE__ ) =~ s/::Sentence/::Word/;
	
	sub _found_word {
		my ( $self, $text ) = ( shift, @_ );
		return $class->new( text => $text );
	}
}

{
	( my $class = __PACKAGE__ ) =~ s/::Sentence/::NonWord/;
	
	sub _found_nonword {
		my ( $self, $text ) = ( shift, @_ );
		return $class->new( text => $text );
	}
}

sub _find_parts {
	my ( $self, $text ) = ( shift, @_ );
	my @parts;
	
	local $_ = $text;
	s/\s+/ /sg;
	s/^\s+//s;
	s/\s+$//s;
	
	while ( length ) {
		if ( /^([^_\W][\w-]*)/ ) {
			my $word = $1;
			substr( $_, 0, length $word ) = '';
			push @parts, $self->_found_word( $word );
		}
		elsif ( /^([_\W]*)/ ) {
			my $nonword = $1;
			substr( $_, 0, length $nonword ) = '';
			if ( $nonword =~ /^(\S+)(\s+.+)$/ ) {
				my ( $first, $second) = ( $1, $2 );
				push @parts, $self->_found_nonword( $first ), $self->_found_nonword( $second );
			}
			else {
				push @parts, $self->_found_nonword( $nonword );
			}
		}
		else {
			die 'Unexpected!';
		}
	}
	
	return @parts;
}

sub _build_syllables {
	my ( $self ) = ( shift );
	return sum0 map $_->syllables, @{ $self->parts };
}

1;
