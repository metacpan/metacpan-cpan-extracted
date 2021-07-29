#!perl

use strict;
use warnings;

use Test::More;

plan tests => 55;

use Math::BigInt::Named;

###############################################################################
# assorted names

while (<DATA>) {
    chomp;
    next if !/\S/;              # skip empty lines
    next if /^#/;               # skip comment lines
    my @args = split /:/;

    my $obj      = Math::BigInt::Named -> new($args[0]);
    my $got      = $obj -> name(language => "no");
    my $expected = $args[1];
    my $test     = $args[0] . " -> " . $args[1];
    is($got, $expected, $test);
    # is($class -> from_name($args[1]), $args[0]);
}

###############################################################################

# nothing valid at all
my $x = Math::BigInt::Named -> new('foo');
is($x -> name(language => "norwegian"), 'NaN', "foo -> NaN");

__END__
0:null
-1:minus en
2:to
3:tre
4:fire
5:fem
6:seks
7:syv
8:åtte
9:ni
10:ti
11:elleve
12:tolv
13:tretten
14:fjorten
15:femten
16:seksten
17:sytten
18:atten
19:nitten
20:tjue
21:tjueen
22:tjueto
33:trettitre
44:førtifire
55:femtifem
66:sekstiseks
77:syttisyv
88:åttiåtte
99:nittini

100:ett hundre
200:to hundre
300:tre hundre
400:fire hundre
500:fem hundre
600:seks hundre
700:sju hundre
800:åtte hundre
900:ni hundre

101:ett hundre og en
202:to hundre og to

1001:ett tusen og en
1002:ett tusen og to
1098:ett tusen og nittiåtte
1099:ett tusen og nittini
1100:ett tusen ett hundre
1101:ett tusen ett hundre og en
1102:ett tusen ett hundre og to
1122:ett tusen ett hundre og tjueto

1000000:en million
1000001:en million og en
1000100:en million ett hundre

2000000:to millioner
2003000000:to milliarder tre millioner
