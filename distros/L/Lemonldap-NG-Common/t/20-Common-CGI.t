# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Manager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
package My::Portal;

use strict;
use Test::More tests => 25;
use_ok('Lemonldap::NG::Common::CGI');

#our @ISA = qw('Lemonldap::NG::Common::CGI');
use base 'Lemonldap::NG::Common::CGI';

sub mySubtest {
    return 'OK1';
}

sub abort {
    shift;
    $, = '';
    print STDERR @_;
    die 'abort has been called';
}

sub quit {
    2;
}

our $param;

sub param {
    return $param;
}

sub soapfunc {
    return 'SoapOK';
}

our $buf;
our $lastpos = 0;

sub diff {
    my $str = $buf;
    $str =~ s/^.{$lastpos}//s if ($lastpos);
    $str =~ s/\r//gs;
    $lastpos = length $buf;
    return $str;
}

SKIP: {
    eval "use IO::String;";
    skip "IO::String not installed", 9 if ($@);
    tie *STDOUT, 'IO::String', $buf;

#########################

    # Insert your test code below, the Test::More module is use()ed here so read
    # its man page ( perldoc Test::More ) for help writing this test script.

    my $cgi;

    $ENV{SCRIPT_NAME}     = '/test.pl';
    $ENV{SCRIPT_FILENAME} = 't/20-Common-CGI.t';
    $ENV{REQUEST_METHOD}  = 'GET';
    $ENV{REQUEST_URI}     = '/';
    $ENV{QUERY_STRING}    = '';

    #$cgi = CGI->new;
    ok( ( $cgi = Lemonldap::NG::Common::CGI->new() ), 'New CGI' );
    bless $cgi, 'My::Portal';

    # Test header_public
    ok( $buf = $cgi->header_public('t/20-Common-CGI.t'), 'header_public' );
    ok( $buf =~ /Cache-control: public; must-revalidate; max-age=\d+\r?\n/s,
        'Cache-Control' );
    ok( $buf =~ /Last-modified: /s, 'Last-Modified' );

    # Test _sub mechanism
    ok( $cgi->_sub('mySubtest') eq 'OK1', '_sub mechanism 1' );
    $cgi->{mySubtest} = sub { return 'OK2' };
    ok( $cgi->_sub('mySubtest') eq 'OK2', '_sub mechanism 2' );

    # Test extract_lang
    my $lang;
    ok( $lang = $cgi->extract_lang(),
        'extract_lang 0 with void "Accept-language"' );
    ok( scalar(@$lang) == 0, 'extract_lang 1 with void "Accept-language"' );

    my $cgi2;
    $ENV{SCRIPT_NAME}          = '/test.pl';
    $ENV{SCRIPT_FILENAME}      = 't/20-Common-CGI.t';
    $ENV{REQUEST_METHOD}       = 'GET';
    $ENV{REQUEST_URI}          = '/';
    $ENV{QUERY_STRING}         = '';
    $ENV{HTTP_ACCEPT_LANGUAGE} = 'fr,fr-fr;q=0.8,en-us;q=0.5,en;q=0.3';
    ok( ( $cgi2 = Lemonldap::NG::Common::CGI->new() ), 'New CGI' );
    ok( $lang = $cgi2->extract_lang(), 'extract_lang' );
    ok( $lang->[0] eq 'fr',  'extract_lang' );
    ok( $lang->[1] eq 'en',  'extract_lang' );
    ok( scalar(@$lang) == 2, 'extract_lang' );

    # Extract lang Android (See #LEMONLDAP-530)
    my $cgi3;
    $ENV{HTTP_ACCEPT_LANGUAGE} = 'fr-FR, en-US';
    ok( ( $cgi3 = Lemonldap::NG::Common::CGI->new() ), 'New CGI' );
    ok( $lang = $cgi3->extract_lang(), 'extract_lang Android' );
    ok( $lang->[0] eq 'fr',  'extract_lang Android' );
    ok( $lang->[1] eq 'en',  'extract_lang Android' );
    ok( scalar(@$lang) == 2, 'extract_lang Android' );

    # Extract lang with * value
    my $cgi4;
    $ENV{HTTP_ACCEPT_LANGUAGE} = "fr,en,*";
    ok( ( $cgi4 = Lemonldap::NG::Common::CGI->new() ), 'New CGI' );
    ok( $lang = $cgi4->extract_lang(), 'extract_lang with * value' );
    ok( scalar(@$lang) == 2, 'extract_lang with * value' );

    # SOAP
    eval { require SOAP::Lite };
    skip "SOAP::Lite is not installed, so CGI SOAP functions will not work", 3
      if ($@);
    $ENV{HTTP_SOAPACTION} =
      'http://localhost/Lemonldap/NG/Common/CGI/SOAPService#soapfunc';
    $param =
'<?xml version="1.0" encoding="UTF-8"?><soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><soapfunc xmlns="http://localhost/Lemonldap/NG/Common/CGI/SOAPService"><var xsi:type="xsd:string">fr</var></soapfunc></soap:Body></soap:Envelope>';
    ok( $cgi->soapTest('soapfunc') == 2, 'SOAP call exit fine' );
    my $tmp = diff();
    ok( $tmp =~ /^Status: 200/s, 'HTTP response 200' );
    ok( $tmp =~ /<result xsi:type="xsd:string">SoapOK<\/result>/s,
        'result of SOAP call' );
}
