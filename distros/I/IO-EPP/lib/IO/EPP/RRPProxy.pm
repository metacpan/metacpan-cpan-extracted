package IO::EPP::RRPProxy;

=encoding utf8

=head1 NAME

IO::EPP::RRPProxy

=head1 SYNOPSIS

    use IO::EPP::RRPProxy;

    # Parameters for IO::Socket::SSL
    my %sock_params = (
        PeerHost        => 'epp.rrpproxy.net',
        PeerPort        => 700,
        Timeout         => 30,
    );

    # Create object, get greeting and call login()
    my $conn = IO::EPP::RRPProxy->new( {
        user => 'login',
        pass => 'xxxxx',
        sock_params => \%sock_params,
        test_mode => 0, # real connect
    } );

    # Check domain
    my ( $answ, $code, $msg ) = $conn->check_domains( { domains => [ 'info.name', 'name.info' ] } );

    # Call logout() and destroy object
    undef $conn;

=head1 DESCRIPTION

Work with RRPProxy EPP API

Features:

=over 3

item *

has its own epp extension <keysys:*> for specifying additional parameters;

=item *

has additional functions.

=back

Examples: L<https://wiki.rrpproxy.net/EPP>, L<https://wiki.rrpproxy.net/api/epp-server/epp-command-reference>.

=cut

use IO::EPP::Base;
use parent qw( IO::EPP::Base );

use strict;
use warnings;

my $ks_ext = 'xmlns:keysys="http://www.key-systems.net/epp/keysys-1.0"';

