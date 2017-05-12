# test non-MARC8 output

use strict;
use warnings;
use Test::More qw( no_plan );

use_ok( 'MARC::Record' );
use_ok( 'MARC::Field' );
use_ok( 'MARC::Detrans' );

my $detrans = MARC::Detrans->new(config => 't/unicodeconfig.xml');

my $r1= MARC::Record->new();
$r1->append_fields(MARC::Field->new('008', '940908s1994    ii            000 1 tamo '));
$r1->append_fields(MARC::Field->new('100', '1', '', a => 'k'));

my $r2 = $detrans->convert($r1);
is($r2->field('100')->subfield('a'), 'k');
is($r2->field('100')->subfield('6'), '880-01');
is($r2->field('880')->subfield('a'), chr(0x0b95) . chr(0x0bcd));

