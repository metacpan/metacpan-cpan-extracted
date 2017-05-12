package Logfile::EPrints::Parser::OAI;

=head1 NAME

Logfile::EPrints::Parser::OAI - Parse hits from an OAI-PMH interface

=head1 METHODS

=over 4

=cut

use strict;
use warnings;

use HTTP::OAI;

=item new( baseURL => <baseURL>, handler => <handler> )

Create a new object to query <baseURL>

=cut

sub new
{
	my( $class, %args ) = @_;
	bless \%args, $class;
}

sub baseurl { shift->{ baseURL }}
sub agent { shift->{ agent }}
sub response { shift->{ response }}

=item $h->harvest(@opts)

Harvest all records from the OAI server, @opts are any OAI arguments (e.g. use 'from' to specify a datestamp to start from). Defaults to using 'context_object' as the metadata prefix.

The service type given is called on the handler (abstract, citation, fulltext etc.).

=cut

sub harvest
{
	my $self = shift;
	my $handler = $self->{ handler } or return;
	my $h = $self->{ agent } = HTTP::OAI::Harvester->new( baseURL => $self->baseurl );
	my $r = $self->{ response } = $h->ListRecords(
		metadataPrefix => 'context_object',
		handlers => {
			metadata => 'Logfile::EPrints::Hit::ContextObject'
		},
		@_,
	);
	die $r->message unless $r->is_success;
	while(my $rec = $r->next)
	{
		my $hit = $rec->metadata;
		my $f = $hit->{ svc };
		$handler->$f( $hit );
	}
	die $r->message unless $r->is_success;
}

=back

=cut

package Logfile::EPrints::Hit::ContextObject;

use strict;
use warnings;

use Data::Dumper;
use Carp;
use HTTP::OAI::Metadata;
use Logfile::EPrints::Hit;
use vars qw( @ISA );
@ISA = qw( HTTP::OAI::Metadata Logfile::EPrints::Hit::Combined );

sub new
{
	return bless {entity => ''}, shift;
}
sub entity { shift->{ 'entity' }};
sub service { shift->{ 'svc' }};

# Logfile accessors
sub date { shift->{ 'date' }};
sub agent { shift->{ 'requester' }->{ 'private-data' }};
sub identifier { shift->{ 'referent' }->{ 'identifier' }}

sub address
{
	substr(shift->{ 'requester' }->{ 'identifier' },7); # strip urn:ip:
}

sub start_element
{
	my( $self, $hash ) = @_;
	my $n = $hash->{ LocalName };
	if( $n eq 'context-object' )
	{
		$self->{ date } = $hash->{ Attributes }->{ '{}timestamp' }->{ Value };
	}
	elsif( $n =~ /^referent|referring-entity|requester|service-type$/ )
	{
		$self->{ 'entity' } = $n;
	}
	elsif( $n eq 'svc-list' )
	{
		$self->{ 'in_svc' } = 1;
	}
}

sub end_element
{
	my( $self, $hash ) = @_;
	my $n = $hash->{ LocalName };
	if( $n eq $self->entity )
	{
		$self->{ 'entity' } = '';
		return;
	}
	if( $n =~ /^identifier|private-data$/ )
	{
		$self->{$self->entity}->{$n} = $hash->{ Text };
	}
	elsif( 'svc-list' eq $n )
	{
		$self->{ 'in_svc' } = 0;
	}
	elsif( $self->{ 'in_svc' } )
	{
		$self->{ 'svc' } = $n if $hash->{ Text } eq 'yes';
	}
}

sub end_document
{
}

1;
