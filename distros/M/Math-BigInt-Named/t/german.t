# -*- mode: perl; -*-

use strict;
use Test;

BEGIN
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 85;
  }

# testing of Math::BigInt::Named::German, primarily for the $x->name() and
# $x->from_name() functionality, and not for the math functionality

use Math::BigInt::Named::German;
use Math::BigInt;

my $c = 'Math::BigInt::Named::German';

###############################################################################
# triple names
my $x = Math::BigInt->bzero();
my $y = Math::BigInt->new(2);

ok ($c->_triple_name(0,$x),'');			# null
ok ($c->_triple_name(2,$x),'');			# null millionen
$x++;
ok ($c->_triple_name(1,$x),'tausend');
my $i = 2;
for (qw/ m b tr quadr pent hex sept oct / )
  {
  ok ($c->_triple_name($i,$x),$_ . 'i' . 'llion');
  ok ($c->_triple_name($i+1,$x),$_ . 'i' . 'lliarde');
  ok ($c->_triple_name($i,$y),$_ . 'i' . 'llionen');
  ok ($c->_triple_name($i+1,$y),$_ . 'i' . 'lliarden');
  $i += 2;
  }

###############################################################################
# assorted names

$x = $c->new(1234);
ok ($x->name(),'ein tausend zweihundertundvierunddreissig'); $x++;
ok ($x->name(),'ein tausend zweihundertundfuenfunddreissig');

while (<DATA>)
  {
  chomp;
  next if /^\s*$/;	# empty lines
  next if /^#/;		# comments
  my @args = split (/:/,$_);

  ok ($c->new($args[0])->name(),$args[1]);
  # ok ($c->from_name($args[1]),$args[0]);
  }


###############################################################################

# nothing valid at all
$x = $c->new('foo'); ok ($x,'NaN');

# done

1;

__END__
0:null
1:eins
-1:minus eins
2:zwei
3:drei
4:vier
5:fuenf
6:sechs
7:sieben
8:acht
9:neun
10:zehn
11:oelf
12:zwoelf
13:dreizehn
14:vierzehn
15:fuenfzehn
16:sechzehn
17:siebzehn
18:achtzehn
19:neunzehn
20:zwanzig
21:einundzwanzig
22:zweiundzwanzig
33:dreiunddreissig
44:vierundvierzig
55:fuenfundfuenfzig
66:sechsundsechzig
77:siebenundsiebzig
88:achtundachtzig
99:neunundneunzig
100:einhundert
200:zweihundert
300:dreihundert
400:vierhundert
500:fuenfhundert
600:sechshundert
700:siebenhundert
800:achthundert
900:neunhundert
1000:ein tausend
101:einhundertundeins
202:zweihundertundzwei
1001:ein tausend eins
1002:ein tausend zwei
1102:ein tausend einhundertundzwei
1122:ein tausend einhundertundzweiundzwanzig
