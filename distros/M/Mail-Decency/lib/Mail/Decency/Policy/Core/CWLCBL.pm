package Mail::Decency::Policy::Core::CWLCBL;


use Moose;
extends qw/
    Mail::Decency::Policy::Core
/;
with qw/
    Mail::Decency::Core::Meta::Database
/;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Data::Dumper;

=head1 NAME

Mail::Decency::Policy::Core::CWLCBL

=head1 DESCRIPTION

Base class for CWL and CBL. Don't use directly.

=cut

has _handle_on_hit => ( is => 'ro', isa => 'Str' );
has _table_prefix  => ( is => 'ro', isa => 'Str' );
has _use_weight    => ( is => 'ro', isa => 'Bool' );
has _description   => ( is => 'ro', isa => 'Str' );
has use_tables     => ( is => 'rw', isa => 'HashRef[Int]' );


=head1 METHODS

=head2 init

Read config, init tables.

=cut

sub init {
    my ( $self ) = @_;
    
    my %tables_ok = map { ( $_ => 1 ) } qw/ ips domains addresses /;
    my @tables = defined $self->config->{ tables }
        ? @{ $self->config->{ tables } }
        : keys %tables_ok
    ;
    foreach my $table( @tables ) {
        die "Cannot use table '$table', please use only ". join( ", ", sort keys %tables_ok ). "\n"
            unless $tables_ok{ $table }
    }
    
    # set tables
    $self->use_tables( { map { ( $_ => 1 ) } @tables } );

}


=head2 handle

Handle method for CWL or CBL.

=cut

sub handle {
    my ( $self, $server, $attrs_ref ) = @_;
    
    # is answer in cache ?
    my $cache_name = $self->name. "-". $self->cache->hash_to_name( $attrs_ref, qw/
        sender_address
        recipient_address
        client_address
    / );
    if ( defined( my $cached = $self->cache->get( $cache_name ) ) ) {
        $self->cache_and_state( $cache_name, @$cached, $attrs_ref );
    }
    
    # check wheter ip/hostname
    if ( $self->use_tables->{ ips } && ( my $ips_ref = $self->database->get( $self->_table_prefix => ips => {
        recipient_domain => $attrs_ref->{ recipient_domain },
        client_address   => $attrs_ref->{ client_address }
    } ) ) ) {
        $self->cache_and_state( $cache_name => $self->_handle_on_hit, "ip", $attrs_ref );
    }
    
    # look in domain databsae
    if ( $self->use_tables->{ domains } && ( my $domains_ref = $self->database->get( $self->_table_prefix => domains => {
        recipient_domain => $attrs_ref->{ recipient_domain },
        sender_domain    => $attrs_ref->{ sender_domain }
    } ) ) ) {
        $self->cache_and_state( $cache_name => $self->_handle_on_hit, "domain", $attrs_ref );
    }
    
    # look in address databse
    if ( $self->use_tables->{ addresses } && ( my $address_ref = $self->database->get( $self->_table_prefix => addresses => {
        recipient_domain => $attrs_ref->{ recipient_domain },
        sender_address   => $attrs_ref->{ sender_address }
    } ) ) ) {
        $self->cache_and_state( $cache_name => $self->_handle_on_hit, "address", $attrs_ref );
    }
    
    
    # remember cached, if negative ok .. 
    $self->cache_and_state( $cache_name => 'DUNNO', "nohit", $attrs_ref );
    
    return ;
}

=head2 cache_and_state

Do cache and call go_finale_state

=cut

sub cache_and_state {
    my ( $self, $cache_name, $state, $where, $attrs_ref ) = @_;
    
    my $final = $state ne 'DUNNO';
    
    # save back to cache
    if ( $final || $self->config->{ use_negative_cache } ) {
        $self->cache->set( $cache_name => [ $state, $where ] );
    }
    
    $self->logger->debug0( "Got hit in $where: '$attrs_ref->{ sender_address }' -> '$attrs_ref->{ recipient_address }': $state" )
        if $final;
    
    # set final state ..
    $self->go_final_state( $state, "Hit on ". $self->_description ) if $final;
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
