## -*- Mode: CPerl -*-
## File: Lingua::TT::Diff.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT I/O: Document diffs


package Lingua::TT::Diff;
use Lingua::TT::Document;

use File::Temp;
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals & Constants

our $DIFF = 'diff'; ##-- search in path

our $vl_silent = 0;
our $vl_error = 1;
our $vl_warn = 2;
our $vl_info = 3;
our $vl_debug = 4;
our $vl_trace = 5;

our $VERBOSE = $vl_warn;

##==============================================================================
## Constructors etc.

## $diff = CLASS_OR_OBJECT->new(%opts)
## + %$diff, %opts
##   ##-- sequences to compare
##   seq1  => \@seq1,     ##-- raw TT line data (default: EMPTY); see $diff->sequenceXYZ() methods
##   seq2  => \@seq2,     ##-- raw TT line data (default: EMPTY); see $diff->sequenceXYZ() methods
##   ##
##   file1 => $file1,     ##-- source name for $seq1 (default: none)
##   file2 => $file2,     ##-- source name for $seq2 (default: none)
##   ##
##   key1  => \&keysub,   ##-- keygen sub for $seq1 (default=\&ksText), called as $key=$keysub->($diff,$line)
##   key2  => \&keysub,   ##-- keygen sub for $seq2 (default=\&ksText), called as $key=$keysub->($diff,$line)
##   ##
##   aux1 => \%aux1,       ##-- aux data: ($seq1i=>\@auxLinesBeforeSeq1i)
##   aux2 => \%aux2,       ##-- aux data: ($seq2i=>\@auxLinesBeforeSeq2i)
##   auxEOS  => $bool,     ##-- if true, EOS lines will be considered "aux" data (default=false)
##   auxComments => $bool, ##-- if true, comment lines will be considered "aux" data (default=false)
##   diffopts => $opts,    ##-- options passed to diff (string)
##   ##
##   ##-- misc options
##   keeptmp => $bool,    ##-- if true, temp files will not be unlinked (default=false)
##   verbose => $level,   ##-- verbosity level (default: $vl_warn)
##   ##
##   ##-- cache data
##   tmpfile1 => $tmp1,   ##-- filename: temporary key-file dump for $seq1
##   tmpfile2 => $tmp2,   ##-- filename: temporary key-file dump for $seq2
##   ##
##   ##-- diff data
##   hunks => \@hunks,    ##-- difference hunks: [$hunk1,$hunk2,...]
##                        ## + each $hunk is: [$opCode, $min1,$max1, $min2,$max2, $fix, $cmt]
##                        ## + $opCode is as for traditional 'diff':
##                        ##    'a' (add)   : Add     @$seq2[$min2..$max2], align after ($min1==$max1) of $seq1
##                        ##    'd' (delete): Delete  @$seq1[$min1..$max1], align after ($min2==$max2) of $seq2
##                        ##    'c' (change): Replace @$seq1[$min1..$max1] with @$seq2[$min2..$max2]
##                        ## + $fix is one of:
##                        ##         0  : unresolved
##                        ##    $which  : int (1 or 2): use corresponding item(s) of "seq${which}"
##                        ##    \@items : ARRAY-ref: resolve conflict with \@items
##                        ## + $cmt is a comment for the fix
sub new {
  my $that = shift;
  my $diff = bless({
		    ##-- sequences to compare
		    seq1 => [],
		    seq2 => [],
		    file1=>undef,
		    file2=>undef,
		    key1 => \&ksText,
		    key2 => \&ksText,

		    ##-- aux data
		    aux1 => {},
		    aux2 => {},
		    auxEOS => 0,
		    auxComments => 0,
		    diffopts => '',

		    ##-- cache data
		    keeptmp  => 0,
		    verbose => $VERBOSE,
		    tmpfile1 => undef,
		    tmpfile2 => undef,

		    ##-- diff data
		    hunks => [],

		    ##-- user args
		    @_,
		   }, ref($that)||$that);

  return $diff;
}

## $diff = $diff->reset()
##  + clears cache and diff data
sub reset {
  my $diff = shift;
  $diff->clearCache;
  @{$diff->{seq1}} = qw();
  @{$diff->{seq2}} = qw();
  %{$diff->{aux1}} = qw();
  %{$diff->{aux2}} = qw();
  @{$diff->{hunks}} = qw();
  delete(@$diff{qw(file1 file2)});
  return $diff;
}

