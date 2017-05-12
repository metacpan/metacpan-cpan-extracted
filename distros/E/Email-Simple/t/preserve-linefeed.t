#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;

use_ok( 'Email::Simple' );

my $original = <<'EOM';
subject:
 =?utf-8?B?ZGVsLmljaW8udXMvbmV0d29yay9qb2VlIC0gW2Zyb20gbWlqaXRdIEJMQiBFY2MgMw==?=
content-type: text/plain

empty body
EOM

my $mail = Email::Simple->new( $original );
isa_ok( $mail, 'Email::Simple' );

is( $mail->as_string, $original );
