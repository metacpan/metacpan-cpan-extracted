package IO::EPP::CNic;

=encoding utf8

=head1 NAME

IO::EPP::CNic

=head1 SYNOPSIS

    use IO::EPP::CNic;

    # Parameters for IO::Socket::SSL
    my %sock_params = (
        PeerHost        => 'epp.centralnic.com',
        PeerPort        => 700,
        SSL_key_file    => 'key_file.pem',
        SSL_cert_file   => 'cert_file.pem',
        Timeout         => 30,
    );

    # Create object, get greeting and call login()
    my $conn = IO::EPP::CNic->new( {
        user => 'H1234567',
        pass => 'XXXXXXXX',
        sock_params => \%sock_params,
        test_mode => 0, # real connect
    } );

    # Check domain
    my ( $answ, $code, $msg ) = $conn->check_domains( { domains => [ 'xyz.xyz' ] } );

    # Call logout() and destroy object
    undef $conn;

=head1 DESCRIPTION

Work with CentralNic APP API,
Overrides the IO::EPP::Base functions where the provider has supplemented the standard

The main documentation is in https://registrar-console.centralnic.com/doc/operations-manual-3.2.6.pdf
Other see on https://registrar-console.centralnic.com/support/documentation
(Authorization required)

=cut

use IO::EPP::Base;
use parent qw( IO::EPP::Base );

use strict;
use warnings;


sub make_request {
    my ( $action, $params ) = @_;

    my ( $self, $code, $msg, $answ );

    unless ( $params->{conn} ) {
        $params->{sock_params}{PeerHost} ||= 'epp.centralnic.com';
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

        goto END_MR;
    }

END_MR:

    $msg .= '; ' . $self->{critical_error} if $self->{critical_error};

    my $full_answ = "code: $code\nmsg: $msg";

    $answ = {} unless $answ && ref $answ;

    $answ->{code} = $code;
    $answ->{msg}  = $msg;

    return wantarray ? ( $answ, $full_answ, $self ) : $answ;
}


sub req_test {
    my ( $self, $out_data, $info ) = @_;

    require IO::EPP::Test::CNic;

    $self->epp_log( "$info request:\n$out_data" ) if $out_data;

    my $answ;
    eval{
        $answ = IO::EPP::Test::CNic::req( @_ );
        1;
    }
    or do {
        $self->{critical_error} = "$info req error: $@";
        return;
    };

    $self->epp_log( "$info answer:\n$answ" );

    return $answ;
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
     <extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>
     <extURI>urn:ietf:params:xml:ns:idn-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:fee-0.5</extURI>
     <extURI>urn:ietf:params:xml:ns:launch-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:regtype-0.1</extURI>
     <extURI>urn:ietf:params:xml:ns:auxcontact-0.1</extURI>';

    return $self->SUPER::login( $pw, $svcs, $extension );
}

sub create_contact {
    my ( $self, $params ) = @_;

    $params->{company} =~ s/&/&amp;/g;

    $params->{addr} = [ $params->{addr} ] unless ref $params->{addr};
    s/&/&amp;/g for @{$params->{addr}};

    $params->{cont_id} = IO::EPP::Base::gen_id( 16 );

    my $visible = $$params{pp_flag} ? 0 : 1;

    $params->{authinfo} ||= IO::EPP::Base::gen_pw( 16 );

    $params->{pp_ext} = '
    <contact:disclose flag="'.$visible.'">
     <contact:voice/>
     <contact:email/>
    </contact:disclose>';

    return $self->SUPER::create_contact( $params );
}


sub update_contact {
    my ( $self, $params ) = @_;

    if ( ref $params->{chg} ) {
        $params->{chg}{company} =~ s/&/&amp;/g if $params->{chg}{company};

        $params->{chg}{addr} = [ $params->{chg}{addr} ] unless ref $params->{chg}{addr};
        s/&/&amp;/g for @{$params->{chg}{addr}};

        $params->{chg}{authinfo} ||= IO::EPP::Base::gen_pw( 16 );
    }

    my $visible = $$params{pp_flag} ? 0 : 1;

    $params->{pp_ext} = '
    <contact:disclose flag="'.$visible.'">
     <contact:voice/>
     <contact:email/>
    </contact:disclose>';

    return $self->SUPER::update_contact( $params );
}


sub update_ns {
    my ( $self, $params ) = @_;

    $params->{no_empty_chg} = 1;

    return $self->SUPER::update_ns( $params );
}

=head2 check_premium

Get prices for premium domains

=cut

