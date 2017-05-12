## -*- Mode: CPerl -*-
## File: DiaColloDB::PackedFile::MMap.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db: flat fixed-length record-oriented files; mmap variant

package DiaColloDB::PackedFile::MMap;
use DiaColloDB::PackedFile;
use DiaColloDB::Utils qw(:fcntl :file :pack);
use File::Map qw(map_handle);
use Fcntl qw(:DEFAULT :seek);
use Carp;
use strict;
no warnings 'portable';

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::PackedFile);

##==============================================================================
## Constructors etc.

## $pf = CLASS_OR_OBJECT->new(%opts)
## + %opts, %$pf:
##   ##-- PackedFile: user options
##   file     => $filename,   ##-- default: undef (none)
##   flags    => $flags,      ##-- fcntl flags or open-mode (default='r')
##   perms    => $perms,      ##-- creation permissions (default=(0666 &~umask))
##   reclen   => $reclen,     ##-- record-length in bytes: (default: guess from pack format if available)
##   packas   => $packas,     ##-- pack-format or array; see DiaColloDB::Utils::packFilterStore();
##   temp     => $bool,       ##-- if true, data file(s) will be unlinked on DESTROY
##   ##
##   ##-- PackedFile: filters
##   filter_fetch => $filter, ##-- DB_File-style filter for fetch
##   filter_store => $filter, ##-- DB_File-style filter for store
##   ##
##   ##-- PackedFile: low-level data
##   fh       => $fh,         ##-- underlying filehandle
##   ##
##   ##-- PackedFile::MMap: buffers
##   bufr     => \$buf,       ##-- mmap $fh
##   bufp     => $bufp,       ##-- current buffer position (logical record number)
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   #$bufr=>undef,
			   #bufp=>0,
			   @_,
			  );
}


##==============================================================================
## API: open/close

## $pf = $pf->open()
## $pf = $pf->open($file)
## $pf = $pf->open($file,$flags,%opts)
##  + %opts are as for new()
##  + $file defaults to $pf->{file}
sub open {
  my ($pf,$file,$flags,%opts) = @_;
  $pf->SUPER::open($file,$flags,%opts) or return undef;
  return $pf if (!$pf->isa(__PACKAGE__)); ##-- superclass open() promoted us to another class
  $pf->{bufp} = 0;
  return $pf->remap();
}

