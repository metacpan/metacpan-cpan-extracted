#
# Test for Lingua::NO::Num2Word
#
# Written by: Kjetil Fikkan, kjetil@fikkan.org
#
# Created: 10.06.2004
#

use strict;
use warnings;
use Test::More tests => 27;

# test if we can load the module
use_ok("Lingua::NO::Num2Word");

my $no_num2word = Lingua::NO::Num2Word->new(); 
ok ( defined $no_num2word, 'new() returned something');
isa_ok( $no_num2word, 'Lingua::NO::Num2Word' );

# test if the module has the required methods
can_ok( $no_num2word, "num2no_cardinal" );

# sigletontest
my $no_num2word_other = Lingua::NO::Num2Word->new();
ok ( $no_num2word == $no_num2word_other, 'Object has singleton functionality' );

# inputtest 
ok ( $no_num2word->num2no_cardinal()       eq '', 'No input returned nothing');
ok ( $no_num2word->num2no_cardinal( -10 )  eq '', 'Negativ numbers returned nothing');
ok ( $no_num2word->num2no_cardinal( -0 )   eq 'null', 'Negativ zero returned the text null');
ok ( $no_num2word->num2no_cardinal( 0 )    eq 'null', 'Zero returned the text null');
ok ( $no_num2word->num2no_cardinal( 5 )    eq 'fem', 'Five returned the text fem');
ok ( $no_num2word->num2no_cardinal( 1.11 ) eq '', '1.11 returned nothing');
ok ( $no_num2word->num2no_cardinal( 2.00 ) eq 'to', '2.00 returned something');

# branch test 
ok ( $no_num2word->num2no_cardinal( 5 )          eq 'fem', 'if branch less than 20');
ok ( $no_num2word->num2no_cardinal( 55 )         eq 'femti fem', 'if branch less than 100');
ok ( $no_num2word->num2no_cardinal( 100 )        eq 'ett hundre', 'if branch less than 1000');
ok ( $no_num2word->num2no_cardinal( 200 )        eq 'to hundre', 'if branch less than 1000');
ok ( $no_num2word->num2no_cardinal( 1000 )       eq 'ett tusen', 'if branch less than 100000 - branch 1');
ok ( $no_num2word->num2no_cardinal( 2000 )       eq 'to tusen', 'if branch less than 100000 - branch 2');
ok ( $no_num2word->num2no_cardinal( 5005 )       eq 'fem tusen og fem', 'if branch less than 100000 - branch 2');
ok ( $no_num2word->num2no_cardinal( 55000 )      eq 'femti fem tusen', 'if branch less than 100000 - branch 3');
ok ( $no_num2word->num2no_cardinal( 550000 )     eq 'fem hundre og femti tusen', 'if branch less than 100000000 - branch 1');
ok ( $no_num2word->num2no_cardinal( 117004 )     eq 'ett hundre og sytten tusen og fire', 'if branch less than 100000000 - branch 2');
ok ( $no_num2word->num2no_cardinal( 1000000 )    eq 'en million', 'if branch less than 1000000000 - branch 1');
ok ( $no_num2word->num2no_cardinal( 10073852 )   eq 'ti millioner og sytti tre tusen åtte hundre og femti to', 'if branch less than 1000000000 - branch 2');
ok ( $no_num2word->num2no_cardinal( 555000000 )  eq 'fem hundre og femti fem millioner', 'if branch less than 1000000000');
ok ( $no_num2word->num2no_cardinal( 1000000000 ) eq '', 'if branch >= 1000000000 is unsupported returns nothing');

# test if max number is supported
ok ( $no_num2word->num2no_cardinal(  999999999 ) eq 'ni hundre og nitti ni millioner ni hundre og nitti ni tusen ni hundre og nitti ni', '999 999 999 is supported');