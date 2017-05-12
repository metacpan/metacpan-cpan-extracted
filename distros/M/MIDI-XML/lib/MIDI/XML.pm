package MIDI::XML;
use strict;
use 5.006;
use Carp;
use XML::DOM;
use XML::Parser;
use Class::ISA;

our @ISA = qw();

our @EXPORT = qw();
our @EXPORT_OK = qw();

our $VERSION = 0.03;

=head1 NAME

MIDI::XML - Module for representing MIDI-XML objects.

=head1 SYNOPSIS

  use MIDI::XML;
  $document = MIDI::XML->parsefile($file);

=head1 DESCRIPTION



=head2 EXPORT

None by default.

=cut

my %sax_handlers = (
  'Init'         => \&handle_init,
  'Final'        => \&handle_final,
  'Start'        => \&handle_start,
  'End'          => \&handle_end,
  'Char'         => \&handle_char,
  'Proc'         => \&handle_proc,
  'Comment'      => \&handle_comment,
  'CdataStart'   => \&handle_cdata_start,
  'CdataEnd'     => \&handle_cdata_end,
  'Default'      => \&handle_default,
  'Unparsed'     => \&handle_unparsed,
  'Notation'     => \&handle_notation,
  'ExternEnt'    => \&handle_extern_ent,
  'ExternEntFin' => \&handle_extern_ent_fin,
  'Entity'       => \&handle_entity,
  'Element'      => \&handle_element,
  'Attlist'      => \&handle_attlist,
  'Doctype'      => \&handle_doctype,
  'DoctypeFin'   => \&handle_doctype_fin,
  'XMLDecl'      => \&handle_xml_decl,
);

my @elem_stack;

my $Document;

my %attributeAsElement = (
  'Absolute' => 1,
  'Delta' => 1,
  'Format' => 1,
  'FrameRate' => 1,
  'TicksPerBeat' => 1,
  'TicksPerFrame' => 1,
  'TimestampType' => 1,
  'TrackCount' => 1,
);

#=================================================================

# Init              (Expat)
sub handle_init() {
  my ($expat) = @_;
  $Document = MIDI::XML::Document->new();
  push @elem_stack,$Document;
}

#=================================================================

# Final             (Expat)
sub handle_final() {
  my ($expat) = @_;
}

#=================================================================

# Start             (Expat, Tag [, Attr, Val [,...]])
sub handle_start() {
  my ($expat, $tag, %attrs) = @_;

  my $Element = $Document->createElement($tag);
  foreach my $attr (keys %attrs) {
    $Element->setAttribute($attr,$attrs{$attr});
  }
  if($attributeAsElement{$tag}) {
    $elem_stack[-1]->attribute_as_element($tag,$Element) if(@elem_stack);
  } else {
    $elem_stack[-1]->appendChild($Element) if(@elem_stack);
  }
  push @elem_stack,$Element;
}

#=================================================================

# End               (Expat, Tag)
sub handle_end() {
  my ($expat, $tag) = @_;
  my $Element = pop @elem_stack;
}

#=================================================================

# Char              (Expat, String)
sub handle_char() {
  my ($expat, $string) = @_;
  $elem_stack[-1]->appendChild($Document->createTextNode($string));
}

#=================================================================

# Proc              (Expat, Target, Data)
sub handle_proc() {
  my ($expat, $target, $data) = @_;
  $elem_stack[-1]->appendChild($Document->createProcessingInstruction($target, $data));
}

#=================================================================

# Comment           (Expat, Data)
sub handle_comment() {
  my ($expat, $data) = @_;
  $elem_stack[-1]->appendChild($Document->createComment($data));
}

#=================================================================

# CdataStart        (Expat)
sub handle_cdata_start() {
  my ($expat) = @_;
}

#=================================================================

# CdataEnd          (Expat)
sub handle_cdata_end() {
  my ($expat) = @_;
}

#=================================================================

# Default           (Expat, String)
sub handle_default() {
  my ($expat, $string) = @_;
}

#=================================================================

# Unparsed          (Expat, Entity, Base, Sysid, Pubid, Notation)
sub handle_unparsed() {
  my ($expat, $entity, $base, $sysid, $pubid, $notation) = @_;
}

#=================================================================

# Notation          (Expat, Notation, Base, Sysid, Pubid)
sub handle_notation() {
  my ($expat, $notation, $base, $sysid, $pubid) = @_;
}

#=================================================================

# ExternEnt         (Expat, Base, Sysid, Pubid)
sub handle_extern_ent() {
  my ($expat, $base, $sysid, $pubid) = @_;
}

#=================================================================

# ExternEntFin      (Expat)
sub handle_extern_ent_fin() {
  my ($expat) = @_;
}

#=================================================================

# Entity            (Expat, Name, Val, Sysid, Pubid, Ndata, IsParam)
sub handle_entity() {
  my ($expat, $name, $val, $sysid, $pubid, $ndata, $isParam) = @_;
}

#=================================================================

# Element           (Expat, Name, Model)
sub handle_element() {
  my ($expat, $name, $model) = @_;
}

#=================================================================

# Attlist           (Expat, Elname, Attname, Type, Default, Fixed)
sub handle_attlist() {
  my ($expat, $elname, $attname, $type, $default, $fixed) = @_;
}

#=================================================================

# Doctype           (Expat, Name, Sysid, Pubid, Internal)
sub handle_doctype() {
  my ($expat, $name, $sysid, $pubid, $internal) = @_;
}

#=================================================================

# DoctypeFin        (Expat)
sub handle_doctype_fin() {
  my ($expat) = @_;
}

#=================================================================

# XMLDecl           (Expat, Version, Encoding, Standalone)
sub handle_xml_decl() {
  my ($expat, $version, $encoding, $standalone) = @_;
}

#=================================================================

=item $Document = MIDI::XML->parse($string);

This method is used to parse an existing MIDI XML file and create 
a DOM tree. Calls XML::Parser->parse with the given string and 
the MIDI::XML handlers.  A DOM Document containing a tree of DOM 
objects is returned. Comments, processing instructions, and notations,
are discarded.  White space is retained.

=cut

sub parse($) {
  my $self = shift @_;
  my $source = shift @_;

  undef $Document;
  my $Parser = new XML::Parser('Handlers' => \%sax_handlers);
  $Parser->parse($source);
  return $Document;
}

#=================================================================

=item $Document = MIDI::XML->parsefile($path);

This method is used to parse an existing MIDI XML file and create 
a DOM tree. Calls XML::Parser->parsefile with the given path and 
the MIDI::XML handlers.  A DOM Document containing a tree of DOM 
objects is returned. Comments, processing instructions, and notations,
are discarded.  White space is retained.

=cut

sub parsefile($) {
  my $self = shift @_;
  my $source = shift @_;

  undef $Document;
  my $Parser = new XML::Parser('Handlers' => \%sax_handlers);
  $Parser->parsefile($source);
  return $Document;
}

#===============================================================================

=item $Document = MIDI::XML->readfile($path,[$pretty]);

This method is used to read an existing Standard MIDI XML file and create a DOM 
tree. It reads the file at the given path and creates SAX events which are 
directed to the MIDI::XML handlers.  A DOM Document containing a tree of DOM 
objects is returned. White space is inserted to produce "pretty" output if the 
optional $pretty argument is non-zero.

=cut

sub readfile($) {
  my $self = shift @_;
  my $source = shift @_;
  
  my $pretty = 1 if (@_ and $_[0] != 0);
  undef $Document;
  my $err = 0;
  open MIDI,'<',$source or $err = 1;
  if ($err) {
    carp "Error opening file $source"; 
    return undef;
  } 
  my $buf;
  read MIDI,$buf,4;
  unless ($buf eq 'MThd') {
    carp "Not a valid MIDI file: $source"; 
    return undef;
  }
  read MIDI,$buf,4;
  my $hsize = unpack('N',$buf);
  
  read MIDI,$buf,$hsize;
  my ($format, $trackCount, $frames, $ticks);
  ($format, $trackCount, $ticks) = unpack('nnn',$buf);
  if ($ticks < 0) {
    ($format, $trackCount, $frames, $ticks) = unpack('nnCC',$buf);
    $frames = -$frames;
  }
  
  $sax_handlers{'Init'}->(undef); # if (exists($sax_handlers{'Init'}));
  $sax_handlers{'XMLDecl'}->(undef, '1.0', 'UTF-8', 'yes') if (exists($sax_handlers{'XMLDecl'}));
  $sax_handlers{'Comment'}->(undef, " Created by MIDI::XML Version $MIDI::XML::VERSION ");
  if (exists($sax_handlers{'Start'}) and exists($sax_handlers{'End'})) {
    my $start = $sax_handlers{'Start'};
    my $end = $sax_handlers{'End'};
    my $char = $sax_handlers{'Char'};
    $start->(undef, 'MIDIFile');
    $char->(undef, "\n  ") if ($pretty);
    
    $start->(undef, 'Format');
    $char->(undef, $format);
    $end->(undef, 'Format');
    $char->(undef, "\n  ") if ($pretty);

    $start->(undef, 'TrackCount');
    $char->(undef, $trackCount);
    $end->(undef, 'TrackCount');
    $char->(undef, "\n  ") if ($pretty);

    $start->(undef, 'TicksPerBeat');
    $char->(undef, $ticks);
    $end->(undef, 'TicksPerBeat');
    $char->(undef, "\n  ") if ($pretty);

    $start->(undef, 'TimestampType');
    $char->(undef, 'Absolute');
    $end->(undef, 'TimestampType');
    
#    $sax_handlers{'Proc'}->(undef, 'midi-xml', 'Start of tracks');
    my $byte;
    for my $t (1..$trackCount) {
      read MIDI,$buf,4;
      unless ($buf eq 'MTrk') {
        carp "Not a valid MIDI file: $source"; 
        return undef;
      }
      read MIDI,$buf,4;
      my $tsize = unpack('N',$buf);
      read MIDI,$buf,$tsize;
      
      $char->(undef, "\n  ") if ($pretty);
      $start->(undef, 'Track', 'Number', $t-1);
      
      my $rstatus = 0;
      my $i = 0;
      my $abs_time = 0;
      my $status;
      my $r_status;
      while ($i < length($buf)) {
        $byte = ord(substr($buf,$i));
#        print "$t $i $byte\n";
        $i += 1;
        my $time = $byte & 0x7F;
        while ($byte > 127) {
          $byte = ord(substr($buf,$i));
          $i += 1;
          $time <<= 7;
          $time |= $byte & 0x7F;
        }
        $abs_time += $time;
        $char->(undef, "\n    ") if ($pretty);
        $start->(undef, 'Event');
        $char->(undef, "\n      ") if ($pretty);
        $start->(undef, 'Absolute');
        $char->(undef, $abs_time);
        $end->(undef, 'Absolute');
        $char->(undef, "\n      ") if ($pretty);
        $byte = ord(substr($buf,$i));
        if ($byte > 127) {
          $status = $byte;
          $i += 1;
          $r_status = $status;
        } else {
          $status = $r_status;
        }
        my $command;
        my $channel;
        if ($status > 0x7f and $status < 0xf0) {
          $command = $status & 0xf0;
          $channel = ($status & 0x0f) + 1;
        } else {
          $command = $status;
        }
        if($status < 0x80) {
          carp "bad status $status";
        } elsif ($command == 0x80) {
          my $note = ord(substr($buf,$i));
          $i += 1;
          my $velocity = ord(substr($buf,$i));
          $i += 1;
          $start->(undef, 'NoteOff','Channel', $channel, 'Note', $note, 'Velocity', $velocity);
          $end->(undef, 'NoteOff');
        } elsif ($command == 0x90) {
          my $note = ord(substr($buf,$i));
          $i += 1;
          my $velocity = ord(substr($buf,$i));
          $i += 1;
          if ($velocity == 0) {
            $start->(undef, 'NoteOff','Channel', $channel, 'Note', $note, 'Velocity', $velocity);
            $end->(undef, 'NoteOff');
          } else {
            $start->(undef, 'NoteOn','Channel', $channel, 'Note', $note, 'Velocity', $velocity);
            $end->(undef, 'NoteOn');
          }
        } elsif ($command == 0xA0) {
          my $note = ord(substr($buf,$i));
          $i += 1;
          my $pressure = ord(substr($buf,$i));
          $i += 1;
          $start->(undef, 'PolyKeyPressure','Channel', $channel, 'Note', $note, 'Pressure', $pressure);
          $end->(undef, 'PolyKeyPressure');
        } elsif ($command == 0xB0) {
          my $control = ord(substr($buf,$i));
          $i += 1;
          my $value = ord(substr($buf,$i));
          $i += 1;
          if ($control == 120) {
           $start->(undef, 'AllSoundOff','Channel', $channel);
           $end->(undef, 'AllSoundOff');
          }
          elsif ($control == 121) {
           $start->(undef, 'ResetAllControllers','Channel', $channel);
           $end->(undef, 'ResetAllControllers');
          }
          elsif ($control == 122) {
           $start->(undef, 'LocalControl','Channel', $channel, 'Value', $value); 
           $end->(undef, 'LocalControl');
          }
          elsif ($control == 123) {
           $start->(undef, 'AllNotesOff','Channel', $channel);
           $end->(undef, 'AllNotesOff');
          }
          elsif ($control == 124) {
           $start->(undef, 'OmniOff','Channel', $channel);
           $end->(undef, 'OmniOff');
          }
          elsif ($control == 125) {
           $start->(undef, 'OmniOn','Channel', $channel);
           $end->(undef, 'OmniOn');
          }
          elsif ($control == 126) {
           $start->(undef, 'MonoMode','Channel', $channel, 'Value', $value);
           $end->(undef, 'MonoMode');
          }
          elsif ($control == 127) {
           $start->(undef, 'PolyMode','Channel', $channel);
           $end->(undef, 'PolyMode');
          } else {
            $start->(undef, 'ControlChange','Channel', $channel, 'Control', $control, 'Value', $value);
            $end->(undef, 'ControlChange');
          }
        } elsif ($command == 0xC0) {
          my $number = ord(substr($buf,$i));
          $i += 1;
          $start->(undef, 'ProgramChange','Channel', $channel, 'Number', $number);
          $end->(undef, 'ProgramChange');
        } elsif ($command == 0xD0) {
          my $pressure = ord(substr($buf,$i));
          $i += 1;
          $start->(undef, 'ChannelKeyPressure','Channel', $channel, 'Pressure', $pressure);
          $end->(undef, 'ChannelKeyPressure');
        } elsif ($command == 0xE0) {
          my $hi = ord(substr($buf,$i));
          $i += 1;
          my $lo = ord(substr($buf,$i));
          $i += 1;
          my $value = ($hi << 7) + $lo;
          $start->(undef, 'PitchBendChange','Channel', $channel, 'Value', $value);
          $end->(undef, 'PitchBendChange');

        } elsif ($status == 0xF0 or $status == 0xF7) {
          $byte = ord(substr($buf,$i));
          my $dl = $byte & 0x7F;
          $i += 1;
          while($byte > 127) {
            $byte = ord(substr($buf,$i));
            $i += 1;
            $dl <<= 7;
            $dl |= $byte & 0x7F;
          }
          my @data;
          while ($dl > 0) {
            $byte = ord(substr($buf,$i));
            $i += 1;
            push @data,sprintf("%02x",$byte);
            $dl -= 1;
          }
          $start->(undef, 'SysEx');
          $char->(undef, join(' ',@data));
          $end->(undef, 'SysEx');
        } elsif ($status == 0xF1) {
          my $position = ord(substr($buf,$i));
          $i += 1;
          $start->(undef, 'SongPositionPointer','Position', $position);
          $end->(undef, 'SongPositionPointer');
        } elsif ($status == 0xF2) {
          my $hi = ord(substr($buf,$i));
          $i += 1;
          my $lo = ord(substr($buf,$i));
          $i += 1;
          my $number = ($hi << 7) + $lo;
          $start->(undef, 'SongSelect','Number', $number);
          $end->(undef, 'SongSelect');
        } elsif ($status == 0xF3) { #MTCQuarterFrame
          $byte = ord(substr($buf,$i));
          $i += 1;
          my $messageType = $byte >> 4;
          my $dataNibble = $byte & 0x07;
          $start->(undef, 'MTCQuarterFrame','MessageType',$messageType,'DataNibble',$dataNibble);
          $end->(undef, 'MTCQuarterFrame');
        } elsif ($status == 0xF6) {
          $start->(undef, 'TuneRequest');
          $end->(undef, 'TuneRequest');
        } elsif ($status == 0xF8) {
          $start->(undef, 'TimingClock');
          $end->(undef, 'TimingClock');
        } elsif ($status == 0xFA) {
          $start->(undef, 'Start');
          $end->(undef, 'Start');
        } elsif ($status == 0xFB) {
          $start->(undef, 'Continue');
          $end->(undef, 'Continue');
        } elsif ($status == 0xFC) {
          $start->(undef, 'Stop');
          $end->(undef, 'Stop');
        } elsif ($status == 0xFE) {
          $start->(undef, 'ActiveSensing');
          $end->(undef, 'ActiveSensing');
        } elsif ($status == 0xFF) {
          # On the wire = SystemReset else MetaEvent
          my $meta = ord(substr($buf,$i));
          $i += 1;
          $byte = ord(substr($buf,$i));
          $i += 1;
          my $dl = $byte & 0x7F;
          while($byte > 127) {
            $byte = ord(substr($buf,$i));
            $i += 1;
            $dl <<= 7;
            $dl |= $byte & 0x7F;
          }
          if($meta >0 and $meta < 10) {
            my $text = substr($buf,$i,$dl);
            $i += $dl;
            if($meta == 1) {
              $start->(undef, 'TextEvent');
              $char->(undef, $text);
              $end->(undef, 'TextEvent');
            }
            elsif($meta == 2) {
              $start->(undef, 'CopyrightNotice');
              $char->(undef, $text);
              $end->(undef, 'CopyrightNotice');
            }
            elsif($meta == 3) {
              $start->(undef, 'TrackName');
              $char->(undef, $text);
              $end->(undef, 'TrackName');
            }
            elsif($meta == 4) {
              $start->(undef, 'InstrumentName');
              $char->(undef, $text);
              $end->(undef, 'InstrumentName');
            }
            elsif($meta == 5) {
              $start->(undef, 'Lyric');
              $char->(undef, $text);
              $end->(undef, 'Lyric');
            }
            elsif($meta == 6) {
              $start->(undef, 'Marker');
              $char->(undef, $text);
              $end->(undef, 'Marker');
            }
            elsif($meta == 7) {
              $start->(undef, 'CuePoint');
              $char->(undef, $text);
              $end->(undef, 'CuePoint');
            }
            elsif($meta == 8) {
              $start->(undef, 'ProgramName');
              $char->(undef, $text);
              $end->(undef, 'ProgramName');
            }
            elsif($meta == 9) {
              $start->(undef, 'DeviceName');
              $char->(undef, $text);
              $end->(undef, 'DeviceName');
            }
          } 
          elsif($meta == 0 or $meta == 0x20 or $meta == 0x21 
             or $meta == 0x2f or $meta == 0x51 or $meta == 0x54 
             or $meta == 0x58 or $meta == 0x59) {
            my @data;
            for my $j (1..$dl) {
              $byte = ord(substr($buf,$i));
              $i += 1;
              push @data,$byte;
            }
            if($meta == 0) {
              $start->(undef, 'SequenceNumber', 'Value', $data[0]<<8 + $data[1]);
              $end->(undef, 'SequenceNumber');
            }
            elsif($meta == 0x20) {
              $start->(undef, 'MIDIChannelPrefix', 'Value', $data[0]);
              $end->(undef, 'MIDIChannelPrefix');
            }
            elsif($meta == 0x21) {
              $start->(undef, 'Port', 'Value', $data[0]);
              $end->(undef, 'Port');
            }
            elsif($meta == 0x2f) {
              $start->(undef, 'EndOfTrack');
              $end->(undef, 'EndOfTrack');
            }
            elsif($meta == 0x51) {
              my $value = ($data[0]<<16) + ($data[1]<<8) + $data[2];
              $start->(undef, 'SetTempo', 'Value', $value);
              $end->(undef, 'SetTempo');
            }
            elsif($meta == 0x54) {
              my $timeCodeType = ($data[0] >> 5) & 0x03;
	            my $hour = $data[0] & 0x1F;
	            my $minute = $data[1];
	            my $second = $data[2];
	            my $frame = $data[3];
	            my $fractionalFrame = $data[4];
              $start->(undef, 'SMPTEOffset','TimeCodeType',$timeCodeType,
	                            'Hour',$hour,
	                            'Minute',$minute,
	                            'Second',$second,
	                            'Frame',$frame,
	                            'FractionalFrame',$fractionalFrame);
              $end->(undef, 'SMPTEOffset');
            }
            elsif($meta == 0x58) {
              $start->(undef, 'TimeSignature','Numerator',$data[0],
                 'LogDenominator',$data[1],
                 'MIDIClocksPerMetronomeClick',$data[2],
                 'ThirtySecondsPer24Clocks',$data[3]);
              $end->(undef, 'TimeSignature');
            }
            elsif($meta == 0x59) {
              my $fifths = $data[0];
              $fifths -= 256 if ($fifths > 127);
              my $mode = $data[1];
              $start->(undef, 'KeySignature','Fifths',$fifths,'Mode',$mode);
              $end->(undef, 'KeySignature');
            }
          } else {
            my @data;
            while ($dl > 0) {
              $byte = ord(substr($buf,$i));
              $i += 1;
              push @data,sprintf("%02x",$byte);
              $dl -= 1;
            }
            if($meta == 0x7f ) {
              $start->(undef, 'SequencerSpecific');
              $char->(undef, join(' ',@data));
              $end->(undef, 'SequencerSpecific');
            } else {
              $start->(undef, 'OtherMetaEvent');
              $char->(undef, join(' ',@data));
              $end->(undef, 'OtherMetaEvent');
            }
          }
				}
        $char->(undef, "\n    ") if ($pretty);
        $end->(undef, 'Event');
			}
      $char->(undef, "\n  ") if ($pretty);
      $end->(undef, 'Track');
    }
    $char->(undef, "\n") if ($pretty);
    $end->(undef, 'MIDIFile');
  }
  
  close MIDI;
  
  return $Document;
}

