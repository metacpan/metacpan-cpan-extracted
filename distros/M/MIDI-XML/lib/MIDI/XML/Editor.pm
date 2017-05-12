package MIDI::XML::Editor;
use strict;
use 5.006;
use Tk 800.000;
use Tk::Tree;
use Carp;
#use XML::DOM;
#use XML::Parser;
#use Class::ISA;
use MIDI::XML;

our @ISA = qw();

our @EXPORT = qw();
our @EXPORT_OK = qw();

our $VERSION = 0.01;

=head1 NAME

MIDI::XML::Editor - Module for editing MIDI XML Document objects.

=head1 DESCRIPTION



=cut

#===============================================================================

sub _bind_message {
  my ($self, $widget, $msg) = @_;
  $widget->bind('<Enter>', sub { $self->{'_status_msg'} = $msg;});
  $widget->bind('<Leave>', sub { $self->{'_status_msg'} = "" ; });
}

#===============================================================================

sub _tree_click {
  my $self = shift @_;
  my $path = shift @_;
  
  print "$path clicked";
  my $tree_nodes = $self->{'_tree_nodes'};
  if(exists($tree_nodes->{$path})) {
    if($path =~ /^t\.[a-z]+\.\d+$/) {
      my ($time,$denom_ticks,$divs) = @{$tree_nodes->{$path}};
      print " = ($time,$denom_ticks,$divs)";
    }
  }
  print "\n";
}

#===============================================================================

sub _refresh ($) {
  my $self = shift @_;
  my $document = shift @_;
  
  my $tree_nodes = {};
  $self->{'_document'} = $document;
  my $model = $document->getDocumentElement();
  $self->{'_model'} = $model;
  $self->{'_format'} = $model->Format();
  $self->{'_ticksPerBeat'} = $model->TicksPerBeat();
  $self->{'_trackCount'} = $model->TrackCount();
  $self->{'_timestampType'} = $model->TimestampType(),
  $self->{'_tree_nodes'} = $tree_nodes;

  my $tree = $self->{'_tree'};

  $tree->delete('all');
  $tree->add('h', -text => 'header');
  $tree->add('t', -text => 'tracks');
  my @tracks = $model->getElementsByTagName('Track');
  my $tno = 'a';
  my $measures = $document->measures();
  foreach my $track (@tracks) {
    my $tname = "track $tno";
    my $tn = $track->name();
    $tname = $tn if(defined($tn));
    $tree->add("t.$tno", -text => $tname);
    $tree->close("t.$tno");
    my $mno=1;
    foreach my $measure (@{$measures}) {
      my $path = "t.$tno.$mno";
      $tree->add($path, -text => "Meas $mno");
      $mno++;
      $tree_nodes->{$path} = $measure;
    }
    $tno++;
  }
  $tree->autosetmode( );
  my $t_no = 'a';
  foreach my $track (@tracks) {
    $tree->close("t.$t_no");
    $t_no++;
  }
}

#===============================================================================

sub _file_parse {
  my $self = shift @_;
  my $source = shift @_;
  my $document = MIDI::XML->parsefile($source);

  $self->_refresh($document);
}

#===============================================================================

sub _file_read {
  my $self = shift @_;
  my $source = shift @_;
  
  my $pretty = $self->{'_pretty'};
  my $document = MIDI::XML->readfile($source,$pretty);

  $self->_refresh($document);
}

#===============================================================================

sub _file_new {
  my $self = shift @_;
  
  my $source = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    . '<!-- Created by MIDI::XML Version '.$MIDI::XML::VERSION.' -->'
    . '<MIDIFile>'
    . '  <Format>1</Format>'
    . '  <TrackCount>2</TrackCount>'
    . '  <TicksPerBeat>384</TicksPerBeat>'
    . '  <TimestampType>Absolute</TimestampType>'
    . '  <Track Number="0">'
    . '    <Event>'
    . '      <Absolute>0</Absolute>'
    . '      <TrackName>Track 0</TrackName>'
    . '    </Event>'
    . '    <Event>'
    . '      <Absolute>0</Absolute>'
    . '      <TimeSignature MIDIClocksPerMetronomeClick="96" LogDenominator="2" Numerator="4" ThirtySecondsPer24Clocks="8"/>'
    . '    </Event>'
    . '  </Track>'
    . '  <Track Number="0">'
    . '    <Event>'
    . '      <Absolute>0</Absolute>'
    . '      <TrackName>Track 1</TrackName>'
    . '    </Event>'
    . '  </Track>'
    . '</MIDIFile>';

  my $document = MIDI::XML->parse($source);

  $self->_refresh($document);
  
}

