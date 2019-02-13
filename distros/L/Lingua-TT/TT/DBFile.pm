## -*- Mode: CPerl -*-
## File: Lingua::TT::DBFile.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT I/O: Berkely DB: tied Files


package Lingua::TT::DBFile;
use 5.010; ##-- for // operator
use Lingua::TT::Persistent;
use DB_File;
use Fcntl;
use Carp;
use IO::File;
use File::Copy qw();
use Encode qw(encode decode);
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(Lingua::TT::Persistent);

## $DEFAULT_TYPE
##  + default file type if otherwise unspecified
our $DEFAULT_TYPE = 'BTREE';

##==============================================================================
## Constructors etc.

## $dbf = CLASS_OR_OBJECT->new(%opts)
## + %opts, %$doc:
##   ##-- user options
##   file  => $filename,    ##-- default: undef (none)
##   mode  => $mode,       ##-- default: 0666 & ~umask
##   flags => $flags,      ##-- default: O_RDWR|O_CREAT
##   type    => $type,     ##-- one of 'HASH', 'BTREE', 'RECNO', 'GUESS' (default: 'GUESS' for read, $DEFAULT_TYPE otherwise)
##   dbinfo  => \%dbinfo,  ##-- default: "DB_File::${type}INFO"->new();
##   dbopts  => \%opts,    ##-- db options (e.g. cachesize,bval,...) -- defaults to none (uses DB_File defaults)
##   encoding => $enc,     ##-- if defined, $enc will be used to store db data (uses Encode and DB filters); default=undef (raw bytes)
##   pack_key => $packas,  ##-- if defined, $packas will be used to (un)pack db keys
##   pack_val => $packas,  ##-- if defined, $packas will be used to (un)pack db values
##   pack_sep => $str,     ##-- separator string for multi-value pack/unpack (default="\t")
##   ##
##   ##-- low-level data
##   data   => $thingy,    ##-- tied data (hash or array)
##   tied   => $ref,       ##-- reference returned by tie()
sub new {
  my $that = shift;
  my $db = bless({
		  file   => undef,
		  encoding => undef,
		  pack_key => undef,
		  pack_val => undef,
		  pack_sep => "\t",
		  mode   => (0644 & ~umask),
		  flags  => (O_RDWR|O_CREAT),
		  type   => undef, ##-- no default type (guess)
		  dbinfo => undef,
		  dbopts => {},
		  data   => undef,
		  tied   => undef,
		  @_
		 }, ref($that)||$that);
  #$db->{dbinfo} = ("DB_File::".uc($db->{type})."INFO")->new() if (!defined($db->{dbinfo}));
  return $db->open($db->{file}) if (defined($db->{file}));
  return $db;
}

## undef = $dbf->clear()
##  + clears data (if any)
sub clear {
  my $dbf = shift;
  return if (!$dbf->opened);
  if (uc($dbf->{type}) eq 'RECNO') {
    $dbf->{tied}->splice(0,scalar(@{$dbf->{data}}));
  } else {
    %{$dbf->{data}} = qw();
  }
  return $dbf;
}

##==============================================================================
## Class Methods

## $typeString = $that->guessFileType($filename_or_handle)
##  + attempts to guess type of $filename; returns undef on failure
##  + this will die() if $filename doesn't already exist
##  + magic codes grabbed from /usr/share/file/magic
sub guessFileType {
  my ($that,$file) = @_;
  my $fh  = ref($file) ? $file     : IO::File->new("<$file");
  my $pos = ref($file) ? tell($fh) : undef;
  die(__PACKAGE__ . "::guessFileType(): open failed for '$file': $!") if (!$fh);
  CORE::binmode($fh);
  my ($buf,$typ,$magic,$fmt);
  seek($fh,12,SEEK_SET) or return undef;
  read($fh,$buf,4)==4   or return undef;
  foreach $fmt (qw(L N V)) {
    $magic = unpack($fmt,$buf);
    if    ($magic == 0x00053162) { $typ='BTREE'; last; }
    elsif ($magic == 0x00061561) { $typ='HASH'; last; }
  }
  if (ref($file)) {
    seek($fh,$pos,SEEK_SET); ##-- return handle to original position
  } else {
    $fh->close();
  }
  return $typ;
}


##==============================================================================
## Methods: low-level utilities

##==============================================================================
## Methods: I/O

## $bool = $dbf->opened()
sub opened {
  return defined($_[0]{tied});
}

## $dbf = $dbf->close()
sub close {
  my $dbf = shift;
  return $dbf if (!$dbf->opened);
  $dbf->{tied} = undef;
  if (uc($dbf->{type}) eq 'RECNO') {
    untie(@{$dbf->{data}});
  } else {
    untie(%{$dbf->{data}});
  }
  return $dbf;
}

