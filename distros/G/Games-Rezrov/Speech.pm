package Games::Rezrov::Speech;
# ZIO functions for speech synthesis (output) and recognition (input)
# mne feb. 2004
#
# HACK: this is just a subset of ZIO functions rather than a complete
# module.  I did it this way just to isolate the speech clutter from
# ZIO_Generic.

# will probably have to change radically as new speech APIs added

# ADD:
#  - error message method explaining problem if enable calls fail
#  - event-based recognition model if ZIO can handle it: allow
#    user also to type commands if they want (Tk interface could handle this,
#    but a ZIO using say '$line = <STDIN>' couldn't due to hang)

use strict;

use Games::Rezrov::ZIO_Tools;

use Games::Rezrov::MethodMaker qw(
  speaking
  listening

  voicetext
  voice_dictation
  recognized_phrases
 
  recog_dictionary_setup

  speech_synthesis_error
  speech_recognition_error
);

# constants copied from Microsoft Speech SDK\Include\speech.h
# ...are they accessible somewhere "officially" in Perl API?  Dunno.
use constant VSRMODE_OFF         => 0x00000002;
use constant VSRMODE_DISABLED    => 0x00000001;
use constant VSRMODE_CMDPAUSED   => 0x00000004;
use constant VSRMODE_CMDONLY     => 0x00000010;
use constant VSRMODE_DCTONLY     => 0x00000020;
use constant VSRMODE_CMDANDDCT   => 0x00000040;

sub init_speech_synthesis {
  #
  # try to enable speech output, return success or failure
  # 
  my ($self) = @_;
  my $result = 0;
  if (find_module('Win32::SAPI4')) {
    require Win32::SAPI4;
    require Win32::OLE;
    import Win32::SAPI4;
    import Win32::OLE;
    my $vt = Win32::SAPI4::VoiceText->new();
    $self->voicetext($vt);
    $result = 1;
  } else {
    $self->speech_synthesis_error("Can't enable speech synthesis because the required support module Win32::SAPI4 is not installed.");
  }
  return $self->speaking($result);
}

sub test_speech_recognition {
  #
  # interactively debug recognition engine
  #
  my ($self) = @_;
  if (find_module('Win32::SAPI4')) {
    require Win32::SAPI4;
    require Win32::OLE;
    import Win32::SAPI4;
    import Win32::OLE;

    my $done = 0;
    $SIG{INT} = sub {
      print "[caught interrupt]\n";
      $done = 1;
    };

    my %stop_words = map {$_, 1} qw(
				    stop
				    quit
				    exit
				    finish
				    done
				   );

    my $comment_tag = '==>';
    my $event_monitor = sub {
      my ($obj, $event, @args) = @_;
      printf "%s\n", join ",", $event, @args;
      $done = 1 if $event eq "PhraseFinish" and exists $stop_words{$args[1]};
    };
    
    my $vd = Win32::SAPI4::VoiceDictation->new();
    Win32::OLE->WithEvents($vd, $event_monitor);
    my $mode = $vd->Mode;
    printf "Speech recognition mode is %d (%s)\n", $mode, describe_dictation_mode($mode);

    if (is_dictation_enabled($vd)) {
      printf "%s Say \"stop\", \"quit\", \"exit\" or hit ctrl-c to finish.\n\n", $comment_tag;

      $vd->Deactivate();
      $vd->Activate();

      while (!$done) {
	Win32::OLE->SpinMessageLoop();
	Win32::Sleep(20);
      }

      $vd->Deactivate();
    } else {
      printf "PROBLEM: speech recognition won't work because dictation is not enabled!\n";
      print "Run the Microsoft Dictation application and enable it.\n";
    }
  }
}

sub describe_dictation_mode {
  # static
  my ($mode) = @_;
  my $desc;
  if ($mode == VSRMODE_DISABLED) {
    $desc = "disabled";
  } elsif ($mode == VSRMODE_OFF) {
    $desc = "off";
  } elsif ($mode == VSRMODE_CMDPAUSED) {
    $desc = "paused";
  } elsif ($mode == VSRMODE_CMDONLY) {
    $desc = "voice commands only";
  } elsif ($mode == VSRMODE_DCTONLY) {
    $desc = "dictation only";
  } elsif ($mode == VSRMODE_CMDANDDCT) {
    $desc = "voice commands and dictation";
  } else {
    $desc = "UNKNOWN (??)";
  }
  return $desc;
}

