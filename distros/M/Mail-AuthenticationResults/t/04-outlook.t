#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

#outlook header is not to the expected spec
#plan( skip_all => 'Outlook does not currently parse correctly' );
#my $ARHeader = 'Authentication-Results: spf=pass (sender IP is 66.111.4.222)
# smtp.mailfrom=fastmail.com; outlook.com; dkim=pass (signature was verified)
# header.d=fastmail.com;outlook.com; dmarc=pass action=none
# header.from=fastmail.com;';

# Refactor the actual outlook.com header for the tests

my $ARHeader = 'Authentication-Results: outlook.com; spf=pass (sender IP is 66.111.4.222)
 smtp.mailfrom=fastmail.com; outlook.com; dkim=pass (signature was verified)
 header.d=fastmail.com; dmarc=pass action=none
 header.from=fastmail.com;';

my $Parsed;
lives_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( $ARHeader ) }, 'Parse lives' );

is ( $Parsed->value()->value(), 'outlook.com', 'ServID' );
is ( scalar @{$Parsed->search({ 'key'=>'spf','value'=>'pass' })->children() }, 1, 'SPF Pass' );
is ( scalar @{$Parsed->search({ 'key'=>'dkim','value'=>'pass' })->children() }, 1, 'DKIM Pass' );
is ( scalar @{$Parsed->search({ 'key'=>'dmarc','value'=>'pass' })->children() }, 1, 'DMARC Pass' );

done_testing();