## $diff = $diff->clearCache()
##  + clears & unlinks cached temp files
sub clearCache {
  my $diff = shift;
  #@{$diff->{seq1}} = qw();
  #@{$diff->{seq2}} = qw();
  unlink($_) foreach (grep {!$diff->{keeptmp} && defined($_)} @$diff{qw(tmpfile1 tmpfile2)});
  delete(@$diff{qw(tmpfile1 tmpfile2)});
  return $diff;
}

##==============================================================================
## Methods: Key Generation Subs

## $key = $diff->ksText($line)
##  + key-generation sub: 'text' field
sub ksText {
  return ($_[1] =~ /^([^\t\n\r]*)/ ? $1 : '');
}

## $key = $diff->ksTag($line)
##  + key-generation sub: 'tag' field
sub ksTag {
  return ($_[1] =~ /^[^\t]*[\t\n\r][\n\r]*([^\t]*)/ ? $1 : '');
}

## $key = $diff->ksAll($line)
##  + key-generation sub: entire line
sub ksAll {
  return $_[1];
}

##==============================================================================
## Methods: messages

## undef = $CLASS_OR_OBJECT->vmsg($min_level, @message)
sub vmsg {
  my ($that,$level,@msg) = @_;
  print STDERR @msg if ((ref($that) ? $that->{verbose} : $VERBOSE) >= $level);
}

