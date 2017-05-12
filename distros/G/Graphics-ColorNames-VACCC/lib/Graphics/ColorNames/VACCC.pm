package Graphics::ColorNames::VACCC;

=head1 NAME

Graphics::ColorNames::VACCC - VisiBone Anglo-Centric Color Codes for Graphics::ColorNames

=head1 SYNOPSIS

  require Graphics::ColorNames::VACCC;

  $NameTable = Graphics::ColorNames::VACCC->NamesRgbTable();
  $RgbColor  = $NameTable->{paledullred};

=head1 DESCRIPTION

This module defines color names and their associated RGB values for
the VisiBone Anglo-Centric Color Code.  This is intended for use with
the L<Graphics::ColorNames> package.

=head1 SEE ALSO

A description of this color scheme can be found at
L<http://www.visibone.com/vaccc/>.

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=head2 Acknowledgements

A while back I had received a request from somebody to implement this
as part of the L<Graphics::ColorNames> distribution.  The request
included source code for the module.  I had suggested to this person
that they upload a separate module to CPAN, but heard no reply.

Afterwards I had lost the original E-mail.

This version of the module was implemented separately.

=head1 LICENSE

Copyright (c) 2004 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

require 5.006;

use strict;
use warnings;

our $VERSION = '1.02';

my %RgbColors   = ( );

sub NamesRgbTable() {
  use integer;
  unless (keys %RgbColors) {
    while (my $line = <DATA>) {
      chomp($line);
      if ($line) {
	my $rgb   = eval "0x" . substr($line, 0, 6);
#	die, unless ($rgb =~ /^\d+$/);
	my $short = lc(substr($line, 8, 3)); $short =~ s/\s+$//;
	my $long  = lc(substr($line, 11));   $long  =~ s/^\s+//;
	$RgbColors{$short} = $rgb;
	$RgbColors{$long}  = $rgb;
	$long =~ s/\s+//g;
	$RgbColors{$long}  = $rgb;
	$long =~ s/\-//g;
	$RgbColors{$long}  = $rgb;
      }
    }
  }
  return \%RgbColors;
}

1;

__DATA__

