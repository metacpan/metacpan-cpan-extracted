#!/usr/bin/perl

=encoding utf8

=head1 NAME

CoCCA.t

=head1 DESCRIPTION

Tests for IO::EPP::Verisign module using Verisign Core server emulation

Other test: https://epptool-ctld.verisign-grs.com/epptool/
or
OTE API: epp-ote.verisign-grs.com:700

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=cut

use Test::Spec;

use strict;
use warnings;

use lib '../lib';

use IO::EPP::Test::Server;

no utf8; # !!!

my %sock_params = (
    PeerHost      => 'epp-ote.verisign.com',
    PeerPort      => 700,
    SSL_key_file  => 'key.pm',
    SSL_cert_file => 'cert.pm',
    Timeout       => 30,
    debug         => 1,
);

my %login_params = (
    sock_params => \%sock_params,
    user        => 'test',
    pass        => 'test123',
    server      => 'Core',
    no_log      => 1,

    test_mode   => 1,
);


use_ok( 'IO::EPP::Verisign' );

describe 'IO::EPP::Verisign::' => sub {
    it 'login, hello, logout, connect as object' => sub {
        my %params = (
            %login_params,
        );

        my $conn = IO::EPP::Verisign->new( \%params );

        is $conn->{user}, 'test';

        ok $conn->{sock};

        ok $conn->{namestore_ext};

        my ( $answ, $code, $msg ) = $conn->hello();

        is $code, 1000;

        like $msg, qr/<greeting>/;

        my ( $answ2, $code2, $msg2 ) = $conn->logout();

        ok !$answ2;

        is $code2, 1500;

        is $msg2, 'ok';
    };

    it 'check_nss' => sub {
        my %params1 = (
            %login_params,
            nss => [ 'ns1.jjj.com', 'ns1.cjkebvhe.com', 'ns1.qq+ww.com', 'ns1.cbhje.jkre7gmf', '---' ],
        );

        my ( $answ, $msg, undef ) = IO::EPP::Verisign::make_request( 'check_nss', \%params1 );

        is $answ->{'ns1.jjj.com'}{avail}, 1;

        is $answ->{'ns1.cjkebvhe.com'}{avail}, 1;

        is $answ->{'ns1.qq+ww.com'}{avail}, 0;

        is $answ->{'ns1.cbhje.jkre7gmf'}{avail}, 1;

        is $answ->{'---'}{avail}, 0;

        is $msg, "code: 1000\nmsg: Command completed successfully";
    };

    it 'create_ns' => sub {
        my $s = new IO::EPP::Test::Server( $sock_params{PeerHost} . ':' . $sock_params{PeerPort} );

        $s->data->{doms}{'godaddy.com'} = { avail => 0, reason => 'in use', owner => 'daddy', 'cre_date' => '1999-03-02T05:00:00Z', 'exp_date' => '2999-03-02T05:00:00Z' };
        $s->data->{nss}{'ns1.godaddy.com'} = { avail => 0, reason => 'in use', owner => 'daddy' };
        $s->data->{nss}{'ns2.godaddy.com'} = { avail => 0, reason => 'in use', owner => 'daddy' };

        $s->data->{doms}{'reg.com'} = { avail => 0, reason => 'in use', owner => 'regru', 'cre_date' => '1997-08-01T04:00:00Z', 'tr_date' => '2014-11-06T05:19:10Z', 'exp_date' => '2997-08-01T04:00:00Z' };
        $s->data->{nss}{'ns1.reg.com'} = { avail => 0, reason => 'in use', owner => 'regru' };
        $s->data->{nss}{'ns2.reg.com'} = { avail => 0, reason => 'in use', owner => 'regru' };
        $s->data->{nss}{'ns1.reg.ru'} = { avail => 0, reason => 'in use', owner => 'regru' };
        $s->data->{nss}{'ns2.reg.ru'} = { avail => 0, reason => 'in use', owner => 'regru' };

        $s->data->{doms}{'my.com'} = { avail => 0, reason => 'in use', owner => $login_params{user} };

        undef $s;

        my %params1 = (
            %login_params,
            ns => 'ns222.bjfr+ebkjfre.google',
        );

        my ( $answ, $msg, $conn ) = IO::EPP::Verisign::make_request( 'create_ns', \%params1 );

        ok ref $conn;

        is $answ->{code}, '2005';

        is $msg, "code: 2005\nmsg: Parameter value syntax error";


        my %params2 = (
            conn => $conn,
            ns => 'ns1.reg.com',
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'create_ns', \%params2 );

        is $answ->{code}, '2201';

        is $msg, "code: 2201\nmsg: Authorization error";


        my %params3 = (
            conn => $conn,
            ns => 'ns1.jjjj.com',
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'create_ns', \%params3 );

        is $answ->{code}, '2305';

        is $msg, "code: 2305\nmsg: Object association prohibits operation";


        my %params4 = (
            conn => $conn,
            ns => 'ns1.my.com',
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'create_ns', \%params4 );

        is $answ->{code}, '2003';

        is $msg, "code: 2003\nmsg: Required parameter missing";


        my %params5 = (
            conn => $conn,
            ns => 'ns1.my.com',
            ips => [ 'hjrnrr:099kl-nfke' ]
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'create_ns', \%params5 );

        is $answ->{code}, '2005';

        is $msg, "code: 2005\nmsg: Parameter value syntax error";


        my %params6 = (
            conn => $conn,
            ns => 'ns1.my.ru',
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'create_ns', \%params6 );

        is $answ->{code}, '1000';

        is $msg, "code: 1000\nmsg: Command completed successfully";


        my %params7 = (
            conn => $conn,
            ns => 'ns1.my.com',
            ips => [ '1.2.3.4', 'aaaa:0000:bbbb::9999' ]
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'create_ns', \%params7 );

        is $answ->{code}, '1000';

        is $msg, "code: 1000\nmsg: Command completed successfully";

        my %params8 = (
            conn => $conn,
            ns => 'ns1.my.com',
            ips => [ '1.2.3.4', 'aaaa:0000:bbbb::9999' ]
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'create_ns', \%params8 );

        is $answ->{code}, '2302';

        is $msg, "code: 2302\nmsg: Object exists";
    };

    it 'get_ns_info' => sub {
        my %params = (
            %login_params,
        );

        my $conn = IO::EPP::Verisign->new( \%params );

        my ( $answ, $code, $msg ) = $conn->get_ns_info( { ns => 'ns.qqq.qwe' } );

        is $code, 2303;

        is $msg, "Object does not exist";

        ( $answ, $code, $msg ) = $conn->get_ns_info( { ns => 'ns.*.qwe' } );

        is $code, 2005;

        is $msg, 'Parameter value syntax error';

        ( $answ, $code, $msg ) = $conn->get_ns_info( { ns => 'ns1.godaddy.com' } );

        is $code, 2201;

        is $msg, 'Authorization error';

        ( $answ, $code, $msg ) = $conn->get_ns_info( { ns => 'ns1.my.com' } );

        is $code, 1000;

        is $msg, 'Command completed successfully';

        is $answ->{owner}, $login_params{user};

        is $answ->{name}, 'ns1.my.com';

        is $answ->{statuses}{ok}, '+';

        is $answ->{statuses}{linked}, undef;

        is scalar( @{$answ->{addrs}} ), 2;
    };

    it 'update_ns' => sub {
        my %params = (
            %login_params,
        );

        my $conn = IO::EPP::Verisign->new( \%params );

        my ( $answ, $code, $msg ) = $conn->update_ns( { ns => 'ns.qqq.qwe', add => { ips => [ '1.2.3.4' ] } } );

        is $code, 2303;

        is $msg, 'Object does not exist';

        ( $answ, $code, $msg ) = $conn->update_ns( { ns => 'ns1.godaddy.com', add => { ips => [ '1.2.3.4' ] } } );

        is $code, 2201;

        is $msg, 'Authorization error';

        ( $answ, $code, $msg ) = $conn->update_ns( { ns => 'ns1.my.com', add => { ips => [ '1,2.3.4' ] } } );

        is $code, 2005;

        is $msg, 'Parameter value syntax error';

        ( $answ, $code, $msg ) = $conn->update_ns( { ns => 'ns1.my.com', add => { ips => [ '1.2.3.4' ] } } );

        is $code, 2306;

        is $msg, 'Parameter value policy error; 1.2.3.4 addr is already associated';

        ( $answ, $code, $msg ) = $conn->update_ns( { ns => 'ns1.my.com', rem => { ips => [ '1.2.3.4', 'aaaa:0000:bbbb::9999' ] } } );

        is $code, 2003;

        is $msg, 'Required parameter missing';

        ( $answ, $code, $msg ) = $conn->update_ns( { ns => 'ns1.my.com', rem => { ips => [ '1.2.3.8' ] } } );

        is $code, 2306;

        is $msg, 'Parameter value policy error; 1.2.3.8 addr not found';

        ( $answ, $code, $msg ) = $conn->update_ns( { ns => 'ns1.my.com', rem => { ips => [ '1.2.3.4' ] }, add => { ips => [ '1.2.3.8' ] } } );

        is $code, 1000;

        is $msg, 'Command completed successfully';

        ( $answ, $code, $msg ) = $conn->update_ns( { ns => 'ns1.my.com', add => { statuses => [ 'clientRenewProhibited' ] } } );

        is $code, 2001;

        ok $msg =~ /Command syntax error/;

        ( $answ, $code, $msg ) = $conn->update_ns( { ns => 'ns1.my.com', add => { statuses => [ 'pendingCreate' ] } } );

        is $code, 2306;

        is $msg, 'Parameter value policy error; request contains no actual object updates';

        ( $answ, $code, $msg ) = $conn->update_ns( { ns => 'ns1.my.com', add => { statuses => [ 'clientDeleteProhibited' ] } } );

        is $code, 1000;

        is $msg, 'Command completed successfully';

        ( $answ, $code, $msg ) = $conn->update_ns( { ns => 'ns1.my.com', add => { statuses => [ 'clientDeleteProhibited' ] } } );

        is $code, 2306;

        is $msg, 'Parameter value policy error; clientDeleteProhibited status is already associated';

        ( $answ, $code, $msg ) = $conn->update_ns( { ns => 'ns1.my.com', rem => { statuses => [ 'clientDeleteProhibited' ] } } );

        is $code, 1000;

        is $msg, 'Command completed successfully';

        ( $answ, $code, $msg ) = $conn->update_ns( { ns => 'ns1.my.com', rem => { statuses => [ 'clientDeleteProhibited' ] } } );

        is $code, 2306;

        is $msg, 'Parameter value policy error; clientDeleteProhibited status not found';
    };

    it 'delete_ns' => sub {
        my %params = (
            %login_params,
        );

        my $conn = IO::EPP::Verisign->new( \%params );

        my ( $answ, $code, $msg ) = $conn->delete_ns( { ns => 'ns.qqq.qwe' } );

        is $code, 2303;

        is $msg, "Object does not exist";

        ( $answ, $code, $msg ) = $conn->delete_ns( { ns => 'ns1.godaddy.com' } );

        is $code, 2201;

        is $msg, 'Authorization error';

        # !!! DOTO delete with linked

        ( $answ, $code, $msg ) = $conn->delete_ns( { ns => 'ns1.my.com' } );

        is $code, 1000;

        is $msg, 'Command completed successfully';
    };

    it 'check_domains' => sub {
        my @domains = qw( fhej7fjd.com njenre.net jkfwbdweklr.site xn--41aaa.com fbehjferw.edu jkrem+fre.com );

        my %params = (
            %login_params,
            tld => 'com',
            domains => \@domains,
        );

        my ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'check_domains', \%params );

        is $answ->{code}, 1000;

        ok $answ->{'fhej7fjd.com'};

        ok $answ->{'njenre.net'};

        is $answ->{'jkfwbdweklr.site'}{avail}, 0;

        is $answ->{'jkfwbdweklr.site'}{reason}, 'Not an authoritative TLD';

        ok defined $answ->{'xn--41aaa.com'}{avail};

        ok defined $answ->{'fbehjferw.edu'}{avail};

        is $answ->{'jkrem+fre.com'}{avail}, 0;

        is $answ->{'jkrem+fre.com'}{reason}, 'Invalid Domain Name';

        is $msg, "code: 1000\nmsg: Command completed successfully";
    };

    it 'create_domain' => sub {
        my %params = (
            %login_params,
        );

        my $conn = IO::EPP::Verisign->new( \%params );

        my ( $answ, $code, $msg ) = $conn->create_domain( { tld => 'com', dname => 'qwe+rty.com', period => 1, nss => [] } );

        is $code, 2005;

        is $msg, 'Parameter value syntax error; Domain name contains an invalid DNS character';

        ( $answ, $code, $msg ) = $conn->create_domain( { tld => 'com', dname => 'qwerty.net', period => 1 } );

        is $code, 2306;

        is $msg, 'Parameter value syntax error; Subproduct ID does not match the domain TLD';

        ( $answ, $code, $msg ) = $conn->create_domain( { tld => 'com', dname => 'qwerty.site', period => 1 } );

        is $code, 2306;

        is $msg, 'Parameter value syntax error; Subproduct ID does not match the domain TLD';

        ( $answ, $code, $msg ) = $conn->create_domain( { tld => 'com', dname => 'xn--qwerty.com', period => 1 } );

        is $code, 2003;

        is $msg, 'Required parameter missing; Language Extension required for IDN label domain names.';

        ( $answ, $code, $msg ) = $conn->create_domain( { tld => 'com', dname => 'qwerty.com', period => 1, authinfo => 'aaabbbcccdddeeefff' } );

        is $code, 2306;

        is $msg, 'Parameter value policy error; Invalid Auth Info';

        ( $answ, $code, $msg ) = $conn->create_domain( { tld => 'com', dname => 'qwerty.com', period => 11 } );

        is $code, 2306;

        is $msg, 'Parameter value policy error';

        ( $answ, $code, $msg ) = $conn->create_domain( { tld => 'com', dname => 'qwerty.com', period => 1, nss => [ 'ns.abc', 'ns1.godaddy.com' ] } );

        is $code, 2303;

        is $msg, 'Object does not exist; ns ns.abc does not exist';

        ( $answ, $code, $msg ) = $conn->create_domain( { tld => 'com', dname => 'godaddy.com', period => 1 } );

        is $code, 2302;

        is $msg, 'Object exists';

        ( $answ, $code, $msg ) = $conn->create_domain( { tld => 'com', dname => 'asdfgh.com', period => 1, nss => [ 'ns1.my.ru', 'ns1.reg.com' ] } );

        is $code, 1000;

        is $msg, 'Command completed successfully';

        ok ref $answ;

        is $answ->{dname}, 'asdfgh.com';
    };

    it 'get_domain_info' => sub {
        my %params = (
            %login_params,
        );

        my $conn = IO::EPP::Verisign->new( \%params );

        my ( $answ, $code, $msg ) = $conn->get_domain_info( { tld => 'com', dname => 'qwe+rty.com' } );

        is $code, 2005;

        is $msg, 'Parameter value syntax error; Domain name contains an invalid DNS character';

        ( $answ, $code, $msg ) = $conn->get_domain_info( { tld => 'com', dname => 'qwerty.net' } );

        is $code, 2306;

        is $msg, 'Parameter value syntax error; Incorrect NameStore Extension';

        ( $answ, $code, $msg ) = $conn->get_domain_info( { tld => 'com', dname => 'jfrkekve8fmfmfnkle.com' } );

        is $code, 2303;

        is $msg, 'Object does not exist';

        ( $answ, $code, $msg ) = $conn->get_domain_info( { tld => 'com', dname => 'asdfgh.com' } );

        is $code, 1000;

        is $msg, 'Command completed successfully';

        ok $answ->{authinfo};

        is $answ->{creater}, $login_params{user};

        is $answ->{owner}, $login_params{user};

        ok $answ->{cre_date} eq $answ->{upd_date};

        ok $answ->{statuses}{ok};

        ok $answ->{statuses}{addPeriod};
    };

    it 'renew_domain' => sub {
        my %params = (
            %login_params,
        );

        my $conn = IO::EPP::Verisign->new( \%params );

        my ( $answ, $code, $msg ) = $conn->renew_domain( { tld => 'com', dname => 'qwe+rty.com', period => 1, exp_date => '2000-20-20' } );

        is $code, 2005;

        is $msg, 'Parameter value syntax error';

        ( $answ, $code, $msg ) = $conn->renew_domain( { tld => 'com', dname => 'qwerty.com', period => 1, exp_date => '2000-20-20' } );

        is $code, 2001;

        is $msg, q|Command syntax error; XML Schema Validation Error: Line: 7, Column: 54, Message: cvc-datatype-valid.1.2.1: '2000-20-20' is not a valid value for 'date'.|;

        ( $answ, $code, $msg ) = $conn->renew_domain( { tld => 'com', dname => 'qwerty.com', period => 11, exp_date => '2020-12-12' } );

        is $code, 2306;

        is $msg, 'Parameter value policy error';

        ( $answ, $code, $msg ) = $conn->renew_domain( { tld => 'com', dname => 'asdfgh.com', period => 2, exp_date => '2020-12-12' } );

        is $code, 2004;

        is $msg, 'Wrong curExpDate provided';

        ( $answ, $code, $msg ) = $conn->get_domain_info( { tld => 'com', dname => 'asdfgh.com' } );

        is $code, 1000;

        ok !$answ->{statuses}{renewPeriod};

        my ( $exp_date ) = $answ->{exp_date} =~ /^(\d{4}-\d{2}-\d{2})/;

        ( $answ, $code, $msg ) = $conn->renew_domain( { tld => 'com', dname => 'asdfgh.com', period => 2, exp_date => $exp_date } );

        is $code, 1000;

        is $msg, 'Command completed successfully';

        ok $answ->{exp_date};

        ( $answ, $code, $msg ) = $conn->get_domain_info( { tld => 'com', dname => 'asdfgh.com' } );

        is $code, 1000;

        ok $answ->{statuses}{renewPeriod};

        ( $exp_date ) = $answ->{exp_date} =~ /^(\d{4}-\d{2}-\d{2})/;

        ( $answ, $code, $msg ) = $conn->renew_domain( { tld => 'com', dname => 'asdfgh.com', period => 2, exp_date => $exp_date } );

        is $code, 2004;

        is $msg, 'Domain in renewPeriod';
    };

    it 'update_domain' => sub {
        my %params = (
            %login_params,
            tld => 'com',
            dname => 'qwe+rty.com',
            add => { nss => [ 'ns1.qqqq.qq' ] }
        );

        my ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'update_domain', \%params );

        is $answ->{code}, 2005;

        is $msg, "code: 2005\nmsg: Parameter value syntax error";

        my %params2 = (
            %login_params,
            tld => 'com',
            dname => 'qwerty.name',
            add => { nss => [ 'ns1.qqqq.qq' ] }
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'update_domain', \%params2 );

        is $answ->{code}, 2306;

        is $msg, "code: 2306\nmsg: Parameter value syntax error; Domainname is invalid";

        my %params3 = (
            %login_params,
            tld => 'com',
            dname => 'qwerty.com',
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'update_domain', \%params3 );

        is $answ->{code}, 2003;

        is $msg, "code: 2003\nmsg: Required parameter missing; empty non-extended update is not allowed";

        my %params4 = (
            %login_params,
            tld => 'com',
            dname => 'qwerty.com',
            add => { nss => [ 'ns1.qqqq.qq' ] }
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'update_domain', \%params4 );

        is $answ->{code}, 2303;

        is $msg, "code: 2303\nmsg: Object does not exist";

        my %params5 = (
            %login_params,
            tld => 'com',
            dname => 'asdfgh.com',
            add => { nss => [ 'ns1.qqqq.qq' ] }
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'update_domain', \%params5 );

        is $answ->{code}, 2303;

        is $msg, "code: 2303\nmsg: Object does not exist; host ns1.qqqq.qq not found.";

        my %params6 = (
            %login_params,
            tld => 'com',
            dname => 'asdfgh.com',
            rem => { nss => [ 'ns1.reg.ru' ] }
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'update_domain', \%params6 );

        is $answ->{code}, 2306;

        is $msg, "code: 2306\nmsg: Parameter value policy error; ns1.reg.ru ns not found";

        my %params7 = (
            %login_params,
            tld => 'com',
            dname => 'asdfgh.com',
            add => { nss => [ 'ns1.reg.ru' ] },
            rem => { nss => [ 'ns1.reg.com' ] },
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'update_domain', \%params7 );

        is $answ->{code}, 1000;

        my %params8 = (
            %login_params,
            tld => 'com',
            dname => 'asdfgh.com',
            add => { statuses => { 'clientXXX' => 'qqq' } }
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'update_domain', \%params8 );

        is $answ->{code}, 2001; # fail Schema

        my %params9 = (
            %login_params,
            tld => 'com',
            dname => 'asdfgh.com',
            add => { statuses => { 'clientUpdateProhibited' => 'qqq' } },
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'update_domain', \%params9 );

        is $answ->{code}, 1000;

        my %params10 = (
            %login_params,
            tld => 'com',
            dname => 'asdfgh.com',
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'get_domain_info', \%params10 );

        is $answ->{code}, 1000;

        is $answ->{statuses}{clientUpdateProhibited}, '+'; # !!! not 'qqq' - verising does not give the reason

        ok !$answ->{statuses}{ok};

        ok $answ->{statuses}{addPeriod};

        ok $answ->{statuses}{renewPeriod};

        is $answ->{nss}[1], 'ns1.reg.ru'; # [ 'ns1.my.ru', 'ns1.reg.ru' ]

        my %params11 = (
            %login_params,
            tld => 'com',
            dname => 'asdfgh.com',
            add => { statuses => [ 'clientHold' ] },
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'update_domain', \%params11 );

        is $answ->{code}, 2304;

        is $msg, "code: 2304\nmsg: Object status prohibits operation";

        my %params12 = (
            %login_params,
            tld => 'com',
            dname => 'asdfgh.com',
            rem => { statuses => [ 'clientUpdateProhibited' ] },
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'update_domain', \%params12 );

        is $answ->{code}, 1000;

        my %params13 = (
            %login_params,
            tld => 'com',
            dname => 'asdfgh.com',
            chg => { authinfo => 'Qq+1' },
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'update_domain', \%params13 );

        is $answ->{code}, 2306;

        is $msg, "code: 2306\nmsg: Parameter value policy error; Invalid Auth Info";

        my %params14 = (
            %login_params,
            tld => 'com',
            dname => 'asdfgh.com',
            chg => { authinfo => 'QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ1' },
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'update_domain', \%params14 );

        is $answ->{code}, 2306;

        is $msg, "code: 2306\nmsg: Parameter value policy error; Invalid Auth Info";

        my %params15 = (
            %login_params,
            tld => 'com',
            dname => 'asdfgh.com',
            chg => { authinfo => 'QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQq+1' },
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'update_domain', \%params15 );

        is $answ->{code}, 1000;

        my %params16 = (
            %login_params,
            tld => 'com',
            dname => 'asdfgh.com',
            chg => { reg_id => 'fhjfre7men7nd' },
        );

        ( $answ, $msg ) = IO::EPP::Verisign::make_request( 'update_domain', \%params16 );

        is $answ->{code}, 2102;

        is $msg, "code: 2102\nmsg: Unimplemented option; Subproduct dotCOM does NOT support contacts.";
    };

    it 'delete_domain' => sub {
        my %params = (
            %login_params,
        );

        my $conn = IO::EPP::Verisign->new( \%params );

        my ( $answ, $code, $msg ) = $conn->delete_domain( { dname => 'qwe+rty.com' } );

        is $code, 2005;

        is $msg, 'Parameter value syntax error';

        ( $answ, $code, $msg ) = $conn->delete_domain( { dname => 'qwerty.com' } );

        is $code, 2303;

        is $msg, 'Object does not exist';

        ( $answ, $code, $msg ) = $conn->delete_domain( { dname => 'godaddy.com' } );

        is $code, 2201;

        is $msg, 'Authorization error';

        ( $answ, $code, $msg ) = $conn->create_ns( { ns => 'ns.asdfgh.com', ips => ['1.2.3.4'] } );

        is $code, 1000;

        ( $answ, $code, $msg ) = $conn->update_domain( { dname => 'asdfgh.com', add => { nss => [ 'ns.asdfgh.com' ] } } );

        is $code, 1000;

        ( $answ, $code, $msg ) = $conn->delete_domain( { dname => 'asdfgh.com' } );

        is $code, 2305;

        is $msg, 'Object association prohibits operation; domain has an active child host';

        ( $answ, $code, $msg ) = $conn->update_domain( { dname => 'asdfgh.com', rem => { nss => [ 'ns.asdfgh.com' ] } } );

        is $code, 1000;

        ( $answ, $code, $msg ) = $conn->delete_domain( { dname => 'asdfgh.com' } );

        is $code, 1000;

        ( $answ, $code, $msg ) = $conn->get_domain_info( { dname => 'asdfgh.com' } );

        is $code, 1000;

        ok $answ->{statuses}{pendingDelete};

        ( $answ, $code, $msg ) = $conn->delete_domain( { dname => 'asdfgh.com' } );

        is $code, 2304;

        is $msg, 'Object status prohibits operation';
    };

    it 'restore_domain' => sub {
        my %params = (
            %login_params,
        );

        my $conn = IO::EPP::Verisign->new( \%params );

        my ( $answ, $code, $msg ) = $conn->restore_domain( { dname => 'asdfgh.com' } );

        is $code, 1000;

        ( $answ, $code, $msg ) = $conn->get_domain_info( { dname => 'asdfgh.com' } );

        is $code, 1000;

        ok $answ->{statuses}{pendingRestore};

        ( $answ, $code, $msg ) = $conn->confirmations_restore_domain( { dname => 'asdfgh.com', del_time => $answ->{'upd_date'}, rest_time => $answ->{'upd_date'} } );

        is $code, 1000;

        ( $answ, $code, $msg ) = $conn->get_domain_info( { dname => 'asdfgh.com' } );

        is $code, 1000;

        ok !$answ->{statuses}{pendingDelete};

        ok !$answ->{statuses}{pendingRestore};
    }

};

runtests unless caller;
