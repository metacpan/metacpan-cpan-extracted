package Mail::Exchange::PropertyContainer;

use strict;
use warnings;
use 5.008;

use Exporter;
use Encode;
use Mail::Exchange::PidTagIDs;
use Mail::Exchange::PidTagDefs;
use OLE::Storage_Lite;

use vars qw($VERSION @ISA);
@ISA=qw(Exporter);

$VERSION = "0.04";

sub new {
	my $class=shift;
	my $file=shift;

	my $self={};
	bless($self, $class);

	$self->{_properties}={};
	$self;
}

# set a property. Property can be a Pid, a Lid, or a string. It should NOT
# be an index in a named property list.

sub set {
	my $self=shift;
	my $property=shift;
	my $value=shift;
	my $flags=shift;
	my $type=shift;
	my $guid=shift;
	my $namedproperties = shift;

	my $normalized=$self->_propertyid($property, $type, $guid, $namedproperties);
	$self->{_properties}{$normalized}{val} = $value;
	$self->{_properties}{$normalized}{flg} = $flags;
	1;
}

sub get {
	my $self=shift;
	my $property=shift;
	my $namedproperties = shift;

	my $normalized=$self->_propertyid($property, undef, undef, $namedproperties);
	if (wantarray) {
		return ($self->{_properties}{$normalized}{val}, $self->{_properties}{$normalized}{flg});
	} else {
		return $self->{_properties}{$normalized}{val};
	}
}

sub _OlePropertyStreamlist {
	my $self=shift;
	my $unicode=shift;
	my $header=shift;

        my @streams=();
        my $propertystr=$header;

        foreach my $property(sort {$a <=> $b } keys %{$self->{_properties}}) {
		my $type;
                if ($property & 0x8000) {
                        $type=$self->{_namedProperties}->getType($property);
                } else {
                        $type=$PidTagDefs{$property}{type};
                }
                die "no type for $property" unless $type;
                # my $data=$self->get($property);
		my $data=$self->{_properties}{$property}{val};
		my $flags=$self->{_properties}{$property}{flg} || 6;

                if ($type==0x000d || $type==0x001e || $type==0x001f
                ||  $type==0x0048 || $type==0x0102) {
			# At this point, data is in utf-8, so we need to
			# turn it into whatever the message wants it to be.
			my $length;
                        if (($type == 0x001E || $type == 0x001F) && $unicode) {
                                $data=Encode::encode("UCS2LE", $data);
				$type=0x001F;
				$length=(length($data)+2);
                        } elsif (($type == 0x001E || $type == 0x001F) && !$unicode) {
                                $data=Encode::encode("latin-1", $data);
				$type=0x001E;
				$length=(length($data)+1);
                        } else {
				$length=(length($data));
			}
                        my $streamname=sprintf("__substg1.0_%04X%04X", $property, $type);
                        my $stream=OLE::Storage_Lite::PPS::File->
                                new(Encode::encode("UCS2LE", $streamname), $data);
                        push(@streams, $stream);
                        $data=$length;
                }
		eval {
			$propertystr.=pack("VVQ", ($property<<16|$type),
				$flags, $data);
		};
		if ($@) {
			$propertystr.=pack("VVVV", ($property<<16|$type),
				$flags, $data&0xffffffff, $data/4294967296.0);
		}
        }
        my $stream=OLE::Storage_Lite::PPS::File->
                new(Encode::encode("UCS2LE", "__properties_version1.0"), $propertystr);
        push(@streams, $stream);

	return @streams;
}


# returns the internal hash index id of a property,
# which is the upper 2 bytes of the official ID, without the
# lower 2 bytes that encode the type. This function can
# be given a Pid, in which case it returns the Pid itself,
# or a LID or Name, in which case it returns 0x8000 plus
# the index of this property in the property stream.

sub _propertyid {
	my $self=shift;
	my $property=shift;
	my $type=shift;
	my $guid=shift;
	my $namedProperties=shift;

	if ($property =~ /^[0-9]/) {
		if ($property & 0xffff0000) {
			$type=$property&0xffff;
			$property>>=16;
		}
		if (defined($type) && $type==0x1e) {
			# Map String8 to UCS-String, we'll care
			# about (non)-Unicode when writing stuff out.
			$type=0x1f;
		}
		if ($property & 0x8000) {
			# map PidLids to indexes
			$property=$namedProperties->namedPropertyIndex(
				$property, $type, $guid);
		} else {
			# This is for when we're parsing and encounter
			# an unknown property type. Remember it so
			# we can use it / write it out later.
			if (!$PidTagDefs{$property} && $type) {
				$PidTagDefs{$property}{type}=$type;
			}
		}
		return $property;
	} elsif ($namedProperties) {
		# @@@ map guid name to guid ID ?
		my $id=$namedProperties->namedPropertyIndex($property, $type, $guid);
		return $id;
	}
	die ("can't make sense of $property");
}

sub _parseProperties {
	my $self=shift;
	my $file=shift;
	my $dir=shift;
	my $headersize=shift;
	my $namedProperties=shift;

	my $data=substr($file->{Data}, $headersize);	# ignore header
	while ($data) {
		my ($tag, $flags, $value, $v1, $v2);
		eval {
			($tag, $flags, $value)=unpack("VVQ", $data);
			$v1=$value&0xffffffff;
		};
		if ($@) {
			($tag, $flags, $v1, $v2)=unpack("VVVV", $data);
			$value=$v2*4294967296+$v1;
		}
		my $type = $tag&0xffff;
		my $ptag = ($tag>>16)&0xffff;

		# If it's a named property, we will have created it when
		# parsing __nameid, but we don't know the type yet, so
		# we have to set it here.
		if ($ptag & 0x8000) {
			$namedProperties->setType($ptag, $type);
		}
		if ($type & 0x1000) {
			die("Multiple properties not implemented");
		}
		if ($type==0x0002) { $value=$v1&0xffff; }
		if ($type==0x0003 || $type==0x0004 || $type==0x000a || $type==0x000b
		||  $type==0x000d || $type==0x001e || $type==0x001f || $type==0x0048
		||  $type==0x00FB || $type==0x00FD || $type==0x00FE || $type==0x0102) {
			$value=$v1;
		}
		if ($type==0x000d || $type==0x001E || $type==0x001F
		||  $type==0x0048 || $type==0x0102) {
			my $streamname=Encode::encode("UCS2LE",
				sprintf("__substg1.0_%08X", $tag));
			my $found=0;
			foreach $file (@{$dir->{Child}}) {
				if ($file->{Name} eq $streamname) {
					$found=1;
					$value=$file->{Data};
					if ($type == 0x1f) {
						$value=Encode::decode("UCS2LE", $value);
					}
					last;
				}
			}
			die "stream for $tag not found" unless $found;
		}
		if ($ptag & 0x8000) {
			$ptag=$namedProperties->LidForID($ptag);
		}
		$self->set($ptag, $value, $flags, $type);
		$data=substr($data, 16);
	}
}