FFFFFF 	W   	White
CCCCCC 	PG 	Pale Gray
999999 	LG 	Light Gray
666666 	DG 	Dark Gray
333333 	OG 	Obscure Gray
000000 	K 	Black
FF0000 	R 	Red
FF3333 	LHR 	Light Hard Red
CC0000 	DHR 	Dark Hard Red
FF6666 	LFR 	Light Faded Red
CC3333 	MFR 	Medium Faded Red
990000 	DFR 	Dark Faded Red
FF9999 	PDR 	Pale Dull Red
CC6666 	LDR 	Light Dull Red
993333 	DDR 	Dark Dull Red
660000 	ODR 	Obscure Dull Red
FFCCCC 	PWR 	Pale Weak Red
CC9999 	LWR 	Light Weak Red
996666 	MWR 	Medium Weak Red
663333 	DWR 	Dark Weak Red
330000 	OWR 	Obscure Weak Red
FF3300 	RRO 	Red-Red-Orange
FF6633 	LRO 	Light Red-Orange
CC3300 	DRO 	Dark Red-Orange
FF9966 	LOR 	Light Orange-Red
CC6633 	MOR 	Medium Orange-Red
993300 	DOR 	Dark Orange-Red
FF6600 	OOR 	Orange-Orange-Red
FF9933 	LHO 	Light Hard Orange
CC6600 	DHO 	Dark Hard Orange
FFCC99 	PDO 	Pale Dull Orange
CC9966 	LDO 	Light Dull Orange
996633 	DDO 	Dark Dull Orange
663300 	ODO 	Obscure Dull Orange
FF9900 	OOY 	Orange-Orange-Yellow
FFCC66 	LOY 	Light Orange-Yellow
CC9933 	MOY 	Medium Orange-Yellow
996600 	DOY 	Dark Orange-Yellow
CC9900 	DYO 	Dark Yellow-Orange
FFCC33 	LYO 	Light Yellow-Orange
FFCC00 	YYO 	Yellow-Yellow-Orange
FFFF00 	Y 	Yellow
FFFF33 	LHY 	Light Hard Yellow
CCCC00 	DHY 	Dark Hard Yellow
FFFF66 	LFY 	Light Faded Yellow
CCCC33 	MFY 	Medium Faded Yellow
999900 	DFY 	Dark Faded Yellow
FFFF99 	PDY 	Pale Dull Yellow
CCCC66 	LDY 	Light Dull Yellow
999933 	DDY 	Dark Dull Yellow
666600 	ODY 	Obscure Dull Yellow
FFFFCC 	PWY 	Pale Weak Yellow
CCCC99 	LWY 	Light Weak Yellow
999966 	MWY 	Medium Weak Yellow
666633 	DWY 	Dark Weak Yellow
333300 	OWY 	Obscure Weak Yellow
CCFF00 	YYS 	Yellow-Yellow-Spring
CCFF33 	LYS 	Light Yellow-Spring
99CC00 	DYS 	Dark Yellow-Spring
CCFF66 	LSY 	Light Spring-Yellow
99CC33 	MSY 	Medium Spring-Yellow
669900 	DSY 	Dark Spring-Yellow
99FF00 	SSY 	Spring-Spring-Yellow
99FF33 	LHS 	Light Hard Spring
66CC00 	DHS 	Dark Hard Spring
CCFF99 	PDS 	Pale Dull Spring
99CC66 	LDS 	Light Dull Spring
669933 	DDS 	Dark Dull Spring
336600 	ODS 	Obscure Dull Spring
66FF00 	SSG 	Spring-Spring-Green
99FF66 	LSG 	Light Spring-Green
66CC33 	MSG 	Medium Spring-Green
339900 	DSG 	Dark Spring-Green
66FF33 	LGS 	Light Green-Spring
33CC00 	DGS 	Dark Green-Spring
33FF00 	GGS 	Green-Green-Spring
00FF00 	G 	Green
33FF33 	LHG 	Light Hard Green
00CC00 	DHG 	Dark Hard Green
66FF66 	LFG 	Light Faded Green
33CC33 	MFG 	Medium Faded Green
009900 	DFG 	Dark Faded Green
99FF99 	PDG 	Pale Dull Green
66CC66 	LDG 	Light Dull Green
339933 	DDG 	Dark Dull Green
006600 	ODG 	Obscure Dull Green
CCFFCC 	PWG 	Pale Weak Green
99CC99 	LWG 	Light Weak Green
669966 	MWG 	Medium Weak Green
336633 	DWG 	Dark Weak Green
003300 	OWG 	Obscure Weak Green
00FF33 	GGT 	Green-Green-Teal
33FF66 	LGT 	Light Green-Teal
00CC33 	DGT 	Dark Green-Teal
66FF99 	LTG 	Light Teal-Green
33CC66 	MTG 	Medium Teal-Green
009933 	DTG 	Dark Teal-Green
00FF66 	TTG 	Teal-Teal-Green
33FF99 	LHT 	Light Hard Teal
00CC66 	DHT 	Dark Hard Teal
99FFCC 	PDT 	Pale Dull Teal
66CC99 	LDT 	Light Dull Teal
339966 	DDT 	Dark Dull Teal
006633 	ODT 	Obscure Dull Teal
00FF99 	TTC 	Teal-Teal-Cyan
66FFCC 	LTC 	Light Teal-Cyan
33CC99 	MTC 	Medium Teal-Cyan
009966 	DTC 	Dark Teal-Cyan
33FFCC 	LCT 	Light Cyan-Teal
00CC99 	DCT 	Dark Cyan-Teal
00FFCC 	CCT 	Cyan-Cyan-Teal
00FFFF 	C 	Cyan
33FFFF 	LHC 	Light Hard Cyan
00CCCC 	DHC 	Dark Hard Cyan
66FFFF 	LFC 	Light Faded Cyan
33CCCC 	MFC 	Medium Faded Cyan
009999 	DFC 	Dark Faded Cyan
99FFFF 	PDC 	Pale Dull Cyan
66CCCC 	LDC 	Light Dull Cyan
339999 	DDC 	Dark Dull Cyan
006666 	ODC 	Obscure Dull Cyan
CCFFFF 	PWC 	Pale Weak Cyan
99CCCC 	LWC 	Light Weak Cyan
669999 	MWC 	Medium Weak Cyan
336666 	DWC 	Dark Weak Cyan
003333 	OWC 	Obscure Weak Cyan
00CCFF 	CCA 	Cyan-Cyan-Azure
33CCFF 	LCA 	Light Cyan-Azure
0099CC 	DCA 	Dark Cyan-Azure
66CCFF 	LAC 	Light Azure-Cyan
3399CC 	MAC 	Medium Azure-Cyan
006699 	DAC 	Dark Azure-Cyan
0099FF 	AAC 	Azure-Azure-Cyan
3399FF 	LHA 	Light Hard Azure
0066CC 	DHA 	Dark Hard Azure
99CCFF 	PDA 	Pale Dull Azure
6699CC 	LDA 	Light Dull Azure
336699 	DDA 	Dark Dull Azure
003366 	ODA 	Obscure Dull Azure
0066FF 	AAB 	Azure-Azure-Blue
6699FF 	LAB 	Light Azure-Blue
3366CC 	MAB 	Medium Azure-Blue
003399 	DAB 	Dark Azure-Blue
3366FF 	LBA 	Light Blue-Azure
0033CC 	DBA 	Dark Blue-Azure
0033FF 	BBA 	Blue-Blue-Azure
0000FF 	B 	Blue
3333FF 	LHB 	Light Hard Blue
0000CC 	DHB 	Dark Hard Blue
6666FF 	LFB 	Light Faded Blue
3333CC 	MFB 	Medium Faded Blue
000099 	DFB 	Dark Faded Blue
9999FF 	PDB 	Pale Dull Blue
6666CC 	LDB 	Light Dull Blue
333399 	DDB 	Dark Dull Blue
000066 	ODB 	Obscure Dull Blue
CCCCFF 	PWB 	Pale Weak Blue
9999CC 	LWB 	Light Weak Blue
666699 	MWB 	Medium Weak Blue
333366 	DWB 	Dark Weak Blue
000033 	OWB 	Obscure Weak Blue
3300FF 	BBV 	Blue-Blue-Violet
6633FF 	LBV 	Light Blue-Violet
3300CC 	DBV 	Dark Blue-Violet
9966FF 	LVB 	Light Violet-Blue
6633CC 	MVB 	Medium Violet-Blue
330099 	DVB 	Dark Violet-Blue
6600FF 	VVB 	Violet-Violet-Blue
9933FF 	LHV 	Light Hard Violet
6600CC 	DHV 	Dark Hard Violet
CC99FF 	PDV 	Pale Dull Violet
9966CC 	LDV 	Light Dull Violet
663399 	DDV 	Dark Dull Violet
330066 	ODV 	Obscure Dull Violet
9900FF 	VVM 	Violet-Violet-Magenta
CC66FF 	LVM 	Light Violet-Magenta
9933CC 	MVM 	Medium Violet-Magenta
660099 	DVM 	Dark Violet-Magenta
CC33FF 	LMV 	Light Magenta-Violet
9900CC 	DMV 	Dark Magenta-Violet
CC00FF 	MMV 	Magenta-Magenta-Violet
FF00FF 	M 	Magenta
FF33FF 	LHM 	Light Hard Magenta
CC00CC 	DHM 	Dark Hard Magenta
FF66FF 	LFM 	Light Faded Magenta
CC33CC 	MFM 	Medium Faded Magenta
990099 	DFM 	Dark Faded Magenta
FF99FF 	PDM 	Pale Dull Magenta
CC66CC 	LDM 	Light Dull Magenta
993399 	DDM 	Dark Dull Magenta
660066 	ODM 	Obscure Dull Magenta
FFCCFF 	PWM 	Pale Weak Magenta
CC99CC 	LWM 	Light Weak Magenta
996699 	MWM 	Medium Weak Magenta
663366 	DWM 	Dark Weak Magenta
330033 	OWM 	Obscure Weak Magenta
FF00CC 	MMP 	Magenta-Magenta-Pink
FF33CC 	LMP 	Light Magenta-Pink
CC0099 	DMP 	Dark Magenta-Pink
FF66CC 	LPM 	Light Pink-Magenta
CC3399 	MPM 	Medium Pink-Magenta
990066 	DPM 	Dark Pink-Magenta
FF0099 	PPM 	Pink-Pink-Magenta
FF3399 	LHP 	Light Hard Pink
CC0066 	DHP 	Dark Hard Pink
FF99CC 	PDP 	Pale Dull Pink
CC6699 	LDP 	Light Dull Pink
993366 	DDP 	Dark Dull Pink
660033 	ODP 	Obscure Dull Pink
FF0066 	PPR 	Pink-Pink-Red
FF6699 	LPR 	Light Pink-Red
CC3366 	MPR 	Medium Pink-Red
990033 	DPR 	Dark Pink-Red
FF3366 	LRP 	Light Red-Pink
CC0033 	DRP 	Dark Red-Pink
FF0033 	RRP 	Red-Red-Pink