#===============================================================================
{
  package XML::DOM::Implementation;

  sub createDocument() {
    my $self = shift;

    my $doc = new XML::DOM::Document();
    my $xmlDecl = $doc->createXMLDecl('1.0','UTF-8','yes');
    $doc->setXMLDecl($xmlDecl);
    my $ns;
    my $qname;
    my $doctype;
    if (@_) {
      $ns = shift;
    }
    if (@_) {
      $qname = shift;
    }
    if (@_) {
      $doctype = shift;
    }
    if (defined($qname)) {
      my $element = $doc->createElement($qname);
      $doc->appendChild($element);
    }
    return $doc;
  }
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 

package MIDI::XML::Document;

use Carp;

our @ISA = qw(XML::DOM::Document);
our @EXPORT = qw();
our @EXPORT_OK = qw();

BEGIN
{
    import XML::DOM::Node qw( :Fields );
}

=head1 NAME

MIDI::XML::Document - Module for representing Document objects.

=head1 DESCRIPTION of Document


=cut

#===============================================================================

=head2 $Object = MIDI::XML::Document->new();

Create a new MIDI::XML::Document object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;

  my $qname;
  if (@_) {
    $qname = shift;
  }

  my $self = XML::DOM::Document::new($class);
  my $xmlDecl = $self->createXMLDecl('1.0','UTF-8','yes');
  $self->setXMLDecl($xmlDecl);
  if (defined($qname)) {
    my $element = $self->createElement($qname);
    $self->appendChild($element);
  }
  $self->[_UserData] = {};
#  $self->[_UserData]{'_measures'} = [];
  return $self;
}

our %tag_map = (
  'Absolute'                          => 'MIDI::XML::Absolute',
  'ActiveSensing'                     => 'MIDI::XML::ActiveSensing',
  'AllNotesOff'                       => 'MIDI::XML::AllNotesOff',
  'AllSoundOff'                       => 'MIDI::XML::AllSoundOff',
  'ChannelKeyPressure'                => 'MIDI::XML::ChannelKeyPressure',
  'Continue'                          => 'MIDI::XML::Continue',
  'ControlChange'                     => 'MIDI::XML::ControlChange',
  'ControlChange14'                   => 'MIDI::XML::ControlChange14',
  'CopyrightNotice'                   => 'MIDI::XML::CopyrightNotice',
  'CuePoint'                          => 'MIDI::XML::CuePoint',
  'Delta'                             => 'MIDI::XML::Delta',
  'DeviceName'                        => 'MIDI::XML::DeviceName',
  'EndOfExclusive'                    => 'MIDI::XML::EndOfExclusive',
  'EndOfTrack'                        => 'MIDI::XML::EndOfTrack',
  'Event'                             => 'MIDI::XML::Event',
  'Format'                            => 'MIDI::XML::Format',
  'FrameRate'                         => 'MIDI::XML::FrameRate',
  'InstrumentName'                    => 'MIDI::XML::InstrumentName',
  'KeySignature'                      => 'MIDI::XML::KeySignature',
  'LocalControl'                      => 'MIDI::XML::LocalControl',
  'Lyric'                             => 'MIDI::XML::Lyric',
  'Marker'                            => 'MIDI::XML::Marker',
  'MIDIChannelPrefix'                 => 'MIDI::XML::MIDIChannelPrefix',
  'MIDIFile'                          => 'MIDI::XML::MIDIfile',
  'MonoMode'                          => 'MIDI::XML::MonoMode',
  'MTCQuarterFrame'                   => 'MIDI::XML::MTCQuarterFrame',
  'NoteOff'                           => 'MIDI::XML::NoteOff',
  'NoteOn'                            => 'MIDI::XML::NoteOn',
  'NRPNChange'                        => 'MIDI::XML::NRPNChange',
  'OmniOff'                           => 'MIDI::XML::OmniOff',
  'OmniOn'                            => 'MIDI::XML::OmniOn',
  'OtherMetaEvent'                    => 'MIDI::XML::OtherMetaEvent',
  'PitchBendChange'                   => 'MIDI::XML::PitchBendChange',
  'PolyKeyPressure'                   => 'MIDI::XML::PolyKeyPressure',
  'PolyMode'                          => 'MIDI::XML::PolyMode',
  'Port'                              => 'MIDI::XML::Port',
  'ProgramChange'                     => 'MIDI::XML::ProgramChange',
  'ProgramName'                       => 'MIDI::XML::ProgramName',
  'ResetAllControllers'               => 'MIDI::XML::ResetAllControllers',
  'RPNChange'                         => 'MIDI::XML::RPNChange',
  'SequenceNumber'                    => 'MIDI::XML::SequenceNumber',
  'SequencerSpecific'                 => 'MIDI::XML::SequencerSpecific',
  'SetTempo'                          => 'MIDI::XML::SetTempo',
  'SMPTEOffset'                       => 'MIDI::XML::SMPTEOffset',
  'SongPositionPointer'               => 'MIDI::XML::SongPositionPointer',
  'SongSelect'                        => 'MIDI::XML::SongSelect',
  'Start'                             => 'MIDI::XML::Start',
  'Stop'                              => 'MIDI::XML::Stop',
  'SysEx'                             => 'MIDI::XML::SysEx',
  'SysExChannel'                      => 'MIDI::XML::SysExChannel',
  'SysExDeviceID'                     => 'MIDI::XML::SysExDeviceID',
  'SystemExclusive'                   => 'MIDI::XML::SystemExclusive',
  'SystemReset'                       => 'MIDI::XML::SystemReset',
  'TextEvent'                         => 'MIDI::XML::TextEvent',
  'TicksPerBeat'                      => 'MIDI::XML::TicksPerBeat',
  'TicksPerFrame'                     => 'MIDI::XML::TicksPerFrame',
  'TimeSignature'                     => 'MIDI::XML::TimeSignature',
  'TimestampType'                     => 'MIDI::XML::TimestampType',
  'TimingClock'                       => 'MIDI::XML::TimingClock',
  'Track'                             => 'MIDI::XML::Track',
  'TrackCount'                        => 'MIDI::XML::TrackCount',
  'TrackName'                         => 'MIDI::XML::TrackName',
  'TuneRequest'                       => 'MIDI::XML::TuneRequest',
  'XMFPatchTypePrefix'                => 'MIDI::XML::XMFPatchTypePrefix',
);

sub createElement() {
  my $self = shift;
  my $qname = shift;
  if(exists($tag_map{$qname})) {
    return XML::DOM::Element::new($tag_map{$qname},$self,$qname);
  } else {
    return XML::DOM::Element->new($self,$qname);
  }
}

#==========================================================================

=item $array_ref = $MidiFile->measures() or $MidiFile->measures('refresh');

Returns a reference to an array of measures.  If called with
any parameter the array is refreshed before the reference is returned.

=cut