sub speak {
  my ($self, $string, %options) = @_;
  
  $string =~ s/([A-Z]\w+ )(I+)/$1 . length($2)/e;
  # convert Roman numerals
  # "Zork I" should be pronounced "Zork 1" rather than "Zork Eye"

  $string =~ s/(\w+ \d+ \/ Serial number )(\d\d)(\d\d)(\d\d)/$1 $2 $3 $4/i;
  # pronounce serial numbers for what they mean: YY MM DD
  # "86 09 04" rather than "860,904"

  $string =~ s/Infocom/InfoCom/;
  # phonetic hack to aid SAPI pronunciation; "info-cum" => "info-com"
  
  $string =~ s/^Copyright \(c\)/Copyright/;
  # just "copyright", not "copyright (c)"

  $string =~ s/^\[(.*)\]$/$1/;
  # don't pronounce the brackets around asides, e.g.
  # "[I don't know the work "bogus".]"

  $string =~ s/\.{3,}/\. /;
  # sometimes pronounces this as "point", e.g.
  # "If you insist.... Poof, you're dead!"

  $string =~ s/\"$//;
  # prevent pronouncing literal "quote" at end, e.g. Zork 1 reading leaflet

  return if $string eq ">";
  # don't speak game prompt, HACK

  my $vt = $self->voicetext();

  my $gender = $options{"-gender"} || 1;
#  my $i = $vt->find("Mfg=Microsoft;Gender=2;ModeName=Sam");
  my $i = $vt->find("Gender=$gender");
  $vt->Select($i);
  
#  $vt->Speed(200);
  # why doesn't this method work?

  $self->update();

  my $speech_done = 0;
  my $finish_callback = sub {
    my ($obj, $event, @args) = @_;
    $speech_done = 1 if $event eq "SpeakingDone";
    # wait for event signalling speech output is complete
  };
    
  Win32::OLE->WithEvents($vt, $finish_callback);
  $vt->Speak($string);

  while (!$speech_done) {
    # wait for speech output to finish
    Win32::OLE->SpinMessageLoop();
    Win32::Sleep(20);
  }
}

sub init_speech_recognition {
  #
  # try to enable speech input, return success or failure
  # 
  my ($self) = @_;
  my $result = 0;
  if (find_module('Win32::SAPI4')) {
    require Win32::SAPI4;
    require Win32::OLE;
    import Win32::SAPI4;
    import Win32::OLE;

    my $vd = Win32::SAPI4::VoiceDictation->new();
    $vd->Deactivate();

    $SIG{INT} = sub {
      $vd->Deactivate();
    };

    $self->recognized_phrases([]);
    
    my $event_monitor = sub {
      my ($obj, $event, @args) = @_;
#      printf "%s\n", join ",", $event, @args;
      if ($event eq "PhraseFinish") {
	push @{$self->recognized_phrases}, $args[1];
      }
    };
    
    Win32::OLE->WithEvents($vd, $event_monitor);

    my $mode = $vd->Mode;
    if (is_dictation_enabled($vd)) {
      # OK to proceed
      $self->voice_dictation($vd);
      $vd->Activate();
      $result = 1;
    } else {
      $self->speech_recognition_error("Can't enable speech recognition because dictation is not enabled.  Run Microsoft Dictation and enable it, then try again.");
    }
  } else {
    $self->speech_recognition_error("Can't enable speech recognition because the required support module Win32::SAPI4 is not installed.");
  }
  return $self->listening($result);
}

sub recognize_line {
  my ($self) = @_;
  unless ($self->recog_dictionary_setup()) {
    if (my $zd = Games::Rezrov::StoryFile::get_zdict()) {
      my @all_words = keys %{$zd->decoded_by_word};
      $self->voice_dictation->Words(join " ", @all_words);
      # feed game dictionary into recognition engine as hints.
      # Pros: allows engine to recognize odds words like "grue".
      # Cons: can reveal internally-truncated words ("mailbo" instead of "mailbox").
      $self->recog_dictionary_setup(1);
    }
  }

  $self->recognized_phrases([]);
  while (1) {
    if (is_dictation_enabled($_[0]->voice_dictation)) {
      # dictation still enabled, wait for user to say something
      my $phrases = $self->recognized_phrases();
      if (@{$phrases}) {
	$self->recognized_phrases([]);
	return $phrases->[$#$phrases];
      } else {
	Win32::OLE->SpinMessageLoop();
	Win32::Sleep(20);
      }
    } else {
      # dictation no longer enabled, so break and return control to keyboard
      $self->write_string("[dictation stopped]");
      $self->listening(0);
      return "";
    }
  }
}

sub is_dictation_enabled {
  # STATIC
  my ($vd) = @_;
  die unless $vd;
  my $mode = $vd->Mode;
  return $mode == VSRMODE_DCTONLY or $mode == VSRMODE_CMDANDDCT;
}

1;
