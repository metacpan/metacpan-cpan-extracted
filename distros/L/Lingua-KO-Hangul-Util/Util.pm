package Lingua::KO::Hangul::Util;

use 5.006001;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.27';
our $PACKAGE = __PACKAGE__;

our @EXPORT = qw(
    decomposeHangul
    composeHangul
    getHangulName
    parseHangulName
    getHangulComposite
);
our @EXPORT_OK = qw(
    decomposeSyllable
    composeSyllable
    decomposeJamo
    composeJamo
    decomposeFull
    getSyllableType
    isStandardForm
    insertFiller
);
our %EXPORT_TAGS = (
    'all' => [ @EXPORT, @EXPORT_OK ],
);

##### The above part is common to XS and PP #####

our @ISA = qw(Exporter);
use Carp;

#####

my @JamoL = ( # Initial (HANGUL CHOSEONG)
    "G", "GG", "N", "D", "DD", "R", "M", "B", "BB",
    "S", "SS", "", "J", "JJ", "C", "K", "T", "P", "H",
  );

my @JamoV = ( # Medial  (HANGUL JUNGSEONG)
    "A", "AE", "YA", "YAE", "EO", "E", "YEO", "YE", "O",
    "WA", "WAE", "OE", "YO", "U", "WEO", "WE", "WI",
    "YU", "EU", "YI", "I",
  );

my @JamoT = ( # Final    (HANGUL JONGSEONG)
    "", "G", "GG", "GS", "N", "NJ", "NH", "D", "L", "LG", "LM",
    "LB", "LS", "LT", "LP", "LH", "M", "B", "BS",
    "S", "SS", "NG", "J", "C", "K", "T", "P", "H",
  );

my $BlockName = "HANGUL SYLLABLE ";

#####

use constant SBase  => 0xAC00;
use constant SFinal => 0xD7A3; # SBase -1 + SCount
use constant SCount =>  11172; # LCount * NCount
use constant NCount =>    588; # VCount * TCount
use constant LBase  => 0x1100;
use constant LFinal => 0x1112;
use constant LCount =>     19; # scalar @JamoL
use constant VBase  => 0x1161;
use constant VFinal => 0x1175;
use constant VCount =>     21; # scalar @JamoV
use constant TBase  => 0x11A7;
use constant TFinal => 0x11C2;
use constant TCount =>     28; # scalar @JamoT
use constant JBase  => 0x1100;
use constant JFinal => 0x11FF;
use constant JCount =>    256;

use constant JamoLIni   => 0x1100;
use constant JamoLFin   => 0x1159;
use constant JamoLFill  => 0x115F;
use constant JamoVIni   => 0x1160;
use constant JamoVFin   => 0x11A2;
use constant JamoTIni   => 0x11A8;
use constant JamoTFin   => 0x11F9;

my(%CodeL, %CodeV, %CodeT);
@CodeL{@JamoL} = 0 .. LCount-1;
@CodeV{@JamoV} = 0 .. VCount-1;
@CodeT{@JamoT} = 0 .. TCount-1;

my $IsJ = sub { JBase <= $_[0] && $_[0] <= JFinal };
my $IsS = sub { SBase <= $_[0] && $_[0] <= SFinal };
my $IsL = sub { LBase <= $_[0] && $_[0] <= LFinal };
my $IsV = sub { VBase <= $_[0] && $_[0] <= VFinal };
my $IsT = sub { TBase  < $_[0] && $_[0] <= TFinal };
	      # TBase <= $_[0] is false!
my $IsLV = sub {
    SBase <= $_[0] && $_[0] <= SFinal && (($_[0] - SBase ) % TCount) == 0;
};

#####

# separator is a semicolon, ';'.
my %Map12;   # ("integer;integer" => integer)
my %Map123;  # ("integer;integer;integer" => integer)