sub measures {
  my $self = shift;
  my @measures;
  my @timesig;
  my $end = 0;

  if (@_) {
    $self->[_UserData]{'_measures'} = undef;
  }
  if (defined($self->[_UserData]{'_measures'})) {
    return  $self->[_UserData]{'_measures'};
  }
  my $model = $self->getDocumentElement();
  my $ticksPerBeat = $model->TicksPerBeat();
  my @tracks = $model->getElementsByTagName('Track');

  # find the length of the longest track.    
  foreach my $track (@tracks) {
    my $e = $track->end();
    $end = $e if ($e > $end);
  }
  
  # collect data from TimeSignature objects;
  my @events = $tracks[0]->getElementsByTagName('Event');
  my $abs = 0;
  foreach my $event (@events) {
    my $timestamp = $event->Timestamp;
    my $value = $timestamp->value();
    my $tsclass = ref($timestamp);
    if ($tsclass eq 'MIDI::XML::Delta') {
      $abs += $value;
    } elsif ($tsclass eq 'MIDI::XML::Absolute') {
      $abs = $value;
    }
    my @tsigs = $event->getElementsByTagName('TimeSignature');
    foreach my $tsig (@tsigs) {
      my $num = $tsig->Numerator();
      my $log = $tsig->LogDenominator();
      my $den = 2 ** $log;
      push @timesig, [$abs,$num,$den];
    }
  }

  push @timesig, [$end,1,1];

  my $meas = 1;
  my $time=0;
  my $denom_ticks;
  for (my $i=0; $i<$#timesig; $i++) {
    my $lim = $timesig[$i+1]->[0];
    $denom_ticks = $ticksPerBeat * 4 / $timesig[$i]->[2];
    my $divs = $denom_ticks * $timesig[$i]->[1];
    while ($time < $lim) {
      push @{$self->[_UserData]{'_measures'}},[$time,$denom_ticks,$divs];
      $meas++;
      $time += $divs;
    }
  }
  push @{$self->[_UserData]{'_measures'}},[$time,$denom_ticks,0];

  return $self->[_UserData]{'_measures'};
}

#===============================================================================

sub var_len_int($) {
  my $int = shift @_;
  
  my @i;
  unshift @i,($int & 0x7F);
  $int >>= 7;
  while ($int > 0) {
    unshift @i,(($int & 0x7F) | 0x80);
    $int >>= 7;
  }
  if(wantarray()) {
    return @i;
  }
  return \@i;
}

#===============================================================================

=item MIDI::XML::Document->writefile($path);

This method is used to write an Standard MIDI file.

=cut

sub writefile($) {
  my $self = shift @_;
  my $source = shift @_;
  
  my $Model = $self->getDocumentElement();
  my $format = $Model->Format();
  my $trackCount = $Model->TrackCount();
  my $frames = $Model->FrameRate();
  my $ticks = $Model->TicksPerBeat();
  
#  print "\$format = $format\n";
#  print "\$trackCount = $trackCount\n";
#  print "\$frames = $frames\n";
#  print "\$ticks = $ticks\n";

  my $err = 0;
  open MIDI,'>',$source or $err = 1;
  if ($err) {
    carp "Error opening file $source"; 
    return undef;
  }
  binmode MIDI;
  my $buf;
  if(defined($frames)) {
    $buf = 'MThd' . pack('NnnCC',6,$format,$trackCount, -$frames, $ticks);
  } else {
    $buf = 'MThd' . pack('Nnnn',6,$format,$trackCount, $ticks);
  }
  syswrite MIDI,$buf,14;
  
  my @tracks = $Model->getElementsByTagName('Track');
  foreach my $track (@tracks) {
    my $tbuf='';
    my @events = $track->getElementsByTagName('Event');
    my $time = 0;
    my $abs = 0;
    my $rstatus = 0;
    foreach my $event (@events) {
      my $timestamp = $event->Timestamp;
      my $value = $timestamp->value();
      my $tsclass = ref($timestamp);
      if ($tsclass eq 'MIDI::XML::Delta') {
        $abs += $value;
      } elsif ($tsclass eq 'MIDI::XML::Absolute') {
        $abs = $value;
      } else {
        carp "Invalid timestamp class: $tsclass";
      }
      my $delta = $abs - $time;
      my @d = var_len_int($delta);
      $time = $abs;
      map {$tbuf .= pack('C',$_);} @d;
      my $smfEvent = $event->SmfEvent();
      my @m = $smfEvent->_bytes();
      my $status = $m[0];
      if ($status >= 0xF0) {
        $rstatus = 0;
      }
      elsif ($rstatus == $status) {
        shift @m;
      } else {
        $rstatus = $status;
      }
      map {$tbuf .= pack('C',$_);} @m;
      
    }
    my $tblen = length($tbuf);
    $buf = 'MTrk' . pack('N',$tblen);
    syswrite MIDI,$buf,8;
    syswrite MIDI,$tbuf,$tblen;
  }
    
  close MIDI;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 

package MIDI::XML::Element;

our @ISA = qw(XML::DOM::Element);
our @EXPORT = qw();
our @EXPORT_OK = qw();

BEGIN
{
    import XML::DOM::Node qw( :Fields );
}

sub xmi_id() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('xmi.id', lc shift);
  }
  return $self->getAttribute('xmi.id');
}

sub xmi_idref() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('xmi.idref', lc shift);
  }
  return $self->getAttribute('xmi.idref');
}

sub get_collection() {
  my $self = shift;
  my $name = shift;
  my $qname = shift;

  $self->[_UserData] = {} unless (defined($self->[_UserData]));
  $self->[_UserData]{'_collections'} = {} unless (exists($self->[_UserData]{'_collections'}));
  unless(exists($self->[_UserData]{'_collections'}{$name})) {
    my $elem = $self->getOwnerDocument->createElement($qname);
    $self->appendChild($elem);
    $self->[_UserData]{'_collections'}{$name} = $elem;
  }
  return $self->[_UserData]{'_collections'}{$name};
}

sub attribute_as_element() {
  my $self = shift;
  my $name = shift;
  my $element = shift;

  $self->[_UserData] = {} unless (defined($self->[_UserData]));
  $self->[_UserData]{'_elements'} = {} unless (exists($self->[_UserData]{'_elements'}));
  if(defined($element)) {
    if(exists($self->[_UserData]{'_elements'}{$name})) {
      $self->replaceChild($element,$self->[_UserData]{'_elements'}{$name});
    } else {
      $self->appendChild($element);
    }
    $self->[_UserData]{'_elements'}{$name} = $element;
  }
  unless(exists($self->[_UserData]{'_elements'}{$name})) {
    return undef;
  }
  return $self->[_UserData]{'_elements'}{$name};
}

#===============================================================================
# MIDI::XML::Element::text

=head2 $value = $Object->text([$new_value]);

Set or get element text content.

=cut

sub text() {
  my $self = shift;
  
  if (@_) {
    while($self->hasChildNodes()) {
      $self->removeChild($self->getLastChild());
    }
    $self->appendChild($self->getOwnerDocument->createTextNode($_[0]));
  } else {
    $self->normalize();
  }
  return $self->getFirstChild->getNodeValue();
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: a4772d55-45af-11dd-8bf4-00502c05c241

package MIDI::XML::MetaEvent;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::SmfEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of MetaEvent

MIDI::XML::MetaEvent is used for representing MetaEvent objects 

=cut

#===============================================================================

#{
#  no strict "refs";
#  *TAG_NAME = sub { return 'meta-event'; };
#}

##END_PACKAGE MetaEvent

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 1515de42-45d8-11dd-8bf4-00502c05c241

package MIDI::XML::CopyrightNotice;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of CopyrightNotice

MIDI::XML::CopyrightNotice is used for representing CopyrightNotice objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'CopyrightNotice'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $text = $self->text();
  my @bytes = (0xFF, 0x02, MIDI::XML::Document::var_len_int(length($text)), unpack('C*',$text));

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE CopyrightNotice

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 333a3ce5-45d8-11dd-8bf4-00502c05c241

package MIDI::XML::CuePoint;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of CuePoint

MIDI::XML::CuePoint is used for representing CuePoint objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'CuePoint'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $text = $self->text();
  my @bytes = (0xFF, 0x07, MIDI::XML::Document::var_len_int(length($text)), unpack('C*',$text));

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE CuePoint

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 47070e18-45d8-11dd-8bf4-00502c05c241

package MIDI::XML::DeviceName;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of DeviceName

MIDI::XML::DeviceName is used for representing DeviceName objects.

 FF 09 len text        DEVICE NAME

The Device Name is the name of the device that this track is intended to address. 
It will often be the model name of a synthesizer, but can be any string which 
uniquely identifies a particular device in a given setup. There should only be 
one Device Name (Meta Event 09) per track, and it should appear at the beginning 
of a track before any events which are sendable (i.e., it should be grouped with 
the text events before the proposed Program Name [Meta Event 08 - see below] and 
before bank select and program change messages). This will ensure that each track 
can only address one device.

Each track of a MIDI File can contain one MIDI stream, including SysEx and up to 
16 channels.  The Device Name Meta Event is used to label each track in a MIDI 
File with a text label. 

If a Type 1 Standard MIDI File contains MIDI data for several devices, the data 
for each device is contained in a separate track, each with a different Device 
Name Meta Event.  It is possible to have any number of tracks which address the 
same Device Name; however, each track can only address one device, as noted above.

Since a Type 0 Standard MIDI File has only one track, it can have only one 
Device Name Meta Event.


=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'DeviceName'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $text = $self->text();
  my @bytes = (0xFF, 0x09, MIDI::XML::Document::var_len_int(length($text)), unpack('C*',$text));

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE DeviceName

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 53cdc6cb-45d8-11dd-8bf4-00502c05c241

package MIDI::XML::EndOfTrack;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of EndOfTrack

MIDI::XML::EndOfTrack is used for representing EndOfTrack objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'EndOfTrack'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my @bytes = (0xFF, 0x2F, 0x00);

  if(wantarray()) {
    return @bytes;
  }
  return \@bytes;
}

##END_PACKAGE EndOfTrack

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 6a099c2e-45d8-11dd-8bf4-00502c05c241

package MIDI::XML::InstrumentName;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of InstrumentName

MIDI::XML::InstrumentName is used for representing InstrumentName objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'InstrumentName'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $text = $self->text();
  my @bytes = (0xFF, 0x04, MIDI::XML::Document::var_len_int(length($text)), unpack('C*',$text));

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE InstrumentName

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 8426f181-45d8-11dd-8bf4-00502c05c241

package MIDI::XML::KeySignature;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of KeySignature

MIDI::XML::KeySignature is used for representing KeySignature objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'KeySignature'; };
}

#===============================================================================
# MIDI::XML::KeySignature::Fifths

=head2 $value = $Object->Fifths([$new_value]);

Set or get value of the Fifths attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Fifths() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Fifths', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Fifths\'';
    }
  }
  return $self->getAttribute('Fifths');
}

#===============================================================================
# MIDI::XML::KeySignature::Mode

=head2 $value = $Object->Mode([$new_value]);

Set or get value of the Mode attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Mode() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Mode', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Mode\'';
    }
  }
  return $self->getAttribute('Mode');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $fifths = $self->Fifths();
  my $mode = $self->Mode();
  $fifths += 256 if ($fifths<0);
  my @bytes = (0xFF, 0x59, 0x02, $fifths, $mode);

  if(wantarray()) {
    return @bytes;
  }
 
  return \@bytes;
}

##END_PACKAGE KeySignature

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: a2fd13f4-45d8-11dd-8bf4-00502c05c241

package MIDI::XML::Lyric;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Lyric

MIDI::XML::Lyric is used for representing Lyric objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'Lyric'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $text = $self->text();
  my @bytes = (0xFF, 0x05, MIDI::XML::Document::var_len_int(length($text)), unpack('C*',$text));

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE Lyric

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: dfb6e287-45d8-11dd-8bf4-00502c05c241

package MIDI::XML::Marker;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Marker

MIDI::XML::Marker is used for representing Marker objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'Marker'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $text = $self->text();
  my @bytes = (0xFF, 0x06, MIDI::XML::Document::var_len_int(length($text)), unpack('C*',$text));

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE Marker

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: ef6d1a0a-45d8-11dd-8bf4-00502c05c241

package MIDI::XML::MIDIChannelPrefix;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of MIDIChannelPrefix

MIDI::XML::MIDIChannelPrefix is used for representing MIDIChannelPrefix objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'MIDIChannelPrefix'; };
}

#===============================================================================
# MIDI::XML::MIDIChannelPrefix::Value

=head2 $value = $Object->Value([$new_value]);

Set or get value of the Value attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Value() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Value', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Value\'';
    }
  }
  return $self->getAttribute('Value');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my @bytes = (0xFF, 0x20, $self->Value());

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE MIDIChannelPrefix

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 0486dd9d-45d9-11dd-8bf4-00502c05c241

package MIDI::XML::OtherMetaEvent;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OtherMetaEvent

MIDI::XML::OtherMetaEvent is used for representing OtherMetaEvent objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'OtherMetaEvent'; };
}

#===============================================================================
# MIDI::XML::OtherMetaEvent::Number

=head2 $value = $Object->Number([$new_value]);

Set or get value of the Number attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Number() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Number', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Number\'';
    }
  }
  return $self->getAttribute('Number');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $text = $self->text();
  my @t = split(' ',$text);

  my @bytes = (0xFF, $self->Number());
  map {push @bytes,ord(pack('H2',"$_"));} @t;

  if(wantarray()) {
    return @bytes;
  }

 return \@bytes;
}

##END_PACKAGE OtherMetaEvent

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 89f69070-45d9-11dd-8bf4-00502c05c241

package MIDI::XML::Port;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Port

MIDI::XML::Port is used for representing Port objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'Port'; };
}

#===============================================================================
# MIDI::XML::Port::Value

=head2 $value = $Object->Value([$new_value]);

Set or get value of the Value attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Value() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Value', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Value\'';
    }
  }
  return $self->getAttribute('Value');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my @bytes = (0xFF, 0x21, 1, $self->Value());

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE Port

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 98f278a3-45d9-11dd-8bf4-00502c05c241

package MIDI::XML::ProgramName;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of ProgramName

MIDI::XML::ProgramName is used for representing ProgramName objects
 FF 08 len text       PROGRAM NAME

One purpose of this event is to aid in reorchestration; since one 
non-General-MIDI device's piano can be another one's drum kit; knowing the 
intended program name can be an important clue.

The Program Name is the name of the program called up by the immediately 
following sequence of bank select and program change messages. The channel for 
the program change is identified by the  bank select and program change messages. 
The Program Name Meta Event may appear anywhere in a track, but should only be 
used in conjunction with optional bank selects and a program change. There may 
be more than one Program Name Meta Events in a track.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'ProgramName'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $text = $self->text();
  my @bytes = (0xFF, 0x08, MIDI::XML::Document::var_len_int(length($text)), unpack('C*',$text));

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE ProgramName

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: b9dd7156-45d9-11dd-8bf4-00502c05c241

package MIDI::XML::SequenceNumber;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SequenceNumber

MIDI::XML::SequenceNumber is used for representing SequenceNumber objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'SequenceNumber'; };
}

#===============================================================================
# MIDI::XML::SequenceNumber::Value

=head2 $value = $Object->Value([$new_value]);

