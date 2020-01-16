package IO::EPP::RIPN;

=encoding utf8

=head1 NAME

IO::EPP::RIPN

=head1 SYNOPSIS

    use IO::EPP::RIPN;

    # Parameters for LWP
    my %sock_params = (
        PeerHost        => 'uap.tcinet.ru',
        PeerPort        => 8028, # 8027 for .SU,  8028 for .RU,  8029 for .РФ
        SSL_key_file    => 'key_file.pem',
        SSL_cert_file   => 'cert_file.pem',
        LocalAddr       => '1.2.3.4',
        Timeout         => 30,
    );

    # Create object, get greeting and call login()
    my $conn = IO::EPP::RIPN->new( {
        user => 'XXX-RU',
        pass => 'XXXXXXXX',
        sock_params => \%sock_params,
        test_mode => 0, # real connect
    } );

    # Check domain
    my ( $answ, $code, $msg ) = $conn->check_domains( { domains => [ 'my.ru', 'out.ru' ] } );

    # Call logout() and destroy object
    undef $conn;

=head1 DESCRIPTION

RIPN is the first organization the registry in the .ru tld.
Then it transferred functions of the registry into L<TCI|https://tcinet.ru>,
but all special headings in epp remained

Examlpe:

C<xsi:schemaLocation="http://www.ripn.net/epp/ripn-epp-1.0 ripn-epp-1.0.xsd">
instead of
C<xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">

Module overwrites IO::EPP::Base where there are differences from RFC
and work with tcinet epp using http api.

For details see:
L<https://tcinet.ru/documents/RU-RF/TechRules.pdf>,
L<https://tcinet.ru/documents/RU-RF/P2_RIPN-EPP.pdf>,
L<https://tcinet.ru/documents/SU/SUTechRules.pdf>,
L<https://tcinet.ru/documents/SU/SU_P2_RipnEPP.pdf>.

All documents -- L<https://tcinet.ru/documents/>.

IO::EPP::RIPN only works with .RU, .SU & .РФ cctlds.

For work with the new gtlds .ДЕТИ, .TATAR need use L<IO::EPP::TCI>.

Features:

Working over https;

Completely other contacts;

Non-standard domain transfer in the .su zone;

The domain:check function has an error: when checking the availability of a blocked domain, it responds that it is available.
The list of blocked domains should be downloaded from the Registrar panel.

=cut

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Cookies;
use Time::HiRes qw( time );

use IO::EPP::Base;
use parent qw( IO::EPP::Base );

use strict;
use warnings;

# Old TCI uses special headings
our $epp_head = '<?xml version="1.0" encoding="UTF-8"?>
<epp xmlns="http://www.ripn.net/epp/ripn-epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.ripn.net/epp/ripn-epp-1.0 ripn-epp-1.0.xsd">';
our $epp_cont_urn =
'xmlns:contact="http://www.ripn.net/epp/ripn-contact-1.0" xsi:schemaLocation="http://www.ripn.net/epp/ripn-contact-1.0 ripn-contact-1.0.xsd"';
our $epp_host_urn =
'xmlns:host="http://www.ripn.net/epp/ripn-host-1.0" xsi:schemaLocation="http://www.ripn.net/epp/ripn-host-1.0 ripn-host-1.0.xsd"';
our $epp_dom_urn  =
'xmlns:domain="http://www.ripn.net/epp/ripn-domain-1.0" xsi:schemaLocation="http://www.ripn.net/epp/ripn-domain-1.0 ripn-domain-1.0.xsd"';
our $epp_dom_urn_ru  =
'xmlns:domain="http://www.ripn.net/epp/ripn-domain-1.1" xsi:schemaLocation="http://www.ripn.net/epp/ripn-domain-1.1 ripn-domain-1.1.xsd"';
our $epp_reg_urn  =
'xmlns:registrar="http://www.ripn.net/epp/ripn-registrar-1.0" xsi:schemaLocation="http://www.ripn.net/epp/ripn-registrar-1.0 ripn-registrar-1.0.xsd"';