my %Decomp = (
0x1101 => [0x1100, 0x1100],
0x1104 => [0x1103, 0x1103],
0x1108 => [0x1107, 0x1107],
0x110A => [0x1109, 0x1109],
0x110D => [0x110C, 0x110C],
0x1113 => [0x1102, 0x1100],
0x1114 => [0x1102, 0x1102],
0x1115 => [0x1102, 0x1103],
0x1116 => [0x1102, 0x1107],
0x1117 => [0x1103, 0x1100],
0x1118 => [0x1105, 0x1102],
0x1119 => [0x1105, 0x1105],
0x111A => [0x1105, 0x1112],
0x111B => [0x1105, 0x110B],
0x111C => [0x1106, 0x1107],
0x111D => [0x1106, 0x110B],
0x111E => [0x1107, 0x1100],
0x111F => [0x1107, 0x1102],
0x1120 => [0x1107, 0x1103],
0x1121 => [0x1107, 0x1109],
0x1122 => [0x1107, 0x1109, 0x1100],
0x1123 => [0x1107, 0x1109, 0x1103],
0x1124 => [0x1107, 0x1109, 0x1107],
0x1125 => [0x1107, 0x1109, 0x1109],
0x1126 => [0x1107, 0x1109, 0x110C],
0x1127 => [0x1107, 0x110C],
0x1128 => [0x1107, 0x110E],
0x1129 => [0x1107, 0x1110],
0x112A => [0x1107, 0x1111],
0x112B => [0x1107, 0x110B],
0x112C => [0x1107, 0x1107, 0x110B],
0x112D => [0x1109, 0x1100],
0x112E => [0x1109, 0x1102],
0x112F => [0x1109, 0x1103],
0x1130 => [0x1109, 0x1105],
0x1131 => [0x1109, 0x1106],
0x1132 => [0x1109, 0x1107],
0x1133 => [0x1109, 0x1107, 0x1100],
0x1134 => [0x1109, 0x1109, 0x1109],
0x1135 => [0x1109, 0x110B],
0x1136 => [0x1109, 0x110C],
0x1137 => [0x1109, 0x110E],
0x1138 => [0x1109, 0x110F],
0x1139 => [0x1109, 0x1110],
0x113A => [0x1109, 0x1111],
0x113B => [0x1109, 0x1112],
0x113D => [0x113C, 0x113C],
0x113F => [0x113E, 0x113E],
0x1141 => [0x110B, 0x1100],
0x1142 => [0x110B, 0x1103],
0x1143 => [0x110B, 0x1106],
0x1144 => [0x110B, 0x1107],
0x1145 => [0x110B, 0x1109],
0x1146 => [0x110B, 0x1140],
0x1147 => [0x110B, 0x110B],
0x1148 => [0x110B, 0x110C],
0x1149 => [0x110B, 0x110E],
0x114A => [0x110B, 0x1110],
0x114B => [0x110B, 0x1111],
0x114D => [0x110C, 0x110B],
0x114F => [0x114E, 0x114E],
0x1151 => [0x1150, 0x1150],
0x1152 => [0x110E, 0x110F],
0x1153 => [0x110E, 0x1112],
0x1156 => [0x1111, 0x1107],
0x1157 => [0x1111, 0x110B],
0x1158 => [0x1112, 0x1112],
0x1162 => [0x1161, 0x1175],
0x1164 => [0x1163, 0x1175],
0x1166 => [0x1165, 0x1175],
0x1168 => [0x1167, 0x1175],
0x116A => [0x1169, 0x1161],
0x116B => [0x1169, 0x1161, 0x1175],
0x116C => [0x1169, 0x1175],
0x116F => [0x116E, 0x1165],
0x1170 => [0x116E, 0x1165, 0x1175],
0x1171 => [0x116E, 0x1175],
0x1174 => [0x1173, 0x1175],
0x1176 => [0x1161, 0x1169],
0x1177 => [0x1161, 0x116E],
0x1178 => [0x1163, 0x1169],
0x1179 => [0x1163, 0x116D],
0x117A => [0x1165, 0x1169],
0x117B => [0x1165, 0x116E],
0x117C => [0x1165, 0x1173],
0x117D => [0x1167, 0x1169],
0x117E => [0x1167, 0x116E],
0x117F => [0x1169, 0x1165],
0x1180 => [0x1169, 0x1165, 0x1175],
0x1181 => [0x1169, 0x1167, 0x1175],
0x1182 => [0x1169, 0x1169],
0x1183 => [0x1169, 0x116E],
0x1184 => [0x116D, 0x1163],
0x1185 => [0x116D, 0x1163, 0x1175],
0x1186 => [0x116D, 0x1167],
0x1187 => [0x116D, 0x1169],
0x1188 => [0x116D, 0x1175],
0x1189 => [0x116E, 0x1161],
0x118A => [0x116E, 0x1161, 0x1175],
0x118B => [0x116E, 0x1165, 0x1173],
0x118C => [0x116E, 0x1167, 0x1175],
0x118D => [0x116E, 0x116E],
0x118E => [0x1172, 0x1161],
0x118F => [0x1172, 0x1165],
0x1190 => [0x1172, 0x1165, 0x1175],
0x1191 => [0x1172, 0x1167],
0x1192 => [0x1172, 0x1167, 0x1175],
0x1193 => [0x1172, 0x116E],
0x1194 => [0x1172, 0x1175],
0x1195 => [0x1173, 0x116E],
0x1196 => [0x1173, 0x1173],
0x1197 => [0x1173, 0x1175, 0x116E],
0x1198 => [0x1175, 0x1161],
0x1199 => [0x1175, 0x1163],
0x119A => [0x1175, 0x1169],
0x119B => [0x1175, 0x116E],
0x119C => [0x1175, 0x1173],
0x119D => [0x1175, 0x119E],
0x119F => [0x119E, 0x1165],
0x11A0 => [0x119E, 0x116E],
0x11A1 => [0x119E, 0x1175],
0x11A2 => [0x119E, 0x119E],
0x11A9 => [0x11A8, 0x11A8],
0x11AA => [0x11A8, 0x11BA],
0x11AC => [0x11AB, 0x11BD],
0x11AD => [0x11AB, 0x11C2],
0x11B0 => [0x11AF, 0x11A8],
0x11B1 => [0x11AF, 0x11B7],
0x11B2 => [0x11AF, 0x11B8],
0x11B3 => [0x11AF, 0x11BA],
0x11B4 => [0x11AF, 0x11C0],
0x11B5 => [0x11AF, 0x11C1],
0x11B6 => [0x11AF, 0x11C2],
0x11B9 => [0x11B8, 0x11BA],
0x11BB => [0x11BA, 0x11BA],
0x11C3 => [0x11A8, 0x11AF],
0x11C4 => [0x11A8, 0x11BA, 0x11A8],
0x11C5 => [0x11AB, 0x11A8],
0x11C6 => [0x11AB, 0x11AE],
0x11C7 => [0x11AB, 0x11BA],
0x11C8 => [0x11AB, 0x11EB],
0x11C9 => [0x11AB, 0x11C0],
0x11CA => [0x11AE, 0x11A8],
0x11CB => [0x11AE, 0x11AF],
0x11CC => [0x11AF, 0x11A8, 0x11BA],
0x11CD => [0x11AF, 0x11AB],
0x11CE => [0x11AF, 0x11AE],
0x11CF => [0x11AF, 0x11AE, 0x11C2],
0x11D0 => [0x11AF, 0x11AF],
0x11D1 => [0x11AF, 0x11B7, 0x11A8],
0x11D2 => [0x11AF, 0x11B7, 0x11BA],
0x11D3 => [0x11AF, 0x11B8, 0x11BA],
0x11D4 => [0x11AF, 0x11B8, 0x11C2],
0x11D5 => [0x11AF, 0x11B8, 0x11BC],
0x11D6 => [0x11AF, 0x11BA, 0x11BA],
0x11D7 => [0x11AF, 0x11EB],
0x11D8 => [0x11AF, 0x11BF],
0x11D9 => [0x11AF, 0x11F9],
0x11DA => [0x11B7, 0x11A8],
0x11DB => [0x11B7, 0x11AF],
0x11DC => [0x11B7, 0x11B8],
0x11DD => [0x11B7, 0x11BA],
0x11DE => [0x11B7, 0x11BA, 0x11BA],
0x11DF => [0x11B7, 0x11EB],
0x11E0 => [0x11B7, 0x11BE],
0x11E1 => [0x11B7, 0x11C2],
0x11E2 => [0x11B7, 0x11BC],
0x11E3 => [0x11B8, 0x11AF],
0x11E4 => [0x11B8, 0x11C1],
0x11E5 => [0x11B8, 0x11C2],
0x11E6 => [0x11B8, 0x11BC],
0x11E7 => [0x11BA, 0x11A8],
0x11E8 => [0x11BA, 0x11AE],
0x11E9 => [0x11BA, 0x11AF],
0x11EA => [0x11BA, 0x11B8],
0x11EC => [0x11BC, 0x11A8],
0x11ED => [0x11BC, 0x11A8, 0x11A8],
0x11EE => [0x11BC, 0x11BC],
0x11EF => [0x11BC, 0x11BF],
0x11F1 => [0x11F0, 0x11BA],
0x11F2 => [0x11F0, 0x11EB],
0x11F3 => [0x11C1, 0x11B8],
0x11F4 => [0x11C1, 0x11BC],
0x11F5 => [0x11C2, 0x11AB],
0x11F6 => [0x11C2, 0x11AF],
0x11F7 => [0x11C2, 0x11B7],
0x11F8 => [0x11C2, 0x11B8],
);

