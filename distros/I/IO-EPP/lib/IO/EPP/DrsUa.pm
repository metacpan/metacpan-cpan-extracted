package IO::EPP::DrsUa;

=encoding utf8

=head1 NAME

IO::EPP::DrsUa

=head1 SYNOPSIS

    use IO::EPP::DrsUa;

    # Parameters for IO::Socket::SSL
    my %sock_params = (
        PeerHost        => 'epp.uadns.com',
        PeerPort        => 700,
        # without certificate
        Timeout         => 30,
    );

    # Create object, get greeting and call login()
    my $conn = IO::EPP::DrsUa->new( {
        user => 'login',
        pass => 'xxxx',
        sock_params => \%sock_params,
        test_mode => 0, # real connect
    } );

    # Check domain
    my ( $answ, $code, $msg ) = $conn->check_domains( { domains => [ 'qqq.com.ua', 'aaa.biz.ua' ] } );

    # Call logout() and destroy object
    undef $conn;

=head1 DESCRIPTION

Module for work with nic.ua/drs.ua domains

Drs.ua is a registry for biz.ua, co.ua, pp.ua and reseller for other .ua tlds

drs.ua uses deprecated epp version 0.5 --
drs.ua использует устаревший epp версии 0.5 -- it uses hostAttr instead of hostObj

Features:

=over 4

=item *

special PP format

=item *

the contact id must be suffixed on "-cunic"

=item *

need full name in contact:update

=item *

to change the email address, you need to update the contact, not change the contact id

=item *

additional extensions with login should be passed as objURI, not extURI

=item *

contacts have only type loc

=item *

no commands host:check, host:create, host:update (consequence of hostAttr)

=item *

cannot use punycode in the email to the left of @

=item *

in contacts for an individual, the company field must be empty

=item *

domains in the zone pp.ua you can not delete, you can only not confirm the sms about registration or renewal so that they themselves are deleted

=item *

the disclose flag only works for biz.ua, co.ua

For pp.ua you can't hide contacts

In other tlds Privacy Protection must be performed on the client side

=item *

epp poll sends only the transaction number and also the result in the form of ok or fail, without the domain name or contact id

=back

Documentation:
L<http://drs.ua/rus/policy.html>,
L<http://tools.ietf.org/html/rfc3730>

=cut

use IO::EPP::Base;
use parent qw( IO::EPP::Base );

use strict;
use warnings;


