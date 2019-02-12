## -*- Mode: CPerl -*-
## File: Lingua::TT::Document.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT I/O: Documents


package Lingua::TT::Document;
use Lingua::TT::Token;
use Lingua::TT::Sentence;
use Lingua::TT::Persistent;
use Encode qw(encode decode);
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(Lingua::TT::Persistent);

##==============================================================================
## Constructors etc.

## $doc = CLASS_OR_OBJECT->new(@sents)
## + $doc: ARRAY-ref
##     [$sent1, $sent2, ..., $sentN]
sub new {
  my $that = shift;
  return bless([@_], ref($that)||$that);
}

## $doc = CLASS_OR_OBJECT->newFromString($str)
##  + should be equivalent to CLASS_OR_OBJECT->new()->fromString($str)
sub newFromString {
  return $_[0]->new()->fromString($_[1]);
}

## $doc2 = $doc->copy($depth)
##  + creates a copy of $doc
##  + if $deep is 0, only a shallow copy is created (sentences & tokens are shared)
##  + if $deep is >=1 (or <0), sentences are copied as well (tokens are still shared)
##  + if $deep is >=2 (or <0), tokens are copied as well
sub copy {
  my ($doc,$deep) = @_;
  my $doc2 = bless([],ref($doc));
  @$doc2 = $deep ? (map {$_->copy($deep-1)} @$doc) : @$doc;
  return $doc2;
}

##==============================================================================
## Methods: Access & Manipulation

## $nSents = $doc->nSentences()
sub nSentences {
  return scalar(@{$_[0]});
}

## $nToks = $doc->nTokens()
sub nTokens {
  my $n = 0;
  $n += scalar(@$_) foreach (@{$_[0]});
  return $n;
}

## $bool = $doc->isEmpty()
##  + true iff $sent has no non-empty sentences
sub isEmpty {
  return !grep {!$_->isEmpty} @{$_[0]};
}

## $doc = $doc->rmEmptySentences()
##  + removes empty & undefined sentences from @$doc
sub rmEmptySentences {
  @{$_[0]} = grep {defined($_) && !$_->isEmpty} @{$_[0]};
  return $_[0];
}

## $doc = $doc->rmEmptyTokens()
##  + removes all empty tokens from all sentences in @$doc
sub rmEmptyTokens {
  $_->rmEmptyTokens foreach (@{$_[0]});
  return $_[0];
}

## $doc = $doc->rmComments()
##  + removes all comment pseudo-tokens from all sentences in @$doc
sub rmComments {
  $_->rmComments foreach (@{$_[0]});
  return $_[0];
}

## $doc = $doc->rmNonVanilla()
##  + removes non-vanilla tokens from all sentences in @$doc
sub rmNonVanilla {
  $_->rmNonVanilla foreach (@{$_[0]});
  return $_[0];
}

## $doc = $doc->canonicalize()
##  + removes all non-vanilla tokens and empty setences from @$doc
sub canonicalize {
  $_[0]->rmNonVanilla;
  $_[0]->rmEmptySentences;
  return $_[0];
}

## $tokens = $doc->flat()
##  + returns flat list of pseudo-tokens (sentence boundaries replaced with "empty" tokens)
sub flat {
  my $doc   = shift;
  my $sflat = Lingua::TT::Sentence->new;
  my $eos   = Lingua::TT::Token->new('');
  @$sflat   = map {(@$_,$eos)} @$doc;
  pop(@$sflat); ##-- remove final $eos
  #@$doc     = ($sflat);
  #return $doc;
  ##--
  return $sflat;
}

##==============================================================================
## Methods: I/O

##--------------------------------------------------------------
## Methods: I/O: TT

## $str = $doc->toString()
##  + returns string representing $doc
BEGIN { *saveNativeString = \&toString; }
sub toString {
  return join("\n", map {$_->toString} @{$_[0]})."\n";
}

## $doc = $doc->fromString($str)
##  + parses $doc from string $str
BEGIN { *loadNativeString = \&fromString; }
sub fromString {
  #my ($sent,$str) = @_;
  @{$_[0]} = map {Lingua::TT::Sentence->newFromString($_)} split(/(?:\r?\n){2}/,$_[1]);
  return $_[0];
}

## $doc = $CLASS_OR_OBJECT->fromFile($filename_or_fh,%opts)
##  + parses $doc from file
BEGIN { *load = *loadNativeFile = \&fromFile; }
sub fromFile {
  my ($doc,$file,%opts) = @_;
  my $ttio = Lingua::TT::IO->fromFile($file,%opts)
    or die((ref($doc)||$doc)."::fromFile(): open failed for '$file': $!");
  my $got = $ttio->getDocument;
  $ttio->close();
  return $got if (!ref($doc));
  @$doc = @$got;
  return $doc;
}

## $doc = $CLASS_OR_OBJECT->toFile($filename_or_fh,%opts)
##  + saves $doc to file
BEGIN { *save = *saveNativeFile = \&toFile; }
sub toFile {
  my ($doc,$file,%opts) = @_;
  my $ttio = Lingua::TT::IO->toFile($file,%opts)
    or die((ref($doc)||$doc)."::toFile(): open failed for '$file': $!");
  my $rc = $ttio->putDocument($doc);
  $ttio->close();
  return $rc ? $doc : undef;
}


##==============================================================================
## Methods: Shuffle & Split

## $doc = $doc->shuffle(%opts)
##  + randomly re-orders sentences in @$doc to @$doc2
##  + %opts:
##    seed => $seed, ##-- calls srand($seed) if defined
sub shuffle {
  my ($doc,%opts) = @_;
  srand($opts{seed}) if (defined($opts{seed}));
  my @keys = map {rand} @$doc;
  @$doc = @$doc[sort {$keys[$a]<=>$keys[$b]} (0..$#$doc)];
  return $doc;
}

##  @docs = $doc->splitN($n,%opts)  ##-- array context
## \@docs = $doc->splitN($n,%opts)  ##-- scalar context
##  + splits $doc deterministically into $n roughly equally-sized @docs
##  + sentence data is shared (refs) between $doc and @docs
##  + for a random split, call $doc->shuffle(seed=>$seed)->splitN($n)
##  + %opts:
##     contiguous => $bool,	##-- if true, output @docs will represent contiguous sections of input (alias: 'contig')
sub splitN {
  my ($doc,$n,%opts) = @_;
  my @odocs  = map {$doc->new} (1..$n);
  my @osizes = map {0} @odocs;
  if ($opts{contiguous} || $opts{contig}) {
    ##-- contiguous mode
    my $oi = 0;
    my $osize = $doc->nTokens / ($n || 1);
    my ($sent);
    foreach $sent (@$doc) {
      push(@{$odocs[$oi]}, $sent);
      $osizes[$oi] += scalar(@$sent);
      ++$oi if ($osizes[$oi] >= $osize);
    }
  } else {
    ##-- best-split mode
    my ($sent,$oi,$oi_min);
    foreach $sent (@$doc) {
      ##-- find smallest @odoc
      $oi_min = 0;
      foreach $oi (1..$#odocs) {
	$oi_min = $oi if ($osizes[$oi] < $osizes[$oi_min]);
      }
      push(@{$odocs[$oi_min]}, $sent);
      $osizes[$oi_min] += scalar(@$sent);
    }
  }
  return wantarray ? @odocs : \@odocs;
}


##==============================================================================
## Footer
1;

__END__