foreach my $char (sort {$a <=> $b} keys %Decomp) {
    $char or croak("$PACKAGE : composition to NULL is not allowed");
    my @dec = @{ $Decomp{$char} };
    @dec == 2 || @dec == 3 or
	croak(sprintf("$PACKAGE : weird decomposition [%04X]", $char));
    if (@dec == 2) {
	$Map12{"$dec[0];$dec[1]"} = $char;
    } else {
	$Map123{"$dec[0];$dec[1];$dec[2]"} = $char;
    }
}

#####

sub getSyllableType($) {
    my $u = shift;
    return
	JamoLIni <= $u && $u <= JamoLFin || $u == JamoLFill ? "L" :
	JamoVIni <= $u && $u <= JamoVFin	     ? "V" :
	JamoTIni <= $u && $u <= JamoTFin	     ? "T" :
	SBase <= $u && $u <= SFinal ?
	    ($u - SBase) % TCount ? "LVT" : "LV" : "NA";
}

my %Fillers = (
    "LT"   => [ 0x1160, 0x115F, 0x1160 ],
    "LNA"  => [ 0x1160 ],
    "TV"   => [ 0x115F ],
    "LVTV" => [ 0x115F ],
    "NAV"  => [ 0x115F ],
    "NAT"  => [ 0x115F, 0x1160 ],
);

