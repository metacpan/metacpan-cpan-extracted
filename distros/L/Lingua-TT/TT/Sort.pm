## -*- Mode: CPerl -*-
## File: Lingua::TT::Sort.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT: sorting (using system 'sort' cmd)


package Lingua::TT::Sort;
use File::Temp qw(tempfile);
use IO::File;
use Exporter;
use Carp;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(Exporter);
our @EXPORT = qw();
our %EXPORT_TAGS = (
		    'vars' => [qw($FS_KEEP $FS_DIR $FS_SUFFIX $FS_PREFIX $FS_VERBOSE)],
		    'sort' => [qw(fs_filesort fs_filemerge fs_cmdfh)],
		    'tmp' => [qw(fs_tmpfile fs_system)],
		   );
$EXPORT_TAGS{all} = [map {@$_} values(%EXPORT_TAGS)];
our @EXPORT_OK = @{$EXPORT_TAGS{all}};


our $FS_KEEP = 0;
our $FS_DIR = $ENV{TMPDIR} || $ENV{TMP} || (-d '/tmp' ? '/tmp' : '.');
our $FS_SUFFIX = '.tmp';
our $FS_PREFIX = 'fs';
our $FS_VERBOSE = 0;

BEGIN {
  $ENV{LC_ALL}="C";
}

##==============================================================================
## OO interface

## $sort = Lingua::TT::Sort->new(%opts)
##  + %opts
##     keep    => $bool,      ##-- keep temps?
##     prefix  => $prefix,    ##-- tempfile prefix
##     suffix  => $suffix,    ##-- tempfile suffix
##     dir     => $dir,       ##-- temp directory
sub new {
  my $that = shift;
  return bless({
		keep=>$FS_KEEP,
		dir=>$FS_DIR,
		prefix=>$FS_PREFIX,
		suffix=>$FS_SUFFIX,
		verbose=>$FS_VERBOSE,
		@_
	       }, ref($that)||$that);
}


##==============================================================================
## Methods

## $tmpfile = $sort->tmpfile()
sub tmpfile {
  my $sort = shift;
  my ($tmpfh,$tmpfile) = tempfile($sort->{prefix}.('X' x (length($sort->{prefix}) <= 4 ? (8-length($sort->{prefix})) : 4)),
				  SUFFIX=>$sort->{suffix},
				  UNLINK=>!$sort->{keep},
				  DIR=>$sort->{dir});
  confess(ref($sort)."::tmpfile(): could not get temporary file: $!") if (!defined($tmpfh));
  $tmpfh->close;
  return $tmpfile;
}

## undef = $sort->vmsg($level,@msg)
#  + print @msg to STDERR if $sort->{verbose} >= $level
sub vmsg {
  my ($sort,$level,@msg) = @_;
  print STDERR (@msg) if (defined($sort->{verbose}) && $sort->{verbose} >= $level);
}


## $rc = $sort->system(@cmd)
sub system {
  my ($sort,@cmd) = @_;
  $sort->vmsg(1,(ref($sort)||$sort), ": ", join(' ', @cmd), "\n");
  return CORE::system(@cmd);
}

## $tmpfile = $sort->filesort(@sort_args)
sub filesort {
  my $sort    = shift;
  my $tmpfile = fs_tmpfile();
  my @cmd = ('sort','-o',$tmpfile,@_);
  $sort->system(@cmd)==0
    or confess(ref($sort)||$sort, ": system(".join(' ',@cmd).") failed: $!");
  return $tmpfile;
}

## $tmpfile = $sort->filemerge(@infiles)
##   + @infiles are assumed already to be sorted
sub filemerge {
  my $sort    = shift;
  my $tmpfile = fs_tmpfile();
  my @cmd = ('sort','-o',$tmpfile,'-m',@_);
  $sort->system(@cmd)==0
    or confess(ref($sort)||$sort, ": system(".join(' ',@cmd).") failed: $!");
  return $tmpfile;
}

## $sortfh = $sort->cmdfh(@cmd)
##  + warning: @cmd get interpolated; you may need to shell-quote them!
##  + opend for read from `@cmd` by default
sub cmdfh {
  my ($sort,@cmd) = @_;
  my $cmd = join(' ', @cmd);
  $cmd = "$cmd |" if ($cmd !~ /\|/);
  $sort->vmsg(1,(ref($sort)||$sort), ": $cmd\n");
  my $sortfh = IO::File->new($cmd)
    or confess((ref($sort)||$sort), ": open failed for \`$cmd\`: $!");
  return $sortfh;
}


##==============================================================================
## Utils

## $tmpfile = PACKAGE::tmpfile()
sub fs_tmpfile { return __PACKAGE__->new->tmpfile; }

## $sorted_filename = PACKAGE::fs_filesort(@sort_args)
sub fs_filesort { return __PACKAGE__->new->filesort(@_); }

## $tmpfile = PACKAGE::fs_filemerge(@infiles)
##   + @infiles are assumed already to be sorted
sub fs_filemerge { return __PACKAGE__->new->filemerge(@_); }

## $cmdfh = PACKAGE::fs_cmdfh($cmd)
sub fs_cmdfh { return __PACKAGE__->new->cmdfh(@_); }

## $rc = PACKAGE::fs_system(@cmd)
sub fs_system { return __PACKAGE__->new->system(@_); }


##==============================================================================
## Footer
1;

__END__
