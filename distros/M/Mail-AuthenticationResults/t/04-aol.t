#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $ARHeader = 'mx.aol.com;
	spf=pass (aol.com: the domain fastmail.com reports 66.111.4.222 as a permitted sender.) smtp.mailfrom=fastmail.com;
	dkim=pass (aol.com: email passed verification from the domain fastmail.com.) header.i=@fastmail.com;
	dmarc=pass (aol.com: the domain fastmail.com reports that Both SPF and DKIM strictly align.) header.from=fastmail.com;';

my $Parsed;
lives_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( $ARHeader ) }, 'Parse lives' );

is ( $Parsed->value()->value(), 'mx.aol.com', 'ServID' );
is ( scalar @{$Parsed->search({ 'key'=>'spf','value'=>'pass' })->children() }, 1, 'SPF Pass' );
is ( scalar @{$Parsed->search({ 'key'=>'dkim','value'=>'pass' })->search({ 'key'=>'header.i','value'=>'@fastmail.com' })->children() }, 1, 'DKIM fastmail.com Pass' );
is ( scalar @{$Parsed->search({ 'key'=>'dmarc','value'=>'pass' })->children() }, 1, 'DMARC Pass' );

done_testing();

