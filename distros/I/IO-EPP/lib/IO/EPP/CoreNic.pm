package IO::EPP::CoreNic;

=encoding utf8

=head1 NAME

IO::EPP::CoreNic

=head1 SYNOPSIS

    use IO::EPP::CoreNic;

    # Parameters for IO::Socket::SSL
    my %sock_params = (
        PeerHost        => 'epp.nic.xn--80aswg',
        PeerPort        => 700,
        # without certificate
        Timeout         => 30,
    );

    # Create object, get greeting and call login()
    my $conn = IO::EPP::CoreNic->new( {
        user => 'login',
        pass => 'xxxx',
        sock_params => \%sock_params,
        test_mode => 0, # real connect
    } );

    # Check domain
    my ( $answ, $code, $msg ) = $conn->check_domains( { domains => [ 'xn--d1acufc.xn--80aswg' ] } );

    # Call logout() and destroy object
    undef $conn;

=head1 DESCRIPTION

Module for work with CoreNic domains

Feature: in all responses incomplete xml schemas, for example, instead of C<< <domain:update> >> is written C<< <update> >>

=cut

use IO::EPP::Base;
use parent qw( IO::EPP::Base );

use strict;
use warnings;


sub make_request {
    my ( $action, $params ) = @_;

    $params = IO::EPP::Base::recursive_utf8_unflaged( $params );

    if ( !$params->{tld}  &&  $params->{dname} ) {
        ( $params->{tld} ) = $params->{dname} =~ /^[0-9a-z\-]+\.(.+)$/;
    }

    my ( $self, $code, $msg, $answ );

    unless ( $params->{conn} ) {
        $params->{sock_params}{PeerHost} ||= 'epp.nic.xn--80aswg';
        $params->{sock_params}{PeerPort} ||= 700;

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

Next, those functions are redefined in which the provider has additions to the EPP

=head2 login

Ext params for login,

INPUT: new password for change

=cut

sub login {
    my ( $self, $pw ) = @_;

    my ( $svcs, $extension );

        $svcs = '
    <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:domain-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:contact-1.0</objURI>';
        $extension = '
     <extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI>
     <extURI>http://xmlns.corenic.net/epp/idn-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:launch-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>';

     # <extURI>http://xmlns.corenic.net/epp/auction-1.0</extURI>

    return $self->SUPER::login( $pw, $svcs, $extension );
}


sub cont_from_xml {
    my ( undef, $rdata ) = @_;

    my %cont;

    ( $cont{cont_id} ) = $rdata =~ /<id>([^<>]+)<\/id>/;

    ( $cont{roid} ) = $rdata =~ /<roid>([^<>]+)<\/roid>/;

    my @atypes = ( 'int', 'loc' );
    foreach my $atype ( @atypes ) {
        my ( $postal ) = $rdata =~ /<postalInfo type="$atype">(.+?)<\/postalInfo>/;

        next unless $postal;

        ( $cont{$atype}{name} ) = $postal =~ /<name>([^<>]+)<\/name>/;

        ( $cont{$atype}{company} ) = $rdata =~ /<org>([^<>]*)<\/org>/;

        $cont{$atype}{addr} = join(', ', $postal =~ /<street>([^<>]*)<\/street>/ );

        ( $cont{$atype}{city} ) = $postal =~ /<city>([^<>]*)<\/city>/;

        ( $cont{$atype}{'state'} ) = $postal =~ /<sp>([^<>]*)<\/sp>/;

        ( $cont{$atype}{postcode} ) = $postal =~ /<pc>([^<>]*)<\/pc>/;

        ( $cont{$atype}{country_code} ) = $postal =~ /<cc>([A-Z]+)<\/cc>/;
    }

    ( $cont{phone} ) = $rdata =~ /<voice[^<>]*>([0-9+.]*)<\/voice>/;

    ( $cont{fax} ) = $rdata =~ /<fax[^<>]*>([0-9+.]*)<\/fax>/;

    ( $cont{email} ) = $rdata =~ /<email>([^<>]+)<\/email>/;

    # <status s="linked"/>
    my @ss = $rdata =~ /<status s="([^"]+)"\/>/g;
    $cont{statuses}{$_} = '+' for @ss;

    if ( $rdata =~ /<authInfo><pw>(.+?)<\/pw>/ ) {
        $cont{authinfo} = $1;
    }

    my ( $visible ) = $rdata =~ /<contact:disclose flag=['"](\d)['"]>/;
    $cont{pp_flag} = $visible ? 0 : 1;

    my %id = %IO::EPP::Base::id;
    foreach my $k ( keys %id ) {
        if ( $rdata =~ /<$k>([^<>]+)<\/$k>/ ) {
            $cont{$id{$k}} = $1;
        }
    }

    my %dt = %IO::EPP::Base::dt;
    foreach my $k ( keys %dt ) {
        if ( $rdata =~ /<$k>([^<>]+)<\/$k>/ ) {
            $cont{$dt{$k}} = $1;

            $cont{$dt{$k}} =~ s/T/ /;
            $cont{$dt{$k}} =~ s/\.\d+Z$//;
        }
    }

    return \%cont;
}


sub update_contact {
    my ( $self, $params ) = @_;

    if ( $params->{chg} ) {
        $params->{chg}{need_name} = 1;
        $params->{chg}{authinfo}  = IO::EPP::Base::gen_pw( 12 );
    }

    return $self->SUPER::update_contact( $params );
}

sub get_ns_info_rdata {
    my ( undef, $rdata ) = @_;

    my %ns;

    ( $ns{name} ) = $rdata =~ /<name>([^<>]+)<\/name>/;
    $ns{name} = lc $ns{name};

    ( $ns{roid} ) = $rdata =~ /<roid>([^<>]+)<\/roid>/;

    # <host:status s="ok"/>
    my @ss = $rdata =~ /<status s="([^"]+)"\s*\/>/g;
    $ns{statuses}{$_} = '+' for @ss;

    $ns{addrs} = [ $rdata =~ /<addr ip="v\d">([0-9A-Fa-f.:]+)<\/addr>/g ];

    my %id = %IO::EPP::Base::id;
    foreach my $k ( keys %id ) {
        if ( $rdata =~ /<$k>([^<>]+)<\/$k>/ ) {
            $ns{$id{$k}} = $1;
        }
    }

    my %dt = %IO::EPP::Base::dt;
    foreach my $k ( keys %dt ) {
        if ( $rdata =~ /<$k>([^<>]+)<\/$k>/ ) {
            $ns{$dt{$k}} = $1;

            $ns{$dt{$k}} =~ s/T/ /;
            $ns{$dt{$k}} =~ s/\.\d+Z$//;
        }
    }

    return \%ns;
}


