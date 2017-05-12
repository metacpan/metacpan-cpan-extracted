## -*- Mode: CPerl -*-
## File: DiaColloDB::PackedFile.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db: flat fixed-length record-oriented files

package DiaColloDB::PackedFile;
use DiaColloDB::Logger;
use DiaColloDB::Persistent;
use DiaColloDB::Utils qw(:fcntl :file :pack);
use Tie::Array;
use Fcntl;
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Persistent Tie::Array);

##==============================================================================
## Constructors etc.

## $pf = CLASS_OR_OBJECT->new(%opts)
## + %opts, %$pf:
##   ##-- user options
##   file     => $filename,   ##-- default: undef (none)
##   flags    => $flags,      ##-- fcntl flags or open-mode (default='r')
##   perms    => $perms,      ##-- creation permissions (default=(0666 &~umask))
##   reclen   => $reclen,     ##-- record-length in bytes: (default: guess from pack format if available)
##   packas   => $packas,     ##-- pack-format or array; see DiaColloDB::Utils::packFilterStore();
##   temp     => $bool,       ##-- if true, data file(s) will be unlinked on DESTROY
##   ##
##   ##-- filters
##   filter_fetch => $filter, ##-- DB_File-style filter for fetch
##   filter_store => $filter, ##-- DB_File-style filter for store
##   ##
##   ##-- low-level data
##   fh       => $fh,         ##-- underlying filehandle
sub new {
  my $that = shift;
  my $pf = bless({
		  file   => undef,
		  flags  => 'r',
		  perms  => (0666 & ~umask),
		  reclen => undef,
		  temp   => 0,
		  #packas => undef,

		  ##-- filters
		  #filter_fetch => undef,
		  #filter_store => undef,

		  ##-- low level data
		  #fh     => undef,

		  ##-- user args
		  @_
		 }, ref($that)||$that);
  $pf->{class} = ref($pf);
  return $pf->open() if (defined($pf->{file}));
  return $pf;
}