sub make_request {
    my ( $action, $params ) = @_;

    my ( $self, $code, $msg, $answ );

    unless ( $params->{conn} ) {
        $params->{sock_params}{PeerHost} ||= 'epp.rrpproxy.net';
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

=head2 login

Ext params for login,

INPUT: new password for change

=cut

sub login {
    my ( $self, $pw ) = @_;

    my $svcs = '
    <objURI>urn:ietf:params:xml:ns:contact-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:domain-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>';

    my $extension = '
     <extURI>http://www.key-systems.net/epp/keysys-1.0</extURI>
     <extURI>http://www.key-systems.net/epp/query-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>
     <extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:launchphase-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:launch-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:idn-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:fee-0.7</extURI>';

    return $self->SUPER::login( $pw, $svcs, $extension );
}

=head2 create_contact

Contact id is generated automatically by the reseller

=cut

sub create_contact {
    my ( $self, $params ) = @_;

    $params->{id} = 'AUTO';

    $params->{company} =~ s/&/&amp;/g  if $params->{company};
    $params->{addr}    =~ s/&/&amp;/g  if $params->{addr};

=pod

    For german characters changes html codes to double symbols:
    ß = ss
    ä = ae
    ü = ue
    ö = oe

=cut
    foreach my $f ( 'name', 'company', 'addr', 'city', 'state' ) {
        next unless $params->{$f};

        $params->{$f} =~ s/&#196;/Ae/g;
        $params->{$f} =~ s/&#214;/Oe/g;
        $params->{$f} =~ s/&#220;/Ue/g;
        $params->{$f} =~ s/&#223;/ss/g;
        $params->{$f} =~ s/&#228;/ae/g;
        $params->{$f} =~ s/&#246;/oe/g;
        $params->{$f} =~ s/&#252;/ue/g;
    }

    # the extension fields must be arranged in alphabetical order

    my $fields = "\n     <keysys:forceDuplication>1</keysys:forceDuplication>\n";

    # each contact is registered separately even if they are the same
    $params->{extension} =
qq|   <keysys:create $ks_ext>
    <keysys:contact>$fields
    </keysys:contact>
   </keysys:create>
|;

    return $self->SUPER::create_contact( $params );
}


=head2 check_claims

Get info on Claims Notice

For details see L<https://tools.ietf.org/html/draft-tan-epp-launchphase-12>

INPUT:

key of params:
C<dname> -- domain name

=cut

sub check_claims {
    my ( $self, $params ) = @_;

    $params->{domains} = [ $params->{dname} ];

    $params->{extension} =
'   <launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="claims">
    <launch:phase>claims</launch:phase>
   </launch:check>
';

    return $self->SUPER::check_domains( $params );
}


# Compile trade, premium  and tlds extension

sub _keysys_domain_ext {
    my ( $params ) = @_;

    foreach my $f ( keys %$params ) {
        if ( $f =~ /^x-/ ) {
            $params->{ uc($f) } = delete $params->{$f};
        }
    }

    unless ( $params->{tld} ) {
        ( $params->{tld} ) = $params->{dname} =~ /\.([0-9A-Za-z\-]+)$/;
    }

    my $tld = uc $params->{tld};

    my %ext;

    # for epp need lc
    foreach my $f ( keys %$params ) {
        if ( $f =~ /^X-$tld-$/  or  $f eq 'X-ACCEPT-PREMIUMPRICE'  or  $f eq 'X-ACCEPT-TRADE' ) {
            $ext{ lc($f) } = delete $params->{$f};
        }
    }

    my $extension = '';
    # the extension fields must be arranged in alphabetical order
    foreach my $f ( sort keys %ext ) {
        my $f1 = $f;
        $f1 =~ s/^x-//;
        $extension .= "     <keysys:$f1>$ext{$f}</keysys:$f1>\n";
    }

    return $extension;
}

=head2 create_domain

additional keys of params:

C<is_premium> -- register a premium domain without specifying the price, but it must be allowed in the panel;

C<premium_price>, C<fee-fee> -- price for premium domain;

C<premium_currency> -- currency for price for premium domain;

C<claims> -- subhash for claims parameters:
C<noticeID>, C<notAfter>, C<acceptedDate>.
For details see L<https://tools.ietf.org/html/draft-tan-epp-launchphase-12>;

The other parameters are zone-specific and are set as specified in The RRPProxy documentation: C<X-TLD-PARAMETER>.

=cut

sub create_domain {
    my ( $self, $params ) = @_;

    $params->{authinfo} = ''; # need empty

    # Set as RRPProxy documentation, but not epp extension documentation
    $params->{'X-ACCEPT-PREMIUMPRICE'} = 1 if delete $params->{is_premium}; # https://wiki.rrpproxy.net/domains/premium-domains
    $params->{'X-FEE-AMOUNT'}   = delete $params->{premium_price}    if defined $params->{premium_price}; # zero is correct price
    $params->{'X-FEE-AMOUNT'}   = delete $params->{'fee-fee'}        if defined $params->{'fee-fee'};
    $params->{'X-FEE-CURRENCY'} = delete $params->{premium_currency} if $params->{premium_currency};

    my $extension = _keysys_domain_ext( $params );

    # closing special domain extensions
    if ( $extension ) {
        $extension =
qq|   <keysys:create $ks_ext>
    <keysys:domain>$extension
    </keysys:domain>
   </keysys:create>
|;
    }


    if ( defined $params->{'X-FEE-AMOUNT'} ) { # https://wiki.rrpproxy.net/domains/premium-domains/x-fee-parameters
        # price can be zero
        $extension .= qq|   <fee:create xmlns:fee="urn:ietf:params:xml:ns:fee-0.7">\n|;

        if ( $params->{'X-FEE-CURRENCY'} ) {
            $extension .= '    <fee:currency>' . $params->{'X-FEE-CURRENCY'} . "</fee:currency>\n";
        }

        $extension .= '    <fee:fee>' . $params->{'X-FEE-AMOUNT'} . "</fee:fee>\n   </fee:create>\n";
    }


    if ( $params->{claims} ) {
        $extension .=
'   <launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0">
    <launch:phase>claims</launch:phase>
    <launch:notice>
     <launch:noticeID>'.    $params->{claims}{noticeID}    .'</launch:noticeID>
     <launch:notAfter>'.    $params->{claims}{notAfter}    .'</launch:notAfter>
     <launch:acceptedDate>'.$params->{claims}{acceptedDate}.'</launch:acceptedDate>
    </launch:notice>
   </launch:create>
';
    }

    $params->{extension} = $extension if $extension;

    return $self->SUPER::create_domain( $params );
}


=head2 transfer

INPUT

For premium domains, you need to pass a special parameter is_premium

You can also specify contact id for some tlds: C<reg_id>, C<admin_id>, C<tech_id>, C<billing_id>

All other parameters such as L<IO::EPP::Base/transfer>.

=cut

sub transfer {
    my ( $self, $params ) = @_;

    if ( defined $params->{authinfo} ) {
        $params->{authinfo} =~ s/&/&amp;/g;
        $params->{authinfo} =~ s/</&lt;/g;
        $params->{authinfo} =~ s/>/&gt;/g;
    }

    my $extension = '';

    if ( $params->{is_premium}  ||  $params->{'X-ACCEPT-PREMIUMPRICE'}  ||  $params->{'x-accept-premiumprice'} ) {
        $extension .= "     <keysys:accept-premiumprice>1</keysys:accept-premiumprice>\n";
    }

    if ( $params->{reg_id} ||  $params->{admin_id} ) {
        $extension .= "     <keysys:ownercontact0>$$params{reg_id}</keysys:ownercontact0>\n"         if $params->{reg_id};
        $extension .= "     <keysys:admincontact0>$$params{admin_id}</keysys:admincontact0>\n"       if $params->{admin_id};
        $extension .= "     <keysys:techcontact0>$$params{tech_id}</keysys:techcontact0>\n"          if $params->{tech_id};
        $extension .= "     <keysys:billingcontact0>$$params{billing_id}</keysys:billingcontact0>\n" if $params->{billing_id};
    }

    if ( $extension ) {
        $params->{extension} =
qq|   <keysys:transfer $ks_ext>
    <keysys:domain>
$extension    </keysys:domain>
   </keysys:transfer>
|;
    }

    return $self->SUPER::transfer( $params );
}

=head2 renew_domain

For renewal of the premium domain name, you need to pass a parameter C<is_premium> or C<X-ACCEPT-PREMIUMPRICE>

=cut

sub renew_domain {
    my ( $self, $params ) = @_;

    if ( $params->{is_premium}  ||  $params->{'X-ACCEPT-PREMIUMPRICE'}  ||  $params->{'x-accept-premiumprice'} ) {
        # https://wiki.rrpproxy.net/domains/premium-domains
        $params->{extension} =
qq|   <keysys:renew $ks_ext>
    <keysys:domain>
     <keysys:accept-premiumprice>1</keysys:accept-premiumprice>
    </keysys:domain>
   </keysys:renew>
|;
    }

    return $self->SUPER::renew_domain( $params );
}


=head2 update_domain

C<trade> – option for special change of domain owner – paid or requires confirmation;

=cut

sub update_domain {
    my ( $self, $params ) = @_;

    $params->{'X-ACCEPT-TRADE'} = 1 if delete $params->{trade};

    my $extension = _keysys_domain_ext( $params );

    if ( $extension ) {
         $params->{extension} =
qq|   <keysys:update $ks_ext>
    <keysys:domain>$extension
    </keysys:domain>
   </keysys:update>
|;
    }

    return $self->SUPER::update_domain( $params );
}


=head2 set_domain_renewal_mode

Set renewal mode for domain.

INPUT:

params with key:

C<renewal_mode> – valid values: C<DEFAULT>, C<RENEWONCE>, C<AUTORENEW>, C<AUTOEXPIRE>, C<AUTODELETE>

For details see L<https://wiki.rrpproxy.net/domains/renewal-system>

OUTPUT:
see L<IO::EPP::Base/simple_request>

=cut

sub set_domain_renewal_mode {
    my ( $self, $params ) = @_;

    $params->{renewal_mode} = uc $params->{renewal_mode};

    $params->{extension} =
qq|   <keysys:update $ks_ext>
    <keysys:domain>
     <keysys:renewalmode>$$params{renewal_mode}</keysys:renewalmode>
    </keysys:domain>
   </keysys:update>
|;

    return $self->update_domain( $params );
}


=head2 req_poll_ext

keysys extension for the req poll

=cut

sub req_poll_ext {
    my ( undef, $ext ) = @_;

    my %info;

    if ( $ext =~ /<keysys:poll[^<>]+>(.+?)<\/keysys:poll>/s ) {
        my $key_ext = $1;

        foreach my $type ( 'data', 'info' ) {
            if ( $key_ext =~ /<keysys:$type>(.+?)<\/keysys:$type>/s ) {
                my $data = $1;

                my @data = $data =~ /<[^<>]+>[^<>]+<\/[^<>]+>/g;

                if ( scalar @data ) {
                    foreach my $row ( @data ) {
                        if ( $row =~ /<([^<>]+)>([^<>]+)<\/[^<>]+>/ ) {
                            $info{$1} = $2;
                        }
                    }
                }
                else {
                    $info{$type} = $data;
                }
            }
        }
    }

    return \%info;
}


1;

__END__

=pod

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>, claims functions are written by Andrey Voyshko

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
