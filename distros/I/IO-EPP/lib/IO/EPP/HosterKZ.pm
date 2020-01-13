package IO::EPP::HosterKZ;

=encoding utf8

=head1 NAME

IO::EPP::HosterKZ

=head1 SYNOPSIS

    use IO::EPP::HosterKZ;

    # All queries are atomic, creating an object doesn't make sense
    sub make_request {
        my ( $action, $params ) = @_;

        $params->{user} = 'login';
        $params->{pass} = 'xxxxx';

        # Parameters for LWP
        my %sock_params = (
            PeerHost        => 'https://billing.hoster.kz/api/',
            PeerPort        => 443,
            Timeout         => 30,
        );

        $params->{sock_params} = \%sock_params;

        return IO::EPP::HosterKZ::make_request( $action, $params );
    }

    # Check domain
    my ( $answ, $msg ) = make_request( 'check_domains', { domains => [ 'hoster.kz' ] } );

=head1 DESCRIPTION

Work with reseller hoster.kz epp api

The module works via LWP

Features:

=over 3

=item *

not the full epp protocol

=item *

works over https

=item *

there are no login and logout commands

=item *

no session

=item *

no epp header in request, but has in answer

=item *

need name in update_contact

=item *

not has epp poll

=item *

transfer without renew

=item *

many features at prolongation and autorenew

=back

Documentation:
L<https://hoster.kz/upload/api_hosterkz.pdf>

=cut

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use Time::HiRes qw(time);

use IO::EPP::Base;
use parent qw( IO::EPP::Base );

use strict;
use warnings;


