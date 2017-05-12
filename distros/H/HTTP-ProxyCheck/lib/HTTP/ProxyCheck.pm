#===============================================================================
# HTTP::ProxyCheck Version 1.4, Thu May 25 10:47:42 CEST 2006
#===============================================================================
# Copyright (c) 2004 - 2006 Thomas Weibel. All rights reserved.
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# More information: See "pod2text ProxyCheck.pm"
#===============================================================================

package HTTP::ProxyCheck;

use strict;
use vars qw($answer $error $VERSION);
use warnings;

use Validate::Net;
use IO::Socket;

BEGIN {
    $VERSION = 1.4;
    $answer  = '';
    $error   = '';

    # Autoflush = True
    $| = 1;
}

=head1 NAME

HTTP::ProxyCheck - a class to check the functionality of HTTP proxy servers.

=head1 SYNOPSIS

    use HTTP::ProxyCheck;
    
    my $proxy       = 'proxy:8080';
    my $url         = 'http://search.cpan.org/';
    my $proxy_check = new HTTP::ProxyCheck(
        proxy       => $proxy,
        url         => $url,
        answer_size => 'header',
        print_error => 0,
    ) 
    or die $HTTP::ProxyCheck::error;
    
    print "Trying to connect to '$proxy' and retrieve '$url'\n";
    
    if ( $proxy_check->check() ) {
        print "'$proxy' returns:\n\n", $proxy_check->get_answer(), "\n\n";
    }
    else {
        print "Error: ", $proxy_check->get_error(), "\n";
    }

=head1 DESCRIPTION

HTTP::ProxyCheck is a class to check HTTP proxy servers. It connects to given 
HTTP proxy servers and tries to retrieve a provided URL through them.

=head1 CONSTRUCTOR

=head2 new( [attribute => $value, ...] )

C<new()> is the HTTP::ProxyCheck object constructor.

If an error happens while constructing the object, use 
C<$HTTP::ProxyCheck::error> to get the error message.

All named attributes of C<new()> are optional.

B<Attributes>

=over 10

=item * proxy => $proxy

Specifies the address of the proxy server to check. This can also be done with 
C<set_proxy()>.

The proxy server address has to match the patter 'host:port'. Host and port are
tested whether they are valid. If you want to disable this test, you can set
C<< check_proxy => 0 >>. 

=item * check_proxy => 1|0

Set C<< check_proxy => 0 >> to disable the check whether the proxy server 
address is valid.

The default value of C<check_proxy> is C<1> which means, the proxy server 
address gets tested.

This attribute can also be set with C<set_check_proxy()>.

=item * url => $url

Specifies the URL to use for the proxy server check. This can also be done 
with C<set_url()>.

The URL has to be of a valid form, e.g. 'http://search.cpan.org'. It gets 
tested whether it is valid. If you want to disable this test, you can set
C<< check_url => 0 >>.

=item * check_url => 1|0

Set C<< check_url => 0 >> to disable the check whether the URL is valid.

The default value of C<check_url> is C<1> which means, the URL gets tested.

This attribute can also be set with C<set_check_url()>.

=item * answer_size => short|header|full

Defines the size of the proxy server answer. 

C<short> means that only the HTTP status code, e.g.

    HTTP/1.0 200 OK

is returned.

With C<header> the full HTTP header gets returned, e.g.

    HTTP/1.0 200 OK
    Date: Tue, 12 Aug 2003 12:19:46 GMT
    Server: Apache/1.3.27 (Unix) mod_perl/1.27
    Cache-Control: max-age=3600
    Expires: Tue, 12 Aug 2003 13:19:46 GMT
    Last-Modified: Tue, 12 Aug 2003 12:19:46 GMT
    Content-Type: text/html
    X-Cache: MISS from search.cpan.org
    X-Cache: MISS from hactar.earth.net
    X-Cache-Lookup: HIT from hactar.earth.net:8080
    Proxy-Connection: close

Use C<full> if you want the HTTP header including the whole data from the
proxy server.

The default value of C<answer_size> is C<header>.

This attribute can also be set with C<set_answer_size()>.

=item * user_agent => $user_agent

Specifies the name of the user agent sent to the proxy.

