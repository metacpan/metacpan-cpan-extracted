package HTTP::OAI::ListIdentifiers;

@ISA = qw( HTTP::OAI::PartialList );

use strict;

our $VERSION = '4.09';

sub identifier { shift->item(@_) }

sub start_element
{
	my ($self,$hash, $r) = @_;

	if( $hash->{Depth} == 3 && $hash->{LocalName} eq "header" )
	{
		$self->set_handler(HTTP::OAI::Header->new);
	}

	$self->SUPER::start_element($hash, $r);
}

sub end_element {
	my ($self,$hash, $r) = @_;

	$self->SUPER::end_element($hash);

	# OAI 1.x
	if( $hash->{Depth} == 3 && $hash->{LocalName} eq "identifier" )
	{
		$r->callback(HTTP::OAI::Header->new(
			identifier=>$hash->{Text},
			datestamp=>'0000-00-00',
		));
	}
	elsif( $hash->{Depth} == 3 && $hash->{LocalName} eq "header" )
	{
		$r->callback( $self->get_handler, $self );
		$self->set_handler( undef );
	}
}

1;

__END__

=head1 NAME

HTTP::OAI::ListIdentifiers - Provide access to an OAI ListIdentifiers response

=head1 SYNOPSIS

	my $r = $h->ListIdentifiers;

	while(my $rec = $r->next) {
		print "identifier => ", $rec->identifier, "\n",
		print "datestamp => ", $rec->datestamp, "\n" if $rec->datestamp;
		print "status => ", ($rec->status || 'undef'), "\n";
	}

	die $r->message if $r->is_error;

=head1 METHODS

=over 4

=item $li = new OAI::ListIdentifiers

This constructor method returns a new OAI::ListIdentifiers object.

=item $rec = $li->next

Returns either an L<HTTP::OAI::Header|HTTP::OAI::Header> object, or undef, if there are no more records. Use $rec->is_error to test whether there was an error getting the next record (otherwise things will break).

If -resume was set to false in the Harvest Agent, next may return a string (the resumptionToken).

=item @il = $li->identifier([$idobj])

Returns the identifier list and optionally adds an identifier or resumptionToken, $idobj. Returns an array ref of L<HTTP::OAI::Header|HTTP::OAI::Header>s.

=item $dom = $li->toDOM

Returns a XML::DOM object representing the ListIdentifiers response.

=item $token = $li->resumptionToken([$token])

Returns and optionally sets the L<HTTP::OAI::ResumptionToken|HTTP::OAI::ResumptionToken>.

=back
