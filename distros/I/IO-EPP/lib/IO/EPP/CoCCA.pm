package IO::EPP::CoCCA;

=encoding utf8

=head1 NAME

IO::EPP::CoCCA

=head1 SYNOPSIS

    use IO::EPP::CoCCA;

    # Parameters for IO::Socket::SSL
    my %sock_params = (
        PeerHost        => 'registry.rusnames.net',
        PeerPort        => 700,
        # without certificate
        Timeout         => 30,
    );

    # Create object, get greeting and call login()
    my $conn = IO::EPP::CoCCA->new( {
        user => 'login',
        pass => 'xxxx',
        sock_params => \%sock_params,
        test_mode => 0, # real connect
    } );

    # Check domain
    my ( $answ, $code, $msg ) = $conn->check_domains( { domains => [ 'xn--d1acufc.xn--p1acf' ] } );

    # Call logout() and destroy object
    undef $conn;

=head1 DESCRIPTION

Module for work with  .РУС/.xn--p1acf, .CX, ... tlds. All list see on https://cocca.org.nz/#five

Frontends:
https://rusnames.com/
https://cocca.org.nz/

Backend:
https://secure.coccaregistry.net/

CoCCA features:

- not show authinfo in domain:info

=cut

use IO::EPP::Base;
use parent qw( IO::EPP::Base );

use strict;
use warnings;


my $rgp_ext = 'xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd"';


sub make_request {
    my ( $action, $params ) = @_;

    my ( $self, $code, $msg, $answ );

    unless ( $params->{conn} ) {
        $params->{sock_params}{PeerHost} ||= 'registry.rusnames.net'; # .РУС / .xn--p1acf
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

    my $svcs = '
    <objURI>urn:ietf:params:xml:ns:contact-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:domain-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>';
    my $extension = '
     <extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI>
     <extURI>https://production.coccaregistry.net/cocca-ip-verification-1.1</extURI>
     <extURI>https://production.coccaregistry.net/cocca-contact-proxy-1.0</extURI>
     <extURI>https://production.coccaregistry.net/cocca-contact-proxy-create-update-1.0</extURI>
     <extURI>https://production.coccaregistry.net/cocca-reseller-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>
     <extURI>urn:ietf:params:xml:ns:fee-0.8</extURI>';

    return $self->SUPER::login( $pw, $svcs, $extension );
}



sub create_domain {
    my ( $self, $params ) = @_;

    $params->{authinfo} ||= IO::EPP::Base::gen_pw();

    $params->{extension} =
'   <fee:create xmlns:fee="urn:ietf:params:xml:ns:fee-0.8" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <fee:currency>RUB</fee:currency>
    <fee:fee>'.$params->{price}.'</fee:fee>
   </fee:create>';

    return $self->SUPER::create_domain( $params );
}

=head2 restore_domain

Domain redemption

INPUT:
params key C<dname> -- name of the domain to be redeemed

OUTPUT:
see L</simple_request>.

=cut

sub restore_domain {
    my ( $self, $params ) = @_;

    $params->{extension} =
"   <rgp:update $rgp_ext>
    <rgp:restore op=\"request\"/>
   </rgp:update>";

    return $self->SUPER::update_domain( $params );
}


=head2 confirmations_restore_domain

Confirmation of domain redemption

INPUT:
C<pre_data>   -- whois before delete, can set 'none';
C<post_data>  -- whois on now, can set 'none';
C<del_time>   -- date-time of domain deletion in UTC;
C<rest_time>  -- date-time of sending the redemption request in UTC.

Fields already filled in:
C<resReason> -- the reason for the redemption;
C<statement> -- write that this is all for the client, not for us;
C<other>     -- can be without additions.

=cut

sub confirmations_restore_domain {
    my ( $self, $params ) = @_;

    $params->{pre_data} ||= 'none';
    $params->{post_data} ||= 'none';

    $params->{extension} = <<RGPEXT;
    <rgp:update xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd">
      <rgp:restore op="report">
        <rgp:report>
          <rgp:preData>$$params{pre_data}</rgp:preData>
          <rgp:postData>$$params{post_data}</rgp:postData>
          <rgp:delTime>$$params{del_time}</rgp:delTime>
          <rgp:resTime>$$params{rest_time}</rgp:resTime>
          <rgp:resReason>Customer forgot to renew.</rgp:resReason>
          <rgp:statement>I agree that the Domain Name has not been restored in order to assume the rights to use or sell the name to myself or for any third party.</rgp:statement>
          <rgp:statement>I agree that the information provided in this Restore Report is true to the best of my knowledge, and acknowledge that intentionally supplying false information in the Restore Report shall constitute an incurable material breach of the Registry-Registrar Agreement.</rgp:statement>
          <rgp:other/>
        </rgp:report>
      </rgp:restore>
    </rgp:update>
RGPEXT

    return $self->SUPER::update_domain( $params );
}


1;

__END__

=pod

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

