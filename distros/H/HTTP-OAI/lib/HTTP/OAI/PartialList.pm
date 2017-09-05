package HTTP::OAI::PartialList;

@ISA = qw( HTTP::OAI::Verb );

use strict;

our $VERSION = '4.06';

sub resumptionToken { shift->_elem('resumptionToken',@_) }

sub item { shift->_multi('item',@_) }

sub next
{
	my( $self ) = @_;

	return shift @{$self->{item}};
}

sub generate_body
{
	my( $self, $driver ) = @_;

	for($self->item)
	{
		$_->generate( $driver );
	}
	if(my $token = $self->resumptionToken)
	{
		$token->generate( $driver );
	}
}

sub start_element
{
	my ($self, $hash, $r) = @_;

	if( $hash->{Depth} == 3 && $hash->{LocalName} eq "resumptionToken" )
	{
		$self->set_handler(HTTP::OAI::ResumptionToken->new);
	}

	$self->SUPER::start_element( $hash, $r );
}

sub end_element
{
	my ($self, $hash, $r) = @_;

	$self->SUPER::end_element( $hash, $r );

	if( $hash->{Depth} == 3 && $hash->{LocalName} eq "resumptionToken" )
	{
		$self->resumptionToken( $self->get_handler );
		$self->set_handler( undef );
	}
}

1;