## $bool = $pf->remap()
##  + re-maps $pf->{bufr} from $pf->{fh}
sub remap {
  my $pf = shift;

  ##-- try to ensure filehandle is flushed to disk to handle recent writes
  if (fcwrite($pf->{flags}//'r')) {
    CORE::seek($pf->{fh},0,SEEK_END) or return undef;
    CORE::truncate($pf->{fh}, $pf->{fh}->tell) or return undef;
  }
  CORE::seek($pf->{fh},0,SEEK_SET) or return undef;

  ##-- mmap handles
  my ($buf);
  ##-- BUGHUNT/birmingham.2016-07: "could not map errors" after 5 calls to remap() (xf.dba2, called from Unigrams::loadTextFile via flush())
  map_handle($buf,  $pf->{fh},  fcperl($pf->{flags}));
  $pf->{bufr} = \$buf;

  return $pf;
}

## $bool = $pf->opened()
sub opened {
  return defined($_[0]{bufr});
}

## $bool = $pf->reopen()
##  + re-opens datafile
sub reopen {
  my $pf = shift;
  return $pf->SUPER::reopen() && $pf->remap();
}

## $bool = $pf->close()
sub close {
  my $pf = shift;
  my $rc = $pf->SUPER::close();
  delete $pf->{bufr};
  return $rc;
}

## $bool = $pf->setsize($nrecords)
sub setsize {
  my $pf = shift;
  $pf->SUPER::setsize(@_) || return undef;
  $pf->remap();
}

## $bool = $pf->truncate()
##  + truncates $pf->{fh} or $pf->{file}; otherwise a no-nop
sub truncate {
  my $pf = shift;
  $pf->SUPER::truncate(@_) || return undef;
  $pf->remap();
}

## $bool = $pf->flush()
##  + attempt to flush underlying filehandle, may not work
##  + INHERITED
sub flush {
  my $pf = shift;
  $pf->SUPER::flush(@_) or return undef;
  $pf->remap();
}

##==============================================================================
## API: filters
##  + INHERITED from PackedFile

##==============================================================================
## API: positioning

## $nrecords = $pf->size()
##  + returns number of records
sub size {
  return undef if (!$_[0]{bufr});
  return length(${$_[0]{bufr}})/$_[0]{reclen};
}

## $bool = $pf->seek($recno)
##  + seek to record-number $recno
sub seek {
  $_[0]{bufp} = $_[1];
  return 1;
}

## $recno = $pf->tell()
##  + report current record-number
sub tell {
  return $_[0]{bufp};
}

## $bool = $pf->reset();
##  + reset position to beginning of file
##  + INHERITED from PackedFile
sub reset {
  return $_[0]->seek(0);
}

## $bool = $pf->seekend()
##  + seek to end-of file
sub seekend {
  return $_[0]->seek($_[0]->size);
}

## $bool = $pf->eof()
##  + returns true iff current position is end-of-file
sub eof {
  return $_[0]{bufp} >= $_[0]->size;
}

##==============================================================================
## API: record access

##--------------------------------------------------------------
## API: record access: read

## $bool = $pf->read(\$buf)
##  + read a raw record into \$buf
sub read {
  ${$_[1]} = substr(${$_[0]{bufr}}, $_[0]{bufp}*$_[0]{reclen}, $_[0]{reclen});
  ++$_[0]{bufp};
  return length(${$_[1]})==$_[0]{reclen};
}

## $bool = $pf->readraw(\$buf, $nrecords)
##  + batch-reads $nrecords into \$buf
sub readraw {
  ${$_[1]} = substr(${$_[0]{bufr}}, $_[0]{bufp}*$_[0]{reclen}, $_[2]*$_[0]{reclen});
  $_[0]{bufp} += $_[2];
  return length(${$_[1]})==$_[2]*$_[0]{reclen};
}

## $value_or_undef = $pf->get()
##  + get (unpacked) value of current record, increments filehandle position to next record
sub get {
  local $_ = substr(${$_[0]{bufr}}, $_[0]{bufp}*$_[0]{reclen}, $_[0]{reclen});
  return undef if (length($_) != $_[0]{reclen});
  ++$_[0]{bufp};
  $_[0]{filter_fetch}->() if ($_[0]{filter_fetch});
  return $_;
}

## \$buf_or_undef = $pf->getraw(\$buf)
##  + get (packed) value of current record, increments filehandle position to next record
sub getraw {
  ${$_[1]} = substr(${$_[0]{bufr}}, $_[0]{bufp}*$_[0]{reclen}, $_[0]{reclen});
  ++$_[0]{bufp};
  return undef if (length(${$_[1]}) != $_[0]{reclen});
  return $_[1];
}

## $value_or_undef = $pf->fetch($index)
##  + get (unpacked) value of record $index
sub fetch {
  local $_ = substr(${$_[0]{bufr}}, $_[1]*$_[0]{reclen}, $_[0]{reclen});
  ++$_[0]{bufp};
  return undef if (length($_) != $_[0]{reclen});
  $_[0]{filter_fetch}->() if ($_[0]{filter_fetch});
  return $_;
}

## $buf_or_undef = $pf->fetchraw($index,\$buf)
##  + get (packed) value of record $index
sub fetchraw {
  ${$_[2]} = substr(${$_[0]{bufr}}, $_[1]*$_[0]{reclen}, $_[0]{reclen});
  ++$_[0]{bufp};
  return undef if (length(${$_[2]}) != $_[0]{reclen});
  return ${$_[2]};
}

##--------------------------------------------------------------
## API: record access: write

## $bool = $pf->write($buf)
##  + write a raw record $buf to current position; increments position
sub write {
  $_[0]->logconfess("write(): method not supported");
}

## $value_or_undef = $pf->set($value)
##  + set (packed) value of current record, increments filehandle position to next record
sub set {
  $_[0]->logconfess("set(): method not supported");
}

## $value_or_undef = $pf->store($index,$value)
##  + store (packed) $value as record-number $index
sub store {
  $_[0]->logconfess("store(): method not supported");
}

## $value_or_undef = $pf->push($value)
##  + store (packed) $value at end of record
sub push {
  $_[0]->logconfess("push(): method not supported");
}

##==============================================================================
## API: batch I/O

## \@data = $pf->toArray(%opts)
##   + read entire contents to an array
##   + %opts : override %$pf:
##      packas => $packas
sub toArray {
  my ($pf,%opts) = @_;
  $pf->setFilters($opts{packas}) if (exists($opts{packas}));
  my ($bufr,$filter_fetch,$reclen) = @$pf{qw(bufr filter_fetch reclen)};
  my @data = qw();
  local $_;
  my $off = 0;
  my $end = length($$bufr);
  for ($off=0; $off < $end; $off += $reclen) {
    $_ = substr($$bufr, $off, $reclen);
    $filter_fetch->() if ($filter_fetch);
    CORE::push(@data,$_);
  }
  $pf->setFilters();
  return \@data;
}

## $pf = $pf->fromArray(\@data,%opts)
##   + write file contents from an array
##   + %opts : override %$pf:
##      packas => $packas
sub fromArray {
  my ($pf,$data,%opts) = @_;
  $pf->setFilters($opts{packas}) if (exists($opts{packas}));
  local $_;
  $pf->setsize(scalar @$data)
    or $pf->logconfess("fromArray(): failed to set file size = ", scalar(@$data), ": $!");
  my ($bufr,$reclen,$filter_store) = @$pf{qw(bufr reclen filter_store)};
  my $i = 0;
  foreach (@$data) {
    $filter_store->() if ($filter_store);
    substr($bufr, $i*$reclen, $reclen) = $_;
    ++$i;
  }
  $pf->setFilters();
  return $pf;
}

## $pdl = $pf->toPdl(%options)
##  + returns a piddle for $pf
##  + %options:
##     type => $pdl_type,    ##-- pdl type (default:'auto':guess)
##     swap => $bool_or_sub, ##-- byte-swap? (default:'auto':guess)
##     mmap => $bool,        ##-- mmap data? (default: 0)
##     ...                   ##-- other options passed to DiaColloDB::Utils::readPdlFile()
##  + INHERITED from PackedFile

##==============================================================================
## API: binary search

## $nbits_or_undef = $pf->vnbits()
##  + returns number of bits for using vec()-style search via Algorithm::BinarySearch::Vec, or undef if not supported
##  + currently UNUSED
sub vnbits {
  my $pf     = shift;
  my $packas = $pf->{packas};
  my $reclen = $pf->{reclen};
  if ($reclen==1) {
    return 8;
  } elsif ($reclen==2) {
    return 16 if (unpack('n',pack($packas,0xfedc)) == 0xfedc);
  } elsif ($reclen==4) {
    return 32 if (unpack('N',pack($packas,0xfedca987)) == 0xfedca987);
  } elsif ($reclen==8) {
    return 64 if (unpack('Q>',pack($packas,0xfedca9876543210f)) == 0xfedca9876543210f);
  }
  return undef;
}

## $index_or_undef = $pf->bsearch($key, %opts)
##  + %opts:
##    lo => $ilo,        ##-- index lower-bound for search (default=0)
##    hi => $ihi,        ##-- index upper-bound for search (default=size)
##    packas => $packas, ##-- key-pack template (default=$pf->{packas})
##  + returns the minimum index $i such that unpack($packas,$pf->[$i]) == $key and $ilo <= $j < $i,
##    or undef if no such $i exists.
##  + $key must be a numeric value, and records must be stored in ascending order
##    by numeric value of key (as unpacked by $packas) between $ilo and $ihi
##  + TODO: optimize this to use Algorithm::BinarySearch::Vec (only applicable for scalar pack-templates)
sub bsearch {
  my ($pf,$key,%opts) = @_;
  my $ilo    = $opts{lo} // 0;
  my $ihi    = $opts{hi} // $pf->size;
  my $packas = $opts{packas} // $pf->{packas};
  my $reclen = $pf->{reclen};
  my $bufr   = $pf->{bufr};

  ##-- binary search guts
  my ($imid,$keymid);
  while ($ilo < $ihi) {
    $imid = ($ihi+$ilo) >> 1;

    ##-- get item[$imid]
    ($keymid) = unpack($packas, substr($$bufr, $imid*$reclen, $reclen));

    if ($keymid < $key) {
      $ilo = $imid + 1;
    } else {
      $ihi = $imid;
    }
  }

  if ($ilo==$ihi) {
    ##-- get item[$ilo]
    ($keymid) = unpack($packas, substr($$bufr, $ilo*$reclen, $reclen));
    return $ilo if ($keymid == $key);
  }

  return undef;
}

##==============================================================================
## disk usage, timestamp, etc
##  + see DiaColloDB::Persistent

## @files = $obj->diskFiles()
##  + returns disk storage files, used by du() and timestamp()
##  + default implementation returns $obj->{file} or glob("$obj->{base}*")
##  + INHERITED from PackedFile


##==============================================================================
## I/O
##  + largely INHERITED from DiaColloDB::Persistent, DiaColloDB::PackedFile

##--------------------------------------------------------------
## I/O: header
##  + largely INHERITED from DiaColloDB::Persistent

## @keys = $coldb->headerKeys()
##  + keys to save as header
sub headerKeys {
  my $pf = shift;
  return grep {!ref($_[0]{$_}) && $_ !~ m{^(?:bufp)$}} $pf->SUPER::headerKeys(@_);
}

##--------------------------------------------------------------
## I/O: text

## $bool = $obj->saveTextFile($filename_or_handle, %opts)
##  + wraps saveTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $bool = $pf->saveTextFh($fh, %opts)
##  + save from text file with lines of the form "KEY? VALUE(s)..."
##  + %opts:
##      keys=>$bool,    ##-- do/don't save keys (default=true)
##      key2s=>$key2s, ##-- code-ref for key formatting, called as $s=$key2s->($key)
sub saveTextFh {
  my ($pf,$outfh,%opts) = @_;
  $pf->logconfess("saveTextFh(): no packed-file opened!") if (!$pf->opened);

  my $key2s = $opts{key2s};
  my $keys  = $opts{keys} // 1;
  my $bufr  = $pf->{bufr};
  my $size  = $pf->size;
  my ($i,$key,$val);
  for ($i=0, $pf->reset; $i < $size; ++$i) {
    $val = $pf->get();
    $outfh->print(($keys
		   ? (($key2s ? $key2s->($i) : $i),"\t")
		   : qw()),
		  (UNIVERSAL::isa($val,'ARRAY') ? join(' ',@$val) : $val),
		  "\n");
  }

  return $pf;
}

## $bool = $obj->loadTextFile($filename_or_handle, %opts)
##  + wraps loadTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $bool = $pf->loadTextFh($fh, %opts)
##  + load from text file with lines of the form "KEY? VALUE(s)..."
##  + %opts:
##      keys=>$bool,     ##-- expect keys in input? (default=true)
##      gaps=>$bool,     ##-- expect gaps or out-of-order elements in input? (default=false; implies keys=>1)
##  + INHERITED from DiaColloDB::Persistent


##==============================================================================
## Footer
1;

__END__
