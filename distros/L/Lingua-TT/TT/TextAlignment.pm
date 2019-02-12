## -*- Mode: CPerl -*-
## File: Lingua::TT::TextAlignment.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT Utils: alignment raw text <-> tokenized text


package Lingua::TT::TextAlignment;
use Lingua::TT::Persistent;
use Lingua::TT::Document;
use Carp;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(Lingua::TT::Persistent Exporter);

our @EXPORT = qw();
our %EXPORT_TAGS = (
		    escape=>[qw(escape_rtt unescape_rtt)],
		   );
$EXPORT_TAGS{all} = [map {@$_} values %EXPORT_TAGS];
our @EXPORT_OK    = @{$EXPORT_TAGS{all}};

##==============================================================================
## Constructors etc.

## $ta = CLASS_OR_OBJECT->new(%opts)
## + %opts, %$ta:
##    buf=>$buf,		##-- raw text buffer
##    lines=>\@lines,		##-- raw tt-lines loaded with Lingua::TT::IO->getLines
##    off=>$off, len=>$len,	##-- byte offsets and lengths in $buf of lines in \@lines
##				##   : ($o,$l)=(vec($off,$i,32),vec($len,$i,32)) iff bytes::susbstr($buf,$o,$l) ~ $lines->[$i]
sub new {
  my $that = shift;
  my $ta = bless({
		  buf=>'',
		  lines=>[],
		  off=>'', len=>'',
		  @_
		 }, ref($that)||$that);
  return $ta;
}

## undef = $ta->clear()
sub clear {
  my $ta = shift;
  @{$ta->{lines}} = qw();
  %$ta = %{$ta->new(lines=>$ta->{lines})};
  return $ta;
}


##==============================================================================
## Methods: I/O

##--------------------------------------------------------------
## Methods: I/O: RTT ("RAW \t TEXT \t ...", with %%$c= comments)

## $str_escaped = escape_rtt($str)
sub escape_rtt {
  my $s = shift;
  $s =~ s/\\/\\\\/g;
  $s =~ s/\f/\\f/g;
  $s =~ s/\t/\\t/g;
  $s =~ s/\r/\\r/g;
  $s =~ s/\n/\\n/g;
  return $s;
}

## $str_escaped = unescape_rtt($str)
sub unescape_rtt {
  my $s = shift;
  $s =~ s/\\\\/\\/g;
  $s =~ s/\\f/\f/g;
  $s =~ s/\\t/\t/g;
  $s =~ s/\\r/\r/g;
  $s =~ s/\\n/\n/g;
  return $s;
}

## $ta = $ta->toRttFile($filename_or_fh,%opts)
##  + saves $ta to rtt-file
BEGIN { *save = *saveRtt = *saveRttFile = *saveNativeFile = *saveNativeFh = \&toRttFile; }
sub toRttFile {
  my ($ta,$file,%opts) = @_;
  my $ttio = Lingua::TT::IO->toFile($file,%opts)
    or die((ref($ta)||$ta)."::toRttFile(): open failed for '$file': $!");
  my $fh = $ttio->{fh};

  no bytes;
  my $bufr = \$ta->{buf};
  my $offr = \$ta->{off};
  my $lenr = \$ta->{len};
  my $buf_is_utf8 = utf8::is_utf8($$bufr);
  my ($pos,$i) = (0,0);
  my ($l,$off,$len,$t0, $t,$rest);
  my $ctxt = '';
  my $compact = $opts{compact};
  my $wrote_rtt_header = 0;
  foreach (@{$ta->{lines}}) {
    $off = vec($$offr,$i,32);
    $len = vec($$lenr,$i,32);

    ##-- check for raw-text prefix
    if ($pos < $off) {
      $ctxt .= escape_rtt(bytes::substr($$bufr,$pos,$off-$pos));
      utf8::decode($ctxt) if ($buf_is_utf8);
      $ctxt =~ s/%%.*?%%//g if (!$opts{keep_text_comments});
      if ($ctxt ne '' && (!$compact || $ctxt !~ /^\s+$/)) {
	$fh->print("%%\$c=$ctxt\n");
	$ctxt = '';
      }
    }

    if (/^%%\$RTT:/) {
      ##-- RTT processing instruction: skip it
      next;
    }
    elsif (/^%%/ || /^$/) {
      ##-- eos or comment
      $l = $_;
    } else {
      ##-- normal word
      $t0 = bytes::substr($$bufr,$off,$len);
      utf8::decode($t0) if ($buf_is_utf8);

      if ($compact) {
	##-- compact mode: check for normalized text identity (on DECODED text)
	($t,$rest) = split(/\t/,$_,2);
	if ($t eq $t0) {
	  $t0 = escape_rtt($t0);
	} else {
	  $t0 = escape_rtt("$t0 \$= $t");
	}
	$l = "$ctxt$t0".(defined($rest) ? "\t$rest" : '');
	$ctxt = '';
      } else {
	##-- prolix mode
	$l = escape_rtt($t0)."\t".$_;
      }

      ##-- ensure header before first word
      if (!$wrote_rtt_header) {
	$fh->print("%%\$RTT:COMPACT=", ($compact ? 1 : 0), "\n");
	$wrote_rtt_header = 1;
      }
    }

    $l .= "\n" if ($l !~ /\R\z/);
    $fh->print($l);
    ++$i;
    $pos = $off + $len;
  }
  if ($pos < bytes::length($$bufr)) {
    $ctxt = escape_rtt(bytes::substr($$bufr,$pos,bytes::length($$bufr)-$pos));
    utf8::decode($ctxt) if ($buf_is_utf8);
    $fh->print("%%\$c=$ctxt\n") if ($ctxt ne '');
  }
  $ttio->close();
}

