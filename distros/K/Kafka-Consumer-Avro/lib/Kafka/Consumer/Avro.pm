package Kafka::Consumer::Avro;

=pod

=head1 NAME

Kafka::Consumer::Avro - Avro message consumer for Apache Kafka.

=head1 SYNOPSIS

  use Kafka qw/DEFAULT_MAX_BYTES/;
  use Kafka::Connection;
  use Kafka::Consumer::Avro;
  use Confluent::SchemaRegistry;
  
  my $connection = Kafka::Connection->new( host => 'localhost' );
  
  my $consumer = Kafka::Consumer::Avro->new( Connection => $connection , SchemaRegistry => Confluent::SchemaRegistry->new() );
  
  # Consuming messages
  my $messages = $consumer->fetch(
  	'mytopic',            # topic
  	0,                    # partition
  	0,                    # offset
  	$DEFAULT_MAX_BYTES    # Maximum size of MESSAGE(s) to receive
  );
  
  if ($messages) {
  	foreach my $message (@$messages) {
  		if ( $message->valid ) {
  			say 'payload    : ', $message->payload;
  			say 'key        : ', $message->key;
  			say 'offset     : ', $message->offset;
  			say 'next_offset: ', $message->next_offset;
  		}
  		else {
  			say 'error      : ', $message->error;
  		}
  	}
  }
  
  # Closes the consumer and cleans up
  undef $consumer;
  $connection->close;
  undef $connection;

=head1 DESCRIPTION

C<Kafka::Consumer::Avro> main feature is to provide object-oriented API to 
consume messages according to I<Confluent SchemaRegistry> and I<Avro> serialization.

C<Kafka::Consumer::Avro> inerhits from and extends L<Kafka::Consumer|Kafka::Consumer>.

=cut

use 5.010;
use strict;
use warnings;

use JSON::XS;
use IO::String;

use base 'Kafka::Consumer';

use Avro::BinaryDecoder;
use Avro::Schema;
use Confluent::SchemaRegistry;

use constant MAGIC_BYTE => 0; 

use version; our $VERSION = version->declare('v1.0.0');

=head1 INSTALL

Installation of C<Kafka::Consumer::Avro> is a canonical:

  perl Makefile.PL
  make
  make test
  make install

=head2 TEST NOTES

Tests are focused on verifying Avro-formatted messages and theirs interactions with Confluent Schema Registry and are intended to extend C<Kafka::Consumer> test suite.

They expect that in the target machine are available Kafka and Schema Registry listening on C<localhost> and default ports, otherwise most of the test are skipped.

=head1 USAGE

=head2 CONSTRUCTOR

=head3 C<new>

Creates new consumer client object.

C<new()> takes arguments in key-value pairs as described in L<Kafka::Consumer|Kafka::Consumer> from which it inherits.

In addition, takes in the following arguments:

=over 3

=item C<SchemaRegistry =E<gt> $schema_registry> (B<mandatory>)

Is a L<Confluent::SchemaRegistry|Confluent::SchemaRegistry> instance.

=back

=cut

sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my $schema_registry_class = 'Confluent::SchemaRegistry';
    my %params = @_;

	# Check SchemaRegistry param
    die "Missing SchemaRegistry param"
    	unless exists $params{SchemaRegistry};
    die "SchemaRegistry param must be a $schema_registry_class instance object"
    	unless ref($params{SchemaRegistry}) eq $schema_registry_class;
    my $schema_registry = delete $params{SchemaRegistry};
    
    # Use parent class constructor
	my $self = $class->SUPER::new(%params);
	
	# Add ans internal reference to SchemaRegistry
	$self->{__SCHEMA_REGISTRY} = $schema_registry;
	
	return bless($self, $class);
}



##### Class methods
our $schemas = [];

# Decode from Avro
sub _from_avro {
	my $blob = shift || return undef;
	my $sr = shift || return undef;
	my $reader = IO::String->new( $blob );
	seek( $reader, 1, 0 );    # Skip magic byte
	my $buf = "\0\0\0\0";
	read( $reader, $buf, 4 );    # Read schema version stored in avro message header
	my $schema_id = unpack( "N", $buf ); # Retreive schema id from unsigned long (32 byte)
	unless ( defined $schemas->[$schema_id] ) {
		$schemas->[$schema_id] = $sr->get_schema_by_id( SCHEMA_ID => $schema_id ) || die "Unavailable schema for id $schema_id";
	}
	return Avro::BinaryDecoder->decode(
		writer_schema => $schemas->[$schema_id],
		reader_schema => $schemas->[$schema_id],
		reader        => $reader
	);
}

# Decode key and payload of the innput message returning a new Kafka::Message instancefrom Avro format according to an Avro schema 
sub _decode_message {
	my $message = shift;
	die "Unknown message format"
		unless $message->isa('Kafka::Message');
	my $sr = shift;
	die "Expected Confluent::SchemaRegistry object"
		unless $sr->isa('Confluent::SchemaRegistry');
	return Kafka::Message->new(
		{
			payload				=> _from_avro($message->payload, $sr),
			key					=> _from_avro($message->key, $sr),
			Timestamp			=> $message->Timestamp, 
			valid				=> $message->valid, 
			error				=> $message->error, 
			offset				=> $message->offset, 
			next_offset			=> $message->next_offset, 
			Attributes			=> $message->Attributes, 
			HighwaterMarkOffset	=> $message->HighwaterMarkOffset, 
			MagicByte			=> $message->MagicByte
		}
	);
}


##### Private methods

sub _clear_error { $_[0]->_set_error() } 
sub _set_error   { $_[0]->{__ERROR} = $_[1] } 
sub _get_error   { $_[0]->{__ERROR} }




##### Public methods

=head2 METHODS

The following methods are defined for the C<Kafka::Avro::Consumer> class:

=cut


=head3 C<schema_registry>()

Returns the L<Confluent::SchemaRegistry|Confluent::SchemaRegistry> instance supplied to the construcor.

=cut

sub schema_registry { $_[0]->{__SCHEMA_REGISTRY} }


=head3 C<get_error>()

Returns a string containing last error message.

=cut

sub get_error { $_[0]->_get_error() }


=head3 C<fetch( %params )>

Gets messages froma a Kafka topic.

Please, see L<Kafka::Consumer|Kafka::Consumer-E<gt>fetch()> for more details.

=cut
sub fetch {
	my $self = shift;
	my $messages = $self->SUPER::fetch(@_);
	my $sr = $self->schema_registry();
	foreach my $message (@$messages) {
		$message = _decode_message($message, $sr);
	}
	return $messages;
}



=head1 AUTHOR

Alvaro Livraghi, E<lt>alvarol@cpan.orgE<gt>

=head1 CONTRIBUTE

L<https://github.com/alivraghi/Kafka-Consumer-Avro>

=head1 BUGS

Please use GitHub project link above to report problems or contact authors.

=head1 COPYRIGHT AND LICENSE

Copyright 2018 by Alvaro Livraghi

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
