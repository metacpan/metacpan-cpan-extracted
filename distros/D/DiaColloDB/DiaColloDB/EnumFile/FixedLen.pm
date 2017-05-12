## -*- Mode: CPerl -*-
## File: DiaColloDB::EnumFile::FixedLen.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, symbol<->integer enum, fixed-length symbols

package DiaColloDB::EnumFile::FixedLen;
use DiaColloDB::EnumFile;
use DiaColloDB::Logger;
use DiaColloDB::Utils qw(:fcntl :file :json :regex :pack);
use Fcntl qw(:DEFAULT :seek);
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::EnumFile);

##==============================================================================
## Constructors etc.

## $enum = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    ##-- EnumFile: basic options
##    base => $base,       ##-- database basename; use files "${base}.fsx", "${base}.fix", "${base}.hdr"
##    perms => $perms,     ##-- default: 0666 & ~umask
##    flags => $flags,     ##-- default: 'r'
##    pack_i => $pack_i,   ##-- integer pack template (default='N')
##    #pack_o => $pack_o,   ##-- file offset pack template (default='N') ; OVERRIDE:unused
##    #pack_l => $pack_l,   ##-- string-length pack template (default='n'); OVERRIDE:unused
##    pack_s => $pack_s,   ##-- string pack template for text i/o; OVERRIDE:REQUIRED (default='Nn')
##    size => $size,       ##-- number of mapped symbols, like scalar(@i2s)
##    utf8 => $bool,       ##-- true iff strings are stored as utf8 (used by re2i()) OVERRIDE: unused
##    ##
##    ##-- EnumFile: in-memory construction
##    s2i => \%s2i,        ##-- maps symbols to integers
##    i2s => \@i2s,        ##-- maps integers to symbols
##    dirty => $bool,      ##-- true if in-memory structures are not in-sync with file data
##    loaded => $bool,     ##-- true if file data has been loaded to memory
##    shared => $bool,     ##-- true to avoid closing filehandles on close() or DESTROY() (default=false)
##    ##
##    ##-- EnumFile: pack lengths (after open())
##    len_i => $len_i,     ##-- packsize($pack_i)
##    #len_o => $len_o,     ##-- packsize($pack_o) ; OVERRIDE: unused
##    #len_l => $len_l,     ##-- packsize($pack_l) ; OVERRIDE: unused
##    len_s => $len_s,     ##-- packsize($pack_s); OVERRIDE: new
##    len_sx => $len_sx,   ##-- $len_s + $len_i ; OVERRIDE: new value
##    ##
##    ##-- EnumFile: filehandles (after open())
##    #sfh  => $sfh,        ##-- $base.es  : OVERRIDE: unused
##    ixfh => $ixfh,       ##-- $base.fix : [$i] => pack("${pack_s}",          $s_with_id_i) : OVERRIDE: new extension, new format
##    sxfh => $sxfh,       ##-- $base.fsx : [$j] => pack("${pack_s}${pack_i}", $s_with_sortorder_j_and_id_i, $i) : OVERRIDE: new extension, new format
##   )
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   utf8   => 0,
			   pack_s => 'Nn',
			   @_, ##-- user arguments
			  );
}

##==============================================================================
## I/O

##--------------------------------------------------------------
## I/O: open/close (file)

## $enum_or_undef = $enum->open($base,$flags)
## $enum_or_undef = $enum->open($base)
## $enum_or_undef = $enum->open()
##  + opens file(s), clears {loaded} flag
sub open {
  my ($enum,$base,$flags) = @_;
  $base  //= $enum->{base};
  $flags //= $enum->{flags};
  $enum->close() if ($enum->opened);
  $enum->{base}  = $base;
  $enum->{flags} = $flags = fcflags($flags);
  if (fcread($flags) && !fctrunc($flags)) {
    $enum->loadHeader()
      or $enum->logconess("failed to load header from '$enum->{base}.hdr': $!");
    return $enum->promote($enum->{hclass})->open($base,$flags)
      if ($enum->{hclass} && !$enum->isa($enum->{hclass}));  ##-- auto-promote based on header data
  }

  $enum->{sxfh} = fcopen("$base.fsx", $flags, $enum->{perms})
    or $enum->logconfess("open failed for $base.fsx: $!");
  $enum->{ixfh} = fcopen("$base.fix", $flags, $enum->{perms})
    or $enum->logconfess("open failed for $base.fix: $!");

  ##-- pack lengths
  $enum->{len_i}  = packsize($enum->{pack_i});
  $enum->{len_s}  = packsize($enum->{pack_s});
  $enum->{len_sx} = $enum->{len_s} + $enum->{len_i};

  ##-- flags
  $enum->{loaded} = 0;

  ##-- cleanup
  delete(@$enum{qw(pack_o len_o pack_l len_l sfh)});

  return $enum;
}

## $enum_or_undef = $enum->close()
##  + INHERITED

