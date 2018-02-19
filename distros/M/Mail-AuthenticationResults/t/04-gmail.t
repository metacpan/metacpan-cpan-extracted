#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $ARHeader = 'Authentication-Results: mx.google.com;
       dkim=pass header.i=@fastmail.com header.s=fm1 header.b=2j32dcmg;
       dkim=pass header.i=@messagingengine.com header.s=fm1 header.b=dgrCnA5f;
       spf=pass (google.com: domain of deliverability@fastmail.com designates 66.111.4.26 as permitted sender) smtp.mailfrom=deliverability@fastmail.com;
       dmarc=pass (p=NONE sp=NONE dis=NONE) header.from=fastmail.com';

my $Parsed;
lives_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( $ARHeader ) }, 'Parse lives' );

is ( $Parsed->value()->value(), 'mx.google.com', 'ServID' );
is ( scalar @{$Parsed->search({ 'key'=>'spf','value'=>'pass' })->children() }, 1, 'SPF Pass' );
is ( scalar @{$Parsed->search({ 'key'=>'dkim','value'=>'pass' })->search({ 'key'=>'header.i','value'=>'@fastmail.com' })->children() }, 1, 'DKIM fastmail.com Pass' );
is ( scalar @{$Parsed->search({ 'key'=>'dkim','value'=>'pass' })->search({ 'key'=>'header.i','value'=>'@messagingengine.com' })->children() }, 1, 'DKIM messagingengine.com Pass' );
is ( scalar @{$Parsed->search({ 'key'=>'dmarc','value'=>'pass' })->children() }, 1, 'DMARC Pass' );

done_testing();

