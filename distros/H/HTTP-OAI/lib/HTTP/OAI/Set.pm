package HTTP::OAI::Set;

@ISA = qw( HTTP::OAI::MemberMixin XML::SAX::Base );

use strict;

our $VERSION = '4.05';

sub setSpec { shift->_elem('setSpec',@_) }
sub setName { shift->_elem('setName',@_) }
sub setDescription { shift->_multi('setDescription',@_) }

sub generate {
	my( $self, $driver ) = @_;

	$driver->start_element( 'set' );
	$driver->data_element( 'setSpec', $self->setSpec );
	$driver->data_element( 'setName', $self->setName );
	for( $self->setDescription ) {
		$_->generate;
	}
	$driver->end_element( 'set' );
}

sub start_element {
	my ($self,$hash,$r) = @_;
	my $elem = lc($hash->{Name});
	if( $elem eq 'setdescription' ) {
		$self->setDescription(my $desc = HTTP::OAI::Metadata->new);
		$self->set_handler($desc);
		$self->{in_desc} = $hash->{Depth};
	}
	$self->SUPER::start_element($hash,$r);
}
sub end_element {
	my ($self,$hash,$r) = @_;
	$self->SUPER::end_element($hash,$r);
	if( $self->{in_desc} )
	{
		if( $self->{in_desc} == $hash->{Depth} )
		{
			$self->set_handler( undef );
		}
	}
	else
	{
		my $elem = $hash->{Name};
		if( $elem =~ /^setSpec|setName$/ )
		{
			$self->$elem( $hash->{Text} );
		}
	}
}

1;

__END__

=head1 NAME

HTTP::OAI::Set - Encapsulates OAI set XML data

=head1 METHODS

=over 4

=item $spec = $s->setSpec([$spec])

=item $name = $s->setName([$name])

These methods return respectively, the setSpec and setName of the OAI Set.

=item @descs = $s->setDescription([$desc])

Returns and optionally adds the list of set descriptions. Returns a reference to an array of L<HTTP::OAI::Description|HTTP::OAI::Description> objects.

=back