## $ta = $ta->fromRttFile($filename_or_fh,%opts)
##  + parses @$tta{qw(buf lines off len) from $filename_or_fh
BEGIN { *load = *loadRtt = *loadRttFile = *loadNativeFile = *loadNativeFh = \&fromRttFile; }
sub fromRttFile {
  my ($ta,$file,%opts) = @_;
  $ta = $ta->new() if (!ref($ta));
  my $ttio = Lingua::TT::IO->fromFile($file,%opts)
    or die((ref($ta)||$ta)."::fromRttFile(): open failed for '$file': $!");
  my $fh = $ttio->{fh};

  no bytes;
  $ta->clear();
  my $bufr = \$ta->{buf};
  my $offr = \$ta->{off};
  my $lenr = \$ta->{len};
  my $lines = $ta->{lines};
  my ($pos,$i) = (0,0);
  my ($raw,$rest);
  my $compact = $opts{compact};
  my ($ctxt,$t,$rt);
  while (defined($_=<$fh>)) {
    chomp;
    if (/^%%\$RTT:COMPACT=(.*)$/) {
      $compact = $1;
      next;
    }
    elsif (/^%%\$c=(.*)$/) {
      $raw    = unescape_rtt($1);
      $$bufr .= $raw;
      $pos   += bytes::length($raw);
    }
    elsif (/^%%/ || /^$/) {
      push(@$lines, $_);
      vec($$offr,$i,32) = $pos;
      vec($$lenr,$i,32) = 0;
      ++$i;
    }
    else {
      ($raw,$rest) = split(/\t/,$_,2);
      $raw = unescape_rtt($raw);

      if ($compact) {
	##-- compact mode: decode word-text and prepend it to $rest
	if ($raw =~ s/^(\s+)//) {
	  $ctxt   = $1;
	  $$bufr .= $ctxt;
	  $pos   += bytes::length($ctxt);
	}
	if (($rt=$raw) =~ /^(.*) \$= (.*)$/s) {
	  ($raw,$t) = ($1,escape_rtt($2));
	} else {
	  $t = escape_rtt($raw);
	}
	$rest = $t . (defined($rest) ? "\t$rest" : '');
      }

      vec($$offr, $i, 32) = $pos;
      vec($$lenr, $i, 32) = bytes::length($raw);
      $$bufr .= $raw;
      push(@$lines, $rest);
      ++$i;
      $pos += bytes::length($raw);
    }
  }
  $ttio->close();
  return $ta;
}

##--------------------------------------------------------------
## Methods: I/O: TT (+ offsets)
## + to be used in conjunction with TextBuffer I/O methods

