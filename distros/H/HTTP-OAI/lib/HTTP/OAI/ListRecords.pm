package HTTP::OAI::ListRecords;

@ISA = qw( HTTP::OAI::PartialList );

use strict;

our $VERSION = '4.06';

sub record { shift->item(@_) }

sub start_element
{
	my ($self,$hash, $r) = @_;

	if( $hash->{Depth} == 3 && $hash->{LocalName} eq "record" )
	{
		$self->set_handler(HTTP::OAI::Record->new);
	}

	$self->SUPER::start_element($hash, $r);
}

sub end_element
{
	my ($self,$hash, $r) = @_;

	$self->SUPER::end_element($hash, $r);

	if( $hash->{Depth} == 3 && $hash->{LocalName} eq "record" )
	{
HTTP::OAI::Debug::trace( "record: " . $self->get_handler->identifier );
		$r->callback( $self->get_handler, $self );
		$self->set_handler( undef );
	}
}

1;

__END__

=head1 NAME

HTTP::OAI::ListRecords - Provide access to an OAI ListRecords response

=head1 SYNOPSIS

	my $r = $h->ListRecords(
		metadataPrefix=>'oai_dc',
	);

	while( my $rec = $r->next ) {
		print "Identifier => ", $rec->identifier, "\n";
	}

	die $r->message if $r->is_error;

	# Using callback method
	sub callback {
		my $rec = shift;
		print "Identifier => ", $rec->identifier, "\n";
	};
	my $r = $h->ListRecords(
		metadataPrefix=>'oai_dc',
		onRecord=>\&callback
	);
	die $r->message if $r->is_error;

=head1 METHODS

=over 4

=item $lr = new HTTP::OAI::ListRecords

This constructor method returns a new HTTP::OAI::ListRecords object.

=item $rec = $lr->next

Returns either an L<HTTP::OAI::Record|HTTP::OAI::Record> object, or undef, if no more record are available. Use $rec->is_error to test whether there was an error getting the next record.

=item @recl = $lr->record([$rec])

Returns the record list and optionally adds a new record or resumptionToken, $rec. Returns an array ref of L<HTTP::OAI::Record|HTTP::OAI::Record>s, including an optional resumptionToken string.

=item $token = $lr->resumptionToken([$token])

Returns and optionally sets the L<HTTP::OAI::ResumptionToken|HTTP::OAI::ResumptionToken>.

=item $dom = $lr->toDOM

Returns a XML::DOM object representing the ListRecords response.

=back
