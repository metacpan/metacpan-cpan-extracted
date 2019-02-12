## -*- Mode: CPerl -*-
## File: Lingua::TT::Packed.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT I/O: packed docs

package Lingua::TT::Packed;
use Lingua::TT::Document;
use Lingua::TT::Persistent;
use Lingua::TT::Enum;
use Lingua::TT::IO;
use Encode qw(encode decode);
use strict;

##==============================================================================
## Globals & Constants

#our @ISA = qw(Lingua::TT::Document);
our @ISA = qw(Lingua::TT::Persistent);

##==============================================================================
## Constructors etc.

## $pk = CLASS_OR_OBJECT->new(%opts)
## + %$pk, %opts:
##    data => $packed_data,  ##-- pack("$PACKFMT*",@ids)
##    enum => $enum,         ##-- for mapping text <-> id
##    packfmt => $packfmt,   ##-- packing format (default='N')
##    fast => $bool,         ##-- encode/decode in memory-intensive "fast" mode, without error checks
##    badid => $id,          ##-- optional id to use for missing symbols (default=undef ~ 0)
##    badsym => $sym,        ##-- optional symbol to use for missing ids (default=undef ~ '')
##    delim => $delimter,    ##-- record delimiter; default='' (none)
sub new {
  my ($that,%opts) = @_;
  if ($opts{packfmt} && $opts{packfmt} eq 'z') {
    require Lingua::TT::Packed::z;
    return Lingua::TT::Packed::z->new(%opts);
  }
  elsif ($opts{packfmt} && $opts{packfmt} eq 'zt') {
    require Lingua::TT::Packed::zt;
    return Lingua::TT::Packed::zt->new(%opts);
  }
  elsif ($opts{packfmt} && $opts{packfmt} eq 'a') {
    require Lingua::TT::Packed::a;
    return Lingua::TT::Packed::a->new(%opts);
  }
  elsif ($opts{packfmt} && $opts{packfmt} eq 'at') {
    require Lingua::TT::Packed::at;
    return Lingua::TT::Packed::at->new(%opts);
  }
  elsif ($opts{packfmt} && $opts{packfmt} eq 'x') {
    require Lingua::TT::Packed::x;
    return Lingua::TT::Packed::x->new(%opts);
  }
  return bless({
		data    => '',
		enum    => Lingua::TT::Enum->new,
		packfmt => 'N',
		fast    => 0,
		badid   => undef,
		badsym  => undef,
		delim   => '',
		%opts,
	       }, ref($that)||$that);
}

## $pk = $pk->clear()
##  + clears data and enum
sub clear {
  my $pk = shift;
  $pk->{enum}->clear;
  $pk->{data} = '';
  return $pk;
}

## $pk = $pk->clearData()
sub clearData {
  $_[0]{data} = '';
  return $_[0];
}

##==============================================================================
## Methods: Access

## \@ids = $pk->ids()
## \@ids = $pk->ids(\@ids)
##  + gets/sets packed data ids
sub ids {
  my ($pk,$ids) = @_;
  my $delim = $pk->{delim} || '';
  if ($ids) {
    if ($delim) {
      ##-- set, +delim
      $pk->{data}  = '';
      $pk->{data} .= pack($pk->{packfmt},$_).$delim foreach (@$ids);
    } else {
      ##-- set, -delim
      $pk->{data} = pack("$pk->{packfmt}*",@$ids);
    }
  }
  else {
    if ($delim) {
      ##-- get, +delim
      my $packfmt  = $pk->{packfmt};
      my $delim_re = qr/\Q$pk->{delim}\E/;
      $ids = [map {unpack($packfmt,$_)} split($delim_re,$pk->{data})];
    } else {
      ##-- get, -delim
      $ids = [unpack("$pk->{packfmt}*",$pk->{data})];
    }
  }
  return $ids;
}


##==============================================================================
## Methods: I/O

##--------------------------------------------------------------
## Methods: I/O: Native (bin)

## $pk = $CLASS_OR_OBJECT->saveNativeFh($fh,%opts)
##  + saves $pk to filehandle
##  + does NOT save enum
BEGIN { *toFh = \&saveNativeFh; }
sub saveNativeFh {
  my ($pk,$fh,%opts) = @_;
  CORE::binmode($fh,':bytes:raw');
  $fh->print($pk->{data});
  return $pk;
}

## $pk = $CLASS_OR_OBJECT->loadNativeFh($fh,%opts)
##  + saves $pk to filehandle
##  + does NOT save enum
BEGIN { *fromFh = \&loadNativeFh; }
sub loadNativeFh {
  my ($pk,$fh,%opts) = @_;
  $pk = $pk->new if (!ref($pk));
  CORE::binmode($fh,':bytes:raw');
  local $/=undef;
  $pk->{data} .= <$fh>;
  return $pk;
}

##--------------------------------------------------------------
## Methods: I/O: TT: pack (i.e. load)