sub check_domains_rdata {
    my ( undef, $rdata ) = @_;

    my @aa = $rdata =~ /<cd>(<name avail="[a-z]+">[^<>]+<\/name>(?:<reason>[^<>]+<\/reason>)?)<\/cd>/sg;

    my %domlist;
    foreach my $a ( @aa ) {
        if ( $a =~ /<name avail="(true|false)">([^<>]+)<\/name>/ ) {
            my $dm = lc($2);
            $domlist{$dm} = { avail => ( $1 eq 'true' ? 1 : 0 ) }; # no utf8, puny only

            if ( $a =~ /<reason>([^<>]+)<\/reason>/ ) {
                $domlist{$dm}{reason} = $1;
            }
        }
    }

    return \%domlist;
}


sub get_domain_info_rdata {
    my ( undef, $rdata ) = @_;

    my $info = {};

    ( $info->{dname} ) = $rdata =~ /<name>([^<>]+)<\/name>/;
    $info->{dname} = lc $info->{dname};

    # <domain:status s="ok"/>
    my @ss = $rdata =~ /<status s=['"]([^'"]+)['"]\s*\/?>/g;
    $info->{statuses}{$_} = '+' for @ss;

    ( $info->{reg_id} ) = $rdata =~ /<registrant>([^<>]+)<\/registrant>/;

    my @cc = $rdata =~ /<contact type=['"][^'"]+['"]>[^<>]+<\/contact>/g;
    foreach my $row ( @cc ) {
        if ( $row =~ /<contact type=['"]([^'"]+)['"]>([^<>]+)<\/contact>/ ) {
            $info->{ lc($1) . '_id' } = $2;
        }
    }

    if ( $rdata =~ /<hostObj>/ ) {
        $info->{nss} = [ $rdata =~ /<hostObj>([^<>]+)<\/hostObj>/g ];
    }

    if ( $info->{nss} ) {
        $info->{nss} = [ map{ lc $_ } @{$info->{nss}} ];
    }

    # domain-based nss
    if ( $rdata =~ /<host>/ ) {
        $info->{hosts} = [ $rdata =~ /<host>([^<>]+)<\/host>/g ];
        $info->{hosts} = [ map{ lc $_ } @{$info->{hosts}} ];
    }

    my %id = %IO::EPP::Base::id;
    foreach my $k ( keys %id ) {
        if ( $rdata =~ /<$k>([^<>]+)<\/$k>/ ) {
            $info->{$id{$k}} = $1;
        }
    }

    my %dt = %IO::EPP::Base::dt;
    foreach my $k ( keys %dt ) {
        if ( $rdata =~ /<$k>([^<>]+)<\/$k>/ ) {
            $info->{$dt{$k}} = $1;

            $info->{$dt{$k}} =~ s/T/ /;
            $info->{$dt{$k}} =~ s/\.\d+Z$//;
        }
    }

    if ( $rdata =~ /authInfo.+<pw>([^<>]+)<\/pw>.+authInfo/s ) {
        ( $info->{authinfo} ) = $1;

        #$info->{authinfo} =~ s/&gt;/>/g;
        #$info->{authinfo} =~ s/&lt;/</g;
        #$info->{authinfo} =~ s/&amp;/&/g;
    }

    return $info;
}


sub req_poll_rdata {
    my ( $self, $rdata, undef ) = @_;

    my %info;

    if ( $rdata =~ /^<trnData[^<>]*>(.+)<\/trnData>/ ) {
        my $trn = $1;
        $info{transfer} = {};
        ( $info{transfer}{dname}  ) = $trn =~ /<name>([^<>]+)<\/name>/;
        ( $info{transfer}{status} ) = $trn =~ /<trStatus>([^<>]+)<\/trStatus>/;

        my %id = %IO::EPP::Base::id;
        foreach my $k ( keys %id ) {
            if ( $rdata =~ /<domain:$k>([^<>]+)<\/domain:$k>/ ) {
                $info{transfer}{$id{$k}} = $1;
            }
        }
    }
    else {
        return ( 0, 'New CoreNic message type!' );
    }

    return ( \%info, '' );
}


1;


__END__

=pod

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

