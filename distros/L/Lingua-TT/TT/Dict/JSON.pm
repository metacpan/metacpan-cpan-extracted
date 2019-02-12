## -*- Mode: CPerl -*-
## File: Lingua::TT::Dict::JSON.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT Utils: dictionary: JSON

package Lingua::TT::Dict::JSON;
use Lingua::TT::Dict;
use Lingua::TT::IO;
use JSON::XS;
use Carp;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(Lingua::TT::Dict);

##==============================================================================
## Constructors etc.

## $dict = CLASS_OR_OBJECT->new(%opts)
## + %opts, %$dict:
##    dict => \%key2val,  ##-- dict data; values are refs (encoded/decoded via JSON)
sub new {
  my $that = shift;
  return $that->SUPER::new(@_);
}

##==============================================================================
## Methods: Access and Manipulation

## $jxs = $obj->jsonxs()
sub jsonxs {
  return $_[0]{jxs} if (ref($_[0]) && defined($_[0]{jxs}));
  return $_[0]{jxs} = JSON::XS->new->utf8(0)->allow_nonref;
}

##==============================================================================
## Methods: merge

## $dict = $dict->merge($dict2, %opts)
##  + include $dict2 entries in $dict, destructively alters $dict
##  + %opts:
##     append => $bool,  ##-- if true, $dict2 values are appended (dict clobber) to $dict1 values
sub merge {
  my ($d1,$d2,%opts) = @_;
  if (!$opts{append}) {
    @{$d1->{dict}}{CORE::keys %{$d2->{dict}}} = CORE::values %{$d2->{dict}}; ##-- clobber
  } else {
    my $h1 = $d1->{dict};
    my $h2 = $d2->{dict};
    my $jxs = $d1->jsonxs;
    my ($key,$val1,$val2);
    while (($key,$val2)=each %$h2) {
      if (!defined($val1=$h1->{$key})) {
	$h1->{$key} = $val2;
      }
      elsif (ref($val1) eq 'HASH' && ref($val2) eq 'HASH') {
	@$val1{keys %$val2} = values %$val2;
      }
      elsif (ref($val1) eq 'ARRAY' && ref($val2) eq 'ARRAY') {
	  push(@$val1, @$val2);
      }
      else {
	warn(ref($d1)."::merge(): cannot merge values $val1, $val2 for key '$key'");
	$h1->{$key} = $val2;
	next;
      }
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
  my $jxs           = $dict->jsonxs;
  my $dh            = $dict->{dict};
  #my $include_empty = $opts{allow_empty};
  my ($text,$a_in,$a_dict);
  return sub {
    ($text,$a_in) = split(/\t/,$_,2);
    $a_in   = $jxs->decode($a_in) if (defined($a_in));
    $a_dict = $dh->{$text};
    if (!defined($a_dict)) {
      ##-- +in, -dict
      ;
    }
    elsif (!defined($a_in)) {
      ##-- -in, +dict
      $a_in = $a_dict;
    }
    elsif (ref($a_in) eq 'HASH' && ref($a_dict) eq 'HASH') {
      ##-- +in, +dict: HASH
      @$a_in{keys %$a_dict} = values %$a_dict;
    }
    elsif (ref($a_in) eq 'ARRAY' && ref($a_dict) eq 'ARRAY') {
      ##-- +in, +dict: ARRAY
      push(@$a_in, @$a_dict);
    }
    else {
      ##-- +in, +dict: OTHER
      warn(ref($dict)."::applySub(): cannot merge values $a_in, $a_dict for key '$text'");
      $a_in = $a_dict;
    }
    $_ = join("\t", $text, (defined($a_in) ? $jxs->encode($a_in) : qw()))."\n";
  };
}

## $bool = $dict->apply($infh,$outfh,%opts)
##  + apply dict to filehandle $fh
##  + %opts:
##     allow_empty => $bool,  ##-- include empty analyses? (default=0)

##==============================================================================
## Methods: I/O

##--------------------------------------------------------------
## Methods: I/O: generic

## $bool = $dict->setFhLayers($fh,%opts)
sub setFhLayers {
  binmode($_[1],':utf8');
}

##--------------------------------------------------------------
## Methods: I/O: Native

## $bool = $dict->saveNativeFh($fh,%opts)
## + saves to filehandle
## + %opts: (none)
sub saveNativeFh {
  my ($dict,$fh,%opts) = @_;
  binmode($fh,":utf8");
  my $jxs = $dict->jsonxs();
  my ($key,$val);
  while (($key,$val)=each(%{$dict->{dict}})) {
    $fh->print($key, "\t", $jxs->encode($val), "\n");
  }
  return $dict;
}

## $bool = $dict->loadNativeFh($fh)
## + loads from handle
## + %opts
##    encoding => $enc,  ##-- sets $fh :encoding flag if defined; default: none
##    append   => $bool, ##-- if true, multiple entries for a single key will be appended (and maybe promoted to ARRAY)
##    merge    => $bool, ##-- if true, multiple HASH-entries for a single key will be merged
sub loadNativeFh {
  my ($dict,$fh,%opts) = @_;
  binmode($fh,":utf8");
  $dict   = $dict->new() if (!ref($dict));
  my $dh  = $dict->{dict};
  my $jxs = $dict->jsonxs;
  my $merge = $opts{merge};
  my ($line,$key,$val);
  if ($opts{append} || $opts{merge}) {
    ##-- append mode
    my ($oldval);
    while (defined($line=<$fh>)) {
      chomp($line);
      next if ($line =~ /^\s*$/ || $line =~ /^%%/);
      ($key,$val) = split(/\t/,$line,2);
      next if (!defined($val)); ##-- don't store keys for undef values (but do for empty string)
      $val = $jxs->decode($val);
      if (!defined($oldval=$dh->{$key})) {
	##-- new key
	$dh->{$key} = $val;
      }
      elsif ($merge && (ref($oldval)//'') eq 'HASH' && (ref($val)//'') eq 'HASH') {
	##-- merge multiple HASH values
	@$oldval{keys %$val} = values %$val;
      }
      else {
	##-- append / promote to ARRAY values
	$oldval = $dh->{$key} = [$oldval] if (!UNIVERSAL::isa($oldval,'ARRAY'));
	push(@$oldval, UNIVERSAL::isa($val,'ARRAY') ? @$val : $val);
      }
    }
  } else {
    ##-- clobber mode (default)
    while (defined($line=<$fh>)) {
      chomp($line);
      next if ($line =~ /^\s*$/ || $line =~ /^%%/);
      ($key,$val) = split(/\t/,$line,2);
      next if (!defined($val)); ##-- don't store keys for undef values (but do for empty string)
      $dh->{$key} = $jxs->decode($val);
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
