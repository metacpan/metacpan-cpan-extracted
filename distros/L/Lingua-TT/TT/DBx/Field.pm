## -*- Mode: CPerl -*-
## File: Lingua::TT::DBx::Field.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT I/O: Berkely DB: enumerated fields

package Lingua::TT::DBx::Field;
use Lingua::TT::DBFile;
use Lingua::TT::Enum;
use Lingua::TT::Persistent;
use DB_File;
use Fcntl;
use Carp;
use File::Copy qw();
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(Lingua::TT::Persistent);

##==============================================================================
## Constructors etc.

## $f = CLASS_OR_OBJECT->new(%opts)
## + no implicit open() on new!
## + %opts, %$doc:
##   ##-- user options
##   name => $name,        ##-- field name (default=undef)
##   dir  => $dir,         ##-- base directory (default='.')
##   packfmt => $packfmt,  ##-- packed $data format (default='L')
##   get => $codestr,      ##-- code to get field data in $_=[$data1,$data2,...]
##                         ##   + compiled to a temporary sub $getsub = eval "sub { $codestr }"
##                         ##   + should return ARRAY of matched token data columns
##                         ##   + called as:
##                         ##      $field_value_string = join("\t", $getsub->());
##                         ##   + default: @$_
##
##   ##-- low-level data
##   file   => $file,      ##-- basename of field data files (default=undef --> from 'name')
##   flags  => $O_XYZ,     ##-- flags mask for dbf
##   enum   => $enum,      ##-- Lingua::TT::Enum: "${file}.enum"
##   dbf    => $dbfile,    ##-- Lingua::TT::DBFile::PackedArray: "${file}.db"
##   data   => $thingy,    ##-- = $doc->{dbf}{data}
sub new {
  my $that = shift;
  my $f = bless({
		 name => undef,
		 dir  => '.',
		 packfmt => 'L',
		 get  => '@$_',
		 file => undef,
		 enum => undef,
		 dbf => undef,
		 data => undef,
		 @_
		}, ref($that)||$that);
  return $f;
}

## undef = $f->clear()
sub clear {
  my $f = shift;
  return if (!$f->opened);
  $f->{enum}->clear;
  $f->{dbf}->clear;
  return $f;
}

##==============================================================================
## Methods: I/O

