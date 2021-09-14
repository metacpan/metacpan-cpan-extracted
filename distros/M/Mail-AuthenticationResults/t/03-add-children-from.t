#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $ARHeader1 = 'Authentication-Results: mx6.messagingengine.com;
    dkim=pass (1024-bit rsa key sha256) header.d=mail.ru header.i=@mail.ru header.b=oF80QtY/ x-bits=1024 x-keytype=rsa x-algorithm=sha256 x-selector=mail2;
    spf=pass smtp.mailfrom=fmdeliverability@mail.ru smtp.helo=smtp46.i.mail.ru;';
my $ARHeader2 = 'Authentication-Results: mx5.messagingengine.com;
    dmarc=pass (p=reject,d=none) header.from=mail.ru;';

my $Parsed1;
my $Parsed2;
lives_ok( sub{ $Parsed1 = Mail::AuthenticationResults::Parser->new()->parse( $ARHeader1 ) }, 'Parse 1 lives' );
lives_ok( sub{ $Parsed2 = Mail::AuthenticationResults::Parser->new()->parse( $ARHeader2 ) }, 'Parse 2 lives' );

is ( $Parsed1->value()->value(), 'mx6.messagingengine.com', 'ServID 1' );
is ( scalar @{$Parsed1->search({ 'key'=>'spf','value'=>'pass' })->children() }, 1, 'SPF Pass 1' );
is ( scalar @{$Parsed1->search({ 'key'=>'dkim','value'=>'pass' })->search({ 'key'=>'header.i','value'=>'@mail.ru' })->children() }, 1, 'DKIM Pass 1' );
is ( scalar @{$Parsed1->search({ 'key'=>'dmarc','value'=>'pass' })->children() }, 0, 'DMARC Missing 1' );

is ( $Parsed2->value()->value(), 'mx5.messagingengine.com', 'ServID 2' );
is ( scalar @{$Parsed2->search({ 'key'=>'spf','value'=>'pass' })->children() }, 0, 'SPF Missing 2' );
is ( scalar @{$Parsed2->search({ 'key'=>'dkim','value'=>'pass' })->search({ 'key'=>'header.i','value'=>'@mail.ru' })->children() }, 0, 'DKIM Missing 2' );
is ( scalar @{$Parsed2->search({ 'key'=>'dmarc','value'=>'pass' })->children() }, 1, 'DMARC Pass 2' );

lives_ok( sub{ $Parsed1->copy_children_from( $Parsed2 ) }, 'Merge 2 into 1 lives' );

is ( $Parsed1->value()->value(), 'mx6.messagingengine.com', 'ServID 1 post copy' );
is ( scalar @{$Parsed1->search({ 'key'=>'spf','value'=>'pass' })->children() }, 1, 'SPF Pass 1 post copy' );
is ( scalar @{$Parsed1->search({ 'key'=>'dkim','value'=>'pass' })->search({ 'key'=>'header.i','value'=>'@mail.ru' })->children() }, 1, 'DKIM Pass 1 post copy' );
is ( scalar @{$Parsed1->search({ 'key'=>'dmarc','value'=>'pass' })->children() }, 1, 'DMARC Pass post copy' );

is ( $Parsed2->value()->value(), 'mx5.messagingengine.com', 'ServID 2' );
is ( scalar @{$Parsed2->search({ 'key'=>'spf','value'=>'pass' })->children() }, 0, 'SPF Missing 2 post copy' );
is ( scalar @{$Parsed2->search({ 'key'=>'dkim','value'=>'pass' })->search({ 'key'=>'header.i','value'=>'@mail.ru' })->children() }, 0, 'DKIM Missing 2 post copy' );
is ( scalar @{$Parsed2->search({ 'key'=>'dmarc','value'=>'pass' })->children() }, 1, 'DMARC Pass 2 post copy' );

done_testing();