## $bool = $enum->opened()
sub opened {
  my $enum = shift;
  return
    (
     #defined($enum->{base}) &&
     #defined($enum->{sfh}) &&
     defined($enum->{ixfh})
     && defined($enum->{sxfh})
    );
}

## $bool = $enum->reopen()
##  + re-opens datafiles
sub reopen {
  my $enum = shift;
  my $base = $enum->{base} || "$enum";
  return (
	  $enum->opened
	  #&& fh_reopen($enum->{sfh}, "$base.fs")
	  && fh_reopen($enum->{ixfh}, "$base.fix")
	  && fh_reopen($enum->{sxfh}, "$base.fsx")
	 );
}

## $bool = $enum->dirty()
##  + returns true iff some in-memory structures haven't been flushed to disk
##  + INHERITED

## $bool = $enum->loaded()
##  + returns true iff in-memory structures have been populated from disk
##  + INHERITED

## $bool = $enum->flush()
## $bool = $enum->flush($force)
##  + flush in-memory structures to disk
##  + no-op unless $force or $enum->dirty() is true
##  + clobbers any old disk-file contents with in-memory maps
##  + enum must be opened in write-mode
##  + invalidates any old references to {s2i}, {i2s} (but doesn't empty them if you need to keep a reference)
##  + clears {dirty} flag
sub flush {
  my ($enum,$force) = @_;
  return undef if (!$enum->opened || !fcwrite($enum->{flags}));
  return $enum if (!$force && !$enum->dirty);

  ##-- save header
  $enum->saveHeader()
    or $enum->logconfess("flush(): failed to store header $enum->{base}.hdr: $!");

  my ($ixfh,$sxfh) = @$enum{qw(ixfh sxfh)};
  $ixfh->seek(0,SEEK_SET);
  $sxfh->seek(0,SEEK_SET);

  ##-- dump $base.fix
  my $i2s     = $enum->{i2s};
  my ($len_s,$pack_i,$pack_s) = @$enum{qw(len_s pack_i pack_s)};
  my $i       = 0;
  my $null    = "\0" x $len_s;
  foreach (@$i2s) {
    $_ //= $null;
    $ixfh->print($_)
      or $enum->logconfess("flush(): failed to write ix-record for id=$i to $enum->{base}.fix");
    ++$i;
  }
  CORE::truncate($ixfh, $ixfh->tell());

  ##-- dump $base.fsx
  foreach $i (sort {$i2s->[$a] cmp $i2s->[$b]} (0..$#$i2s)) {
    $sxfh->print($i2s->[$i], pack($pack_i, $i))
      or $enum->logconfess("flush(): failed to dump sx-record for id $i to $enum->{base}.fsx");
  }
  CORE::truncate($sxfh, $sxfh->tell());

  ##-- clear in-memory structures (but don't clobber existing references; used for xenum by DiaColloDB::create())
  $enum->{i2s} = [];
  $enum->{s2i} = {};
  $enum->{dirty} = 0;

  $enum->reopen() or return undef if ((caller(1))[3] !~ /::close$/);
  return $enum;
}


##--------------------------------------------------------------
## I/O: memory <-> file

## \@i2s = $enum->toArray()
sub toArray {
  my $enum = shift;
  return $enum->{i2s} if ($enum->loaded || !$enum->opened);

  #use bytes; ##-- deprecated in perl v5.18.2
  my $ixfh   = $enum->{ixfh};
  my $ixlen  = (-s $ixfh);
  my ($ixbuf,@i2s);
  CORE::seek($ixfh,0,SEEK_SET)
      or $enum->logconfess("toArray(): seek(0) failed on $enum->{base}.fix: $!");
  CORE::read($ixfh, $ixbuf, $ixlen)==$ixlen
      or $enum->logconfess("toArray(): read() failed for $ixlen bytes from $enum->{base}.fix: $!");
  @i2s = unpack("(A[$enum->{len_s}])*", $ixbuf);
  undef $ixbuf;
  push(@i2s, @{$enum->{i2s}}[scalar(@i2s)..$#{$enum->{i2s}}]) if ($enum->dirty);
  return \@i2s;
}

## $enum = $enum->fromArray(\@i2s)
##  + clobbers $enum contents, steals \@i2s
##  + INHERITED

## $enum = $enum->fromHash(\%s2i)
##  + clobbers $enum contents, steals \%s2i
##  + INERHITED

## $enum = $enum->fromEnum($enum2)
##  + clobbers $enum contents, does NOT steal $enum2->{i2s}
##  + INHERITED

## $bool = $enum->load()
##  + loads files to memory; must be opened
##  + INHERITED

## $enum = $enum->save()
## $enum = $enum->save($base)
##  + saves enum to $base; really just a wrapper for open() and flush()
##  + INHERITED

##--------------------------------------------------------------
## I/O: header

## @keys = $coldb->headerKeys()
##  + keys to save as header
sub headerKeys {
  my $enum = shift;
  return grep {!m{(?:(?:pack|len)_[lo])$}} $enum->SUPER::headerKeys();
}

## $bool = $enum->loadHeader()
##  + INHERITED

## $bool = $enum->saveHeader()
##  + INHERITED

##--------------------------------------------------------------
## I/O: text
##  + INHERITED

##==============================================================================
## Methods: population (in-memory only)
##  + INHERITED

##==============================================================================
## Methods: lookup

## $s_or_undef = $enum->i2s($i)
##   + in-memory cache overrides file contents
sub i2s {
  my ($enum,$i) = @_;
  return undef if ($i >= $enum->{size});

  my ($buf,$soff,$slen);
  return $buf if (defined($buf=$enum->{i2s}[$i]));

  CORE::seek($enum->{ixfh}, $i*$enum->{len_s}, SEEK_SET)
      or $enum->logconfess("i2s(): seek() failed on $enum->{base}.fix for i=$i");
  CORE::read($enum->{ixfh},$buf,$enum->{len_s})==$enum->{len_s}
      or $enum->logconfess("i2s(): read() failed on $enum->{base}.fix for i=$i");

  return $buf;
}

## $i_or_undef = $enum->s2i($s)
## $i_or_undef = $enum->s2i($s, $ilo,$ihi)
##   + binary search; in-memory cache overrides file contents
sub s2i {
  my ($enum,$key,$ilo,$ihi) = @_;

  my ($sxfh,$len_s,$len_sx) = @$enum{qw(sxfh len_s len_sx)};
  $ilo //= 0;
  $ihi //= $enum->{dirty} ? ((-s $sxfh)/$len_sx) : $enum->{size};

  my ($imid,$buf,$s,$si);
  return $buf if (defined($buf=$enum->{s2i}{$key}));

  while ($ilo < $ihi) {
    $imid = ($ihi+$ilo) >> 1;

    ##-- get sx-record @ $imid
    CORE::seek($sxfh, $imid*$len_sx, SEEK_SET)
	or $enum->logconfess("s2i(): seek() failed on $enum->{base}.fsx for item $imid");
    CORE::read($sxfh, $buf, $len_s)==$len_s
	or $enum->logconfess("s2i(): read() failed on $enum->{base}.fsx for item $imid");

    if ($buf lt $key) {
      $ilo = $imid + 1;
    } else {
      $ihi = $imid;
    }
  }

  ##-- output
  if ($ilo==$ihi) {
    ##-- get sx-record @ $ilo
    CORE::seek($sxfh, $ilo*$len_sx, SEEK_SET)
	or $enum->logconfess("s2i(): seek() failed on $enum->{base}.fsx for item $imid");
    CORE::read($sxfh, $buf, $len_sx)==$len_sx
	or $enum->logconfess("s2i(): read() failed on $enum->{base}.fsx for item $imid");
    ($s,$si) = unpack($enum->{pack_s}.$enum->{pack_i}, $buf);

    return $si if ($buf eq $key);
  }

  return undef;
}


## \@is = $enum->re2i($regex, $pack_s)
##  + gets indices for all (packed) strings matching $regex
##  + if $pack_s is specified, is will be used to unpack strings (default=$enum->{pack_s}), only the first unpacked element will be tested
sub re2i {
  #use bytes; ##-- deprecated in perl v5.18.2
  my ($enum,$re,$pack_s) = @_;
  $re = regex($re) if (!ref($re));

  $pack_s //= $enum->{pack_s};
  my $i2s   = $enum->{i2s};

  if ($enum->loaded || !$enum->opened) {
    ##-- easy answer: loaded
    if ($pack_s) {
      my ($s);
      return [grep {($s)=unpack($pack_s,$i2s->[$_]); $s =~ $re} [0..$#$i2s]];
    } else {
      return [grep {$i2s->[$_] =~ $re} [0..$#$i2s]];
    }
  }

  ##-- iteration a la toArray
  my $ixfh   = $enum->{ixfh};
  my $len_s  = $enum->{len_s};
  my @is     = qw();
  my ($i,$buf);
  for ($i=0,CORE::seek($ixfh,0,SEEK_SET); !eof($ixfh); ++$i) {
    CORE::read($ixfh, $buf, $len_s)==$len_s
	or $enum->logconfess("re2i(): read() failed for $len_s bytes from $enum->{base}.fix: $!");
    ($buf) = unpack($pack_s, $buf) if ($pack_s);
    push(@is, $i) if ($buf =~ $re);
  }

  ##-- append expansions from in-memory cache
  if ($enum->dirty) {
    if ($pack_s) {
      my ($s);
      push(@is, grep {($s)=unpack($pack_s,$i2s->[$_]); $s =~ $re} (((-s $ixfh)/$len_s)..$#$i2s));
    } else {
      push(@is, grep {$i2s->[$_] =~ $re} (((-s $ixfh)/$len_s)..$#$i2s));
    }
  }

  return \@is;
}



##==============================================================================
## Footer
1;

__END__




