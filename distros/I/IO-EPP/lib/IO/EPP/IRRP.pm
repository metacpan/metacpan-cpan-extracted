package IO::EPP::IRRP;

=encoding utf8

=head1 NAME

IO::EPP::IRRP

=head1 SYNOPSIS

    use IO::EPP::IRRP;

    # Parameters for IO::Socket::SSL
    my %sock_params = (
        PeerHost        => 'epp.ispapi.net',
        PeerPort        => 700,
        Timeout         => 30,
    );

    # Create object, get greeting and call login()
    my $conn = IO::EPP::IRRP->new( {
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

Work with iRRP/iDotz/Hexonet epp api:

A large number of add-ons, but all special data is passed through the key-value extension

Some of the transfer Functions have been replaced with the key-value extension

To change the contacts of many zones you need to use trade

Description of EPP from iRRP/Hexonet:
L<https://wiki.hexonet.net/wiki/EPP_examples>

Special EPP functions, as Query*List:
L<http://www.irrp.net/document.pdf>
(domain, contact, transfer, zone, event, nameserver, accounting)

TLD lists: L<https://wiki.hexonet.net/wiki/Main_Page>  and New GTLD  L<https://wiki.hexonet.net/wiki/NewTLD_Main_Page>

=cut

use IO::EPP::Base;
use parent qw( IO::EPP::Base );

use strict;
use warnings;

my $kv_ext = 'xmlns:keyvalue="http://schema.ispapi.net/epp/xml/keyvalue-1.0" xsi:schemaLocation="http://schema.ispapi.net/epp/xml/keyvalue-1.0 keyvalue-1.0.xsd"';

sub make_request {
    my ( $action, $params ) = @_;

    my ( $self, $code, $msg, $answ );

    unless ( $params->{conn} ) {
        $params->{sock_params}{PeerHost} ||= 'epp.ispapi.net';
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
    <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:domain-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:contact-1.0</objURI>
    <objURI>http://schema.ispapi.net/epp/xml/keyvalue-1.0</objURI>';

    my $extension = '
     <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>
     <extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:fee-0.7</extURI>
     <extURI>http://schema.ispapi.net/epp/xml/keyvalue-1.0</extURI>';

    return $self->SUPER::login( $pw, $svcs, $extension );
}


sub create_contact {
    my ( $self, $params ) = @_;

    $params->{id} ||= IO::EPP::Base::gen_id( 16 );

    $params->{authinfo} = SRS::Comm::Provider::EPP::Base::gen_pw( 16 );

    return $self->SUPER::create_contact( $params );
}


=head2 create_domain

Additional tld parameters must be specified as described in the tld documentation

=cut

sub create_domain {
    my ( $self, $params ) = @_;

    $params->{authinfo} ||= SRS::Comm::Provider::EPP::Base::gen_pw( 16 );

    my $extension = '';

    # Up keys for key-value extension
    foreach my $k ( keys %$params ) {
        if ( $k =~ /^x-/ ) {
            $params->{ uc($k) } = delete $params->{$k}
        }
    }

    foreach my $k ( keys %$params ) {
        if ( $k =~ /^X-/ ) {
            $extension .= "    <keyvalue:kv key='$k' value='$$params{$k}' />\n"
        }
    }

    if ( $extension ) {
        $params->{extension} = "   <keyvalue:extension $kv_ext>\n$extension   </keyvalue:extension>\n";
    }

    return $self->SUPER::create_domain( $params );
}


=head2 check_transfer

Check the availability of domain transfer, the specific function

INPUT:

key of params:
C<dname> -- domain name

An Example, request:

    my ( $answ, $msg ) = make_request( 'check_transfer', { dname => 'irrp.xyz', %conn_params } );

Answer:

    {
        'msg' => 'Object exists; 540 Attribute value is not unique; DOMAIN DOES NOT EXIST [irrp.xyz]',
        'code' => 2302
    };

=cut

sub check_transfer {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no dname' ) unless $params->{dname};

my $body = <<CHTR;
$$self{urn}{head}
 <extension>
  <keyvalue:extension $kv_ext>
   <keyvalue:kv key='COMMAND' value='CheckDomainTransfer' />
   <keyvalue:kv key='DOMAIN' value='$$params{dname}' />
  </keyvalue:extension>
 </extension>
</epp>
CHTR

    my $content = $self->req( $body, 'check_transfer' );

    if ( $content  &&  $content =~ /<result code=['"](\d+)['"]>/ ) {
        my $code = $1 + 0;

        my $msg = '';
        if ( $content =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        if ( $code != 1000 ) {
            my $reason = join( ';', $content =~ /<reason[^<>]*>([^<>]+)<\/reason>/g );

            $msg .= "; " . $reason if $reason;
        }

        my %info;

        my @list = $content =~ m|(<keyvalue:kv key="[^"]+" value="[^"]+"/>)|gs;

        foreach my $row ( @list ) {
            if ( $row =~ /key="([^"]+)" value="([^"]+)"/ ) {
                $info{ lc $1 } = $2;
            }
        }

        return wantarray ? ( \%info, $code, $msg ) : \%info;
    }

    return wantarray ? ( 0, 0, 'empty answer' ) : 0 ;
}


sub transfer {
    my ( $self, $params ) = @_;

    if ( defined $params->{authinfo} ) {
        $params->{authinfo} =~ s/&/&amp;/g;
        $params->{authinfo} =~ s/</&lt;/g;
        $params->{authinfo} =~ s/>/&gt;/g;
    }

    if ( 0  &&  $params->{op} eq 'query' ) {
        #There are two options: its own feature and standard
        my $body = <<INTTR;
$$self{urn}{head}
 <extension>
   <keyvalue:extension $kv_ext>
    <keyvalue:kv key='COMMAND' value='StatusDomainTransfer' />
    <keyvalue:kv key='DOMAIN' value='$$params{dname}' />
   </keyvalue:extension>
 </extension>
</epp>
INTTR

        my $answ = $self->req( $body, 'query_transfer' );

#         if ( ref $res && $res->{code} == 1000 ) {
#             $res->{trstatus} = 'pending';
#         }
#
        return $answ;
    }

    return $self->SUPER::transfer( $params );
}

=head2 get_transfer_list

Get a list of all domains that are currently in the transfer state

No input params

An Example, request:

    my ( $answ, $msg, $conn ) = make_request( 'get_transfer_list', \%conn_params );

    # Answer:

    {
        'user1' => 'login',
        'parentuser2' => 'brsmedia.net',
        'user' => 'login',
        'domainumlaut1' => 'mmmm.travel',
        'code' => '1000',
        'count' => '3',
        'total' => '3',
        'parentuser' => 'brsmedia.net',
        'domain1' => 'mmmm.travel',
        'domainumlaut2' => 'pppp.travel',
        'createddate' => '2019-02-07 08:56:06',
        'domain2' => 'pppp.travel',
        'domain' => 'eeee.travel',
        'limit' => '10000',
        'msg' => 'Command completed successfully',
        'first' => '0',
        'createddate2' => '2018-03-06 10:26:57',
        'last' => '2',
        'parentuser1' => 'brsmedia.net',
        'domainumlaut' => 'eeee.travel',
        'createddate1' => '2018-03-27 05:03:40',
        'user2' => 'login'
    };

=cut

sub get_transfer_list {
    my ( $self, $params ) = @_;

my $body = <<QTL;
$$self{urn}{head}
 <extension>
  <keyvalue:extension $kv_ext>
   <keyvalue:kv key='COMMAND' value='QueryTransferList' />
  </keyvalue:extension>
 </extension>
</epp>
QTL

    my $content = $self->req( $body, 'get_transfer_list' );

    if ( $content  &&  $content =~ /<result code=['"](\d+)['"]>/ ) {
        my $code = $1 + 0;

        my $msg = '';
        if ( $content =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        my %info;

        my @list = $content =~ m|(<keyvalue:kv key="[^"]+" value="[^"]+"/>)|gs;

        foreach my $row ( @list ) {
            if ( $row =~ /key="([^"]+)" value="([^"]+)"/ ) {
                $info{ lc $1 } = $2;
            }
        }

        return wantarray ? ( \%info, $code, $msg ) : \%info;
    }

    return wantarray ? ( 0, 0, 'empty answer' ) : 0 ;
}


=head2 get_status_domain

Function for getting additional domain data

INPUT:

key of params:
C<dname> -- domain name

An Example, request:

    my ( $answ, $msg, $conn ) = make_request( 'get_status_domain', { dname => '777.mx', %conn_params } );

    # Answer:

    {
        'REGISTRATIONGRACEPERIOD' => '0',
        'NEXTACTION' => 'expire',
        'FINALIZATIONDATE' => '2021-02-02 15:07:40',
        'CREATEDDATE' => '2017-12-20 15:07:40',
        'TRANSFERDATE' => '0000-00-00 00:00:00',
        'STATUS1' => 'clientTransferProhibited',
        'TECHCONTACT' => '777esap4gmjnbv',
        'NAMESERVER' => 'ns1.777.com',
        'STATUS' => 'ACTIVE',
        'OWNERCONTACT' => '777vw7yurk2x2k',
        'FAILUREDATE' => '2021-02-02 15:07:40',
        'ACCOUNTINGPERIOD' => '0',
        'RENEWALMODE' => 'AUTOEXPIRE',
        'USER' => 'login',
        'code' => 1000,
        'X-WHOIS-RSP' => 'My Company',
        'NEXTACTIONDATE' => '2021-02-02 15:07:40',
        'DOMAINUMLAUT' => '777.mx',
        'FINALIZATIONPERIOD' => '44d',
        'NAMESERVER1' => 'ns2.777.com',
        'EXPIRATIONDATE' => '2020-12-20 15:07:40',
        'SUBCLASS' => 'MX',
        'REGISTRARUPDATEDDATE' => '2019-12-26 15:51:38',
        'PREPAIDPERIOD' => '0',
        'UPDATEDDATE' => '2019-12-26 15:51:38',
        'ROID' => 'DOMAIN_77700005500777-MX',
        'HOSTTYPE' => 'OBJECT',
        'UPDATEDBY' => 'SYSTEM',
        'CREATEDBY' => 'SYSTEM',
        'DESCRIPTION' => '777.mx',
        'AUTH' => '777rhE!r9q=#y',
        'ID' => '777.mx',
        'BILLINGCONTACT' => '777y2emz0ib63xj',
        'REGISTRAR' => 'SYSTEM',
        'DELETIONRESTORABLEPERIOD' => '30d',
        'REGISTRARTRANSFERDATE' => '0000-00-00 00:00:00',
        'REGISTRATIONEXPIRATIONDATE' => '2020-12-20 15:07:40',
        'PAIDUNTILDATE' => '2020-12-20 15:07:40',
        'msg' => 'Command completed successfully',
        'FAILUREPERIOD' => '44d',
        'ADMINCONTACT' => '777sagtqh10mvpo',
        'CLASS' => 'DOMAIN',
        'ACCOUNTINGDATE' => '2020-12-20 15:07:40',
        'REPOSITORY' => 'MX-LIVE-1API',
        'DELETIONHOLDPERIOD' => '0d',
        'TRANSFERLOCK' => '1',
        'X-WHOIS-URL' => 'http://www.777.com',
        'X-WHOIS-BANNER0' => 'Please register your domains at http://www.777.com'
    };

=cut

sub get_status_domain {
    my ( $self, $params ) = @_;

    my $body = qq|$$self{urn}{head}
 <extension>
   <keyvalue:extension $kv_ext>
    <keyvalue:kv key='COMMAND' value='StatusDomain' />
    <keyvalue:kv key='DOMAIN' value='$$params{dname}' />
   </keyvalue:extension>
 </extension>
</epp>|;

    my $answ = $self->req( $body, 'get_status_domain' );

    if ( $answ =~ /result code=['"](\d+)['"]/ ) {
        my $rcode = $1 + 0;

        my $msg = '';
        if ( $answ =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        my %info;

        if ( $rcode == 1000 ) {
            my @kv = $answ =~ /<keyvalue:kv\s+(key="[^"]+"\s+value="[^"]+")\/>/sg;

            foreach my $row ( @kv ) {
                if ( $row =~ /key="([^"]+)"\s+value="([^"]+)"/ ) {
                    $info{$1} = $2;
                }
            }
        }

        return wantarray ? ( \%info, $rcode, $msg ) : \%info;
    }

    return wantarray ? ( 0, 0, 'no answer' ) : 0;
}

=head2 renew_domain

Automatic adds an additional parameter for the .jp tld

=cut

sub renew_domain {
    my ( $self, $params ) = @_;

    if ( $params->{dname} =~ /\.jp$/ ) {
        $params->{extension} =
"   <keyvalue:extension $kv_ext>
    <keyvalue:kv key='COMMAND' value='PayDomainRenewal' />
   </keyvalue:extension>
";
    }

    return $self->SUPER::renew_domain( $params );
}


=head2 set_domain_renewal_mode

Update domain renewal mode

L<https://wiki.hexonet.net/wiki/API:SetDomainRenewalMode>

INPUT:

params with key:

C<renewal_mode> – valid values: C<AUTORENEW>, C<AUTODELETE>, C<AUTOEXPIRE>

OUTPUT:
see L<IO::EPP::Base/simple_request>

=cut

sub set_domain_renewal_mode {
    my ( $self, $params ) = @_;

    $params->{renewal_mode} = uc $params->{renewal_mode};

    $params->{extension} = qq|
  <extension>
   <keyvalue:extension  $kv_ext>
      <keyvalue:kv key='COMMAND' value='SetDomainRenewalMode' />
      <keyvalue:kv key='RENEWALMODE' value='$$params{renewal_mode}' />
  </extension>|;

    return $self->SUPER::update_domain( $params );
}


=head2 update_domain

Has additional parameters:

C<trade> – Changing domain contacts requires confirmation or a fee, depending on the tld;

C<confirm_old_registrant> – send confirmation of changing the owner's email address to the old address;

C<confirm_new_registrant>– send confirmation of changing the owner's email address to the new address;

Other additional parameters depend on the tld.

=cut

sub update_domain {
    my ( $self, $params ) = @_;

    my $extension = '';

    # Up keys for key-value extension
    foreach my $k ( keys %$params ) {
        if ( $k =~ /^x-/ ) {
            $params->{ uc($k) } = delete $params->{$k};
        }
    }

    if ( $params->{trade} ) {
        # a paid update or change the owner of the gtld
        $extension .= "    <keyvalue:kv key='COMMAND' value='TradeDomain' />\n";

        if ( $params->{dname} =~ /\.xxx$/ ) {
            $extension .= "    <keyvalue:kv key='X-REQUEST-OPT-OUT-TRANSFERLOCK' value='0' />\n";
        }
    }

    if ( defined $params->{'confirm_old_registrant'} ) {
        # confirm old email
        $extension .= "    <keyvalue:kv key='X-CONFIRM-DA-OLD-REGISTRANT' value='$params->{'confirm_old_registrant'}' />\n";
    }

    if ( defined $params->{'confirm_new_registrant'} ) {
        # confirm new email
        $extension .= "    <keyvalue:kv key='X-CONFIRM-DA-NEW-REGISTRANT' value='$params->{'confirm_new_registrant'}' />\n";
    }

    if ( $extension ) {
        $params->{extension} = "   <keyvalue:extension $kv_ext>\n$extension   </keyvalue:extension>\n";
    }

    return $self->SUPER::update_domain( $params );
}


=head2 restore_domain

Domain redemption after deletion

its own feature instead of rgp:restore

INPUT:

key of params:
C<dname> -- domain name

=cut

sub restore_domain {
    my ( $self, $params ) = @_;

    $params->{extension} =
"   <keyvalue:extension $kv_ext>
    <keyvalue:kv key='COMMAND' value='RestoreDomain' />
   </keyvalue:extension>
";

    return $self->SUPER::update_domain( $params );
}


=head2 get_domain_list

Get a list of all your domains

=cut

sub get_domain_list {
    my ( $self, $params ) = @_;

my $body = <<INTTR;
$$self{urn}{head}
 <extension>
  <keyvalue:extension $kv_ext>
   <keyvalue:kv key='COMMAND' value='QueryDomainList' />
  </keyvalue:extension>
 </extension>
</epp>
INTTR

    my $content = $self->req( $body, 'get_domain_list' );

    if ( $content  &&  $content =~ /<result code=['"](\d+)['"]>/ ) {
        my $code = $1 + 0;

        my $msg = '';
        if ( $content =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        my %info;

        my @list = $content =~ m|(<keyvalue:kv key="[^"]+" value="[^"]+"/>)|gs;

        foreach my $row ( @list ) {
            if ( $row =~ /key="([^"]+)" value="([^"]+)"/ ) {
                $info{ lc $1 } = $2;
            }
        }

        return wantarray ? ( \%info, $code, $msg ) : \%info;
    }

    return wantarray ? ( 0, 0, 'empty answer' ) : 0 ;
}


=head2 get_accounting_list

Get lists of accounts, it makes sense to watch only the first record

    my ( $answ, $msg, $conn ) = make_request( 'get_accounting_list', { limit => 1, %conn_params } );

You can use this request to check your account balance

=cut

sub get_accounting_list {
    my ( $self, $params ) = @_;

    my $add_values = '';
    foreach my $k ( keys %$params ) {
        $add_values .= "\n   <keyvalue:kv key='" . uc( $k ) . "' value='$$params{$k}' />";
    }

my $body = <<QAL;
$$self{urn}{head}
 <extension>
  <keyvalue:extension $kv_ext>
   <keyvalue:kv key='COMMAND' value='QueryAccountingList' />$add_values
  </keyvalue:extension>
 </extension>
</epp>
QAL

    my $content = $self->req( $body, 'get_accounting_list' );

    if ( $content  &&  $content =~ /<result code=['"](\d+)['"]>/ ) {
        my $code = $1 + 0;

        my $msg = '';
        if ( $content =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        my %info;

        my @list = $content =~ m|(<keyvalue:kv key="[^"]+" value="[^"]+"/>)|gs;

        foreach my $row ( @list ) {
            if ( $row =~ /key="([^"]+)" value="([^"]+)"/ ) {
                $info{ lc $1 } = $2;
            }
        }

        return wantarray ? ( \%info, $code, $msg ) : \%info;
    }

    return wantarray ? ( 0, 0, 'empty answer' ) : 0 ;
}


=head2 req_poll_ext

key-value extension for the req poll

=cut

sub req_poll_ext {
    my ( undef, $ext ) = @_;

    my %info;

    if ( $ext =~ /<keyvalue:extension[^<>]+>(.+)<\/keyvalue:extension>/s ) {
        my $kv = $1;
        my @kv = $kv =~ /<keyvalue:kv([^<>]+)\/>/g;

        foreach ( @kv ) {
            if ( /key="([^"]+)"\s+value="([^"]+)"/ ) {
                $info{$1} = $2;
            }
        }

        foreach my $k ( keys %info ) {
            if ( $info{$k} =~ /^[A-Z0-9._-]+$/ ) {
                # domain and other names
                $info{$k} = lc $info{$k};
            }

            if ( $info{$k} =~ /\%/ ) {
                # original irrp encode
                $info{$k} =~ tr/+/ /;
                $info{$k} =~ s/%25([0-9a-f]{2})/%$1/g;
                $info{$k} =~ s/%([0-9a-f]{2})/chr(hex($1))/eg; #//
            }
        }
    }

    return \%info;
}

1;

__END__

=pod

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>, renewal_mode function are written by Andrey Voyshko

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