sub make_request {
    my ( $action, $params ) = @_;

    #$params = IO::EPP::Base::recursive_utf8_unflaged( $params );

    my ( $code, $msg, $answ, $self );

    unless ( $params->{conn} ) {
        # Default:
        $params->{sock_params}{PeerHost} ||= 'uap.tcinet.ru';
        $params->{sock_params}{PeerPort} ||= 8028; # .RU

        ( $self, $code, $msg ) = IO::EPP::RIPN->new( $params );

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

    $msg .= ', ' . $self->{critical_error} if $self->{critical_error};

    my $full_answ = "code: $code\nmsg: $msg";

    $answ = {} unless $answ && ref $answ;

    $answ->{code} = $code;
    $answ->{msg}  = $msg;

    return wantarray ? ( $answ, $full_answ, $self ) : $answ;
}


sub gen_pw {
    my @chars = ( 'A'..'Z', 'a'..'z', '0'..'9', '!', '@', '$', '%', '*', '_', '.', ':', '-', '=', '+', '?', '#', ',' );

    return join '', map( { $chars[ int rand( scalar @chars ) ] } 1..16 );
}


=head1 METHODS

=head2 new

If the C<alien_conn> parameter is received, it loads cookies from the file specified by C<load_cook_from>

=cut

sub new {
    my ( $package, $params ) = @_;

    my ( $self, $code, $msg );

    my $sock_params   = delete $params->{sock_params};

    my $host          = $sock_params->{PeerHost};
    my $port          = $sock_params->{PeerPort};
    my $url           = "https://$host:$port";
    my $local_address = $sock_params->{LocalAddr};
    my $timeout       = $sock_params->{Timeout} || 5;

    my %ua_params = ( ssl_opts => $sock_params );
    $ua_params{local_address} = $local_address if $local_address;

    if ( $timeout ) {
        # LWP feature: first param for LWP, second - for IO::Socket
        $ua_params{timeout} = $timeout;
        $ua_params{Timeout} = $timeout;
    }

    my $cookie;
    if ( $params->{alien_conn} ) {
        $cookie = HTTP::Cookies->new( autosave => 0 );

        unless ( $cookie->load( $params->{load_cook_from} ) ) {
            $msg = "load cooker is fail";
            $code = 0;

            goto ERR;
        }
    }
    else {
        $cookie = HTTP::Cookies->new;
    }

    my $ua = LWP::UserAgent->new(
        agent      => 'EppBot/7.02 (Perl; Linux i686; ru, en_US)',
        parse_head =>  0,
        keep_alive => 30,
        cookie_jar => $cookie,
        %ua_params,
    );

    unless ( $ua ) {
        $msg = "can not connect";
        $code = 0;

        goto ERR;
    }

    $self = bless {
        sock     => $ua,
        user     => $params->{user},
        url      => $url,
        cookies  => $cookie,
        no_log   => delete $params->{no_log},
        alien    => $params->{alien_conn} ? 1 : 0,
    };

    $self->set_urn();

    $self->set_log_vars( $params );

    $self->epp_log( "Connect to $url\n" );

    if ( $self->{alien} ) {
        return wantarray ? ( $self, 1000, 'ok' ) : $self;
    }

    # Get HEADER only
    $self->epp_log( "HEAD connect to $url from $local_address" );

    my $request = HTTP::Request->new( HEAD => $url ); # не POST
    my $response = $ua->request( $request );

    my $rcode = $response->code;
    $self->epp_log( "header answ code: $rcode" );

    unless ( $rcode == 200 ) {
        $code = 0;
        $msg  = "Can't open socket";

        goto ERR;
    }

    my $headers = $response->headers;

    my $length = $headers->content_length;
    $self->epp_log( "header content-length == $length" );

    if ( $length == 0 ) {
        $code = 0;
        $msg  = "Can't open socket";

        goto ERR;
    }

    my ( undef, $c0, $m0 ) = $self->hello();

    unless ( $c0  &&  $c0 == 1000 ) {
        $code = 0;
        $msg = "Can't get greeting";
        $msg .= '; ' . $self->{critical_error} if $self->{critical_error};

        goto ERR;
    }


    my ( undef, $c1, $m1 ) = $self->login( delete $params->{pass} ); # no password in object

    if ( $c1  &&  $c1 == 1000 ) {
        return wantarray ? ( $self, $c1, $m1 ) : $self;
    }

    $msg = ( $m1 || '' ) . $self->{critical_error};
    $code = $c1 || 0;

ERR:
    return wantarray ? ( 0, $code, $msg ) : 0;
}


sub set_urn {
    $_[0]->{urn} = {
        head => $IO::EPP::RIPN::epp_head,
        cont => $IO::EPP::RIPN::epp_cont_urn,
        host => $IO::EPP::RIPN::epp_host_urn,
        dom  => $IO::EPP::RIPN::epp_dom_urn,
        reg  => $IO::EPP::RIPN::epp_reg_urn,
    };
}


sub req {
    my ( $self, $out_data, $info ) = @_;

    return 0 unless $out_data && $self->{sock};

    $info ||= '';

    if ( $out_data ) {
        my $d = $out_data;
        # remove password, authinfo from log
        $d =~ s/<pw>[^<>]+<\/pw>/<pw>xxxxx<\/pw>/;

        $self->epp_log( "$info request:\n$d" );
    }

    my $request = HTTP::Request->new( POST => $self->{url} );
    $request->content_type('text/xml');
    $request->content_type_charset('UTF-8');
    $request->content( $out_data );

    my $start_time = time;

    my $response = $self->{sock}->request( $request );

    my $req_time = sprintf( '%0.4f', time - $start_time );

    # print Dumper $response;

    my $rcode = $response->code;

    unless ( $rcode == 200 ) {
        $self->{critical_error} = "Get answer code = $rcode";

        return 0;
    }

    # feature of connection on epp over https
    if ( $info eq 'login' ) {
        $self->{cook} = $self->{sock}->cookie_jar->as_string;
        $self->epp_log( "cookies: $$self{cook}" );

        $self->{sessionid} = $response->header('set-cookie') || '';
        $self->epp_log( "sessionid: $$self{sessionid}" );
    }

    my $in_data = $response->content;

    $self->epp_log( "req_time: $req_time\n$info answer:\n$in_data\n" );

    return $in_data;
}


=head2 login

Ext params for login,

INPUT: new password for change

=cut

sub login {
    my ( $self, $pw, undef, undef, $new_pw ) = @_;

    return 0 unless $pw;

    my $npw = $new_pw ? "\n   <newPW>$new_pw</newPW>" : '';

    my ( $svcs, $ext ) = ( '', '' );

    if ( $self->{user} =~ /-(RU|RF)$/ ) {
        $svcs = "\n    <objURI>http://www.ripn.net/epp/ripn-domain-1.1</objURI>";
        # Does not work $ext  = "\n     <extURI>http://www.tcinet.ru/epp/tci-billing-1.0</extURI>";
    }

    my $cltrid = $self->get_cltrid();

    my $body = <<LOGIN;
$$self{urn}{head}
 <command>
  <login>
   <clID>$$self{user}</clID>
   <pw>$pw</pw>$npw
   <options>
    <version>1.0</version>
    <lang>en</lang>
   </options>
   <svcs>
    <objURI>http://www.ripn.net/epp/ripn-contact-1.0</objURI>
    <objURI>http://www.ripn.net/epp/ripn-domain-1.0</objURI>$svcs
    <objURI>http://www.ripn.net/epp/ripn-epp-1.0</objURI>
    <objURI>http://www.ripn.net/epp/ripn-eppcom-1.0</objURI>
    <objURI>http://www.ripn.net/epp/ripn-host-1.0</objURI>
    <objURI>http://www.ripn.net/epp/ripn-registrar-1.0</objURI>
    <svcExtension>
     <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>$ext
    </svcExtension>
   </svcs>
  </login>
  <clTRID>$cltrid</clTRID>
  </command>
</epp>
LOGIN

    return $self->simple_request( $body, 'login' );
}


=head2 save_cookies

Save http connection cookies,
they can be used to create another connection on this IP address without opening a new session, that is, without a login

=cut

sub save_cookies {
    my ( $self, $params ) = @_;

    unless ( ref $params  and  $params->{save_cook_to} ) {
        return wantarray ? ( 0, 0, 'no params' ) : 0;
    }

    my $cook = $self->{sock}->cookie_jar->as_string;

    open( COOKFILE, '>', $params->{save_cook_to} )  or  return ( 0, 0, "Can't open $$params{save_cook_to} file: $!" );
    print COOKFILE "#LWP-Cookies-1.0\n";
    print COOKFILE "$cook\n";
    close COOKFILE;

    my %info = ( cook => $cook );
    $self->{cook} = $cook;

    return wantarray ? ( \%info, 1000, 'ok' ) : \%info;
}


=head2 hello

For details, see L<IO::EPP::Base/hello>

=cut

sub hello {
    my ( $self ) = @_;

    my $body = <<HELLO;
$$self{urn}{head}
 <hello/>
</epp>
HELLO

    my $content = $self->req( $body, 'hello' );

    return 0 unless $content && $content =~ /greeting/;

    my $info = { code => 1000, msg  => $content };

    return wantarray ? ( $info, 1000, $content ) : $info;
}

=head2 cont_to_xml

Overrides the base class converter, since the contacts are very different here.

=cut

sub cont_to_xml {
    my ( undef, $cont ) = @_;

    my $is_person = $cont->{passport} ? 1 : 0;

    my $txtcont .= $is_person ? "<contact:person>\n" : "<contact:organization>\n";

    foreach my $type ( 'int', 'loc' ) {
        $txtcont .= "    <contact:".$type."PostalInfo>\n";

        if ( $is_person ) {
	   $txtcont .= "     <contact:name>".$$cont{$type}{name}."</contact:name>\n";
        }
        else {
	   $txtcont .= "     <contact:org>".$$cont{$type}{org}."</contact:org>\n";
        }

        $$cont{$type}{addr} = [ $$cont{$type}{addr} ] unless ref $$cont{$type}{addr};

        $txtcont .= "     <contact:address>$_</contact:address>\n" foreach @{$$cont{$type}{addr}};

        $txtcont .= "    </contact:".$type."PostalInfo>\n";
    }

    unless ( $is_person ) {
	$txtcont .= "    <contact:legalInfo>\n";

	$$cont{legal}{addr} = [ $$cont{legal}{addr} ] unless ref $$cont{legal}{addr};

        $txtcont .= "     <contact:address>$_</contact:address>\n" foreach @{$$cont{legal}{addr}};

	$txtcont .= "    </contact:legalInfo>\n";
    }

    if ( $$cont{taxpayerNumbers} ) {
	$txtcont .= "    <contact:taxpayerNumbers>$$cont{TIN}</contact:taxpayerNumbers>\n";
    }
    else {
	$txtcont .= "    <contact:taxpayerNumbers/>\n";
    }

    if ( $is_person ) {
	$txtcont .= "    <contact:birthday>$$cont{birthday}</contact:birthday>\n";

	$$cont{passport} = [ $$cont{passport} ] unless ref $$cont{passport};

        $txtcont .= "    <contact:passport>$_</contact:passport>\n" foreach @{$$cont{passport}};
    }

    $$cont{phone} = [ $$cont{phone} ] unless ref $$cont{phone};

    $txtcont .= "    <contact:voice>$_</contact:voice>\n" foreach @{$$cont{phone}};

    if ( $$cont{fax} ) {
        $$cont{fax} = [ $$cont{fax} ] unless ref $$cont{fax};

        $txtcont .= "    <contact:fax>$_</contact:fax>\n" foreach @{$$cont{fax}};
    }
    else {
        $txtcont .= "    <contact:fax/>\n";
    }

    $$cont{email} = [ $$cont{email} ] unless ref $$cont{email};

    $txtcont .= "    <contact:email>$_</contact:email>\n" foreach @{$$cont{email}};

    if ( $is_person ) {
        $txtcont .= "   </contact:person>\n";
    }
    else {
        $txtcont .= "   </contact:organization>\n";
    }

    if ( $$cont{verified} ) {
        $txtcont .= "   <contact:verified/>";
    }
    else {
	$txtcont .= "   <contact:unverified/>";
    }

    return $txtcont;
}


=head2 create_contact

Parameter names are maximally unified with other providers.

INPUT:

for individual:

C<name> — full name, need for C<int> and C<loc> types;

C<birthday> — date of birth;

C<passport> — identification card number, place and date of issue;

for legal entity:

C<org> — organization name

C<addr> — string or array with full legal address of the organization, need for C<legal> type data

common fields:

C<addr> — string or array with full address;

C<TIN> - taxpayer numbers;

C<phone> – string or array with phone numbers in international format,
you can specify a list of multiple phones,
the suffixes C<(sms)> and C<(transfer)> are used to mark phones for confirming transfers;

C<fax> – string or array with faxes, usually only required for legal entities;

C<email>;

C<verified> – the full name or name of the organization was confirmed by documents.

Examples:

Create person contact

    my %pers = (
        cont_id => 'MY-123456',
        'int' => {
            name => 'Igor I Igover',
            addr => 'UA, 12345, Igorevsk, Igoreva str, 13',
        },
        loc => {.
            name => 'Игорь Игоревич Игорев',.
            addr =>  [ 'UA', '85012', 'Игоревск', 'ул. Игорева, д.12, Игореву И.И.' ],
        },
        TIN => '',
        birthday => '2001-01-01',
        passport => [ 'II662244', 'выдан Игоревским МВД УДМС', '1.1.2017' ],
        phone => '+380.501234567',
        fax => '',
        email => 'mail@igor.name',
    );

    my ( $answ, $code, $msg ) = $conn->create_contact( \%pers );

    # answer

    {
        'cont_id' => 'my-123456',
        'cre_date' => '2020-01-11 10:10:10',
        'cltrid' => '1710de82a0e9249277ffd713f51c8888',
        'svtrid' => '4997598888'
    };

Create legal entity contact

    my %org = (
        # cont_id - auto
        'int' => {.
            org => 'Igor Limited Liability Company',
            addr => [ 'RU', '123456', 'Moscow', 'Igoreva str, 3', 'Igor LLC' ]
        },
        loc => {
            org => 'ООО «Игорь»',
            addr => [ 'RU, 123456, г. Москва, ул. Игорева, дом 3, ООО «Игорь»', 'охраннику' ],
        },
        legal => {.
            addr => [ '125476, г.Москва, ул. Игорева, д.3' ],
        },
        TIN => '7777777777',
        phone => [ '+7.4951111111', '+7.4951111111(transfer)' ],
        fax => '+7.4951111111',
        email => [ 'mail@igor.ru' ],
    );

    my ( $answ, $code, $msg ) = $conn->create_contact( \%org );

    # answer

    {
        'cont_id' => 'e88c1fngsz1e',
        'cre_date' => '2020-01-01 10:10:10',
        'cltrid' => '6194b816dd3f5d3f417fd2cfe0c88888',
        'svtrid' => '4997633333'
    };

=cut

sub create_contact {
    my ( $self, $params ) = @_;

    $params->{cont_id} ||= IO::EPP::Base::gen_id( 16 );

    return $self->SUPER::create_contact( $params );
}


=head2 cont_from_xml

Overrides the base class contact parser.

As a result, the get_contact_info function displays the request response in the registry as follows:

Individual

    my ( $a, $m, $o ) = make_request( 'get_contact_info', { cont_id => 'my-123456' } );

    # answer

    {
        'msg' => 'Command completed successfully',
        'owner' => 'XXX-RU',
        'int' => {
            'name' => 'Igor I Igover',
            'addr' => [
                'UA, 12345, Igorevsk, Igoreva str, 13'
            ]
        },
        'cre_date' => '2020-01-10 10:10:10',
        'phone' => [
            '+380.501234567'
        ],
        'email' => [
            'mail@igor.name'
        ],
        'loc' => {
            'name' => 'Игорь Игоревич Игорев',
            'addr' => [
                'UA',
                '85012',
                'Игоревск',
                'ул. Игорева, д.12, Игореву И.И.'
            ]
        },
        'fax' => [],
        'creater' => 'XXX-RU',
        'verified' => 0,
        'statuses' => {
            'ok' => '+'
        },
        'birthday' => '2001-01-01',
        'passport' => [
            'II662244',
            'выдан Игоревским МВД УДМС',
            '1.1.2017'
        ],
        'code' => '1000'
    };

Legal entity

    my ( $a, $m, $o ) = make_request( 'get_contact_info', { cont_id => 'e88c1fngsz1e' } );

    # answer

    {
        'msg' => 'Command completed successfully',
        'owner' => 'XXX-RU',
        'int' => {
            'org' => 'Igor Limited Liability Company',
            'addr' => [
                'RU',
                '123456',
                'Moscow',
                'Igoreva str, 3',
                'Igor LLC'
            ]
        },
        'cre_date' => '2020-01-10 10:10:10',
        'phone' => [
            '+7.4951111111',
            '+7.4951111111(transfer)'
        ],
        'email' => [
            'mail@igor.ru'
        ],
        'loc' => {
            'org' => 'ООО «Игорь»',
            'addr' => [
                'RU, 123456, г. Москва, ул. Игорева, дом 3, ООО «Игорь»',
                'охраннику'
            ]
        },
        'fax' => [
            '+7.4951111111'
        ],
        'legal' => {
            'addr' => [
            '125476, г.Москва, ул. Игорева, д.3'
            ]
        },
        'creater' => 'XXX-RU',
        'verified' => 0,
        'statuses' => {
            'ok' => '+'
        },
        'code' => '1000'
    };

=cut

sub cont_from_xml {
    my ( undef, $txtcont ) = @_;

    my %cont;

    my $is_person = ($txtcont =~ /contact:person/) ? 1 : 0;

    my @ss = $txtcont =~ /<contact:status s="([^"]+)"\/>/g;
    $cont{statuses}{$_} = '+' for @ss;

    my %types = ( intPostalInfo => 'int', locPostalInfo => 'loc', legalInfo => 'legal' );
    foreach my $type ( keys %types ) {
        if ( $txtcont =~ /<contact:$type>(.+)<\/contact:$type>/s ) {
            my $pi = $1;

            if ( $pi =~ /<contact:name>([^<>]+)<\/contact:name>/ ) {
                $cont{$types{$type}}{name} = $1;
            }
            if ( $pi =~ /<contact:org>([^<>]+)<\/contact:org>/ ) {
                $cont{$types{$type}}{org} = $1;
            }

            $cont{$types{$type}}{addr} = [ $pi =~ /<contact:address>([^<>]+)<\/contact:address>/g ];
        }
    }

    if ( $txtcont =~ /<contact:taxpayerNumbers>([^<>]+)<\/contact:taxpayerNumbers>/ ) {
        $cont{TIN} = $1;
    }

    if ( $is_person ) {
        if ( $txtcont =~ /<contact:birthday>([^<>]+)<\/contact:birthday>/ ) {
            $cont{birthday} = $1;
        }

        $cont{passport} = [ $txtcont =~ /<contact:passport>([^<>]+)<\/contact:passport>/g ];
    }

    $cont{phone} = [ $txtcont =~ /<contact:voice>([^<>]+)<\/contact:voice>/g ];

    $cont{fax} = [ $txtcont =~ /<contact:fax>([^<>]+)<\/contact:fax>/g ];

    $cont{email} = [ $txtcont =~ /<contact:email>([^<>]+)<\/contact:email>/g ];

    if ( $txtcont =~ /<contact:verified\/>/ ) {
        $cont{verified} = 1;
    }
    elsif ( $txtcont =~ /<contact:unverified\/>/ ) {
        $cont{verified} = 0;
    }

    my %id = %IO::EPP::Base::id;
    foreach my $k ( keys %id ) {
        if ( $txtcont =~ /<contact:$k>([^<>]+)<\/contact:$k>/ ) {
            $cont{$id{$k}} = $1;
        }
    }

    my %dt = %IO::EPP::Base::dt;
    foreach my $k ( keys %dt ) {
        if ( $txtcont =~ /<contact:$k>([^<>]+)<\/contact:$k>/ ) {
            $cont{$dt{$k}} = $1;

            $cont{$dt{$k}} =~ s/T/ /;
            $cont{$dt{$k}} =~ s/\.\d+Z$//;
        }
    }

    return \%cont;
}


