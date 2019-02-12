## -*- Mode: CPerl -*-
## File: Lingua::TT::Enum.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT Utils: in-memory Enum


package Lingua::TT::Enum;
use Lingua::TT::Persistent;
use Carp;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(Lingua::TT::Persistent);

##==============================================================================
## Constructors etc.

## $enum = CLASS_OR_OBJECT->new(%opts)
## + %opts, %$enum:
##    sym2id => \%sym2id, ##-- $sym=>$id, ...
##    id2sym => \@id2sym, ##-- $id=>$sym, ...
##    size   => $n_ids,   ##-- index of first free id
##    maxid  => $max,     ##-- maximum allowable id, e.g. 2**16-1, 2**32-1, (default=undef: no max)
sub new {
  my $that = shift;
  my $enum = bless({
		    sym2id => {},
		    id2sym => [],
		    size => 0,
		    maxid => undef,
		    @_
		   }, ref($that)||$that);
  return $enum;
}

## undef = $enum->clear()
sub clear {
  my $enum = shift;
  %{$enum->{sym2id}} = qw();
  @{$enum->{id2sym}} = qw();
  $enum->{size} = 0;
  return $enum;
}

##==============================================================================
## Methods: Access and Manipulation

## $id = $enum->getId($sym)
##  + gets (possibly new) id for $sym
sub getId {
  return $_[0]{sym2id}{$_[1]} if (exists($_[0]{sym2id}{$_[1]}));
  confess(ref($_[0])."::getId(): maxid=$_[0]{maxid} exceeded!") ##-- check for overflow
    if (defined($_[0]{maxid}) && $_[0]{size}==$_[0]{maxid});
  $_[0]{id2sym}[$_[0]{size}] = $_[1];
  return $_[0]{sym2id}{$_[1]} = $_[0]{size}++;
}

## $id = $enum->getSym($id)
##  + gets (possibly new (and if so, "SYM${i}")) symbol for $id
BEGIN { *getSym = \&getSymbol; };
sub getSymbol {
  return $_[0]{id2sym}[$_[1]] if ($_[1] < $_[0]{size});
  $_[0]{sym2id}{"SYM$_[1]"} = $_[1];
  return $_[0]{id2sym}[$_[1]] = "SYM$_[1]";
}

## $id = $enum->setId($sym=>$id)
sub setId {
  $_[0]{id2sym}{$_[1]}=$_[2];
  $_[0]{sym2id}[$_[2]]=$_[1];
  return $_[2];
}

##==============================================================================
## Methods: I/O

##--------------------------------------------------------------
## Methods: I/O: Native

## $bool = $enum->saveNativeFh($fh,%opts)
## + saves to filehandle
## + implicitly sets $fh ':utf8' flag unless $opts{raw} is set
## + %opts
##    noids => $bool,    ##-- suppress printing of ids?
sub saveNativeFh {
  my ($enum,$fh,%opts) = @_;
  my ($sym,$id);
  if ($opts{noids}) {
    my $id2sym = $enum->{id2sym};
    $fh->print(map {(defined($_) ? $_ : '')."\n"} @$id2sym);
  } else {
    my $sym2id = $enum->{sym2id};
    foreach $sym (sort {$sym2id->{$a} <=> $sym2id->{$b}} keys (%$sym2id)) {
      $fh->print($sym2id->{$sym}, "\t", $sym, "\n");
    }
  }
  return $enum;
}

## $bool = $enum->loadNativeFh($fh)
## + loads from handle
## + %opts
##    encoding => $enc,  ##-- use encoding (default='utf8', unless 'raw' is true)
##    noids => $bool,    ##-- don't expect to load ids?
sub loadNativeFh {
  my ($enum,$fh,%opts) = @_;
  $enum = $enum->new() if (!ref($enum));
  my $id2sym = $enum->{id2sym};
  my $sym2id = $enum->{sym2id};
  my ($line,$sym);
  my $id=0;
  if ($opts{noids}) {
    while (defined($sym=<$fh>)) {
      chomp($sym);
      $id2sym->[$id]  = $sym;
      $sym2id->{$sym} = $id;
      ++$id;
    }
  } else {
    while (defined($line=<$fh>)) {
      chomp($line);
      next if ($line =~ /^\s*$/ || $line =~ /^%%/);
      ($id,$sym) = split(/\t/,$line,2);
      $id2sym->[$id]  = $sym;
      $sym2id->{$sym} = $id;
    }
  }
  $enum->{size} = scalar(@$id2sym);
  return $enum;
}

##--------------------------------------------------------------
## Methods: I/O: Bin


## ($serialized_string,\@other_refs) = STORABLE_freeze($obj, $cloning_flag)
sub STORABLE_freeze {
  my ($obj,$cloning) = @_;
  return ('',[map { $_ eq 'sym2id' ? qw() : ($_=>$obj->{$_}) } keys(%$obj)]);
}

## $obj = STORABLE_thaw($obj, $cloning_flag, $serialized_string, @other_refs)
sub STORABLE_thaw {
  my ($obj,$cloning,$str,$ar) = @_;
  if (!defined($str) || $str eq '') {
    ##-- backwards-compatibility
    %$obj = @$ar;
    #return $obj if (ref($obj) ne __PACKAGE__); ##-- hack
    $obj->{sym2id} = {} if (!defined($obj->{sym2id}));
    @{$obj->{sym2id}}{grep {defined($_)} @{$obj->{id2sym}}}
      = grep {defined($obj->{id2sym}[$_])} (0..$#{$obj->{id2sym}});
  }
  return $obj;
}



##==============================================================================
## Footer
1;

__END__
