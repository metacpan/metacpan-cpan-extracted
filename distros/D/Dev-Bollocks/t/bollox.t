#!/usr/bin/perl -w

use strict;
use Test;

BEGIN 
  { 
  $| = 1;
  # chdir 't' if -d 't';
  unshift @INC, '../lib'; # to run manually
  plan tests => 176;
  }

use Dev::Bollocks;
use Math::BigInt;

my ($try,$rc,$x,$y,$z,$i);
$| = 1;

##############################################################################
# check wether cmp and <=> work
$x = Dev::Bollocks->new ('adaptively CEOs');	# 1
$y = Dev::Bollocks->new ('adaptively IPOs');	# 2
$z = Dev::Bollocks->new ($x);			# make copy

ok ($x < $y, 1);	# ok (1 < 2, 1)
ok ($x > $y, '');	# ok (1 > 2, '')
ok ($x <=> $y, -1); 	# ok (1 <=> 2, -1)
ok ($y <=> $x, 1); 	# ok (2 <=> 1, 1)
ok ($x <=> $x, 0); 	# ok (1 <=> 1, 1)
ok ($x <=> $z, 0); 	# ok (1 <=> 1, 1)

ok ($x lt $y, 1);
ok ($x gt $y, '');
ok ($x cmp $y, -1);
ok ($y cmp $x, 1);
ok ($x cmp $x, 0);
ok ($x cmp $z, 0);

##############################################################################
# check if negative numbers give same output as positives
$try =  "\$x = Dev::Bollocks::from_number(-12); \$x->as_number();";
$rc = eval $try;
print "# For '$try'\n" if (!ok "$rc" , '-12');
$try =  '$x = Dev::Bollocks::from_number(-12);';
$try .= '$y = Dev::Bollocks::from_number(12); "true" if "$x" eq "$y";';
$rc = eval $try;
print "# For '$try'\n" if (!ok "$rc" , 'true');

##############################################################################
# check wether ++ and -- work
$try =  '$x = Dev::Bollocks->new("");';
$try =  '$y = $x; $y++; "true" if $x < $y;';

$rc = eval $try;
print "# For '$try'\n" if (!ok "$rc" , 'true');
  
$try =  '$x = Dev::Bollocks->new("administrate best-of-breed niches");';
$try =  '$y = $x; $y++; $y--; "true" if $x == $y;';
$rc = eval $try;
print "# For '$try'\n" if (!ok "$rc" , 'true');

##############################################################################
# check wether bior(),bxor(), band() work

$x = Dev::Bollocks->new ('adaptively CEOs');
$y = Dev::Bollocks->new ('adaptively IPOs'); $z = $y | $x;	# 1 | 2 => 3
print "# For '\$z = $y | $x'\n" if (!ok "$z" , 'adaptively ROI');

$x = Dev::Bollocks->new("adaptively appliances");
$y = Dev::Bollocks->new("adaptively architectures"); $z = $y & $x; # 5 & 7 => 5 
print "# For '\$z = $y & $x'\n" if (!ok "$z" , 'adaptively appliances');

#$x = Dev::Bollocks->new("adaptively channels");
#$y = Dev::Bollocks->new("adaptively customers"); $z = $y ^ $x;	# 8 ^ 13 => 5
#print "# For '\$z = $y ^ $x'\n" if (!ok "$z" , 'adaptively applications');
#print $z->as_number(),"\n";

##############################################################################
# check objectify of additional params

$x = Dev::Bollocks->new('advantageously customers');
$x->badd('advantageously infomediaries');

ok ($x->as_number(),292);
$x->badd(1);			# can't add numbers 
				# ('1' is not a valid Math::String here!)
ok ($x->as_number(),'NaN');

ok ($x->order(),1);		# SIMPLE
ok ($x->type(),1);		# grouping

$x = Dev::Bollocks->new('carefully data');
$x->badd( new Math::BigInt (1) ); 	# 136+1 = 137
ok ($x,'carefully deliverables');