## $sizeInt = parseSize($sizeString)
sub parseSize {
  my ($dbf,$str) = @_;
  if (defined($str) && $str =~ /^\s*([\d\.\+\-eE]*)\s*([BKMGT]?)\s*$/i) {
    my ($size,$suff) = ($1,$2);
    $suff = 'B' if (!defined($suff));
    $suff = uc($suff);
    $size *= 1024    if ($suff eq 'K');
    $size *= 1024**2 if ($suff eq 'M');
    $size *= 1024**3 if ($suff eq 'G');
    $size *= 1024**4 if ($suff eq 'T');
    return $size;
  }
  return $str;
}

## \%opts = $dbf->parseOptions(\%opts=$dbf->{dbopts})
sub parseOptions {
  my ($dbf,$dbopts) = @_;
  $dbopts = $dbf->{dbopts} if (!$dbopts);
  $dbopts = $dbf->{dbopts} = {} if (!$dbopts);

  ##-- parse: size arguments
  foreach (qw(cachesize psize)) {
    $dbopts->{$_} = $dbf->parseSize($dbopts->{$_}) if (defined($dbopts->{$_}));
  }

  ##-- delete undef arguments
  delete @$dbopts{grep {!defined($dbopts->{$_})} keys %$dbopts};

  return $dbopts;
}


## $dbf = $dbf->open($file,%opts)
##  + %opts are as for new()
##  + $file defaults to $dbf->{file}
sub open {
  my ($dbf,$file,%opts) = @_;
  $dbf->close() if ($dbf->opened);
  @$dbf{keys %opts} = values(%opts);
  $file = $dbf->{file} if (!defined($file));
  $dbf->{file} = $file;
  $dbf->parseOptions();

  ##-- truncate file here if user specified O_TRUNC, since DB_File doesn't
  if (($dbf->{flags} & O_TRUNC) && defined($dbf->{file}) && -e $dbf->{file}) {
    $dbf->truncate()
      or confess(ref($dbf)."::open(O_TRUNC): could not unlink file '$dbf->{file}': $!");
  }

  ##-- guess file type
  if (!defined($dbf->{type}) || uc($dbf->{type}) eq 'GUESS') {
    if (-e $dbf->{file}) {
      $dbf->{type} = $dbf->guessFileType($dbf->{file}) || 'RECNO';
    }
    $dbf->{type} = $DEFAULT_TYPE if (!defined($dbf->{type}) || uc($dbf->{type}) eq 'GUESS'); ##-- last-ditch effort
  }

  ##-- parse bval (octal, hex, and unicode escapes)
  if ($dbf->{dbopts}{bval} && length($dbf->{dbopts}{bval}) != 1) {
    $dbf->{dbopts}{bval} =~ s{\\([0-7]{1,3})}{chr(oct($1))}ge;
    $dbf->{dbopts}{bval} =~ s{\\x([0-9a-f]{1,2})}{chr(hex($1))}gie;
    $dbf->{dbopts}{bval} =~ s{\\u([0-9a-f]{1,4})}{chr(hex($1))}gie;
    $dbf->{dbopts}{bval} =~ s{\\n}{\n}g;
    $dbf->{dbopts}{bval} =~ s{\\r}{\r}g;
    $dbf->{dbopts}{bval} =~ s{\\t}{\t}g;
    $dbf->{dbopts}{bval} =~ s{\\v}{\x0b}g;
  }

  ##-- setup info
  $dbf->{dbinfo} = ("DB_File::".uc($dbf->{type})."INFO")->new();
  @{$dbf->{dbinfo}}{keys %{$dbf->{dbopts}}} = values %{$dbf->{dbopts}};

  if (uc($dbf->{type}) eq 'RECNO') {
    ##-- tie: recno (array)
    $dbf->{dbinfo}{flags} |= R_FIXEDLEN if (defined($dbf->{dbinfo}{reclen}));
    $dbf->{data} = [];
    $dbf->{tied} = tie(@{$dbf->{data}}, 'DB_File', $dbf->{file}, $dbf->{flags}, $dbf->{mode}, $dbf->{dbinfo})
      or confess(ref($dbf).":open(): tie() failed for ARRAY file '$dbf->{file}': $!");
  } else {
    ##-- tie: btree or hash (hash)
    $dbf->{data} = {};
    $dbf->{tied} = tie(%{$dbf->{data}}, 'DB_File', $dbf->{file}, $dbf->{flags}, $dbf->{mode}, $dbf->{dbinfo})
      or confess(ref($dbf).":open(): tie() failed for $dbf->{type} file '$dbf->{file}': $!");
  }

  ##-- maybe install encoding filters
  if (defined($dbf->{encoding}) && $dbf->{encoding} ne 'raw') {
    my $ffetch = $dbf->encFilterFetch();
    my $fstore = $dbf->encFilterStore();
    if (uc($dbf->{type}) ne 'RECNO') {
      $dbf->{tied}->filter_fetch_key($ffetch);
      $dbf->{tied}->filter_store_key($fstore);
    }
    $dbf->{tied}->filter_fetch_value($ffetch);
    $dbf->{tied}->filter_store_value($fstore);
  }
  else {
    ##-- maybe install pack filters
    if (defined($dbf->{pack_key}) && $dbf->{pack_key} ne 'raw' && uc($dbf->{type}) ne 'RECNO') {
      $dbf->{tied}->filter_fetch_key($dbf->packFilterFetch($dbf->{pack_key}));
      $dbf->{tied}->filter_store_key($dbf->packFilterStore($dbf->{pack_key}));
    }
    if (defined($dbf->{pack_val}) && $dbf->{pack_val} ne 'raw') {
      $dbf->{tied}->filter_fetch_value($dbf->packFilterFetch($dbf->{pack_val}));
      $dbf->{tied}->filter_store_value($dbf->packFilterStore($dbf->{pack_val}));
    }
  }

  return $dbf;
}