=head2 transfer

Addition parameter for .SU, .NET.RU, .ORG.RU, .PP.RU:
C<sent_to> - registrar name which will receive the domain (here all on the contrary)

=cut

sub transfer {
    my ( $self, $params ) = @_;

    if ( $params->{to} ) {
        $params->{addition} = "\n    <domain:acID>$$params{sent_to}</domain:acID>";
    }

    if ( $params->{user} =~ /-(RU|RF)$/ ) {
        $self->{urn}{dom} = $epp_dom_urn_ru;
    }

    my @res = $self->SUPER::transfer( $params );

    $self->{urn}{dom} = $IO::EPP::RIPN::epp_dom_urn;

    return @res;
}


=head2 get_registrar_info

Get Registrar data: white IP, email, whois data

=cut

sub get_registrar_info {
    my ( $self ) = @_;

    my $cltrid = $self->get_cltrid();

    my $body = <<REGINFO;
$$self{urn}{head}
 <command>
  <info>
   <registrar:info $$self{urn}{reg}>
    <registrar:id>$$self{user}</registrar:id>
   </registrar:info>
  </info>
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
REGINFO

    my $answ = $self->req( $body, 'registrar_info' );

    if ( $answ  &&  $answ =~ /<result code="(\d+)">/ ) {
        my $rcode = $1 + 0;

        my $msg = '';
        if ( $answ =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        if ( $rcode != 1000 ) {
            if ( $answ =~ /<reason>(.+)<\/reason>/s ) {
                $msg .= '; ' . $1;
            }

            return wantarray ? ( 0, $rcode, $msg ) : 0;
        }

        my $info = {};

        if ( $answ =~ /<resData>(.+)<\/resData>/s ) {
            my $rdata = $1 // '';

            my %types = ( intPostalInfo => 'int', locPostalInfo => 'loc', legalInfo => 'legal' );
            foreach my $type ( keys %types ) {
                if ( $rdata =~ /<registrar:$type>(.+)<\/registrar:$type>/s ) {
                    my $pi = $1;
                    if ( $pi =~ /<registrar:org>([^<>]+)<\/registrar:org>/ ) {
                        $info->{$types{$type}}{org} = $1;
                    }

                    $info->{$types{$type}}{addr} = join(', ', $pi =~ /<registrar:address>([^<>]+)<\/registrar:address>/g );
                }
            }

            if ( $rdata =~ /<registrar:taxpayerNumbers>([^<>]+)<\/registrar:taxpayerNumbers>/ ) {
                $info->{TIN} = $1;
            }

            $info->{phone} = [ $rdata =~ /<registrar:voice>([^<>]+)<\/registrar:voice>/g ];

            $info->{fax} = [ $rdata =~ /<registrar:fax>([^<>]+)<\/registrar:fax>/g ];

            my @emails = $rdata =~ /(<registrar:email type="[^"]+">[^<>]+<\/registrar:email>)/g;

            foreach my $e ( @emails ) {
                if ( $e =~ /registrar:email type="([^"]+)">([^<>]+)<\/registrar:email/ ) {
                    $info->{emails}{$1} = $2;
                }
            }

            if ( $rdata =~ /<registrar:www>([^<>]+)<\/registrar:www>/ ) {
                $info->{www} = $1;
            }

            if ( $rdata =~ /<registrar:whois>([^<>]+)<\/registrar:whois>/ ) {
                $info->{whois} = $1;
            }

            $info->{ips} = [ $rdata =~ /<registrar:addr ip="v\d">([0-9A-Fa-f.:]+)<\/registrar:addr>/g ];

            my %dt = %IO::EPP::Base::dt;
            foreach my $k ( keys %dt ) {
                if ( $rdata =~ /<registrar:$k>([^<>]+)<\/registrar:$k>/ ) {
                    $info->{$dt{$k}} = $1;

                    $info->{$dt{$k}} =~ s/T/ /;
                    $info->{$dt{$k}} =~ s/\.\d+Z$//;
                }
            }
        }

        return wantarray ? ( $info, $rcode, $msg ) : $info;
    }

    return wantarray ? ( 0, 0, 'empty answer' ) : 0;
}