##############################################################################
# check if output of bstr is again a valid Math::String

for ($i = 1; $i < 123; $i++)
  {
##  next if $i == 74; 	# does not pass ye
  $try = "\$x = Dev::Bollocks::from_number($i);";
  $try .= "\$x = Dev::Bollocks->new(\"\$x\")->as_number();";
  $rc = eval $try;
  print "# For '$try'\n" if (!ok "$rc" , $i );
  }

##############################################################################
# check overloading of cmp

#$try = "\$x = Dev::Bollocks->new('deploy B2B'); 'true' if \$x eq 'deploy B2B';";
#$rc = eval $try;
#print "# For '$try'\n" if (!ok "$rc" , "true" );

##############################################################################
# check $string->length()

$try = "\$x = Dev::Bollocks->new('carefully clusters'); \$x->length();";
$rc = eval $try;
print "# For '$try'\n" if (!ok "$rc" , 2 );

$try = '$x = Dev::Bollocks->new("adaptively scale markets"); $x->length();';
$rc = eval $try;
print "# For '$try'\n" if (!ok "$rc" , 3 );

#$try = '$x = Dev::Bollocks->new("adaptively syndicate synergistic initiatives"); print "$x ",$x->as_number(),"\n"; $x->length();';
#$rc = eval $try;
#print "# For '$try'\n" if (!ok "$rc" , 4 );

#$x = Dev::Bollocks::from_number("541827");
# print "try: $x ",$x->as_number(),"\n";

##############################################################################
# as_number

$x = Dev::Bollocks->new('adaptively syndicate granular ROI'); 
ok (ref($x->as_number()),'Math::BigInt');

##############################################################################
# numify

$x = Dev::Bollocks->new('adaptively empower systems'); 
ok (ref($x->numify()),''); ok ($x->numify(),4337);

##############################################################################
# rand

$x = Dev::Bollocks->rand(); my $spaces = ($x =~ tr/ / /); ok ($spaces,4);
$x = Dev::Bollocks->rand(3); $spaces = ($x =~ tr/ / /); ok ($spaces,2);
$x = Dev::Bollocks->rand(4); $spaces = ($x =~ tr/ / /); ok ($spaces,3);
$x = Dev::Bollocks->rand(5); $spaces = ($x =~ tr/ / /); ok ($spaces,4);

##############################################################################
# bzero, binf, bnan

$x = Dev::Bollocks->new('paradigmatically infomediaries'); $x->bzero();
ok (ref($x),'Dev::Bollocks'); ok ($x,''); ok ($x->sign(),'+');

$x = Dev::Bollocks->new('adaptively empower systems'); $x->bnan();
ok (ref($x),'Dev::Bollocks'); ok_undef ($x->bstr()); ok ($x->sign(),'NaN');

$x = Dev::Bollocks->new('advantageously disintermediate clusters'); $x->binf();
ok (ref($x),'Dev::Bollocks'); ok_undef ($x->bstr()); ok ($x->sign(),'+inf');

$x = Dev::Bollocks::bzero(); 
ok (ref($x),'Dev::Bollocks'); ok ($x,''); ok ($x->sign(),'+');
$x = Dev::Bollocks::bnan();
ok (ref($x),'Dev::Bollocks'); ok_undef ($x->bstr()); ok ($x->sign(),'NaN');
$x = Dev::Bollocks::binf();
ok (ref($x),'Dev::Bollocks'); ok_undef ($x->bstr()); ok ($x->sign(),'+inf');

##############################################################################
# accuracy/precicison

ok_undef ($Dev::Bollocks::accuracy);
ok_undef ($Dev::Bollocks::precision);
ok ($Dev::Bollocks::fallback,0);
ok ($Dev::Bollocks::rnd_mode,'even');

# all done

###############################################################################
# Perl 5.005 does not like ok ($x,undef)

sub ok_undef
  {
  my $x = shift;

  ok (1,1) and return 1 if !defined $x;
  ok ($x,'undef');
  return 0;
  }

1;