sub isStandardForm($) {
    my $str = shift(@_).pack('U*');

    my $ptype = 'NA';
    foreach my $ch (unpack('U*', $str)) {
	my $ctype = getSyllableType($ch);
	return "" if $Fillers{"$ptype$ctype"};
	$ptype = $ctype;
    }
    return $ptype eq "L" ? "" : 1;
}

sub insertFiller($) {
    my $str = shift(@_).pack('U*');
    my $ptype = 'NA';
    my(@ret);
    foreach my $ch (unpack('U*', $str)) {
	my $ctype = getSyllableType($ch);
	$Fillers{"$ptype$ctype"} and
	    push(@ret, @{ $Fillers{"$ptype$ctype"} });
	push @ret, $ch;
	$ptype = $ctype;
    }
    $ptype eq "L" and push(@ret, @{ $Fillers{"LNA"} });
    return pack('U*', @ret);
}

sub getHangulName ($) {
    my $u = shift;
    return undef unless &$IsS($u);
    my $sindex = $u - SBase;
    my $lindex = int( $sindex / NCount);
    my $vindex = int(($sindex % NCount) / TCount);
    my $tindex =      $sindex % TCount;
    return "$BlockName$JamoL[$lindex]$JamoV[$vindex]$JamoT[$tindex]";
}

sub parseHangulName ($) {
    my $arg = shift;
    return undef unless $arg =~ s/$BlockName//o;
    return undef unless $arg =~ /^([^AEIOUWY]*)([AEIOUWY]+)([^AEIOUWY]*)$/;
    return undef unless exists $CodeL{$1}
		 && exists $CodeV{$2} && exists $CodeT{$3};
    return SBase + $CodeL{$1} * NCount + $CodeV{$2} * TCount + $CodeT{$3};
}

sub getHangulComposite ($$) {
    if (&$IsL($_[0]) && &$IsV($_[1])) {
	my $lindex = $_[0] - LBase;
	my $vindex = $_[1] - VBase;
	return (SBase + ($lindex * VCount + $vindex) * TCount);
    }
    if (&$IsLV($_[0]) && &$IsT($_[1])) {
	return($_[0] + $_[1] - TBase);
    }
    return undef;
}