Set or get value of the Value attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Value() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Value', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Value\'';
    }
  }
  return $self->getAttribute('Value');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $value = $self->Value();
  my $hi = ($value >> 8) & 0xFF; 
  my $lo = $value & 0xFF;
  my @bytes = (0xFF, 0x00, 0x02, $hi, $lo);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE SequenceNumber

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 4a76f5c2-45da-11dd-8bf4-00502c05c241

package MIDI::XML::SequencerSpecific;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SequencerSpecific

MIDI::XML::SequencerSpecific is used for representing SequencerSpecific objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'SequencerSpecific'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $text = $self->text();
  my @t = split(' ',$text);

  my @bytes = (0xFF, 0x7F, MIDI::XML::Document::var_len_int($#t+1));
  map {push @bytes,ord(pack('H2',"$_"));} @t;

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE SequencerSpecific

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: e58fa939-45d9-11dd-8bf4-00502c05c241

package MIDI::XML::SetTempo;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SetTempo

MIDI::XML::SetTempo is used for representing SetTempo objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'SetTempo'; };
}

#===============================================================================
# MIDI::XML::SetTempo::Value

=head2 $value = $Object->Value([$new_value]);

Set or get value of the Value attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Value() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Value', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Value\'';
    }
  }
  return $self->getAttribute('Value');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $v = $self->Value();
  my $hi = ($v >> 16) & 0x7F;
  my $mid = ($v >> 8) &0x7F;
  my $lo = $v & 0x7F;
  my @bytes = (0xFF, 0x51, 0x03, $hi, $mid, $lo);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE SetTempo

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: f8883a7c-45d9-11dd-8bf4-00502c05c241

package MIDI::XML::SMPTEOffset;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SMPTEOffset

MIDI::XML::SMPTEOffset is used for representing SMPTEOffset objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'SMPTEOffset'; };
}

#===============================================================================
# MIDI::XML::SMPTEOffset::TimeCodeType

=head2 $value = $Object->TimeCodeType([$new_value]);

Set or get value of the TimeCodeType attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub TimeCodeType() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('TimeCodeType', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'TimeCodeType\'';
    }
  }
  return $self->getAttribute('TimeCodeType');
}

#===============================================================================
# MIDI::XML::SMPTEOffset::Hour

=head2 $value = $Object->Hour([$new_value]);

Set or get value of the Hour attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Hour() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Hour', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Hour\'';
    }
  }
  return $self->getAttribute('Hour');
}

#===============================================================================
# MIDI::XML::SMPTEOffset::Minute

=head2 $value = $Object->Minute([$new_value]);

Set or get value of the Minute attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Minute() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Minute', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Minute\'';
    }
  }
  return $self->getAttribute('Minute');
}

#===============================================================================
# MIDI::XML::SMPTEOffset::Second

=head2 $value = $Object->Second([$new_value]);

Set or get value of the Second attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Second() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Second', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Second\'';
    }
  }
  return $self->getAttribute('Second');
}

#===============================================================================
# MIDI::XML::SMPTEOffset::Frame

=head2 $value = $Object->Frame([$new_value]);

Set or get value of the Frame attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Frame() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Frame', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Frame\'';
    }
  }
  return $self->getAttribute('Frame');
}

#===============================================================================
# MIDI::XML::SMPTEOffset::FractionalFrame

=head2 $value = $Object->FractionalFrame([$new_value]);

Set or get value of the FractionalFrame attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub FractionalFrame() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('FractionalFrame', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'FractionalFrame\'';
    }
  }
  return $self->getAttribute('FractionalFrame');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
#  my $text = $self->text();
  my $d1 = ($self->TimeCodeType()<< 5) + ($self->Hour() & 0x1F);
  my $d2 = $self->Minute();
  my $d3 = $self->Second();
  my $d4 = $self->Frame();
  my $d5 = $self->FractionalFrame();
  my @bytes = (0xFF, 0x54, 0x05, $d1, $d2, $d3, $d4, $d5);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE SMPTEOffset

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 153625bf-45da-11dd-8bf4-00502c05c241

package MIDI::XML::TextEvent;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of TextEvent

MIDI::XML::TextEvent is used for representing TextEvent objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'TextEvent'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $text = $self->text();
  my @bytes = (0xFF, 0x01, MIDI::XML::Document::var_len_int(length($text)), unpack('C*',$text));

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE TextEvent

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 68d55025-45da-11dd-8bf4-00502c05c241

package MIDI::XML::TimeSignature;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of TimeSignature

MIDI::XML::TimeSignature is used for representing TimeSignature objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'TimeSignature'; };
}

#===============================================================================
# MIDI::XML::TimeSignature::Numerator

=head2 $value = $Object->Numerator([$new_value]);

Set or get value of the Numerator attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Numerator() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Numerator', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Numerator\'';
    }
  }
  return $self->getAttribute('Numerator');
}

#===============================================================================
# MIDI::XML::TimeSignature::LogDenominator

=head2 $value = $Object->LogDenominator([$new_value]);

Set or get value of the LogDenominator attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub LogDenominator() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('LogDenominator', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'LogDenominator\'';
    }
  }
  return $self->getAttribute('LogDenominator');
}

#===============================================================================
# MIDI::XML::TimeSignature::MIDIClocksPerMetronomeClick

=head2 $value = $Object->MIDIClocksPerMetronomeClick([$new_value]);

Set or get value of the MIDIClocksPerMetronomeClick attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub MIDIClocksPerMetronomeClick() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('MIDIClocksPerMetronomeClick', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'MIDIClocksPerMetronomeClick\'';
    }
  }
  return $self->getAttribute('MIDIClocksPerMetronomeClick');
}

#===============================================================================
# MIDI::XML::TimeSignature::ThirtySecondsPer24Clocks

=head2 $value = $Object->ThirtySecondsPer24Clocks([$new_value]);

Set or get value of the ThirtySecondsPer24Clocks attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub ThirtySecondsPer24Clocks() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('ThirtySecondsPer24Clocks', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'ThirtySecondsPer24Clocks\'';
    }
  }
  return $self->getAttribute('ThirtySecondsPer24Clocks');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $d1 = $self->Numerator();
  my $d2 = $self->LogDenominator();
  my $d3 = $self->MIDIClocksPerMetronomeClick();
  my $d4 = $self->ThirtySecondsPer24Clocks();
  my @bytes = (0xFF, 0x58, 0x04, $d1, $d2, $d3, $d4);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE TimeSignature

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 8c03a928-45da-11dd-8bf4-00502c05c241

package MIDI::XML::TrackName;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of TrackName

MIDI::XML::TrackName is used for representing TrackName objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'TrackName'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $text = $self->text();
  my @bytes = (0xFF, 0x03, MIDI::XML::Document::var_len_int(length($text)), unpack('C*',$text));

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE TrackName

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 5faf654c-4757-11dd-8bf4-00502c05c241

package MIDI::XML::XMFPatchTypePrefix;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MetaEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of XMFPatchTypePrefix

MIDI::XML::XMFPatchTypePrefix is used for representing XMFPatchTypePrefix objects The XMFPatchTypePrefix meta-event is described in RP-032 from the MMA. It allows specification of using General MIDI 1, General MIDI 2, or DLS to interpret subsequent program change and bank select messages in the same track.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'XMFPatchTypePrefix'; };
}

#===============================================================================
# MIDI::XML::XMFPatchTypePrefix::Value

=head2 $value = $Object->Value([$new_value]);

Set or get value of the Value attribute.

  
Type: NMTOKEN
Lower: 1
Upper: 1

=cut

sub Value() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/ ) {
      $self->setAttribute('Value', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'NMTOKEN\' for attribute \'Value\'';
    }
  }
  return $self->getAttribute('Value');
}

#===============================================================================

#sub _bytes {
#  my $self = shift;
  
#  my @bytes = (0xFF, 0x7E, 0x00);

#  if(wantarray()) {
#    return @bytes;
#  }

#  return \@bytes;
#}

##END_PACKAGE XMFPatchTypePrefix

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: cd100a51-45f4-11dd-8bf4-00502c05c241

package MIDI::XML::ChannelMessage;

use Carp;

our @ISA = qw(MIDI::XML::Element  MIDI::XML::SmfEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of ChannelMessage

MIDI::XML::ChannelMessage is used for representing ChannelMessage objects MIDI::XML::Channel is the base class from which MIDI Channel objects are derived.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'ChannelMessage'; };
}

#===============================================================================
# MIDI::XML::ChannelMessage::Channel

=head2 $value = $Object->Channel([$new_value]);

Set or get value of the Channel attribute.

  
Type: nybble
Lower: 1
Upper: 1

=cut

sub Channel() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Channel', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Channel\'';
    }
  }
  return $self->getAttribute('Channel');
}

##END_PACKAGE ChannelMessage

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d61f6053-45f4-11dd-8bf4-00502c05c241

package MIDI::XML::NoteOff;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ChannelMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of NoteOff

MIDI::XML::NoteOff is used for representing NoteOff objects MIDI::XML::NoteOff is a class encapsulating MIDI Note Off messages. A Note Off message includes either a delta time or absolute time as implemented by MIDI::XML::Message and the MIDI Note Off event encoded in 3 bytes as follows:

 1000cccc 0nnnnnnn 0vvvvvvv

 cccc = channel;
 nnnnnnn = note number
 vvvvvvv = velocity

The classes for MIDI Note Off messages and the other six channel messages are derived from MIDI::XML::Channel.


=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'NoteOff'; };
}

#===============================================================================
# MIDI::XML::NoteOff::Note

=head2 $value = $Object->Note([$new_value]);

Set or get value of the Note attribute.

  
Type: byte
Lower: 1
Upper: 1

=cut

sub Note() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Note', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Note\'';
    }
  }
  return $self->getAttribute('Note');
}

#===============================================================================
# MIDI::XML::NoteOff::Velocity

=head2 $value = $Object->Velocity([$new_value]);

Set or get value of the Velocity attribute.

  
Type: byte
Lower: 1
Upper: 1

=cut

sub Velocity() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Velocity', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Velocity\'';
    }
  }
  return $self->getAttribute('Velocity');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0x80+$self->Channel()-1;
  my $d1 = $self->Note();
  my $d2 = $self->Velocity();
  my @bytes = ($status, $d1, $d2);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE NoteOff

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 09512676-45f5-11dd-8bf4-00502c05c241

package MIDI::XML::NoteOn;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ChannelMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of NoteOn

MIDI::XML::NoteOn is used for representing NoteOn objects MIDI::XML::NoteOn is a class encapsulating MIDI Note On messages. A Note On message includes either a delta time or absolute time as implemented by MIDI::XML::Message and the MIDI Note On event encoded in 3 bytes as follows:

 1001cccc 0nnnnnnn 0vvvvvvv

 cccc = channel;
 nnnnnnn = note number
 vvvvvvv = velocity

The classes for MIDI Note On messages and the other six channel messages are derived from MIDI::XML::Channel.


=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'NoteOn'; };
}

#===============================================================================
# MIDI::XML::NoteOn::Note

=head2 $value = $Object->Note([$new_value]);

Set or get value of the Note attribute.

  
Type: byte
Lower: 1
Upper: 1

=cut

sub Note() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Note', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Note\'';
    }
  }
  return $self->getAttribute('Note');
}

#===============================================================================
# MIDI::XML::NoteOn::Velocity

=head2 $value = $Object->Velocity([$new_value]);

Set or get value of the Velocity attribute.

  
Type: byte
Lower: 1
Upper: 1

=cut

sub Velocity() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Velocity', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Velocity\'';
    }
  }
  return $self->getAttribute('Velocity');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0x90+$self->Channel()-1;
  my $d1 = $self->Note();
  my $d2 = $self->Velocity();
  my @bytes = ($status, $d1, $d2);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE NoteOn

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: ad7f2df9-45f5-11dd-8bf4-00502c05c241

package MIDI::XML::PolyKeyPressure;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ChannelMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of PolyKeyPressure

MIDI::XML::PolyKeyPressure is used for representing PolyKeyPressure objects MIDI::XML::PolyKeyPressure is a class encapsulating MIDI Poly Key Pressure messages. A Poly Key Pressure message includes either a delta time or absolute time as implemented by MIDI::XML::Message and the MIDI Poly Key Pressure event encoded in 3 bytes as follows:

 1010cccc 0nnnnnnn 0ppppppp

 cccc = channel;
 nnnnnnn = note number
 ppppppp = pressure

The classes for MIDI Poly Key Pressure messages and the other six channel messages are derived from MIDI::XML::Channel.


=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'PolyKeyPressure'; };
}

#===============================================================================
# MIDI::XML::PolyKeyPressure::Note

=head2 $value = $Object->Note([$new_value]);

Set or get value of the Note attribute.

  
Type: byte
Lower: 1
Upper: 1

=cut

sub Note() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Note', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Note\'';
    }
  }
  return $self->getAttribute('Note');
}

#===============================================================================
# MIDI::XML::PolyKeyPressure::Pressure

=head2 $value = $Object->Pressure([$new_value]);

Set or get value of the Pressure attribute.

  
Type: byte
Lower: 1
Upper: 1

=cut

sub Pressure() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Pressure', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Pressure\'';
    }
  }
  return $self->getAttribute('Pressure');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xA0+$self->Channel()-1;
  my $d1 = $self->Note();
  my $d2 = $self->Pressure();
  my @bytes = ($status, $d1, $d2);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE PolyKeyPressure

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 4489733c-45f7-11dd-8bf4-00502c05c241

package MIDI::XML::ControlChangeMessage;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ChannelMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of ControlChangeMessage

MIDI::XML::ControlChangeMessage is used for representing ControlChangeMessage objects MIDI::XML::ControlChangeMessage is a class encapsulating MIDI Control Change messages. A Control Change message includes either a delta time or absolute time as implemented by MIDI::XML::Message and the MIDI Control Change event encoded in 3 bytes as follows:

 1011cccc 0nnnnnnn 0vvvvvvv

 cccc = channel;
 nnnnnnn = control number
 vvvvvvv = value

The classes for MIDI Control Change messages and the other six channel messages are derived from MIDI::XML::Channel.


=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'control-change-message'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xB0+$self->Channel()-1;
  my $d1 = $self->Control();
  my $d2 = $self->Value();
  my @bytes = ($status, $d1, $d2);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE ControlChangeMessage

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 589178af-45f7-11dd-8bf4-00502c05c241

package MIDI::XML::ProgramChange;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ChannelMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of ProgramChange

MIDI::XML::ProgramChange is used for representing ProgramChange objects MIDI::XML::ProgramChange is a class encapsulating MIDI Program Change messages.
A Program_Change message includes either a delta time or absolute time as 
implemented by MIDI::XML::Message and the MIDI Program Change event encoded
in 2 bytes as follows:

 1100cccc 0nnnnnnn

 cccc = channel;
 nnnnnnn = program number

The classes for MIDI Program Change messages and the other six channel messages are derived from MIDI::XML::Channel.


