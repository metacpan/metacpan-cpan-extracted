package TestPolicy;

use strict;
use TestMisc;
use Mail::Decency::Policy;

sub create {
    return TestMisc::create_server(
        'Mail::Decency::Policy', 'policy' );
}

sub get_config {
    my ( $name, $policy ) = @_;
    foreach my $ref( @{ $policy->config->{ policy } } ) {
        my ( $pname, $config_ref ) = %$ref;
        if ( $name eq $pname ) {
            return $config_ref;
        }
    }
}

sub session_init {
    my ( $policy, $attrs_ref ) = @_;
    $attrs_ref ||= {};
    
    my %default_attr = (
        recipient      => $attrs_ref->{ recipient_address } || 'recipient@default.tld',
        sender         => $attrs_ref->{ sender_address } || 'sender@default.tld',
        client_address => '255.255.255.254',
    );
    my %attrs = ( %default_attr, %$attrs_ref );
    
    $policy->session_init( \%attrs );
}

1;