sub DESTROY {
  my $obj = $_[0];
  $obj->unlink() if ($obj->{temp});
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
  $pf->close() if ($pf->opened);
  @$pf{keys %opts} = values(%opts);
  $flags = $pf->{flags} = fcflags($flags // $pf->{flags});
  return undef if (!defined($pf->{file} = $file = ($file // $pf->{file})));
  return undef if (-f "$pf->{file}.hdr" && !$pf->loadHeader()); ##-- allow missing header files for old v0.01 PackedFile objects
  $pf->{fh} = fcopen($file, $flags, $pf->{perms})
    or return undef;
  binmode($pf->{fh},':raw');
  $pf->setFilters();
  return $pf;
}

## $bool = $pf->opened()
sub opened {
  return defined($_[0]{fh});
}

## $bool = $pf->reopen()
##  + re-opens datafile
sub reopen {
  my $pf   = shift;
  my $file = $pf->{file} || "$pf";
  return $pf->opened && fh_reopen($pf->{fh}, $file);
}

## $bool = $pf->close()
sub close {
  my $pf = shift;
  my $rc = (($pf->opened && fcwrite($pf->{flags}) ? $pf->flush : 1)
	    &&
	    (defined($pf->{fh}) ? CORE::close($pf->{fh}) : 1));
  delete $pf->{fh};
  $pf->{size} = 0;
  return $rc;
}

## $bool = $pf->setsize($nrecords)
sub setsize {
  if ($_[1] > $_[0]->size) {
    ##-- grow
    CORE::seek($_[0]{fh}, $_[1]*$_[0]{reclen}-1, SEEK_SET)
      or $_[0]->logconfess(__PACKAGE__, "::setsize() failed to grow file to $_[1] elements: $!");
    $_[0]{fh}->print("\0");
  }
  else {
    ##-- shrink
    CORE::truncate($_[0]{fh}, $_[1]*$_[0]{reclen})
      or $_[0]->logconfess(__PACKAGE__, "::setsize() failed to shrink file to $_[1] elements: $!");
  }
  return 1;
}

## $bool = $pf->truncate()
##  + truncates $pf->{fh} or $pf->{file}; otherwise a no-nop
sub truncate {
  my $pf = shift;
  if (defined($pf->{fh})) {
    return CORE::truncate($pf->{fh},0) ;
  }
  elsif (defined($pf->{file})) {
    my $fh = fcopen($pf->{file}, (O_WRONLY|O_CREAT|O_TRUNC)) or return undef;
    return CORE::close($fh);
  }
  return undef;
}

## $bool = $pf->flush()
##  + attempt to flush underlying filehandle, may not work
sub flush {
  my $pf = shift;
  return undef if (!$pf->opened || !fcwrite($pf->{flags}));
  $pf->saveHeader()
    or $pf->logconfess("flush(): failed to store header file ", $pf->headerFile, ": $!");

  ##-- BUGHUNT/Birmingham: strangeness: tied @$docoff buffers seem not to get flushed
  #return $pf->{fh}->flush() if (UNIVERSAL::can($pf->{fh},'flush'));
  #return binmode($pf->{fh},':raw'); ##-- see perlfaq5(1) re: flushing filehandles

  $pf->reopen() or return undef if ((caller(1))[3] !~ /::close$/);
  return $pf;
}

##==============================================================================
## API: filters

## $pf = $pf->setFilters($packfmt)
## $pf = $pf->setFilters([$packfmt, $unpackfmt])
## $pf = $pf->setFilters([\&packsub,\&unpacksub])
##  + %opts : override (but don't clobber) $pf->{packfmt}
sub setFilters {
  my ($pf,$packfmt) = @_;
  $packfmt //= $pf->{packas};
  $pf->{filter_fetch} = packFilterFetch($packfmt);
  $pf->{filter_store} = packFilterStore($packfmt);
  if (!defined($pf->{reclen}) && defined($pf->{filter_store})) {
    ##-- guess record length from pack filter output
    ##use bytes; ##-- deprecated in perl v5.18.2
    no warnings;
    local $_ = 0;
    $pf->{filter_store}->();
    utf8::encode($_) if (utf8::is_utf8($_));
    $pf->{reclen} = length($_);
  }
  return $pf;
}

##==============================================================================
## API: positioning

## $nrecords = $pf->size()
##  + returns number of records
##  + doesn't handle recent writes correctly (probably due to perl i/o buffering)
sub size {
  return undef if (!$_[0]{fh});
  return (-s $_[0]{fh}) / $_[0]{reclen};
}

## $bool = $pf->seek($recno)
##  + seek to record-number $recno
sub seek {
  CORE::seek($_[0]{fh}, $_[1]*$_[0]{reclen}, SEEK_SET);
}

## $recno = $pf->tell()
##  + report current record-number
sub tell {
  return CORE::tell($_[0]{fh}) / $_[0]{reclen};
}

## $bool = $pf->reset();
##   + reset position to beginning of file
sub reset {
  return $_[0]->seek(0);
}

## $bool = $pf->seekend()
##  + seek to end-of file
sub seekend {
  CORE::seek($_[0]{fh}, 0, SEEK_END);
}

## $bool = $pf->eof()
##  + returns true iff current position is end-of-file
sub eof {
  return CORE::eof($_[0]{fh});
}

##==============================================================================
## API: record access

##--------------------------------------------------------------
## API: record access: read

## $bool = $pf->read(\$buf)
##  + read a raw record into \$buf
sub read {
  return CORE::read($_[0]{fh}, ${$_[1]}, $_[0]{reclen})==$_[0]{reclen};
}

## $bool = $pf->readraw(\$buf, $nrecords)
##  + batch-reads $nrecords into \$buf
sub readraw {
  return CORE::read($_[0]{fh}, ${$_[1]}, $_[2]*$_[0]{reclen})==$_[2]*$_[0]{reclen};
}

## $value_or_undef = $pf->get()
##  + get (unpacked) value of current record, increments filehandle position to next record
sub get {
  local $_=undef;
  CORE::read($_[0]{fh}, $_, $_[0]{reclen})==$_[0]{reclen} or return undef;
  $_[0]{filter_fetch}->() if ($_[0]{filter_fetch});
  return $_;
}

## \$buf_or_undef = $pf->getraw(\$buf)
##  + get (packed) value of current record, increments filehandle position to next record
sub getraw {
  CORE::read($_[0]{fh}, ${$_[1]}, $_[0]{reclen})==$_[0]{reclen} or return undef;
  return $_[1];
}

## $value_or_undef = $pf->fetch($index)
##  + get (unpacked) value of record $index
sub fetch {
  local $_=undef;
  CORE::seek($_[0]{fh}, $_[1]*$_[0]{reclen}, SEEK_SET) or return undef;
  CORE::read($_[0]{fh}, $_, $_[0]{reclen})==$_[0]{reclen} or return undef;
  $_[0]{filter_fetch}->() if ($_[0]{filter_fetch});
  return $_;
}

## $buf_or_undef = $pf->fetchraw($index,\$buf)
##  + get (packed) value of record $index
sub fetchraw {
  CORE::seek($_[0]{fh}, $_[1]*$_[0]{reclen}, SEEK_SET) or return undef;
  CORE::read($_[0]{fh}, ${$_[2]}, $_[0]{reclen})==$_[0]{reclen} or return undef;
  return ${$_[2]};
}

##--------------------------------------------------------------
## API: record access: write

## $bool = $pf->write($buf)
##  + write a raw record $buf to current position; increments position
sub write {
  $_[0]{fh}->print($_[1]);
}

## $value_or_undef = $pf->set($value)
##  + set (packed) value of current record, increments filehandle position to next record
sub set {
  local $_=$_[1];
  $_[0]{filter_store}->() if ($_[0]{filter_store});
  $_[0]{fh}->print($_) or return undef;
  return $_[1];
}

## $value_or_undef = $pf->store($index,$value)
##  + store (packed) $value as record-number $index
sub store {
  CORE::seek($_[0]{fh}, $_[1]*$_[0]{reclen}, SEEK_SET) or return undef;
  local $_=$_[2];
  $_[0]{filter_store}->() if ($_[0]{filter_store});
  $_[0]{fh}->print($_) or return undef;
  return $_[2];
}

## $value_or_undef = $pf->push($value)
##  + store (packed) $value at end of record
sub push {
  CORE::seek($_[0]{fh}, 0, SEEK_END) or return undef;
  local $_ = $_[1];
  $_[0]{filter_store}->() if ($_[0]{filter_store});
  $_[0]{fh}->print($_) or return undef;
  return $_[1];
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
  my ($fh,$filter_fetch,$reclen) = @$pf{qw(fh filter_fetch reclen)};
  my @data = qw();
  local $_;
  $fh->seek(0,SEEK_SET);
  while (!CORE::eof($fh)) {
    CORE::read($fh, $_, $reclen)==$reclen
	or $pf->logconfess("toArray(): failed to read $reclen bytes for record number ", scalar(@data), ": $!");
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
  my ($fh,$filter_store) = @$pf{qw(fh filter_store)};
  local $_;
  $pf->setsize(scalar @$data)
    or $pf->logconfess("fromArray(): failed to set file size = ", scalar(@$data), ": $!");
  $fh->seek(0,SEEK_SET);
  my $i = 0;
  foreach (@$data) {
    $filter_store->() if ($filter_store);
    $fh->print($_)
      or $pf->logconfess("fromArray(): failed to write record number $i: $!");
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
sub toPdl {
  my ($pf,%opts) = @_;
  #require 'PDL.pm';
  #require 'PDL/IO/FastRaw.pm';

  ##-- type
  if (($opts{type}//'auto') eq 'auto') {
    $opts{type} = (map {$_->{ioname}}
		   grep {length(pack($PDL::Types::pack[$_->{numval}],0))==$pf->{reclen}}
		   @PDL::Types::typehash{@PDL::Types::names}
		  )[0];
  }
  $opts{type} = PDL->can($opts{type})->() if (PDL->can($opts{type}));
  $pf->logconfess("toPdl(): could not guess PDL type for pack template '$pf->{packas}'")
    if (!UNIVERSAL::isa($opts{type},'PDL::Type'));

  ##-- swap?
  my $packsize = $pf->{reclen};
  if (($opts{swap}//'auto') eq 'auto') {
    my $buf = pack("C*", (1..$packsize));
    my $val = unpack($pf->{packas}, $buf);
    my $pdl = PDL->zeroes($opts{type}, 1);
    ${$pdl->get_dataref} = $buf;
    $pdl->upd_data;
    if ($pdl->sclr == $val) {
      $opts{swap} = 0;
    }
    elsif (defined(my $swapsub = $pdl->can("bswap${packsize}"))) {
      $swapsub->($pdl);
      if ($pdl->sclr==$val) {
	$opts{swap} = $swapsub;
      }
    }
  }
  elsif ($opts{swap}) {
    $opts{swap} = PDL->can("bswap${packsize}");
  }
  $pf->logconfess("toPdl(): could not guess swap function for pack template '$pf->{packas}' and PDL type $opts{type}")
    if (($opts{swap}//'auto') eq 'auto');

  ##-- create header
  $pf->flush();
  my $hfile = "$pf->{file}.phdr";
  DiaColloDB::Utils::writePdlHeader($hfile, $opts{type}, 1, $pf->size)
      or $pf->logconfess("toPdl(): failed to write PDL::IO::FastRaw header $hfile: $!");

  ##-- read or mmap piddle file
  my %io = (Creat=>0,Header=>$hfile);
  my ($pdl);
  if ($opts{mmap}) {
    $pdl = PDL->mapfraw($pf->{file},{%io,ReadOnly=>($opts{ReadOnly}//1)});
  } else {
    $pdl = PDL->readfraw($pf->{file}, \%io);
  }
  defined($pdl) or $pf->logconfess("toPdl(): failed to ".($opts{mmap} ? "mmap" : "read")." file $pf->{file} as PDL data of type $opts{type}: $!");
  $opts{swap}->($pdl) if (UNIVERSAL::isa($opts{swap},'CODE'));
  !-e $hfile
    or CORE::unlink($hfile)
    or $pf->logconfess("toPdl(): failed to unlink temporary PDL header '$hfile': $!");
  return $pdl;
}

##==============================================================================
## API: binary search

## $index_or_undef = $pf->bsearch($key, %opts)
##  + %opts:
##    lo => $ilo,        ##-- index lower-bound for search (default=0)
##    hi => $ihi,        ##-- index upper-bound for search (default=size)
##    packas => $packas, ##-- key-pack template (default=$pf->{packas})
##  + returns the minimum index $i such that unpack($packas,$pf->[$i]) == $key and $ilo <= $j < $i,
##    or undef if no such $i exists.
##  + $key must be a numeric value, and records must be stored in ascending order
##    by numeric value of key (as unpacked by $packas) between $ilo and $ihi
sub bsearch {
  my ($pf,$key,%opts) = @_;
  my $ilo    = $opts{lo} // 0;
  my $ihi    = $opts{hi} // $pf->size;
  my $packas = $opts{packas} // $pf->{packas};

  ##-- binary search guts
  my ($imid,$buf,$keymid);
  while ($ilo < $ihi) {
    $imid = ($ihi+$ilo) >> 1;

    ##-- get item[$imid]
    $pf->fetchraw($imid,\$buf);
    ($keymid) = unpack($packas,$buf);

    if ($keymid < $key) {
      $ilo = $imid + 1;
    } else {
      $ihi = $imid;
    }
  }

  if ($ilo==$ihi) {
    ##-- get item[$ilo]
    $pf->fetchraw($ilo,\$buf);
    ($keymid) = unpack($packas,$buf);
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
sub diskFiles {
  my $obj = shift;
  return ($obj->{file}, $obj->{file}.".hdr") if (ref($obj) && defined($obj->{file}));
  return qw();
}


##==============================================================================
## I/O
##  + largely INHERITED from DiaColloDB::Persistent

##--------------------------------------------------------------
## I/O: header
##  + largely INHERITED from DiaColloDB::Persistent

## @keys = $coldb->headerKeys()
##  + keys to save as header
sub headerKeys {
  return grep {!ref($_[0]{$_}) && $_ !~ m{^(?:flags|perms|file|loaded|dirty)$}} keys %{$_[0]};
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
  my $fh   = $pf->{fh};
  my ($i,$key,$val);
  for ($i=0, $pf->reset(); !CORE::eof($fh); ++$i) {
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
sub loadTextFh {
  my ($pf,$infh,%opts) = @_;
  $pf->logconfess("loadTextFile(): no packed-file opened!") if (!$pf->opened);

  $pf->truncate();
  my $gaps = $opts{gaps} // 0;
  my $keys = $gaps || ($opts{keys} // 1);
  my $fh   = $pf->{fh};
  my ($key,$val);
  if ($gaps) {
    ##-- load with keys, possibly out-of-order
    while (defined($_=<$infh>)) {
      chomp;
      next if (/^$/ || /^%%/);
      ($key,$val) = split(' ',$_,2);
      $pf->store($key,$val);
    }
  }
  else {
    ##-- load in serial order, with or without keys (ignored)
    $pf->reset;
    while (defined($_=<$infh>)) {
      chomp;
      next if (/^$/ || /^%%/);
      ($key,$val) = ($keys ? split(' ',$_,2) : (undef,$_));
      $pf->set($val);
    }
  }
  $pf->flush();

  return $pf;
}

##==============================================================================
## API: tie interface

## $tied = tie(@array, $class, $file, $flags, %opts)
## $tied = TIEARRAY($class, $file, $flags, %opts)
sub TIEARRAY {
  my ($that,$file,$flags,%opts) = @_;
  $flags //= 'r';
  return $that->new(%opts,file=>$file,flags=>$flags);
}

BEGIN {
  *FETCH = \&fetch;
  *STORE = \&store;
  *STORESIZE = \&setsize;
  *EXTEND    = \&setsize;
  *CLEAR     = \&truncate;
}

## $count = $tied->FETCHSIZE()
##  + like scalar(@array)
##  + re-positions $tied->{fh} to eof
sub FETCHSIZE {
  return undef if (!$_[0]{fh});
  #return ((-s $_[0]{fh}) / $_[0]{reclen}); ##-- doesn't handle recent writes correctly (probably due to perl i/o buffering)
  ##
  CORE::seek($_[0]{fh},0,SEEK_END) or return undef;
  return CORE::tell($_[0]{fh}) / $_[0]{reclen};
}

## $bool = $tied->EXISTS($index)
sub EXISTS {
  return ($_[1] < $_[0]->size);
}

## undef = $tied->DELETE($index)
sub DELETE {
  $_[0]->STORE($_[1], pack("C$_[0]{reclen}"));
}


##==============================================================================
## Footer
1;

__END__