If you don't specify a user agent, "HTTP::ProxyCheck/1.4" is used.

=item * verbose_errors => 0|1

Set C<< verbose_errors => 1 >> to enable verbose error messages.

Verbose error messages look like this:

    $method failed: $error_message

And non-verbose error messages like this:

    $error_message

The default value of C<verbose_errors> is C<0>.

For more information see L</"ERROR HANDLING">.

=item * print_error => 1|0

Set C<< print_error => 0 >> to disable that error messages are displayed with
C<Carp::carp()>.

The default value of C<print_error> is C<1>.

For more information see L</"ERROR HANDLING">.

=item * raise_error => 0|1

Set C<< raise_error => 1 >> to enable that error messages are displayed with 
C<Carp::croak()> and the program is brought to an end.

The default value of C<raise_error> is C<0>.

For more information see L</"ERROR HANDLING">.

=back

B<Return values>

=over 10

=item * Okay

Blessed reference

=item * Error

C<undef>

The error message can be retrieved with C<$HTTP::ProxyCheck::error>.

=back

=cut

sub new {
    my ( $class, %attr ) = @_;
    my $self = bless( {%attr}, $class );

    if ( $self->_init ) {
        return $self;
    }
    else {
        return $self->_throw( $self->{error} );
    }
}

=head1 METHODS

=head2 check( [attribute => $value, ...] )

C<check()> does the actual proxy server checking. It connects to a specified
proxy server and tries to get a defined URL through it.

All named attributes of C<check()> are optional, but C<proxy> and C<url>
must be either set as object or method attribute.

B<Attributes>

=over 10

=item * proxy => $proxy

Defines the proxy server to check. 

C<< proxy => $proxy >> has higher precedence than the object attribute 
C<proxy>. It is only used by this method call. It doesn't get saved as object
attribute or changes the object attribute. If you want to do this use 
C<set_proxy()>.

For more information see L</"CONSTRUCTOR">.

=item * check_proxy => 1|0

Set C<< check_proxy => 0 >> to disable the check whether the proxy server 
address is valid. If C<< check_proxy => 1 >> is set the proxy server 
address gets tested.

This method attribute has higher precedence than the object attribute 
C<check_proxy>. It is only used by this method call. It doesn't get saved as 
object attribute or changes the object attribute. If you want to do this use 
C<set_check_proxy()>.

=item * url => $url

Defines the URL to use with the proxy server check. 

C<< url => $url >> has higher precedence than the object attribute 
C<url>. It is only used by this method call. It doesn't get saved as object 
attribute or changes the object attribute. If you want to do this use 
C<set_url()>.

For more information see L</"CONSTRUCTOR">.

=item * check_url => 1|0

Set C<< check_url => 0 >> to disable the check whether the URL is valid. If 
C<< check_url => 1 >> is set the URL gets tested.

This method attribute has higher precedence than the object attribute 
C<check_url>. It is only used by this method call. It doesn't get saved as 
object attribute or changes the object attribute. If you want to do this use 
C<set_check_url()>.

=item * answer_size => short|header|full

Defines the size of the proxy server answer. 

This method attribute has higher precedence than the object attribute 
C<answer_size>. It is only used by this method call. It doesn't get saved as 
object attribute or changes the object attribute. If you want to do this use 
C<set_answer_size()>.

For more information see L</"CONSTRUCTOR">.

=back

B<Return values>

=over 10

=item * Okay

C<1>

The answer of the proxy server can be retrieved with C<get_answer()> or
C<$HTTP::ProxyCheck::answer>

=item * Error

C<undef>

The error message can be retrieved with C<get_error()> or 
C<$HTTP::ProxyCheck::error>

=back

=cut