## $pk = $tt->packFile($ttfile,%opts)
##  + append data from $ttfile
sub packFile {
  my ($pk,$file,%opts) = @_;
  return $pk->packIO(Lingua::TT::IO->fromFile($file,%opts),%opts);
}

## $pk = $tt->packFh($ttfh,%opts)
##  + append data from $ttfh
sub packFh {
  my ($pk,$fh,%opts) = @_;
  return $pk->packIO(Lingua::TT::IO->fromFh($fh,%opts),%opts);
}

## $pk = $tt->packString(\$ttstr,%opts)
##  + append data from $ttstr
sub packString {
  my ($pk,$strref,%opts) = @_;
  return $pk->packIO(Lingua::TT::IO->fromString($strref,%opts),%opts);
}

## $pk = $tt->packIO($ttio,%opts)
##  + append data from $ttio
##  + %opts overrides %$pk
sub packIO {
  my ($pk,$ttio,%opts) = @_;
  @$pk{keys %opts} = values(%opts);
  my $infh = $ttio->{fh};
  my $enum   = $pk->{enum};
  my $sym2id = $pk->{enum}{sym2id};
  my $datar  = \$pk->{data};
  my $packfmt = $pk->{packfmt};
  my $badid   = $pk->{badid};
  my $delim   = $pk->{delim};
  $delim = '' if (!defined($delim));

  if ($pk->{fast}) {
    ##-- "fast" mode
    if ($delim eq '') {
      $$datar .= pack("${packfmt}*", @$sym2id{map {chomp; $_} <$infh>});
    } else {
      $$datar .= pack("${packfmt}",$_).$delim foreach (@$sym2id{map {chomp; $_} <$infh>});
    }
  } else {
    ##-- "paranoid" mode
    my ($id,$badid);
    while (defined($_=<$infh>)) {
      chomp;
      #next if ((/^\s*%%/ && !$want_cmts) || ($_ eq '' && !$want_eos));
      if (!defined($id = $sym2id->{$_})) {
	if (defined($badid)) {
	  ##-- clobber
	  warn(ref($pk)."::packIO(): WARNING: no id for input '$_'; using -badid=$badid");
	  $id=$badid;
	} else {
	  $id = $enum->getId($_);
	}
      }
      $$datar .= pack($packfmt,$id).$delim;
    }
  }
  return $pk;
}

##--------------------------------------------------------------
## Methods: I/O: TT: unpack (i.e. save)

## $pk = $tt->unpackFile($ttfile,%opts)
##  + unpack data to $ttfile
sub unpackFile {
  my ($pk,$file,%opts) = @_;
  return $pk->unpackIO(Lingua::TT::IO->toFile($file,%opts),%opts);
}

## $pk = $tt->unpackFh($ttfh,%opts)
##  + unpack data to $ttfh
sub unpackFh {
  my ($pk,$fh,%opts) = @_;
  return $pk->unpackIO(Lingua::TT::IO->toFh($fh,%opts),%opts);
}

## $pk = $tt->unpackString(\$ttstr,%opts)
##  + unpack data to $ttstr
sub unpackString {
  my ($pk,$strref,%opts) = @_;
  return $pk->unpackIO(Lingua::TT::IO->toString($strref,%opts),%opts);
}

## $pk = $tt->unpackIO($ttio,%opts)
##  + unpack data to $ttio
##  + %opts overrides %$pk
sub unpackIO {
  my ($pk,$ttio,%opts) = @_;
  @$pk{keys %opts} = values(%opts);
  my $outfh  = $ttio->{fh};
  my $enum   = $pk->{enum};
  my $id2sym = $pk->{enum}{id2sym};
  my $datar  = \$pk->{data};
  my $badsym = $pk->{badsym};
  my $packfmt = $pk->{packfmt};
  my $delim_re = defined($pk->{delim}) && $pk->{delim} ne '' ? qr/\Q$pk->{delim}\E/ : undef;

  if ($pk->{fast}) {
    ##-- unpack: fast mode
    if ($delim_re) {
      ##-- +fast,+delim
      $outfh->print(map {$_."\n"} @$id2sym[map {unpack($packfmt,$_)} split($delim_re,$$datar)]);
    } else {
      ##-- +fast,-delim
      $outfh->print(map {$_."\n"} @$id2sym[unpack("${packfmt}*",$$datar)]);
    }
  }
  else {
    ##-- unpack: "paranoid" mode
    my ($sym);
    $outfh->print(
		  map {
		    if (!defined($sym=$id2sym->[$_])) {
		      if (defined($badsym)) {
			##-- clobber
			warn(ref($pk)."::unpackIO(): WARNING: no symbol for id '$_'; using -badsym='$badsym'");
			$sym = $badsym;
		      } else {
			$sym = $enum->getSymbol($_);
		      }
		    }
		    $sym."\n"
		  } ($delim_re
		     ? map {unpack($packfmt,$_)} split($delim_re,$$datar) ##-- -fast,+delim
		     : unpack("$packfmt*", $$datar)                       ##-- -fast,-delim
		    )
		 );
  }

  return $pk;
}


##==============================================================================
## Footer
1;

__END__
