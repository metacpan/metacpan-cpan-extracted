package IO::EPP::Flexireg;

=encoding utf8

=head1 NAME

IO::EPP::Flexireg

=head1 SYNOPSIS

    use IO::EPP::Flexireg;

    # Parameters for IO::Socket::SSL
    my %sock_params = (
        PeerHost        => 'epp.flexireg.net',
        PeerPort        => 700,
        Timeout         => 30,
    );

    # Create object, get greeting and call login()
    my $conn = IO::EPP::Flexireg->new( {
        user => 'login-msk-fir',
        pass => 'xxxxxxxx',
        sock_params => \%sock_params,
        test_mode => 0, # real connect
    } );

    # Check domain
    my ( $answ, $code, $msg ) = $conn->check_domains( { domains => [ 'my.moscow', 'xn--l1ae5c.xn--80adxhks' ] } );

    # Call logout() and destroy object
    undef $conn;

=head1 DESCRIPTION

Module work with Flexireg tlds: .moscow, .москва, ru.net and 3lvl.ru/su

Frontend:
https://faitid.org/

Backend:
http://flexireg.net/


Documentaion:

moscow, москва
L<https://faitid.org/projects/moscow/documents>,
L<https://faitid.org/sites/default/files/policy/tech/Tu-flexireg-EPP_1.2_ru.pdf>,
L<https://faitid.org/sites/default/files/Tu-flexireg-Examples_1.3_ru.pdf>

ru.net+
L<https://faitid.org/projects/RU.NET/documents>,
L<https://faitid.org/sites/default/files/Tu-flexireg-EPP_ext.pdf>


=cut

use IO::EPP::Base;
use parent qw( IO::EPP::Base );

use strict;
use warnings;

my $cont_ext =
'xmlns:contact="http://www.tcinet.ru/epp/tci-contact-ext-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.tcinet.ru/epp/tci-contact-ext-1.0 tci-contact-ext-1.0.xsd"';
my $rgp_ext =
'xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd"';

