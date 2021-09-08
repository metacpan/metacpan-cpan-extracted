use 5.012;
use strict;
use warnings;

package Lingua::Poetry::Haiku::Finder;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Moo;
use Types::Standard -types;
use List::Util 'sum0';
use Lingua::Sentence;
use namespace::autoclean;

use Lingua::Poetry::Haiku::Finder::Sentence;

my @LINE_LENGTHS = ( 5, 7, 5 );
my $HAIKU_LENGTH = sum0 @LINE_LENGTHS;

has text => (
	is        => 'ro',
	isa       => Str,
	required  => !!1,
);

has sentences => (
	is        => 'lazy',
	isa       => ArrayRef[ InstanceOf[ __PACKAGE__ . '::Sentence' ] ],
	init_arg  => undef,
);

has haikus => (
	is        => 'lazy',
	isa       => ArrayRef[ Str ],
	init_arg  => undef,
);

has _splitter => (
	is        => 'lazy',
	isa       => Object,
	builder   => sub { 'Lingua::Sentence'->new("en") },
	handles   => {
		'_split_array' => 'split_array',
	},
);

{
	my $class = __PACKAGE__ . '::Sentence';
	
	sub _build_sentences {
		my ( $self ) = ( shift );
		
		my $text = $self->text;
		$text =~ s/\s+/ /sg;
		$text =~ s/^\s+//s;
		$text =~ s/\s+$//s;
		
		return [
			map $class->new( text => $_ ), $self->_split_array( $text )
		];
	}
}

sub _format_haiku {
	my ( $self, $sentences ) = ( shift, @_ );
	my @parts = map {
		my $end = ( __PACKAGE__ . '::NonWord' )->new( text => ' ' );
		@{ $_->parts }, $end;
	} @{ $sentences };
	
	my @lines;
	my $current_line = 0;
	
	while ( @parts ) {
		my $part = shift @parts;
		if ( $part->is_word ) {
			my $current_line_length = sum0 map $_->syllables, @{ $lines[$current_line] || [] };
			if ( $current_line_length >= $LINE_LENGTHS[$current_line] ) {
				++$current_line;
			}
		}
		push @{ $lines[$current_line] ||= [] }, $part;
	}
	
	return join "\n", map {
		my @line = @$_;
		my $text = join "", map $_->text, @line;
		$text =~ s/\s+/ /sg;
		$text =~ s/^\s+//s;
		$text =~ s/\s+$//s;
		$text;
	} @lines;
}

sub _build_haikus {
	my ( $self ) = ( shift );
	
	my @sentences = @{ $self->sentences };
	my @found;
	STARTER: for my $start_index ( 0 .. $#sentences ) {
		ENDER: for my $end_index ( $start_index .. $#sentences ) {
			my @slice = @sentences[ $start_index .. $end_index ];
			my $slice_syllables = sum0 map $_->syllables, @slice;
			
			if ( $slice_syllables == $HAIKU_LENGTH ) {
				push @found, $self->_format_haiku( \@slice );
			}
			elsif ( $slice_syllables > $HAIKU_LENGTH ) {
				next STARTER;
			}
		}
	}
	
	return \@found;
}

sub from_text {
	my ( $class, $text ) = ( shift, @_ );
	return $class->new( text => $text );
}

sub from_filehandle {
	my ( $class, $fh ) = ( shift, @_ );
	my $text = do { local $/; <$fh> };
	return $class->from_text( $text );
}

sub from_filename {
	my ( $class, $filename ) = ( shift, @_ );
	open my $fh, '<', $filename or die "Cannot open $filename: $!";
	return $class->from_filehandle( $fh );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lingua::Poetry::Haiku::Finder - find poetry in the least poetic places

=head1 SYNOPSIS

  use Lingua::Poetry::Haiku::Finder;
  
  my $finder = 'Lingua::Poetry::Haiku::Finder'->from_filename(
    '/usr/share/common-licenses/GPL-2'
  );
  
  for my $poem ( @{ $finder->haikus } ) {
    print "$poem\n\n";
  }

=head1 DESCRIPTION

This module will scan a string (which may be read from a file) for consecutive
sentences which sound like haikus.

It uses L<Lingua::EN::Syllable>, which provides imperfect syllable counts, so
they may not always work. It will also occasionally split lines as 6/7/4 or
similar, to avoid hyphenating a word and splitting it onto multiple lines.

=head2 Constructors

=over

=item C<< from_text( $string ) >>

=item C<< from_filehandle( $ref ) >>

=item C<< from_filename( $string ) >>

=back

=head2 Methods

=over

=item C<< haikus >>

Returns an arrayref of strings, each string being one haiku. Lines of each
haiku are joined using "\n".

=back

There are other methods and helper classes, but you probably don't need to
know about them.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Lingua-Poetry-Haiku-Finder>.

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Black_Perl>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
