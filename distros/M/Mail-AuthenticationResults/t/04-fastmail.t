#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $ARHeader = 'Authentication-Results: mx6.messagingengine.com;
    arc=none (no signatures found);
    dkim=pass (1024-bit rsa key sha256) header.d=mail.ru header.i=@mail.ru header.b=oF80QtY/ x-bits=1024 x-keytype=rsa x-algorithm=sha256 x-selector=mail2;
    dmarc=pass (p=reject,d=none) header.from=mail.ru;
    iprev=pass policy.iprev=94.100.177.106 (smtp46.i.mail.ru);
    spf=pass smtp.mailfrom=fmdeliverability@mail.ru smtp.helo=smtp46.i.mail.ru;
    x-aligned-from=pass;
    x-ptr=pass x-ptr-helo=smtp46.i.mail.ru x-ptr-lookup=smtp46.i.mail.ru;
    x-return-mx=pass smtp.domain=mail.ru smtp.result=pass smtp_is_org_domain=yes header.domain=mail.ru header.result=pass header_is_org_domain=yes;
    x-tls=pass version=TLSv1.2 cipher=ECDHE-RSA-AES128-GCM-SHA256 bits=128/128';

my $Parsed;
lives_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( $ARHeader ) }, 'Parse lives' );

is ( $Parsed->value()->value(), 'mx6.messagingengine.com', 'ServID' );
is ( scalar @{$Parsed->search({ 'key'=>'spf','value'=>'pass' })->children() }, 1, 'SPF Pass' );
is ( scalar @{$Parsed->search({ 'key'=>'dkim','value'=>'pass' })->search({ 'key'=>'header.i','value'=>'@mail.ru' })->children() }, 1, 'DKIM Pass' );
is ( scalar @{$Parsed->search({ 'key'=>'dmarc','value'=>'pass' })->children() }, 1, 'DMARC Pass' );

done_testing();

