use strict;
use warnings;
use Math::Decimal128 qw(:all);

my $t = 2;

print "1..$t\n";

my $rop = Math::Decimal128->new('3.78');

my $ok = '';

if( $rop ==  '3.78')          {$ok .= 'a'}
if( $rop !=  '2.78')          {$ok .= 'b'}
if( $rop >   '3.77')          {$ok .= 'c'}
if( $rop >=  '3.77')          {$ok .= 'd'}
if( $rop >=  '3.78')          {$ok .= 'e'}
if( $rop >   '-inf')          {$ok .= 'f'}
if( $rop !=  '-nan')          {$ok .= 'g'}
if( $rop <   '+inf')          {$ok .= 'h'}
if( $rop <   '3.79')          {$ok .= 'i'}
if( $rop <=  '3.79')          {$ok .= 'j'}
if( $rop <=  '3.78')          {$ok .= 'k'}
if(($rop <=> '3.78') == 0)    {$ok .= 'l'}
if(($rop <=> '3.79') == -1)   {$ok .= 'm'}
if(($rop <=> '3.77') == 1)    {$ok .= 'n'}
if(!defined($rop <=> 'nan'))  {$ok .= 'o'}
if(-$rop >   '-inf')          {$ok .= 'p'}

if($ok eq 'abcdefghijklmnop') {print "ok 1\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 1\n";
}

$ok = '';

my $str = '0.22';

if($rop + $str  == '4.0'    ) {$ok .= 'a'}
if($rop - $str  == '3.56'   ) {$ok .= 'b'}
if($rop * $str  == '.8316'  ) {$ok .= 'c'}
if($rop / '0.4' == '+945e-2') {$ok .= 'd'}
$rop  /= '4e-1';
if($rop == '9.45')    {$ok .= 'e'}
$rop += $str;
if($rop == '9.67')       {$ok .= 'f'}
$rop -= '2.2e-1';
if($rop == '945E-2')    {$ok .= 'g'}
$rop *= '.04e1';
if($rop == '37.8e-1') {$ok .= 'h'}

if($ok eq 'abcdefgh') {print "ok 2\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 2\n";
}
