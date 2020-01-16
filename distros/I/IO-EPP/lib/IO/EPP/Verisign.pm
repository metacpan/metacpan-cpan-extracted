package IO::EPP::Verisign;

=encoding utf8

=head1 NAME

IO::EPP::Verisign

=head1 SYNOPSIS

    use IO::EPP::Verisign;

    # Parameters for IO::Socket::SSL
    my %sock_params = (
        PeerHost        => 'epp.verisign-grs.com',
        PeerPort        => 700,
        SSL_key_file    => 'key_file.pem',
        SSL_cert_file   => 'cert_file.pem',
        Timeout         => 30,
    );

    # Create object, get greeting and call login()
    my $conn = IO::EPP::Verisign->new( {
        user => 'login',
        pass => 'XXXXX',
        sock_params => \%sock_params,
        server => 'Core', # or NameStore, or  DotName
        test_mode => 0, # real connect
    } );

    # Check domain
    my ( $answ, $code, $msg ) = $conn->check_domains( { domains => [ 'com.net', 'net.com' ] } );

    # Call logout() and destroy object
    undef $conn;

=head1 DESCRIPTION

Work with Verisign EPP API

Features:
Very mach extension, verisign here is leader. Absolutely all extensions have not yet been implemented

docs:
L<https://www.verisign.com/en_US/channel-resources/domain-registry-products/epp-sdks/index.xhtml?loc=en_US>,
L<https://epptool-ctld.verisign-grs.com/epptool/> (need white IP)

for .name:
L<https://www.verisign.com/assets/email-forwarding-mapping.pdf>

The behavior of C<Core> and C<NameStore> servers is markedly different.

=cut

use IO::EPP::Base;
use parent qw( IO::EPP::Base );

use strict;
use warnings;

# not to change formatting:
our $sub_product_ext_begin =
'   <namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd">
    <namestoreExt:subProduct>';
our $sub_product_ext_end =
'</namestoreExt:subProduct>
   </namestoreExt:namestoreExt>';
our $idn_ext =
'xmlns:idnLang="http://www.verisign.com/epp/idnLang-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.verisign.com/epp/idnLang-1.0 idnLang-1.0.xsd"';
our $rgp_ext =
'xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd"';

