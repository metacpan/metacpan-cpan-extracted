## -*- Mode: CPerl -*-
## File: Lingua::TT::DBx::Enum.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT I/O: Berkely DB: enums


package Lingua::TT::DBx::Enum_HH;
use Lingua::TT::DBFile;
#use Lingua::TT::DBFile::Array;
use DB_File;
use Fcntl;
use Carp;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw();

##==============================================================================
## Constructors etc.

## $dbe = CLASS_OR_OBJECT->new(%opts)
## + %opts, %$doc:
##   ##-- user options
##   file     => $basename,    ##-- file basename; default=undef (none)
##   opts_s2i => \%opts,       ##-- Lingua::TT::DBFile options for 's2i' file
##   opts_i2s => \%opts,       ##-- Lingua::TT::DBFile options for 'i2s' file
##   ##
##   ##-- low-level data
##   s2i => $s2i,              ##-- Lingua::TT::DBFile object for 'sym2id'
##   i2s => $i2s,              ##-- Lingua::TT::DBFile object for 'id2sym'
##   sym2id => \%sym2id,       ##-- ref to tied data: $sym => $id
##   id2sym => \%id2sym,       ##-- ref to tied data: $id  => $sym
##   size => $n_ids,           ##-- number of allocated ids (== index of first free id)
sub new {
  my $that = shift;
  my $dbe = bless({
		   file => undef,
		   opts_s2i => { type=>'HASH' },
		   opts_i2s => { type=>'HASH' },
		   s2i => undef,
		   i2s => undef,
		   sym2id => undef,
		   id2sym => undef,
		   size => undef,
		   @_
		  }, ref($that)||$that);
  return $dbe->open($dbe->{file}) if (defined($dbe->{file}));
  return $dbe;
}

## undef = $dbe->clear()
sub clear {
  my $dbe = shift;
  return if (!$dbe->opened);
  $dbe->{s2i}->clear;
  $dbe->{i2s}->clear;
  $dbe->{size} = 0;
  return $dbe;
}

##==============================================================================
## Methods: I/O

## $bool = $dbe->opened()
sub opened {
  return defined($_[0]{s2i});
}

## $dbe = $dbe->close()
sub close {
  my $dbe = shift;
  @$dbe{qw(sym2id id2sym size)} = qw();
  $dbe->{s2i}->close if ($dbe->{s2i});
  $dbe->{i2s}->close if ($dbe->{i2s});
  return $dbe;
}

## $dbe = $dbe->open($file,%opts)
##  + %opts are as for new()
sub open {
  my ($dbe,$file,%opts) = @_;
  $dbe->close() if ($dbe->opened());
  $dbe->{file} = $file;
  @$dbe{keys %opts} = values(%opts);

  $dbe->{s2i} = Lingua::TT::DBFile->new(%{$dbe->{opts_s2i}}, file=>undef);
  $dbe->{i2s} = Lingua::TT::DBFile->new(%{$dbe->{opts_i2s}}, file=>undef);

  $dbe->{s2i}->open("${file}_s2i.db")
    or croak(ref($dbe)."::open() failed for '${file}_s2i.db': $!");
  $dbe->{i2s}->open($file."_i2s.db")
    or croak(ref($dbe)."::open() failed for '${file}_i2s.db': $!");

  ##-- initialize local references
  $dbe->{id2sym} = $dbe->{i2s}{data};
  $dbe->{sym2id} = $dbe->{s2i}{data};

  $dbe->{size} = 0;
  my ($key,$val);
  while (($key,$val)=each(%{$dbe->{sym2id}})) {
    ++$dbe->{size};
  }

  return $dbe;
}

##==============================================================================
## Methods: Access and Manipulation

## $id = $dbe->getId($sym)
##  + gets (possibly new) id for $sym
sub getId {
  return $_[0]{sym2id}{$_[1]} if (exists($_[0]{sym2id}{$_[1]}));
  #$_[0]{id2sym}[$_[0]{size}] = $_[1];
  $_[0]{id2sym}{$_[0]{size}} = $_[1];
  return $_[0]{sym2id}{$_[1]} = $_[0]{size}++;
}

## $id = $dbe->getSym($id)
##  + gets (possibly new (and if so, "SYM${i}")) symbol for $id
sub getSym {
  return $_[0]{id2sym}[$_[1]] if ($_[1] < $_[0]{size});
  $_[0]{sym2id}{"SYM$_[1]"} = $_[1];
  #return $_[0]{id2sym}[$_[1]] = "SYM$_[1]";
  return $_[0]{id2sym}{$_[1]} = "SYM$_[1]";
}


##==============================================================================
## Footer
1;

__END__