sub decomposeJamo ($) {
    my $str = shift(@_).pack('U*');
    my(@ret);
    foreach my $ch (unpack('U*', $str)) {
	push @ret, $Decomp{$ch} ? @{ $Decomp{$ch} } : ($ch);
    }
    return pack('U*', @ret);
}

sub decomposeSyllable ($) {
    my $str = shift(@_).pack('U*');
    my(@ret);
    foreach my $ch (unpack('U*', $str)) {
	my @r = decomposeHangul($ch);
	push @ret, @r ? @r : ($ch);
    }
    return pack('U*', @ret);
}

sub decomposeHangul ($) {
    my $code = shift;
    return unless &$IsS($code);
    my $sindex = $code - SBase;
    my $lindex = int( $sindex / NCount);
    my $vindex = int(($sindex % NCount) / TCount);
    my $tindex =      $sindex % TCount;
    my @ret = (
       LBase + $lindex,
       VBase + $vindex,
      $tindex ? (TBase + $tindex) : (),
    );
    wantarray ? @ret : pack('U*', @ret);
}

sub composeJamo ($) {
    my $str = shift(@_).pack('U*');
    my @tmp = unpack('U*', $str);
    for (my $i = 0; $i < @tmp; $i++) {
	next unless &$IsJ($tmp[$i]);

	if ($tmp[$i + 2] && $Map123{"$tmp[$i];$tmp[$i+1];$tmp[$i+2]"}) {
	    $tmp[$i] = $Map123{"$tmp[$i];$tmp[$i+1];$tmp[$i+2]"};
	    $tmp[$i+1] = $tmp[$i+2] = undef;
	    $i += 2;
	}
	elsif ($tmp[$i + 1] && $Map12{"$tmp[$i];$tmp[$i+1]"}) {
	    $tmp[$i] = $Map12{"$tmp[$i];$tmp[$i+1]"};
	    $tmp[$i+1] = undef;
	    $i ++;
	}
    }
    return pack 'U*', grep defined, @tmp;
}

sub composeSyllable ($) {
    my $str = shift(@_).pack('U*');
    my(@ret);
    foreach my $ch (unpack('U*', $str)) {
	push(@ret, $ch) and next unless @ret;

      # 1. check to see if $ret[-1] is L and $ch is V.

	if (&$IsL($ret[-1]) && &$IsV($ch)) {
	    $ret[-1] -= LBase; # LIndex
	    $ch      -= VBase; # VIndex
	    $ret[-1]  = SBase + ($ret[-1] * VCount + $ch) * TCount;
	    next; # discard $ch
	}

      # 2. check to see if $ret[-1] is LV and $ch is T.

	if (&$IsLV($ret[-1]) && &$IsT($ch)) {
	    $ret[-1] += $ch - TBase; # + TIndex
	    next; # discard $ch
	}

      # 3. just append $ch
	push(@ret, $ch);
    }
    return pack('U*', @ret);
}

##### The below part is common to XS and PP #####

sub decomposeFull ($) { decomposeJamo(decomposeSyllable(shift)) }

sub composeHangul ($) {
    my $ret = composeSyllable(shift);
    wantarray ? unpack('U*', $ret) : $ret;
}

1;
__END__

=head1 NAME

Lingua::KO::Hangul::Util - utility functions for Hangul in Unicode

=head1 SYNOPSIS

  use Lingua::KO::Hangul::Util qw(:all);

  decomposeSyllable("\x{AC00}");          # "\x{1100}\x{1161}"
  composeSyllable("\x{1100}\x{1161}");    # "\x{AC00}"
  decomposeJamo("\x{1101}");              # "\x{1100}\x{1100}"
  composeJamo("\x{1100}\x{1100}");        # "\x{1101}"

  getHangulName(0xAC00);                  # "HANGUL SYLLABLE GA"
  parseHangulName("HANGUL SYLLABLE GA");  # 0xAC00

=head1 DESCRIPTION

A Hangul syllable consists of Hangul jamo (Hangul letters).

Hangul letters are classified into three classes:

  CHOSEONG  (the initial sound) as a leading consonant (L),
  JUNGSEONG (the medial sound)  as a vowel (V),
  JONGSEONG (the final sound)   as a trailing consonant (T).

