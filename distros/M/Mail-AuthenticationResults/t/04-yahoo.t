#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $ARHeader = 'Authentication-Results: mta4011.mail.gq1.yahoo.com  from=fastmail.com; domainkeys=neutral (no sig);  from=messagingengine.com; dkim=pass (ok)';

my $Parsed;
lives_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( $ARHeader ) }, 'Parse lives' );

is ( $Parsed->value()->value(), 'mta4011.mail.gq1.yahoo.com', 'ServID' );
is ( scalar @{$Parsed->search({ 'key'=>'dkim','value'=>'pass' })->children() }, 1, 'DKIM Pass' );

done_testing();

