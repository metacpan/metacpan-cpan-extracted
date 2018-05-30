package HTTP::OAI::MetadataFormat;

@ISA = qw( HTTP::OAI::MemberMixin XML::SAX::Base );

use strict;

our $VERSION = '4.07';

sub metadataPrefix { shift->_elem('metadataPrefix',@_) }
sub schema { shift->_elem('schema',@_) }
sub metadataNamespace { shift->_elem('metadataNamespace',@_) }

sub generate
{
	my( $self, $driver ) = @_;

	$driver->start_element('metadataFormat');
	$driver->data_element('metadataPrefix',$self->metadataPrefix);
	$driver->data_element('schema',$self->schema);
	if( defined($self->metadataNamespace) )
	{
		$driver->data_element('metadataNamespace',$self->metadataNamespace);
	}
	$driver->end_element('metadataFormat');
}

sub end_element {
	my ($self,$hash) = @_;
	$self->SUPER::end_element($hash);
	my $elem = lc($hash->{LocalName});
	if( defined $hash->{Text} )
	{
		$hash->{Text} =~ s/^\s+//;
		$hash->{Text} =~ s/\s+$//;
	}
	if( $elem eq 'metadataprefix' ) {
		$self->metadataPrefix($hash->{Text});
	} elsif( $elem eq 'schema' ) {
		$self->schema($hash->{Text});
	} elsif( $elem eq 'metadatanamespace' ) {
		$self->metadataNamespace($hash->{Text});
	}
}

1;

__END__

=head1 NAME

HTTP::OAI::MetadataFormat - Encapsulates OAI metadataFormat XML data

=head1 METHODS

=over 4

=item $mdf = new HTTP::OAI::MetadataFormat

This constructor method returns a new HTTP::OAI::MetadataFormat object.

=item $mdp = $mdf->metadataPrefix([$mdp])

=item $schema = $mdf->schema([$schema])

=item $ns = $mdf->metadataNamespace([$ns])

These methods respectively return and optionally set the metadataPrefix, schema and, metadataNamespace, for the metadataFormat record.

metadataNamespace is optional in OAI 1.x and therefore may be undef when harvesting pre OAI 2 repositories.

=back