=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'ProgramChange'; };
}

#===============================================================================
# MIDI::XML::ProgramChange::Number

=head2 $value = $Object->Number([$new_value]);

Set or get value of the Number attribute.

  
Type: byte
Lower: 1
Upper: 1

=cut

sub Number() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Number', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Number\'';
    }
  }
  return $self->getAttribute('Number');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xC0+$self->Channel()-1;
  my $d1 = $self->Number();
  my @bytes = ($status, $d1);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE ProgramChange

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 9be6de22-45f7-11dd-8bf4-00502c05c241

package MIDI::XML::ChannelKeyPressure;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ChannelMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of ChannelKeyPressure

MIDI::XML::ChannelKeyPressure is used for representing ChannelKeyPressure objects MIDI::XML::ChannelKeyPressure is a class encapsulating MIDI Channel Key Pressure 
messages. A Channel Key Pressure message includes either a delta time or absolute time as implemented by MIDI::XML::Message and the MIDI Channel Key Pressure event encoded in 2 bytes as follows:

 1101cccc 0ppppppp

 cccc = channel;
 ppppppp = pressure

The classes for MIDI Channel Key Pressure messages and the other six channel messages are derived from MIDI::XML::Channel.


=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'ChannelKeyPressure'; };
}

#===============================================================================
# MIDI::XML::ChannelKeyPressure::Pressure

=head2 $value = $Object->Pressure([$new_value]);

Set or get value of the Pressure attribute.

  
Type: byte
Lower: 1
Upper: 1

=cut

sub Pressure() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Pressure', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Pressure\'';
    }
  }
  return $self->getAttribute('Pressure');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xD0+$self->Channel()-1;
  my $d1 = $self->Pressure();
  my @bytes = ($status, $d1);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE ChannelKeyPressure

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: e28701c5-45f7-11dd-8bf4-00502c05c241

package MIDI::XML::PitchBendChange;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ChannelMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of PitchBendChange

MIDI::XML::PitchBendChange is used for representing PitchBendChange objects MIDI::XML::PitchBendChange is a class encapsulating MIDI Pitch Bend Change messages. A Pitch Bend Change message includes either a delta time or absolute time as implemented by MIDI::XML::Message and the MIDI Pitch Bend Change event encoded in 3 bytes as follows:

 1110cccc 0xxxxxxx 0yyyyyyy

 cccc = channel;
 xxxxxxx = least significant bits
 yyyyyyy = most significant bits

The classes for MIDI Pitch Bend messages and the other six channel messages are derived from MIDI::XML::Channel.


=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'PitchBendChange'; };
}

#===============================================================================
# MIDI::XML::PitchBendChange::Value

=head2 $value = $Object->Value([$new_value]);

Set or get value of the Value attribute.

  
Type: short
Lower: 1
Upper: 1

=cut

sub Value() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Value', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Value\'';
    }
  }
  return $self->getAttribute('Value');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xE0+$self->Channel()-1;
  my $v = $self->Value();
  my $d1 = ($v >> 7) &0x7f;
  my $d2 = $v & 0x7F;
  my @bytes = ($status, $d1, $d2);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE PitchBendChange

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: cde37ce1-463d-11dd-8bf4-00502c05c241

package MIDI::XML::AllSoundOff;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ControlChangeMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of AllSoundOff

MIDI::XML::AllSoundOff is used for representing AllSoundOff objects MIDI::XML::AllSoundOff is a class encapsulating MIDI All Sound Off messages. An All Sound Off message includes either a delta time or absolute time as 
implemented by MIDI::XML::Message and the MIDI All Sound Off event encoded in 3 bytes as follows:

 1011cccc 0nnnnnnn 0vvvvvvv

 cccc = channel;
 nnnnnnn = control number (120)
 vvvvvvv = value (0)

The classes for MIDI Control Change messages and the other six channel messages are derived from MIDI::XML::Channel.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'AllSoundOff'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xB0+$self->Channel()-1;
  my @bytes = ($status, 120, 0);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE AllSoundOff

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 47c481d4-463e-11dd-8bf4-00502c05c241

package MIDI::XML::ResetAllControllers;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ControlChangeMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of ResetAllControllers

MIDI::XML::ResetAllControllers is used for representing ResetAllControllers objects MIDI::XML::ResetAllControllers is a class encapsulating MIDI Reset All Controllers messages. A Reset All Controllers message includes either a delta time or absolute time as implemented by MIDI::XML::Message and the MIDI Reset All Controllers event encoded in 3 bytes as follows:

 1011cccc 0nnnnnnn 0vvvvvvv

 cccc = channel;
 nnnnnnn = control number (121)
 vvvvvvv = value (0)

The classes for MIDI Control Change messages and the other six channel messages are derived from MIDI::XML::Channel.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'ResetAllControllers'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xB0+$self->Channel()-1;
  my @bytes = ($status, 121, 0);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE ResetAllControllers

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 5f6ba707-463e-11dd-8bf4-00502c05c241

package MIDI::XML::LocalControl;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ControlChangeMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of LocalControl

MIDI::XML::LocalControl is used for representing LocalControl objects MIDI::XML::LocalControl is a class encapsulating MIDI Local Control messages. A Local Control message includes either a delta time or absolute time as implemented by MIDI::XML::Message and the MIDI Local Control event encoded in 3 bytes as follows:

 1011cccc 0nnnnnnn 0vvvvvvv

 cccc = channel;
 nnnnnnn = control number (122)
 vvvvvvv = value

The classes for MIDI Control Change messages and the other six channel messages are derived from MIDI::XML::Channel.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'LocalControl'; };
}

#===============================================================================
# MIDI::XML::LocalControl::Value

=head2 $value = $Object->Value([$new_value]);

Set or get value of the Value attribute.

  
Type: byte
Lower: 1
Upper: 1

=cut

sub Value() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Value', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Value\'';
    }
  }
  return $self->getAttribute('Value');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xB0+$self->Channel()-1;
  my $d2 = $self->Value();
  my @bytes = ($status, 122, $d2);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE LocalControl

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 7a41c50a-463e-11dd-8bf4-00502c05c241

package MIDI::XML::AllNotesOff;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ControlChangeMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of AllNotesOff

MIDI::XML::AllNotesOff is used for representing AllNotesOff objects MIDI::XML::AllNotesOff is a class encapsulating MIDI All Notes Off messages. An All Notes Off message includes either a delta time or absolute time as implemented by MIDI::XML::Message and the MIDI All Notes Off event encoded in 3 bytes as follows:

 1011cccc 0nnnnnnn 0vvvvvvv

 cccc = channel;
 nnnnnnn = control number (123)
 vvvvvvv = value (0)

The classes for MIDI Control Change messages and the other six channel messages are derived from MIDI::XML::Channel.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'AllNotesOff'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xB0+$self->Channel()-1;
  my @bytes = ($status, 123, 0);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE AllNotesOff

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: a80f62dd-463e-11dd-8bf4-00502c05c241

package MIDI::XML::OmniOff;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ControlChangeMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OmniOff

MIDI::XML::OmniOff is used for representing OmniOff objects MIDI::XML::OmniOff is a class encapsulating MIDI Omni Off messages. An Omni Off message includes either a delta time or absolute time as implemented by MIDI::XML::Message and the MIDI Omni Off event encoded in 3 bytes as follows:

 1011cccc 0nnnnnnn 0vvvvvvv

 cccc = channel;
 nnnnnnn = control number (124)
 vvvvvvv = value (0)

The classes for MIDI Control Change messages and the other six channel messages are derived from MIDI::XML::Channel.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'OmniOff'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xB0+$self->Channel()-1;
  my @bytes = ($status, 124, 0);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE OmniOff

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 63ff91a0-463f-11dd-8bf4-00502c05c241

package MIDI::XML::OmniOn;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ControlChangeMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OmniOn

MIDI::XML::OmniOn is used for representing OmniOn objects MIDI::XML::OmniOn is a class encapsulating MIDI Omni On messages. An Omni On message includes either a delta time or absolute time as implemented by MIDI::XML::Message and the MIDI Omni On event encoded in 3 bytes as follows:

 1011cccc 0nnnnnnn 0vvvvvvv

 cccc = channel;
 nnnnnnn = control number (125)
 vvvvvvv = value (0)

The classes for MIDI Control Change messages and the other six channel messages are derived from MIDI::XML::Channel.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'OmniOn'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xB0+$self->Channel()-1;
  my @bytes = ($status, 125, 0);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE OmniOn

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 72cacce3-463f-11dd-8bf4-00502c05c241

package MIDI::XML::MonoMode;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ControlChangeMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of MonoMode

MIDI::XML::MonoMode is used for representing MonoMode objects MIDI::XML::MonoMode is a class encapsulating MIDI Mono Mode messages. A Mono Mode message includes either a delta time or absolute time as 
implemented by MIDI::XML::Message and the MIDI Mono Mode event encoded in 3 bytes as follows:

 1011cccc 0nnnnnnn 0vvvvvvv

 cccc = channel;
 nnnnnnn = control number (126)
 vvvvvvv = value

The classes for MIDI Control Change messages and the other six channel messages are derived from MIDI::XML::Channel.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'MonoMode'; };
}

#===============================================================================
# MIDI::XML::MonoMode::Value

=head2 $value = $Object->Value([$new_value]);

Set or get value of the Value attribute.

  
Type: byte
Lower: 1
Upper: 1

=cut

sub Value() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Value', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Value\'';
    }
  }
  return $self->getAttribute('Value');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xB0+$self->Channel()-1;
  my $d2 = $self->Value();
  my @bytes = ($status, 126, $d2);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE MonoMode

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 86fdd9f6-463f-11dd-8bf4-00502c05c241

package MIDI::XML::PolyMode;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ControlChangeMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of PolyMode

MIDI::XML::PolyMode is used for representing PolyMode objects MIDI::XML::PolyMode is a class encapsulating MIDI Poly Mode messages. A Poly Mode message includes either a delta time or absolute time as implemented by MIDI::XML::Message and the MIDI Poly Mode event encoded in 3 bytes as follows:

 1011cccc 0nnnnnnn 0vvvvvvv

 cccc = channel;
 nnnnnnn = control number (127)
 vvvvvvv = value (0)

The classes for MIDI Control Change messages and the other six channel messages are derived from MIDI::XML::Channel.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'PolyMode'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xB0+$self->Channel()-1;
  my @bytes = ($status, 127, 0);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE PolyMode

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 23859159-4640-11dd-8bf4-00502c05c241

package MIDI::XML::ControlChange;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ControlChangeMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of ControlChange

MIDI::XML::ControlChange is used for representing ControlChange objects MIDI::XML::ControlChange is a class encapsulating MIDI Control Change messages. A Control Change message includes either a delta time or absolute time as implemented by MIDI::XML::Message and the MIDI Control Change event encoded in 3 bytes as follows:

 1011cccc 0nnnnnnn 0vvvvvvv

 cccc = channel;
 nnnnnnn = control number
 vvvvvvv = value

The classes for MIDI Control Change messages and the other six channel messages are derived from MIDI::XML::Channel.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'ControlChange'; };
}

#===============================================================================
# MIDI::XML::ControlChange::Control

=head2 $value = $Object->Control([$new_value]);

Set or get value of the Control attribute.

  
Type: byte
Lower: 1
Upper: 1

=cut

sub Control() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Control', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Control\'';
    }
  }
  return $self->getAttribute('Control');
}

#===============================================================================
# MIDI::XML::ControlChange::Value

=head2 $value = $Object->Value([$new_value]);

Set or get value of the Value attribute.

  
Type: byte
Lower: 1
Upper: 1

=cut

sub Value() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Value', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Value\'';
    }
  }
  return $self->getAttribute('Value');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xB0+$self->Channel()-1;
  my $d1 = $self->Control();
  my $d2 = $self->Value();
  my @bytes = ($status, $d1, $d2);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE ControlChange

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 0ffb7e73-4654-11dd-8bf4-00502c05c241

package MIDI::XML::ControlChange14;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ControlChangeMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of ControlChange14

MIDI::XML::ControlChange14 is used for representing ControlChange14 objects MIDI::XML::ControlChange14 is a class encapsulating MIDI Control Change messages. A Control Change message includes either a delta time or absolute time as implemented by MIDI::XML::Message and the MIDI Control Change event encoded in 6 bytes as follows:

 1011cccc 0nnnnnnn 0vvvvvvv

 cccc = channel;
 nnnnnnn = control number
 vvvvvvv = value MSB

1011cccc 0nnnnnnn 0vvvvvvv

 cccc = channel;
 nnnnnnn = control number + 32
 vvvvvvv = value LSB

The classes for MIDI Control Change messages and the other six channel messages are derived from MIDI::XML::Channel.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'ControlChange14'; };
}

#===============================================================================
# MIDI::XML::ControlChange14::Control

=head2 $value = $Object->Control([$new_value]);

Set or get value of the Control attribute.

  
Type: byte
Lower: 1
Upper: 1

=cut

sub Control() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Control', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Control\'';
    }
  }
  return $self->getAttribute('Control');
}

#===============================================================================
# MIDI::XML::ControlChange14::Value

=head2 $value = $Object->Value([$new_value]);

Set or get value of the Value attribute.

  
Type: short
Lower: 1
Upper: 1

=cut

sub Value() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Value', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Value\'';
    }
  }
  return $self->getAttribute('Value');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xB0+$self->Channel()-1;
  my $v = $self->Value();
  my $d1 = $self->Control();
  my $d2 = ($v >> 7) & 0x7F;
  my $d3 = $d1 + 32;
  my $d4 = $v & 0x7F;
  my @bytes = ($status, $d1, $d2, 0, $d3, $d4);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE ControlChange14

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 60c40936-4654-11dd-8bf4-00502c05c241

package MIDI::XML::RPNChange;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ControlChangeMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of RPNChange

MIDI::XML::RPNChange is used for representing RPNChange objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'RPNChange'; };
}

#===============================================================================
# MIDI::XML::RPNChange::RPN

=head2 $value = $Object->RPN([$new_value]);

Set or get value of the RPN attribute.

  
Type: short
Lower: 1
Upper: 1

=cut

sub RPN() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('RPN', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'RPN\'';
    }
  }
  return $self->getAttribute('RPN');
}

#===============================================================================
# MIDI::XML::RPNChange::Value

=head2 $value = $Object->Value([$new_value]);

Set or get value of the Value attribute.

  
Type: short
Lower: 1
Upper: 1

=cut

sub Value() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Value', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Value\'';
    }
  }
  return $self->getAttribute('Value');
}

#===============================================================================
# A chain of four messages with the three zeros being cheat delta times;

