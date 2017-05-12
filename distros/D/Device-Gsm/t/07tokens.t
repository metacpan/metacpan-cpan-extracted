# test new token engine for decoding/encoding sms messages 
#
use Test::More;
BEGIN { plan tests => 7 };
use lib '../lib';
use_ok('Device::Gsm');
use_ok('Device::Gsm::Sms');
use_ok('Device::Gsm::Sms::Structure');
use_ok('Device::Gsm::Sms::Token');

#my @messages = (
#	[ '+CMGL: 3,3,,36' => '079193235058580011A50A8123988277790000AD1AC33468FE76BF41B19A0B068381E065F9FCED2E8342A110' ],
#	[ '+CMGL: 4,1,,140' => '0791932350591900040CD0ECB4B82C7F033900209021319490008AF3F67C14D381C6E9F09B051ABFDB75777A1CD683C8A079596E4FEB8' ],
#	[ '+CMGL: 2,1,,31' => '0791932350593900040C919323988277190000208082319082000DC170382C168BC3E1B0582C06' ]
#);

my $sca = new Sms::Token 'SCA';
my $msg = '0791932350593900';
my $ok = $sca->decode( \$msg );

ok( $ok );
is( $sca->toString(), '+393205959300' );

#
# CPAN Bug #24781 regression test
# 
my $oa = new Sms::Token 'OA';
$oa->set('address', '+3289287791');
$oa->set('type',    91);
is($oa->toString(), '+3289287791', 'avoid ++ in sender address (CPAN Bug #24781)');

