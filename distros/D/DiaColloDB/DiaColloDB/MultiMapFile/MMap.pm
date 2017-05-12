## -*- Mode: CPerl -*-
## File: DiaColloDB::MultiMapFile::MMap.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, integer->integer* multimap file, using mmap

package DiaColloDB::MultiMapFile::MMap;
use DiaColloDB::MultiMapFile;
use DiaColloDB::Utils qw(:fcntl :file :json :pack);
use File::Map qw(map_handle);
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::MultiMapFile);

##==============================================================================
## Constructors etc.

## $mmf = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    ##-- MultiMapFile: basic options
##    base => $base,       ##-- database basename; use files "${base}.ma", "${base}.mb", "${base}.hdr"
##    perms => $perms,     ##-- default: 0666 & ~umask
##    flags => $flags,     ##-- default: 'r'
##    pack_i => $pack_i,   ##-- integer pack template (default='N')
##    size => $size,       ##-- number of mapped , like scalar(@data)
##    ##
##    ##-- MultiMapFile: in-memory construction
##    a2b => \@a2b,        ##-- maps source integers to (packed) target integer-sets: [$a] => pack("${pack_i}*", @bs)
##    ##
##    ##-- MultiMapFile: computed pack templates and lengths (after open())
##    pack_a => $pack_a,   ##-- "($pack_i)[2]"
##    pack_b => $pack_a,   ##-- "($pack_i)*"
##    len_i => $len_i,     ##-- bytes::length(pack($pack_i,0))
##    len_a => $len_a,     ##-- bytes::length(pack($pack_a,0))
##    ##
##    ##-- MultiMapFile: filehandles (after open())
##    afh => $afh,         ##-- $base.ma : [$a]      => pack(${pack_a}, $bidx_a, $blen_a) : $byte_offset_in_bfh = $len_i*$bidx_a
##    bfh => $bfh,         ##-- $base.mb : $bidx_a   :  pack(${pack_b}, @targets_for_a)   : $byte_length_in_bfh = $len_i*$blen_a
##    ##
##    ##-- MultiMapFile::MMap: buffers
##    abufr => \$abuf,     ##-- mmap $base.ma
##    bbufr => \$bbuf,     ##-- mmap $base.mb
##   )
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   #abufr=>undef,
			   #bbufr=>undef,
			   @_, ##-- user arguments
			  )
}

##==============================================================================
## I/O

##--------------------------------------------------------------
## I/O: open/close (file)

## $mmf_or_undef = $mmf->open($base,$flags)
## $mmf_or_undef = $mmf->open($base)
## $mmf_or_undef = $mmf->open()
sub open {
  my ($mmf,$base,$flags) = @_;
  $mmf->SUPER::open($base,$flags) or return undef;
  return $mmf if (!$mmf->isa(__PACKAGE__)); ##-- uh-oh: we were re-blessed out of __PACKAGE__
  return $mmf->remap();
}

## $mmf_or_undef = $mmf->remap()
##  + mmaps local buffers abufr,bbufr from afh,bfh
BEGIN {
  *mmap_open = \&remap;
}
sub remap {
  my $mmf = shift;

  ##-- mmap handles
  my $mapmode = fcperl($mmf->{flags});
  map_handle(my $abuf, $mmf->{afh}, $mapmode);
  map_handle(my $bbuf, $mmf->{bfh}, $mapmode);

  ##-- buffers
  $mmf->{abufr} = \$abuf;
  $mmf->{bbufr} = \$bbuf;

  return $mmf;
}

## $mmf_or_undef = $mmf->mmap_close()
##  + un-references local  buffers abufr,bbufr
BEGIN {
  *mmap_close = \&unmap;
}
sub unmap {
  my $mmf = shift;
  delete @$mmf{qw(abufr bbufr)};
  return $mmf;
}


## $mmf_or_undef = $mmf->close()
sub close {
  my $mmf = shift;
  return $mmf->unmap() && $mmf->SUPER::close();
}

## $bool = $mmf->opened()
sub opened {
  my $mmf = shift;
  return $mmf->SUPER::opened() && defined($mmf->{abufr}) && defined($mmf->{bbufr});
}

## $bool = $mmf->reopen()
##  + re-opens datafiles
##  + override also remaps buffers
sub reopen {
  my $mmf = shift;
  return $mmf->SUPER::reopen() && $mmf->remap();
}