sub _bytes {
  my $self = shift;
  
  my $status = 0xB0+$self->Channel()-1;
  my $r = $self->RPN();
  my $v = $self->Value();
  my $d1 = ($r >> 7) & 0x7F;
  my $d2 = $r & 0x7F;
  my $d3 = ($v >> 7) & 0x7F;
  my $d4 = $v & 0x7F;
  my @bytes = ($status, 0x65, $d1, 0, 0x64, $d2, 0, 0x06, $d3, 0, 0x26, $d4);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE RPNChange

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 9c39bf09-4654-11dd-8bf4-00502c05c241

package MIDI::XML::NRPNChange;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::ControlChangeMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of NRPNChange

MIDI::XML::NRPNChange is used for representing NRPNChange objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'NRPNChange'; };
}

#===============================================================================
# MIDI::XML::NRPNChange::NRPN

=head2 $value = $Object->NRPN([$new_value]);

Set or get value of the NRPN attribute.

  
Type: short
Lower: 1
Upper: 1

=cut

sub NRPN() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('NRPN', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'NRPN\'';
    }
  }
  return $self->getAttribute('NRPN');
}

#===============================================================================
# MIDI::XML::NRPNChange::Value

=head2 $value = $Object->Value([$new_value]);

Set or get value of the Value attribute.

  
Type: short
Lower: 1
Upper: 1

=cut

sub Value() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Value', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Value\'';
    }
  }
  return $self->getAttribute('Value');
}

#===============================================================================
# A chain of four messages with the three zeros being cheat delta times;

sub _bytes {
  my $self = shift;
  
  my $status = 0xB0+$self->Channel()-1;
  my $n = $self->NRPN();
  my $v = $self->Value();
  my $d1 = ($n >> 7) & 0x7F;
  my $d2 = $n & 0x7F;
  my $d3 = ($v >> 7) & 0x7F;
  my $d4 = $v & 0x7F;
  my @bytes = ($status, 0x65, $d1, 0, 0x64, $d2, 0, 0x06, $d3, 0, 0x26, $d4);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE NRPNChange

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 74507384-468f-11dd-8bf4-00502c05c241

package MIDI::XML::SysEx;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDISystemMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SysEx

MIDI::XML::SysEx is used for representing SysEx objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'SysEx'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $text = $self->text();
  my @t = split(' ',$text);

  my @bytes = (0xF0, MIDI::XML::Document::var_len_int($#t+1));
  map {push @bytes,ord(pack('H2',"$_"));} @t;

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE SysEx

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 88829636-468f-11dd-8bf4-00502c05c241

package MIDI::XML::SysExDeviceID;

use Carp;

our @ISA = qw(MIDI::XML::Element);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SysExDeviceID

MIDI::XML::SysExDeviceID is used for representing SysExDeviceID objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'SysExDeviceID'; };
}

#===============================================================================
# MIDI::XML::SysExDeviceID::Multiplier

=head2 $value = $Object->Multiplier([$new_value]);

Set or get value of the Multiplier attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Multiplier() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Multiplier', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Multiplier\'';
    }
  }
  return $self->getAttribute('Multiplier');
}

#===============================================================================
# MIDI::XML::SysExDeviceID::Offset

=head2 $value = $Object->Offset([$new_value]);

Set or get value of the Offset attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Offset() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Offset', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Offset\'';
    }
  }
  return $self->getAttribute('Offset');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my @bytes;

  return \@bytes;
}

##END_PACKAGE SysExDeviceID

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 941da028-468f-11dd-8bf4-00502c05c241

package MIDI::XML::SysExChannel;

use Carp;

our @ISA = qw(MIDI::XML::Element);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SysExChannel

MIDI::XML::SysExChannel is used for representing SysExChannel objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'SysExChannel'; };
}

#===============================================================================
# MIDI::XML::SysExChannel::Multiplier

=head2 $value = $Object->Multiplier([$new_value]);

Set or get value of the Multiplier attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Multiplier() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Multiplier', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Multiplier\'';
    }
  }
  return $self->getAttribute('Multiplier');
}

#===============================================================================
# MIDI::XML::SysExChannel::Offset

=head2 $value = $Object->Offset([$new_value]);

Set or get value of the Offset attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Offset() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Offset', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Offset\'';
    }
  }
  return $self->getAttribute('Offset');
}

##END_PACKAGE SysExChannel

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: aa85196a-468f-11dd-8bf4-00502c05c241

package MIDI::XML::MTCQuarterFrame;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDISystemMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of MTCQuarterFrame

MIDI::XML::MTCQuarterFrame is used for representing MTCQuarterFrame objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'MTCQuarterFrame'; };
}

#===============================================================================
# MIDI::XML::MTCQuarterFrame::MessageType

=head2 $value = $Object->MessageType([$new_value]);

Set or get value of the MessageType attribute.

  
Type: mtc_category
Lower: 1
Upper: 1

=cut

sub MessageType() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('MessageType', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'MIDI::XML::mtc_category\' for attribute \'MessageType\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'MIDI::XML::mtc_category\' for attribute \'MessageType\'';
      }
    }
  }
  return $self->getAttribute('MessageType');
}

#===============================================================================
# MIDI::XML::MTCQuarterFrame::DataNibble

=head2 $value = $Object->DataNibble([$new_value]);

Set or get value of the DataNibble attribute.

  
Type: nybble
Lower: 1
Upper: 1

=cut

sub DataNibble() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('DataNibble', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'DataNibble\'';
    }
  }
  return $self->getAttribute('DataNibble');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xF1;
  my $d1 = ($self->MessageType() << 4) + ($self->DataNibble() & 0x0f);;
  my @bytes = ($status, $d1);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE MTCQuarterFrame

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: bdb7313c-468f-11dd-8bf4-00502c05c241

package MIDI::XML::SongPositionPointer;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDISystemMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SongPositionPointer

MIDI::XML::SongPositionPointer is used for representing SongPositionPointer objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'SongPositionPointer'; };
}

#===============================================================================
# MIDI::XML::SongPositionPointer::Position

=head2 $value = $Object->Position([$new_value]);

Set or get value of the Position attribute.

  
Type: short
Lower: 1
Upper: 1

=cut

sub Position() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Position', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Position\'';
    }
  }
  return $self->getAttribute('Position');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xF2;
  my $p = $self->Position();
  my $d1 = $p & 0x7F;
  my $d2 = ($p >> 7) & 0x7F;
  my @bytes = ($status, $d1, $d2);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE SongPositionPointer

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d62b435e-468f-11dd-8bf4-00502c05c241

package MIDI::XML::SongSelect;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDISystemMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SongSelect

MIDI::XML::SongSelect is used for representing SongSelect objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'SongSelect'; };
}

#===============================================================================
# MIDI::XML::SongSelect::Number

=head2 $value = $Object->Number([$new_value]);

Set or get value of the Number attribute.

  
Type: byte
Lower: 1
Upper: 1

=cut

sub Number() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Number', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Number\'';
    }
  }
  return $self->getAttribute('Number');
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my $status = 0xF3;
  my $d1 = $self->Number();
  my @bytes = ($status, $d1);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE SongSelect

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: dfdcccd0-468f-11dd-8bf4-00502c05c241

package MIDI::XML::TuneRequest;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDISystemMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of TuneRequest

MIDI::XML::TuneRequest is a class encapsulating MIDI Tune Request messages.
A Tune Request message includes either a delta time or absolute time as 
implemented by MIDI::XML::Message and the MIDI Tune Request event encoded
in 1 byte as follows:

 11110110

The class for MIDI Tune Request messages is derived from MIDI::XML::MIDISystemMessage.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'TuneRequest'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my @bytes = (0xF6);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE TuneRequest

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: e8c11b32-468f-11dd-8bf4-00502c05c241

package MIDI::XML::TimingClock;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDISystemMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of TimingClock

MIDI::XML::TimingClock is a class encapsulating MIDI Timing Clock messages.
A Timing Clock message includes either a delta time or absolute time as 
implemented by MIDI::XML::Message and the MIDI Timing Clock event encoded
in 1 byte as follows:

 11111000

The class for MIDI Timing Clock messages is derived from MIDI::XML::MIDISystemMessage.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'TimingClock'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my @bytes = (0xF8);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE TimingClock

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: f1964e64-468f-11dd-8bf4-00502c05c241

package MIDI::XML::Start;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDISystemMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Start

MIDI::XML::Start is a class encapsulating MIDI Start messages.
A Start message includes either a delta time or absolute time as 
implemented by MIDI::XML::Message and the MIDI Start event encoded
in 1 byte as follows:

 11111010

The class for MIDI Start messages is derived from MIDI::XML::MIDISystemMessage.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'Start'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my @bytes = (0xFA);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE Start

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: f9945b76-468f-11dd-8bf4-00502c05c241

package MIDI::XML::Continue;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDISystemMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Continue

MIDI::XML::Continue is a class encapsulating MIDI Continue messages.
A Continue message includes either a delta time or absolute time as 
implemented by MIDI::XML::Message and the MIDI Continue event encoded
in 1 byte as follows:

 11111011

The class for MIDI Continue messages is derived from MIDI::XML::MIDISystemMessage.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'Continue'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my @bytes = (0xFB);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE Continue

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 01a24708-4690-11dd-8bf4-00502c05c241

package MIDI::XML::Stop;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDISystemMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Stop

MIDI::XML::Stop is a class encapsulating MIDI Stop messages.
A Stop message includes either a delta time or absolute time as 
implemented by MIDI::XML::Message and the MIDI Stop event encoded
in 1 byte as follows:

 11111100

The class for MIDI Stop messages is derived from MIDI::XML::MIDISystemMessage.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'Stop'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my @bytes = (0xFC);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE Stop

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 092d46fa-4690-11dd-8bf4-00502c05c241

package MIDI::XML::ActiveSensing;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDISystemMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of ActiveSensing

MIDI::XML::ActiveSensing is a class encapsulating MIDI Active Sensing messages.
An Active Sensing message includes either a delta time or absolute time as 
implemented by MIDI::XML::Message and the MIDI Active Sensing event encoded
in 1 byte as follows:

 11111110

The class for MIDI Active Sensing messages is derived from MIDI::XML::MIDISystemMessage.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'ActiveSensing'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my @bytes = (0xFE);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE ActiveSensing

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 222751fc-4690-11dd-8bf4-00502c05c241

package MIDI::XML::SystemReset;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDISystemMessage);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SystemReset

MIDI::XML::SystemReset is a class encapsulating MIDI System Reset messages.
A System Reset message includes either a delta time or absolute time as 
implemented by MIDI::XML::Message and the MIDI System Reset event encoded
in 1 byte as follows:

 11111111

The class for MIDI System Reset messages is derived from MIDI::XML::MIDISystemMessage.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'SystemReset'; };
}

#===============================================================================

sub _bytes {
  my $self = shift;
  
  my @bytes = (0xFF);

  if(wantarray()) {
    return @bytes;
  }

  return \@bytes;
}

##END_PACKAGE SystemReset

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: fb0a8b4e-4690-11dd-8bf4-00502c05c241

package MIDI::XML::MIDISystemMessage;

use Carp;

our @ISA = qw(MIDI::XML::Element  MIDI::XML::SmfEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of MIDISystemMessage

MIDI::XML::MIDISystemMessage is used for representing MIDISystemMessage objects 

=cut

##===============================================================================

#{
#  no strict "refs";
#  *TAG_NAME = sub { return 'midi-system-message'; };
#}

##END_PACKAGE MIDISystemMessage

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 31f31103-45a0-11dd-8bf4-00502c05c241

package MIDI::XML::MIDIfile;

use Carp;

our @ISA = qw(MIDI::XML::Element);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of MIDIfile

MIDI::XML::MIDIfile is used for representing MIDIfile objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'MIDIFile'; };
}

#===============================================================================
# MIDI::XML::MIDIfile::Format

=head2 $value = $Object->Format([$new_value]);

Set or get value of the Format attribute.

  Format indicates MIDI format 0, 1, or 2. So far only types 0 and 1 are explicitly supported by the MIDI XML format.
Type: int
Lower: 1
Upper: 1

=cut

sub Format() {
  my $self = shift;
  if (@_) {
    my $newval = shift;
    if (ref($newval)) {
      my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
      if ('MIDI::XML::int' =~ /$regexp/ ) {
        $self->attribute_as_element('Format', $newval);
      } else {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'MIDI::XML::int\' for attribute \'Format\'';
      }
    } else {
      my $newelem = $self->getOwnerDocument->createElement('Format');
      $newelem->appendChild($Document->createTextNode($newval));
      $self->attribute_as_element('Format',$newelem);
    }
  }
  return $self->attribute_as_element('Format')->[0][0]->getNodeValue();
}

#===============================================================================
# MIDI::XML::MIDIfile::TrackCount

=head2 $value = $Object->TrackCount([$new_value]);

Set or get value of the TrackCount attribute.

  TrackCount indicate the number of tracks in a file: 1 for type 0, usually more for types 1 and 2. The TrackCount matches the number of Track elements in the MIDI XML file.
Type: int
Lower: 1
Upper: 1

=cut

sub TrackCount() {
  my $self = shift;
  if (@_) {
    my $newval = shift;
    if (ref($newval)) {
      my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
      if ('MIDI::XML::int' =~ /$regexp/ ) {
        $self->attribute_as_element('TrackCount', $newval);
      } else {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'MIDI::XML::int\' for attribute \'TrackCount\'';
      }
    } else {
      my $newelem = $self->getOwnerDocument->createElement('TrackCount');
      $newelem->appendChild($Document->createTextNode($newval));
      $self->attribute_as_element('TrackCount',$newelem);
    }
  }
  return $self->attribute_as_element('TrackCount')->[0][0]->getNodeValue();
}

#===============================================================================
# MIDI::XML::MIDIfile::TicksPerBeat

=head2 $value = $Object->TicksPerBeat([$new_value]);

Set or get value of the TicksPerBeat attribute.

  How many ticks in a beat (MIDI quarter note).
Type: int
Lower: 1
Upper: 1

=cut

sub TicksPerBeat() {
  my $self = shift;
  if (@_) {
    my $newval = shift;
    if (ref($newval)) {
      my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
      if ('MIDI::XML::int' =~ /$regexp/ ) {
        $self->attribute_as_element('TicksPerBeat', $newval);
      } else {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'MIDI::XML::int\' for attribute \'TicksPerBeat\'';
      }
    } else {
      my $newelem = $self->getOwnerDocument->createElement('TicksPerBeat');
      $newelem->appendChild($Document->createTextNode($newval));
      $self->attribute_as_element('TicksPerBeat',$newelem);
    }
  }
  return $self->attribute_as_element('TicksPerBeat')->[0][0]->getNodeValue();
}

#===============================================================================
# MIDI::XML::MIDIfile::FrameRate

=head2 $value = $Object->FrameRate([$new_value]);

Set or get value of the FrameRate attribute.

  Frame rate and ticks per frame are used with SMPTE time codes.
Type: int
Lower: 1
Upper: 1

=cut

