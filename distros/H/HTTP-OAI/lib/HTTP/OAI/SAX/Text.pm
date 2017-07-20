package HTTP::OAI::SAX::Text;

@ISA = qw( XML::SAX::Base );

use strict;

our $VERSION = '4.05';

sub start_element
{
	( my $self, my $hash, @_ ) = @_;

	$self->{Data} = "";
	push @{$self->{Attributes}}, $hash->{Attributes};

	$self->SUPER::start_element( $hash, @_ );
}

sub characters { $_[0]->{Data} .= $_[1]->{Data} }

sub end_element
{
	( my $self, my $hash, @_ ) = @_;

	$hash->{Text} = $self->{Data};
	$hash->{Attributes} = pop @{$self->{Attributes} || []};

	# strip surrounding whitespace in leaf nodes
	$hash->{Text} =~ s/^\s+//;
	$hash->{Text} =~ s/\s+$//;

	$self->SUPER::characters( {Data => $self->{Data}}, @_ );

	$self->{Data} = "";

	$self->SUPER::end_element( $hash, @_ );
}

1;

=head1 NAME

HTTP::OAI::SAX::Text

=head1 DESCRIPTION

This module adds Text and Attributes to the end_element call. This is only useful for leaf nodes (elements that don't contain any child elements).