## undef = $CLASS_OR_OBJECT->vmsg1($min_level, @message)
sub vmsg1 {
  $_[0]->vmsg($_[1], (ref($_[0])||$_[0]), ": ", @_[2..$#_], "\n");
}



##==============================================================================
## Methods: Sequence Selection

##----------------------------------------------------------------------
## Methods: Sequence Selection: High-Level

## $diff = $diff->seq1($src,%opts)
##  + wrapper for $diff->setSequence(1,...)
sub seq1 {
  return $_[0]->setSequence(1,@_[1..$#_]);
}

## $diff = $diff->seq2($src,%opts)
##  + wrapper for $diff->setSequence(2,...)
sub seq2 {
  return $_[0]->setSequence(2,@_[1..$#_]);
}

## $diff = $diff->setSequence($which,$src,%opts)
##   + sets sequence $which (1 or 2) from $src
##   + $src may be one of the following:
##     - a Lingua::TT::Sentence object
##     - a Lingua::TT::Document object
##     - a Lingua::TT::IO object
##     - a flat array-ref of line-strings (without terminating newlines)
##     - a filehandle
##     - a filename
##   + implicitly calls $diff->setAux($which)
BEGIN { *isa = \&UNIVERSAL::isa; }
sub setSequence {
  my ($diff,$i,$src,%opts) = @_;
  $diff->vmsg1($vl_trace, "setSequence(i=$i, src=$src)");
  $i = $diff->checkWhich($i);
  my $rc = undef;
  if (isa($src,'Lingua::TT::Sentence')) {
    $rc = $diff->sequenceSentence($i,$src,%opts);   ##-- Lingua::TT::Sentence
  }
  elsif (isa($src,'Lingua::TT::Document')) {
    $rc = $diff->sequenceDocument($i,$src,%opts);   ##-- Lingua::TT::Document
  }
  elsif (isa($src,'Lingua::TT::IO')) {
    $rc = $diff->sequenceIO($i,$src,%opts);         ##-- Lingua::TT::IO
  }
  elsif (isa($src,'IO::Handle')) {
    $rc = $diff->sequenceFile($i,$src,%opts);       ##-- IO::Handle
  }
  elsif (isa($src,'ARRAY')) {
    $rc = $diff->sequenceLines($i,$src,%opts);      ##-- array of lines
  }
  elsif (!ref($src)) {
    $rc = $diff->sequenceFile($i,$src,%opts);       ##-- filename
  }
  else {
    $rc = $diff->sequenceFile($i,$src,%opts);         ##-- other ref; maybe a filehandle?
  }
  return defined($rc) ? $rc->setAux($i,%opts) : undef;
}

##----------------------------------------------------------------------
## Methods: Sequence Selection: Aux data

## $diff = $diff->setAux($which)
##  + auto-computes $diff->{"aux${which}"} from $diff->{"seq${which}"}
sub setAux {
  my ($diff,$which) = @_;
  $diff->vmsg1($vl_trace, "setAux(which=$which)");
  $which = $diff->checkWhich($which);

  my $seq = $diff->{"seq${which}"};
  my $aux = $diff->{"aux${which}"};
  my @oseq = qw();
  %$aux   = qw();
  my ($i,$j);
  for ($i=$j=0; $i<=$#$seq; ++$i,++$j) {
    if ( ($diff->{auxEOS} && $seq->[$i]=~/^$/) || ($diff->{auxComments} && $seq->[$i]=~/^\%\%/) ) {
      push(@{$aux->{$j}}, $seq->[$i]);
      --$j;
    } else {
      push(@oseq, $seq->[$i]);
    }
  }
  @$seq = @oseq;

  return $diff;
}


##----------------------------------------------------------------------
## Methods: Sequence Selection: Low-Level

## $which = $diff->checkWhich($which)
##  + common sanity check for '$which' values (1 or 2)
sub checkWhich {
  my ($diff,$which) = @_;
  $which = 0 if (!defined($which));
  if ($which != 1 && $which != 2) {
    confess(ref($diff)."::checkWhich(): sequence \$which must be 1 or 2 (got='$which'): assuming '1'");
    return 1;
  }
  return $which;
}

## $diff = $diff->sequenceDocument($which,$doc)
##  + populate sequence $which (1 or 2) from Lingua::TT::Document $doc
##  + calls $diff->sequenceSentence()
sub sequenceDocument {
  my ($diff,$which,$doc) = @_;
  $which = $diff->checkWhich($which);
  $diff->{"file${which}"}   = "$doc";     ##-- ugly but at least non-empty
  @{$diff->{"seq${which}"}} = map {join("\t",@$_)} @{$doc->flat};
  return $diff;
}

## $diff = $diff->sequenceSentence($which,$sent)
##  + populate sequence $which (1 or 2) from Lingua::TT::Sentence $sent
sub sequenceSentence {
  my ($diff,$which,$sent) = @_;
  $which = $diff->checkWhich($which);
  $diff->{"file${which}"}   = "$sent";    ##-- ugly but at least non-empty
  @{$diff->{"seq${which}"}} = map {join("\t",@$_)} @$sent;
  return $diff;
}

## $diff = $diff->sequenceLines($which,\@lines)
##  + populate sequence $which (1 or 2) from \@lines
sub sequenceLines {
  my ($diff,$which,$lines) = @_;
  $which = $diff->checkWhich($which);
  $diff->{"file${which}"}   = "$lines";
  @{$diff->{"seq${which}"}} = @$lines;
  return $diff;
}

## $diff = $diff->sequenceIO($which,$ttio)
##  + populate sequence $which (1 or 2) from Lingua::TT::IO $ttio
sub sequenceIO {
  my ($diff,$which,$ttio) = @_;
  $which = $diff->checkWhich($which);
  $diff->{"file${which}"}   = $ttio->{name};
  @{$diff->{"seq${which}"}} = $ttio->getLines;
  return $diff;
}

## $diff = $diff->sequenceFile($which,$filename_or_fh,%opts)
##   + generate sequence $which (1 or 2) from $filename_or_fh
##   + %opts are passed to Lingua::TT::IO->new()
sub sequenceFile {
  my ($diff,$which,$file,%opts) = @_;
  return $diff->sequenceIO($which,Lingua::TT::IO->fromFile($file,%opts));
}


##==============================================================================
## Methods: Comparison

## $diff = $diff->compare()
## $diff = $diff->compare($src2)
## $diff = $diff->compare($src1,$src2,%opts)
##  + compare currently selected sequences, wrapping setSequence() calls if required
sub compare {
  my ($diff,$src1,$src2,%opts) = @_;
  $diff->vmsg1($vl_trace, "compare(src1=$src1, $src2=src2)");

  ##-- args: sequences
  $diff->seq1($src1,%opts) if (defined($src1));
  $diff->seq2($src2,%opts) if (defined($src2));

  ##-- sanity check(s)
  confess(ref($diff)."::compare(): {seq1} undefined!") if (!$diff->{seq1});
  confess(ref($diff)."::compare(): {seq2} undefined!") if (!$diff->{seq2});

  ##-- create temp files
  my $file1 = $diff->seqTempFile(1);
  my $file2 = $diff->seqTempFile(2);

  ##-- compute & parse the diff (external call)
  $diff->vmsg1($vl_trace, "compare(): SYSTEM $DIFF $diff->{diffopts} $file1 $file2");
  my $fh = IO::File->new("$DIFF $diff->{diffopts} $file1 $file2|")
    or die(ref($diff)."::compare(): could not open pipe from system diff '$DIFF': $!");
  binmode($fh,':utf8');
  my ($op,$min1,$min2,$max1,$max2) = ('',0,0,0,0);
  @{$diff->{hunks}} = qw();
  my $hunks = $diff->{hunks};
  my ($line);
  while (defined($line=<$fh>)) {
    if ($line =~ /^(\d+)(?:\,(\d+))?([acd])(\d+)(?:\,(\d+))?$/) {
      ($min1,$max1, $op, $min2,$max2) = ($1,$2, $3, $4,$5);
    }
    else {
      next; ##-- ignore
    }
    if    ($op eq 'a') { $max1=$min1++; }
    elsif ($op eq 'd') { $max2=$min2++; }
    $max1 = $min1 if (!defined($max1));
    $max2 = $min2 if (!defined($max2));
    push(@$hunks, [$op, map {$_-1} $min1,$max1,$min2,$max2]);
  }
  $fh->close;

  ##-- unlink temp files
  if (!$diff->{keeptmp}) {
    unlink($file1);
    unlink($file2);
    delete(@$diff{qw(tmpfile1 tmpfile2)});
  }

  return $diff;
}

##----------------------------------------------------------------------
## Methods: Comparison: Low-Level

## $tmpfile = $diff->seqTempFile($which)
##  + creates temporary key-dump file $seq->{"tmpfile${which}"} for $diff->{"seq${which}"}
sub seqTempFile {
  my ($diff,$which) = @_;
  $diff->vmsg1($vl_trace, "seqTempFile(which=$which)");

  ##-- sanity check(s)
  $which = $diff->checkWhich($which);
  confess(ref($diff)."::seqFile($which): sequence '$which' is not defined!")
    if (!$diff->{"seq${which}"});

  my ($fh,$filename);
  if (!defined($filename=$diff->{"tmpfile${which}"})) {
    ##-- get tempfile
    ($fh,$filename) = File::Temp::tempfile("ttdiff_XXXX", SUFFIX=>'.t0', UNLINK=>(!$diff->{keeptmp}) );
    confess(ref($diff)."::seqFile($which): open failed for '$filename': $!") if (!defined($fh));
  } else {
    $fh = IO::File->new(">$filename");
    confess(ref($diff)."::seqFile($which): open failed for '$filename': $!") if (!defined($fh));
  }
  binmode($fh,':utf8');
  $diff->{"tmpfile${which}"} = $filename;

  ##-- dump
  my $keysub = $diff->{"key${which}"};
  if (defined($keysub)) {
    $fh->print(map {$keysub->($diff,$_)."\n"} @{$diff->{"seq${which}"}});
  } else {
    $fh->print(@{$diff->{"seq${which}"}});
  }
  $fh->close();

  return $filename;
}

##==============================================================================
## Methods: Application / Resolution

## \@seq = $diff->apply(%opts)
##  + get "fixed" sequence from fully populated diff
##  + %opts:
##     prefer => $which,      ##-- prefer/project which sequence (1 or 2); default=1
##     fix    => $bool,       ##-- allow fixes to override preference? default=true
##     aux1   => $bool,       ##-- include aux1 items? (default: ($prefer==1))
##     aux2   => $bool,       ##-- include aux2 items? (default: ($prefer==2))
sub apply {
  my ($diff,%opts) = @_;

  ##-- defaults
  %opts = (prefer=>1,fix=>1,%opts);
  my $pref = $opts{prefer};
  my $pfix = $opts{fix};
  my $dump_aux1 = defined($opts{aux1}) ? $opts{aux1} : ($pref==1);
  my $dump_aux2 = defined($opts{aux2}) ? $opts{aux2} : ($pref==2);

  ##-- output sequence
  my $seq3 = [];

  ##-- loop: vars
  my ($seq1,$seq2,$aux1,$aux2,$hunks) = @$diff{qw(seq1 seq2 aux1 aux2 hunks)};
  my ($hunk,$hmax);
  my ($op,$min1,$max1,$min2,$max2, $fix) ;
  my ($i1,$i2) = (0,0);

  foreach $hunk (@$hunks) {
    ($op,$min1,$max1,$min2,$max2,$fix) = @$hunk;

    ##-- leading context: shared
    if (0) {
      ##-- ORIG
      push(@$seq3,
	   map {
	     (($dump_aux1 && exists($aux1->{$i1+$_}) ? @{$aux1->{$i1+$_}} : qw()),
	      ($dump_aux2 && exists($aux2->{$i2+$_}) ? @{$aux2->{$i2+$_}} : qw()),
	      ($pref==1 ? $seq1->[$i1+$_] : qw()),
	      ($pref==2 ? $seq2->[$i2+$_] : qw()))
	   } (0..($min1-$i1-1)));
    } else {
      ##-- DEBUG
      foreach (0..($min1-$i1-1)) {
	push(@$seq3,
	     (($dump_aux1 && exists($aux1->{$i1+$_}) ? @{$aux1->{$i1+$_}} : qw()),
	      ($dump_aux2 && exists($aux2->{$i2+$_}) ? @{$aux2->{$i2+$_}} : qw()),
	      ($pref==1 ? $seq1->[$i1+$_] : qw()),
	      ($pref==2 ? $seq2->[$i2+$_] : qw()))
	    );
      }
    }

    ##-- current item (hunk-internal)
    if (!$pfix || !ref($fix)) {
      $fix = [@$seq1[$min1..$max1]] if ($pfix ? (!$fix || $fix==1) : ($pref==1));
      $fix = [@$seq2[$min2..$max2]] if ($pfix ? (!$fix || $fix==2) : ($pref==2));
    }elsif (ref($fix) && $pref==1) {
      $fix = [ map {s/(?:^|\t)\>[^\t]*//g; s/(^|\t)[\~\<]/$1/g; $_} @$fix ];
    } elsif (ref($fix) && $pref==2) {
      $fix = [ map {s/(?:^|\t)\<[^\t]*//g; s/(^|\t)[\~\>]/$1/g; $_} @$fix ];
    }
    $hmax = ($max1-$min1);
    $hmax = ($max2-$min2) if ($hmax < $max2-$min2);
    $hmax = $#$fix if ($hmax < $#$fix);

    push(@$seq3,
	 map {
	   (($min1+$_<=$max1 && $dump_aux1 && exists($aux1->{$min1+$_}) ? @{$aux1->{$min1+$_}} : qw()),
	    ($min2+$_<=$max2 && $dump_aux2 && exists($aux2->{$min2+$_}) ? @{$aux2->{$min2+$_}} : qw()),
	    ($_ <= $#$fix ? $fix->[$_] : qw()))
	 } (0..$hmax));

    ##-- update current position counters (with safety checks for hacked diffs)
    #$max1 = $min1 if ($min1>$max1); ##-- BAD for 'a' ("add") ops: see notes.fix
    #$max2 = $min2 if ($min2>$max2); ##-- (?)BAD for 'd' ("del") ops: see notes.fix
    $i1 = $max1+1 if ($max1 >= $i1);
    $i2 = $max2+1 if ($max2 >= $i2);
  }

  ##-- trailing context: shared
  push(@$seq3,
       map {
	 (($dump_aux1 && exists($aux1->{$i1+$_}) ? @{$aux1->{$i1+$_}} : qw()),
	  ($dump_aux2 && exists($aux2->{$i2+$_}) ? @{$aux2->{$i2+$_}} : qw()),
	  ($pref==1 ? $seq1->[$i1+$_] : qw()),
	  ($pref==2 ? $seq2->[$i2+$_] : qw()))
       } (0..($#$seq1-$i1)));

  return wantarray ? @$seq3 : $seq3;
}

##-- DEBUG
sub _strtext {
  my $str = shift;
  $str =~ s/\t.*$//;
  return $str;
}
sub bugstr { my $s=shift; $s=~s/\t/ /g; return '"'.$s.'"'; }
sub bugline { my ($i,$i1,$i2,$seq1,$seq2) = @_; return sprintf("	  %3d  %d  %d  %-24s %s", $i, $i1+$i, $i2+$i, bugstr($seq1->[$i1+$i]), bugstr($seq2->[$i2+$i])); }


##==============================================================================
## Methods: Alignment extraction

## \@alignment = $diff->alignment()
## + returns an array-of-arrays of alignment items \@alignment = [ \@item1, \@item2, ... ]
##   where each \@item = [ $i1, $i2, $hunk ]
## + $hunk is undef for shared items
## + $i1, $i2 are indices into $diff->{seq1} and $diff->{seq2} respectively
sub alignment {
  my $diff = shift;
  my ($i1,$i2) = (0,0);
  my ($seq1,$seq2,$hunks) = @$diff{qw(seq1 seq2 hunks)};
  my @align = qw();

  my ($hunk, $op,$min1,$max1,$min2,$max2, $fix);
  foreach $hunk (@$hunks) {
    ($op,$min1,$max1,$min2,$max2,$fix) = @$hunk;

    push(@align,
	 ##-- shared preceding context
	 (map {[$i1+$_, $i2+$_]} (0..($min1-$i1-1))),
	 ##
	 ##-- hunk content
	 (map {[$_, undef, $hunk]} (($min1+0)..($max1+0))),
	 (map {[undef, $_, $hunk]} (($min2+0)..($max2+0))),
	);

    ##-- update current position
    ($i1,$i2) = ($max1+1,$max2+1);
  }

  ##-- shared trailing context
  push(@align, map {[$i1+$_, $i2+$_]} (0..($#$seq1-$i1-1)));

  return \@align;
}

##==============================================================================
## Methods: I/O

##----------------------------------------------------------------------
## Methods: I/O: Low-Level

## $sharedStr = $diff->sharedString($seq1i,$seq2i)
sub sharedString {
  my ($diff,$i1,$i2) = @_;
  my $str1 = $i1 >= 0 && $i1 <= $#{$diff->{seq1}} ? $diff->{seq1}[$i1] : undef;
  my $str2 = $i2 >= 0 && $i2 <= $#{$diff->{seq2}} ? $diff->{seq2}[$i2] : undef;
  my @w1 = defined($str1) ? split(/[\t\n\r]/,$str1) : qw();
  my @w2 = defined($str2) ? split(/[\t\n\r]/,$str2) : qw();
  my @w12 = map {
    (defined($w1[$_])
     ? (defined($w2[$_])
	? ($w1[$_] eq $w2[$_]
	   ? "~$w1[$_]"
	   : "<$w1[$_]\t>$w2[$_]")
	: "<$w1[$_]")
     : (defined($w2[$_])
	? ">$w2[$_]"
	: ''))
  } (0..($#w1 > $#w2 ? $#w1 : $#w2));
  return join("\n",
	      ($diff->{"aux1"}{$i1} ? (map {"#< $_"} @{$diff->{aux1}{$i1}}) : qw()),
	      ($diff->{"aux2"}{$i2} ? (map {"#> $_"} @{$diff->{aux2}{$i2}}) : qw()),
	      ('~ '.join("\t", @w12)),
	     )."\n";
}

## $str = $diff->singleString($which,$i)
sub singleString {
  my ($diff,$which,$i) = @_;
  my $chr = $which==1 ? '<' : '>';
  return join("\n",
	      ($diff->{"aux${which}"}{$i} ? (map {"#${chr} $_"} @{$diff->{"aux${which}"}{$i}}) : qw()),
	      ($i <= $#{$diff->{"seq${which}"}} ? ("${chr} ".$diff->{"seq${which}"}[$i]) : qw()),
	     )."\n";
}

##----------------------------------------------------------------------
## Methods: I/O: Text

## $diff = $diff->saveTextFile($filename_or_fh,%opts)
##  + stores text representation of $diff to $filename_or_fh
##  + %opts:
##     syntax => $bool, ##-- store syntax help? (default=1)
##     context => $n,   ##-- number of context lines (undef or <0 for full; default=-1)
## $diff = $diff->saveTextFile($filename_or_fh,%opts)
##  + stores text representation of $diff to $filename_or_fh
##  + %opts:
##     syntax => $bool, ##-- store syntax help? (default=1)
##     context => $n,   ##-- number of context lines (undef or <0 for full; default=-1)
sub saveTextFile {
  my ($diff,$file,%opts) = @_;
  $diff->vmsg1($vl_trace, "saveTextFile(", ($opts{filename}||$file), ")");

  my $fh = ref($file) ? $file : IO::File->new(">$file");
  confess(ref($diff)."::saveTextFile(): open failed for '$file': $!") if (!defined($fh));
  binmode($fh,':utf8');

  ##-- options
  my @optkeys = qw(header files shared context);
  %opts = ((map {($_=>$diff->{$_})} @optkeys),syntax=>1,context=>-1,%opts);
  my $k = defined($opts{context}) ? $opts{context} : -1;

  ##-- dump: header
  $fh->print("%% -*- Mode: Diff; encoding: utf-8 -*-\n",
	     (("%" x 80), "\n"),
	     "%% File auto-generated by ", ref($diff), "\n",
	     "%% File Format:\n",
	     "%%  \% COMMENT                           : comment\n",
	     "%%  \$ NAME: VALUE                       : ".ref($diff)." object data field\n",
	     "%%  \@ OP MIN1,MAX1 MIN2,MAX2 :FIX? CMT? : diff hunk address (0-based), fix = '0' (none), '\@' (user), '1' or '2' (file)\n",
	     "%%  < LINE1                             : (\"deleted\")  line in file1 only\n",
	     "%%  > LINE2                             : (\"inserted\") line in file2 only\n",
	     "%%  ~ LINE_BOTH                         : (\"matched\")  with field prefixes)\n",
	     "%%  = LINE_FIXED                        : (\"fixed\")    conflict resolution for FIX=\@\n",
	     "%%  #< AUX1                             : (\"ignored1\") diff-irrelevant line from file1\n",
	     "%%  #> AUX2                             : (\"ignored2\") diff-irrelevant line from file2\n",
	     (("%" x 80), "\n"),
	    ) if ($opts{syntax});

  $fh->print("\$ file1: $diff->{file1}\n",
	     "\$ file2: $diff->{file2}\n",
	     "\$ context: $k\n",
	     "\$ auxEOS: $diff->{auxEOS}\n",
	     "\$ auxComments: $diff->{auxComments}\n",
	    ) if (1);

  ##-- get alignment
  my $align = $diff->alignment;

  ##-- dump: sequences + hunks
  my ($i1,$i2) = (0,0);
  my ($fmin1,$fmax1,$fmin2,$fmax2); ##-- finite-context vars
  my ($seq1,$seq2,$hunks) = @$diff{qw(seq1 seq2 hunks)};
  my ($hunk, $op,$min1,$max1,$min2,$max2,$fix,$cmt, $addr);

  ##-- dump: full context
  my ($ai,$aitem);
  foreach $hunk (@{$diff->{hunks}}) {
    ($op,$min1,$max1,$min2,$max2,$fix,$cmt) = @$hunk;

    if ($k < 0) {
      ##-- full context

      ##-- full context: dump preceding context
      $fh->print(map { $diff->sharedString($i1+$_, $i2+$_) } (0..($min1-$i1-1)));

      ##-- full context: dump hunk data
      $addr  = "\@ $op $min1,$max1 $min2,$max2";
      $addr .= (defined($fix) ? (ref($fix) ? ' :@' : " :$fix") : ' :0');
      $addr .= ' '.(defined($cmt) ? $cmt : '');
      $fh->print($addr, "\n",
		 (map {$diff->singleString(1, $_)} (($min1+0)..($max1+0))),
		 (map {$diff->singleString(2, $_)} (($min2+0)..($max2+0))),
		 (ref($fix) ? (map {"= $_\n"} @$fix) : qw()),
		);

      ##-- full context: update current position counters
      ($i1,$i2) = ($max1+1,$max2+1);
    }
    else {
      ##-- finite context: positions
      $fmin1 = ($min1 >= $k ? ($min1-$k) : 0);
      $fmin2 = ($min2 >= $k ? ($min2-$k) : 0);
      $fmax1 = $max1+$k+1 <= $#$seq1 ? ($max1+$k+1) : $#$seq1;
      $fmax2 = $max2+$k+1 <= $#$seq2 ? ($max2+$k+1) : $#$seq2;

      ##-- finite context: hunk address
      $addr  = "\@ $op ($fmin1 $fmin2) $min1,$max1 $min2,$max2";
      $addr .= (defined($fix) ? (ref($fix) ? ' :@' : " :$fix") : ' :0');
      $addr .= ' '.(defined($cmt) ? $cmt : '');

      ##-- finite context: dump
      $fh->print(
		 ##-- leading separator
		 "********\n",
		 ##
		 ##-- address
		 $addr, "\n",
		 ##
		 ##-- leading context
		 (map { $diff->sharedString($min1+$_, $min2+$_) } (-$k..-1)),
		 ##
		 ##-- hunk data
		 (map {$diff->singleString(1, $_)} (($min1+0)..($max1+0))),
		 (map {$diff->singleString(2, $_)} (($min2+0)..($max2+0))),
		 (ref($fix) ? (map {"= $_\n"} @$fix) : qw()),
		 ##
		 ##-- trailing context
		 (map { $diff->sharedString($max1+$_, $max2+$_) } (1..$k)),
		);
    }
  }

  ##-- dump trailing context (full dump only)
  if ($k<0) {
    $fh->print(map { $diff->sharedString($i1+$_, $i2+$_) } (0..($#$seq1-$i1)));
  } else {
    ##-- final trailing separator
    $fh->print("********\n");
  }

  $fh->close() if (!ref($file));
  return $diff;
}

## $diff = $CLASS_OR_OBJ->loadTextFile($filename_or_fh,%opts)
##  + %opts: (none)
sub loadTextFile {
  my ($diff,$file,%opts) = @_;
  $diff = $diff->new if (!ref($diff));
  $diff->vmsg1($vl_trace, "loadTextFile($file)");

  my $fh = ref($file) ? $file : IO::File->new("<$file");
  confess(ref($diff)."::loadTextFile(): open failed for '$file': $!") if (!defined($fh));
  binmode($fh,':utf8');

  ##-- load
  @{$diff->{hunks}} = qw();
  @{$diff->{seq1}}  = qw();
  @{$diff->{seq2}}  = qw();
  %{$diff->{aux1}}  = qw();
  %{$diff->{aux2}}  = qw();
  my ($hunks,$seq1,$seq2,$aux1,$aux2) = @$diff{qw(hunks seq1 seq2 aux1 aux2)};
  my ($i1,$i2) = (0,0);
  my ($line, $hunk);
  my (@w1,@w2);
  while (defined($line=<$fh>)) {
    chomp($line);
    if    ($line =~ /^\%/) { ; }    ##-- comment
    elsif ($line =~ /^\$\s+(\w+):\s+(.*)$/) {
      ##-- object data field
      $diff->{$1} = $2;
    }
    elsif ($line =~ /^\@ ([acd]) (?:\((\-?\d+) (\-?\d+)\) )?(\-?\d+),(\-?\d+) (\-?\d+),(\-?\d+)(?: \: ?([\d\@\?]+)\s{0,1}(.*))?$/)
      {
	##-- hunk address
	($i1,$i2) = ($2+0,$3+0) if (defined($2) && defined($3));
	push(@$hunks, $hunk=[$1,
			     (map {$_+0} ($4,$5,$6,$7)),
			     (defined($8) && $8 ne '?' ? $8 : '0'),
			     (defined($9) ? $9 : qw())]);
	$hunk->[5] = [] if ($hunk->[5] && $hunk->[5] eq '@');
      }
    elsif ($line =~ /^~ /)
      {
	##-- shared sequence item
	@w1 = @w2 = qw();
	substr($line,0,2,'');
	while ($line =~ /([\=\~\<\>])([^\t\n\r]*)/g) {
	  push(@w1, $2) if ($1 ne '>');
	  push(@w2, $2) if ($1 ne '<');
	}
	$seq1->[$i1++] = join("\t",@w1);
	$seq2->[$i2++] = join("\t",@w2);
      }
    elsif ($line =~ /^\< (.*)$/) { ##-- seq1-only item
      $seq1->[$i1++] = $1;
    }
    elsif ($line =~ /^\> (.*)$/) { ##-- seq2-only item
      $seq2->[$i2++] = $1;
    }
    elsif ($line =~ /^\#\< (.*)$/) { ##-- seq1-aux item
      push(@{$diff->{aux1}{$i1}}, $1);
    }
    elsif ($line =~ /^\#\> (.*)$/) { ##-- seq2-aux item
      push(@{$diff->{aux2}{$i2}}, $1);
    }
    elsif ($line =~ /^\= (.*)$/) { ##-- fix item
      warn(ref($diff)."::loadTextFile($file): ignoring fix without current hunk: '$line'") if (!$hunk);
      $hunk->[5] = [] if (!ref($hunk->[5]));
      push(@{$hunk->[5]}, $1);
    }
    elsif ($line =~ /^[\-\*]+$/) { ##-- separator: ignore
      next;
    }
    else {
      warn(ref($diff)."::loadTextFile($file): parse error at line ", $fh->input_line_number, ", ignoring: '$line'");
    }
  }
  $fh->close() if (!ref($file));

  return $diff;
}


##==============================================================================
## Footer
1;

__END__
