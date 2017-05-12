## -*- Mode: CPerl -*-
## File: DiaColloDB::EnumFile::Tied.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db: file-based enums: tied interface

package DiaColloDB::EnumFile::Tied;
1;

package DiaColloDB::EnumFile;
use Carp;
use strict;

##==============================================================================
## Global Wrappers

## $enum = $CLASS->tienew(%opts,class=>$enumFileClass)
## $enum = $CLASS->tienew($enum)
##  + returns $enum if specified, otherwise a new EnumFile object for %opts
sub tienew {
  my $that = shift;
  my $enum;
  if (@_==1) {
    $enum = shift;
  } else {
    my %opts  = @_;
    my $class = $opts{class} || ref($that) || $that || __PACKAGE__;
    $class    = "DiaColloDB::$class" if (!UNIVERSAL::isa($class,'DiaColloDB::EnumFile'));
    delete $opts{class};
    $enum     = $class->new(%opts)
      or $that->logconfess("tienew(): could not create enum object of class '$class'");
  }
  #$enum->{shared} = 1;  ##-- refs are shared, so we should be o.k. with auto-close
  return $enum;
}

## (\@id2sym,\%sym2id) = $CLASS->tiepair(%opts)
## (\@id2sym,\%sym2id) = $CLASS->tiepair($enum)
## (\@id2sym,\%sym2id) = $OBJECT->tiepair()
##  + returns pair of tied objects suitable for simulating e.g. MUDL::Enum
##  + %opts: passed to $CLASS->tienew()
sub tiepair {
  my $that = shift;
  my $enum = ref($that) ? $that : $that->tienew(@_)
    or $that->logconfess("tiepair(): could not create EnumFile object");

  my (@id2sym,%sym2id);
  tie(@id2sym, $enum->tieArrayClass, $enum);
  tie(%sym2id, $enum->tieHashClass,  $enum);
  return (\@id2sym,\%sym2id);
}

## $class = $CLASS_OR_OBJECT->tieArrayClass()
##  + returns class for tied arrays to be returned by tiepair() method
##  + default just returns "DiaColloDB::EnumFile::TiedArray"
sub tieArrayClass {
  return "DiaColloDB::EnumFile::TiedArray";
}

## $class = $CLASS_OR_OBJECT->tieHashClass()
##  + returns class for tied arrays to be returned by tiepair() method
##  + default just returns "DiaColloDB::EnumFile::TiedHash"
sub tieHashClass {
  return "DiaColloDB::EnumFile::TiedHash";
}

##==============================================================================
## API: TiedArray

package DiaColloDB::EnumFile::TiedArray;
use Tie::Array;
use Carp;
use strict;
our @ISA = qw(Tie::Array);

##--------------------------------------------------------------
## API: TiedArray: mandatory methods

## $tied = tie(@array, $tieClass, $enum)
## $tied = tie(@array, $tieClass, %opts)
## $tied = TIEARRAY($class, $tieClass, %opts, class=>$enumFileClass)
## $tied = TIEARRAY($class, $tieClass, $enum)
##  + %opts as for DiaColloDB::EnumFile::tienew()
##  + returns $tied = \$enum
sub TIEARRAY {
  my $that = shift;
  my $enum = DiaColloDB::EnumFile->tienew(@_);
  return bless \$enum, ref($that)||$that;
}


## $val = $tied->FETCH($index)
sub FETCH {
  return ${$_[0]}->i2s($_[1]);
}

## $count = $tied->FETCHSIZE()
##  + like scalar(@array)
sub FETCHSIZE {
  return ${$_[0]}->size();
}

## $val = $tied->STORE($index,$val)
sub STORE {
  ${$_[0]}->{dirty} = 1;
  ${$_[0]}->setsize($_[1]+1) if ($_[1] >= ${$_[0]}->size);
  return ${$_[0]}->{i2s}[$_[1]] = $_[2];
}

## $count = $tied->STORESIZE($count)
##  + not quite safe
sub STORESIZE {
  ${$_[0]}->{dirty} = 1;
  return ${$_[0]}->setsize($_[1]);
}

## $bool = $tied->EXISTS($index)
sub EXISTS {
  return $_[1] < ${$_[0]}->size();
}

## undef = $tied->DELETE($index)
##  + not properly supported; just deletes from in-memory cache
sub DELETE {
  return delete ${$_[0]}->{i2s}[$_[1]];
}

##--------------------------------------------------------------
## API: TiedArray: optional methods

## undef = $tied->CLEAR()
sub CLEAR {
  ${$_[0]}->fromArray([]);
}

#sub PUSH { ... }
#sub POP { ... }
#sub SHIFT { ... }
#sub UNSHIFT { ... }
#sub SPLICE { ... }
#sub EXTEND { ... }
#sub DESTROY { ... }


##==============================================================================
## API: TiedHash

package DiaColloDB::EnumFile::TiedHash;
use Tie::Hash;
use Carp;
use strict;
our @ISA = qw(Tie::Hash);

##--------------------------------------------------------------
## API: TiedHash: mandatory methods

## $tied = tie(%hash, $tieClass, $enum)
## $tied = tie(%hash, $tieClass, %opts)
## $tied = TIEHASH($class, $tieClass, %opts, class=>$enumFileClass)
## $tied = TIEHASH($class, $tieClass, $enum)
##  + %opts as for DiaColloDB::EnumFile::tienew()
##  + returned $tied = \$enum
sub TIEHASH {
  my $that = shift;
  my $enum = DiaColloDB::EnumFile->tienew(@_);
  return bless \$enum, ref($that)||$that;
}

##--------------------------------------------------------------
## API: TiedArray: optional methods

## $val = $tied->STORE($key, $value)
sub STORE {
  ${$_[0]}->{dirty} = 1;
  ${$_[0]}->setsize($_[2]+1) if ($_[2] >= ${$_[0]}->size);
  return ${$_[0]}->{s2i}{$_[1]} = $_[2];
}

## $val = $tied->FETCH($key)
sub FETCH {
  return ${$_[0]}->s2i($_[1]);
}

## $key = $tied->FIRSTKEY()
sub FIRSTKEY {
  return ${$_[0]}->i2s(0) // '';
}

## $key = $tied->NEXTKEY($lastkey)
##  + only works for enums without index-gaps
sub NEXTKEY {
  my $i = ${$_[0]}->s2i($_[1]);
  return undef if (!defined($i) || ++$i >= ${$_[0]}->size);
  return ${$_[0]}->i2s($i);
}

## $bool = $tied->EXISTS($key)
sub EXISTS {
  return ${$_[0]}->s2i($_[1]);
}

## undef = $tied->DELETE($key)
##  + not properly supported; just deletes from in-memory cache
sub DELETE {
  ${$_[0]}->{dirty} = 1;
  delete ${$_[0]}->{s2i}{$_[1]};
}

## undef = $tied->CLEAR()
sub CLEAR {
  ${$_[0]}->fromArray([]);
}

## $scalar = $tied->SCALAR()
##  + returns key count
sub SCALAR {
  return ${$_[0]}->size();
}


##==============================================================================
## Footer
1;

__END__