sub make_request {
    my ( $action, $params ) = @_;

    my ( $self, $code, $msg, $answ );

    unless ( $params->{conn} ) {
        $params->{sock_params}{PeerHost} ||= 'epp.verisign-grs.com';
        $params->{sock_params}{PeerPort} ||= 700;

        ( $self, $code, $msg ) = __PACKAGE__->new( $params );

        unless ( $code  and  $code == 1000 ) {
            goto END_MR;
        }
    }
    else {
        $self = $params->{conn};
    }


    # You can change the zone if you do not change the server
    # com <-> net <-> edu
    # cc <-> tv <-> jobs <-> name <-> ... new gtld
    my $tld = $self->{tld} || '';

    if ( not $tld  and  $params->{dname} ) {
        ( $tld ) = $params->{dname} =~ /\.([^.]+)$/;
    }

    if ( $tld ) {
        if ( lc ( $tld ) eq 'name' ) {
            $self->{dzone} = 'name';
        }
        else {
            $self->{dzone} = 'dot' . uc( $tld );
        }

        $self->{namestore_ext} = $sub_product_ext_begin . $self->{dzone} . $sub_product_ext_end ."\n";
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


sub req_test {
    my ( $self, $out_data, $info ) = @_;

    $self->epp_log( "$info request:\n$out_data" ) if $out_data;

    my $answ;

    if ( $self->{server} eq 'Core' ) {
        require IO::EPP::Test::VerisignCore;

        eval{
            $answ = IO::EPP::Test::VerisignCore::req( @_ );
            1;
        }
        or do {
            $self->{critical_error} = "$info req error: $@";
            return;
        };
    }
    else { # DotName, NameStore
        require IO::EPP::Test::VerisignName;

        eval{
            $answ = IO::EPP::Test::VerisignName::req( @_ );
            1;
        }
        or do {
            $self->{critical_error} = "$info req error: $@";
            return;
        };
    }

    $self->epp_log( "$info answer:\n$answ" );

    return $answ;
}


=head1 METHODS

Here are the features that distinguish the registry from the EPP RFC.
All basic information about functions is in L<IO::EPP::Base>

=head2 new

See description in L<IO::EPP::Base/new>

Requires the C<server> field to be specified, which can have values:
C<Core> for .com/.net/.edu,
C<DotName> for .name,
C<NameStore> for cctld and new gtlds.

=cut

sub new {
    my ( $package, $params ) = @_;

    unless ( $params->{server}  ||  $params->{dname}  ||  $params->{tld} ) {
        if ( $params->{sock_params}{PeerHost} =~ 'epp.verisign-grs.com' ) {
            $params->{server} = 'Core';
        }
        elsif ( $params->{sock_params}{PeerHost} eq 'namestoressl.verisign-grs.com' ) {
            $params->{server} = 'NameStore';
        }
    }

    unless ( $params->{server}  or  $params->{tld}  or  $params->{dname} ) {
        return wantarray ? ( 0, 0, 'unknown server: Core or DotName, need set server, tld or dname field' ) : 0 ;
    }

    $params->{dname} = lc $params->{dname} if $params->{dname};

    my $tld = $params->{tld} || '';

    if ( not $tld  and  $params->{dname} ) {
        ( $tld ) = $params->{dname} =~ /\.([^.]+)$/;
    }

    if ( $params->{server}  and  not $tld ) {
        if ( $params->{server} eq 'Core' ) {
            $tld = 'com';
        }
        elsif ( $params->{server} eq 'DotName' ) {
            $tld = 'name';
        }
        else {
            $tld = 'tv';
        }
    }

    if ( $tld  and  not $params->{server} ) {
        if ( $tld eq 'name' ) {
            $params->{server} = 'DotName';
        }
        elsif ( $tld =~ /^(com|net|edu)$/ ) {
            $params->{server} = 'Core';
        }
        else {
            $params->{server} = 'NameStore';
        }
    }

    $params->{server} = 'DotName' if $tld eq 'name' && $params->{server} ne 'DotName';


    my ( $self, $code, $msg ) = $package->SUPER::new( $params );

    unless ( $code  and  $code == 1000 ) {
        return wantarray ? ( 0, $code, $msg ) : 0;
    }

    if ( $tld ) {
        if ( lc ( $tld ) eq 'name' ) {
            $self->{dzone} = 'name';
        }
        else {
            $self->{dzone} = 'dot' . uc( $tld );
        }

        $self->{namestore_ext} = "   $sub_product_ext_begin" . $self->{dzone} . "$sub_product_ext_end\n";
    }

    return wantarray ? ( $self, $code, $msg ) : $self;
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
    <objURI>urn:ietf:params:xml:ns:contact-1.0</objURI>
    <objURI>http://www.verisign.com/epp/lowbalance-poll-1.0</objURI>';

    my $extension = '
     <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>
     <extURI>http://www.verisign.com/epp/idnLang-1.0</extURI>
     <extURI>http://www.verisign-grs.com/epp/namestoreExt-1.1</extURI>
     <extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI>';

    if ( $self->{server} eq 'Core' ) {

        $svcs .= '
    <objURI>http://www.verisign.com/epp/registry-1.0</objURI>
    <objURI>http://www.verisign.com/epp/rgp-poll-1.0</objURI>';
        $extension .= '
     <extURI>http://www.verisign.com/epp/whoisInf-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:coa-1.0</extURI>
     <extURI>http://www.verisign.com/epp/sync-1.0</extURI>
     <extURI>http://www.verisign.com/epp/relatedDomain-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:changePoll-1.0</extURI>';

    }
    elsif ( $self->{server} eq 'DotName' ) {
        # moved to NameStore but extension in use
        # https://www.verisign.com/assets/email-forwarding-mapping.pdf
        $svcs .= '
    <objURI>http://www.nic.name/epp/nameWatch-1.0</objURI>
    <objURI>http://www.nic.name/epp/emailFwd-1.0</objURI>
    <objURI>http://www.nic.name/epp/defReg-1.0</objURI>';
        $extension .= '
     <extURI>http://www.nic.name/epp/persReg-1.0</extURI>';

    }
    elsif ( $self->{server} eq 'NameStore' ) {

        $svcs .= '
    <objURI>http://www.verisign.com/epp/rgp-poll-1.0</objURI>
    <objURI>http://www.verisign.com/epp/balance-1.0</objURI>
    <objURI>http://www.verisign-grs.com/epp/suggestion-1.1</objURI>
    <objURI>http://www.verisign.com/epp/registry-1.0</objURI>';
        $extension .= '
     <extURI>http://www.verisign.com/epp/sync-1.0</extURI>
     <extURI>http://www.verisign.com/epp/jobsContact-1.0</extURI>
     <extURI>http://www.verisign.com/epp/premiumdomain-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:launch-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:verificationCode-1.0</extURI>
     <extURI>urn:ietf:params:xml:ns:fee-0.9</extURI>';

    }

    return $self->SUPER::login( $pw, $svcs, $extension );
}

=head2 check_contacts

.com/.net/.edu zones are not currently supported

For more information, see L<IO::EPP::Base/check_contacts>

An Example

    my ( $answ, $msg ) = make_request( 'check_contacts', { tld => 'name', contacts => [ 'PP-SP-001', 'GB789HBHKS' ] } );

    # answer:

    {
        'msg' => 'Command completed successfully',
        'PP-SP-001' => {
            'avail' => '0'
        },
        'GB789HBHKS' => {
            'avail' => '1'
        },
        'BHJVJH' => {
            'avail' => '1'
        },
        'code' => '1000'
    };

=cut

sub check_contacts {
    my ( $self, $params ) = @_;

    $params->{extension} = $self->{namestore_ext};

    return $self->SUPER::check_contacts( $params );
}

=head2 create_contact

You cannot register a contact that has two data types at once -- C<int> and C<loc>,
a contact can have any type, but only one.

.com/.net/.edu zones are not currently supported.

For .jobs need additional parameters:
C<jobs_title>, C<jobs_website>, C<jobs_industry_type>, C<is_admin>.

About .jobs parameters see L<https://www.verisign.com/assets/epp-jobscontact-extension.pdf>.

The C<pp_flag> / <disclose> flag is not supported, and the registry does not display contacts in whois

For more information, see L<IO::EPP::Base/create_contact>.

Example with C<int> data type

    my %cont = (
        name       => 'Protection of Private Person',
        org        => 'Private Person',
        addr       => 'PO box 01, Protection Service',
        city       => 'Moscow',
        state      => '',
        postcode   => '125000',
        country_code => 'RU',
        phone      => '+7.4951111111',
        fax        => '+7.4951111111',
        email      => 'my@private.ru',
    );

    my ( $answ, $msg ) = make_request( 'create_contact', { tld => 'name', %cont } );

    # answer
    {
        'msg' => 'Command completed successfully',
        'cont_id' => '5555LECTU555',
        'cre_date' => '2020-01-11 11:11:11',
        'cltrid' => '5552d5cc9ab81c787eb9892eed888888',
        'code' => 1000,
        'svtrid' => '8888176177629-666916888'
    };

Example with C<loc> data type

    my %cont = (
        loc => {
            name       => 'Защита персональных данных',
            org        => 'Частное лицо',
            addr       => 'А/Я 01, Сервис защиты персональных данных',
            city       => 'Москва',
            state      => '',
            postcode   => '125000',
            country_code => 'RU',
        },
        phone      => '+7.4951111111',
        fax        => '+7.4951111111',
        email      => 'my@private.ru',
    );

    my ( $answ, $msg ) = make_request( 'create_contact', { tld => 'name', %cont } );

    # answer

    {
        'msg' => 'Command completed successfully',
        'cont_id' => '5555EMELT555',
        'cre_date' => '2020-01-11 11:11:11',
        'cltrid' => '88807717dfcb0ea49d0106697e888888',
        'code' => 1000,
        'svtrid' => '8889175980353-666988888'
    };

=cut

sub create_contact {
    my ( $self, $params ) = @_;

    $params->{cont_id} ||= IO::EPP::Base::gen_id( 16 );

    $params->{authinfo} = IO::EPP::Base::gen_pw( 16 );

    my $extension = '';

    if ( $self->{dzone} eq 'dotJOBS' ) {
        $extension .= q|   <jobsContact:create xmlns:jobsContact="http://www.verisign.com/epp/jobsContact-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.verisign.com/epp/jobsContact-1.0 jobsContact-1.0.xsd">\n|;
        $extension .=  "    <jobsContact:title>$$params{jobs_title}</jobsContact:title>\n";
        $extension .=  "    <jobsContact:website>$$params{jobs_website}</jobsContact:website>\n";
        $extension .=  "    <jobsContact:industryType>$$params{jobs_industry_type}</jobsContact:industryType>\n";
        $extension .=  "    <jobsContact:isAdminContact>$$params{is_admin}</jobsContact:isAdminContact>\n";
        $extension .=  "    <jobsContact:isAssociationMember>No</jobsContact:isAssociationMember>\n";
        $extension .=  "   </jobsContact:create>\n";
    }

    $params->{extension} = $extension . $self->{namestore_ext};

    return $self->SUPER::create_contact( $params );
}

=head2 get_contact_info

.com/.net/.edu zones are not currently supported.

For more information, see L<IO::EPP::Base/get_contact_info>.

An Example

    my ( $answ, $msg ) = make_request( 'get_contact_info', { tld => 'name', cont_id => '5555LECTU555' } );

    # answer

    {
        'int' => {
            'city' => 'Moscow',
            'country_code' => 'RU',
            'name' => 'Protection of Private Person',
            'postcode' => '125000',
            'addr' => 'PO box 01, Protection Service',
            'state' => undef
        },
        'roid' => '22222100_CONTACT_NAME-VRSN',
        'cre_date' => '2020-01-11 11:11:11',
        'email' => [
            'my@private.ru'
        ],
        'upd_date' => '2020-01-11 11:11:11',
        'fax' => [
            '+7.4951111111'
        ],
        'creater' => 'login',
        'authinfo' => 'HF+B5ON$,qUDkyYW',
        'code' => '1000',
        'owner' => 'LOGIN',
        'msg' => 'Command completed successfully',
        'phone' => [
            '+7.4951111111'
        ],
        'updater' => 'login',
        'cont_id' => '5555LECTU555',
        'statuses' => {
            'ok' => '+'
        }
    };

=cut

sub get_contact_info {
    my ( $self, $params ) = @_;

    $params->{extension} = $self->{namestore_ext};

    return $self->SUPER::get_contact_info( $params );
}


=head2 update_contact

.com/.net/.edu zones are not currently supported.

For more information, see L<IO::EPP::Base/update_contact>.

=cut

sub update_contact {
    my ( $self, $params ) = @_;

    $params->{extension} = $self->{namestore_ext};

    return $self->SUPER::update_contact( $params );
}


=head2 delete_contact

.com/.net/.edu zones are not currently supported.

For more information, see L<IO::EPP::Base/delete_contact>.

=cut

sub delete_contact {
    my ( $self, $params ) = @_;

    $params->{extension} = $self->{namestore_ext};

    return $self->SUPER::delete_contact( $params );
}


sub check_nss {
    my ( $self, $params ) = @_;

    $params->{extension} = $self->{namestore_ext};

    return $self->SUPER::check_nss( $params );
}

=head2 create_ns

Within a single server, all NS-s are shared, that is,
if you register NS for the .com tld, it will be available for the .net tld as well.

For details, see L<IO::EPP::Base/create_ns>.

=cut

sub create_ns {
    my ( $self, $params ) = @_;

    $params->{extension} = $self->{namestore_ext};

    return $self->SUPER::create_ns( $params );
}


sub get_ns_info {
    my ( $self, $params ) = @_;

    $params->{extension} = $self->{namestore_ext};

    return $self->SUPER::get_ns_info( $params );
}


sub update_ns {
    my ( $self, $params ) = @_;

    $params->{extension} = $self->{namestore_ext};

    $params->{no_empty_chg} = 1 unless $params->{chg};

    return $self->SUPER::update_ns( $params );
}


sub delete_ns {
    my ( $self, $params ) = @_;

    $params->{extension} = $self->{namestore_ext};

    return $self->SUPER::delete_ns( $params );
}

=head2 check_domains

With a single request, you can check availability in all zones of this server at once,
if they have accreditation

In the example, accreditation is not available in the .edu tld.
The .info tld belongs to a different registry.

    my ( $answ, $msg ) = make_request( 'check_domains', {
        tld => 'com',
        domains => [ 'qwerty.com', 'bjdwferbkr-e3jd0hf.net', 'bjk8bj-kewew.edu', 'xn--xx.com', 'hiebw.info' ]
    } );

    # answer

    {
        'msg' => 'Command completed successfully',
        'qwerty.com' => {
            'reason' => 'Domain exists',
            'avail' => '0'
        },
        'hiebw.info' => {
            'reason' => 'Not an authoritative TLD',
            'avail' => '0'
        },
        'bjk8bj-kewew.edu' => {
            'reason' => 'Not authorized',
            'avail' => '0'
        },
        'code' => '1000',
        'xn--xx.com' => {
            'reason' => 'Invalid punycode encoding',
            'avail' => '0'
        },
        'bjdwferbkr-e3jd0hf.net' => {
            'avail' => '1'
            }
        };

For details, see L<IO::EPP::Base/check_domains>.

=cut

sub check_domains {
    my ( $self, $params ) = @_;

    $params->{extension} = $self->{namestore_ext};

    return $self->SUPER::check_domains( $params );
}

=head2 create_domain

For IDN domains you need to specify the language code in the C<idn_lang> field

See L<https://www.verisign.com/assets/idn-valid-language-tags.pdf>,
and L<https://www.iana.org/domains/idn-tables> for .com, .net

An Example of a domain with C<idn_lang>, without NSs

    ( $answ, $code, $msg ) = $conn->create_domain( {
        tld => 'com',
        dname => 'xn----htbdjfuifot5a9e.com', # хитрый-домен.com
        period => 1,
        idn_lang => 'RUS'
    } );

    # answer

    {
        'dname' => 'xn----htbdjfuifot5a9e.com',
        'exp_date' => '2021-01-01 01:01:01',
        'cre_date' => '2020-01-01 01:01:01',
        'cltrid' => '37777a45e43d0c691c65538aacd77777',
        'svtrid' => '8888827708-7856526698888'
    };

For more information, see L<IO::EPP::Base/create_domain>.

=cut

sub create_domain {
    my ( $self, $params ) = @_;

    $params->{authinfo} ||= IO::EPP::Base::gen_pw( 16 );

    # Do not change the order of records
    my $extension = $self->{namestore_ext};

    if ( $params->{idn_lang} ) {
        $extension .= "   <idnLang:tag $idn_ext>$$params{idn_lang}</idnLang:tag>\n";
    }

    $params->{extension} = $extension;

    return $self->SUPER::create_domain( $params );
}


sub transfer {
    my ( $self, $params ) = @_;

    if ( defined $params->{authinfo} ) {
        $params->{authinfo} =~ s/&/&amp;/g;
        $params->{authinfo} =~ s/</&lt;/g;
        $params->{authinfo} =~ s/>/&gt;/g;
    }

    $params->{extension} = $self->{namestore_ext};

    return $self->SUPER::transfer( $params );
}

=head2 get_domain_info

For details, see L<IO::EPP::Base/check_domains>.

An Example

    my ( $answ, $msg, $conn ) = make_request( 'get_domain_info', { dname => 'llll.com' } );

    # answer

    {
        'msg' => 'Command completed successfully',
        'owner' => '1000',
        'hosts' => [
            'ns2.llll.com',
            'ns1.llll.com'
        ],
        'roid' => '2222489946_DOMAIN_COM-VRSN',
        'exp_date' => '2020-01-01 01:01:01',
        'cre_date' => '2018-01-01 01:01:01',
        'nss' => [
            'ns1.rrr.ru',
            'ns2.rrr.ru'
        ],
        'dname' => 'llll.com',
        'updater' => 'login',
        'upd_date' => '2019-12-30 13:17:54',
        'creater' => 'login',
        'authinfo' => 'AAA:8k.o5*p"_pAA',
        'statuses' => {
            'clientTransferProhibited' => '+'
        },
        'code' => 1000
    };

=cut

sub get_domain_info {
    my ( $self, $params ) = @_;

    $params->{extension} = $self->{namestore_ext};

    return $self->SUPER::get_domain_info( $params );
}


sub renew_domain {
    my ( $self, $params ) = @_;

    $params->{extension} = $self->{namestore_ext};

    return $self->SUPER::renew_domain( $params );
}


sub update_domain {
    my ( $self, $params ) = @_;

    $params->{extension} = $self->{namestore_ext};

    return $self->SUPER::update_domain( $params );
}

=head2 delete_domain

You can delete a domain only if it does not have NS-s that are used by other domains.
If there are such NS-s, they should be renamed using the C<< update_ns( chg => { new_name => 'new.ns.xxxx.com' } ) >>,
For details see L<IO::EPP::Base/update_ns>.

For more information about C<delete>, see L<IO::EPP::Base/delete_domain>

=cut

sub delete_domain {
    my ( $self, $params ) = @_;

    $params->{extension} = $self->{namestore_ext};

    return $self->SUPER::delete_domain( $params );
}


=head2 restore_domain

First call of restore — request

INPUT:

params with key:

C<dname> — domain name

OUTPUT:
see L<IO::EPP::Base/simple_request>.

=cut

sub restore_domain {
    my ( $self, $params ) = @_;

    $params->{extension} = $self->{namestore_ext} .
"   <rgp:update $rgp_ext>
    <rgp:restore op=\"request\"/>
   </rgp:update>\n";

    return $self->SUPER::update_domain( $params );
}


=head2 confirmations_restore_domain

Secont call of restore — confirmation

INPUT:

params with keys:

C<dname> — domain name

C<pre_data>   — whois before delete, may be none;

C<post_data>  — whois now, may be none;

C<del_time>   — domain delete datetime in UTC;

C<rest_time>  — restore request call datetime in UTC.

The following fields already contain the required value, they do not need to be passed:

C<resReason> — restore reason: "Customer forgot to renew.";

C<statement> — need to write what it is for the client:
"I agree that the Domain Name has not been restored in order to assume the rights to use or sell the name to myself or for any third party.
I agree that the information provided in this Restore Report is true to the best of my knowledge, and acknowledge that intentionally supplying false information in the Restore Report shall constitute an incurable material breach of the Registry-Registrar Agreement.";

C<other>     — additional information, may be empty.

OUTPUT:
see L<IO::EPP::Base/simple_request>.

=cut

sub confirmations_restore_domain {
    my ( $self, $params ) = @_;

    my $extension = $self->{namestore_ext};

    $params->{pre_data}  ||= 'none';
    $params->{post_data} ||= 'none';

    $params->{extension} = <<RGPEXT;
$extension
   <rgp:update $rgp_ext>
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


=head2 req_poll_ext

Processing a special messages from a poll.
Now only processing the message about deleting NS.

An Example

    my ( $answ, $msg, $conn ) = make_request( 'req_poll', \%conn_params );

    # answer:

    {
        'roid' => '77777866_HOST_NAME-VRSN',
        'date' => '2020-01-10 10:10:10',
        'cre_date' => '2010-01-10 10:15:05',
        'ips' => [
            '3.1.1.1'
        ],
        'upd_date' => '2013-01-01 10:00:01',
        'qmsg' => 'Unused Objects Policy',
        'creater' => 'direct',
        'id' => '2222282',
        'ext' => {
            'change' => {
                'who' => 'ctldbatch',
                'row_msg' => '<changePoll:operation op="purge">delete</changePoll:operation>',
                'date' => '2020-01-10 10:00:10.000',
                'reason' => 'Unused objects policy',
                'svtrid' => '416801225',
                'state' => 'before'
            }
        },
        'code' => 1301,
        'msg' => 'Command completed successfully; ack to dequeue',
        'owner' => 'LOGIN',
        'count' => '13',
        'cltrid' => '2222701245bb287334838a273fd22222',
        'ns' => 'ns1.abuse.name',
        'updater' => 'ctldbatch',
        'statuses' => {
            'ok' => '+'
        },
        'svtrid' => '7777770945650-666947777'
    };

=cut

sub req_poll_ext {
    my ( $self, $ext ) = @_;

    my %info;

    if ( $ext =~ m|<changePoll:changeData state="([a-z]+)"[^<>]+>(.+)</changePoll:changeData>|s ) {
        $info{change}{'state'} = $1;
        my $row = $2;

        if ( $row =~ s|<changePoll:date>([^<>]+)</changePoll:date>|| ) {
            $info{change}{date} = $1;

            $info{change}{date} =~ s/T/ /;
            $info{change}{date} =~ s/Z$//;
        }

        if ( $row =~ s|<changePoll:who>([^<>]+)</changePoll:who>|| ) {
            $info{change}{who} = $1;
        }

        if ( $row =~ s|<changePoll:svTRID>([^<>]+)</changePoll:svTRID>|| ) {
            $info{change}{svtrid} = $1;
        }

        if ( $row =~ s|<changePoll:reason>([^<>]+)</changePoll:reason>|| ) {
            $info{change}{reason} = $1;
        }

        $info{change}{row_msg} = $row;
    }
    else {
        $info{ext} = $ext;
    }

    return \%info;
}


=head2 get_registry_info

Registry information for the specified zone

key in params: C<tld>

An Example:

    my ( $answ, $code, $msg ) = $conn->get_registry_info( { tld => 'net' } );

    # answer

    {
          'alphaNumStart' => 'true',
          'max' => [
                     '13',
                     '13'
                   ],
          'language code' => [
                               'ARG',
                               'ASM',
                               'AST',
                               'AVE',
                               'AWA',
                               'BAK',
                               'BAL',
                               'BAN',
                               'BAS',
                               'BEL',
                               'BOS',
                               'CAR',
                               'CHE',
                               'CHV',
                               'COP',
                               'COS',
                               'WEL',
                               'DIV',
                               'DOI',
                               'FIJ',
                               'FRY',
                               'GLA',
                               'GLE',
                               'GON',
                               'INC',
                               'IND',
                               'INH',
                               'JAV',
                               'KAS',
                               'KAZ',
                               'KHM',
                               'KIR',
                               'LTZ',
                               'MAO',
                               'MAY',
                               'MLT',
                               'MOL',
                               'MON',
                               'OSS',
                               'PUS',
                               'SIN',
                               'SMO',
                               'SOM',
                               'SRD',
                               'TGK',
                               'YID',
                               'AFR',
                               'ALB',
                               'ARA',
                               'ARM',
                               'AZE',
                               'BAQ',
                               'BEN',
                               'BHO',
                               'TIB',
                               'BUL',
                               'BUR',
                               'CAT',
                               'CZE',
                               'CHI',
                               'DAN',
                               'GER',
                               'DUT',
                               'GRE',
                               'ENG',
                               'EST',
                               'FAO',
                               'PER',
                               'FIN',
                               'FRE',
                               'GEO',
                               'GUJ',
                               'HEB',
                               'HIN',
                               'SCR',
                               'HUN',
                               'ICE',
                               'ITA',
                               'JPN',
                               'KOR',
                               'KUR',
                               'LAO',
                               'LAV',
                               'LIT',
                               'MAC',
                               'MAL',
                               'NEP',
                               'NOR',
                               'ORI',
                               'PAN',
                               'POL',
                               'POR',
                               'RAJ',
                               'RUM',
                               'RUS',
                               'SAN',
                               'SCC',
                               'SLO',
                               'SLV',
                               'SND',
                               'SPA',
                               'SWA',
                               'SWE',
                               'SYR',
                               'TAM',
                               'TEL',
                               'THA',
                               'TUR',
                               'UKR',
                               'URD',
                               'UZB',
                               'VIE'
                             ],
          'gracePeriod command:transfer unit:d' => '5',
          'gracePeriod command:create unit:d' => '5',
          'default unit:y' => [
                                '1',
                                '1',
                                '1'
                              ],
          'gracePeriod command:autorenew unit:d' => '45',
          'subProduct' => 'NET',
          'idnVersion' => '1.1',
          'expression' => [
                            '[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?',
                            '^(?=.*\\\\d)(?=.*[a-zA-Z])(?=.*[\\\\x21-\\\\x2F\\\\x3A-\\\\x40\\\\x5B-\\\\x60\\\\x7B-\\\\x7E])[\\\\x21-\\\\x7e]{8,32}$',
                            '^([\\-|\\w])+\\.([\\-|\\w])+\\s{0,}$)$'
                          ],
          'redemptionPeriod unit:d' => '30',
          'encoding' => 'PunyCode',
          'max unit:y' => [
                            '10',
                            '10',
                            '1'
                          ],
          'name' => 'NET',
          'maxCheckHost' => '20',
          'urgent' => 'false',
          'default' => '604800',
          'onlyDnsChars' => 'true',
          'maxCheckDomain' => '20',
          'transferHoldPeriod unit:d' => '5',
          'digestType' => [
                            'SHA-1',
                            'SHA-256',
                            'GOST R 34.11-94',
                            'SHA-384'
                          ],
          'alg' => [
                     'RSAMD5',
                     'DH',
                     'DSA',
                     'RSASHA1',
                     'DSA-NSEC3-SHA1',
                     'RSASHA1-NSEC3-SHA1',
                     'RSASHA256',
                     'RSASHA512',
                     'ECC-GOST',
                     'ECDSAP256SHA256',
                     'ECDSAP384SHA384'
                   ],
          'startDate' => '2000-01-01T00:00:00Z',
          'minLength' => '3',
          'status' => [
                        'ok',
                        'serverHold',
                        'serverRenewProhibited',
                        'serverTransferProhibited',
                        'serverUpdateProhibited',
                        'serverDeleteProhibited',
                        'redemptionPeriod',
                        'pendingRestore',
                        'pendingDelete',
                        'clientRenewProhibited',
                        'clientTransferProhibited',
                        'clientUpdateProhibited',
                        'clientDeleteProhibited',
                        'pendingTransfer',
                        'clientHold',
                        'ok',
                        'pendingDelete',
                        'pendingTransfer',
                        'serverUpdateProhibited',
                        'serverDeleteProhibited',
                        'clientUpdateProhibited',
                        'clientDeleteProhibited',
                        'linked'
                      ],
          'zoneMember type:equal' => 'NET',
          'group' => 'THIN',
          'clientDefined' => 'false',
          'pendingRestore unit:d' => '7',
          'minIP' => [
                       '1',
                       '0'
                     ],
          'extURI required:true' => [
                                      'urn:ietf:params:xml:ns:coa-1.0',
                                      'http://www.verisign.com/epp/idnLang-1.0',
                                      'urn:ietf:params:xml:ns:secDNS-1.1',
                                      'http://www.verisign-grs.com/epp/namestoreExt-1.1',
                                      'urn:ietf:params:xml:ns:rgp-1.0',
                                      'http://www.verisign.com/epp/whoisInf-1.0',
                                      'http://www.verisign.com/epp/sync-1.0',
                                      'http://www.verisign.com/epp/relatedDomain-1.0',
                                      'urn:ietf:params:xml:ns:launch-1.0'
                                    ],
          'upDate' => '2013-08-10T21:16:01Z',
          'min unit:y' => [
                            '1',
                            '1',
                            '1'
                          ],
          'unicodeVersion' => '6.0',
          'commingleAllowed' => 'false',
          'pendingDelete unit:d' => '5',
          'sharePolicy' => [
                             'perSystem',
                             'perSystem'
                           ],
          'min' => [
                     '0',
                     '0',
                     '1'
                   ],
          'idnaVersion' => 'IDNA 2008',
          'objURI required:true' => [
                                      'urn:ietf:params:xml:ns:domain-1.0',
                                      'urn:ietf:params:xml:ns:contact-1.0',
                                      'urn:ietf:params:xml:ns:host-1.0',
                                      'http://www.verisign.com/epp/registry-1.0',
                                      'http://www.verisign.com/epp/lowbalance-poll-1.0',
                                      'http://www.verisign.com/epp/rgp-poll-1.0'
                                    ],
          'crDate' => '2000-01-01T00:00:00Z',
          'premiumSupport' => 'false',
          'alphaNumEnd' => 'true',
          'gracePeriod command:renew unit:d' => '5',
          'maxLength' => '63',
          'maxIP' => [
                       '13',
                       '0'
                     ],
          'contactsSupported' => 'false'
    };

=cut

sub get_registry_info {
    my ( $self, $params ) = @_;

    my $tld = uc( $params->{tld} );

    my $cltrid = IO::EPP::Base::get_cltrid();

my $body = <<RINFO;
$$self{urn}{head}
 <command xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <info>
   <registry:info xmlns:registry="http://www.verisign.com/epp/registry-1.0">
    <registry:name>$tld</registry:name>
   </registry:info>
  </info>
  <clTRID>$cltrid</clTRID>
</command>
</epp>
RINFO

    my $content = $self->req( $body, 'get_registry_info' );

    if ( $content =~ /result code=['"](\d+)['"]/ ) {
        my $rcode = $1 + 0;

        my $msg = '';
        if ( $content =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        my %info;

        # take the main part and disassemble
        if ( $content =~ /<resData>(.+)<\/resData>/s ) {
            my $rdata = $1;

            my @list = $rdata =~ m|(<registry:[^<>]+>[^<>]+</registry:[^<>]+>)|g;

            foreach my $row ( @list ) {
                if ( $row =~ m|<registry:([0-9A-Za-z]+)>([^<>]+)</registry:[^<>]+>| ) {
                    my $k = $1;

                    push @{$info{$k}}, $2;
                }
                elsif ( $row =~ m|<registry:([0-9A-Za-z]+)\s+([a-z]+)="([^"]+)">([^<>]+)</registry:[^<>]+>| ) {
                    my $k = "$1 $2:$3";

                    push @{$info{$k}}, $4;
                }
                elsif ( $row =~ m|<registry:([0-9A-Za-z]+)\s+([a-z]+)="([^"]+)"\s+([a-z]+)="([^"]+)">([^<>]+)</registry:[^<>]+>| ) {
                    my $k = "$1 $2:$3 $4:$5";

                    push @{$info{$k}}, $6;
                }
            }

            @list = $rdata =~ m|(<registry:[^<>]+/>)|g;

            foreach my $row ( @list ) {
                if ( $row =~ m|<registry:([0-9A-Za-z]+)\s+([a-z]+)="([^"]+)"/>| ) {
                    my $k .= "$1 $2";

                    push @{$info{$k}}, "$3";
                }
            }

            foreach my $k ( keys %info ) {
                if ( ( scalar @{$info{$k}} ) == 1 ) {
                    $info{$k} = $info{$k}[0];
                }
            }
        }
        else {
            return wantarray ? ( 0, $rcode, $msg ) : 0 ;
        }

        return wantarray ? ( \%info, $rcode, $msg ) : \%info;
    }

    return wantarray ? ( 0, 0, 'empty answer' ) : 0 ;
}


1;


__END__

=pod

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
