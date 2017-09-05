package HTTP::OAI::ListMetadataFormats;

@ISA = qw( HTTP::OAI::PartialList );

use strict;

our $VERSION = '4.06';

sub metadataFormat { shift->item(@_) }

sub start_element {
	my ($self,$hash,$r) = @_;
	if( !$self->{'in_mdf'} ) {
		if( lc($hash->{LocalName}) eq 'metadataformat' ) {
			$self->set_handler(my $mdf = HTTP::OAI::MetadataFormat->new);
			$self->metadataFormat($mdf);
			$self->{'in_mdf'} = $hash->{Depth};
		}
	}
	$self->SUPER::start_element($hash,$r);
}

sub end_element {
	my ($self,$hash,$r) = @_;
	$self->SUPER::end_element($hash,$r);
	if( $self->{'in_mdf'} == $hash->{Depth} ) {
		if( lc($hash->{LocalName}) eq 'metadataformat' ) {
HTTP::OAI::Debug::trace( "metadataFormat: " . $self->get_handler->metadataPrefix );
			$self->set_handler( undef );
			$self->{'in_mdf'} = 0;
		}
	}
}

1;

__END__

=head1 NAME

HTTP::OAI::ListMetadataFormats - Provide access to an OAI ListMetadataFormats response

=head1 SYNOPSIS

	my $r = $h->ListMetadataFormats;

	# ListMetadataFormats doesn't use flow control
	while( my $rec = $r->next ) {
		print $rec->metadataPrefix, "\n";
	}

	die $r->message if $r->is_error;

=head1 METHODS

=over 4

=item $lmdf = new HTTP::OAI::ListMetadataFormats

This constructor method returns a new HTTP::OAI::ListMetadataFormats object.

=item $mdf = $lmdf->next

Returns either an L<HTTP::OAI::MetadataFormat|HTTP::OAI::MetadataFormat> object, or undef, if no more records are available.

=item @mdfl = $lmdf->metadataFormat([$mdf])

Returns the metadataFormat list and optionally adds a new metadataFormat, $mdf. Returns an array ref of L<HTTP::OAI::MetadataFormat|HTTP::OAI::MetadataFormat>s.

=item $dom = $lmdf->toDOM

Returns a XML::DOM object representing the ListMetadataFormats response.

=back