## $bool = $mmf->dirty()
##  + returns true iff some in-memory structures haven't been flushed to disk
##  + INHERITED from MultiMapFile

## $bool = $mmf->flush()
##  + flush in-memory structures to disk
##  + clobbers any old disk-file contents with in-memory maps
##  + file must be opened in write-mode
##  + invalidates any old references to {a2b} (but doesn't empty them if you need to keep a reference)
##  + INHERITED from MultiMapFile

##--------------------------------------------------------------
## I/O: memory <-> file

## \@a2b = $mmf->toArray()
sub toArray {
  my $mmf = shift;
  return $mmf->{a2b} if (!$mmf->opened);

  #use bytes; ##-- deprecated in perl v5.18.2
  my ($abufr,$bbufr,$len_a,$pack_a,$len_i) = @$mmf{qw(abufr bbufr len_a pack_a len_i)};
  my @a2b    = qw();

  ##-- ye olde loope
  my ($aoff,$bidx,$blen);
  my $aend = length($$abufr);
  for ($aoff=0; $aoff < $aend; $aoff += $len_a) {
    ($bidx,$blen) = unpack($pack_a, substr($$abufr, $aoff, $len_a));
    push(@a2b, substr($$bbufr, $bidx*$len_i, $blen*$len_i));
  }

  push(@a2b, @{$mmf->{a2b}}[scalar(@a2b)..$#{$mmf->{a2b}}]) if ($mmf->dirty);
  return \@a2b;
}

## $mmf = $mmf->fromArray(\@a2b)
##  + clobbers $mmf contents, steals \@a2b
##  + INHERITED from MultiMapFile

## $bool = $mmf->load()
##  + loads files to memory; must be opened
##  + INHERITED from MultiMapFile

## $mmf = $mmf->save()
## $mmf = $mmf->save($base)
##  + saves multimap to $base; really just a wrapper for open() and flush()
##  + INHERITED from MultiMapFile

##--------------------------------------------------------------
## I/O: header
##  + see also DiaColloDB::Persistent

## @keys = $coldb->headerKeys()
##  + keys to save as header
##  + INHERITED from MultiMapFile

## $bool = $CLASS_OR_OBJECT->loadHeader()
##  + wraps $CLASS_OR_OBJECT->loadHeaderFile($CLASS_OR_OBJ->headerFile())
##  + INHERITED from DiaColloDB::Persistent

## $bool = $mmf->loadHeaderData($hdr)
##  + INHERITED from MultiMapFile

## $bool = $enum->saveHeader()
##  + inherited from DiaColloDB::Persistent

##--------------------------------------------------------------
## I/O: text

## $bool = $obj->loadTextFile($filename_or_handle, %opts)
##  + wraps loadTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $mmf = $CLASS_OR_OBJECT->loadTextFh($fh)
##  + loads from text file with lines of the form "A B1 B2..."
##  + clobbers multimap contents
##  + INHERITED from MultiMapFile

## $bool = $obj->saveTextFile($filename_or_handle, %opts)
##  + wraps saveTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $bool = $mmf->saveTextFh($filename_or_fh,%opts)
##  + save from text file with lines of the form "A B1 B2..."
##  + %opts:
##     a2s=>\&a2s  ##-- stringification code for A items, called as $s=$a2s->($bi)
##     b2s=>\&b2s  ##-- stringification code for B items, called as $s=$b2s->($bi)
##  + INHERITED from MultiMapFile

##==============================================================================
## Methods: population (in-memory only)

## $newsize = $mmf->addPairs($a,@bs)
## $newsize = $mmf->addPairs($a,\@bs)
##  + adds mappings $a=>$b foreach $b in @bs
##  + multimap must be loaded to memory
##  + INHERITED from MultiMapFile

##==============================================================================
## Methods: lookup

## $bs_packed = $mmf->fetchraw($a)
sub fetchraw {
  my ($mmf,$a) = @_;
  return '' if (!defined($a));
  my ($boff,$blen) = unpack($mmf->{pack_a}, substr(${$mmf->{abufr}}, $a*$mmf->{len_a}, $mmf->{len_a}));
  return substr(${$mmf->{bbufr}}, $boff*$mmf->{len_i}, $blen*$mmf->{len_i});
}

## \@bs_or_undef = $mmf->fetch($a)
##  + returns array \@bs of targets for $a, or undef if not found
##  + multimap must be opened
##  + INHERITED from MultiMapFile

##==============================================================================
## Footer
1;

__END__




