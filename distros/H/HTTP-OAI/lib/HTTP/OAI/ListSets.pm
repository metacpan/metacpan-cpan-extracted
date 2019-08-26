package HTTP::OAI::ListSets;

@ISA = qw( HTTP::OAI::PartialList );

use strict;

our $VERSION = '4.09';

sub set { shift->item(@_) }

sub start_element
{
	my ($self,$hash, $r) = @_;

	if( $hash->{Depth} == 3 && $hash->{LocalName} eq "set" )
	{
		$self->set_handler(HTTP::OAI::Set->new);
	}

	$self->SUPER::start_element($hash, $r);
}

sub end_element
{
	my ($self,$hash, $r) = @_;

	$self->SUPER::end_element($hash, $r);

	if( $hash->{Depth} == 3 && $hash->{LocalName} eq "set" )
	{
		$r->callback( $self->get_handler, $self );
		$self->set_handler( undef );
	}
}

1;

__END__

=head1 NAME

HTTP::OAI::ListSets - Provide access to an OAI ListSets response

=head1 SYNOPSIS

	my $r = $h->ListSets();

	while( my $rec = $r->next ) {
		print $rec->setSpec, "\n";
	}

	die $r->message if $r->is_error;

=head1 METHODS

=over 4

=item $ls = new HTTP::OAI::ListSets

This constructor method returns a new OAI::ListSets object.

=item $set = $ls->next

Returns either an L<HTTP::OAI::Set|HTTP::OAI::Set> object, or undef, if no more records are available. Use $set->is_error to test whether there was an error getting the next record.

If -resume was set to false in the Harvest Agent, next may return a string (the resumptionToken).

=item @setl = $ls->set([$set])

Returns the set list and optionally adds a new set or resumptionToken, $set. Returns an array ref of L<HTTP::OAI::Set|HTTP::OAI::Set>s, with an optional resumptionToken string.

=item $token = $ls->resumptionToken([$token])

Returns and optionally sets the L<HTTP::OAI::ResumptionToken|HTTP::OAI::ResumptionToken>.

=item $dom = $ls->toDOM

Returns a XML::DOM object representing the ListSets response.

=back