#===============================================================================

sub _file_open {
  my $self = shift @_;
  
  my $source = $self->{'_main_w'}->getOpenFile();
  $self->{'_xml_source'} = $source;
  $self->{'_midi_source'} = undef;
  $self->_file_parse($source);
  $self->{'_save_b'}->configure(-state => 'normal');
  $self->{'_status_msg'} = "File $source opened.";
}

#===============================================================================

sub _file_save {
  my $self = shift @_;
  
  my $source = $self->{'_xml_source'};
  $source = $self->{'_main_w'}->getSaveFile() unless (defined($source));
  $self->{'_document'}->printToFile($source);
  $self->{'_status_msg'} = "File $source saved.";
}

#===============================================================================

sub _file_save_as {
  my $self = shift @_;
  
  my $source = $self->{'_main_w'}->getSaveFile();
  $self->{'_xml_source'} = $source;
  $self->{'_document'}->printToFile($source);
  $self->{'_status_msg'} = "File saved as $source.";
}
#===============================================================================

sub _file_import {
  my $self = shift @_;
  my $source = $self->{'_main_w'}->getOpenFile();
  $self->{'_midi_source'} = $source;
  $self->{'_xml_source'} = undef;
  $self->_file_read($source);
  
}

#===============================================================================

sub _file_export {
  my $self = shift @_;
  my $source = $self->{'_main_w'}->getSaveFile();
  $self->{'_midi_source'} = $source;
  $self->{'_document'}->writefile($source);
  
}

#===============================================================================

sub _file_close {
  my $self = shift @_;
  print "File Close\n";
  
}

#===============================================================================

sub _file_exit {
  exit;
}

#===============================================================================
# Create the menu items for the File menu.

sub _file_menuitems {
  my $self = shift @_;

  return 
  [
    ['command', '~New',         '-accelerator'=>'Ctrl-n', '-command' => sub {$self->_file_new;     }],
    '',
    ['command', '~Open',        '-accelerator'=>'Ctrl-o', '-command' => sub {$self->_file_open;    }],
    '',
    ['command', '~Save',        '-accelerator'=>'Ctrl-s', '-command' => sub {$self->_file_save;    }],
    ['command', 'S~ave As ...', '-accelerator'=>'Ctrl-a', '-command' => sub {$self->_file_save_as; }],
    '',
    ['command', '~Import ...',  '-accelerator'=>'Ctrl-i', '-command' => sub {$self->_file_import;  }],
    ['command', '~Export ...',  '-accelerator'=>'Ctrl-e', '-command' => sub {$self->_file_export;  }],               
    '',
    ['command', '~Close',       '-accelerator'=>'Ctrl-w', '-command' => sub {$self->_file_close;   }],               
    '',
    ['command', '~Quit',        '-accelerator'=>'Ctrl-q', '-command' => sub {$self->_file_exit;    }],
  ];

}

#===============================================================================

sub _edit_fix_lyrics {
  my $self = shift @_;
  
#  my @tracks = $model->getElementsByTagName('Track');
  my $model = $self->{'_model'};
  my @lyrics = $model->getElementsByTagName('Lyric');
  foreach my $lyric (@lyrics) {
    my $text = $lyric->text();
    if ($text =~ s/-$//) {
      $lyric->text($text);
    }
    elsif ($text =~ / $/) {
    } else {
      $lyric->text("$text ");
    }
  }
}

#===============================================================================
# Create the menu items for the Edit menu.

sub _edit_menuitems {
my $self = shift @_;
  [
    ['command', '~Fix Lyrics',        '-command' => sub {$self->_edit_fix_lyrics;    }],
    ['command', 'Preferences ...'],
  ];
}

#===============================================================================

