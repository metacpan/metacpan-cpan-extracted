#!/usr/bin/perl

use Test::More;
use strict;
use IO::String;
use File::Copy;

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_RESETCERTIFICATE_INVALID PE_RESETCERTIFICATE_FORMEMPTY
  PE_RESETCERTIFICATE_FIRSTACCESS
);

BEGIN {
    eval {
        require 't/test-lib.pm';
        require 't/smtp.pm';
    };
}

my ( $res, $user );
my $maintests = 12;

SKIP: {
    eval
'require Email::Sender::Simple; use GD::SecurityImage; use Image::Magick; use Net::SSLeay;
use DateTime::Format::RFC3339;';
    if ($@) {
        skip 'Missing dependencies ' . $@, $maintests;

    }

    skip 'LLNGTESTLDAP is not set', $maintests unless ( $ENV{LLNGTESTLDAP} );
    require 't/test-ldap.pm';

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel              => 'error',
                useSafeJail           => 1,
                portalDisplayRegister => 1,
                authentication        => 'SSL',
                userDB                => 'LDAP',
                passwordDB            => 'LDAP',
                registerDB            => 'LDAP',
                ldapServer            => $main::slapd_url,
                ldapBase              => 'ou=users,dc=example,dc=com',
                managerDn             => 'cn=admin,dc=example,dc=com',
                managerPassword       => 'admin',
                captcha_mail_enabled  => 0,
                portalDisplayCertificateResetByMail        => 1,
                certificateResetByMailCeaAttribute         => 'description',
                certificateResetByMailCertificateAttribute =>
                  'userCertificate;binary',
                certificateResetByMailStep1Body =>
'Click here <a href="$url">  to confirm your mail. It will expire $expMailDate',
                certificateResetByMailStep2Body =>
                  'Certificate successfully reset!',
                certificateValidityDelay => 30

            }
        }
    );

    # Test form
    # ------------------------
    ok( $res = $client->_get( '/certificateReset', accept => 'text/html' ),
        'Reset form', );
    my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'mail' );

    $query = 'mail=dwho%40badwolf.org';

    # Post email
    ok(
        $res = $client->_post(
            '/certificateReset', IO::String->new($query),
            length => length($query),
            accept => 'text/html'
        ),
        'Post mail'
    );

    ok( mail() =~ m#a href="http://auth.example.com/certificateReset\?(.*?)"#,
        'Found link in mail' );
    $query = $1;
    my $querymail = $query;
    ok(
        $res = $client->_get(
            '/certificateReset',
            query  => $query,
            accept => 'text/html'
        ),
        'Post mail token received by mail'
    );

    # print STDERR Dumper($res);

    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
    ok( $res->[2]->[0] =~ /certif/s, ' Ask for a new certificate file' );

    #print STDERR Dumper($query);
    my %inputs   = split( /[=&]/, $query );
    my %querytab = split( /[=&]/, $querymail );

    # Create the certificate  file
    my $cert = "-----BEGIN CERTIFICATE-----
