#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $ARHeader = 'mxs.mail.ru; spf=pass (mx159.mail.ru: domain of fastmail.com designates 66.111.4.221 as permitted sender) smtp.mailfrom=deliverability@fastmail.com smtp.helo=new1-smtp.messagingengine.com;
	 dkim=pass header.d=fastmail.com;
	 dkim=pass header.d=messagingengine.com; dmarc=pass header.from=deliverability@fastmail.com';

my $Parsed;
lives_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( $ARHeader ) }, 'Parse lives' );

is ( $Parsed->value()->value(), 'mxs.mail.ru', 'ServID' );
is ( scalar @{$Parsed->search({ 'key'=>'spf','value'=>'pass' })->children() }, 1, 'SPF Pass' );
is ( scalar @{$Parsed->search({ 'key'=>'dkim','value'=>'pass' })->search({ 'key'=>'header.d','value'=>'fastmail.com' })->children() }, 1, 'DKIM fastmail.com Pass' );
is ( scalar @{$Parsed->search({ 'key'=>'dkim','value'=>'pass' })->search({ 'key'=>'header.d','value'=>'messagingengine.com' })->children() }, 1, 'DKIM messagingengine.com Pass' );
is ( scalar @{$Parsed->search({ 'key'=>'dmarc','value'=>'pass' })->children() }, 1, 'DMARC Pass' );

done_testing();

