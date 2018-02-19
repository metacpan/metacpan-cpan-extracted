#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $ARHeader = 'Authentication-Results: mxfront8g.mail.yandex.net; spf=pass (mxfront8g.mail.yandex.net: domain of fastmail.com designates 66.111.4.222 as permitted sender, rule=[ip4:66.111.4.0/24]) smtp.mail=deliverability@fastmail.com; dkim=pass header.i=@fastmail.com';

my $Parsed;
lives_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( $ARHeader ) }, 'Parse lives' );

is ( $Parsed->value()->value(), 'mxfront8g.mail.yandex.net', 'ServID' );
is ( scalar @{$Parsed->search({ 'key'=>'spf','value'=>'pass' })->children() }, 1, 'SPF Pass' );
is ( scalar @{$Parsed->search({ 'key'=>'dkim','value'=>'pass' })->search({ 'key'=>'header.i','value'=>'@fastmail.com' })->children() }, 1, 'DKIM fastmail.com Pass' );

done_testing();