sub make_request {
    my ( $action, $params ) = @_;

    my ( $self, $code, $msg, $answ );

    unless ( $params->{conn} ) {
        $params->{sock_params}{PeerHost} ||= 'epp.flexireg.net';
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
     <extURI>http://www.tcinet.ru/epp/tci-contact-ext-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:fee-0.11</extURI>
     <extURI>urn:ietf:params:xml:ns:idn-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:launch-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>';

    return $self->SUPER::login( $pw, $svcs, $extension );
}

sub contact_ext {
    my ( undef, $params ) = @_;

    my $ext = '';

    if ( $params->{birthday} ) {
        $ext .= "<contact:person>\n";

        foreach my $f ( 'birthday', 'passport', 'TIN' ) {
            $ext .= "    <contact:$f>$$params{$f}</contact:$f>\n" if $$params{$f};
        }

        $ext .= "   </contact:person>";
    }

    if ( $params->{legal} ) {
        $ext .= "   <contact:organization>\n";
        foreach my $type ( 'int', 'loc' ) {
            $ext .= qq|    <contact:legalAddr type="$type">\n|;

            $$params{legal}{$type}{addr} = [ $$params{legal}{$type}{addr} ] unless ref $$params{legal}{$type}{addr};

            foreach my $s ( @{$$params{legal}{$type}{addr}} ) {
                $ext .= "     <contact:street>$s</contact:street>\n";
            }

            $ext .= "     <contact:city>$$params{legal}{$type}{city}</contact:city>\n";
            $ext .= ( $$params{legal}{$type}{'state'} ? "     <contact:sp>$$params{legal}{$type}{state}</contact:sp>\n"  : "     <contact:sp/>\n" );
            $ext .= ( $$params{legal}{$type}{postcode} ? "     <contact:pc>$$params{legal}{$type}{postcode}</contact:pc>\n"  : "     <contact:pc/>\n" );
            $ext .= "     <contact:cc>$$params{legal}{$type}{country_code}</contact:cc>\n";

            $ext .= "    </contact:legalAddr>\n";
        }
        $ext .= "    <contact:TIN>$$params{TIN}</contact:TIN>\n";
        $ext .= "   </contact:organization>";
    }

    return $ext;
}


=head2 create_contact

For moscow/москва:

When registering a contact, you must specify both int type data and loc type data, and if the domain owner has passport data in Cyrillic,
then loc type data must be entered in Cyrillic.
This is mandatory for citizens and legal entities of Russia, Ukraine, Belarus and other countries that have the Cyrillic alphabet.

In addition, the owner must provide additional information.

For individuals:

C<birthday> -- date of birth;

C<passport> -- passport series and number, by whom and when it was issued;

C<TIN> -- TIN for individual entrepreneurs.

For legal entities:

hashref C<legal>, that contains the legal address, it also needs to specify two types: C<int> and C<loc>, consisting of the fields C<addr>, C<city>, C<state>, C<postcode>, C<country_code>.

You also need to specify the C<TIN> field.

An Example:

Individuals:

    my %cont = (
        int => {
            first_name => 'Igor',
            patronymic => 'Igorevich',
            last_name  => 'Igorev',
            org        => '',
            addr       => 'Igoreva str, 129',
            city       => 'Igorevsk',
            state      => 'Ogorevskaya obl.',
            postcode   => '699001',
            country_code => 'RU',
        },
        loc => {
            first_name => 'Игорь',
            patronymic => 'Игоревич',
            last_name  => 'Игорев',
            org        => '',
            addr       => 'ул. Игорева, 129',
            city       => 'Игоревск',
            state      => 'Игоревская обл.',
            postcode   => '699001',
            country_code => 'RU',
        },
        birthday => '1909-01-14',
        passport => '11.11.2011, выдан Отделом УФМС России по Игоревской области в г.Игоревске, 2211 446622',
        phone      => '+7.9012345678',
        fax        => '',
        email      => 'igor@i.ru',
        TIN        => '',
    };

    my ( $answ, $msg, $conn ) = make_request( 'create_contact',  \%cont );

Legal entities:

    my %cont = (
        int => {
            first_name => 'Igor',
            patronymic => 'Igorevich',
            last_name  => 'Igorev',
            org        => 'Igor and Co',
            addr       => 'Igoreva str, 129',
            city       => 'Igorevsk',
            state      => 'Igorevskaya obl.',
            postcode   => '699001',
            country_code => 'RU',
        },
        loc => {
            first_name => 'Игорь',
            patronymic => 'Игоревич',
            last_name  => 'Игорев',
            org        => 'Игорь и Ко',
            addr       => 'ул. Игорева, 129',
            city       => 'Игоревск',
            state      => 'Игоревская обл.',
            postcode   => '699001',
            country_code => 'RU',
        },
        legal => {
            int => {
                addr       => 'Company str, 1',
                city       => 'Igorevsk',
                state      => 'Igorevskaya obl.',
                postcode   => '699002',
                country_code => 'RU',
            },
            loc => {
                addr       => 'ул. Компаний, 1',
                city       => 'Игоревск',
                state      => 'Игоревская обл.',
                postcode   => '699002',
                country_code => 'RU',
            }
        }
    };

    my ( $answ, $code, $msg ) = $conn->create_contact( \%cont );

=cut

sub create_contact {
    my ( $self, $params ) = @_;

    $params->{cont_id} = IO::EPP::Base::gen_id( 16 );

    $params->{authinfo} = IO::EPP::Base::gen_pw( 16 );

    my $extension = $self->contact_ext( $params );

    if ( $extension ) {
        $params->{extension} = "   <contact:create $cont_ext>\n$extension   </contact:create>\n";
    }

    return $self->SUPER::create_contact( $params );
}


sub get_contact_ext {
    my ( undef, $ext ) = @_;

    my %cont;

    if ( $ext =~ m|<contact:infData[^<>]+tci-contact-ext-1[^<>]+>(.+?)</contact:infData>|s ) {
        my $data = $1;

        if ( $data =~ m|<contact:person>(.+)</contact:person>|s ) {
            my $person_data = $1;

            my @rows = $person_data =~ m|(<contact:[A-Za-z]+>[^<>]+)</contact:[A-Za-z]+>|gs;

            foreach my $row ( @rows ) {
                if ( $row =~ m|<contact:([A-Za-z]+)>([^<>]+)| ) {
                    $cont{$1} = $2;
                }
            }
        }

        if ( $data =~ m|<contact:organization>(.+)</contact:organization>|s ) {
            my $org_data = $1;

            ( $cont{TIN} ) = $org_data =~ /<contact:TIN>([^<>]+)<\/contact:TIN>/;

            my @atypes = ( 'int', 'loc' );
            foreach my $atype ( @atypes ) {
                my ( $postal ) = $org_data =~ m|<contact:legalAddr type="$atype">(.+?)</contact:legalAddr>|s;

                next unless $postal;

                $cont{legal}{$atype}{addr} = join(' ', $postal =~ /<contact:street>([^<>]*)<\/contact:street>/ );

                ( $cont{legal}{$atype}{city} ) = $postal =~ /<contact:city>([^<>]*)<\/contact:city>/;

                ( $cont{legal}{$atype}{'state'} ) = $postal =~ /<contact:sp>([^<>]*)<\/contact:sp>/;

                ( $cont{legal}{$atype}{postcode} ) = $postal =~ /<contact:pc>([^<>]*)<\/contact:pc>/;

                ( $cont{legal}{$atype}{country_code} ) = $postal =~ /<contact:cc>([A-Z]+)<\/contact:cc>/;
            }
        }
    }

    return \%cont;
}

=head2 create_domain

Domains ru.net+ tlds have only the registrant, without the administrator and other contacts

=cut

sub create_domain {
    my ( $self, $params ) = @_;

    $params->{authinfo} ||= IO::EPP::Base::gen_pw( 16 );

    my $extension = '';

    if ( $params->{dname} =~ /\.xn--80adxhks$/ ) {
        # .москва support RU lang only
        $extension .= qq|   <idn:data xmlns:idn="urn:ietf:params:xml:ns:idn-1.0">\n|;
        $extension .=   "    <idn:table>ru-RU</idn:table>\n";
        $extension .=   "   </idn:data>\n";
    }

    if ( $params->{price}  or  $params->{fee} ) {
        my $price = $params->{price} || $params->{fee};
        # Russian Ruble only
        $extension .= qq|   <fee:create xmlns:fee="urn:ietf:params:xml:ns:fee-0.11">\n|;
        $extension .=   "    <fee:currency>RUB</fee:currency>\n";
        $extension .=   "    <fee:fee>$price</fee:fee>\n";
        $extension .=   "   </fee:create>\n";
    }

    $params->{extension} = $extension if $extension;

    return $self->SUPER::create_domain( $params );
}


sub get_domain_spec_ext {
    my ( undef, $ext ) = @_;

    my %info;

    if ( $ext =~ /<idn:data xmlns:idn="urn:ietf:params:xml:ns:idn-1.0">(.+?)<\/idn:data>/s ) {
        my $idn = $1;

        ( $info{uname} ) = $idn =~ /<idn:uname>([^<>]+)<\/idn:uname>/;
    }

    return \%info;
}


sub renew_domain {
    my ( $self, $params ) = @_;

    my $extension = '';

    if ( $params->{price}  or  $params->{fee} ) {
        my $price = $params->{price} || $params->{fee};
        # Russian Ruble only
        $extension .= qq|   <fee:renew xmlns:fee="urn:ietf:params:xml:ns:fee-0.11">\n|;
        $extension .=   "    <fee:currency>RUB</fee:currency>\n";
        $extension .=   "    <fee:fee>$price</fee:fee>\n";
        $extension .=   "   </fee:renew>\n";
    }

    $params->{extension} = $extension if $extension;

    return $self->SUPER::renew_domain( $params );
}


=head2 restore_domain

first call for restore_domain

=cut

sub restore_domain {
    my ( $self, $params ) = @_;

    $params->{extension} = qq|<rgp:update $rgp_ext>
    <rgp:restore op=\"request\"/>
   </rgp:update>|;

    return $self->SUPER::update_domain( $params );
}


=head2 confirmations_restore_domain

Second call for restore_domain

=over 4

=item C<pre_data>

whois before delete;

=item C<post_data>

whois on now;

=item C<del_time>

delete domain date-time, see. upd_date in domain:info before call restore_domain;

=item C<rest_time>

restore request call datetime in UTC;

=item C<reason>

restore reason,

variants: C<Registrant Error>, C<Registrar Error>, C<Judicial / Arbitral / Administrative / UDRP Order>;

=item C<statement>

need to write what it is for the client;

=item C<other>

can and without other.

=back

=cut

sub confirmations_restore_domain {
    my ( $self, $params ) = @_;

    $params->{extension} = <<RGPEXT;
    <rgp:update $rgp_ext>
      <rgp:restore op="report">
        <rgp:report>
          <rgp:preData>$$params{pre_data}</rgp:preData>
          <rgp:postData>$$params{post_data}</rgp:postData>
          <rgp:delTime>$$params{del_time}</rgp:delTime>
          <rgp:resTime>$$params{rest_time}</rgp:resTime>
          <rgp:resReason>$$params{reason}</rgp:resReason>
          <rgp:statement>$$params{statement}</rgp:statement>
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
