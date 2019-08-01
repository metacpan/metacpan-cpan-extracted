package Device::Firewall::PaloAlto;
$Device::Firewall::PaloAlto::VERSION = '0.1.9';
use strict;
use warnings;
use 5.010;

use parent qw(
    Exporter
    Device::Firewall::PaloAlto::API
);

# If we're in a one-liner, we export the 'fw()' sub which returns
# an object. This shortens the one liners.
our @EXPORT;
push @EXPORT, 'fw' if (caller())[1] eq '-e';

use Hook::LexWrap;

use Device::Firewall::PaloAlto::Errors qw(ERROR);
use Device::Firewall::PaloAlto::Op;
use Device::Firewall::PaloAlto::UserID;
use Device::Firewall::PaloAlto::Test;

# VERSION
# PODNAME
# ABSTRACT: Interact with the Palo Alto firewall API


sub fw {
    my ($user, $pass, $verify) = @_;
    $verify //= 0;
    return Device::Firewall::PaloAlto::new->(
        __PACKAGE__,
        username => $user,
        password => $pass,
        verify_hostname => $verify
    )->auth;
}


sub new {
    my $class = shift;
    my %args = @_;

    my %object;
    my @args_keys = qw(uri username password);

    @object{ @args_keys } = @args{ @args_keys };

    $object{uri} //= $ENV{PA_FW_URI} or return ERROR('No uri specified and no environment variable PA_FW_URI found');
    $object{username} //= $ENV{PA_FW_USERNAME} // 'admin';
    $object{password} //= $ENV{PA_FW_PASSWORD} // 'admin';

    $args{verify_hostname} //= 1;
    my $ssl_opts = { verify_hostname => $args{verify_hostname} };


    my $uri = URI->new($object{uri});
    if (!($uri->scheme eq 'http' or $uri->scheme eq 'https')) {
        return ERROR('URI scheme is neither \'http\' nor \'https\'');
    }

    $uri->path('/api/');

    my $ua = LWP::UserAgent->new(ssl_opts => $ssl_opts);
    $ua->env_proxy();

    $object{uri} = $uri;
    $object{user_agent} = $ua;
    $object{api_key} = '';
    $object{active_vsys_id} = 1;

    return bless \%object, $class;
}




sub auth {
    my $self = shift;

    my $response = $self->_send_request(
        type => 'keygen',
        user => $self->{username},
        password => $self->{password}
    );

    # Return the Class::Error
    return $response unless $response;

    $self->{api_key} = $response->{result}{key};

    return $self;
}


sub debug {
    my $self = shift;

    return $self if $self->{wrap};

    $self->{wrap} = wrap 'Device::Firewall::PaloAlto::API::_send_raw_request',
        pre => \&Device::Firewall::PaloAlto::API::_debug_pre_wrap,
        post => \&Device::Firewall::PaloAlto::API::_debug_post_wrap;

    return $self;
}


sub undebug {
    my $self = shift;
    $self->{wrap} = undef;

    return $self;
}


sub op {
    my $self = shift;

    return Device::Firewall::PaloAlto::Op->new($self);
}


sub user_id {  
    my $self = shift;
    return Device::Firewall::PaloAlto::UserID->_new($self);
}


