package Mail::Decency::Policy::CWL;

use Moose;
extends 'Mail::Decency::Policy::Core::CWLCBL';

use version 0.74; our $VERSION = qv( "v0.1.4" );

use mro 'c3';

use Data::Dumper;

=head1 NAME

Mail::Decency::Policy::CWL


=head1 CONFIG

    ---
    
    disable: 0
    
    # enable negative cache
    use_negative_cache: 1
    
    # enable all tables
    tables:
        - ips
        - domains
        - addresses
    

=head1 DESCRIPTION

Implementation of a custom whitelist based on sending server (ip/hostname), sending domain or (domain.tld) sending address (email@domain.tld).

=head1 DATABASE

    CREATE TABLE cwl_ips (
        id INTEGER PRIMARY KEY,
        recipient_domain varchar( 255 ),
        client_address varchar( 39 )
    );
    CREATE UNIQUE INDEX cwl_ips_uk ON cwl_ips( recipient_domain, client_address );
    
    CREATE TABLE cwl_domains (
        id INTEGER PRIMARY KEY,
        recipient_domain varchar( 255 ),
        sender_domain varchar( 255 )
    );
    CREATE UNIQUE INDEX cwl_domains_uk ON cwl_domains( recipient_domain, sender_domain );
    
    CREATE TABLE cwl_addresses (
        id INTEGER PRIMARY KEY,
        recipient_domain varchar( 255 ),
        sender_address varchar( 255 )
    );
    CREATE UNIQUE INDEX cwl_addresses_uk ON cwl_addresses( recipient_domain, sender_address );

=cut

=head1 CLASS ATTRIBUTES

=cut

has schema_definition => ( is => 'ro', isa => 'HashRef[HashRef]', default => sub {
    {
        cwl => {
            ips         => {
                recipient_domain => [ varchar => 255 ],
                client_address   => [ varchar => 39 ],
                -unique          => [ 'recipient_domain', 'client_address' ]
            },
            domains     => {
                recipient_domain => [ varchar => 255 ],
                sender_domain    => [ varchar => 255 ],
                -unique          => [ 'recipient_domain', 'sender_domain' ]
            },
            addresses   => {
                recipient_domain => [ varchar => 255 ],
                sender_address   => [ varchar => 255 ],
                -unique          => [ 'recipient_domain', 'sender_address' ]
            },
        }
    };
} );


=head1 METHODS


=head2 init

=cut

sub init {
    my ( $self ) = @_;
    
    $self->next::method();
    $self->{ _handle_on_hit } = 'OK';
    $self->{ _table_prefix }  = 'cwl';
    $self->{ _description }   = 'Custom White List';
    
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut



1;