MIIDdzCCAl+gAwIBAgIJAKGx8siw7lkRMA0GCSqGSIb3DQEBCwUAMFExCzAJBgNV
BAYTAkZSMQ8wDQYDVQQIDAZGcmFuY2UxDjAMBgNVBAcMBVBBcmlzMREwDwYDVQQK
DAhMaW5hZ29yYTEOMAwGA1UECwwFTElOSUQwIBcNMTkwNzA0MTcyNjI4WhgPMjEx
OTA2MTAxNzI2MjhaMFExCzAJBgNVBAYTAkZSMQ8wDQYDVQQIDAZGcmFuY2UxDjAM
BgNVBAcMBVBBcmlzMREwDwYDVQQKDAhMaW5hZ29yYTEOMAwGA1UECwwFTElOSUQw
ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC3iyeNE2vpURgdY7xwxS16
xUJANPuMSrCfy1E/xpCtbP02zK0B11DkT81AnTHgvsWYuiubR1P3Phhh+JLsLRho
Grzu9xjaiKXQ+kT1cAiq6skZljphykXBfKUb73W9CPntHL/zl3XyIfu+dWyCGbqa
jHw0Llomi8JqU/XKB6XAYumsV3QzFMM7ECm5HeV3BxfIBwoIOwfwINDUrAGS3h4k
WH/iiqwG7uSuADupSfdmOrvE7rYZupPas4YATX1m5hmON++9pRRFVEoNeOV1qyGY
G7swH1uoO2hAgwKIw0vinft/pJLqe3qhrJwNCIZFHaDEx/PRERFeeEH9/6HSz5kt
AgMBAAGjUDBOMB0GA1UdDgQWBBTFv6pQT/9IBWEAGhILGCcweVfHmTAfBgNVHSME
GDAWgBTFv6pQT/9IBWEAGhILGCcweVfHmTAMBgNVHRMEBTADAQH/MA0GCSqGSIb3
DQEBCwUAA4IBAQBFYneMW5etMnsA3/PdvOqx/ijBF98aKlB4U4IKZpdDRAcsstdL
BSsHRQbHXtb9VdlDWvUnNg5DmjsA8DkOXKXGPGM9ncu9tQi9EoInbOJTMaEsIr2j
zrLj6PHTvazy+6Au+R/9N5u3WQtq/Z2xoN/+bbQ1dyjXgQmBZFizHP32l5AdgBDT
jF7xMHxJ6Jxz9lkI+d9v0TzpxTStsaC+pbDfoouNc2deZkv84YTIrD0EPSHFDH5d
u5i9b+lrWZeCtpVEPzSYpnBwGfepbZAzfVRKJm7wZPCe7KxqMGXQLVBkD8oN7vA1
lkRrWfQftwmLyNIu3HfSgXlgAZS30ymfbzBU
-----END CERTIFICATE-----";

    open my $FH2, '>', '/tmp/v296ZJQ_kG';
    print {$FH2} "$cert";
    close $FH2;

    $res = $client->app->( {
            'plack.request.query' => bless( {
                    'skin'       => $querytab{'skin'},
                    'mail_token' => $querytab{'mail_token'}
                },
                'Hash::MultiValue'
            ),
            'PATH_INFO'   => '/certificateReset',
            'HTTP_ACCEPT' =>
'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3',
            'REQUEST_METHOD'       => 'POST',
            'HTTP_ORIGIN'          => 'http://auth.example.com',
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'REQUEST_SCHEME'       => 'http',
            'HTTP_CACHE_CONTROL'   => 'max-age=0',

            'plack.request.merged' => bless( {
                    'skin'       => $querytab{'skin'},
                    'mail_token' => $querytab{'mail_token'},
                    'url'        => '',
                    'token'      => $inputs{'token'}
                },
                'Hash::MultiValue'
            ),
            'REMOTE_PORT'                    => '36674',
            'QUERY_STRING'                   => $querymail,
            'SERVER_SIGNATURE'               => '',
            'psgix.input.buffered'           => 1,
            'HTTP_UPGRADE_INSECURE_REQUESTS' => '1',
            'CONTENT_TYPE'                   =>
'multipart/form-data; boundary=----WebKitFormBoundarybabRY9u6K9tERoLr',
            'plack.request.upload' => bless( {
                    'certif' => bless( {
                            'headers' => bless( {
                                    'content-disposition' =>
'form-data; name="certif"; filename="user.pem"',
                                    'content-type' =>
                                      'application/x-x509-ca-cert',
                                    '::std_case' => {
                                        'content-disposition' =>
                                          'Content-Disposition'
                                    }
                                },
                                'HTTP::Headers'
                            ),
                            'filename' => 'user.pem',
                            'tempname' => '/tmp/v296ZJQ_kG',
                            'size'     => 1261
                        },
                        'Plack::Request::Upload'
                    )
                },
                'Hash::MultiValue'
            ),
            'psgi.streaming'     => 1,
            'plack.request.body' => bless( {
                    'skin'  => 'bootstrap',
                    'url'   => '',
                    'token' => $inputs{'token'}
                },
                'Hash::MultiValue'
            ),
            'SCRIPT_URL'   => '/certificateReset',
            'SERVER_NAME'  => 'auth.example.com',
            'HTTP_REFERER' => 'http://auth.example.com/certificateReset?'
              . $querymail,
            'HTTP_CONNECTION'     => 'close',
            'CONTENT_LENGTH'      => '1759',
            'SCRIPT_URI'          => 'http://auth.example.com/certificateReset',
            'plack.cookie.parsed' => {
                'llnglanguage' => 'fr'
            },
            'SERVER_PORT'     => '80',
            'SERVER_NAME'     => 'auth.example.com',
            'SERVER_PROTOCOL' => 'HTTP/1.1',
            'SCRIPT_NAME'     => '',
            'HTTP_USER_AGENT' =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'HTTP_COOKIE'         => 'llnglanguage=fr',
            'REMOTE_ADDR'         => '127.0.0.1',
            'REQUEST_URI'         => '/certificateReset?' . $querymail,
            'plack.cookie.string' => 'llnglanguage=fr',
            'SERVER_ADDR'         => '127.0.0.1',
            'psgi.url_scheme'     => 'http',
            'psgix.harakiri'      => '',
            'HTTP_HOST'           => 'auth.example.com'
        }
    );

    ok( mail() =~ /Certificate successfully reset/,
        'Certificate has been reset' );

    # Test invalid certificate

    # Test form
    # ------------------------
    ok( $res = $client->_get( '/certificateReset', accept => 'text/html' ),
        'Reset form', );
    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'mail' );

    $query = 'mail=dwho%40badwolf.org';

    # Post email
    ok(
        $res = $client->_post(
            '/certificateReset', IO::String->new($query),
            length => length($query),
            accept => 'text/html'
        ),
        'Post mail'
    );

    ok( mail() =~ m#a href="http://auth.example.com/certificateReset\?(.*?)"#,
        'Found link in mail' );
    $query     = $1;
    $querymail = $query;
    ok(
        $res = $client->_get(
            '/certificateReset',
            query  => $query,
            accept => 'text/html'
        ),
        'Post mail token received by mail'
    );

    # print STDERR Dumper($res);

    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
    ok( $res->[2]->[0] =~ /certif/s, ' Ask for a new certificate file' );

    #print STDERR Dumper($query);
    %inputs   = split( /[=&]/, $query );
    %querytab = split( /[=&]/, $querymail );

    # Create the certificate  file
    $cert = "INVALID CERTIFICATE";

    open $FH2, '>', '/tmp/v296ZJQ_kG';
    print {$FH2} "$cert";
    close $FH2;

    $res = $client->app->( {
            'plack.request.query' => bless( {
                    'skin'       => $querytab{'skin'},
                    'mail_token' => $querytab{'mail_token'}
                },
                'Hash::MultiValue'
            ),
            'PATH_INFO'   => '/certificateReset',
            'HTTP_ACCEPT' =>
'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3',
            'REQUEST_METHOD'       => 'POST',
            'HTTP_ORIGIN'          => 'http://auth.example.com',
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'REQUEST_SCHEME'       => 'http',
            'HTTP_CACHE_CONTROL'   => 'max-age=0',

            'plack.request.merged' => bless( {
                    'skin'       => $querytab{'skin'},
                    'mail_token' => $querytab{'mail_token'},
                    'url'        => '',
                    'token'      => $inputs{'token'}
                },
                'Hash::MultiValue'
            ),
            'REMOTE_PORT'                    => '36674',
            'QUERY_STRING'                   => $querymail,
            'SERVER_SIGNATURE'               => '',
            'psgix.input.buffered'           => 1,
            'HTTP_UPGRADE_INSECURE_REQUESTS' => '1',
            'CONTENT_TYPE'                   =>
'multipart/form-data; boundary=----WebKitFormBoundarybabRY9u6K9tERoLr',
            'plack.request.upload' => bless( {
                    'certif' => bless( {
                            'headers' => bless( {
                                    'content-disposition' =>
'form-data; name="certif"; filename="user.pem"',
                                    'content-type' =>
                                      'application/x-x509-ca-cert',
                                    '::std_case' => {
                                        'content-disposition' =>
                                          'Content-Disposition'
                                    }
                                },
                                'HTTP::Headers'
                            ),
                            'filename' => 'user.pem',
                            'tempname' => '/tmp/v296ZJQ_kG',
                            'size'     => 1261
                        },
                        'Plack::Request::Upload'
                    )
                },
                'Hash::MultiValue'
            ),
            'psgi.streaming'     => 1,
            'plack.request.body' => bless( {
                    'skin'  => 'bootstrap',
                    'url'   => '',
                    'token' => $inputs{'token'}
                },
                'Hash::MultiValue'
            ),
            'SCRIPT_URL'   => '/certificateReset',
            'SERVER_NAME'  => 'auth.example.com',
            'HTTP_REFERER' => 'http://auth.example.com/certificateReset?'
              . $querymail,
            'HTTP_CONNECTION'     => 'close',
            'CONTENT_LENGTH'      => '1759',
            'SCRIPT_URI'          => 'http://auth.example.com/certificateReset',
            'plack.cookie.parsed' => {
                'llnglanguage' => 'fr'
            },
            'SERVER_PORT'     => '80',
            'SERVER_NAME'     => 'auth.example.com',
            'SERVER_PROTOCOL' => 'HTTP/1.1',
            'SCRIPT_NAME'     => '',
            'HTTP_USER_AGENT' =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'HTTP_COOKIE'         => 'llnglanguage=fr',
            'REMOTE_ADDR'         => '127.0.0.1',
            'REQUEST_URI'         => '/certificateReset?' . $querymail,
            'plack.cookie.string' => 'llnglanguage=fr',
            'SERVER_ADDR'         => '127.0.0.1',
            'psgi.url_scheme'     => 'http',
            'psgix.harakiri'      => '',
            'HTTP_HOST'           => 'auth.example.com'
        }
    );

    my $trmsg = $res->[2]->[0];               # get html response
    my @trmsg = split( /\n/, $trmsg );        # split into lines
    @trmsg = grep( /trmsg="/, @trmsg ); # only get line corresponding to message
    $trmsg = $trmsg[0];                 # get the first one only
    $trmsg =~ s/.*trmsg="([0-9]+)".*/$1/g;    # get error code number
    ok( $trmsg == PE_RESETCERTIFICATE_INVALID, 'Invalid certificate' );
}

clean_sessions();
count($maintests);
done_testing( count() );
