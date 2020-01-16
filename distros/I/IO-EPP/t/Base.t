#!/usr/bin/perl

=encoding utf8

=head1 NAME

Base.t

=head1 DESCRIPTION

Tests for IO::EPP::CNic using IO::EPP::Test::CNic for registry emulation

The order of the tests cannot be changed.
The tests make requests into the virtual registrar which stores all data.
Each subsequent test uses the data which were entered into the registry by the previous test.

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=cut

use Test::Spec;

use strict;
use warnings;

use lib '../lib';

use IO::EPP::Test::Server;

no utf8; # !!!  In IO::EPP::Base all work without utf8 flag

use_ok( 'IO::EPP::Base' );

my %sock_params = (
    PeerHost      => 'epp.example.com',
    PeerPort      => 700,
    SSL_key_file  => 'key.pm',
    SSL_cert_file => 'cert.pm',
);

my %login_params = (
    sock_params => \%sock_params,
    user        => 'test',
    pass        => 'test123',
    no_log      => 1,

    test_mode   => 1, # emulation, work without inet
);

# The order of tests cannot be changed!!!

describe 'IO::EPP::Base::' => sub {
    it 'login + hello + manual logout, call through make_request' => sub {
        my %params = %login_params;

        my ( $answ, $msg, $conn ) = IO::EPP::Base::make_request( 'hello', \%params );

        is $answ->{code}, 1000;

        like $msg, qr/<greeting>/;

        like $msg, qr/EXAMPLE EPP server EPP.EXAMPLE.COM/;

        is $conn->{user}, 'test';

        ok $conn->{sock};

        my ( $answ2, $msg2, undef ) = IO::EPP::Base::make_request( 'logout', { conn => $conn } );

        is $answ2->{code}, 1500;

        is $msg2, "code: 1500\nmsg: ok";
    };

    it 'login + hello + manual logout, call through object' => sub {
        my %params = %login_params;

        my $conn = IO::EPP::Base->new( \%params );

        is $conn->{user}, 'test';

        ok $conn->{sock};

        my ( $answ, $code, $msg ) = $conn->hello();

        is $code, 1000;

        like $msg, qr/<greeting>/;

        my ( $answ2, $code2, $msg2 ) = $conn->logout();

        ok !$answ2;

        is $code2, 1500;

        is $msg2, 'ok';
    };

    it 'contact:check' => sub {
        my @contacts = ( 'frhemd78d', 'jekf7fsssdeefnjrejfhjw' );

        my %params = (
            contacts => \@contacts,
            %login_params,
        );

        my ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'check_contacts', \%params );

        is $answ->{code}, 1000;

        foreach my $cont_id ( @contacts ) {
            ok defined $answ->{$cont_id};
        }

        is $msg, "code: 1000\nmsg: Command completed successfully.";
    };

    it 'contact:create' => sub {
        my %cont = (
            cont_id => 'TEST-123',
            'int' => {
                first_name => 'Test',
                last_name => 'Testov',
                org => 'Private Person',
                addr => 'Vagnera 11-22-33',
                city => 'Donetsk',
                'state' => 'DONETSYKA',
                postcode => '83000',
                country_code => 'UA',
            },
            loc => {
                first_name => 'Тест',
                last_name => 'Тестов',
                org => 'Физик',
                addr => [ 'Вагнера', '11-22-33' ],
                city => 'Донецк',
                'state' => 'Донецка',
                postcode => '83000',
                country_code => 'UA',
            },
            phone => [ '+380.987654321', '+380.123456789' ],
            fax => '',
            email => 'test1010@ya.ru',
            authinfo => 'Q2+qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq',
        );

        my %params1 = (
            %cont,
            %login_params,
        );

        $params1{authinfo} = 'qqq';

        my ( $answ1, $msg1, undef ) = IO::EPP::Base::make_request( 'create_contact', \%params1 );

        is $answ1->{code}, 2004;

        is $msg1, "code: 2004\nmsg: authInfo code is invalid: password must be at least 16 characters";


        my %params2 = (
            %cont,
            %login_params,
        );

        $params2{authinfo} = 'qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq';

        my ( $answ2, $msg2, undef ) = IO::EPP::Base::make_request( 'create_contact', \%params2 );

        is $answ2->{code}, 2004;

        is $msg2, "code: 2004\nmsg: authInfo code is invalid: password must contain a mix of uppercase and lowercase characters";


        my %params3 = (
            %cont,
            %login_params,
        );

        $params3{phone} = '84951234567';

        my ( $answ3, $msg3, undef ) = IO::EPP::Base::make_request( 'create_contact', \%params3 );

        is $answ3->{code}, 2001;

        is $msg3, "code: 2001\n".'msg: XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:contact-1.0}voice&#039;: [facet &#039;pattern&#039;] The value &#039;A380954272445&#039; is not accepted by the pattern &#039;(\+[0-9]{1,3}\.[0-9]{1,14})?&#039;.';


        my %params = (
            %cont,
            %login_params,
        );

        my ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'create_contact', \%params );

        is $answ->{code}, 1000;

        is $answ->{cont_id}, $cont{cont_id};

        is $msg, "code: 1000\nmsg: Command completed successfully.";


        my %params0 = (
            %cont,
            %login_params,
        );

        my ( $answ0, $msg0, undef ) = IO::EPP::Base::make_request( 'create_contact', \%params0 );

        is $answ0->{code}, 2302;

        is $msg0, "code: 2302\nmsg: Contact object &#039;TEST-123&#039; already exists.";
    };

    it 'contact:info' => sub {
        my %params = (
            cont_id => 'TEST-123',
            %login_params,
        );

        my ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'get_contact_info', \%params );

        is $answ->{code}, 1000;

        is $answ->{'int'}{name}, 'Test Testov';

        is $answ->{'loc'}{name}, 'Тест Тестов';

        is $answ->{phone}[1], '+380.123456789';

        is $answ->{email}[0], 'test1010@ya.ru';

        my $id = 'TEST-321';

        my %params1 = (
            cont_id => $id,
            %login_params,
        );

        my ( $answ1, $msg1, undef ) = IO::EPP::Base::make_request( 'get_contact_info', \%params1 );

        is $answ1->{code}, 2303;

        is $msg1, "code: 2303\nmsg: Cannot find an object with an ID of $id.";

    };

    it 'contact:update' => sub {
        my $id = 'TEST-123';

        my %cont = (
            first_name => 'Test',
            last_name => 'Testov',
            company => 'Private Person',
            addr => 'Vagnera 11-22-33',
            city => 'Donetsk',
            'state' => 'Donetskaya',
            postcode => '83000',
            country_code => 'UA',
            phone => '+380.987654321',
            fax => '',
            email => 'test0101@ya.ru',
            authinfo => 'Q2+qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq',
        );

        my %params0 = (
            cont_id => $id,
            %login_params,
        );

        my ( $answ0, $msg0, $conn ) = IO::EPP::Base::make_request( 'get_contact_info', \%params0 );

        is $answ0->{code}, 1000;

        is $msg0, "code: 1000\nmsg: Command completed successfully.";

        is $answ0->{'int'}{'state'}, 'DONETSYKA';

        is $answ0->{email}[0], 'test1010@ya.ru';

        my %params = (
            cont_id => $id,
            chg => \%cont,
            conn => $conn,
        );

        my ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_contact', \%params );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";

        my %params2 = (
            cont_id => $id,
            %login_params,
        );

        my ( $answ2, $msg2, undef ) = IO::EPP::Base::make_request( 'get_contact_info', \%params2 );

        is $answ2->{code}, 1000;

        is $answ2->{'int'}{name}, 'Test Testov';

        is $answ2->{'int'}{'state'}, 'Donetskaya';

        is $answ2->{email}[0], 'test0101@ya.ru';

        my %params3 = (
            cont_id => 'YYYY-333',
            chg => \%cont,
            conn => $conn,
        );

        my ( $answ3, $msg3, undef ) = IO::EPP::Base::make_request( 'update_contact', \%params3 );

        is $answ3->{code}, 2303;

        is $msg3, "code: 2303\nmsg: Cannot find that object.";
    };

    it 'contact:delete' => sub {
        my $id = 'TEST-123';

        my %params = (
            cont_id => $id,
            %login_params,
        );

        my ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'delete_contact', \%params );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";

        my %params1 = (
            cont_id => $id,
            %login_params,
        );

        my ( $answ1, $msg1, undef ) = IO::EPP::Base::make_request( 'delete_contact', \%params1 );

        is $answ1->{code}, 2303;

        is $msg1, "code: 2303\nmsg: Contact object cannot be found.";
    };

    it 'host:check' => sub {
        my $s = new IO::EPP::Test::Server( $sock_params{PeerHost} . ':' . $sock_params{PeerPort} );

        $s->data->{doms}{'godaddy.com'} = { avail => 0, reason => 'in use', owner => 'daddy' };
        $s->data->{nss}{'ns1.godaddy.com'} = { avail => 0, reason => 'in use', owner => 'daddy' };
        $s->data->{nss}{'ns2.godaddy.com'} = { avail => 0, reason => 'in use', owner => 'daddy' };
        $s->data->{nss}{'ns1.reg.com'} = { avail => 0, reason => 'in use', owner => 'reg.ru' };
        $s->data->{nss}{'ns2.reg.com'} = { avail => 0, reason => 'in use', owner => 'reg.ru' };
        $s->data->{doms}{'my.com'} = { avail => 0, reason => 'in use', owner => $login_params{user} };

        undef $s;

        my %params = (
            nss => [ 'ns1.my.com', 'ns2.godaddy.com', 'ns1.+++.com' ],
            %login_params,
        );

        my ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'check_nss', \%params );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";

        ok $answ->{'ns1.my.com'}{avail};

        is $answ->{'ns2.godaddy.com'}{avail}, 0;

        is $answ->{'ns2.godaddy.com'}{reason}, 'in use';

        is $answ->{'ns1.+++.com'}{avail}, 0;
    };

    it 'host:create' => sub {
        my %params1 = (
            ns => 'ns1.godaddy.com',
            %login_params,
        );

        my ( $answ1, $msg1, undef ) = IO::EPP::Base::make_request( 'create_ns', \%params1 );

        is $answ1->{code}, 2302;

        is $msg1, "code: 2302\nmsg: A host object with that hostname already exists.";

        my %params2 = (
            ns => 'ns111.godaddy.com',
            %login_params,
        );

        my ( $answ2, $msg2, undef ) = IO::EPP::Base::make_request( 'create_ns', \%params2 );

        is $answ2->{code}, 2201;

        is $msg2, "code: 2201\nmsg: You are not the sponsor for the parent domain of this host and cannot create subordinate host objects for it.";

        my %params3 = (
            ns => 'ns1.my.com',
            %login_params,
        );

        my ( $answ3, $msg3, undef ) = IO::EPP::Base::make_request( 'create_ns', \%params3 );

        is $answ3->{code}, 2004;

        is $msg3, "code: 2004\nmsg: You need IPv4 or IPv6 address.";

        my %params4 = (
            ns => 'ns1.my.com',
            ips => [ '11.bb.cc.dd' ],
            %login_params,
        );

        my ( $answ4, $msg4, undef ) = IO::EPP::Base::make_request( 'create_ns', \%params4 );

        is $answ4->{code}, 2004;

        is $msg4, "code: 2004\nmsg: IP address 11.bb.cc.dd is not valid.";

        my %params = (
            ns => 'ns1.my.com',
            ips => [ '11.22.33.44' ],
            %login_params,
        );

        my ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'create_ns', \%params );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";

        is $answ->{ns}, 'ns1.my.com';
    };

    it 'host:info' => sub {
        my $ns1 = 'my.my.com';

        my %params1 = (
            ns => $ns1,
            %login_params,
        );

        my ( $answ1, $msg1, undef ) = IO::EPP::Base::make_request( 'get_ns_info', \%params1 );

        is $answ1->{code}, 2303;

        is $msg1, "code: 2303\nmsg: The host &#039;$ns1&#039; does not exist";

        my $ns = 'ns1.my.com';

        my %params = (
            ns => $ns,
            %login_params,
        );

        my ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'get_ns_info', \%params );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";

        is $answ->{name}, $ns;

        is $answ->{ips}[0], '11.22.33.44';
    };

    it 'host:update' => sub {
        my $ns1 = 'my.my.com';

        my %params1 = (
            ns => $ns1,
            chg => { add => { ips => '2.4.8.16' } },
            %login_params,
        );

        my ( $answ1, $msg1, undef ) = IO::EPP::Base::make_request( 'update_ns', \%params1 );

        is $answ1->{code}, 2303;

        is $msg1, "code: 2303\nmsg: The host &#039;$ns1&#039; does not exist";

        my $ns = 'ns1.my.com';
        my $ip = '11:22.44.88';

        my %params2 = (
            ns => $ns,
            add => { ips => [ $ip ] },
            %login_params,
        );

        my ( $answ2, $msg2, undef ) = IO::EPP::Base::make_request( 'update_ns', \%params2 );

        is $answ2->{code}, 2004;

        is $msg2, "code: 2004\nmsg: IP address $ip is not valid.";

        my %params = (
            ns => $ns,
            add => { ips => [ '11.22.44.88' ] },
            %login_params,
        );

        my ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_ns', \%params );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";
    };

    it 'host:delete' => sub {
        my $ns1 = 'my.my.com';

        my %params1 = (
            ns => $ns1,
            %login_params,
        );

        my ( $answ1, $msg1, undef ) = IO::EPP::Base::make_request( 'delete_ns', \%params1 );

        is $answ1->{code}, 2303;

        is $msg1, "code: 2303\nmsg: The host &#039;$ns1&#039; does not exist";

        my %params = (
            ns => 'ns1.my.com',
            %login_params,
        );

        my ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'delete_ns', \%params );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";
    };

    it 'domain:check' => sub {
        # preordered data
        my $s = new IO::EPP::Test::Server( $sock_params{PeerHost} . ':' . $sock_params{PeerPort} );

        $s->data->{doms}{'xyz.xyz'} = { avail => 0, reason => 'in use' };
        $s->data->{doms}{'my.name'} = { avail => 1 };

        undef $s;

        my @domains = qw( fhej7fjd.site njenre.ru.com jkfwbd+weklr.bar xn--41aaa.xn--p1acf blond.art avaaaa.online xyz.xyz my.name dhfhf.com hjfnm.net hfreje.org njfrenme.info njrenme.ru djkfre.su kewbfrene.moscow );

        my %params = (
            domains => \@domains,
            %login_params,
        );

        my ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'check_domains', \%params );

        is $answ->{code}, 1000;

        foreach my $dm ( @domains ) {
            ok defined $answ->{$dm};
        }

        is $answ->{'jkfwbd+weklr.bar'}{avail}, 0;

        like $answ->{'jkfwbd+weklr.bar'}{reason}, qr/not permitted/;

        is $answ->{'blond.art'}{avail}, 0;

        is $answ->{'blond.art'}{reason}, 'blocked';

        is $answ->{'avaaaa.online'}{avail}, 1;

        is $answ->{'xyz.xyz'}{avail}, 0;

        is $answ->{'xyz.xyz'}{reason}, 'in use';

        is $answ->{'my.name'}{avail}, 1;

        is $msg, "code: 1000\nmsg: Command completed successfully.";
    };

    it 'domain:create' => sub {
        my $reg_id = 'TEST-r123';
        my $admin_id = 'TEST-a123';
        my $tech_id = 'TEST-t123';
        my $billing_id = 'TEST-b123';

        my %cont = (
            'int' => {
                first_name => 'Test',
                last_name => 'Testov',
                company => 'Private Person',
                addr => 'Vagnera 11-22-33',
                city => 'Donetsk',
                'state' => 'Donetskaya',
                postcode => '83000',
                country_code => 'UA',
            },
            phone => '+380.987654321',
            fax => '',
            email => 'test0101@ya.ru',
            authinfo => 'Q2+qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq',
        );

        my %dom = (
            dname      => 'mydom.xyz',
            reg_id     => $reg_id,
            admin_id   => $admin_id,
            tech_id    => $tech_id,
            billing_id => $billing_id,
            period     => 1,
            nss        => [ 'ns1.godaddy.com', 'ns2.godaddy.com' ],
            authinfo   => 'bfhRem884mfmf,FMd:fnnfe'
        );

        my %params1 = (
            %login_params,
            cont_id => $reg_id,
            %cont,
        );

        my ( $answ1, $msg1, $conn ) = IO::EPP::Base::make_request( 'create_contact', \%params1 );

        is $answ1->{code}, 1000;


        my %params2 = (
            conn => $conn,
            cont_id => $admin_id,
            %cont,
        );

        my ( $answ2, $msg2, undef ) = IO::EPP::Base::make_request( 'create_contact', \%params2 );

        is $answ2->{code}, 1000;


        my %params3 = (
            conn => $conn,
            cont_id => $tech_id,
            %cont,
        );

        my ( $answ3, $msg3, undef ) = IO::EPP::Base::make_request( 'create_contact', \%params3 );

        is $answ3->{code}, 1000;


        my %params4 = (
            conn => $conn,
            cont_id => $billing_id,
            %cont,
        );

        my ( $answ4, $msg4, undef ) = IO::EPP::Base::make_request( 'create_contact', \%params4 );

        is $answ4->{code}, 1000;


        my %params5 = (
            %dom,
            dname => 'my=dom.com',
            conn => $conn,
        );

        my ( $answ5, $msg5, undef ) = IO::EPP::Base::make_request( 'create_domain', \%params5 );

        is $answ5->{code}, 2004;

        is $msg5, "code: 2004\nmsg: &#039;my=dom.com&#039; is not a valid domain name: the following characters are not permitted: &#039;=&#039;";


        my %params6 = (
            %dom,
            dname => 'mydom.',
            conn => $conn,
        );

        my ( $answ6, $msg6, undef ) = IO::EPP::Base::make_request( 'create_domain', \%params6 );

        is $answ6->{code}, 2004;

        is $msg6, "code: 2004\nmsg: &#039;mydom.&#039; is not a valid domain name: suffix ... does not exist";


        my %params7 = (
            %dom,
            conn => $conn,
        );

        delete $params7{reg_id};

        my ( $answ7, $msg7, undef ) = IO::EPP::Base::make_request( 'create_domain', \%params7 );

        is $answ7->{code}, 2003;

        is $msg7, "code: 2003\nmsg: The &#039;registrant&#039; attribute is empty or missing";


        my %params8 = (
            %dom,
            conn => $conn,
        );

        $params8{reg_id} = 'qqqwwweee8';

        my ( $answ8, $msg8, undef ) = IO::EPP::Base::make_request( 'create_domain', \%params8 );

        is $answ8->{code}, 2303;

        is $msg8, "code: 2303\nmsg: Specified registrant contact qqqwwweee8 is not registered here.";


        my %params9 = (
            %dom,
            conn => $conn,
        );

        $params9{admin_id} = 'qqqwwweee9';

        my ( $answ9, $msg9, undef ) = IO::EPP::Base::make_request( 'create_domain', \%params9 );

        is $answ9->{code}, 2303;

        is $msg9, "code: 2303\nmsg: Specified admin contact qqqwwweee9 is not registered here.";


        my %params10 = (
            %dom,
            nss => [ 'ns1.qqqq.com' ],
            conn => $conn,
        );

        my ( $answ10, $msg10, undef ) = IO::EPP::Base::make_request( 'create_domain', \%params10 );

        is $answ10->{code}, 2303;

        is $msg10, "code: 2303\nmsg: Cannot find host object &#039;ns1.qqqq.com&#039;";


        my %params11 = (
            %dom,
            conn => $conn,
        );

        $params11{authinfo} = '1';

        my ( $answ11, $msg11, undef ) = IO::EPP::Base::make_request( 'create_domain', \%params11 );

        is $answ11->{code}, 2004;

        is $msg11, "code: 2004\nmsg: authInfo code is invalid: password must be at least 16 characters";


        my %params12 = (
            %dom,
            conn => $conn,
        );

        $params12{authinfo} = '1234567890abcdefghij';

        my ( $answ12, $msg12, undef ) = IO::EPP::Base::make_request( 'create_domain', \%params12 );

        is $answ12->{code}, 2004;

        is $msg12, "code: 2004\nmsg: authInfo code is invalid: password must contain a mix of uppercase and lowercase characters";


        my %params13 = (
            %dom,
            conn => $conn,
        );

        $params13{dname} = 'godaddy.com';

        my ( $answ13, $msg13, undef ) = IO::EPP::Base::make_request( 'create_domain', \%params13 );

        is $answ13->{code}, 2302;

        is $msg13, "code: 2302\nmsg: &#039;godaddy.com&#039; is already registered.";


        my %params = (
            %dom,
            conn => $conn,
        );

        my ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'create_domain', \%params );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";


        my %params50 = (
            %dom,
            dname => 'nssdom.best',
            nss => [ 'ns1.reg.com', 'ns2.reg.com' ],
            conn => $conn,
        );

        my ( $answ50, $msg50, undef ) = IO::EPP::Base::make_request( 'create_domain', \%params50 );

        is $answ50->{code}, 1000;

        is $msg50, "code: 1000\nmsg: Command completed successfully.";


        my %params51 = (
            ns => 'ns1.nssdom.best',
            conn => $conn,
        );

        my ( $answ51, $msg51, undef ) = IO::EPP::Base::make_request( 'create_ns', \%params51 );

        is $answ51->{code}, 2004;

        is $msg51, "code: 2004\nmsg: You need IPv4 or IPv6 address.";


        my %params52 = (
            ns => 'ns1.nssdom.best',
            ips => [ '11.22.33.44' ],
            conn => $conn,
        );

        my ( $answ52, $msg52, undef ) = IO::EPP::Base::make_request( 'create_ns', \%params52 );

        is $answ52->{code}, 1000;

        is $msg52, "code: 1000\nmsg: Command completed successfully.";

        is $answ52->{ns}, 'ns1.nssdom.best';


        my %params53 = (
            ns => 'ns2.nssdom.best',
            ips => [ '22.44.66.88' ],
            conn => $conn,
        );

        my ( $answ53, $msg53, undef ) = IO::EPP::Base::make_request( 'create_ns', \%params53 );

        is $answ53->{code}, 1000;

        is $msg53, "code: 1000\nmsg: Command completed successfully.";

        is $answ53->{ns}, 'ns2.nssdom.best';


        my %params99 = (
            %dom,
            conn => $conn,
        );

        my ( $answ99, $msg99, undef ) = IO::EPP::Base::make_request( 'create_domain', \%params99 );

        is $answ99->{code}, 2302;

        is $msg99, "code: 2302\nmsg: &#039;$dom{dname}&#039; is already registered.";
    };

    it 'domain:info' => sub {
        my %params = (
            %login_params,
            dname => 'mydom.xyz',
        );

        my ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'get_domain_info', \%params );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";

        is $answ->{reg_id}, 'TEST-r123';

        ok $answ->{statuses}{ok};


        my %params1 = (
            %login_params,
            dname => 'nssdom.best',
        );

        my ( $answ1, $msg1, undef ) = IO::EPP::Base::make_request( 'get_domain_info', \%params1 );

        is $answ1->{code}, 1000;

        is $msg1, "code: 1000\nmsg: Command completed successfully.";

        ok $answ1->{statuses}{ok};

        is $answ1->{hosts}[0], 'ns1.nssdom.best';


        my %params2 = (
            %login_params,
            dname => 'nssdom.com',
        );

        my ( $answ2, $msg2, undef ) = IO::EPP::Base::make_request( 'get_domain_info', \%params2 );

        is $answ2->{code}, 2303;

        is $msg2, "code: 2303\nmsg: The domain &#039;nssdom.com&#039; does not exist";
    };

    it 'domain:renew' => sub {
        my %params1 = (
            %login_params,
            dname => 'mydom.xyz',
            period => 100,
            exp_date => '2012-12-12',
        );

        my ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'renew_domain', \%params1 );

        is $answ->{code}, 2001;

        ok $msg =~ /XML schema validation failed: Element &#039;\{urn:ietf:params:xml:ns:domain-1.0\}period&#039;/;

        my %params2 = (
            %login_params,
            dname => 'mydom.xyz',
            period => 2,
            exp_date => '2018',
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'renew_domain', \%params2 );

        is $answ->{code}, 2001;

        ok $msg =~ /XML schema validation failed: Element &#039;\{urn:ietf:params:xml:ns:domain-1.0\}curExpDate&#039;/;


        my %params3 = (
            %login_params,
            dname => 'mydom.xyz',
            period => 2,
            exp_date => '2020-01-01',
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'renew_domain', \%params3 );

        is $answ->{code}, 2004;

        is $msg, "code: 2004\nmsg: Expiry date is not correct.";


        my $s = new IO::EPP::Test::Server( $sock_params{PeerHost} . ':' . $sock_params{PeerPort} );

        $s->data->{doms}{'mydom.xyz'}{statuses}{serverRenewProhibited} = '+';

        my %params4 = (
            %login_params,
            dname => 'mydom.xyz',
            period => 2,
            exp_date => '2020-01-01',
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'renew_domain', \%params4 );

        is $answ->{code}, 2304;

        is $msg, "code: 2304\nmsg: Domain cannot be renewed (serverRenewProhibited)";

        delete $s->data->{doms}{'mydom.xyz'}{statuses}{serverRenewProhibited};

        undef $s;


        my (undef,undef,undef,$mday,$mon,$year) = localtime(time);

        $year += 1900 + 1;
        $mon  += 1;

        my $exp_date = sprintf( '%0004d-%02d-%02d', $year,  $mon, $mday );

        my %params = (
            %login_params,
            dname => 'mydom.xyz',
            period => 2,
            exp_date => $exp_date,
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'renew_domain', \%params );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";

        my $new_exp_date = sprintf( '%0004d-%02d-%02d 23:59:59', $year+2,  $mon, $mday );

        is $answ->{exp_date}, $new_exp_date;
    };

    it 'domain:update' => sub {

        my %params0 = (
            %login_params,
            dname => 'mydoms.xyz',
            add => { statuses => [ 'clientUpdateProhibited' ] },
        );

        my ( $answ0, $msg0, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params0 );

        is $answ0->{code}, 2303;

        is $msg0, "code: 2303\nmsg: The domain &#039;mydoms.xyz&#039; does not exist";


        my $s = new IO::EPP::Test::Server( $sock_params{PeerHost} . ':' . $sock_params{PeerPort} );

        $s->data->{doms}{'mydom.xyz'}{statuses}{serverUpdateProhibited} = '+';

        my %params1 = (
            %login_params,
            dname => 'mydom.xyz',
            add => { statuses => [ 'clientUpdateProhibited' ] },
        );

        my ( $answ, $msg, $conn ) = IO::EPP::Base::make_request( 'update_domain', \%params1 );

        is $answ->{code}, 2304;

        is $msg, "code: 2304\nmsg: The domain name cannot be updated (serverUpdateProhibited).";


        delete $s->data->{doms}{'mydom.xyz'}{statuses}{serverUpdateProhibited};

        undef $s;

        my %params2 = (
            conn => $conn,
            dname => 'mydom.xyz',
            add => { statuses => [ 'clientUpdateProhibited' ] },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params2 );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";


        my %params3 = (
            conn => $conn,
            dname => 'mydom.xyz',
            add => { statuses => [ 'clientHold' ] },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params3 );

        is $answ->{code}, 2304;

        is $msg, "code: 2304\nmsg: The domain name cannot be updated (clientUpdateProhibited).";


        my %params4 = (
            conn => $conn,
            dname => 'mydom.xyz',
            rem => { statuses => [ 'clientUpdateProhibited' ] },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params4 );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";


        my %params5 = (
            conn => $conn,
            dname => 'mydom.xyz',
            add => { statuses => [ 'clientHoldd' ] },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params5 );

        is $answ->{code}, 2001;

        ok $msg =~ /XML schema validation failed: Element &#039;\{urn:ietf:params:xml:ns:domain-1.0\}status&#039;/;


        my %params6 = (
            conn => $conn,
            dname => 'mydom.xyz',
            add => { statuses => [ 'clientHold' ] },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params6 );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";



        my %params7 = (
            conn => $conn,
            dname => 'mydom.xyz',
            add => { statuses => [ 'clientHold' ] },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params7 );

        is $answ->{code}, 2004;

        is $msg, "code: 2004\nmsg: clientHold is already set on this domain.";


        my %cont = (
            'int' => {
                first_name => 'Test',
                last_name => 'Testov',
                company => 'Private Person',
                addr => 'Vagnera 11-22-33',
                city => 'Donetsk',
                'state' => 'Donetskaya',
                postcode => '83000',
                country_code => 'UA',
            },
            phone => '+380.987654321',
            fax => '',
            email => 'test0101@ya.ru',
            authinfo => 'Q2+qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq',
        );

        my %params8 = (
            %login_params,
            cont_id => 'UTEST-r123',
            %cont,
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'create_contact', \%params8 );

        is $answ->{code}, 1000;

        my %params9 = (
            %login_params,
            cont_id => 'UTEST-t123',
            %cont,
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'create_contact', \%params9 );

        is $answ->{code}, 1000;


        my %params10 = (
            conn => $conn,
            dname => 'mydom.xyz',
            chg => { reg_id => 'FAILTEST-r123' },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params10 );

        is $answ->{code}, 2303;

        is $msg, "code: 2303\nmsg: Contact FAILTEST-r123 does not exist, cannot change registrant.";


        my %params11 = (
            conn => $conn,
            dname => 'mydom.xyz',
            chg => { reg_id => 'UTEST-r123' },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params11 );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";


        my %params12 = (
            conn => $conn,
            dname => 'mydom.xyz',
            chg => { authinfo => '123' },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params12 );

        is $answ->{code}, 2004;

        is $msg, "code: 2004\nmsg: authInfo code is invalid: password must be at least 16 characters";


        my %params13 = (
            conn => $conn,
            dname => 'mydom.xyz',
            chg => { authinfo => '123qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq' },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params13 );

        is $answ->{code}, 2004;

        is $msg, "code: 2004\nmsg: authInfo code is invalid: password must contain a mix of uppercase and lowercase characters";


        my %params14 = (
            conn => $conn,
            dname => 'mydom.xyz',
            chg => { authinfo => '123+qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq=Q' },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params14 );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";


        my %params15 = (
            conn => $conn,
            dname => 'mydom.xyz',
            add => { tech_id => [ 'UTEST-t123' ] },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params15 );

        is $answ->{code}, 2004;

        is $msg, "code: 2004\nmsg: Cannot assign a new tech contact without removing current tech contact.";


        my %params16 = (
            conn => $conn,
            dname => 'mydom.xyz',
            rem => { tech_id => [ 'TEST-t123' ] },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params16 );

        is $answ->{code}, 2004;

        is $msg, "code: 2004\nmsg: Invalid contact association type &#039;tech&#039;";


        my %params17 = (
            conn => $conn,
            dname => 'mydom.xyz',
            add => { tech_id => [ 'UTEST-t123' ] },
            rem => { tech_id => [ 'TEST-t123' ] },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params17 );

        is $answ->{code}, 1000;


        my %params18 = (
            conn => $conn,
            dname => 'mydom.xyz',
            add => { nss => [ 'ns1.qqq.ru' ] },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params18 );

        is $answ->{code}, 2303;

        is $msg, "code: 2303\nmsg: Cannot find host object &#039;ns1.qqq.ru&#039;";


        my %params19 = (
            conn => $conn,
            dname => 'mydom.xyz',
            rem => { nss => [ 'ns1.qqq.ru' ] },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params19 );

        is $answ->{code}, 2303;

        is $msg, "code: 2303\nmsg: The host ns1.qqq.ru is not linked to this domain name.";


        my %params20 = (
            conn => $conn,
            dname => 'mydom.xyz',
            add => { nss => [ 'ns1.nssdom.best' ] },
            rem => { nss => [ 'ns1.nssdom.best' ] },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params20 );

        is $answ->{code}, 1000;


        my %params21 = (
            conn => $conn,
            dname => 'mydom.xyz',
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'get_domain_info', \%params21 );

        is $answ->{code}, 1000;

        is grep( /^ns1\.nssdom\.best$/, @{$answ->{nss}} ), 0;


        my %params22 = (
            conn => $conn,
            dname => 'mydom.xyz',
            add => { nss => [ 'ns1.nssdom.best' ] },
            rem => { nss => [ 'ns2.godaddy.com' ] },
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'update_domain', \%params22 );

        is $answ->{code}, 1000;
    };

    it 'domain:delete' => sub {
        my %params1 = (
            %login_params,
            dname => 'fhjddsjk.xyz',
        );

        my ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'delete_domain', \%params1 );

        is $answ->{code}, 2303;

        is $msg, "code: 2303\nmsg: The domain &#039;fhjddsjk.xyz&#039; does not exist";


        my %params2 = (
            %login_params,
            dname => 'blond.art',
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'delete_domain', \%params2 );

        is $answ->{code}, 2303;

        is $msg, "code: 2303\nmsg: The domain &#039;blond.art&#039; does not exist";


        my %params3 = (
            %login_params,
            dname => 'nssdom.best',
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'delete_domain', \%params3 );

        is $answ->{code}, 2305;

        is $msg, "code: 2305\nmsg: Domain host ns1.nssdom.best is linked to one or more domains.";


        my %params4 = (
            %login_params,
            dname => 'mydom.xyz',
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'delete_domain', \%params4 );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";
    };

    it 'transfer' => sub {
        my %params1 = (
            %login_params,
            op => 'request',
            dname => 'hjhhgjhk.xyz',
            period => 1,
        );

        my ( $answ, $msg, $conn ) = IO::EPP::Base::make_request( 'transfer', \%params1 );

        is $answ->{code}, 2303;

        is $msg, "code: 2303\nmsg: The domain &#039;hjhhgjhk.xyz&#039; cannot be found.";


        my %params2 = (
            conn => $conn,
            op => 'request',
            dname => 'nssdom.best',
            period => 1,
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'transfer', \%params2 );

        is $answ->{code}, 2304;

        is $msg, "code: 2304\nmsg: You are already the sponsor for this domain";


        my %params3 = (
            conn => $conn,
            op => 'cancel',
            dname => 'nssdom.best',
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'transfer', \%params3 );

        is $answ->{code}, 2301;

        is $msg, "code: 2301\nmsg: There are no pending transfer requests for this object.";


        my $s = new IO::EPP::Test::Server( $sock_params{PeerHost} . ':' . $sock_params{PeerPort} );

        $s->data->{doms}{'nssdom.best'}{owner} = 'daddy';
        my $authinfo = $s->data->{doms}{'nssdom.best'}{authInfo};

        undef $s;


        my %params4 = (
            conn => $conn,
            op => 'request',
            dname => 'nssdom.best',
            period => 1,
            authinfo => 'qqqq',
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'transfer', \%params4 );

        is $answ->{code}, 2202;

        is $msg, "code: 2202\nmsg: Invalid authorisation code.";


        my %params5 = (
            conn => $conn,
            op => 'request',
            dname => 'nssdom.best',
            period => 1,
            authinfo => $authinfo,
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'transfer', \%params5 );

        is $answ->{code}, 1001;

        is $msg, "code: 1001\nmsg: Command completed OK; action pending";


        my %params6 = (
            conn => $conn,
            op => 'query',
            dname => 'nssdom.best',
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'transfer', \%params6 );

        is $answ->{code}, 1000;

        is $answ->{trstatus}, "pending";


        my %params7 = (
            conn => $conn,
            op => 'cancel',
            dname => 'nssdom.best',
        );

        ( $answ, $msg, undef ) = IO::EPP::Base::make_request( 'transfer', \%params7 );

        is $answ->{code}, 1000;

        is $msg, "code: 1000\nmsg: Command completed successfully.";
    };

    it 'poll' => sub {
        my %params1 = (
            %login_params,
        );

        my ( $answ, $msg, $conn ) = IO::EPP::Base::make_request( 'req_poll', \%params1 );

        is $answ->{code}, 1300;

        is $msg, "code: 1300\nmsg: There are no messages for you!";
    };
};

runtests unless caller;
