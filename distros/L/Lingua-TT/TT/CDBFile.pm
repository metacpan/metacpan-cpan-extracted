## -*- Mode: CPerl -*-
## File: Lingua::TT::CDBFile.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT I/O: CDB: tied read-only access via CDB_File

package Lingua::TT::CDBFile;
use Lingua::TT::Dict;
use CDB_File;
use Carp;
use IO::File;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(Lingua::TT::Dict);

##==============================================================================
## Constructors etc.

## $dbf = CLASS_OR_OBJECT->new(%opts)
## + %opts, %$doc:
##   ##-- user options
##   file     => $filename,    ##-- default: undef (none)
##   tmpfile  => $tmpfilename, ##-- defualt: "$filename.$$" (not used correctly due to CDB_File bug)
##   mode     => $mode,        ##-- open mode 'r', 'w', 'rw', '<', '>', '>>': default='r'
##   utf8     => $bool,        ##-- if true, keys/values are stored as UTF8 (default=1)
##   ##
##   ##-- low-level data
##   data   => \%data,         ##-- tied data (hash)
##   tied   => $ref,           ##-- read-only: reference returned by tie()
##   writer => $ref,           ##-- read/write: reference returned by CDB_File::new()
##   fetch  => \&fetch,        ##-- fetch subroutine: $val = $fetch->($key)
##   store  => \&store,        ##-- store subroutine: $val = $store->($key,$val)#
sub new {
  my $that = shift;
  my $dbf = bless({
		   file    => undef,
		   tmpfile => undef,
		   mode    => 'r',
		   utf8    => 1,
		   ##
		   data   => undef,
		   tied   => undef,
		   @_
		  }, ref($that)||$that);
  return $dbf->open($dbf->{file}) if (defined($dbf->{file}));
  return $dbf;
}

## undef = $dbf->clear()
##  + clears data (if any)
sub clear {
  my $dbf = shift;
  return if (!$dbf->opened);
  %{$dbf->{data}} = qw();
  return $dbf;
}


##==============================================================================
## Methods: low-level utilities

##==============================================================================
## Methods: I/O

## $bool = $dbf->opened()
sub opened {
  return (defined($_[0]{tied}) || defined($_[0]{writer}));
}

## $dbf = $dbf->close()
sub close {
  my $dbf = shift;
  return $dbf if (!$dbf->opened);
  $dbf->{writer}->finish() if ($dbf->{writer});
  delete(@$dbf{qw(fetch store)});
  if (defined($dbf->{tied})) {
    $dbf->{tied} = undef;
    untie(%{$dbf->{data}});
  }
  return $dbf;
}

## $dbf = $dbf->open($file,%opts)
##  + %opts are as for new()
##  + $file defaults to $dbf->{file}
sub open {
  my ($dbf,$file,%opts) = @_;
  $dbf->close() if ($dbf->opened);
  @$dbf{keys %opts} = values(%opts);
  $file           = $dbf->{file} if (!defined($file));
  $dbf->{file}    = $file;
  $dbf->{tmpfile} = "$file.$$" if (!defined($dbf->{tmpfile}));

  ##-- truncate file here if user requested it
  if ($dbf->{mode} =~ /^[\+r]*[>w]$/) {
    $dbf->truncate()
      or confess(ref($dbf)."::open(): could not truncate file '$dbf->{file}': $!");
  }

  ##-- tie data hash
  delete(@$dbf{qw(writer data tied fetch store)});
  if ($dbf->{mode} =~ /[\+w>]/) {
    $dbf->{writer} = CDB_File->new($dbf->{file}, $dbf->{tmpfile})
      or confess(ref($dbf)."::open(): CDB_File->new() failed for '$dbf->{file}': $!");
  }
  if ($dbf->{mode} =~ /[\+r<]/) {
    $dbf->{data} = {};
    $dbf->{tied} = tie(%{$dbf->{data}}, 'CDB_File', $dbf->{file}) #$dbf->{tmpfile}
      or confess(ref($dbf).":open(): could not tie CDB_File for file '$dbf->{file}': $!");
  }

  ##-- set fetch/store closures
  $dbf->{fetch} = $dbf->fetchSub();
  $dbf->{store} = $dbf->storeSub();

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
  !-e $file || unlink($file) || return undef;
}

## $bool = $dbf->sync()
## $bool = $dbf->sync($flags)
sub sync {
  my $dbf = shift;
  return 1 if (!$dbf->opened);
  return $dbf->close() && $dbf->open() ? 1 : 0;
}

## $bool = $dbf->copy($file2)
## $bool = PACKAGE::copy($file1,$file2)
##  + copies database data to $file2
sub copy {
  confess(ref($_[0])."::copy() not implemented");
}

##==============================================================================
## Methods: Lookup: Closures

## \&sub = $dbf->fetchSub($key)
##   + subroutine to return (decoded) value
sub fetchSub {
  my $tied = $_[0]{tied};
  if ($_[0]{utf8}) {
    ##-- TT mode, utf8
    return sub {
      local $_ = $tied->FETCH($_[0]);
      utf8::decode($_);
      return $_;
    };
  }
  ##-- TT mode, raw
  return sub {
    return $tied->FETCH($_[0]);
  };
}

## $storeSub = $dbf->store($key,$val)
sub storeSub {
  my $tied = $_[0]{tied};
  return sub {
    return $tied->STORE($_[0],$_[1]);
  };
}

##==============================================================================
## Methods: Lookup

## $val = $dbf->fetch($key)
##   + returns (decoded) value
sub fetch {
  return $_[0]{fetch}->($_[1]);
}

## $val = $dbf->store($key)
##  + just stores value
sub store {
  return $_[0]{store}->($_[1],$_[2]);
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
  my $fetch         = $dict->{fetch};
  my $include_empty = $opts{allow_empty};
  my ($text,$a_in,$a_dict);
  return sub {
    ($text,$a_in) = split(/\t/,$_,2);
    $a_dict       = $fetch->($text);
    $_            = join("\t", $text, (defined($a_in) ? $a_in : qw()), (defined($a_dict) && ($include_empty || $a_dict ne '') ? $a_dict : qw()))."\n";
  };
}



##==============================================================================
## Methods: TT::Persistent

## @keys = $dbf->noSaveKeys()
sub noSaveKeys {
  return qw(data tied writer fetch store);
}

##==============================================================================
## Footer
1;

__END__
