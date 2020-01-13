package IO::EPP::TCI;

=encoding utf8

=head1 NAME

IO::EPP::TCI

=head1 SYNOPSIS

    use IO::EPP::TCI;

    # Parameters for IO::Socket::SSL
    my %sock_params = (
        PeerHost        => 'uap.tcinet.ru',
        PeerPort        => 8130, # .дети 8130, .tatar 8131
        SSL_key_file    => 'key_file.pem',
        SSL_cert_file   => 'cert_file.pem',
        Timeout         => 30,
    );

    # Create object, get greeting and call login()
    my $conn = IO::EPP::TCI->new( {
        user => 'XXX-DETI',
        pass => 'XXXXXXXX',
        sock_params => \%sock_params,
        server => 'afilias', # or pir, ...
        test_mode => 0, # real connect
    } );

    # Check domain
    my ( $answ, $code, $msg ) = $conn->check_domains( { domains => [ 'xn--80akfym3e.xn--d1acj3b' ] } );

    # Call logout() and destroy object
    undef $conn;

=head1 DESCRIPTION

Work with normal TCI EPP API

.дети/.xn--d1acj3b documents:
L<http://dotdeti.ru/foruser/docs/>, L<https://tcinet.ru/documents/deti/2TechPolitDeti.pdf>

.tatar documents:
L<http://domain.tatar/to-registars/documents.php>, L<https://tcinet.ru/documents/deti/2TechPolitTatar.pdf>

=cut

use IO::EPP::Base;
use parent qw( IO::EPP::Base );

use strict;
use warnings;

sub make_request {
    my ( $action, $params ) = @_;

    my ( $self, $code, $msg, $answ );

    unless ( $params->{conn} ) {
        $params->{sock_params}{PeerHost} ||= 'uap.tcinet.ru';
        $params->{sock_params}{PeerPort} ||= 8130; #  .дети, for .tatar need 8131

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
    <objURI>urn:ietf:params:xml:ns:epp-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:eppcom-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:contact-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:domain-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>';
    my $extension = '
     <extURI>http://www.tcinet.ru/epp/tci-contact-ext-1.0</extURI>
     <extURI>http://www.tcinet.ru/epp/tci-domain-ext-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:launch-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>
     <extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI>
     <extURI>http://www.tcinet.ru/epp/tci-billing-1.0</extURI>';

    return $self->SUPER::login( $pw, $svcs, $extension );
}


sub contact_ext {
    my ( undef, $params ) = @_;

    my $ext = '';

    if ( $params->{birthday} ) {
        $ext .= "   <contact:person>\n";

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

    $params->{cont_id} ||= IO::EPP::Base::gen_id( 16 );

    $params->{authinfo} = IO::EPP::Base::gen_pw( 16 );

    my $extension = $self->contact_ext( $params );

    if ( $extension ) {
        $params->{extension} = qq|   <contact:create xmlns:contact="http://www.tcinet.ru/epp/tci-contact-ext-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.tcinet.ru/epp/tci-contact-ext-1.0 tci-contact-ext-1.0.xsd">\n$extension   </contact:create>\n|;
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

Has an optional C<description> field.

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

    $params->{extension} = $extension if $extension;

    return $self->SUPER::create_domain( $params );
}


sub get_domain_spec_ext {
    my ( undef, $ext ) = @_;

    my %info;

    if ( $ext =~ m|<domain:infData[^<>]+tci-domain-ext-1[^<>]+>(.+?)</domain:infData>|s ) {
        my $tciinfo = $1;

        ( $info{descr} ) = $tciinfo =~ m|<domain:description>([^<>]+)</domain:description>|;
    }

    return \%info;
}


sub DESTROY {
    local ($!, $@, $^E, $?);

    my $self = shift;

    if ( $self->{sock} ) {
        $self->logout();
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
