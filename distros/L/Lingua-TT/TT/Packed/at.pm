## -*- Mode: CPerl -*-
## File: Lingua::TT::Packed::zt.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT I/O: packed docs: human-readable ascii decimal with tt-style eos newlines

package Lingua::TT::Packed::at;
use Lingua::TT::Packed::a;
use strict;

##==============================================================================
## Globals & Constants

#our @ISA = qw(Lingua::TT::Document);
our @ISA = qw(Lingua::TT::Packed::a);

##==============================================================================
## Constructors etc.

## $pk = CLASS_OR_OBJECT->new(%opts)
## + %$pk, %opts:
##    ##-- overrides
##    packfmt => $packfmt,   ##-- packing format (default='w') : IGNORED
##    delim => $delimter,    ##-- record delimiter; default="\n" (newline)
##    ##
##    ##-- inherited
##    data => $packed_data,  ##-- pack("$PACKFMT*",@ids)
##    enum => $enum,         ##-- for mapping text <-> id
##    packfmt => $packfmt,   ##-- packing format (default='N') : IGNORED
##    fast => $bool,         ##-- encode/decode in memory-intensive "fast" mode, without error checks
##    badid => $id,          ##-- optional id to use for missing symbols (default=undef ~ 0)
##    badsym => $sym,        ##-- optional symbol to use for missing ids (default=undef ~ '')
##    delim => $delimter,    ##-- record delimiter; default="\n" (newline)
sub new {
  my ($that,%opts) = @_;
  $opts{delim}   = "\n" if (!$opts{delim});
  $opts{packfmt} = 'A*';
  my $pz = $that->SUPER::new(%opts);
  $pz->{delim} = "\n" if (!defined($pz->{delim}) || $pz->{delim} eq '');
  return $pz;
}

##==============================================================================
## Methods: Access

## \@ids = $pk->ids()
## \@ids = $pk->ids(\@ids)
##  + gets/sets packed data ids
##  + @ids may contain empty strings
##  + INHERITED version ought to work


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
  my $delim   = $pk->{delim} || "\n";

  if ($pk->{fast}) {
    ##-- "fast" mode
    $$datar .= $_.$delim foreach (map {defined($_) ? $_ : ''} @$sym2id{map {chomp; $_} <$infh>});
  } else {
    ##-- "paranoid" mode
    my ($id,$badid);
    while (defined($_=<$infh>)) {
      chomp;
      #next if ((/^\s*%%/ && !$want_cmts) || ($_ eq '' && !$want_eos));
      if ($_ eq '') {
	$$datar .= $delim;
	next;
      }
      if (!defined($id = $sym2id->{$_})) {
	if (defined($badid)) {
	  ##-- clobber
	  warn(ref($pk)."::packIO(): WARNING: no id for input '$_'; using -badid=$badid");
	  $id=$badid;
	} else {
	  $id = $enum->getId($_);
	}
      }
      $$datar .= $id.$delim;
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
  my $delim   = $pk->{delim} || "\n";
  my $delim_re = qr/\Q$delim\E/;

  if ($pk->{fast}) {
    ##-- unpack: fast mode
    $outfh->print(map { ($_ ne '' ? $id2sym->[$_] : '')."\n" } split($delim_re,$$datar));
  }
  else {
    ##-- unpack: "paranoid" mode
    my ($sym);
    $outfh->print(
		  map {
		    if (!defined($sym = $_ ne '' ? $id2sym->[$_] : '')) {
		      if (defined($badsym)) {
			##-- clobber
			warn(ref($pk)."::unpackIO(): WARNING: no symbol for id '$_'; using -badsym='$badsym'");
			$sym = $badsym;
		      } else {
			$sym = $enum->getSymbol($_);
		      }
		    }
		    $sym."\n"
		  } split($delim_re,$$datar)
		 );
  }
  if ($$datar =~ /${delim_re}{2,}$/) {
    ##-- insert trailing eos (if any), since split() trims empty trailing fields
    $outfh->print("\n" x ($+[0] - $-[0] - 1));
  }

  return $pk;
}


##==============================================================================
## Footer
1;

__END__