## $bool = $dbf->truncate()
## $bool = $CLASS_OR_OBJ->truncate($file)
##  + actually calls unlink($file)
##  + no-op if $file and $dbf->{file} are both undef
sub truncate {
  my ($dbf,$file) = @_;
  $file = $dbf->{file} if (!defined($file));
  return if (!defined($file));
  unlink($file);
}

## $bool = $dbf->sync()
## $bool = $dbf->sync($flags)
sub sync {
  my $dbf = shift;
  return 1 if (!$dbf->opened);
  return $dbf->{tied}->sync(@_) == 0;
}

## $bool = $dbf->copy($file2)
## $bool = PACKAGE::copy($file1,$file2)
##  + copies database data to $file2
sub copy {
  my ($dbf,$file2) = @_;
  my $that  = ref($dbf) || __PACKAGE__;
  my $file1 = ref($dbf) ? $dbf->{file} : $dbf;
  confess("${that}::copy(): no source specified!") if (!defined($file1));
  confess("${that}::copy(): no destination specified!") if (!defined($file2));
  if (ref($dbf)) { $dbf->sync() or confess("${that}::copy(): sync failed: $!"); }
  File::Copy::copy($file1, $file2)
      or confess("${that}::copy() failed from '$file1' to '$file2': $!");
  return 1;
}

##==============================================================================
## Methods: TT::Persistent

## @keys = $dbf->noSaveKeys()
sub noSaveKeys {
  return qw(dbinfo dbopts data tied);
}

##==============================================================================
## Utils: Filters

## \&filter_sub = $db->encFilterFetch()
## \&filter_sub = $db->encFilterFetch($encoding=$db->{encoding})
##   + returns a DB FETCH-filter sub for transparent decoding of DB-data from $encoding
sub encFilterFetch {
  my $enc = defined($_[1]) ? $_[1] : $_[0]{encoding};
  return undef if (!$enc || $enc eq 'raw');
  return sub {
    $_ = decode($enc,$_);
  };
}

## \&filter_sub = $db->encFilterStore()
## \&filter_sub = $db->encFilterStore($encoding=$db->{encoding})
##   + returns a DB STORE-filter sub for transparent encoding of DB-data to $encoding
sub encFilterStore {
  my $enc = defined($_[1]) ? $_[1] : $_[0]{encoding};
  return undef if (!$enc || $enc eq 'raw');
  return sub {
    $_ = encode($enc,$_);
  };
}

## \&filter_sub = $dbf->packFilterFetch($packas)
##   + returns a DB FETCH-filter sub for transparent unpacking of DB-data from $packas
sub packFilterFetch {
  my ($dbf,$packas) = @_;
  my $packsep = $dbf->{pack_sep} // "\t";
  return undef if (!$packas || $packas eq 'raw');
  if (length($packas)==1) {
    return sub {
      $_ = unpack($packas,$_);
    };
  } else {
    return sub {
      $_ = join($packsep,unpack($packas,$_));
    }
  }
}

## \&filter_sub = $db->packFilterStore($packas)
##   + returns a DB STORE-filter sub for transparent encoding of DB-data to $encoding
sub packFilterStore {
  my ($dbf,$packas) = @_;
  my $packsep = $dbf->{packsep} // "\t";
  return undef if (!$packas || $packas eq 'raw');
  if (length($packas)==1) {
    return sub {
      $_ = pack($packas,$_);
    };
  } else {
    return sub {
      $_ = pack($packas,ref($_) ? @$_ : split($packsep,$_));
    };
  }
}


##==============================================================================
## Footer
1;

__END__
