# Main auto-protected PSGI adapter for LLNG handler
#
# See https://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::PSGI::Main;

use strict;
use base 'Lemonldap::NG::Handler::Main';
our $VERSION = '2.0.6';

# Specific modules and constants for Test or CGI
use constant FORBIDDEN         => 403;
use constant HTTP_UNAUTHORIZED => 401;
use constant REDIRECT          => 302;
use constant OK                => 0;
use constant DECLINED          => 0;
use constant DONE              => 0;
use constant SERVER_ERROR      => 500;
use constant AUTH_REQUIRED     => 401;
use constant MAINTENANCE       => 503;
use constant defaultLogger     => 'Lemonldap::NG::Common::Logger::Std';

## @method void thread_share(string $variable)
# share or not the variable (if authorized by specific module)
# @param $variable the name of the variable to share
sub thread_share {

    # nothing to do in PSGI
}

## @method void setServerSignature(string sign)
# modifies web server signature
# @param $sign String to add to server signature
sub setServerSignature {
}

## @method void set_user(string user)
# sets remote_user in response headers
# @param user string username
sub set_user {
    my ( $class, $req, $user ) = @_;
    push @{ $req->{respHeaders} }, 'Lm-Remote-User' => $user;
}

## @method void set_custom(string custom)
# sets remote_custom in response headers
# @param custom string custom_value
sub set_custom {
    my ( $class, $req, $custom ) = @_;
    push @{ $req->{respHeaders} }, 'Lm-Remote-Custom' => $custom
      if defined $custom;
}

## @method void set_header_in(hash headers)
# sets or modifies request headers
# @param headers hash containing header names => header value
sub set_header_in {
    my ( $class, $req, %headers ) = @_;
    while ( my ( $h, $v ) = each %headers ) {
        $req->{env}->{ cgiName($h) } = $v if ( defined $v );
    }
}

## @method void unset_header_in(array headers)
# removes request headers
# @param headers array with header names to remove
sub unset_header_in {
    my ( $class, $req, @headers ) = @_;
    foreach my $h (@headers) {
        delete $req->{env}->{ cgiName($h) };
    }
}

## @method void set_header_out(hash headers)
# sets response headers
# @param headers hash containing header names => header value
sub set_header_out {
    my ( $class, $req, %headers ) = @_;
    while ( my ( $h, $v ) = each %headers ) {
        push @{ $req->{respHeaders} }, $h => $v;
    }
}

## @method boolean is_initial_req
# always returns true
# @return is_initial_req boolean
sub is_initial_req {
    return 1;
}

## @method void print(string data)
# write data in HTTP response body
# @param data Text to add in response body
sub print {
    my ( $class, $req, $data ) = @_;
    $req->{respBody} .= $data;
}

sub addToHtmlHead {
    my $self = shift;
    $self->logger->error(
        'Features like form replay or logout_app can only be used with Apache');
}

sub cgiName {
    my $h = uc(shift);
    $h =~ s/-/_/g;
    return "HTTP_$h";
}

*setPostParams = *addToHtmlHead;

1;
