#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Header::Group;
use Mail::AuthenticationResults::Parser;

my $Group = Mail::AuthenticationResults::Header::Group->new();

# iCloud adds multiple headers, let's add them all to a group

my @ARHeaders = (
'Authentication-results: mr21p00im-dmarcmilter001.me.com; dmarc=pass
 header.from=fastmail.com',
'Authentication-results: mr21p00im-spfmilter010.me.com; spf=pass
 (mr21p00im-spfmilter010.me.com: domain of deliverability@fastmail.com
 designates 66.111.4.221 as permitted sender)
 smtp.mailfrom=deliverability@fastmail.com',
'Authentication-results: mr21p00im-dkimmilter005.me.com;	dkim=pass (2048-bit
 key) header.d=messagingengine.com header.i=@messagingengine.com
 header.b=V9y21l+w;	dkim-adsp=pass',
'Authentication-results: mr21p00im-dkimmilter005.me.com;	dkim=pass (2048-bit
 key) header.d=fastmail.com header.i=@fastmail.com header.b=0GObIji6;
	dkim-adsp=pass',
);

foreach my $Header ( @ARHeaders ) {
    my $Parsed;
    lives_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( $Header ) }, 'Parse lives' );
    $Group->add_child( $Parsed );
}

#is ( $Parsed->value(), 'mxs.mail.ru', 'ServID' );
is ( scalar @{$Group->search({ 'key'=>'spf','value'=>'pass' })->children() }, 1, 'SPF Pass' );
is ( scalar @{$Group->search({ 'key'=>'dkim','value'=>'pass' })->search({ 'key'=>'header.d','value'=>'fastmail.com' })->children() }, 1, 'DKIM fastmail.com Pass' );
is ( scalar @{$Group->search({ 'key'=>'dkim','value'=>'pass' })->search({ 'key'=>'header.d','value'=>'messagingengine.com' })->children() }, 1, 'DKIM messagingengine.com Pass' );
is ( scalar @{$Group->search({ 'key'=>'dmarc','value'=>'pass' })->children() }, 1, 'DMARC Pass' );

done_testing();

