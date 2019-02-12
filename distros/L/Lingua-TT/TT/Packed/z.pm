## -*- Mode: CPerl -*-
## File: Lingua::TT::Packed::z.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT I/O: packed docs: using (our own) Encode::Base128

package Lingua::TT::Packed::z;
use Lingua::TT::Packed;
use Encode::Base128 qw(:all);
use strict;

##==============================================================================
## Globals & Constants

#our @ISA = qw(Lingua::TT::Document);
our @ISA = qw(Lingua::TT::Packed);

##==============================================================================
## Constructors etc.

## $pk = CLASS_OR_OBJECT->new(%opts)
## + %$pk, %opts:
##    data => $packed_data,  ##-- pack("$PACKFMT*",@ids)
##    enum => $enum,         ##-- for mapping text <-> id
##    packfmt => $packfmt,   ##-- packing format (default='N') : IGNORED
##    fast => $bool,         ##-- encode/decode in memory-intensive "fast" mode, without error checks
##    badid => $id,          ##-- optional id to use for missing symbols (default=undef ~ 0)
##    badsym => $sym,        ##-- optional symbol to use for missing ids (default=undef ~ '')
##    delim => $delimter,    ##-- record delimiter; default="\0" (NUL byte)
sub new {
  my ($that,%opts) = @_;
  $opts{delim}   = "\0" if (!$opts{delim});
  $opts{packfmt} = 'w';
  my $pz = $that->SUPER::new(%opts);
  $pz->{delim} = "\n" if (!defined($pz->{delim}) || $pz->{delim} eq '');
  return $pz;
}

##==============================================================================
## Methods: Access

## \@ids = $pk->ids()
## \@ids = $pk->ids(\@ids)
##  + gets/sets packed data ids
sub ids {
  my ($pk,$ids) = @_;
  my $delim = $pk->{delim} || "\0";
  if ($ids) {
    ##-- set, +delim
    $pk->{data}  = '';
    $pk->{data} .= b128_encode($_).$delim foreach (@$ids);
  }
  else {
    my $delim_re = qr/\Q$delim\E/;
    $ids = [map {b128_decode($_)} split($delim_re,$pk->{data})];
  }
  return $ids;
}


##==============================================================================
## Methods: I/O

##--------------------------------------------------------------
## Methods: I/O: Native (bin)
## + INHERITED

##--------------------------------------------------------------
## Methods: I/O: TT: pack (i.e. load)

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
  my $delim   = $pk->{delim} || "\0";

  if ($pk->{fast}) {
    ##-- "fast" mode
    $$datar .= b128_encode($_).$delim foreach (@$sym2id{map {chomp; $_} <$infh>});
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
      $$datar .= b128_encode($id).$delim;
    }
  }
  return $pk;
}

##--------------------------------------------------------------
## Methods: I/O: TT: unpack (i.e. save)

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
  my $delim   = $pk->{delim} || "\0";
  my $delim_re = qr/\Q$delim\E/;

  if ($pk->{fast}) {
    ##-- unpack: fast mode
    $outfh->print(map {$_."\n"} @$id2sym[map {b128_decode($_)} split($delim_re,$$datar)]);
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
		  } map {b128_decode($_)} split($delim_re,$$datar) ##-- -fast,+delim
		 );
  }

  return $pk;
}


##==============================================================================
## Footer
1;

__END__