sub _insert_measures {
  my $self = shift @_;
  
  my $document = $self->{'_document'};
  my $model = $self->{'_model'};
  my @tracks = $model->getElementsByTagName('Track');
  my $measures = $document->measures();
  foreach my $track (@tracks) {
    my @events = $track->getElementsByTagName('Event');
    my $e_abs = 0;
    my $e = 0;
    my $mno = 0;
#    foreach my $measure (@{$measures}) {
    while (defined($measures->[$mno]) and $e <= $#events) {
      my $measure = $measures->[$mno];
      my $m_abs = $measure->[0];
      my $event = $events[$e];
#      print "$m_abs <= $e_abs\n";
      if ($m_abs <= $e_abs) {
        $mno++;
        my $data = "type=\"measure\" time=\"$m_abs\" number=\"$mno\"";
        my $pi = $document->createProcessingInstruction('midi-xml', $data);
        my $prev = $event->getPreviousSibling();
        $event = $events[$e-1] if ($e > 0); #  and $m_abs == $e_abs
        $track->insertBefore($pi,$event);
        if ($prev->getNodeType == 3) {
          $track->insertBefore($document->createTextNode($prev->getNodeValue()),$event);
        }
      } else {
 #       while ($m_abs > $e_abs) {
          if ($e <= $#events) {
            $event = $events[$e];
            my $timestamp = $event->Timestamp;
            my $value = $timestamp->value();
            my $tsclass = ref($timestamp);
            if ($tsclass eq 'MIDI::XML::Delta') {
              $e_abs += $value;
            } elsif ($tsclass eq 'MIDI::XML::Absolute') {
              $e_abs = $value;
            } else {
              print "\$tsclass = $tsclass\n";
            }
          } else {
            $e_abs = $m_abs;
          }
          $e++;
#        }
      }
    }
  }
}

#===============================================================================
# Create the menu items for the Insert menu.

sub _insert_menuitems {
my $self = shift @_;
  [
    ['command', '~Measures',    '-accelerator'=>'Ctrl-m', '-command' => sub {$self->_insert_measures; }],
  ];
}

#===============================================================================

sub _help_version {
  print "MIDI::XML::Editor Version $VERSION\n";
}

#===============================================================================

sub _help_about {
  print "Help About\n";
}

#===============================================================================
# Create the menu items for the Help menu.

sub _help_menuitems {
my $self = shift @_;
  [
    ['command', 'Version', '-command' => sub {$self->_help_version;}],
    '',
    ['command', 'About',   '-command' => sub {$self->_help_about;}],
  ];
}


#===============================================================================

=head2 $Object = MIDI::XML::Document->new();

Create a new MIDI::XML::Document object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  
  my $self = {};
  bless $self,$class;
  
  $self->{'_status_msg'} = "";
  $self->{'_title'} = 'MIDI XML Editor';
  $self->{'_pretty'} = 1;
  $self->{'_format'} = 99;
  $self->{'_ticksPerBeat'} = 1384;
  $self->{'_trackCount'} = 99;
  $self->{'_timestampType'} ='Absolute_',
  
  my $main_w = MainWindow->new();
  $self->{'_main_w'} = $main_w;
#  $main_w->configure(-width => 600, -height => 800,);
  $main_w->title($self->{'_title'});

#-------------------------------------------------------------------------------
  my $menu_f = $main_w->Frame(
      -relief => 'groove',
      -bd => 2,
    )->grid(
      "-",
      -sticky => "nsew",
    );
    
#$menu_f->Button(-text => "Exit", -command => sub { exit; } )->
#    pack(-side => 'right');
#$menu_f->Button(-text => "Save", -command => \&save_file)->
#    pack(-side => 'right', -anchor => 'e');
#$menu_f->Button(-text => "Load", -command => \&load_file)->
#    pack(-side => 'right', -anchor => 'e');
    
my $file = $menu_f->Menubutton(qw/-text File -underline 0/,
    -menuitems => $self->_file_menuitems);
my $edit = $menu_f->Menubutton(qw/-text Edit -underline 0/,
    -menuitems => $self->_edit_menuitems);
my $insert = $menu_f->Menubutton(qw/-text Insert -underline 0/,
    -menuitems => $self->_insert_menuitems);
my $help = $menu_f->Menubutton(qw/-text Help -underline 0/, 
    -menuitems => $self->_help_menuitems);

# In Unix the Help menubutton is right justified.

$file->pack(qw/-side left/);
$edit->pack(qw/-side left/);
$insert->pack(qw/-side left/);
$help->pack(qw/-side right/);


#  my $menubar = $menu_f->Menu(-type => 'menubar');
#  $menu_f->configure(-menu => $menubar);

#  map {$menubar->cascade( -label => '~' . $_->[0], -menuitems => $_->[1] )}
#      ['File', _file_menuitems],
#      ['Edit', _edit_menuitems],
#      ['Help', _help_menuitems];