sub FrameRate() {
  my $self = shift;
  if (@_) {
    my $newval = shift;
    if (ref($newval)) {
      my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
      if ('MIDI::XML::int' =~ /$regexp/ ) {
        $self->attribute_as_element('FrameRate', $newval);
      } else {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'MIDI::XML::int\' for attribute \'FrameRate\'';
      }
    } else {
      my $newelem = $self->getOwnerDocument->createElement('FrameRate');
      $newelem->appendChild($Document->createTextNode($newval));
      $self->attribute_as_element('FrameRate',$newelem);
    }
  }
  my $fr = $self->attribute_as_element('FrameRate');
  if(defined($fr)) {
    return $self->attribute_as_element('FrameRate')->[0][0]->getNodeValue();
  }
  return undef;
}

#===============================================================================
# MIDI::XML::MIDIfile::TicksPerFrame

=head2 $value = $Object->TicksPerFrame([$new_value]);

Set or get value of the TicksPerFrame attribute.

  Frame rate and ticks per frame are used with SMPTE time codes.
Type: int
Lower: 1
Upper: 1

=cut

sub TicksPerFrame() {
  my $self = shift;
  if (@_) {
    my $newval = shift;
    if (ref($newval)) {
      my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
      if ('MIDI::XML::int' =~ /$regexp/ ) {
        $self->attribute_as_element('TicksPerFrame', $newval);
      } else {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'MIDI::XML::int\' for attribute \'TicksPerFrame\'';
      }
    } else {
      my $newelem = $self->getOwnerDocument->createElement('TicksPerFrame');
      $newelem->appendChild($Document->createTextNode($newval));
      $self->attribute_as_element('TicksPerFrame',$newelem);
    }
  }
  return $self->attribute_as_element('TicksPerFrame')->[0][0]->getNodeValue();
}

#===============================================================================
# MIDI::XML::MIDIfile::TimestampType

=head2 $value = $Object->TimestampType([$new_value]);

Set or get value of the TimestampType attribute.

TimestampType should be Delta or Absolute. Indicates the element name to look 
for in the initial timestamp in each MIDI event.

Type: timestamp_type
Lower: 1
Upper: 1

=cut

sub TimestampType() {
  my $self = shift;
  if (@_) {
    my $newval = shift;
    if (ref($newval)) {
      my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
      if ('MIDI::XML::timestamp_type' =~ /$regexp/ ) {
        $self->attribute_as_element('TimestampType', $newval);
      } else {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'MIDI::XML::timestamp_type\' for attribute \'TimestampType\'';
      }
    } else {
      my $newelem = $self->getOwnerDocument->createElement('TimestampType');
      $newelem->appendChild($Document->createTextNode($newval));
      $self->attribute_as_element('TimestampType',$newelem);
    }
  }
  return $self->attribute_as_element('TimestampType')->[0][0]->getNodeValue();
}

#===============================================================================
# MIDI::XML::Track::track

=item $arrayref = $Object->track();

Returns a reference to an array of the contained Track objects.
Get values of the track property.

  
Type: 

=cut

sub track() {
  my $self = shift;
  return $self->{'_track'};
}

#===============================================================================
# MIDI::XML::Track::track

=item $value = $Object->push_track([$new_value]);

Set or get value of the track attribute.

  
Type: 

=cut

sub push_track() {
  my $self = shift;
  if (@_) {
    $self->{'_track'} = [] unless(exists($self->{'_track'}));
    push @{$self->{'_track'}}, shift;
  }
  return $self->{'_track'};
}

##END_PACKAGE MIDIfile

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 37ad642f-45aa-11dd-8bf4-00502c05c241

package MIDI::XML::Format;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDIfile);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Format

MIDI::XML::Format is used for representing Format objects Format indicates MIDI format 0, 1, or 2. So far only types 0 and 1 are explicitly supported by the MIDI XML format.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'Format'; };
}

##END_PACKAGE Format

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 5dcb14f0-45aa-11dd-8bf4-00502c05c241

package MIDI::XML::TrackCount;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDIfile);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of TrackCount

MIDI::XML::TrackCount is used for representing TrackCount objects TrackCount indicate the number of tracks in a file: 1 for type 0, usually more for types 1 and 2. The TrackCount matches the number of Track elements in the MIDI XML file.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'TrackCount'; };
}

##END_PACKAGE TrackCount

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: b146b1c1-45aa-11dd-8bf4-00502c05c241

package MIDI::XML::TicksPerBeat;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDIfile);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of TicksPerBeat

MIDI::XML::TicksPerBeat is used for representing TicksPerBeat objects How many ticks in a beat (MIDI quarter note).

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'TicksPerBeat'; };
}

##END_PACKAGE TicksPerBeat

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: be3a94f2-45aa-11dd-8bf4-00502c05c241

package MIDI::XML::FrameRate;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDIfile);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of FrameRate

MIDI::XML::FrameRate is used for representing FrameRate objects Frame rate and ticks per frame are used with SMPTE time codes.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'FrameRate'; };
}

##END_PACKAGE FrameRate

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 06ad55b3-45ab-11dd-8bf4-00502c05c241

package MIDI::XML::TicksPerFrame;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDIfile);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of TicksPerFrame

MIDI::XML::TicksPerFrame is used for representing TicksPerFrame objects Frame rate and ticks per frame are used with SMPTE time codes.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'TicksPerFrame'; };
}

##END_PACKAGE TicksPerFrame

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 2609e634-45ab-11dd-8bf4-00502c05c241

package MIDI::XML::TimestampType;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::MIDIfile);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of TimestampType

MIDI::XML::TimestampType is used for representing TimestampType objects TimestampType should be Delta or Absolute. Indicates the element name to look for in the initial timestamp in each MIDI event.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'TimestampType'; };
}

##END_PACKAGE TimestampType

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 4c621699-45a5-11dd-8bf4-00502c05c241

package MIDI::XML::Track;

use Carp;

our @ISA = qw(MIDI::XML::Element);
our @EXPORT = qw();
our @EXPORT_OK = qw();

BEGIN
{
    import XML::DOM::Node qw( :Fields );
}

=head1 DESCRIPTION of Track

MIDI::XML::Track is used for representing Track objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'Track'; };
}

#===============================================================================
# MIDI::XML::Track::Number

=head2 $value = $Object->Number([$new_value]);

Set or get value of the Number attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Number() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Number', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Integer\' for attribute \'Number\'';
    }
  }
  return $self->getAttribute('Number');
}

#===============================================================================
# MIDI::XML::Event::event

=item $arrayref = $Object->event();

Returns a reference to an array of the contained Event objects.
Get values of the event property.

  
Type: ArrayRef

=cut

sub event() {
  my $self = shift;
  return $self->{'_event'};
}

#===============================================================================
# MIDI::XML::Event::event

=item $value = $Object->push_event([$new_value]);

Set or get value of the event attribute.

  
Return Type: ArrayRef

=cut

sub push_event() {
  my $self = shift;
  if (@_) {
    $self->{'_event'} = [] unless(exists($self->{'_event'}));
    push @{$self->{'_event'}}, shift;
  }
  return $self->{'_event'};
}

#===============================================================================
# MIDI::XML::Event::name()

=item $trackName = $Track->name();

Returns a the value of the first TrackName object in the Track.

Type: String

=cut

sub name() {
  my $self = shift;
  
  my @tns = $self->getElementsByTagName('TrackName');
  if (@tns) {
#    return $tns[0]->[0]->getNodeValue();
    my $ch = $tns[0]->getChildNodes();
    if ($ch->getLength()>1) {
      $tns[0]->normalize();
    }
    return $ch->item(0)->getNodeValue();
#    return "$tns[0]->[0]";
  }
  
  return undef;
}

#==========================================================================

=item $end = $Track->end() or $Track->end('refresh');

Returns the absolute time for the end of the track.  If called with
any parameter the value is refreshed before it is returned.

=cut

sub end {
  my $self = shift;
  my $abs = 0;
  my $del = 0;

  if (@_) {
      $self->[_UserData]{'_end'} = undef;
  }
  if (defined($self->[_UserData]{'_end'})) {
      return  $self->[_UserData]{'_end'};
  }

  my @events = $self->getElementsByTagName('Event');
  foreach my $event (@events) {
    my $timestamp = $event->Timestamp;
    my $value = $timestamp->value();
    my $tsclass = ref($timestamp);
    if ($tsclass eq 'MIDI::XML::Delta') {
      $abs += $value;
#      $event->absolute($abs);
    } elsif ($tsclass eq 'MIDI::XML::Absolute') {
      $abs = $value;
    }
  }
  $self->[_UserData]{'_end'} = $abs;
#  print "end: $abs\n";
  return  $self->[_UserData]{'_end'};
}

##END_PACKAGE Track

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 73a6e8b2-45ad-11dd-8bf4-00502c05c241

package MIDI::XML::Event;

use Carp;

our @ISA = qw(MIDI::XML::Element);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Event

MIDI::XML::Event is used for representing Event objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'Event'; };
}

#===============================================================================
# MIDI::XML::Event::Timestamp

=head2 $value = $Object->Timestamp([$new_value]);

Set or get value of the Timestamp attribute.

  
Type: Timestamp
Lower: 1
Upper: 1

=cut

sub Timestamp() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('MIDI::XML::Timestamp' =~ /$regexp/ ) {
      $self->attribute_as_element('Timestamp', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'MIDI::XML::Timestamp\' for attribute \'Timestamp\'';
    }
  }
  my @children = $self->getChildNodes();
  foreach my $child (@children) {
    my $class = ref($child);
    if($class eq 'MIDI::XML::Absolute' or $class eq 'MIDI::XML::Delta') {
      return $child;
    }
  }
  
  return undef;  # this should never happen
}

#===============================================================================
# MIDI::XML::Event::SmfEvent

=head2 $value = $Object->SmfEvent([$new_value]);

Set or get value of the SmfEvent attribute.

  
Type: SmfEvent
Lower: 1
Upper: 1

=cut

sub SmfEvent() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('MIDI::XML::SmfEvent' =~ /$regexp/ ) {
      $self->attribute_as_element('SmfEvent', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'MIDI::XML::SmfEvent\' for attribute \'SmfEvent\'';
    }
  }
  my $smfEvent = $self->attribute_as_element('SmfEvent');

  unless (defined($smfEvent)) {
    my @nodes = $self->getChildNodes();
    foreach my $node (@nodes) {
      my $regexp = join('|',Class::ISA::self_and_super_path(ref($node)));
      if ('MIDI::XML::SmfEvent' =~ /$regexp/ ) {
        $self->attribute_as_element('SmfEvent', $node);
        return $node;
      }
    }
  }
  
  return $smfEvent;
}

##END_PACKAGE Event

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 13e629d7-45ae-11dd-8bf4-00502c05c241

package MIDI::XML::Timestamp;

use Carp;

our @ISA = qw(MIDI::XML::Element);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Timestamp

MIDI::XML::Timestamp is used for representing Timestamp objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'Timestamp'; };
}

#===============================================================================
# MIDI::XML::Timestamp::Absolute

=head2 $value = $Object->Absolute([$new_value]);

Set or get value of the Absolute attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Absolute() {
  my $self = shift;
  
#  my $sref = ref($self);
  if (@_) {
    my $newval = shift;
    if (ref($newval)) {
      my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
      if ('MIDI::XML::int' =~ /$regexp/ ) {
        $self->attribute_as_element('Absolute', $newval);
      } else {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'MIDI::XML::int\' for attribute \'Absolute\'';
      }
    } else {
      my $newelem = $self->getOwnerDocument->createElement('Absolute');
      $newelem->appendChild($Document->createTextNode($newval));
      $self->attribute_as_element('Absolute',$newelem);
    }
  }
#  if ($sref eq 'MIDI::XML::Absolute') {
#  )
#  print 'ref 1',ref($self),',',ref($self->attribute_as_element('Absolute')),"\n";
#  print 'ref 2',ref($self->attribute_as_element('Absolute')->[0]),"\n";
#  print 'ref 3',ref($self->attribute_as_element('Absolute')->[0][0]),"\n";
  return $self->attribute_as_element('Absolute')->[0][0]->getNodeValue();
}

#===============================================================================
# MIDI::XML::Timestamp::Delta

=head2 $value = $Object->Delta([$new_value]);

Set or get value of the Delta attribute.

  
Type: int
Lower: 1
Upper: 1

=cut

sub Delta() {
  my $self = shift;
  if (@_) {
    my $newval = shift;
    if (ref($newval)) {
      my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
      if ('MIDI::XML::int' =~ /$regexp/ ) {
        $self->attribute_as_element('Delta', $newval);
      } else {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'MIDI::XML::int\' for attribute \'Delta\'';
      }
    } else {
      my $newelem = $self->getOwnerDocument->createElement('Delta');
      $newelem->appendChild($Document->createTextNode($newval));
      $self->attribute_as_element('Delta',$newelem);
    }
  }
  return $self->attribute_as_element('Delta')->[0][0]->getNodeValue();
}

##END_PACKAGE Timestamp

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: c7c8941d-45ae-11dd-8bf4-00502c05c241

package MIDI::XML::Absolute;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::Timestamp);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Absolute

MIDI::XML::Absolute is used for representing Absolute objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'Absolute'; };
}

#===============================================================================
# MIDI::XML::Absolute::value

=head2 $value = $Object->Delta([$new_value]);

Set or get value of the Absolute element.
  
Type: int
Lower: 1
Upper: 1

=cut

sub value() {
  my $self = shift;
  return $self->[0][0]->getNodeValue();
#  return &MIDI::XML::Timestamp::Absolute(@_);
}

##END_PACKAGE Absolute

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: c7e56aee-45ae-11dd-8bf4-00502c05c241

package MIDI::XML::Delta;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::Timestamp);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Delta

MIDI::XML::Delta is used for representing Delta objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'Delta'; };
}

#===============================================================================
# MIDI::XML::Delta::value

=head2 $value = $Object->Delta([$new_value]);

Set or get value of the Delta element.
  
Type: int
Lower: 1
Upper: 1

=cut

sub value() {
  my $self = shift;
  return $self->[0][0]->getNodeValue();
#  return &MIDI::XML::Timestamp::Delta(@_);
}

##END_PACKAGE Delta

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 5743577a-45ae-11dd-8bf4-00502c05c241

package MIDI::XML::SmfEvent;

use Carp;

our @ISA = qw(MIDI::XML::Element);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SmfEvent

MIDI::XML::SmfEvent is used for representing SmfEvent objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'smf-event'; };
}

#===============================================================================
# MIDI::XML::SmfEvent::ChannelMessage

=head2 $value = $Object->ChannelMessage([$new_value]);

Set or get value of the ChannelMessage attribute.

  
Type: ChannelMessage
Lower: 1
Upper: 1

=cut

