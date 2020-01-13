package IO::EPP::Afilias;

=encoding utf8

=head1 NAME

IO::EPP::Afilias

=head1 SYNOPSIS

    use IO::EPP::Afilias;

    # Parameters for IO::Socket::SSL
    my %sock_params = (
        PeerHost        => 'epp.afilias.net',
        PeerPort        => 700,
        SSL_key_file    => 'key_file.pem',
        SSL_cert_file   => 'cert_file.pem',
        Timeout         => 30,
    );

    # Create object, get greeting and call login()
    my $conn = IO::EPP::Afilias->new( {
        user => '12345-XX',
        pass => 'XXXXXXXX',
        sock_params => \%sock_params,
        server => 'afilias', # or 'pir', ...
        test_mode => 0, # real connect
    } );

    # Check domain
    my ( $answ, $code, $msg ) = $conn->check_domains( { domains => [ 'org.info' ] } );

    # Call logout() and destroy object
    undef $conn;

=head1 DESCRIPTION

working with registries that have Afilias backend.

Frontends: Afilias, PIR, DotAsia, ...

Feature: at the initial request, you must specify the server parameter for activation the necessary extensions.

Now it is C<afilias> or C<pir>.

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

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
        $params->{sock_params}{PeerHost} ||= 'epp.afilias.net';
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

    $code //= '';

    my $full_answ = "code: $code\nmsg: $msg";

    $answ = {} unless $answ && ref $answ;

    $answ->{code} = $code;
    $answ->{msg}  = $msg;

    return wantarray ? ( $answ, $full_answ, $self ) : $answ;
}

=head1 METHODS

=head2 new

See description in L<IO::EPP::Base/new>

Requires the C<server> field to be specified, which can have values: C<pir> for .org/.ngo/.ong/.орг/.संगठन/.机构, C<afilias> for other tlds.

=cut

sub new {
    my ( $package, $params ) = @_;

    unless ( $params->{server} ) {
        if ( $params->{sock_params}{PeerHost} =~ /\.afilias.net$/ ) {
            $params->{server} = 'afilias';
        }
        elsif ( $params->{sock_params}{PeerHost} =~ /\.publicinterestregistry.net$/ ) {
            $params->{server} = 'pir';
        }
    }

    return $package->SUPER::new( $params );
}

=head2 login

Ext params for login,

INPUT: new password for change

=cut

sub login {
    my ( $self, $pw ) = @_;

    my $svcs = '
    <objURI>urn:ietf:params:xml:ns:domain-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:contact-1.0</objURI>';

    my $extension = '
     <extURI>urn:afilias:params:xml:ns:oxrs-1.1</extURI>
     <extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>
     <extURI>urn:ietf:params:xml:ns:launch-1.0</extURI>';


    if ( $self->{server}  and  $self->{server} eq 'afilias' ) {
        $extension .= '
     <extURI>urn:afilias:params:xml:ns:idn-1.0</extURI>
     <extURI>urn:afilias:params:xml:ns:ipr-1.1</extURI>
     <extURI>urn:ietf:params:xml:ns:fee-0.8</extURI>';
    }
    elsif ( $self->{server}  and  $self->{server} eq 'pir' ) {
        $extension .= '
     <extURI>urn:afilias:params:xml:ns:idn-1.0</extURI>
     <extURI>urn:afilias:params:xml:ns:trademark-1.0</extURI>';
    }

    return $self->SUPER::login( $pw, $svcs, $extension );
}


sub create_contact {
    my ( $self, $params ) = @_;

    $params->{authinfo} = IO::EPP::Base::gen_pw( 16 );

    # contact:disclose flag not supported, need to use personal service of hiding of contacts

    # $params->{pp_ext} = '
    # <contact:disclose flag="'.$visible.'">
    #  <contact:voice/>
    #  <contact:email/>
    # </contact:disclose>';

    return $self->SUPER::create_contact( $params );
}

=head2 check_domains, create_domain

For IDN domains you need to specify the language code in the C<idn_lang> field

List of IDN characters for all zones see in L<https://www.iana.org/domains/idn-tables>

=cut

sub check_domains {
    my ( $self, $params ) = @_;

    if ( $params->{lang} ) {
        $params->{extension} = '
   <idn:check xmlns:idn="urn:iana:xml:ns:idn" xsi:schemaLocation="urn:iana:xml:ns:idn idn.xsd">
    <idn:script>' . $params->{idn_lang} . '</idn:script>
   </idn:check>'
    }

    return $self->SUPER::check_domains( $params );
}


sub create_domain {
    my ( $self, $params ) = @_;

    $params->{authinfo} ||= IO::EPP::Base::gen_pw( 16 );

    my $extension = '';

    if ( $params->{lang} ) {
        $extension = '
   <idn:create xmlns:idn="urn:iana:xml:ns:idn" xsi:schemaLocation="urn:iana:xml:ns:idn idn.xsd">
    <idn:script>' . $params->{idn_lang} . '</idn:script>
   </idn:create>'
    }

    return $self->SUPER::create_domain( $params );
}


sub transfer {
    my ( $self, $params ) = @_;

    if ( $params->{authinfo} ) {
        $params->{authinfo} =~ s/&/&amp;/g;
        $params->{authinfo} =~ s/</&lt;/g;
        $params->{authinfo} =~ s/>/&gt;/g;
    }

    return $self->SUPER::transfer( $params );
}


=head2 restore_domain

first call for restore_domain

=cut

sub restore_domain {
    my ( $self, $params ) = @_;

    $params->{extension} = "
   <rgp:update $rgp_ext>
    <rgp:restore op=\"request\"/>
   </rgp:update>";

    return $self->SUPER::update_domain( $params );
}

=head2 confirmations_restore_domain

second call for restore_domain

C<pre_data>   -- whois before delete
C<post_data>  -- whois on now
C<del_time>   -- delete domain date-time, see. upd_date in domain:info before call restore_domain
C<rest_time>  -- date-time of sending the redemption request in UTC.
C<reason>     -- restore reason, variants:
C<Registrant Error>, C<Registrar Error>, C<Judicial / Arbitral / Administrative / UDRP Order>.

The following parameters have already been defined:

C<statement>     -- write that this is all for the client, not for us,
since the phrase is standard, you only need to substitute the company and the position of the one who buys the domain: C<company>, C<position>
C<other>         -- can and without other.

Instead, you need to pass:

C<company> -- name of your organization and its ID in the registry;
C<position> -- name, surname and position of the employee who is responsible for the purchase of remote domains.

=cut

sub confirmations_restore_domain {
    my ( $self, $params ) = @_;

    $params->{extension} = <<RGPEXT;
    <rgp:update xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd">
      <rgp:restore op="report">
        <rgp:report>
          <rgp:preData>$$params{pre_data}</rgp:preData>
          <rgp:postData>$$params{post_data}</rgp:postData>
          <rgp:delTime>$$params{del_time}</rgp:delTime>
          <rgp:resTime>$$params{rest_time}</rgp:resTime>
          <rgp:resReason>$$params{reason}</rgp:resReason>
          <rgp:statement>$$params{company}, attests that we have not restored the name above in order to assume the rights to use or sell the Registered Name ourselves or for any third party
          $$params{company}, attests that the information in this report is true to the best of our knowledge,
          and we acknowledge that intentionally suplying false informationin the Restore Report shall constitute an incurable material breach of the Registry-Registrar Agreement</rgp:statement>
          <rgp:statement>I, $$params{position}, attest that I am duly authorized to submit Restore Reports on behalf of $$params{company}</rgp:statement>
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