sub check {
    my ( $self, %attr ) = @_;
    my ( $check_proxy, $check_url, $proxy, $url, $answer_size, $user_agent );

    #---------------------------------------------------------------------------
    # Parse attributes and set defaults
    #---------------------------------------------------------------------------

    # Set the proxy check attribute
    if ( defined $attr{check_proxy} ) {
        $check_proxy = $self->_get_bool( $attr{check_proxy} );
    }
    else {
        $check_proxy = $self->{check_proxy};
    }

    # Set the URL check attribute
    if ( defined $attr{check_url} ) {
        $check_url = $self->_get_bool( $attr{check_url} );
    }
    else {
        $check_url = $self->{check_url};
    }

    # Set the proxy address
    if ( defined $attr{proxy} ) {
        $proxy = $attr{proxy};
        unless ( $self->_check_proxy( $proxy, $check_proxy ) ) {
            return $self->_throw( $self->{error} );
        }
    }
    elsif ( defined $self->{proxy} ) {
        $proxy = $self->{proxy};
    }
    else {
        return $self->_throw(
q#No proxy defined. Set it as attribute of your 'HTTP::ProxyCheck' object or the 'check()' method. You can also set it with 'set_proxy()'.#
        );
    }

    # Set the URL
    if ( defined $attr{url} ) {
        $url = $attr{url};
        unless ( $self->_check_url( $url, $check_url ) ) {
            return $self->_throw( $self->{error} );
        }
    }
    elsif ( defined $self->{url} ) {
        $url = $self->{url};
    }
    else {
        return $self->_throw(
q#No url defined. Set it as attribute of your 'HTTP::ProxyCheck' object or the 'check()' method. You can also set it with 'set_url()'.#
        );
    }

    # Set the answer size
    if ( defined $attr{answer_size} ) {
        $answer_size = $attr{answer_size};
        unless ( $self->_check_answer_size($answer_size) ) {
            return $self->_throw( $self->{error} );
        }
    }
    elsif ( defined $self->{answer_size} ) {
        $answer_size = $self->{answer_size};
    }
    else {
        return $self->_throw(
q#No answer_size defined. Set it as attribute of your 'HTTP::ProxyCheck' object or the 'check()' method. You can also set it with 'set_answer_size()'.#
        );
    }

    # Set the user agent
    if ( defined $attr{user_agent} ) {
        $user_agent = $attr{user_agent};
    }
    elsif ( defined $self->{user_agent} ) {
        $user_agent = $self->{user_agent};
    }
    else {
        $user_agent = "HTTP::ProxyCheck/" . $VERSION;
    }

    #---------------------------------------------------------------------------
    # Proxy check
    #---------------------------------------------------------------------------

    my ( $i, @answer, $answer, @header, $request, $line, $EOL );

    $EOL = "\015\012";

    # Fix to unset the error message of a previous IO::Socket::INET run
    # Thanks to Ben Schnopp <ben at schnopp dot com>
    undef $@;

    # Open socket to proxy server
    my $socket = IO::Socket::INET->new(
        PeerAddr => $proxy,
        Proto    => 'tcp',
        Timeout  => 5,
        Type     => SOCK_STREAM
    );

    # If there was an error, throw an exception
    if ($@) {
        return $self->_throw("Couldn't connect to '$proxy'. $@");
    }
    
    # Set request
    $request = <<"REQUEST";
GET $url HTTP/1.0
Referer: None
User-Agent: $user_agent
Pragma: no-cache

REQUEST

    $request =~ s/\n/\015\012/g;

    # Print request to the open socket
    print $socket $request;
    
    # Read the answer of the proxy server to an array
    while ( defined( $line = <$socket> ) ) {
        $line =~ s/\n//g;
        push @answer, $line;
    }

    $answer = join "\n", @answer;

    # Throw an exception if the answer is empty
    unless ( defined $answer && $answer !~ /^\s*$/ ) {
        return $self->_throw("'$proxy' didn't return anything. Maybe '$proxy' is not the address of a proxy server.");
    }
   
    # Parse the answer according to the requested answer size
    if ( $answer_size eq 'short' ) {
        $answer = $answer[0];
    }
    elsif ( $answer_size eq 'header' ) {
        foreach (@answer) {
            if ( !/^\s*</ && !/^\s+/ ) {
                push @header, $_;
            }
            else {
                last;
            }
        }
        $answer = join "\n", @header;
    }

    # Throw an exception if the parsed answer is empty
    unless ( defined $answer && $answer !~ /^\s*$/ ) {
        return $self->_throw(qq#'$proxy' didn't return a header. Try setting 'answer_size => "full"' as attribute of your 'HTTP::ProxyCheck' object or the 'check()' method. You can also use 'set_answer_size( "full" )'.#);
    }

    close($socket);

    $self->_set_answer($answer);

    return 1;
}

=head2 get_answer( )

C<get_answer()> gets the most recent proxy server answer.

The proxy server answer is in the form specified by the C<answer_size> 
attribute of the HTTP::ProxyCheck object or the C<check()> method.

For more information see L</"CONSTRUCTOR">.

B<Return values>

=over 10

=item * Okay

C<< $proxy_check->{answer} >>

This is the most recent proxy server answer.

=item * Error

C<undef>

The error message can be retrieved with C<get_error()> or 
C<$HTTP::ProxyCheck::error>

=back

=cut

sub get_answer {
    my ($self) = @_;

    unless ( defined $self->{answer} ) {
        return $self->_throw('No answer returned so far.');
    }

    return $self->{answer};
}

=head2 get_error( )

C<get_error()> gets the most recent error message.

For more information see L</"ERROR HANDLING">.

B<Return values>

=over 10

=item * Okay

C<< $proxy_check->{error} >>

This is the most recent error message.

=back

=cut

sub get_error {
    my ($self) = @_;

    unless ( defined $self->{error} ) {
        return $self->_throw('No error happened so far.');
    }

    return $self->{error};
}

=head2 get_proxy( )

C<get_proxy()> gets the current value of the object attribute C<proxy>.

B<Return values>

=over 10

=item * Okay

C<< $proxy_check->{proxy} >>

This is the current proxy server address.

=item * Error

C<undef>

The error message can be retrieved with C<get_error()> or 
C<$HTTP::ProxyCheck::error>

=back

=cut

sub get_proxy {
    my ($self) = @_;

    unless ( defined $self->{proxy} ) {
        $self->_throw(
q#No proxy defined. Set it as attribute of your 'HTTP::ProxyCheck' object or with 'set_proxy()'.#
        );
    }

    return $self->{proxy};
}

=head2 set_proxy( $proxy )

C<set_proxy()> sets the value of the object attribute C<proxy>.

B<Attributes>

=over 10

=item * $proxy

The proxy server address has to match the patter 'host:port'. Host and port are
tested whether they are valid. If you want to disable this test, you can set
the object attribute C<< check_proxy => 0 >> or use C<set_check_proxy(0)>.

=back

B<Return values>

=over 10

=item * Okay

C<1>

=item * Error

C<undef>

The error message can be retrieved with C<get_error()> or 
C<$HTTP::ProxyCheck::error>

=back

=cut

sub set_proxy {
    my ( $self, $proxy ) = @_;

    unless ( defined $proxy ) {
        return $self->_throw('No proxy server defined.');
    }

    # Check the proxy server address
    unless ( $self->_check_proxy( $proxy, $self->{check_proxy} ) ) {
        return $self->_throw( $self->{error} );
    }

    $self->{proxy} = $proxy;

    return 1;
}

=head2 get_check_proxy( )

C<get_check_proxy()> gets the current value of the object attribute C<check_proxy>.

B<Return values>

=over 10

=item * Okay

C<< $proxy_check->{check_proxy} >>

This is the current value of the C<check_proxy> attribute.

=back

=cut

sub get_check_proxy {
    my ($self) = @_;

    return $self->{check_proxy};
}

=head2 set_check_proxy( $check )

C<set_check_proxy> sets the object attribute C<check_proxy>.

B<Attributes>

=over 10

=item * $check

Use C<0> to disable the check whether the proxy server address is valid and C<1>
to enable it.

=back

B<Return values>

=over 10

=item * Okay

C<1>

=item * Error

C<undef>

The error message can be retrieved with C<get_error()> or 
C<$HTTP::ProxyCheck::error>

=back

=cut

sub set_check_proxy {
    my ( $self, $check_proxy ) = @_;

    unless ( defined $check_proxy ) {
        return $self->_throw(q#No 'check_proxy' value defined.#);
    }

    # Get boolean value for $check_proxy
    $check_proxy = $self->_get_bool( $check_proxy );
    
    $self->{check_proxy} = $check_proxy;

    return 1;
}

=head2 get_url( )

C<get_url()> gets the current value of the object attribute C<url>.

B<Return values>

=over 10

=item * Okay

C<< $proxy_check->{url} >>

This is the current URL.

=item * Error

C<undef>

The error message can be retrieved with C<get_error()> or 
C<$HTTP::ProxyCheck::error>

=back

=cut

sub get_url {
    my ($self) = @_;

    unless ( defined $self->{url} ) {
        $self->_throw(
q#No url defined. Set it as attribute of your 'HTTP::ProxyCheck' object or with 'set_url()'.#
        );
    }

    return $self->{url};
}

=head2 set_url( $url )

C<set_url> sets the object attribute C<url>.

B<Attributes>

=over 10

=item * $url

The URL has to be of a valid form, e.g. 'http://search.cpan.org'. It gets 
tested whether it is valid. If you want to disable this test, you can set
the object attribute C<< check_url => 0 >> or use C<set_check_url(0)>.

=back

B<Return values>

=over 10

=item * Okay

C<1>

=item * Error

C<undef>

The error message can be retrieved with C<get_error()> or 
C<$HTTP::ProxyCheck::error>

=back

=cut

sub set_url {
    my ( $self, $url ) = @_;

    unless ( defined $url ) {
        return $self->_throw('No URL defined.');
    }

    # Check the URL
    unless ( $self->_check_url( $url, $self->{check_url} ) ) {
        return $self->_throw( $self->{error} );
    }

    $self->{url} = $url;

    return 1;
}

=head2 get_check_url( )

C<get_check_url()> gets the current value of the object attribute C<check_url>.

B<Return values>

=over 10

=item * Okay

C<< $proxy_check->{check_url} >>

This is the current value of the C<check_url> attribute.

=back

=cut

sub get_check_url {
    my ($self) = @_;

    return $self->{check_url};
}

=head2 set_check_url( $check )

C<set_check_url> sets the object attribute C<check_url>.

B<Attributes>

=over 10

=item * $check

Use C<0> to disable the check whether the URL is valid and C<1> to enable it.

=back

B<Return values>

=over 10

=item * Okay

C<1>

=item * Error

C<undef>

The error message can be retrieved with C<get_error()> or 
C<$HTTP::ProxyCheck::error>

=back

=cut

sub set_check_url {
    my ( $self, $check_url ) = @_;

    unless ( defined $check_url ) {
        return $self->_throw(q#No 'check_url' value defined.#);
    }

    # Get boolean value for $check_url
    $check_url = $self->_get_bool( $check_url );
    
    $self->{check_url} = $check_url;

    return 1;
}

=head2 get_answer_size( )

C<get_answer_size()> gets the current value of the object attribute C<answer_size>.

B<Return values>

=over 10

=item * Okay

C<< $proxy_check->{answer_size} >>

This is the current answer size.

=item * Error

C<undef>

The error message can be retrieved with C<get_error()> or 
C<$HTTP::ProxyCheck::error>

=back

=cut

sub get_answer_size {
    my ($self) = @_;

    unless ( defined $self->{answer_size} ) {
        $self->_throw(
q#No answer size defined. Set it as attribute of your 'HTTP::ProxyCheck' object or with 'set_answer_size()'.#
        );
    }

    return $self->{answer_size};
}

=head2 set_answer_size( $answer_size )

C<set_answer_size> sets the object attribute C<answer_size>.

B<Attributes>

=over 10

=item * $answer_size

Defines the size of the proxy server answer. Use either C<short>, C<header> or 
C<full> as value. 

For more information see L</"CONSTRUCTOR">.

=back

B<Return values>

=over 10

=item * Okay

C<1>

=item * Error

C<undef>

The error message can be retrieved with C<get_error()> or 
C<$HTTP::ProxyCheck::error>

=back

=cut

sub set_answer_size {
    my ( $self, $answer_size ) = @_;

    unless ( defined $answer_size ) {
        return $self->_throw('No answer size defined.');
    }

    # Check the answer size
    unless ( $self->_check_answer_size($answer_size) ) {
        return $self->_throw( $self->{error} );
    }

    $self->{answer_size} = $answer_size;

    return 1;
}

#-------------------------------------------------------------------------------
# Private method: _check_proxy()
#-------------------------------------------------------------------------------
# Checks whether a provided proxy server address complies with the pattern 
# 'host:port'.
#
# Attributes
#   * $proxy
#     Defines the proxy server address to check.
#   * $check_proxy
#     Indicates whether to check the proxy server address or not. Possible 
#     values are
#     '1' or '0'.
#
# Return values
#   * Okay
#     1
#   * Error
#     undef
#-------------------------------------------------------------------------------

sub _check_proxy {
    my ( $self, $proxy, $check_proxy ) = @_;

    unless ( defined $proxy ) {
        return undef;
    }

    if ($check_proxy) {

        # Check proxy server address format
        unless ( $proxy =~ /^(\S*):(\d{1,5})$/ ) {
            $self->{error} =
"The specified proxy server '$proxy' doesn't comply with the pattern 'host:port' e.g. 'proxy:8080'.";
            return undef;
        }

        my $proxyhost = $1;
        my $proxyport = $2;

        # Check proxy server host and port
        unless ( Validate::Net->host($proxyhost)
            && Validate::Net->port($proxyport) )
        {
            $self->{error} =
              "The specified proxy server address '$proxy' is invalid. "
              . Validate::Net->reason() . ".";
            return undef;
        }
    }

    return 1;
}

#-------------------------------------------------------------------------------
# Private method: _check_url()
#-------------------------------------------------------------------------------
# Checks whether a provided URL is a valid URL for HTTP::ProxyCheck e.g. 
# 'http://search.cpan.org'.
#
# Attributes
#   * $url
#     Defines the URL to check.
#   * $check_url
#     Indicates whether to check the URL or not. Possible values are '1' or '0'.
#
# Return values
#   * Okay
#     1
#   * Error
#     undef
#-------------------------------------------------------------------------------

sub _check_url {
    my ( $self, $url, $check_url ) = @_;

    unless ( defined $url ) {
        return undef;
    }

    if ($check_url) {

        # Check URL format
        unless ( $url =~ m#^http://([^:/]+)(?::(\d+))?(?:/.*)?# ) {
            $self->{error} =
"The specified URL '$url' doesn't comply with the pattern of a valid URL for HTTP::ProxyCheck e.g. 'http://search.cpan.org'";
            return undef;
        }
        my $host = $1;
        my $port = $2;

        my $invalid_url = "The specified URL '$url' is not valid. ";

        # Check host and port
        unless ( Validate::Net->host($host) ) {
            $self->{error} = $invalid_url . Validate::Net->reason() . ".";
            return undef;
        }

        if ( defined $port ) {
            unless ( Validate::Net->port($port) ) {
                $self->{error} = $invalid_url . Validate::Net->reason() . ".";
                return undef;
            }
        }
    }

    return 1;
}

#-------------------------------------------------------------------------------
# Private method: _check_answer_size()
#-------------------------------------------------------------------------------
# Checks whethera provided answer size is valid.
#
# Attributes
#   * $answer_size
#     Specifies the answer size. Possible values are 'short', 'header' or 
#     'full'.
#
# Return values
#   * Okay
#     1
#   * Error
#     undef
#-------------------------------------------------------------------------------

sub _check_answer_size {
    my ( $self, $answer_size ) = @_;

    unless ( defined $answer_size ) {
        return undef;
    }

    # The answer size must be either 'short', 'header' or 'full'
    unless ( $answer_size =~ m/^short|header|full$/ ) {
        $self->{error} =
"The specified answer size '$answer_size' is invalid, use either 'header' or 'full'.";
        return undef;
    }

    return 1;
}

#-------------------------------------------------------------------------------
# Private method: _throw()
#-------------------------------------------------------------------------------
# Throws an exeption with a message and optional with a specified return code.
# If no return code is specified, 'undef' is returned.
#
# Attributes
#   * $message
#     Defines the error message.
#   * $return_code
#     Specifies an optional return code for scalar context (default is 'undef').
#     In list context, '()' (empty list) is used.
#
# Return values
#   * Okay
#       * Array context
#         () (empty list)
#       * Scalar context
#         $return_code
#-------------------------------------------------------------------------------

sub _throw {
    my ( $self, $message, $return_code ) = @_;

    unless ( defined $return_code ) {
        $return_code = undef;
    }

    # Get the method name
    my $method = ( caller 1 )[3];

    # If the verbose errors attribut is set, add 'method_name failed:' to the 
    # error message
    if ( $self->{verbose_errors} ) {
        $message = "$method failed: " . $message;
    }

    $self->_set_error($message);

    # Throw the exception
    Carp::croak $self->{error} if $self->{raise_error};
    Carp::carp $self->{error}  if $self->{print_error};

    # Return the return code in the right context
    if (wantarray) {
        return ();
    }
    else {
        return $return_code;
    }
}

#-------------------------------------------------------------------------------
# Private method: _set_error()
#-------------------------------------------------------------------------------
# Sets $self->{error} and $error and returns the previous error message.
#
# Attributes
#   * $my_error
#     Defines the error message.
#
# Return values
#   * Okay
#     $prev_error
#   * Error
#     undef
#-------------------------------------------------------------------------------

sub _set_error {
    my ( $self, $my_error ) = @_;
    my $prev_error = $self->{error};

    unless ( defined $my_error ) {
        return undef;
    }

    $self->{error} = $my_error;
    $error = $my_error;

    return $prev_error;
}

#-------------------------------------------------------------------------------
# Private method: _set_answer()
#-------------------------------------------------------------------------------
# Sets $self->{answer} and $answer and returns the previous answer.
#
# Attributes
#   * $my_answer
#     Defines the proxy server answer.
#
# Return values
#   * Okay
#     $prev_answer
#   * Error
#     undef
#-------------------------------------------------------------------------------

sub _set_answer {
    my ( $self, $my_answer ) = @_;
    my $prev_answer = $self->{answer};

    unless ( defined $my_answer ) {
        return undef;
    }

    $self->{answer} = $my_answer;
    $answer = $my_answer;

    return $prev_answer;
}

#-------------------------------------------------------------------------------
# Private method: _get_bool()
#-------------------------------------------------------------------------------
# Translates values to boolean value. '0' remains '0', 'undef' is translated to
# the default value and every other value is gets '1'.
#
# Attributes
#   * $value
#     Specifies the value to translate.
#   * $default
#     Defines the default value for undefined values.
#
# Return values
#   * True
#     1
#   * False
#     0
#-------------------------------------------------------------------------------

sub _get_bool {
    my ( $self, $value, $default ) = @_;

    # Check and set $default
    if ( defined $default ) {
        unless ( $default eq 0 ) {
            $default = 1;
        }
    }
    else {
        $default = 1;
    }

    # Check and set $value
    if ( defined $value ) {
        unless ( $value eq 0 ) {
            $value = 1;
        }
    }
    else {
        $value = $default;
    }

    return $value;
}

#-------------------------------------------------------------------------------
# Private method: _init()
#-------------------------------------------------------------------------------
# Initializes the default values of the attributes of new().
#
# Return values
#   * Okay
#     1
#   * Error
#     undef
#-------------------------------------------------------------------------------

sub _init {
    my ($self) = @_;
    my $verbose_errors = $self->{verbose_errors};
    my $print_error    = $self->{print_error};
    my $raise_error    = $self->{raise_error};
    my $check_proxy    = $self->{check_proxy};
    my $check_url      = $self->{check_url};
    my $proxy          = $self->{proxy};
    my $url            = $self->{url};
    my $answer_size    = $self->{answer_size};

    # Set the verbose errors attribute
    $self->{verbose_errors} = $self->_get_bool( $verbose_errors, 0 );

    # Set the print error attribute
    $self->{print_error} = $self->_get_bool( $print_error, 1 );

    # Set the raise error attribute
    $self->{raise_error} = $self->_get_bool( $raise_error, 0 );

    # Set the check proxy attribute
    $self->{check_proxy} = $self->_get_bool( $check_proxy, 1 );

    # Set the check URL attribute
    $self->{check_url} = $self->_get_bool( $check_url, 1 );

    # Check the proxy server address
    if ( defined $proxy ) {
        unless ( $self->_check_proxy( $proxy, $self->{check_proxy} ) ) {
            return undef;
        }
        $self->{proxy} = $proxy;
    }

    # Check the URL
    if ( defined $url ) {
        unless ( $self->_check_url( $url, $self->{check_url} ) ) {
            return undef;
        }
        $self->{url} = $url;
    }

    # Check the answer size
    if ( defined $answer_size ) {
        unless ( $self->_check_answer_size($answer_size) ) {
            return undef;
        }
    }
    else {
        $answer_size = 'header';
    }
    $self->{answer_size} = $answer_size;

    return 1;
}

1;

__END__

=head1 ERROR HANDLING

HTTP::ProxyCheck has a highly configurable error handling system. It is 
configured with the attributes C<verbose_errors>, C<print_error> and 
C<raise_error> at object creation:

    my $proxy_check = new HTTP::ProxyCheck(
        proxy          => 'proxy:8080',
        url            => 'http://search.cpan.org',
        verbose_errors => 1,
        print_error    => 0,
        raise_error    => 1,
    );

Every time you call a method of HTTP::ProxyCheck and an error happens, which 
means the method returns C<undef>, the error message can be retrieved with 
C<get_error()> or C<$HTTP::ProxyCheck::error>:

    $proxy_check->set_answer_size( 'full' )
      or die $proxy_check->get_error();
    
    $proxy_check->check()
      or die $HTTP::ProxyCheck::error;

If there's an error during the object construction, you can't get the error 
message through C<get_error()>. Use C<$HTTP::ProxyCheck::error> instead:

    my $proxy_check = new HTTP::ProxyCheck( proxy => 'proxy' )
      or die $HTTP::ProxyCheck::error;

The object attribute C<verbose_errors> configures the verbosity of the error 
message. Set C<< verbose_errors => 1 >> to enable verbose error messages and 
C<< verbose_errors => 0 >> to disable verbose error messages.

Verbose error messages look like this:

    $method failed: $error_message

And non-verbose error messages like this:

    $error_message

The default value of C<verbose_errors> is C<0>.

With C<print_error> and C<raise_error> you can set the degree of automation of
the error handling.

If C<print_error> is set to C<1>, the error message is displayed with 
C<Carp::carp()>. Set C<print_error> to C<0> to disable this feature.

If C<raise_error> is set to C<1>, the error message is displayed with 
C<Carp::croak()> and the program is brought to an end. If C<raise_error>
is set to C<0>, this feature is disabled.

The default value of C<print_error> is C<1> and of C<raise_error> it is C<0>.

=head1 SUPPORT

Contact the L</"AUTHOR">.


=head1 BUGS

Unknown


=head1 VERSION

    HTTP::ProxyCheck version 1.2


=head1 CHANGES

    1.4 Thu May 25 10:47:42 CEST 2006
        - Added installation instructions to README
    
    1.3 Sun May  7 11:51:50 CEST 2006
        - Charles Longeau <chl attuxfamily dot org> made a small patch to 
          specify the user agent, instead of a fixed "HTTP::ProxyCheck/$VERSION"
          one.
    
    1.2 Sat May  8 09:38:02 CEST 2004
        - Fix to unset the error message of a previous IO::Socket::INET run
          Thanks to Ben Schnopp <ben at schnopp dot com>
    
    
    1.1 Tue Aug 12 19:45:00 CEST 2003
        - rewrote the module
        - added better error handling
        - updated POD
    
    1.0  Fri Feb 21 17:09:32 CET 2003
        - gone stable after detailed testing 
        - updated POD (synopsis)
    
    0.2  Fri Feb 21 11:57:43 CET 2003
        - added check(answer => $type)
        - renamed methods to gain more consistency
        - updated POD (synopsis, methods)
    
    0.1  Wed Feb  5 14:35:25 CET 2003
        - original version

=head1 AUTHOR

    Thomas Weibel
    cpan@beeblebrox.net
    http://beeblebrox.net/


=head1 COPYRIGHT

Copyright (c) 2004 - 2006 Thomas Weibel. All rights reserved.

This library is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
