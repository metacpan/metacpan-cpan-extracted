BEGIN {
  unshift @INC,'/home/bames/project/MIDI-XML/lib'
}
use strict;
use Tk;
use MIDI::XML::Editor;

my $editor = MIDI::XML::Editor->new();

MainLoop;

