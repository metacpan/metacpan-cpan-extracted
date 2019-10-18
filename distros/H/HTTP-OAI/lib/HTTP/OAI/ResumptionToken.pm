package HTTP::OAI::ResumptionToken;

@ISA = qw( HTTP::OAI::MemberMixin XML::SAX::Base );

use strict;

use overload "bool" => \&not_empty;

our $VERSION = '4.10';

sub resumptionToken { shift->_elem('resumptionToken',@_) }
sub expirationDate { shift->_elem('expirationDate',@_) }
sub completeListSize { shift->_elem('completeListSize',@_) }
sub cursor { shift->_elem('cursor',@_) }

sub not_empty { defined($_[0]->resumptionToken) and length($_[0]->resumptionToken) > 0 }
sub is_empty { !not_empty(@_) }

sub generate {
	my( $self, $driver ) = @_;

	$driver->data_element( 'resumptionToken', $self->resumptionToken,
		expirationDate => scalar($self->expirationDate),
		completeListSize => scalar($self->completeListSize),
		cursor => scalar($self->cursor),
	);
}

sub end_element {
	my ($self,$hash) = @_;
	$self->SUPER::end_element($hash);
	if( lc($hash->{LocalName}) eq 'resumptiontoken' ) {
		$self->resumptionToken($hash->{Text});

		my $attr = $hash->{Attributes};
		$self->expirationDate($attr->{'{}expirationDate'}->{'Value'});
		$self->completeListSize($attr->{'{}completeListSize'}->{'Value'});
		$self->cursor($attr->{'{}cursor'}->{'Value'});
	}
}

1;

__END__

=head1 NAME

HTTP::OAI::ResumptionToken - Encapsulates an OAI resumption token

=head1 METHODS

=over 4

=item $rt = new HTTP::OAI::ResumptionToken

This constructor method returns a new HTTP::OAI::ResumptionToken object.

=item $token = $rt->resumptionToken([$token])

Returns and optionally sets the resumption token string.

=item $ed = $rt->expirationDate([$rt])

Returns and optionally sets the expiration date of the resumption token.

=item $cls = $rt->completeListSize([$cls])

Returns and optionally sets the cardinality of the result set.

=item $cur = $rt->cursor([$cur])

Returns and optionally sets the index of the first record (of the current page) in the result set.

=back

=head1 NOTE - Completing incomplete list

The final page of a record list which has been split using resumption tokens must contain an empty resumption token.
