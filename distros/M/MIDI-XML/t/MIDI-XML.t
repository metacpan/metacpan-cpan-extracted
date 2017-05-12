# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MIDI-XML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('MIDI::XML') };

BEGIN { use_ok('MIDI::XML::Editor') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use 5.006;
use Tk 800.000;
use Tk::Tree;
use Carp;
use MIDI::XML;

my $document = MIDI::XML->readfile('test_src/test.mid',1);
my @elems = $document->getElementsByTagName('*');
ok($#elems == 2244, "  element count for test.mid: $#elems == 2244");

$document->printToFile('test_src/test.xml');

$document = MIDI::XML->parsefile('test_src/test.xml');
@elems = $document->getElementsByTagName('*');
ok($#elems == 2244, "  element count for test.xml: $#elems == 2244");

$document = MIDI::XML->readfile('test_src/h16128.mid',1);
@elems = $document->getElementsByTagName('*');
ok($#elems == 15814, "  element count for h16128.mid: $#elems == 15814");

$document->printToFile('test_src/h16128.xml');

$document = MIDI::XML->parsefile('test_src/h16128.xml');
@elems = $document->getElementsByTagName('*');
ok($#elems == 15814, "  element count for h16128.xml: $#elems == 15814");

