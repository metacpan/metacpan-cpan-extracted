package IO::EPP::Taeping;

=encoding utf8

=head1 NAME

IO::EPP::Taeping

=head1 SYNOPSIS

    use IO::EPP::Taeping;

    # Parameters for LWP
    my %sock_params = (
        PeerHost        => 'epp.nic.net.ru',
        PeerPort        => 7080,
        SSL_key_file    => 'key_file.pem',
        SSL_cert_file   => 'cert_file.pem',
        LocalAddr       => '1.2.3.4',
        Timeout         => 30,
    );

    # Create object, get greeting and call login()
    my $conn = IO::EPP::Taeping->new( {
        user => 'XXX-3LVL',
        pass => 'XXXXXXXX',
        sock_params => \%sock_params,
        test_mode => 0, # real connect
    } );

    # Check domain
    my ( $answ, $code, $msg ) = $conn->check_domains( { domains => [ 'org.info' ] } );

    # Call logout() and destroy object
    undef $conn;


=head1 DESCRIPTION

Module overwrites IO::EPP::RIPN where there are differences
and work with tcinet epp using http api

Previously 3lvl.ru domains were serviced by TCI, but then were transferred to a separate registry, which has small differences

For details see:
L<https://nic.net.ru/docs/EPP-3LVL.pdf>

All documents -- L<http://pp.ru/documents.html>

IO::EPP::Taeping works with .net.ru, .org.ru  & .pp.ru only

Domain transfer in these zones works as in the .su tld

=cut

use IO::Socket::SSL;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Cookies;
use Time::HiRes qw( time );

use IO::EPP::Base;
use IO::EPP::RIPN;
use parent qw( IO::EPP::RIPN );

use strict;
use warnings;


sub make_request {
    my ( $action, $params ) = @_;

    #$params = IO::EPP::Base::recursive_utf8_unflaged( $params );

    my ( $code, $msg, $answ, $self );

    unless ( $params->{conn} ) {
        # Default:
        $params->{sock_params}{PeerHost} ||= 'epp.nic.net.ru';
        $params->{sock_params}{PeerPort} ||= 7080;

        ( $self, $code, $msg ) = __PACKAGE__->new( $params );

        unless ( $code  and  $code == 1000 ) {
            goto END_MR;
        }
    }
    else {
        $self = $params->{conn};
    }

    $self->{critical_error} = '';

    if ( $self->can( $action ) ) {
        ( $answ, $code, $msg ) = $self->$action( $params );
    }
    else {
        $msg = "undefined command <$action>, request cancelled";
        $code = 0;
    }

END_MR:

    $msg .= ', ' . $self->{critical_error} if $self->{critical_error};

    my $full_answ = "code: $code\nmsg: $msg";

    $answ = {} unless $answ && ref $answ;

    $answ->{code} = $code;
    $answ->{msg}  = $msg;

    return wantarray ? ( $answ, $full_answ, $self ) : $answ;
}


=head1 METHODS

=head2 new

Method is rewritten because of verify mode/hostname

=cut

sub new {
    my ( $package, $params ) = @_;

    my ( $self, $code, $msg );

    my $sock_params   = delete $params->{sock_params};

    $sock_params->{SSL_verify_mode} = SSL_VERIFY_NONE; # there are no words
    $sock_params->{verify_hostname} = 0;

    # Further all as in the RIPN

    my $host          = $sock_params->{PeerHost};
    my $port          = $sock_params->{PeerPort};
    my $url           = "https://$host:$port";
    my $local_address = $sock_params->{LocalAddr};
    my $timeout       = $sock_params->{Timeout} || 5;

    my %ua_params = ( ssl_opts => $sock_params );
    $ua_params{local_address} = $local_address if $local_address;

    if ( $timeout ) {
        # LWP feature: first param for LWP, second - for IO::Socket
        $ua_params{timeout} = $timeout;
        $ua_params{Timeout} = $timeout;
    }

    my $cookie;
    if ( $params->{alien_conn} ) {
        $cookie = HTTP::Cookies->new( autosave => 0 );

        unless ( $cookie->load( $params->{load_cook_from} ) ) {
            $msg = "load cooker is fail";
            $code = 0;

            goto ERR;
        }
    }
    else {
        $cookie = HTTP::Cookies->new;
    }

    my $ua = LWP::UserAgent->new(
        agent      => 'EppBot/7.02 (Perl; Linux i686; ru, en_US)',
        parse_head =>  0,
        keep_alive => 30,
        cookie_jar => $cookie,
        %ua_params,
    );

    unless ( $ua ) {
        $msg = "can not connect";
        $code = 0;

        goto ERR;
    }

    $self = bless {
        sock     => $ua,
        user     => $params->{user},
        url      => $url,
        cookies  => $cookie,
        no_logs  => delete $params->{no_logs},
        alien    => $params->{alien_conn} ? 1 : 0,
    };

    $self->set_urn();

    $self->set_log_vars( $params );

    if ( $self->{alien} ) {
        return wantarray ? ( $self, 1000, 'ok' ) : $self;
    }

    # Get HEADER only
    $self->epp_log( "HEAD connect to $url from $local_address" );

    my $request = HTTP::Request->new( HEAD => $url ); # не POST
    my $response = $ua->request( $request );

    my $rcode = $response->code;
    $self->epp_log( "header answ code: $rcode" );

    unless ( $rcode == 200 ) {
        $code = 0;
        $msg  = "Can't open socket";

        goto ERR;
    }

    my $headers = $response->headers;

    my $length = $headers->content_length;
    $self->epp_log( "header content-length == $length" );

    if ( $length == 0 ) {
        $code = 0;
        $msg  = "Can't open socket";

        goto ERR;
    }

    my ( undef, $c0, $m0 ) = $self->hello();

    unless ( $c0  &&  $c0 == 1000 ) {
        $code = 0;
        $msg = "Can't get greeting";
        $msg .= '; ' . $self->{critical_error} if $self->{critical_error};

        goto ERR;
    }


    my ( undef, $c1, $m1 ) = $self->login( delete $params->{pass} ); # no password in object

    if ( $c1  &&  $c1 == 1000 ) {
        return wantarray ? ( $self, $c1, $m1 ) : $self;
    }

    $msg = ( $m1 || '' ) . $self->{critical_error};
    $code = $c1 || 0;

ERR:
    return wantarray ? ( 0, $code, $msg ) : 0;
}

=head2 get_billing_info, get_limits_info, get_stat_info

Not support

=cut

sub get_billing_info {
    return wantarray ? ( 0, 0, 'not work' ) : 0;
}


sub get_limits_info {
    return wantarray ? ( 0, 0, 'not work' ) : 0;
}


sub get_stat_info {
    return wantarray ? ( 0, 0, 'not work' ) : 0;
}


1;


__END__

=pod

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