sub check_premium {
    my ( $self, $params ) = @_;

    $params->{domains} = [ delete $params->{dname} ] if $params->{dname};

    return ( 0, 0, 'no domains' ) unless $params->{domains} && scalar( @{$params->{domains}} );

    my $dms = '';
    foreach my $dm ( @{$params->{domains}} ) {
        $dms .= qq|    <fee:domain>
     <fee:name>$dm</fee:name>
     <fee:currency>USD</fee:currency>
     <fee:command>create</fee:command>
     <fee:period unit="y">1</fee:period>
    </fee:domain>\n|;
    }

    $params->{extension} = qq|   <fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.5">\n$dms   </fee:check>\n|;

    return $self->SUPER::check_domains( $params );
}


# Get info on Claims Notice
sub check_claims {
    my ( $self, $params ) = @_;

    $params->{domains} = [ delete $params->{dname} ] if $params->{dname};

    $params->{extension} =
'   <launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" type="claims">
    <launch:phase>claims</launch:phase>
   </launch:check>
';

    return $self->SUPER::check_domains( $params );
}

=head1 create_domain

CentralNic requires a domain price for each registration, need keys:
C<cost> -- the price of a domain, if the domain is registered for several years, the first year is the price of registration, and the remaining year is the price of renewal;
C<currency> -- price currency.

For IDN domains you need to specify C<idn_lang> -- the code page of the name and C<uname> -- the name itself in utf8

=cut

sub create_domain {
    my ( $self, $params ) = @_;

    $params->{authinfo} ||= IO::EPP::Base::gen_pw( 16 );

    my $extension = '';

    if ( $params->{dname} =~ /\bfeedback$/ ) {
        $extension = '
    <regType:create xmlns:regType="urn:ietf:params:xml:ns:regtype-0.1">
     <regType:type>hosted</regType:type>
    </regType:create>';
    }

    if ( $params->{idn_lang} ) {
        # 100% remove utf8 flag
        utf8::decode( $params->{uname} );
        utf8::encode( $params->{uname} );

        $extension .=
'   <idn:data xmlns:idn="urn:ietf:params:xml:ns:idn-1.0">
    <idn:table>' . $params->{idn_lang} . '</idn:table>
    <idn:uname>' . $params->{uname}  . '</idn:uname>
   </idn:data>
';
    }

    $extension .=
'   <fee:create xmlns:fee="urn:ietf:params:xml:ns:fee-0.5">
    <fee:currency>'.$params->{currency}.'</fee:currency>
    <fee:fee>'.     $params->{cost}    .'</fee:fee>
   </fee:create>
';

    if ( $params->{claims} ) {
        $extension .=
'   <launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0">
    <launch:phase>claims</launch:phase>
    <launch:notice>
     <launch:noticeID>'.    $params->{claims}->{noticeID}    .'</launch:noticeID>
     <launch:notAfter>'.    $params->{claims}->{notAfter}    .'</launch:notAfter>
     <launch:acceptedDate>'.$params->{claims}->{acceptedDate}.'</launch:acceptedDate>
    </launch:notice>
   </launch:create>
';
    }

    $params->{extension} = $extension if $extension;

    return $self->SUPER::create_domain( $params );
}


=head1 transfer

CentralNic requires a domain price for each transfer, need keys:
C<price> -- domain renewal and transfer price;
C<currency> -- price currency.

=cut


sub transfer {
    my ( $self, $params ) = @_;

    if ( defined $params->{authinfo} ) {
        $params->{authinfo} =~ s/&/&amp;/g;
        $params->{authinfo} =~ s/</&lt;/g;
        $params->{authinfo} =~ s/>/&gt;/g;
    }

    if ( $params->{price} ) {
        $params->{extension} =
'   <fee:transfer xmlns:fee="urn:ietf:params:xml:ns:fee-0.5">
    <fee:currency>'.$params->{currency}.'</fee:currency>
    <fee:fee>'.$params->{price}.'</fee:fee>
   </fee:transfer>
';
    }

    return $self->SUPER::transfer( $params );
}


=head1 renew_domain

CentralNic requires a domain price for each renew, need keys:
C<cost> -- domain renewal and transfer price;
C<currency> -- price currency.

=cut

sub renew_domain {
    my ( $self, $params ) = @_;

    if ( $params->{price} ) {
        $params->{extension} =
'   <fee:renew xmlns:fee="urn:ietf:params:xml:ns:fee-0.5">
    <fee:currency>'.$params->{currency}.'</fee:currency>
    <fee:fee>'.$params->{price}.'</fee:fee>
   </fee:renew>
';
    }

    return $self->SUPER::renew_domain( $params );
}


=head2 restore_domain

Domain redemption after deletion

=cut

sub restore_domain {
    my ( $self, $params ) = @_;

    $params->{extension} =
'   <rgp:update xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0">
    <rgp:restore op="request"/>
   </rgp:update>
';

    return $self->SUPER::update_domain( $params );
}


1;

__END__

=pod

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>, claims functions are written by Andrey Voyshko

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