Any Hangul syllable is a composition of (i) L + V, or (ii) L + V + T.

=head2 Composition and Decomposition

=over 4

=item C<$resultant_string = decomposeSyllable($string)>

It decomposes a precomposed syllable (C<LV> or C<LVT>)
to a sequence of conjoining jamo (C<L + V> or C<L + V + T>)
and returns the result as a string.

Any characters other than Hangul syllables are not affected.

=item C<$resultant_string = composeSyllable($string)>

It composes a sequence of conjoining jamo (C<L + V> or C<L + V + T>)
to a precomposed syllable (C<LV> or C<LVT>) if possible,
and returns the result as a string.
A syllable C<LV> and final jamo C<T> are also composed.

Any characters other than Hangul jamo and syllables are not affected.

=item C<$resultant_string = decomposeJamo($string)>

It decomposes a complex jamo to a sequence of simple jamo if possible,
and returns the result as a string.
Any characters other than complex jamo are not affected.

  e.g.
      CHOSEONG SIOS-PIEUP to CHOSEONG SIOS + PIEUP
      JUNGSEONG AE        to JUNGSEONG A + I
      JUNGSEONG WE        to JUNGSEONG U + EO + I
      JONGSEONG SSANGSIOS to JONGSEONG SIOS + SIOS

=item C<$resultant_string = composeJamo($string)>

It composes a sequence of simple jamo (C<L1 + L2>, C<V1 + V2 + V3>, etc.)
to a complex jamo if possible,
and returns the result as a string.
Any characters other than simple jamo are not affected.

  e.g.
      CHOSEONG SIOS + PIEUP to CHOSEONG SIOS-PIEUP
      JUNGSEONG A + I       to JUNGSEONG AE
      JUNGSEONG U + EO + I  to JUNGSEONG WE
      JONGSEONG SIOS + SIOS to JONGSEONG SSANGSIOS

=item C<$resultant_string = decomposeFull($string)>

It decomposes a syllable/complex jamo to a sequence of simple jamo.
Equivalent to C<decomposeJamo(decomposeSyllable($string))>.

=back

=head2 Composition and Decomposition (Old-interface, deprecated!)

=over 4

=item C<$string_decomposed = decomposeHangul($code_point)>

=item C<@codepoints = decomposeHangul($code_point)>

If the specified code point is of a Hangul syllable,
it returns a list of code points (in a list context)
or a string (in a scalar context) of its decomposition.

   decomposeHangul(0xAC00) # U+AC00 is HANGUL SYLLABLE GA.
      returns "\x{1100}\x{1161}" or (0x1100, 0x1161);

   decomposeHangul(0xAE00) # U+AE00 is HANGUL SYLLABLE GEUL.
      returns "\x{1100}\x{1173}\x{11AF}" or (0x1100, 0x1173, 0x11AF);

Otherwise, returns false (empty string or empty list).

   decomposeHangul(0x0041) # outside Hangul syllables
      returns empty string or empty list.

=item C<$string_composed = composeHangul($src_string)>

=item C<@code_points_composed = composeHangul($src_string)>

Any sequence of an initial jamo C<L> and a medial jamo C<V>
is composed to a syllable C<LV>;
then any sequence of a syllable C<LV> and a final jamo C<T>
is composed to a syllable C<LVT>.

Any characters other than Hangul jamo and syllables are not affected.

   composeHangul("\x{1100}\x{1173}\x{11AF}.")
   # returns "\x{AE00}." or (0xAE00,0x2E);

=item C<$code_point_composite = getHangulComposite($code_point_here, $code_point_next)>

It returns the codepoint of the composite
if both two code points, C<$code_point_here> and C<$code_point_next>,
are in Hangul, and composable.

Otherwise, returns C<undef>.

=back

=head2 Hangul Syllable Name

The following functions handle only a precomposed Hangul syllable
(from C<U+AC00> to C<U+D7A3>), but not a Hangul jamo
or other Hangul-related character.

Names of Hangul syllables have a format of C<"HANGUL SYLLABLE %s">.

=over 4

=item C<$name = getHangulName($code_point)>

