#!/usr/bin/perl
#
# Dump the contents of a .msg file. This program reads directly from the
# OLE container, without using any of the Mail::Exchange modules (except
# ID definitions etc.). It can be used to check the contents of an
# outlook-produced file (to check which properties Outlook uses to
# store various information), as well as to verify for validity 
# files produced by the Mail::Exchanges modules.

use strict;
use Encode;
use OLE::Storage_Lite;
use Mail::Exchange::PidTagDefs;
use Mail::Exchange::PidLidDefs;
use Mail::Exchange::PropertyTypes;
use Mail::Exchange::Time qw(mstime_to_unixtime);
use utf8;
binmode(STDOUT, ":utf8");

die "No file specified" if($#ARGV < 0);
my $OLEfile = OLE::Storage_Lite->new($ARGV[0]);
my $DirTree = $OLEfile->getPpsTree(1);
die( $ARGV[0]. " must be a OLE file") unless($DirTree);
my $fileindex = 0;
my %filetype = (1 => 'DIR', 2 => 'FILE', 5=>'ROOT');
my $stringstreamdata;
my @npropname;

my %pset = (
	"00020329-0000-0000-C000-000000000046" => "PS_PUBLIC_STRINGS",
	"00062008-0000-0000-C000-000000000046" => "PSETID_Common",
	"00062004-0000-0000-C000-000000000046" => "PSETID_Address",
	"00020386-0000-0000-C000-000000000046" => "PS_INTERNET_HEADERS",
	"00062002-0000-0000-C000-000000000046" => "PSETID_Appointment",
	"6ED8DA90-450B-101B-98DA-00AA003F1305" => "PSETID_Meeting",
	"0006200A-0000-0000-C000-000000000046" => "PSETID_Log",
	"41F28F13-83F4-4114-A584-EEDB5A6B0BFF" => "PSETID_Messaging",
	"0006200E-0000-0000-C000-000000000046" => "PSETID_Note",
	"00062041-0000-0000-C000-000000000046" => "PSETID_PostRss",
	"00062003-0000-0000-C000-000000000046" => "PSETID_Task",
	"4442858E-A9E3-4E80-B900-317A210CC15B" => "PSETID_UnifiedMessaging",
	"00020328-0000-0000-C000-000000000046" => "PS_MAPI",
	"71035549-0739-4DCB-9163-00F0580DBBDF" => "PSETID_AirSync",
	"00062040-0000-0000-C000-000000000046" => "PSETID_Sharing",
	"23239608-685D-4732-9C55-4C95CB4E8E33" => "PSETID_XmlExtractedEntities",

	"11000E07-B51B-40D6-AF21-CAA85EDAB1D0" => "PSETID_CalendarAssistant",
	"96357f7f-59e1-47d0-99a7-46515c183b54" => "PSETID_Attachment",
);

msgdump($DirTree, 0, \$fileindex, 1, undef);

sub msgdump {
	my($tree, $level, $fileindex, $dirIndex, $parent) = @_;
	my $raDate;
	my $display;
	my ($tag, $type);
	my @guid;

	my $filename = Encode::decode("UCS2LE", $tree->{Name});
	my $parentname = Encode::decode("UCS2LE", $parent->{Name}) if $parent;
	$display = sprintf("%s %3d '%s' (pps %x)", 
	' ' x ($level * 2), $dirIndex, $filename, $tree->{No});

	if ($tree->{Type}==2) {
		 if ($filename eq "__properties_version1.0") {
			my $headersize;
			if ($parentname eq "Root Entry") {
				printf("\t\theader\n");
				hexdump(substr($tree->{Data}, 0, 32));
				my (undef, undef, $nrid, $naid, $rc, $ac, undef, undef)=unpack("i8", $tree->{Data});
				printf("\t\t\tnext recipient id = $nrid\n");
				printf("\t\t\tnext attachment id = $naid\n");
				printf("\t\t\trecipient count = $rc\n");
				printf("\t\t\tattachment count = $ac\n");
				$headersize=8*4;
			} elsif (substr($parentname, 0, 8) eq "__recip_"
			||       substr($parentname, 0, 8) eq "__attach") {
				hexdump(substr($tree->{Data}, 0, 8));
				$headersize=2*4;
			} else {
				$headersize=6*4;		## embedded .... ???
			}
			my $data=substr($tree->{Data}, $headersize);
				printf("\t\tdata (%d items)\n", length($data)/16);
			my @decoded=();
			while ($data) {
				my ($tag, $flags, $value)=unpack("VVQ", $data);
				my $type = $tag&0xffff;
				my $ptag = ($tag>>16)&0xffff;

				my $flagstr="";
				if ($flags&1) { $flagstr.="m"; } else { $flagstr.="-"; }
				if ($flags&2) { $flagstr.="r"; } else { $flagstr.="-"; }
				if ($flags&4) { $flagstr.="w"; } else { $flagstr.="-"; }


				my $tagname;
				if ($ptag&0x8000) {
					$tagname=$npropname[$ptag&0x7fff];
				} else {
					$tagname=$PidTagDefs{$ptag}->{name} || sprintf("%04x", $ptag);
				}
				my $typename=$PropertyTypes{sprintf("0x%04X", $type)} || sprintf("%04X", $type);
				my $xstream=0;
				my $multi=0;

				if    (($type&0x0fff) == 0x0002)	{ $value&=0xffff; }			# Integer16
				elsif (($type&0x0fff) == 0x0003)	{ $value&=0xffffffff; }			# Integer32
				elsif (($type&0x0fff) == 0x0004)	{ $value&=0xffffffff; }			# Floating32
				elsif (($type&0x0fff) == 0x0005)	{ $value=unpack("d<", substr($data, 8))}# Floating64
				elsif (($type&0x0fff) == 0x0006)	{ ; }					# Currency
				elsif (($type&0x0fff) == 0x0007)	{ ; }					# FloatingTime
				elsif (($type&0x0fff) == 0x000A)	{ $value&=0xffffffff; }			# Errorcode
				elsif (($type&0x0fff) == 0x000B)	{ $value&=0xffffffff; }			# Boolean
				elsif (($type&0x0fff) == 0x000D)	{ $value&=0xffffffff; $xstream=1;}	# Object
				elsif (($type&0x0fff) == 0x0014)	{ ;}					# Integer64
				elsif (($type&0x0fff) == 0x001E)	{ $value&=0xffffffff; $xstream=1;}	# String8
				elsif (($type&0x0fff) == 0x001F)	{ $value&=0xffffffff; $xstream=1;}	# String
				elsif (($type&0x0fff) == 0x0040)	{ }					# Time
				elsif (($type&0x0fff) == 0x0048)	{ $value&=0xffffffff; $xstream=1;}	# Guid
				elsif (($type&0x0fff) == 0x00FB)	{ $value&=0xffffffff; }			# ServerID
				elsif (($type&0x0fff) == 0x00FD)	{ $value&=0xffffffff; }			# Restriction
				elsif (($type&0x0fff) == 0x00FE)	{ $value&=0xffffffff; }			# RuleAction
				elsif (($type&0x0fff) == 0x0102)	{ $value&=0xffffffff; $xstream=1; }	# Binary

				if (($type&0x1000) == 0x1000) {						# Multiple versions
					$multi=1;
				}

				my $hexvalue=substr($data, 0, 16);
				$hexvalue=~s/./sprintf("%02x ", ord($&))/ges;

				if ($xstream || $multi) {
					my $streamname=sprintf("__substg1.0_%08X", $tag);
					my $file=findfile($parent, Encode::encode("UCS2LE", $streamname));
					die "file $streamname not found" unless $file;

					my $tmp=$file->{Data};
					$tmp=~s/./sprintf("%02x ", ord($&))/ges;
					$hexvalue.=" --- $tmp";

					if    ($type == 0x1e)	{ $value = $file->{Data}; }
					elsif ($type == 0x1f)	{ $value = Encode::decode("UCS2LE", $file->{Data}); }
					elsif (!$multi)	 {
						$value = $hexvalue;
					} elsif ($multi) {
						$value="Multi";
						my $lsize=0;
						if ($type == 0x1102) { $lsize=8; }
						if ($type == 0x101e || $type == 0x101f) { $lsize=4; }
						if ($lsize) { # variable length
							for (my $i=0; $i<length($file->{Data}); $i+=$lsize) {
								my $length=unpack("V", substr($file->{Data}, $i));
								my $substreamname=$streamname.sprintf("-%08x", $i/$lsize);
								my $subfile=findfile($parent, Encode::encode("UCS2LE", $substreamname));
								die "file $substreamname not found" unless $subfile;
								my $tmp=$subfile->{Data};
								die "length doesn't match data" unless $length==length($tmp);
								if ($type==0x1102) {
									$tmp=~s/./sprintf("%02x ", ord($&))/ges;
								} elsif ($type==0x101f) {
									$tmp = Encode::decode("UCS2LE", $tmp);
									$tmp = substr($tmp, 0, -1);
								} elsif ($type==0x101e) {
									$tmp = substr($tmp, 0, -1);
								}
								$value.=":$tmp";
							}
						} else { # fixed length
							$value = $hexvalue;
						}
					}
					$value=~s/[\x00-\x1f]/sprintf("\\x%02x", ord($&))/ge;
				} else {
					if    ($type == 0x40)	{ $value = scalar localtime mstime_to_unixtime($value); }
				}


				# push(@decoded, sprintf("\t\t%-45s %04X/%04X  %s  %s", $tagname, $ptag, $type, $flagstr, $hexvalue));
				push(@decoded, sprintf("\t\t%-45s %04X/%04X  %s  %s", $tagname, $ptag, $type, $flagstr, $value));
				$data=substr($data, 16);
			}
			print join("\n", sort @decoded), "\n";
			# print join("\n", @decoded);

		}
	} elsif ($tree->{Type} == 1 && $filename eq "__nameid_version1.0") {
		print "NameID\n";
		foreach my $item (@{$tree->{Child}}) {
			my $name=Encode::decode("UCS2LE", $item->{Name});
			if ($name eq "__substg1.0_00040102") {
				$stringstreamdata=$item->{Data};
			}
		}
		foreach my $item (@{$tree->{Child}}) {
			my $name=Encode::decode("UCS2LE", $item->{Name});
			print "\t$name";
			if ($name eq "__substg1.0_00020102") {
				print ": GUID Stream\n";
				for (my $i=0; $i<length $item->{Data}; $i+=16) {
					my $guid=$guid[$i/16]=bintoguid(substr($item->{Data}, $i));
					print "$guid ";
					print "($pset{$guid})" if $pset{$guid};
					print "\n";
				}
				# hexdump($item->{Data});
			}
			if ($name eq "__substg1.0_00030102") {
				print ": Entry Stream\n";
				my $data=$item->{Data};
				while ($data ne "") {
					my ($niso, $iko)=unpack("II", $data);
					my $pi=($iko>>16)&0xffff;
					my $gi=($iko>>1)&0x7fff;
					my $pk=$iko&1;
					printf "%2x: niso=%08x iko=%08x guid index=%d", $pi, $niso, $iko, $gi;
					if ($gi==1) { print " (PS_MAPI)"; }
					if ($gi==2) { print " (PS_PUBLIC_STRINGS)"; }
					if ($gi>2)  { printf" (GUID Stream Entry %d)", $gi-3; }

					if ($pk==0) {
						$npropname[$pi]=$PidLidDefs{$niso}{name} || "PidLid-".sprintf("%04x", $niso);
						printf " LID=%08x", $niso;
						if ($niso<0x8000) {
							$npropname[$pi]="(low) ".$npropname[$pi];
						}
						if ($PidLidDefs{$niso}{guid} && $guid[$gi-3] ne $PidLidDefs{$niso}{guid}) {
							$npropname[$pi]="(wrong guid) ".$npropname[$pi];
						}
					}
					if ($pk==1) {
						printf " strpos=%d", $niso;
						my $len=unpack("I", substr($stringstreamdata, $niso, 4));
						$npropname[$pi]=Encode::decode("UCS2LE", substr($stringstreamdata, $niso+4, $len));
					}
					print " - $npropname[$pi]";
					$data=substr($data, 8);
					print "\n";
				}
			}
			if ($name eq "__substg1.0_00040102") {
				print ": String Stream, property names\n";
				hexdump($item->{Data});
			}
			if ($name =~ /__substg1.0_10..0102/) {
				print ": Property name to ID mapping Stream\n";
				my $data=$item->{Data};
				while ($data ne "") {
					my ($crc, $iko)=unpack("II", $data);
                                        my $pi=($iko>>16)&0xffff;
                                        my $gi=($iko>>1)&0x7fff;
                                        my $pk=$iko&1;
					printf "crc=%08x pi=%d gi=%04x pk=%d\n", $crc, $pi, $gi, $pk;
					$data=substr($data, 8);
				}
			}
		}
	} else {
		printf("%s (%d)\n", $filename, $tree->{Type});
	}

	my $dirIndex=1;
	foreach my $item (@{$tree->{Child}}) {
		msgdump($item, $level+1, $fileindex, $dirIndex, $tree);
		$dirIndex++;
	}
}

sub findfile {
	my $dir=shift;
	my $filename=shift;

	foreach my $item (@{$dir->{Child}}) {
		return $item if $item->{Name} eq $filename;
	}
	return undef;
}

sub hexdump {
	my $data=shift;
	my $i;
	while (length($data) > 0) {
		for ($i=0; $i<16 && $i<length($data); $i++) {
			printf("%02x ", ord(substr($data, $i, 1)));
		}
		while ($i<16) {
			print "   ";
			$i++;
		}
		for ($i=0; $i<16 && $i<length($data); $i++) {
			my $o=ord(substr($data, $i, 1));
			if ($o>=32 && $o<127) {
				print chr($o);
			} else {
				print ".";
			}
		}
		print "\n";
		$data=substr($data, 16);
	}
}

sub bintoguid {
        my $guid=shift;

	my @f=unpack("VvvnH12", $guid);
	return uc sprintf("%08x-%04x-%04x-%04x-%12s", @f);
}