## $file = $CLASS_OR_OBJ->name2file($name)
sub name2file {
  my ($f,$name) = @_;
  $name = $f->{name} if (!defined($name) && defined($f->{name}));
  $name = '' if (!defined($name));
  my $file = $name;
  $file =~ s/[\s\/\:\;\#]/_/g;
  $file = $f->{dir}.'/'.$name if (ref($f) && defined($f->{dir}));
  return $file;
}

## $file = $f->filename()
sub filename {
  return $_[0]->name2file();
}

## $bool = $f->opened()
sub opened {
  return defined($_[0]{data});
}

## $f = $f->close(%opts)
##  + %opts:
##     nosync => $bool,  ##-- if true, no sync() will be performed
sub close {
  my ($f,%opts) = @_;
  delete($f->{data});
  if (!$opts{nosync}) {
    $f->sync() or warn(ref($f)."::close(): sync failed: $!");
  }
  $f->{dbf}->close if (defined($f->{dbf}));
  delete(@$f{qw(enum dbf)});
  return $f;
}

## $bool = $f->sync()
##  + syncs enum to file too
sub sync {
  my $f = shift;
  my $rc = 1;
  my $file = $f->{file};
  if (defined($f->{enum}) && $file) {
    $rc &&= $f->{enum}->saveNativeFile("$file.enum")
      or warn(ref($f)."::sync(): save failed for enum file '$file.enum': $!");
  }
  if (defined($f->{dbf})) {
    $rc &&= $f->{dbf}->sync()
      or warn(ref($f)."::sync(): save failed for enum file '$file.enum': $!");
  }
  return $rc;
}

## $f = $f->open(%opts)
##  + %opts are as for new()
sub open {
  my ($f,%opts) = @_;
  $f->close() if ($f->opened());
  @$f{keys %opts} = values(%opts);
  confess(ref($f)."::open(): no 'name' key defined!") if (!defined($f->{name}));
  my $file = $f->{file} = $f->filename();

  $f->{enum} = Lingua::TT::Enum->new();
  $f->{dbf}  = Lingua::TT::DBFile::PackedArray->new(packfmt=>$f->{packfmt});

  ##-- truncate enum?
  if (defined($f->{flags}) && ($f->{flags}&O_TRUNC)) {
    my $fh = IO::File->new(">${file}.enum")
      or confess(ref($f)."::load(): truncate failed for enum file '$file.enum': $!");
    $fh->close;
  }

  ##-- load file(s)
  $f->{enum}->loadNativeFile("${file}.enum")
    or confess(ref($f)."::load() failed for field enum file '${file}.enum': $!");
  $f->{dbf}->open($file.".db",
		  (defined($f->{flags}) ? (flags=>$f->{flags}) : qw()),
		 )
    or confess(ref($f)."::open() failed for field data file '${file}.db': $!");

  ##-- local references
  $f->{data} = $f->{dbf}{data};

  return $f;
}

## $bool = $f->copy($file2);
## $bool = PACKAGE::copy($file1,$file2)
sub copy {
  my ($f,$file2) = @_;
  my $that  = ref($f) || __PACKAGE__;
  my $file1 = ref($f)  ? $f->filename : $f;
  confess("${that}::copy(): no source specified!") if (!defined($file1));
  confess("${that}::copy(): no destination specified!") if (!defined($file2));
  if (ref($f)) { $f->sync() or confess("${that}::copy(): sync failed: $!"); }
  File::Copy::copy("$file1.enum","$file2.enum")
      or confess("${that}::copy() failed for enum file from '$file1.enum' to '$file2.enum': $!");
  File::Copy::copy("$file1.db","$file2.db")
      or confess("${that}::copy() failed for DB file from '$file1.db' to '$file2.db': $!");
  return 1;
}

## @filenames = $f->datafiles()
## @filenames = $CLASS_OR_OBJ->datafiles($name)
## @suffixes  = $CLASS->datafiles()
sub datafiles {
  my ($f,$name) = @_;
  my $file = $f->name2file($name);
  return ("$file.enum", "$file.db");
}

## $bool = $f->fileExists()
## $bool = $f->fileExists($name)
sub fileExists {
  my ($f,$name) = @_;
  my $file = $f->name2file($name);
  return (-e "$file.enum" && -e "$file.db");
}

## $bool = $f->truncate()
## $bool = $f->truncate($name)
sub truncate {
  my ($f,$name) = @_;
  my $file = $f->name2file($name);
  return ((!-e "$file.db" || unlink("$file.db"))
	  &&
	  (!-e "$file.enum" || CORE::truncate("$file.enum",0)));
}

##==============================================================================
## Methods: I/O: TT::Persistent

## @keys = $f->noSaveKeys
sub noSaveKeys {
  return qw(enum dbf data getsub);
}

##==============================================================================
## Methods: Access and Manipulation

## $f = $f->compileClosures()
sub compileClosures {
  my $f = shift;
  $f->{getsub} = eval "sub { $f->{get} }";
  return $f;
}

## $bool = $f->putToken(\@tok)
##  + adds field data for single token
our ($put_val,$put_id);
sub putToken {
  local $_ = $_[1];
  $put_val = join("\t",grep {defined($_)} $_[0]{getsub}->());
  $put_id = $_[0]{enum}->getId($put_val) if (!defined($put_id=$_[0]{enum}{sym2id}{$put_val}));
  push(@{$_[0]{data}}, pack($_[0]{packfmt},$put_id));
}


##==============================================================================
## Footer
1;

__END__