=head2 update_registrar

Changing Registrar data: white IP, email, whois data

INPUT:

key of params:

C<add> or C<rem>:

C<ips> -- arrayref of ipv4 or ipv6 address,

C<emails> - hashref where keys - email type, values - email

C<chg>:

C<www> - new web url

C<whois> - new whois url

=cut

sub update_registrar {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no params' ) unless ref $params;

    my $cltrid = $self->get_cltrid();

    my $add = '';
    if ( $params->{add} ) {
        if ( defined $params->{add}{ips}  and  ref $params->{add}{ips} ) {
            foreach my $ip ( @{$params->{add}{ips}} ) {
                if ( $ip =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
                    $add .= '     <registrar:addr ip="v4">' . $ip . "</registrar:addr>\n";
                }
                else {
                    $add .= '     <registrar:addr ip="v6">' . $ip . "</registrar:addr>\n";
                }
            }
        }

        if ( defined $params->{add}{emails}  and  ref $params->{add}{emails} ) {
            foreach my $type ( @{$params->{add}{emails}} ) {
                $add .= qq|     <registrar:emailtype="$type">| . $$params{add}{emails}{$type} . "</registrar:email>\n";
            }
        }
    }

    if ( $add ) {
        $add = "<registrar:add>\n$add    </registrar:add>";
    }
    else {
        $add = '<registrar:add/>'
    }

    my $rem = '';
    if ( $params->{rem} ) {
        if ( defined $params->{rem}{ips}  &&  ref $params->{rem}{ips} ) {
            foreach my $ip ( @{$params->{rem}{ips}} ) {
                if ( $ip =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
                    $rem .= '     <registrar:addr ip="v4">' . $ip . "</registrar:addr>\n";
                }
                else {
                    $rem .= '     <registrar:addr ip="v6">' . $ip . "</registrar:addr>\n";
                }
            }
        }

        if ( defined $params->{rem}{emails}  and  ref $params->{rem}{emails} ) {
            foreach my $type ( @{$params->{rem}{emails}} ) {
                $rem .= qq|     <registrar:emailtype="$type">| . $$params{rem}{emails}{$type} . "</registrar:email>\n";
            }
        }
    }

    if ( $rem ) {
        $rem = "<registrar:rem>\n$rem    </registrar:rem>";
    }
    else {
        $rem = '<registrar:rem/>'
    }

    my $chg = '';
    if ( $params->{chg} ) {
        if ( $params->{chg}{www} ) {
            $chg .= '     <registrar:www>' . $$params{chg}{www} . "</registrar:www>\n";
        }

        if ( $params->{chg}{whois} ) {
            $chg .= '     <registrar:whois>' . $$params{chg}{www} . "</registrar:whois>\n";
        }
    }

    if ( $chg ) {
        $chg = "<registrar:chg>\n$chg    </registrar:chg>";
    }
    else {
        $chg = "<registrar:chg/>";
    }


    my $body = <<UPDREG;
$$self{urn}{head}
 <command>
  <update>
   <registrar:update $$self{urn}{reg}>
    <registrar:id>$$self{user}</registrar:id>
    $add
    $rem
    $chg
   </registrar:update>
  </update>
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
UPDREG

    return $self->simple_request( $body, 'update_registrar' );
}