sub make_request {
    my ( $action, $params ) = @_;

    $params = IO::EPP::Base::recursive_utf8_unflaged( $params ); # LWP does not support utf8 flag

    my ( $self, $code, $msg, $answ );

    unless ( $params->{conn} ) {
        # Default:
        $params->{sock_params}{PeerHost} ||= 'https://billing.hoster.kz/api/';
        $params->{sock_params}{PeerPort} ||= 443;

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

    $msg .= '; ' . $self->{critical_error} if $self->{critical_error};

    my $full_answ = "code: $code\nmsg: $msg";

    $answ = {} unless $answ && ref $answ;

    $answ->{code} = $code;
    $answ->{msg}  = $msg;

    return wantarray ? ( $answ, $full_answ, $self ) : $answ;
}


=head1 METHODS

=head2 req

Completely replaces IO::EPP::Base::req because it works via LWP

=cut


sub req {
    my ( $self, $out_data, $info ) = @_;

    $out_data =~ s/^\n//s;
    $out_data =~ s/\n<\/epp>//; # !!!

    $info ||= '';

    if ( $out_data ) {
        my $d = $out_data;
        # remove password, authinfo from log
        $d =~ s/<pw>[^<>]+<\/pw>/<pw>xxxxx<\/pw>/;

        $self->epp_log( "$info request:\n$d" );
    }

    my $THRESHOLD = 100000000;

    my $start_time = time;

    #my $cookie = HTTP::Cookies->new;

    my $ua = LWP::UserAgent->new(
        agent      => 'EppBot/7.02 (Perl; Linux i686; ru, en_US)',
        parse_head =>  0,
        #keep_alive => 30,
        #cookie_jar => $cookie,
        #%ua_params,
    );

    my $in_data;

    eval {
        local $SIG{ALRM} = sub { die "connection timeout\n" };

        alarm 120;

        my $req = POST $self->{url}, [
            login => $self->{user},
            psw   => $self->{pass},
            xml   => $out_data,
        ];

        my $res = $ua->request( $req );

        alarm 0;

        if ( $res->is_success ) {
            $in_data = $res->content;

            die "data length is zero\n" unless $in_data;

            my $data_size = length $in_data;

            die "data length is $data_size which exceeds $THRESHOLD\n" if $data_size > $THRESHOLD;
        }
        else {
            die "fail answer: " . $res->as_string . "\n";
        }

        1;
    }
    or do {
        my $err = $@;

        alarm 0;

        my $req_time = sprintf( '%0.4f', time - $start_time );
        $self->epp_log( "req_time: $req_time\n$info req error: $err" );

        $self->{critical_error} = "req error: $err";

        return;
    };

    my $req_time = sprintf( '%0.4f', time - $start_time );

    # "Authentication error" - work with normal code & msg
    # "User regikz_user already has more than.*active connections" - we did not see yet

    $self->epp_log( "req_time: $req_time\n$info answer:\n$in_data\n" );

    return $in_data;
}


sub new {
    my ( $package, $params ) = @_;

    my ( $self, $code, $msg );

    my $sock_params   = delete $params->{sock_params};

    my $test = delete $params->{test_mode};

    $self = bless {
        sock           => 'https', # no session
        user           => delete $params->{user},
        pass           => delete $params->{pass}, # !!! Send login and password with each request
        url            => $sock_params->{PeerHost},
        local_ip       => $sock_params->{LocalAddr},
        timeout        => $sock_params->{Timeout},
        tld            => $params->{tld} || '',
        server         => delete $params->{server},
        log_name       => delete $params->{log_name},
        log_fn         => delete $params->{log_fn},
        no_log         => delete $params->{no_log} || 0,
        test           => $test,
        critical_error => undef,
    }, $package;

    $self->set_urn();

    $self->set_log_vars( $params );

    $self->epp_log( "Connect to $$sock_params{PeerHost}\n" );

    return wantarray ? ( $self, '1000', 'ok' ) : $self;
}


sub set_urn {
    $_[0]->{urn} = {
        head => '', # !!!
        cont => $IO::EPP::Base::epp_cont_urn,
        host => $IO::EPP::Base::epp_host_urn,
        dom  => $IO::EPP::Base::epp_dom_urn,
    };
}


sub create_contact {
    my ( $self, $params ) = @_;

    $params->{cont_id}  = IO::EPP::Base::gen_id( 16 );

    $params->{authinfo} = IO::EPP::Base::gen_pw( 16 );

    return $self->SUPER::create_contact( $params );
}


sub update_contact {
    my ( $self, $params ) = @_;

    $params->{company} =~ s/&/&amp;/g
        if $params->{company};

    $params->{need_name} = 1;

    return $self->SUPER::update_contact( $params );
}

=head2 create_domain

Since September 7, 2010, for Kazakhstan domains, you need to fill in data on the location of the server equipment
on which the site is located, accessible by this domain name.
The server equipment should be located on the territory of Kazakhstan.

C<server_loc> -- hashref with parameters:

C<srvloc_state> -- server location area or region;
C<srvloc_city>  -- city;
C<srvloc_street> -- address in the city.

=cut

sub create_domain {
    my ( $self, $params ) = @_;

    $params->{authinfo} ||= IO::EPP::Base::gen_pw( 16 );

    if ( $params->{server_loc} ) {
        my $server_loc = delete $params->{server_loc};

        $params->{extension} =
'   <srvloc:create xmlns:srvloc="urn:kaznic:params:xml:ns:srvloc-1.0" xsi:schemaLocation="urn:kaznic:params:xml:ns:srvloc-1.0 srvloc-1.0.xsd">
    <srvloc:street>'.$server_loc->{srvloc_street}.'</srvloc:street>
    <srvloc:city>'.$server_loc->{srvloc_city}.'</srvloc:city>
    <srvloc:sp>'.$server_loc->{srvloc_state}.'</srvloc:sp>
   </srvloc:create>';
    }

    return $self->SUPER::create_domain( $params );
}


sub transfer {
    my ( $self, $params ) = @_;

    $params->{authinfo} =~ s/&/&amp;/g;
    $params->{authinfo} =~ s/</&lt;/g;
    $params->{authinfo} =~ s/>/&gt;/g;

    return $self->SUPER::request_transfer( $params );
}

=head2 update_domain

See L</create_domain> for C<server_loc> parameters.

=cut

sub update_domain {
    my ( $self, $params ) = @_;

    if ( $params->{server_loc} ) {
        my $server_loc = delete $params->{server_loc};

        $params->{extension} =
'   <srvloc:create xmlns:srvloc="urn:kaznic:params:xml:ns:srvloc-1.0" xsi:schemaLocation="urn:kaznic:params:xml:ns:srvloc-1.0 srvloc-1.0.xsd">
    <srvloc:street>'.$server_loc->{srvloc_street}.'</srvloc:street>
    <srvloc:city>'.$server_loc->{srvloc_city}.'</srvloc:city>
    <srvloc:sp>'.$server_loc->{srvloc_state}.'</srvloc:sp>
   </srvloc:create>';
    }

    return $self->SUPER::update_domain( $params );
}

=head2 logout

For replace IO::EPP::Base::logout.

Do nothing.

=cut

sub logout {
    my ( $self ) = @_;

    $self->epp_log( "</logout>" );

    delete $self->{sock};
    delete $self->{user};
    delete $self->{pass};

    return ( undef, '1500', 'ok' );
}


sub DESTROY {
    my ( $self ) = @_;

    local ($!, $@, $^E, $?); # Protection against action-at-distance

    $self->logout();

    if ( $self->{log_fh} ) {
        close $self->{log_fh};

        delete $self->{log_fh};
    }
}

1;

__END__

=pod

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
