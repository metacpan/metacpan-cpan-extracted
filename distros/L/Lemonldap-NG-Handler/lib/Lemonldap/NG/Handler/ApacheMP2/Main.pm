# Main ApacheMP2 adapter for LLNG handler
#
# See https://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::ApacheMP2::Main;

use strict;
use AutoLoader 'AUTOLOAD';
use Apache2::RequestUtil;
use Apache2::RequestRec;
use Apache2::Log;
use Apache2::ServerUtil;
use Apache2::Connection;
use Apache2::RequestIO;
use Apache2::Const;
use Apache2::Filter;
use APR::Table;
use Apache2::Const -compile =>
  qw(FORBIDDEN HTTP_UNAUTHORIZED REDIRECT OK DECLINED DONE SERVER_ERROR AUTH_REQUIRED HTTP_SERVICE_UNAVAILABLE);
use base 'Lemonldap::NG::Handler::Main';

use constant FORBIDDEN         => Apache2::Const::FORBIDDEN;
use constant HTTP_UNAUTHORIZED => Apache2::Const::HTTP_UNAUTHORIZED;
use constant REDIRECT          => Apache2::Const::REDIRECT;
use constant OK                => Apache2::Const::OK;
use constant DECLINED          => Apache2::Const::DECLINED;
use constant DONE              => Apache2::Const::DONE;
use constant SERVER_ERROR      => Apache2::Const::SERVER_ERROR;
use constant AUTH_REQUIRED     => Apache2::Const::AUTH_REQUIRED;
use constant MAINTENANCE       => Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
use constant BUFF_LEN          => 8192;

our $VERSION = '2.0.6';

# Set default logger
use constant defaultLogger => 'Lemonldap::NG::Common::Logger::Apache2';

# Set also default logger for PSGI launched in the same Perl process
$ENV{LLNG_DEFAULTLOGGER} ||= 'Lemonldap::NG::Common::Logger::Apache2';

eval { require threads::shared; };

our $request;    # Apache2::RequestRec object for current request

#*run = \&Lemonldap::NG::Handler::Main::run;

$ENV{LLNGSTATUSLISTEN} ||= 'localhost:64321';
__PACKAGE__->init();

# INTERNAL METHODS

## @method void thread_share(string $variable)
# try to share $variable between threads
# note: eval is needed,
# else it fails to compile if threads::shared is not loaded
# @param $variable the name of the variable to share
sub thread_share {
    my ( $class, $variable ) = @_;
    eval "threads::shared::share(\$variable);";
}

## @method void setServerSignature(string sign)
# modifies web server signature
# @param $sign String to add to server signature
sub setServerSignature {
    my ( $class, $sign ) = @_;
    eval {
        Apache2::ServerUtil->server->push_handlers(
            PerlPostConfigHandler => sub {
                my ( $c, $l, $t, $s ) = @_;
                $s->add_version_component($sign);
            }
        );
    };
}

## @method void set_user(string user)
# sets remote_user
# @param user string username
sub set_user {
    my ( $class, $request, $user ) = @_;
    $request->env->{'psgi.r'}->user($user);
}

## @method void set_custom(string custom)
# sets remote_custom
# @param custom string custom_header
sub set_custom {
    my ( $class, $request, $custom ) = @_;
    $request->env->{'psgi.r'}->subprocess_env( REMOTE_CUSTOM => $custom )
      if defined $custom;
}

## @method void set_header_in(hash headers)
# sets or modifies request headers
# @param headers hash containing header names => header value
sub set_header_in {
    my ( $class, $request, %headers ) = @_;
    while ( my ( $h, $v ) = each %headers ) {
        utf8::downgrade($v);
        $request->env->{'psgi.r'}->headers_in->set( $h => $v );
    }
}

## @method void unset_header_in(array headers)
# removes request headers
# This function looks a bit heavy: it is to ensure that if a request
# header 'Auth-User' is removed, 'Auth_User' be removed also
# @param headers array with header names to remove
sub unset_header_in {
    my ( $class, $request, @headers ) = @_;
    foreach my $h1 (@headers) {
        $h1 = lc $h1;
        $h1 =~ s/-/_/g;
        $request->env->{'psgi.r'}->headers_in->do(
            sub {
                my $h  = shift;
                my $h2 = lc $h;
                $h2 =~ s/-/_/g;
                $request->env->{'psgi.r'}->headers_in->unset($h)
                  if ( $h1 eq $h2 );
                return 1;
            }
        );
    }
}