=head2 get_billing_info

INPUT:

keys of params:

C<date>,

C<period>: in days,

C<currency>: RUB.

=cut

sub get_billing_info {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no params' ) unless ref $params;

    my $cltrid = $self->get_cltrid();

    my $body = <<BILINFO;
$$self{urn}{head}
 <command>
  <info>
   <billing:info xmlns:billing="http://www.tcinet.ru/epp/tci-billing-1.0">
   <billing:type>balance</billing:type>
    <billing:param>
     <billing:date>$$params{date}</billing:date>
     <billing:period unit="d">$$params{period}</billing:period>
     <billing:currency>$$params{currency}</billing:currency>
    </billing:param>
   </billing:info>
  </info>
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
BILINFO

    my $answ = $self->req( $body, 'billing_info' );

    if ( $answ  &&  $answ =~ /<result code=['"](\d+)['"]>/ ) {
        my $rcode = $1 + 0;

        my $msg = '';
        if ( $answ =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        if ( $rcode != 1000 ) {
            if ( $answ =~ /<reason>(.+)<\/reason>/s ) {
                $msg .= '; ' . $1;
            }

            return wantarray ? ( 0, $rcode, $msg ) : 0;
        }

        my $info = {};

        if ( $answ =~ /<resData>(.+)<\/resData>/s ) {
            my $rdata = $1 // '';

            my @billing = $rdata =~ /(<billing:[^<>]+>[^<>]+<\/billing:[^<>]+>)/g;

            foreach my $row ( @billing ) {
                if ( $row =~ /<billing:([A-Za-z]+)\b[^<>]*>([^<>]+)<\/billing:[^<>]+>/ ) {
                    $info->{$1} = $2;
                }
            }

            $info->{calc_date} = delete $info->{calcDate};
            $info->{calc_date} =~ s/T/ /;
            $info->{calc_date} =~ s/\.\d+Z$//;
        }

        return wantarray ? ( $info, $rcode, $msg ) : $info;
    }

    return wantarray ? ( 0, 0, 'empty answer' ) : 0;
}


=head2 get_limits_info

How many requests are left in this hour

=cut

sub get_limits_info {
    my ( $self ) = @_;

    my $cltrid = $self->get_cltrid();

    my $body = <<LIMINFO;
$$self{urn}{head}
 <command>
  <info>
   <limits:info xmlns:limits="http://www.tcinet.ru/epp/tci-limits-1.0" xsi:schemaLocation="http://www.tcinet.ru/epp/tci-limits-1.0 tci-limits-1.0.xsd"/>
  </info>
 <clTRID>$cltrid</clTRID>
 </command>
</epp>
LIMINFO

    my $answ = $self->req( $body, 'limits_info' );

    if ( $answ  &&  $answ =~ /<result code=['"](\d+)['"]>/ ) {
        my $rcode = $1 + 0;

        my $msg = '';
        if ( $answ =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        if ( $rcode != 1000 ) {
            if ( $answ =~ /<reason>(.+)<\/reason>/s ) {
                $msg .= '; ' . $1;
            }

            return wantarray ? ( 0, $rcode, $msg ) : 0;
        }

        my $info = {};

        if ( $answ =~ /<resData>(.+)<\/resData>/s ) {
            my $rdata = $1 // '';

            my @limits = $rdata =~ /(<limits:[^<>]+>[^<>]+<\/limits:[^<>]+>)/g;

            foreach my $row ( @limits ) {
                if ( $row =~ /<limits:([^<>]+)>([^<>]+)<\/limits:[^<>]+>/ ) {
                    $info->{$1} = $2;
                }
            }
        }

        return wantarray ? ( $info, $rcode, $msg ) : $info;
    }

    return wantarray ? ( 0, 0, 'empty answer' ) : 0;
}


=head2 get_stat_info

Show domain statistics by metric

key of params:
C<metric> -- varians: C<domain>, C<domain_pending_transfer>, C<domain_pending_delete>, C<contact>, C<host>, C<all>

Now not work:

code="2400", msg="Command failed", reason="Internal server error"

=cut

sub get_stat_info {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no params' ) unless ref $params;

    my $cltrid = $self->get_cltrid();

    my $body = <<STATINFO;
$$self{urn}{head}
 <command>
  <info>
   <stat:info xmlns:stat="http://www.tcinet.ru/epp/tci-stat-1.0">
    <stat:metric name="$$params{metric}"/>
   </stat:info>
  </info>
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
STATINFO

    return $self->simple_request( $body, 'info' );
}


=head2 logout

Close session, disconnect

=cut

sub logout {
    my ( $self ) = @_;

    return 0 unless $self && $self->{sock};

    return 0 if $self->{alien};

    my $cltrid = $self->get_cltrid();

    my $body = <<LOGOUT;
$$self{urn}{head}
 <command>
  <logout/>
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
LOGOUT

    # The answer doesn't matter
    $self->req( $body, 'logout' );

    delete $$self{sock};
    delete $$self{cook};
    delete $$self{cookies};
    delete $$self{sessionid};
    delete $$self{user};
    delete $$self{url};
}

1;


__END__

=pod

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
