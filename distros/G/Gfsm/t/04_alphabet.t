# -*- Mode: CPerl -*-

$TEST_DIR = './t';
#use lib qw(../blib/lib ../blib/arch); $TEST_DIR = '.'; # for debugging

# load common subs
do "$TEST_DIR/common.plt"
  or die("could not load $TEST_DIR/common.plt");

plan(test => 25);

# load modules
use Gfsm;

##-- 1: new()
evalok('$abet=Gfsm::Alphabet->new();');

##-- 2..5: insert pairs
evalok("\$abet->insert('<eps>')==0;");
evalok("\$abet->insert('a')==1;");
evalok("\$abet->insert('a',3)==3;");
evalok("\$abet->insert('a',1)==1;");

##-- 6..10 : get labels
evalok("\$abet->find_label('<eps>')==0;");
evalok("\$abet->find_label('a')==1;");
evalok("\$abet->get_label('a')==1;");
evalok("\$abet->find_label('b')==Gfsm::noLabel;");
evalok("(\$blab=\$abet->get_label('b'))!=Gfsm::noLabel;");

##-- 11..13 : get keys
evalok("\$abet->find_key(0) eq '<eps>';");
evalok("\$abet->find_key(1) eq 'a';");
evalok("\$abet->find_key(\$blab) eq 'b';");

##-- 14..15: remove
evalok("\$abet->remove_key('b');
        \$abet->find_label('b')==Gfsm::noLabel && !defined(\$abet->find_key(\$blab))");

evalok("\$abet->remove_label(1);
        \$abet->find_label('a')==Gfsm::noLabel && !defined(\$abet->find_key(1))");

##-- 16: clear, size
evalok("\$abet->clear(); \$abet->size==0;");

##-- 17--19: size, lab_min, lab_max
$abet->insert($_) foreach ('<eps>', qw(a b c));
evalok('$abet->size==4');
evalok('$abet->lab_min==0');
evalok('$abet->lab_max==3');

##-- 20: merge, size
$abet2 = Gfsm::Alphabet->new();
$abet2->insert($_) foreach ('<eps>', qw(d e f   a b c));
evalok('$abet->merge($abet2); $abet->size==7;');

##-- 21: remove, labels
$abet->remove_label(0);
evalok('join(" ", @{$abet->labels}) eq "1 2 3 4 5 6";');

##-- 22..23: save, integrity
$abet->clear;
$abet->insert($_) foreach ('<eps>', qw(a b c d e f foo bar baz bonk));

evalok("\$abet->save('$TEST_DIR/tmp.lab');");
fileok("$TEST_DIR/tmp.lab", "$TEST_DIR/test.lab");

##-- 24..25: load, integrity
evalok("\$abet2->clear; \$abet2->load('$TEST_DIR/tmp.lab');");
codeok("loaded $TEST_DIR/tmp.lab ; equivalence-check",
       sub {
	 foreach $lab (@{$abet2->labels}) {
	   return 0 if ($abet2->find_key($lab) ne $abet->find_key($lab));
	 }
	 foreach $lab (@{$abet->labels}) {
	   return 0 if ($abet2->find_key($lab) ne $abet->find_key($lab));
	 }
	 return 1;
       });

##-- xxx 26..28 xxx: string_to_labels, labels_to_string
if (0) {
  evalok('join(" ", @{$abet->string_to_labels("abc")}) eq "1 2 3";');
  evalok('$abet->labels_to_string([4,5,6],1,0) eq "d e f";');
  evalok('$abet->labels_to_string([4,5,6],1,1) eq "def";');
}

print "\n";


