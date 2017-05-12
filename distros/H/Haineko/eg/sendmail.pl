#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Furl;
use JSON;
use Data::Dumper;

my $credential = { 
    'username' => 'haineko', 
    'password' => 'kijitora',
};
my $clientname = qx(hostname); chomp $clientname;
my $hainekourl = 'http://127.0.0.1:2794/submit';
my $emaildata1 = {
    'ehlo' => $clientname,
    'mail' => 'envelope-sender@example.jp',
    'rcpt' => [ 'envelope-recipient@example.org' ],
    'body' => 'メール本文です。',
    'header' => {
        'from' => 'キジトラ <envelope-sender@example.jp>',
        'subject' => 'テストメール',
        'replyto' => 'neko@example.jp',
    },
};
my $methodargv = undef;
my $jsonstring = undef;
my $htresponse = undef;
my $httpobject = undef;
my $hainekores = undef;
my $httpheader = [];

if( $ENV{'HAINEKO_AUTH'} || $ARGV[0] ) {
    require MIME::Base64;
    my $_auth = MIME::Base64::encode_base64( $credential->{'username'}.':'.$credential->{'password'} );
    $httpheader = [ 'Authorization' => sprintf( "Basic %s", $_auth ) ];
}
$jsonstring = JSON::encode_json( $emaildata1 );

$httpobject = Furl->new(
    'agent'    => 'Haineko/eg/sendmail.pl',
    'timeout'  => 10,
    'headers'  => $httpheader,
    'ssl_opts' => { 'SSL_verify_mode' => 0 }
);
$htresponse = $httpobject->post( $hainekourl, $httpheader, $jsonstring );
$hainekores = JSON::decode_json( $htresponse->content );
warn Dumper $hainekores;