## $ta = $ta->parseOffsetLines()
##  + parses @$ta{qw(off len)} from $ta->{lines}
##  + destructively alters $ta->{lines}
sub parseOffsetLines {
  my $ta = shift;
  my $offr = \$ta->{off};
  my $lenr = \$ta->{len};
  $$offr = '';
  $$lenr = '';
  my ($pos,$i) = (0,0);
  my ($woff,$wlen);
  foreach (@{$ta->{lines}}) {
    if (!/^%%/ && s/^([^\t]*)\t([0-9]+) ([0-9]+)/$1/) {
      ($woff,$wlen) = ($2,$3);
    } else {
      ($woff,$wlen) = ($pos,0);
    }
  } continue {
    vec($$offr,$i,32) = $woff;
    vec($$lenr,$i,32) = $wlen;
    $pos = $woff+$wlen;
    ++$i;
  }
  return $ta;
}

## $ta = $CLASS_OR_OBJECT->fromTTFile($filename_or_fh,%opts)
##  + parses $ta->{doc} from file
BEGIN { *loadTT = *loadTTFile = \&fromTTFile; }
sub fromTTFile {
  my ($ta,$file,%opts) = @_;
  $ta = $ta->new() if (!ref($ta));
  my $ttio = Lingua::TT::IO->fromFile($file,%opts)
    or die((ref($ta)||$ta)."::fromTTFile(): open failed for '$file': $!");
  $ta->{lines} = $ttio->getLines();
  $ttio->close();
  return $ta->parseOffsetLines();
}

## $ta = $ta->toTTFile($filename_or_fh,%opts)
##  + saves $ta to file (with offset+len pairs)
BEGIN { *saveTT = *saveTTFile = \&toTTFile; }
sub toTTFile {
  my ($ta,$file,%opts) = @_;
  my $ttio = Lingua::TT::IO->toFile($file,%opts)
    or die((ref($ta)||$ta)."::toTTFile(): open failed for '$file': $!");
  my $fh = $ttio->{fh};
  my $lines = $ta->{lines};
  my $offr  = \$ta->{off};
  my $lenr  = \$ta->{len};
  my ($l,$w,$rest);
  my $i=0;
  foreach (@$lines) {
    if (/^$/ || /^%%/) {
      $l = $_;
    } else {
      ($w,$rest) = split(/\t/,$_,2);
      $l = "$w\t".vec($$offr,$i,32)." ".vec($$lenr,$i,32).(defined($rest) ? "\t$rest" : '');
    }
    $l .= "\n" if ($l !~ /\R\z/);
  } continue {
    $fh->print($l);
    ++$i;
  }
  $ttio->close();
  return $ta;
}

##--------------------------------------------------------------
## Methods: I/O: text-buffer
## + to be used in conjunction with TTFile I/O methods

## $ta = $ta->loadTextFile($filename_or_fh,%opts)
## + %opts:
##    raw => $bool,	##-- set to avoid utf8 flag on buf
BEGIN { *loadBuffer = \&loadTextFile; }
sub loadTextFile {
  my ($ta,$file,%opts) = @_;
  my $fh = ref($file) ? $file : IO::File->new("<$file");
  die((ref($ta)||$ta),"::loadTextFile(): open failed for '$file': $!") if (!$fh);
  if ($opts{encoding}) {
    binmode($fh,":encoding($opts{encoding})");
  } elsif ($opts{raw}) {
    binmode($fh,':raw');
  } else {
    binmode($fh,':utf8');
  }
  local $/=undef;
  $ta->{buf} = <$fh>;
  $fh->close();
  return $ta;
}

## $ta = $ta->saveTextFile($filename_or_fh,%opts)
## + %opts:
##    raw => $bool,	##-- set to avoid utf8 flag on buf
BEGIN { *saveBuffer = \&saveTextFile; }
sub saveTextFile {
  my ($ta,$file,%opts) = @_;
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  die((ref($ta)|$ta),"::saveTextFile(): open failed for '$file': $!") if (!$fh);
  if ($opts{encoding}) {
    binmode($fh,":encoding($opts{encoding})");
  } elsif ($opts{raw}) {
    binmode($fh,':raw');
  } else {
    binmode($fh,':utf8') if (utf8::is_utf8($ta->{buf}));
  }
  $fh->print($ta->{buf});
  $fh->close();
  return $ta;
}



##==============================================================================
## Footer
1;

__END__
