BEGIN {
  unshift @INC,'/home/bames/project/MIDI-XML/lib'
}

use strict;
use 5.006;
use Tk 800.000;
use Tk::Tree;
use Carp;
use MIDI::XML;

my $document = MIDI::XML->readfile('test_src/test.mid',1);
my @elems = $document->getElementsByTagName('*');

$document = MIDI::XML->parsefile('test_src/test.xml');
@elems = $document->getElementsByTagName('*');

$document = MIDI::XML->readfile('test_src/h16128.mid',1);
@elems = $document->getElementsByTagName('*');

$document = MIDI::XML->parsefile('test_src/h16128.xml');
@elems = $document->getElementsByTagName('*');

