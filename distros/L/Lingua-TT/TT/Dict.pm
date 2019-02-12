## -*- Mode: CPerl -*-
## File: Lingua::TT::Enum.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT Utils: in-memory Enum

package Lingua::TT::Dict;
use Lingua::TT::Persistent;
use Lingua::TT::IO;
use Carp;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(Lingua::TT::Persistent);

##==============================================================================
## Constructors etc.

## $dict = CLASS_OR_OBJECT->new(%opts)
## + %opts, %$dict:
##    dict => \%key2val,  ##-- dict data
sub new {
  my $that = shift;
  my $dict = bless({
		    dict=>{},
		    @_
		   }, ref($that)||$that);
  return $dict;
}

## undef = $dict->clear()
sub clear {
  my $dict = shift;
  %{$dict->{dict}} = qw();
  return $dict;
}

##==============================================================================
## Methods: Access and Manipulation

## $n_keys = $dict->size()
sub size {
  return scalar CORE::keys %{$_[0]{dict}};
}

## @keys = $dict->keys()
sub keys {
  return CORE::keys %{$_[0]{dict}};
}

## $val = $dict->get($key)
sub get {
  return $_[0]{dict}{$_[1]};
}

##==============================================================================
## Methods: merge

## $dict = $dict->merge($dict2, %opts)
##  + include $dict2 entries in $dict, destructively alters $dict
##  + %opts:
##     append => $bool,  ##-- if true, $dict2 values are appended to $dict1 values
sub merge {
  my ($d1,$d2,%opts) = @_;
  if (!$opts{append}) {
    @{$d1->{dict}}{CORE::keys %{$d2->{dict}}} = CORE::values %{$d2->{dict}}; ##-- clobber
  } else {
    my $h1 = $d1->{dict};
    my $h2 = $d2->{dict};
    my ($key,$val);
    while (($key,$val)=each %$h2) {
      $h1->{$key} = exists($h1->{$key}) ? "$h1->{$key}\t$val" : $val;
    }
  }
  return $d1;
}


##==============================================================================
## Methods: Apply

## \&apply = $dict->applySub(%opts)
##   + returns a CODE-ref for applying dictionary analysis to a single item
##   + returned sub is called without arguments
##     - data line to be analyzed (chomped) is in $_
##     - output for current data line should be stored in $_
sub applySub {
  my ($dict,%opts) = @_;
  my $dh            = $dict->{dict};
  my $include_empty = $opts{allow_empty};
  my ($text,$a_in,$a_dict);
  return sub {
    ($text,$a_in) = split(/\t/,$_,2);
    $a_dict       = $dh->{$text};
    $_            = join("\t", $text, (defined($a_in) ? $a_in : qw()), (defined($a_dict) && ($include_empty || $a_dict ne '') ? $a_dict : qw()))."\n";
  };
}

## $bool = $dict->apply($infh,$outfh,%opts)
##  + apply dict to TT data from $infh, writing output to $outfh
##  + uses $dict->applySub() for actual analysis
##  + %opts:
##     allow_empty => $bool,  ##-- include empty analyses? (default=0)
sub apply {
  my ($dict,$infh,$outfh,%opts) = @_;
  $infh     = $infh->{fh}  if (UNIVERSAL::isa($infh,'HASH') && defined($infh->{fh}));
  $outfh    = $outfh->{fh} if (UNIVERSAL::isa($outfh,'HASH') && defined($outfh->{fh}));
  my $apply = $dict->applySub(%opts);
  while (defined($_=<$infh>)) {
    next if (/^%%/ || /^$/);  ##-- ignore comments and blank lines (pass-through)
    chomp;
    $apply->();
  }
  continue {
    $outfh->print($_) or return undef;
  }
  return 1;
}

##==============================================================================
## Methods: I/O

##--------------------------------------------------------------
## Methods: I/O: generic

## $bool = $dict->setFhLayers($fh,%opts)
sub setFhLayers {
  my ($obj,$fh,%opts) = @_;
  binmode($fh,":encoding($opts{encoding})") if (defined($opts{encoding}));
}

##--------------------------------------------------------------
## Methods: I/O: Native

## $bool = $dict->saveNativeFh($fh,%opts)
## + saves to filehandle
## + %opts
##    encoding => $enc,  ##-- sets $fh :encoding flag if defined; default: none
sub saveNativeFh {
  my ($dict,$fh,%opts) = @_;
  $dict->setFhLayers($fh,%opts);
  my ($key,$val);
  while (($key,$val)=each(%{$dict->{dict}})) {
    $fh->print($key, "\t", $val, "\n");
  }
  return $dict;
}

## $bool = $dict->loadNativeFh($fh)
## + loads from handle
## + %opts
##    encoding => $enc,  ##-- sets $fh :encoding flag if defined; default: none
##    append   => $bool, ##-- if true, multiple entries for a single key will be appended (TAB-separated)
sub loadNativeFh {
  my ($dict,$fh,%opts) = @_;
  $dict->setFhLayers($fh,%opts);
  $dict = $dict->new() if (!ref($dict));
  my $dh = $dict->{dict};
  my ($line,$key,$val);
  if ($opts{append}) {
    ##-- append mode
    while (defined($line=<$fh>)) {
      chomp($line);
      next if ($line =~ /^\s*$/ || $line =~ /^%%/);
      ($key,$val) = split(/\t/,$line,2);
      next if (!defined($val)); ##-- don't store keys for undef values (but do for empty string)
      if (exists($dh->{$key})) {
	$dh->{$key} .= "\t$val";
      } else {
	$dh->{$key}  = $val;
      }
    }
  } else {
    ##-- clobber mode (default)
    while (defined($line=<$fh>)) {
      chomp($line);
      next if ($line =~ /^\s*$/ || $line =~ /^%%/);
      ($key,$val) = split(/\t/,$line,2);
      next if (!defined($val)); ##-- don't store keys for undef values (but do for empty string)
      $dh->{$key} = $val;
    }
  }
  return $dict;
}

##--------------------------------------------------------------
## Methods: I/O: Bin

## ($serialized_string,\@other_refs) = STORABLE_freeze($obj, $cloning_flag)

## $obj = STORABLE_thaw($obj, $cloning_flag, $serialized_string, @other_refs)

##==============================================================================
## Footer
1;

__END__
