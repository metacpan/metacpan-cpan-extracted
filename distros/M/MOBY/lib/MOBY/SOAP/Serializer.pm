#$Id: Serializer.pm,v 1.2 2008/08/25 15:21:01 kawas Exp $
package MOBY::SOAP::Serializer;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

# this module serializes SOAP messages to ensure
# compatibility with other soap clients (Java)
# All that you have to do to make this your serializer,
# is to uncomment, from MOBY-Central.pl, the line:
#
# 	$x->serializer(MOBY::SOAP::Serializer->new);
#
# and all soap messages will pass through this serializer.
#
# 	MAKE SURE TO 'use MOBY::SOAP::Serializer;'
#
# This ensures that mobycentral is compatible with
# SOAP-lite version >= .6
@MOBY::SOAP::Serializer::ISA = 'SOAP::Serializer';

sub xmlize {
	my $self = shift;
	my ( $name, $attrs, $values, $id ) = @{ +shift };
	$attrs ||= {};
	return $self->SUPER::xmlize( [ $name, $attrs, $values, $id ] );
}

sub envelope {

#	delete $_[0]{_namespaces}->{'http://schemas.xmlsoap.org/soap/encoding/'}
#	  if $_[0];

	# only 'transform' soap responses
	UNIVERSAL::isa( $_[3] => 'SOAP::Data' )
	  ? do {
		# when we set to string, we dont have to encode
		$_[3]->type( 'string' => $_[3]->value() );
	  }

	  : do {
		do {

			# for dumps, they are of type string[]: set components accordingly
			$_[3]->[0] = SOAP::Data->type( 'string' => $_[3]->[0] )
			  if $_[3]->[0];
			$_[3]->[1] = SOAP::Data->type( 'string' => $_[3]->[1] )
			  if $_[3]->[1];
			$_[3]->[2] = SOAP::Data->type( 'string' => $_[3]->[2] )
			  if $_[3]->[2];
			$_[3]->[3] = SOAP::Data->type( 'string' => $_[3]->[3] )
			  if $_[3]->[3];
			$_[3]->[4] = SOAP::Data->type( 'string' => $_[3]->[4] )
			  if $_[3]->[4];
		} if ( ref( $_[3] ) eq 'ARRAY' );
		do {

			# below encodes data -> set type to string and we dont have to
			# set to string to avoid encoding
			$_[3] = SOAP::Data->type( 'string' => $_[3] );
		} unless ( ref( $_[3] ) eq 'ARRAY' );
	  } if $_[1] =~ /^(?:method|response)$/;

	$_[2] = (
			  UNIVERSAL::isa( $_[2] => 'SOAP::Data' )
			  ? $_[2]
			  : SOAP::Data->name( $_[2] )->attr( { xmlns => $uri } )
	  )
	  if $_[1] =~ /^(?:method|response)$/;

	shift->SUPER::envelope(@_);
}

1;