sub test {
    my $self = shift;
    return Device::Firewall::PaloAlto::Test->new($self);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto - Interact with the Palo Alto firewall API

=head1 VERSION

version 0.1.9

=head1 SYNOPSIS

    use Device::Firewall::PaloAlto;

    # Constructon doesn't initiate any comms with the firewall.    
    my $fw = Device::Firewall::PaloAlto->new(
        uri => 'https://pa.localdomain',
        username => 'user11',
        password => 'a_password'
    );

    # Auth is required before performing any actions
    $fw->auth or die "Could not authenticate";

    # Calls can be chained together
    my $proto = $fw
        ->op
        ->virtual_router('default')
        ->route('0.0.0.0/0)
        ->protocol

    # Can use the 'Test' module to test aspects of the firewall.
    # Returns true if both IPs are in the ARP table
    ok( $fw->test->arp( qw(192.0.2.1 192.0.2.2) );
    
    my $flow = $fw->test->secpolicy(
       from => 'Trust', to => 'Untrust',
       src_ip => '192.0.2.1', dst_ip => '203.0.113.1',
       protocol => 6, port => 443
    );

    ok( $flow, 'Flow was allowed' );
    say "Flow hit rule: ".$flow->rulename;

    # Add and remove user ID information on the firewall
    $fw->user_id->add_ip_mapping('192.0.2.1', 'localdomain\greg.foletta');

    # If the module is used in a one liner, fw() sub is exported to make
    # it easier to use, and to_json() automatically prints to STDOUT.
    bash% perl -MDevice::Firewall::PaloAlto -E 'fw()->op->arp_table->to_json'

=head1 DESCRIPTION

This module provides an interface to the Palo Alto firewall API.

=head1 FUNCTIONS 

=head2 fw()

This is exported automatically into the main:: namespace if the module is
loaded within a one-liner - i.e. the calling script name is '-e'. If the module is
loaded within a normal script, this sub is not exported into main (though is of course accessible
using C<Device::Firewall::PaloAlto::fw()>.)

The purpose of this sub is to reduce the amount of code needed in one liners. As an example

    # Long way
    % perl -MDevice::Firewall::PaloAlto -E 'Device::Firewall::PaloAlto::new(vefify_hostname => 0)->auth->op->system_info->to_json'
    
    # Shorter way
    % perl -MDevice::Firewall::PaloAlto -E 'fw()->op->system_info->to_json'

The sub takes C<($user, $pass, $verify)> arguments. If C<$user> and C<$pass> arguments are not specified,
their undefinedness is passed through to C<new()> and either environment variables are used or they default
to 'admin'. 

If C<$verify> is not specified, C<new()> is called with C<verify_hostname => 0>, and thus the TLS certificate is
not verified. This is opposite to the default behaviour of C<new()> where the verification is performed.

=head1 METHODS

=head2 new

    my $fw = Device::Firewall::PaloAlto(
        uri => 'https://pa.localdomain',
        username => 'user',
        password => 'pass',
        verify_hostname => 1
    );

The C<new()> method creates a new Device::Firewall::PaloAlto object. The uri, username and password can be
passed in using the environment variables 'PA_FW_URI', PA_FW_USERNAME and PA_FW_PASSWORD. If no environment
variables are set, the username and password both default to 'admin'.

=head2 auth

    my $fw = $fw->auth;

This function authenticates the credentials passed to new against the firewall.

If successful, it returns the object itself to all method calls to be chains. If unsuccessful, it returns a L<Class::Error> object.

=head2 debug

    $fw->debug->op->interfaces();

Enables the debugging of HTTP requests and responses to the firewall.

=head2 undebug 

Disables debugging.

=head2 op

Returns a L<Device::Firewall::PaloAlto::Op> object. This object has methods to perform operational tasks on the firewall.

    my $fw_op = $fw->auth->op();
   
    # Return the firewall's interfaces
    my $interfaces = $fw_op->interfaces();

    # Return the ARP table
    my $arp_table = $fw->op->arp_table();

    # Returns the routes in the guest_vr virtual router
    my $routes = $fw->op->virtual_router('guest_vr');

=head2 user_id

Provides access to the L<Device::Firewall::PaloAlto::UserID> module. This module contains subroutines to add and remove dynamic IP to user mappings:

    # Add a mapping
    $fw->user_id->add_ip_mapping('192.0.2.1', 'localdomain\greg.foletta');

    # Remove a mapping
    $fw->user_id->rm_ip_mapping('192.0.2.1', 'localdomain\greg.foletta');

Refer to the module documentation for more information.

=head2 test

Provides access to the L<Device::Firewall::PaloAlto::Test> module. This module allows you to test the current state of a firewall.

    use Test::More;
    $test = $fw->test;
    ok( $test->interfaces('ethernet1/1', 'ethernet1/2'), 'Interfaces up' );

=head1 ERRORS

Errors are handled differently depending on whether the script is running from a file, or from a 'one-liner'.

=head2 File Errors

In the event of an error, a L<Class::Error> object is returned. The module's documentation provides the best information, but essentially it slurps up any method calls, evaluates to false in a boolean context, and contains an error string and code.

This allows you to chain together method calls and the error is propagated all the way through. A suggested way of checking for errors would be:

    my $state = $fw->auth->op->interfaces->interface('ethernet1/1')->state or die $state->error();

=head2 One-liner Errors

If the code is being run from a one-liner, the error is immeidately croaked rather than being returned as a L<Class::Error> object. This saves the user from having to add the explicit croak at the end of the call on what it likely an already crowded shell line. An example:

    bash% perl -MDevice::Firewall::PaloAlto -E 'fw()->op->system_info->to_json'         
    HTTP Error: 500 Can't connect to pa.localdomain:443 (certificate verify failed) - 500 at -e line 1.

=head1 ENVIRONMENT VARIABLES

The module uses the environment variables C<PA_FW_URI>, C<PA_FW_USERNAME> and C<PA_FW_PASSWORD>. These map to the C<uri>, C<username> and C<password> arguments to the new constructor. If any of these arguments are not present, the environment variable (if defined) is used.

The purpose of these is to reduce the clutter when using the module in a one-liner:

    bash% export PA_FW_URI=https://pa.localdomain
    bash% export PA_FW_USERNAME=greg.foletta
    bash% export PA_FW_PASSWORD=a_complex_password
    bash% perl -MDevice::Firewall::PaloAlto -E 'say fw()->op->interfaces->to_json'

=head1 JSON

Most objects inherit the C<to_json> method which returns a JSON representation of the object. By default the JSON is printed to STDOUT, however
a filename can be pased instead.

    # Outputs the json to STDOUT
    $fw->op->system_info->to_json;

    # Outputs the json the file 'firewall_info.json' in the current working directory
    $fw->op->system_info->to_json('firewall_info.json');

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
