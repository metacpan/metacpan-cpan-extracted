package Mail::Exchange::NamedProperties;

use strict;
use warnings;
use 5.008;

use Exporter;
use Encode;
use Mail::Exchange::PidTagDefs;
use Mail::Exchange::PidTagIDs;
use Mail::Exchange::PidLidDefs;
use Mail::Exchange::PropertyContainer;
use Mail::Exchange::CRC qw(crc);

use vars qw($VERSION @ISA @EXPORT);
@ISA=qw(Exporter);
@EXPORT=qw(GUIDEncode GUIDDecode);

$VERSION = "0.04";

sub new {
	my $class=shift;
	my $file=shift;

	my $self={};
	bless($self, $class);

	$self->{namedprops}=[];

	return $self;
}

sub OleContainer {
	my $self=shift;

	my @guidlist=("??", "PS_MAPI", "PS_PUBLIC_STRINGS");
	my $strstream="";
	my $entrystream="";
	my @nametoidstring;

	my $idx=0;
	foreach my $str (@{$self->{namedprops}}) {
		my $guididx=0;
		while ($guididx <= $#guidlist) {
			last if $guidlist[$guididx] eq $str->{guid};
			$guididx++;
		}
		if ($guididx==$#guidlist+1) {
			push(@guidlist, $str->{guid});
		}
		$str->{_guidindex}=$guididx;

		if ($str->{str} =~ /^\d/) {
			### this is a LID
			$entrystream.=pack("VV", $str->{str},
				$idx<<16 | $guididx<<1 | 0);

			my $nametoididx;
			$nametoididx=($str->{str}^($guididx << 1))%0x1f;

			$nametoidstring[$nametoididx].=pack("VV",
				$str->{str}, $idx<<16 | $guididx<<1 | 0);
		} else {
			### this is a string named property 

			$str->{_streampos}=length $strstream;
			my $ucs=Encode::encode("UCS2LE", $str->{str});
			$strstream.=pack("V", length($ucs)).$ucs;
			if (length($strstream)%4) {
				$strstream.="\0"x(4-length($strstream)%4);
			}
			$entrystream.=pack("VV", $str->{_streampos},
				$idx<<16 | $guididx<<1 | 1);

			my $crc;
			$crc=crc($ucs);

			my $nametoididx;
			$nametoididx=($crc ^ (($guididx << 1) | 1))%0x1f;

			$nametoidstring[$nametoididx].=pack("VV",
				$crc, $idx<<16 | $guididx<<1 | 1);
		}
		$idx++;
	}

	my $GUIDStream  =OLE::Storage_Lite::PPS::File->
		new(Encode::encode("UCS2LE", "__substg1.0_00020102"), $self->_packGUIDlist(@guidlist));
	my $EntryStream =OLE::Storage_Lite::PPS::File->
		new(Encode::encode("UCS2LE", "__substg1.0_00030102"), $entrystream);
	my $StringStream=OLE::Storage_Lite::PPS::File->
		new(Encode::encode("UCS2LE", "__substg1.0_00040102"), $strstream);

	my @streams=($GUIDStream, $EntryStream, $StringStream);
	for (my $i=0; $i<=0x1e; $i++) {
		if ($nametoidstring[$i]) {
			my $ntpstream=OLE::Storage_Lite::PPS::File->
				new(Encode::encode("UCS2LE", sprintf("__substg1.0_10%02X0102", $i)),
				$nametoidstring[$i]);
			push(@streams, $ntpstream);
		}
	}

	my $dirname=Encode::encode("UCS2LE", sprintf("__nameid_version1.0"));
	my @ltime=localtime();
	my $dir=OLE::Storage_Lite::PPS::Dir->new($dirname, \@ltime, \@ltime, \@streams );
	return $dir;
}


sub GUIDEncode {
	my $str=shift;

	return undef unless $str =~ /^([0-9a-f]{8})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{12})$/i;
	return pack("VvvnH12", hex($1), hex($2), hex($3), hex($4), $5);
}

sub GUIDDecode {
	my $guid=shift;

	my @f=unpack("VvvnH12", $guid);
	return sprintf("%08x-%04x-%04x-%04x-%12s", @f);
}

sub _packGUIDlist {
	my $self=shift;
	my @guidlist=@_;
	my $str="";

	foreach my $i (3..$#guidlist) {
		$str.=GUIDEncode($guidlist[$i]);
	}
	return $str;
}

=head2 namedPropertyIndex

=cut

# There are a few special cases to consider.
# - Standard call, when creating a message, is with property name,
#   property type, and guid. In this case, match it against
#   what we have and return an appropriate index, or create a new
#   entry if there's no match.
# - Also, when creating a message, the user may call us with a 
#   PidLid ID without name or type; in this case, try to find out
#   about those from the PidLidDefs hash.
# - When parsing a message, we'll be called first with name and guid,
#   but without a type, as type isn't present in __nameid. In this
#   case, create an entry with an undef type; the parser will set
#   the type later using setType.
# - Also, when parsing properties later, the parser will call us
#   with a property name  it knows to exist (because parsing __nameid
#   will have created it), but the parser doesn't know the GUID. So
#   if we're not given a guid (or type), and can't determine it from
#   the PidLid definitions, ignore it and just use the string to look
#   up the correct ID.

sub namedPropertyIndex {
	my $self=shift;

	my ($str, $type, $guid)=@_;
	if ($str=~/^\d/ && $str>=0x8000 && $PidLidDefs{$str}) {
		$type=$PidLidDefs{$str}{type} unless defined $type;
		$guid=$PidLidDefs{$str}{guid} unless defined $guid;
	}
	foreach my $i (0..$#{$self->{namedprops}}) {
		if ($self->{namedprops}[$i]{str} eq $str
		&&  (!$type || $self->{namedprops}[$i]{type} == $type)
		&&  (!$guid || $self->{namedprops}[$i]{guid} eq $guid)) {
			return 0x8000 | $i;
		}
	}
	die("named Property $str unknown, can't add without guid")
		unless ($guid);
	push(@{$self->{namedprops}}, {
		str => $str, guid => $guid, type => $type,
		_streampos => -1, _guidindex => -1, _crc => 0,
		_streamidx => 0,
	});
	return 0x8000 | $#{$self->{namedprops}};
}

sub LidForID {
	my $self=shift;
	my $id=shift;
	return $self->{namedprops}[$id&0x7fff]{str};
}

sub getType {
	my $self=shift;
	my $id=shift;

	return $self->{namedprops}[$id&0x7fff]{type};
}

sub setType {
	my $self=shift;
	my $id=shift;
	my $type=shift;

	$self->{namedprops}[$id&0x7fff]{type}=$type;
}

1;