## @method void set_header_out(hash headers)
# sets response headers
# @param headers hash containing header names => header value
sub set_header_out {
    my ( $class, $request, %headers ) = @_;
    while ( my ( $h, $v ) = each %headers ) {
        $request->env->{'psgi.r'}->err_headers_out->set( $h => $v );
    }
}

## @method boolean is_initial_req
# returns true unless the current request is a subrequest
# @return is_initial_req boolean
sub is_initial_req {
    return $_[1]->env->{'psgi.r'}->is_initial_req;
}

## @method void print(string data)
# write data in HTTP response body
# @param data Text to add in response body
sub print {
    my ( $class, $request, $data ) = @_;
    $request->env->{'psgi.r'}->print($data);
}

## @rmethod protected int redirectFilter(string url, Apache2::Filter f)
# Launch the current HTTP request then redirects the user to $url.
# Used by logout_app and logout_app_sso targets
# @param $url URL to redirect the user
# @param $f Current Apache2::Filter object
# @return Constant $class->OK
sub redirectFilter {
    my $class = shift;
    my $url   = shift;
    my $f     = shift;
    unless ( $f->ctx ) {

        # Here, we can use Apache2 functions instead of set_header_out
        # since this function is used only with Apache2.
        $f->r->status( $class->REDIRECT );
        $f->r->status_line("303 See Other");
        $f->r->headers_out->unset('Location');
        $f->r->err_headers_out->set( 'Location' => $url );
        $f->ctx(1);
    }
    while ( $f->read( my $buffer, 1024 ) ) {
    }
    $class->updateStatus( $f->r, '$class->REDIRECT',
        $class->data->{ $class->tsv->{whatToTrace} }, 'filter' );
    return $class->OK;
}

1;

__END__

## @method void addToHtmlHead(string data)
# add data at end of html head
# @param data Text to add in html head
sub addToHtmlHead {
    use APR::Bucket  ();
    use APR::Brigade ();
    my ( $class, $request, $data ) = @_;
    $request->{env}->{'psgi.r'}->add_output_filter(
        sub {
            my $f   = shift;
            my $bb  = shift;
            my $ctx = $f->ctx;

            #unless ($ctx) {
            #    $f->r->headers_out->unset('Content-Length');
            #}
            my $done   = 0;
            my $buffer = $ctx->{data} ? $ctx->{data} : '';
            my ( $bdata, $seen_eos ) = flatten_bb($bb);
            unless ($done) {
                $done = 1
                  if ( $bdata =~ s/(<\/head>)/$data$1/si
                    or $bdata =~ s/(<body>)/$1$data/si );
            }
            $buffer .= $bdata if ($bdata);
            if ($seen_eos) {
                my $len = length $buffer;
                $f->r->headers_out->set( 'Content-Length', $len );
                $f->print($buffer) if ($buffer);
            }
            else {
                $ctx->{data} = $buffer;
                $f->ctx($ctx);
            }
            return OK;
        }
    );
}

sub flatten_bb {
    my ($bb) = shift;

    my $seen_eos = 0;

    my @data;
    for ( my $b = $bb->first ; $b ; $b = $bb->next($b) ) {
        $seen_eos++, last if $b->is_eos;
        $b->read( my $bdata );
        push @data, $bdata;
    }
    return ( join( '', @data ), $seen_eos );
}

## @method void setPostParams(hashref $params)
# add or modify parameters in POST request body
# @param $params hashref containing name => value
sub setPostParams {
    my ( $class, $request, $params ) = @_;
    $request->{env}->{'psgi.r'}->add_input_filter(
        sub {
            my $f = shift;
            my $buffer;

            # Filter only POST request body
            if ( $f->r->method eq "POST" ) {
                my $body;
                while ( $f->read($buffer) ) { $body .= $buffer; }
                while ( my ( $name, $value ) = each(%$params) ) {
                    $body =~ s/((^|&))$name=[^\&]*/$1$name=$value/
                      or $body .= "&$name=$value";
                }
                $body =~ s/^&//;
                $f->print($body);
            }
            else {
                $f->print($buffer) while ( $f->read($buffer) );
            }
            return OK;
        }
    );
}