#  $self->{'_menu_f'} = $menu_f;
#  $menu_f->Label(
#      -textvariable => \$self->{'_status_msg'},
#    )->pack(
#      -side => 'bottom',
#      -fill => 'x'
#    );

#-------------------------------------------------------------------------------
  my $east_f = $main_w->Frame(
#      -relief => 'groove',
#      -bd => 2,
      -width => 480,
      -height => 600,
    );
  $self->{'_east_f'} = $east_f;

#-------------------------------------------------------------------------------
  my $tree_f = $main_w->Frame(
      -relief => 'groove',
      -bd => 2,
    )->grid(
      $east_f,
      -sticky => "nsew",
    );
  $self->{'_tree_f'} = $tree_f;

#-------------------------------------------------------------------------------
  my $status_f = $main_w->Frame(
      -relief => 'groove',
      -bd => 2,
    )->grid(
      "-",
      -sticky => "nsew",
    );
  $self->{'_status_f'} = $status_f;
  my $status_l = $status_f->Label(
      -textvariable => \$self->{'_status_msg'},
    )->pack(
      -side => 'left',
      -fill => 'x'
    );
  $self->{'_status_l'} = $status_l;
 #-------------------------------------------------------------------------------
  my $object_f = $east_f->Frame(
      -relief => 'groove',
      -bd => 2,
      -width => 480,
      -height => 600,
    )->pack(
      -side => 'top',
      -fill => 'both',
      -expand => 1,
    );
  $self->{'_object_f'} = $object_f;
  
  my $midifile_f = $object_f->Frame(
      -relief => 'flat',
      -bd => 2,
      -width => 480,
      -height => 600,
    )->grid(
      -sticky => "nsew",
    );
  $self->{'_midifile_f'} = $midifile_f;
  
  foreach my $item (
    ['Format', \$self->{'_format'}],
    ['TicksPerBeat', \$self->{'_ticksPerBeat'}],
    ['TrackCount', \$self->{'_trackCount'}],
    ['TimestampType', \$self->{'_timestampType'}],
  ) {
    my $ltxt = $item->[0] . ':';
    my $f = $midifile_f->Frame(
      -width => 400,
    );
    my $e = $midifile_f->Entry(      -relief       => 'groove',
      -state        => 'disabled',
      -textvariable => $item->[1],
      -width        => 10,
      -background   => '#FFFFFF',
      -highlightbackground   => '#FFFFFF',
      -insertbackground   => '#FFFFFF',
      -state        => 'normal',
    );
    my $l = $midifile_f->Label(
      -text => $ltxt, 
      -width => 16,
      -anchor => 'w',
      )->grid(
        $e,
        $f,
        -sticky => "w",
      );
  }
  my $f = $midifile_f->Frame(
      -width => 480,
      -height => 600,
  )->grid('-','-');    

#-------------------------------------------------------------------------------
  my $button_f = $east_f->Frame(
      -relief => 'groove',
      -bd => 2,
    )->pack(
      -side => 'bottom',
      -fill => 'x',
    );
  $self->{'_button_f'} = $button_f;

  my $open_b = $button_f->Button(
      -text => "Open", 
      -command => sub { $self->_file_open(); },
    );
  $self->{'_open_b'} = $open_b;
  $self->_bind_message($open_b, 'Press to open file.');
  
  my $save_b = $button_f->Button(
      -text => "Save",
      -command => sub { $self->_file_save_as(); },
      -state => 'disabled',
  );
  $self->{'_save_b'} = $save_b;
  $self->_bind_message($save_b, 'Press to save file.');
  
  my $exit_b = $button_f->Button(
      -text => "Exit",
      -command => sub { $self->_file_exit(); },
  );
  $self->{'_exit_b'} = $exit_b;
  $self->_bind_message($exit_b, 'Press to exit editor.');
  $open_b->grid(
      $save_b,
      $exit_b,
      -padx => 2,
      -pady => 2,
    );

  my $tree = $tree_f->Scrolled(
      "Tree",
      -width => 32,
#      -height => 600,
      -command => sub {$self->_tree_click(@_);},
  )->pack(
      -fill => 'both',
      -expand => 1,
    );
  $self->{'_tree'} = $tree;

  foreach (qw/header track track.one track.one.m1 track.one.m2 track.one.m3 track.two track.three track.four/) {
    $tree->add($_, -text => $_);
  }

  $tree->autosetmode( );

  MainLoop;
  return $self;
}


