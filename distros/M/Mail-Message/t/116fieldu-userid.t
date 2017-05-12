#!/usr/bin/env perl
#
# Test processing in combination with User::Identity as documented in
# Mail::Message::Field.
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Field::Fast;
use User::Identity;

use Test::More tests => 22;

my $mmf = 'Mail::Message::Field::Fast';

# A user's identity

my $patrik = User::Identity->new
 ( "patrik"
 , full_name => "Patrik Fältström"  # from rfc
 , charset   => "ISO-8859-1"
 );

isa_ok($patrik, 'User::Identity');

my $email1 = $patrik->add
 ( email     => 'home'
 , address   => 'him@home.net'
 );

isa_ok($email1, 'Mail::Identity');

# address based on Mail::Identity with user

my $f1 = $mmf->new(To => $email1);
isa_ok($f1, $mmf);
is($f1, '=?ISO-8859-1?q?Patrik_F=E4ltstr=F6m?= <him@home.net>');

my $f1b = $mmf->new(To => $patrik);
isa_ok($f1b, $mmf);
is($f1b, '=?ISO-8859-1?q?Patrik_F=E4ltstr=F6m?= <him@home.net>');

# address based on Mail::Identity without user

require Mail::Identity;
my $email2 = Mail::Identity->new
 ( 'work'
 , address   => 'somewhere@example.com'
 );
my $f2 = $mmf->new(To => $email2);
is($f2, 'somewhere@example.com');

# A very complex address

my $email3 = Mail::Identity->new
 ( 'work'
 , address   => 'somehow@example.com'
 , phrase    => 'my " quote'
 , comment   => 'make it ) hard'
 );
my $f3 = $mmf->new(To => $email3);
is($f3, qq["my \\" quote" <somehow\@example.com> (make it \\) hard)]);

# A collection of e-mails

$patrik->add(email => $email3);
my $emails = $patrik->collection('emails');
isa_ok($emails, 'User::Identity::Collection::Emails');
cmp_ok(@$emails, '==', 2);

# An array of addresses

my $f4 = $mmf->new
  ( To =>
     [ $email1
     , "aap\@hok.nl"
     , $email2
     , $patrik->find(email => 'work')
     ]
  );

is($f4->string, <<'FOLDED');
To: =?ISO-8859-1?q?Patrik_F=E4ltstr=F6m?= <him@home.net>, aap@hok.nl,
 somewhere@example.com, "my \" quote" <somehow@example.com> (make it \) hard)
FOLDED

# Test a collection which is linked to user

my $f5 = $mmf->new(To => $emails);
is($f5->string, <<'TWO');
To: emails: "my \" quote" <somehow@example.com> (make it \) hard),
 =?ISO-8859-1?q?Patrik_F=E4ltstr=F6m?= <him@home.net>;
TWO

require Mail::Message::Field::AddrGroup;

# test a collection which is not linked to a user

my $mmfg = 'Mail::Message::Field::AddrGroup';
my $g = $mmfg->new(name => 'groupie');
isa_ok($g, $mmfg);
is($g->name, 'groupie');
my @addrs = $g->addresses;
cmp_ok(scalar @addrs, '==', 0);
is($g->string, "groupie: ;");

$g->addAddress($email1);
@addrs = $g->addresses;
cmp_ok(scalar @addrs, '==', 1);
is($g->string, 'groupie: him@home.net;');

$g->addAddress($email3);
@addrs = $g->addresses;
cmp_ok(scalar @addrs, '==', 2);
is($g->string, 'groupie: "my \" quote" <somehow@example.com> (make it \) hard), him@home.net;');

$g->addAddress('aap@hok.nl');
@addrs = $g->addresses;
cmp_ok(scalar @addrs, '==', 3);
is($g->string, 'groupie: "my \" quote" <somehow@example.com> (make it \) hard), aap@hok.nl, him@home.net;');