sub ChannelMessage() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('MIDI::XML::ChannelMessage' =~ /$regexp/ ) {
      $self->attribute_as_element('ChannelMessage', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'MIDI::XML::ChannelMessage\' for attribute \'ChannelMessage\'';
    }
  }
  return $self->attribute_as_element('ChannelMessage');
}

#===============================================================================
# MIDI::XML::SmfEvent::MetaEvent

=head2 $value = $Object->MetaEvent([$new_value]);

Set or get value of the MetaEvent attribute.

  
Type: MetaEvent
Lower: 1
Upper: 1

=cut

sub MetaEvent() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('MIDI::XML::MetaEvent' =~ /$regexp/ ) {
      $self->attribute_as_element('MetaEvent', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'MIDI::XML::MetaEvent\' for attribute \'MetaEvent\'';
    }
  }
  return $self->attribute_as_element('MetaEvent');
}

#===============================================================================
# MIDI::XML::SmfEvent::SysExEvent

=head2 $value = $Object->SysExEvent([$new_value]);

Set or get value of the SysExEvent attribute.

  
Type: SysExEvent
Lower: 1
Upper: 1

=cut

sub SysExEvent() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('MIDI::XML::SysExEvent' =~ /$regexp/ ) {
      $self->attribute_as_element('SysExEvent', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'MIDI::XML::SysExEvent\' for attribute \'SysExEvent\'';
    }
  }
  return $self->attribute_as_element('SysExEvent');
}

##END_PACKAGE SmfEvent

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: f380a2f7-45af-11dd-8bf4-00502c05c241

package MIDI::XML::SysExEvent;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::SmfEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SysExEvent

MIDI::XML::SysExEvent is used for representing SysExEvent objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'sys-ex-event'; };
}

##END_PACKAGE SysExEvent

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 5e9693b9-45b0-11dd-8bf4-00502c05c241

package MIDI::XML::SystemExclusive;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::SysExEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SystemExclusive

MIDI::XML::SystemExclusive is used for representing SystemExclusive objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'SystemExclusive'; };
}

##END_PACKAGE SystemExclusive

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 86b3e50c-45b0-11dd-8bf4-00502c05c241

package MIDI::XML::EndOfExclusive;

use Carp;

our @ISA = qw(MIDI::XML::Element MIDI::XML::SysExEvent);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of EndOfExclusive

MIDI::XML::EndOfExclusive is used for representing EndOfExclusive objects 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'EndOfExclusive'; };
}

##END_PACKAGE EndOfExclusive

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 4f1e4c48-45ac-11dd-8bf4-00502c05c241

package MIDI::XML::timestamp_type;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of timestamp_type enumeration

MIDI::XML::timestamp_type - Module representing the timestamp_type enumeration. 

=head1 CONSTANTS for the timestamp_type enumeration

 Absolute                                  => 'Absolute'
 Delta                                     => 'Delta'

=cut

#===============================================================================
  *Absolute                                  = sub { return 'Absolute'; };
  *Delta                                     = sub { return 'Delta'; };

my @_literal_list_timestamp_type = (
  'Absolute'                                  => 'Absolute',
  'Delta'                                     => 'Delta',
);

#===============================================================================
# MIDI::XML::timestamp_type::Literals

=head1 METHODS for the timestamp_type enumeration

=head2 @Literals = MIDI::XML::timestamp_type::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = MIDI::XML::timestamp_type::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_timestamp_type;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 828bc502-4657-11dd-8bf4-00502c05c241

package MIDI::XML::control_change_enum;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of control_change_enum enumeration

MIDI::XML::control_change_enum - Module representing the control_change_enum enumeration. 

=head1 CONSTANTS for the control_change_enum enumeration

 BankSelectMSB                             => 0
 ModulationWheelMSB                        => 1
 BreathControllerMSB                       => 2
 FootControllerMSB                         => 4
 PortamentoTimeMSB                         => 5
 DataEntryMSB                              => 6
 ChannelVolumeMSB                          => 7
 BalanceMSB                                => 8
 PanMSB                                    => 10
 ExpressionControllerMSB                   => 11
 EffectControl1MSB                         => 12
 EffectControl2MSB                         => 13
 GeneralPurposeController1MSB              => 16
 GeneralPurposeController2MSB              => 17
 GeneralPurposeController3MSB              => 18
 GeneralPurposeController4MSB              => 19
 BankSelectLSB                             => 32
 ModulationWheelLSB                        => 33
 BreathControllerLSB                       => 34
 FootControllerLSB                         => 36
 PortamentoTimeLSB                         => 37
 DataEntryLSB                              => 38
 ChannelVolumeLSB                          => 39
 BalanceLSB                                => 40
 PanLSB                                    => 42
 ExpressionControllerLSB                   => 43
 EffectControl1LSB                         => 44
 EffectControl2LSB                         => 45
 GeneralPurposeController1LSB              => 48
 GeneralPurposeController2LSB              => 49
 GeneralPurposeController3LSB              => 50
 GeneralPurposeController4LSB              => 51
 DamperPedal                               => 64
 Portamento                                => 65
 Sostenuto                                 => 66
 SoftPedal                                 => 67
 LegatoFootswitch                          => 68
 Hold2                                     => 69
 SoundVariation                            => 70
 Timbre                                    => 71
 ReleaseTime                               => 72
 AttackTime                                => 73
 Brightness                                => 74
 DecayTime                                 => 75
 VibratoRate                               => 76
 VibratoDepth                              => 77
 VibratoDelay                              => 78
 SoundController10                         => 79
 GeneralPurposeController5                 => 80
 GeneralPurposeController6                 => 81
 GeneralPurposeController7                 => 87
 GeneralPurposeController8                 => 83
 PortamentoControl                         => 84
 ReverbSendLevel                           => 91
 TremoloDepth                              => 92
 ChorusSendLevel                           => 93
 Effects4Depth                             => 94
 Effects5Depth                             => 95
 DataIncrement                             => 96
 DataDecrement                             => 97
 NonRegisteredParameterNumberLSB           => 98
 NonRegisteredParameterNumberMSB           => 99
 RegisteredParameterNumberLSB              => 100
 RegisteredParameterNumberMSB              => 101

=cut

#===============================================================================
  *BankSelectMSB                             = sub { return 0; };
  *ModulationWheelMSB                        = sub { return 1; };
  *BreathControllerMSB                       = sub { return 2; };
  *FootControllerMSB                         = sub { return 4; };
  *PortamentoTimeMSB                         = sub { return 5; };
  *DataEntryMSB                              = sub { return 6; };
  *ChannelVolumeMSB                          = sub { return 7; };
  *BalanceMSB                                = sub { return 8; };
  *PanMSB                                    = sub { return 10; };
  *ExpressionControllerMSB                   = sub { return 11; };
  *EffectControl1MSB                         = sub { return 12; };
  *EffectControl2MSB                         = sub { return 13; };
  *GeneralPurposeController1MSB              = sub { return 16; };
  *GeneralPurposeController2MSB              = sub { return 17; };
  *GeneralPurposeController3MSB              = sub { return 18; };
  *GeneralPurposeController4MSB              = sub { return 19; };
  *BankSelectLSB                             = sub { return 32; };
  *ModulationWheelLSB                        = sub { return 33; };
  *BreathControllerLSB                       = sub { return 34; };
  *FootControllerLSB                         = sub { return 36; };
  *PortamentoTimeLSB                         = sub { return 37; };
  *DataEntryLSB                              = sub { return 38; };
  *ChannelVolumeLSB                          = sub { return 39; };
  *BalanceLSB                                = sub { return 40; };
  *PanLSB                                    = sub { return 42; };
  *ExpressionControllerLSB                   = sub { return 43; };
  *EffectControl1LSB                         = sub { return 44; };
  *EffectControl2LSB                         = sub { return 45; };
  *GeneralPurposeController1LSB              = sub { return 48; };
  *GeneralPurposeController2LSB              = sub { return 49; };
  *GeneralPurposeController3LSB              = sub { return 50; };
  *GeneralPurposeController4LSB              = sub { return 51; };
  *DamperPedal                               = sub { return 64; };
  *Portamento                                = sub { return 65; };
  *Sostenuto                                 = sub { return 66; };
  *SoftPedal                                 = sub { return 67; };
  *LegatoFootswitch                          = sub { return 68; };
  *Hold2                                     = sub { return 69; };
  *SoundVariation                            = sub { return 70; };
  *Timbre                                    = sub { return 71; };
  *ReleaseTime                               = sub { return 72; };
  *AttackTime                                = sub { return 73; };
  *Brightness                                = sub { return 74; };
  *DecayTime                                 = sub { return 75; };
  *VibratoRate                               = sub { return 76; };
  *VibratoDepth                              = sub { return 77; };
  *VibratoDelay                              = sub { return 78; };
  *SoundController10                         = sub { return 79; };
  *GeneralPurposeController5                 = sub { return 80; };
  *GeneralPurposeController6                 = sub { return 81; };
  *GeneralPurposeController7                 = sub { return 87; };
  *GeneralPurposeController8                 = sub { return 83; };
  *PortamentoControl                         = sub { return 84; };
  *ReverbSendLevel                           = sub { return 91; };
  *TremoloDepth                              = sub { return 92; };
  *ChorusSendLevel                           = sub { return 93; };
  *Effects4Depth                             = sub { return 94; };
  *Effects5Depth                             = sub { return 95; };
  *DataIncrement                             = sub { return 96; };
  *DataDecrement                             = sub { return 97; };
  *NonRegisteredParameterNumberLSB           = sub { return 98; };
  *NonRegisteredParameterNumberMSB           = sub { return 99; };
  *RegisteredParameterNumberLSB              = sub { return 100; };
  *RegisteredParameterNumberMSB              = sub { return 101; };

my @_literal_list_control_change_enum = (
  'BankSelectMSB'                             => 0,
  'ModulationWheelMSB'                        => 1,
  'BreathControllerMSB'                       => 2,
  'FootControllerMSB'                         => 4,
  'PortamentoTimeMSB'                         => 5,
  'DataEntryMSB'                              => 6,
  'ChannelVolumeMSB'                          => 7,
  'BalanceMSB'                                => 8,
  'PanMSB'                                    => 10,
  'ExpressionControllerMSB'                   => 11,
  'EffectControl1MSB'                         => 12,
  'EffectControl2MSB'                         => 13,
  'GeneralPurposeController1MSB'              => 16,
  'GeneralPurposeController2MSB'              => 17,
  'GeneralPurposeController3MSB'              => 18,
  'GeneralPurposeController4MSB'              => 19,
  'BankSelectLSB'                             => 32,
  'ModulationWheelLSB'                        => 33,
  'BreathControllerLSB'                       => 34,
  'FootControllerLSB'                         => 36,
  'PortamentoTimeLSB'                         => 37,
  'DataEntryLSB'                              => 38,
  'ChannelVolumeLSB'                          => 39,
  'BalanceLSB'                                => 40,
  'PanLSB'                                    => 42,
  'ExpressionControllerLSB'                   => 43,
  'EffectControl1LSB'                         => 44,
  'EffectControl2LSB'                         => 45,
  'GeneralPurposeController1LSB'              => 48,
  'GeneralPurposeController2LSB'              => 49,
  'GeneralPurposeController3LSB'              => 50,
  'GeneralPurposeController4LSB'              => 51,
  'DamperPedal'                               => 64,
  'Portamento'                                => 65,
  'Sostenuto'                                 => 66,
  'SoftPedal'                                 => 67,
  'LegatoFootswitch'                          => 68,
  'Hold2'                                     => 69,
  'SoundVariation'                            => 70,
  'Timbre'                                    => 71,
  'ReleaseTime'                               => 72,
  'AttackTime'                                => 73,
  'Brightness'                                => 74,
  'DecayTime'                                 => 75,
  'VibratoRate'                               => 76,
  'VibratoDepth'                              => 77,
  'VibratoDelay'                              => 78,
  'SoundController10'                         => 79,
  'GeneralPurposeController5'                 => 80,
  'GeneralPurposeController6'                 => 81,
  'GeneralPurposeController7'                 => 87,
  'GeneralPurposeController8'                 => 83,
  'PortamentoControl'                         => 84,
  'ReverbSendLevel'                           => 91,
  'TremoloDepth'                              => 92,
  'ChorusSendLevel'                           => 93,
  'Effects4Depth'                             => 94,
  'Effects5Depth'                             => 95,
  'DataIncrement'                             => 96,
  'DataDecrement'                             => 97,
  'NonRegisteredParameterNumberLSB'           => 98,
  'NonRegisteredParameterNumberMSB'           => 99,
  'RegisteredParameterNumberLSB'              => 100,
  'RegisteredParameterNumberMSB'              => 101,
);

#===============================================================================
# MIDI::XML::control_change_enum::Literals

=head1 METHODS for the control_change_enum enumeration

=head2 @Literals = MIDI::XML::control_change_enum::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = MIDI::XML::control_change_enum::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_control_change_enum;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: c396dec6-46f1-11dd-8bf4-00502c05c241

package MIDI::XML::mtc_category;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of mtc_category enumeration

MIDI::XML::mtc_category - Module representing the mtc_category enumeration. 

=head1 CONSTANTS for the mtc_category enumeration

 FrameLSNibble                             => 0
 FrameMSNibble                             => 1
 SecsLSNibble                              => 2
 SecsMSNibble                              => 3
 MinsLSNibble                              => 4
 MinsMSNibble                              => 5
 HrsLSNibble                               => 6
 HrsMSNibbleSMPTEType                      => 7

=cut

#===============================================================================
  *FrameLSNibble                             = sub { return 0; };
  *FrameMSNibble                             = sub { return 1; };
  *SecsLSNibble                              = sub { return 2; };
  *SecsMSNibble                              = sub { return 3; };
  *MinsLSNibble                              = sub { return 4; };
  *MinsMSNibble                              = sub { return 5; };
  *HrsLSNibble                               = sub { return 6; };
  *HrsMSNibbleSMPTEType                      = sub { return 7; };

my @_literal_list_mtc_category = (
  'FrameLSNibble'                             => 0,
  'FrameMSNibble'                             => 1,
  'SecsLSNibble'                              => 2,
  'SecsMSNibble'                              => 3,
  'MinsLSNibble'                              => 4,
  'MinsMSNibble'                              => 5,
  'HrsLSNibble'                               => 6,
  'HrsMSNibbleSMPTEType'                      => 7,
);

#===============================================================================
# MIDI::XML::mtc_category::Literals

=head1 METHODS for the mtc_category enumeration

=head2 @Literals = MIDI::XML::mtc_category::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = MIDI::XML::mtc_category::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_mtc_category;
}

1

__END__

=head1 AUTHOR

Brian M. Ames, E<lt>bmames@apk.netE<gt>

=head1 SEE ALSO

L<XML::Parser>.

=head1 COPYRIGHT and LICENSE

Copyright 2008 Brian M. Ames.  This software may be used under the terms of
the GPL and Artistic licenses, the same as Perl itself.

=cut
