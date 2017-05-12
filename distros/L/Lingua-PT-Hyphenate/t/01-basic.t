# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 493;
BEGIN { use_ok('Lingua::PT::Hyphenate') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $tests = '
mó du lo
bar ca ça
bo te
cor ti na
gam bas
sub ma ri no
ca ma rão
o ce a no
tes te
mão
li mão
ma ca co
com pu ta dor
pa lha ço
ques tão
ma ri nhei ro
bo tão
for mi guei ro
for mi ga
e le fan te
con ten te
ra to
ra ta za na
a ves truz
co po
a ber to
in fan til
bor bo le ta
em bo ra
ja ne la
ca ne la
con ten ta men to
tes ta men to
li vro
ca ba ça
ca me lo
co lu nas
co lu na
rá di o
te le vi são
me di ca men to
pa ler ma
co le te
ca ma
guar da
fa to
ba nho
ba nhei ra
ar má ri o
mo to ri za da
ca sa co
so bre tu do
por tá til
ca mi sa
ca mi se ta
em pre sa

fan tás ti co
pro gra ma dor
que
faz
es tes
mó du los

al mo çar
can ti na
pão
be bi da
es pí ri to
noi te
dia
co mi da
re fei ção
pa tro cí ni o
eu ro pa
cas te lo
ci ne ma
gran de
co ber tor

se cre tá ria
cor rei o
fac to
er ro
ser ro te

bar ril
rép til
fós sil
fu nil

su ba li men tar
de di car
en car na do
bi sa vô
trans li ne ar
trans mi gra ção
tran sa tlân ti co
cons tar
de sa tar
e xa mi nar
óp ti mo
subs cre ver
ac ção

se guir
pseu dó ni mo
psí qui co
gra ma

a dop tar
jac to
óp ti ca
dis cen te
ad mi nis trar

se cre to
pro cla mar
a pli car
a fro di te
a pron tar
pro ble má ti co
a tle ta
o pró bri o
a trac ção
ne vri te
re pri mir

sub lo car
sub lu nar

sa char
fa lhar
a pa nhar

oc ci são
ac ci o nar
co mum men te
con nos co
nar rar
pas so

con cla mar
em ble má ti co
em pre en der
ex pli car
trans cre ver
in frin gir

subs tan ti vo
ins tá vel
ins pec tor
pers pec ti var
subs ti tu to

guar dar
al guém
i gual
li qui dar
ne guem
pin gue

an dai
jei to so
teus
tro vão

gá ve a
se me ar
bi bli o te ca
es pé ci e
vo ou
ru iu
sai am
sai ais

tran qui li da de
tra di ci o nal
es pe cia li da de
ma ca cos
';

my @tests = map { [split / /, $_] } split /\n/, $tests;

for (@tests) {
  my ($word, @expected) = ((join '', @$_), @$_);
  my @got = hyphenate($word);
  while ($a = shift @got) {
    $b = shift @expected;
    is($a,$b);
  }
  while (@expected) {
    $b = shift @expected;
    is(undef,$b);
  }
}