sub make_request {
    my ( $action, $params ) = @_;

    my ( $self, $code, $msg, $answ );

    unless ( $params->{conn} ) {
        $params->{sock_params}{PeerHost} ||= 'epp.uadns.com';
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

Further overlap functions where the provider has features

=cut

sub login {
    my ( $self, $pw ) = @_;

    # wihout urn:ietf:params:xml:ns:host
    my $svcs = '
    <objURI>urn:ietf:params:xml:ns:contact-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:domain-1.0</objURI>';

    my $extension = '
     <objURI>http://drs.ua/epp/drs-1.0</objURI>'; # objURI !!! not extURI !!!

    return $self->SUPER::login( $pw, $svcs, $extension );
}


sub _prepare_contact {
    my ( $params ) = @_;

    # int only:  code: 2400, msg: Only 'loc' type of postal info is supported
    # int + loc: code: 2400, msg: Multiple postal info not supported
    unless ( $$params{'loc'} ) {
        foreach my $f ( 'name','first_name','last_name','company','addr','city','state','postcode','country_code' ) {
            $$params{'loc'}{$f} = delete $$params{$f} if defined $$params{$f};
        }
    }
}

=head1 create_contact

It has many features, see the description of the module above

=cut

sub create_contact {
    my ( $self, $params ) = @_;

    _prepare_contact( $params );

    my $visible = $$params{pp_flag} ? 0 : 1;

    # This format is feature drs, but for biz.ua, co.ua only
    $params->{pp_ext} = '
     <contact:disclose flag="'.$visible.'">
      <contact:name type="loc"/>
      <contact:org type="loc"/>
      <contact:addr type="loc"/>
      <contact:voice/>
      <contact:fax/>
      <contact:email/>
     </contact:disclose>';

    return $self->SUPER::create_contact( $params );
}

=head1 update_contact

It has many features, see the description of the module above

=cut

sub update_contact {
    my ( $self, $params ) = @_;

    _prepare_contact( $params );

    $params->{chg}{need_name} = 1;

    my $visible = $$params{pp_flag} ? 0 : 1;

    $params->{pp_ext} = '
     <contact:disclose flag="'.$visible.'">
      <contact:name type="loc"/>
      <contact:org type="loc"/>
      <contact:addr type="loc"/>
      <contact:voice/>
      <contact:fax/>
      <contact:email/>
     </contact:disclose>';

    return $self->SUPER::update_contact( $params );
}


sub create_domain_nss {
    my ( $self, $params ) = @_;

    my $nss = '';

    # Old EPP version, sbut it was resolved in https://tools.ietf.org/html/rfc3731
    foreach my $ns ( @{$params->{nss}} ) {
        $nss .= "     <domain:hostAttr>\n      <domain:hostName>$ns</domain:hostName>\n     </domain:hostAttr>\n";
    }

    $nss = "\n    <domain:ns>\n$nss    </domain:ns>" if $nss;

    return $nss;
}


sub create_domain {
    my ( $self, $params ) = @_;

    $params->{authinfo} ||= IO::EPP::Base::gen_pw( 16 );

    return $self->SUPER::create_domain( $params );
}


sub update_domain_add_nss {
    my ( $self, $params ) = @_;

    my $add = "     <domain:ns>\n";

    # Old EPP version, see in https://tools.ietf.org/html/rfc3731
    foreach my $ns ( @{$$params{add}{nss}} ) {
        $add .= "      <domain:hostAttr>\n       <domain:hostName>$$ns{ns}</domain:hostName>\n";
        if ( $ns->{ips} ) {
            foreach my $ip ( @{$ns->{ips}} ) {
                if ( $ip =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
                    $add .= "       <domain:hostAddr ip=\"v4\">$ip</domain:hostAddr>\n";
                }
                else {
                    $add .= "       <domain:hostAddr ip=\"v6\">$ip</domain:hostAddr>\n";
                }
            }
        }

        $add .= "      </domain:hostAttr>\n";
    }

    $add .= "     </domain:ns>\n";

    return $add;
}


sub update_domain_rem_nss {
    my ( $self, $params ) = @_;

    my $rem = "     <domain:ns>\n";

    # Old EPP version, see in  https://tools.ietf.org/html/rfc3731
    foreach my $ns ( @{$$params{rem}{nss}} ) {
        $rem .= "      <domain:hostAttr>\n       <domain:hostName>$$ns{ns}</domain:hostName>\n";

        if ( $ns->{ips} ) {
            foreach my $ip ( @{$ns->{ips}} ) {
                if ( $ip =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
                    $rem .= "       <domain:hostAddr ip=\"v4\">$ip</domain:hostAddr>\n";
                }
                else {
                    $rem .= "       <domain:hostAddr ip=\"v6\">$ip</domain:hostAddr>\n";
                }
            }
        }

        $rem .= "      </domain:hostAttr>\n";
    }

    $rem .= "     </domain:ns>\n";

    return $rem;
}


sub update_domain {
    my ( $self, $params ) = @_;

    $params->{nss_as_attr} = 1;

    return $self->SUPER::update_domain( $params );
}

=head1 req_poll

It has many features, see the description of the module above

=cut

sub req_poll_rdata {
    my ( $self, $rdata, undef ) = @_;

    my %info;

    if ( $rdata =~ /^<domain:trnData/ ) {
        # TRANSFER_PENDING, TRANSFER_CLIENT_APPROVED, TRANSFER_SERVER_APPROVED
        $info{transfer} = {};
        ( $info{transfer}{dname}  ) = $rdata =~ /<domain:name>([^<>]+)<\/domain:name>/;
        ( $info{transfer}{status} ) = $rdata =~ /<domain:trStatus>([^<>]+)<\/domain:trStatus>/;

        my %id = %IO::EPP::Base::id;
        foreach my $k ( keys %id ) {
            if ( $rdata =~ /<domain:$k>([^<>]+)<\/domain:$k>/ ) {
                $info{transfer}{$id{$k}} = $1;
            }
        }
        #( $info{transfer}{from}   ) = $rdata =~ /<domain:acID>([^<>]+)<\/domain:acID>/;
        #( $info{transfer}{to}     ) = $rdata =~ /<domain:reID>([^<>]+)<\/domain:reID>/;
        my %dt = %IO::EPP::Base::dt;
        foreach my $k ( keys %dt ) {
            if ( $rdata =~ /<domain:$k>([^<>]+)<\/domain:$k>/ ) {
                $info{transfer}{$dt{$k}} = IO::EPP::Base::cldate( $1 );
            }
        }
    }
    elsif ( $rdata =~ /^<domain:panData/ ) {
        # Pending action completed with error.
        # Pending action completed successfully.
        $info{upd_del} = {};
        ( $info{upd_del}{result}, $info{upd_del}{dname} ) = $rdata =~ /<domain:name paResult="([^"]+)">([^<>]+)<\/domain:name>/;

        if ( $rdata =~ /<domain:paTRID>(.+)<\/domain:paTRID>/ ) {
            my $trids = $1;
            ( $info{upd_del}{cltrid} ) = $trids =~ /<clTRID>([^<>]+)<\/clTRID>/;
            ( $info{upd_del}{svtrid} ) = $trids =~ /<svTRID>([^<>]+)<\/svTRID>/;
        }

        if ( $rdata =~ /<domain:paDate>([^<>]+)<\/domain:paDate>/ ) {
            $info{upd_del}{date} = IO::EPP::Base::cldate( $1 );
        }
    }
    elsif ( $rdata =~ /^<drs:notify/ ) {
        # drs feature
        $info{notify} = {};
        ( $info{notify}{type}    ) = $rdata =~ /<drs:type>([^<>]+)<\/drs:type>/;       # command
        ( $info{notify}{object}  ) = $rdata =~ /<drs:object>([^<>]+)<\/drs:object>/;   # domain
        ( $info{notify}{message} ) = $rdata =~ /<drs:message>([^<>]+)<\/drs:message>/; #
    }
    else {
        return ( 0, 'New DrsUa message type!' );
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

