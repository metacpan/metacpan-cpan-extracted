package Device::Firewall::PaloAlto::API;
$Device::Firewall::PaloAlto::API::VERSION = '0.1.2';
use strict;
use warnings;
use 5.010;

use URI;
use Carp;
use LWP::UserAgent;
use HTTP::Request;
use XML::Twig;
use Class::Error;
use Hook::LexWrap;

# VERSION
# PODNAME
# ABSTRACT: Palo Alto firewall API module


sub new {
    my $class = shift;
    my %args = @_;

    my %object;
    my @args_keys = qw(uri username password);

    @object{ @args_keys } = @args{ @args_keys };

    $object{uri} //= $ENV{PA_FW_URI} or return ERROR('No uri specified and no environment variable PA_FW_URI found');
    $object{username} //= $ENV{PA_FW_USERNAME} // 'admin';
    $object{password} //= $ENV{PA_FW_PASSWORD} // 'admin';
    carp "Not enough keys specified" and return unless keys %object >= 3;

    $args{verify_hostname} //= 1;
    my $ssl_opts = { verify_hostname => $args{verify_hostname} };


    my $uri = URI->new($object{uri});
    if (!($uri->scheme eq 'http' or $uri->scheme eq 'https')) {
        carp "Incorrect URI scheme in uri '$object{uri}': must be either http or https";
        return
    }

    $uri->path('/api/');

    $object{uri} = $uri;
    $object{user_agent} = LWP::UserAgent->new(ssl_opts => $ssl_opts);
    $object{api_key} = '';

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

    $self->{wrap} = wrap '_send_raw_request',
        pre => \&_debug_pre_wrap,
        post => \&_debug_post_wrap;

    return $self;
}


sub undebug {
    my $self = shift;
    $self->{wrap} = undef;

    return $self;
}


# Sends a request to the firewall. The query string parameters come from the key/value 
# parameters passed to the function, ie _send_request(type = 'op', cmd => '<xml>')
#
# The method automatically adds in the autentication key if it exists.
sub _send_request {
    my $self = shift;
    my %query = @_;

    # If we're authenticated, add the API key
    $query{key} = $self->{api_key} if $self->{api_key};

    # Build the URI query section
    my $uri = $self->{uri};
    $uri->query_form( \%query );

    # Create and send the HTTP::Request
    my $http_request = HTTP::Request->new(GET => $uri->as_string);
    my $response = $self->_send_raw_request($http_request);

    # Check and return
    return _parse_and_check_response( $response );
}


sub _send_raw_request {
    my $self = shift;
    return $self->{user_agent}->request($_[0]);
}


sub _parse_and_check_response {
    my ($http_response) = @_;
    my $r;
    $r = _check_http_response($http_response) or return $r;
    return _check_api_response($r);
}
  
# Checks whether the HTTP response is an error. Carps and returns undef if it is.
# Returns the decoded HTTP content on success.
# On failure returns 'false'.
sub _check_http_response {
    my ($http_response) = @_;

    if ($http_response->is_error) {
        my $err = "HTTP Error: @{[$http_response->status_line]} - @{[$http_response->code]}";
        return ERROR($err, 0);
    }

    return $http_response->decoded_content;
}

# Parses the API response and checks if it's an API error.
# Returns a data structure representing the XML content on success.
# On failure returns 'false'.
sub _check_api_response {
    my ($http_content) = @_;
    return $http_content unless $http_content;

    my $api_response = XML::Twig->new->safe_parse( $http_content );
    return ERROR('Invalid XML returned in PA response') unless $api_response;

    $api_response = $api_response->simplify( forcearray => ['entry'] );

    if ($api_response->{status} eq 'error') {
        my $err = "API Error: $api_response->{msg}{line} (Code: $api_response->{code})";
        return ERROR($err);
    }

    return $api_response;
}


use Data::Dumper;

sub _debug_pre_wrap {
    my $self = shift;
    my ($http_request) = @_;
    say "REQUEST:";
    say $http_request->as_string;
}

sub _debug_post_wrap {
    my $self = shift;
    my ($http_response) = @_;
    say "RESPONSE:";
    say $http_response->as_string;
}


sub ERROR {
    my ($errstring, $errno) = @_;
    
    # Are we in a one liner? If so, we croak out straight away
    my ($sub, $file, $inc);
    while (!defined $sub or $sub ne 'main') { 
        ($sub, $file) = caller(++$inc);
    } 
    
    croak $errstring if $file eq '-e';

    return Class::Error->new($errstring, $errno);
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::API - Palo Alto firewall API module

=head1 VERSION

version 0.1.2

=head1 DESCRIPTION

This module contains API related methods used by the L<Device::Firewall::PaloAlto> package.

=head2 auth

Authenticates the supplies credentials against the firewall. If successfull it returns the object to allow for method chaining.
If not successful it returns a L<Class::Error> object.

=head2 debug

    $fw->debug->op->interfaces();

Enables the debugging of HTTP requests and responses to the firewall.

=head2 undebug 

Disables debugging.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