If the specified code point is of a Hangul syllable,
it returns its name; otherwise it returns undef.

   getHangulName(0xAC00) returns "HANGUL SYLLABLE GA";
   getHangulName(0x0041) returns undef.

=item C<$codepoint = parseHangulName($name)>

If the specified name is of a Hangul syllable,
it returns its code point; otherwise it returns undef.

   parseHangulName("HANGUL SYLLABLE GEUL") returns 0xAE00;

   parseHangulName("LATIN SMALL LETTER A") returns undef;

   parseHangulName("HANGUL SYLLABLE PERL") returns undef;
    # Regrettably, HANGUL SYLLABLE PERL does not exist :-)

=back

=head2 Standard Korean Syllable Block

Standard Korean syllable block consists of C<L+ V+ T*>
(a sequence of one or more L, one or more V, and zero or more T)
according to conjoining jamo behabior revised in Unicode 3.2 (cf. UAX #28).
A sequence of C<L> followed by C<T> is not a syllable block without C<V>,
but consists of two nonstandard syllable blocks: one without C<V>, and another
without C<L> and C<V>.

=over 4

=item C<$bool = isStandardForm($string)>

It returns boolean whether the string is encoded in the standard form
without a nonstandard sequence. It returns true only if the string
contains no nonstandard sequence.

=item C<$resultant_string = insertFiller($string)>

It transforms the string into standard form by inserting fillers
into each syllables and returns the result as a string.
Choseong filler (C<Lf>, C<U+115F>) is inserted into a syllable block
without C<L>. Jungseong filler (C<Vf>, C<U+1160>) is inserted into
a syllable block without C<V>.

=item C<$type = getSyllableType($code_point)>

It returns the Hangul syllable type (cf. F<HangulSyllableType.txt>)
for the specified code point as a string:
C<"L"> for leading jamo, C<"V"> for vowel jamo, C<"T"> for trailing jamo,
C<"LV"> for LV syllables, C<"LVT"> for LVT syllables, and C<"NA">
for other code points (as B<N>ot B<A>pplicable).

=back

=head1 EXPORT

By default:

    decomposeHangul
    composeHangul
    getHangulName
    parseHangulName
    getHangulComposite

On request:

    decomposeSyllable
    composeSyllable
    decomposeJamo
    composeJamo
    decomposeFull
    isStandardForm
    insertFiller
    getSyllableType

=head1 CAVEAT

This module does not support Hangul jamo assigned in Unicode 5.2.0 (2009).

A list of Hangul charcters this module supports:

    1100..1159 ; 1.1 # [90] HANGUL CHOSEONG KIYEOK..HANGUL CHOSEONG YEORINHIEUH
    115F..11A2 ; 1.1 # [68] HANGUL CHOSEONG FILLER..HANGUL JUNGSEONG SSANGARAEA
    11A8..11F9 ; 1.1 # [82] HANGUL JONGSEONG KIYEOK..HANGUL JONGSEONG YEORINHIEUH
    AC00..D7A3 ; 2.0 # [11172] HANGUL SYLLABLE GA..HANGUL SYLLABLE HIH

=head1 AUTHOR

SADAHIRO Tomoyuki <SADAHIRO@cpan.org>

Copyright(C) 2001, 2003, 2005, SADAHIRO Tomoyuki. Japan.
All rights reserved.

This module is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item Unicode Normalization Forms (UAX #15)

L<http://www.unicode.org/reports/tr15/>

=item Conjoining Jamo Behavior (revision) in UAX #28

L<http://www.unicode.org/reports/tr28/#3_11_conjoining_jamo_behavior>

=item Hangul Syllable Type

L<http://www.unicode.org/Public/UNIDATA/HangulSyllableType.txt>

=item Jamo Decomposition in Old Unicode

L<http://www.unicode.org/Public/2.1-Update3/UnicodeData-2.1.8.txt>

=item ISO/IEC JTC1/SC22/WG20 N954

Paper by K. KIM:
New canonical decomposition and composition processes for Hangeul

L<http://std.dkuug.dk/JTC1/SC22/WG20/docs/N954.PDF>

(summary: L<http://std.dkuug.dk/JTC1/SC22/WG20/docs/N953.PDF>)
(cf. L<http://std.dkuug.dk/JTC1/SC22/WG20/docs/documents.html>)

=back

=cut
