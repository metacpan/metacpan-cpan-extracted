package Locale::CLDR::EraBoundries;
# This file auto generated from Data.xml
#	on Fri 13 Apr  6:59:48 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo::Role;


sub era_boundry {
	my ($self, $type, $date) = @_;
	my $era = $self->_era_boundry;
	return $era->($self, $type, $date);
}

has '_era_boundry' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { sub {
		my ($self, $type, $date) = @_;
		# $date in yyyymmdd format
		my $return = -1;
		SWITCH:
		for ($type) {
			if ($_ eq 'gregorian') {
				$return = 0 if $date <= 1231;
				$return = 1 if $date >= 10101;
			last SWITCH
			}
			if ($_ eq 'generic') {
			last SWITCH
			}
			if ($_ eq 'japanese') {
				$return = 0 if $date >= 6450619;
				$return = 1 if $date >= 6500215;
				$return = 2 if $date >= 6720101;
				$return = 3 if $date >= 6860720;
				$return = 4 if $date >= 7010321;
				$return = 5 if $date >= 7040510;
				$return = 6 if $date >= 7080111;
				$return = 7 if $date >= 7150902;
				$return = 8 if $date >= 7171117;
				$return = 9 if $date >= 7240204;
				$return = 10 if $date >= 7290805;
				$return = 11 if $date >= 7490414;
				$return = 12 if $date >= 7490702;
				$return = 13 if $date >= 7570818;
				$return = 14 if $date >= 7650107;
				$return = 15 if $date >= 7670816;
				$return = 16 if $date >= 7701001;
				$return = 17 if $date >= 7810101;
				$return = 18 if $date >= 7820819;
				$return = 19 if $date >= 8060518;
				$return = 20 if $date >= 8100919;
				$return = 21 if $date >= 8240105;
				$return = 22 if $date >= 8340103;
				$return = 23 if $date >= 8480613;
				$return = 24 if $date >= 8510428;
				$return = 25 if $date >= 8541130;
				$return = 26 if $date >= 8570221;
				$return = 27 if $date >= 8590415;
				$return = 28 if $date >= 8770416;
				$return = 29 if $date >= 8850221;
				$return = 30 if $date >= 8890427;
				$return = 31 if $date >= 8980426;
				$return = 32 if $date >= 9010715;
				$return = 33 if $date >= 9230411;
				$return = 34 if $date >= 9310426;
				$return = 35 if $date >= 9380522;
				$return = 36 if $date >= 9470422;
				$return = 37 if $date >= 9571027;
				$return = 38 if $date >= 9610216;
				$return = 39 if $date >= 9640710;
				$return = 40 if $date >= 9680813;
				$return = 41 if $date >= 9700325;
				$return = 42 if $date >= 9731220;
				$return = 43 if $date >= 9760713;
				$return = 44 if $date >= 9781129;
				$return = 45 if $date >= 9830415;
				$return = 46 if $date >= 9850427;
				$return = 47 if $date >= 9870405;
				$return = 48 if $date >= 9890808;
				$return = 49 if $date >= 9901107;
				$return = 50 if $date >= 9950222;
				$return = 51 if $date >= 9990113;
				$return = 52 if $date >= 10040720;
				$return = 53 if $date >= 10121225;
				$return = 54 if $date >= 10170423;
				$return = 55 if $date >= 10210202;
				$return = 56 if $date >= 10240713;
				$return = 57 if $date >= 10280725;
				$return = 58 if $date >= 10370421;
				$return = 59 if $date >= 10401110;
				$return = 60 if $date >= 10441124;
				$return = 61 if $date >= 10460414;
				$return = 62 if $date >= 10530111;
				$return = 63 if $date >= 10580829;
				$return = 64 if $date >= 10650802;
				$return = 65 if $date >= 10690413;
				$return = 66 if $date >= 10740823;
				$return = 67 if $date >= 10771117;
				$return = 68 if $date >= 10810210;
				$return = 69 if $date >= 10840207;
				$return = 70 if $date >= 10870407;
				$return = 71 if $date >= 10941215;
				$return = 72 if $date >= 10961217;
				$return = 73 if $date >= 10971121;
				$return = 74 if $date >= 10990828;
				$return = 75 if $date >= 11040210;
				$return = 76 if $date >= 11060409;
				$return = 77 if $date >= 11080803;
				$return = 78 if $date >= 11100713;
				$return = 79 if $date >= 11130713;
				$return = 80 if $date >= 11180403;
				$return = 81 if $date >= 11200410;
				$return = 82 if $date >= 11240403;
				$return = 83 if $date >= 11260122;
				$return = 84 if $date >= 11310129;
				$return = 85 if $date >= 11320811;
				$return = 86 if $date >= 11350427;
				$return = 87 if $date >= 11410710;
				$return = 88 if $date >= 11420428;
				$return = 89 if $date >= 11440223;
				$return = 90 if $date >= 11450722;
				$return = 91 if $date >= 11510126;
				$return = 92 if $date >= 11541028;
				$return = 93 if $date >= 11560427;
				$return = 94 if $date >= 11590420;
				$return = 95 if $date >= 11600110;
				$return = 96 if $date >= 11610904;
				$return = 97 if $date >= 11630329;
				$return = 98 if $date >= 11650605;
				$return = 99 if $date >= 11660827;
				$return = 100 if $date >= 11690408;
				$return = 101 if $date >= 11710421;
				$return = 102 if $date >= 11750728;
				$return = 103 if $date >= 11770804;
				$return = 104 if $date >= 11810714;
				$return = 105 if $date >= 11820527;
				$return = 106 if $date >= 11840416;
				$return = 107 if $date >= 11850814;
				$return = 108 if $date >= 11900411;
				$return = 109 if $date >= 11990427;
				$return = 110 if $date >= 12010213;
				$return = 111 if $date >= 12040220;
				$return = 112 if $date >= 12060427;
				$return = 113 if $date >= 12071025;
				$return = 114 if $date >= 12110309;
				$return = 115 if $date >= 12131206;
				$return = 116 if $date >= 12190412;
				$return = 117 if $date >= 12220413;
				$return = 118 if $date >= 12241120;
				$return = 119 if $date >= 12250420;
				$return = 120 if $date >= 12271210;
				$return = 121 if $date >= 12290305;
				$return = 122 if $date >= 12320402;
				$return = 123 if $date >= 12330415;
				$return = 124 if $date >= 12341105;
				$return = 125 if $date >= 12350919;
				$return = 126 if $date >= 12381123;
				$return = 127 if $date >= 12390207;
				$return = 128 if $date >= 12400716;
				$return = 129 if $date >= 12430226;
				$return = 130 if $date >= 12470228;
				$return = 131 if $date >= 12490318;
				$return = 132 if $date >= 12561005;
				$return = 133 if $date >= 12570314;
				$return = 134 if $date >= 12590326;
				$return = 135 if $date >= 12600413;
				$return = 136 if $date >= 12610220;
				$return = 137 if $date >= 12640228;
				$return = 138 if $date >= 12750425;
				$return = 139 if $date >= 12780229;
				$return = 140 if $date >= 12880428;
				$return = 141 if $date >= 12930855;
				$return = 142 if $date >= 12990425;
				$return = 143 if $date >= 13021121;
				$return = 144 if $date >= 13030805;
				$return = 145 if $date >= 13061214;
				$return = 146 if $date >= 13081009;
				$return = 147 if $date >= 13110428;
				$return = 148 if $date >= 13120320;
				$return = 149 if $date >= 13170203;
				$return = 150 if $date >= 13190428;
				$return = 151 if $date >= 13210223;
				$return = 152 if $date >= 13241209;
				$return = 153 if $date >= 13260426;
				$return = 154 if $date >= 13290829;
				$return = 155 if $date >= 13310809;
				$return = 156 if $date >= 13340129;
				$return = 157 if $date >= 13360229;
				$return = 158 if $date >= 13400428;
				$return = 159 if $date >= 13461208;
				$return = 160 if $date >= 13700724;
				$return = 161 if $date >= 13720401;
				$return = 162 if $date >= 13750527;
				$return = 163 if $date >= 13790322;
				$return = 164 if $date >= 13810210;
				$return = 165 if $date >= 13840428;
				$return = 166 if $date >= 13840227;
				$return = 167 if $date >= 13870823;
				$return = 168 if $date >= 13890209;
				$return = 169 if $date >= 13900326;
				$return = 170 if $date >= 13940705;
				$return = 171 if $date >= 14280427;
				$return = 172 if $date >= 14290905;
				$return = 173 if $date >= 14410217;
				$return = 174 if $date >= 14440205;
				$return = 175 if $date >= 14490728;
				$return = 176 if $date >= 14520725;
				$return = 177 if $date >= 14550725;
				$return = 178 if $date >= 14570928;
				$return = 179 if $date >= 14601221;
				$return = 180 if $date >= 14660228;
				$return = 181 if $date >= 14670303;
				$return = 182 if $date >= 14690428;
				$return = 183 if $date >= 14870729;
				$return = 184 if $date >= 14890821;
				$return = 185 if $date >= 14920719;
				$return = 186 if $date >= 15010229;
				$return = 187 if $date >= 15040230;
				$return = 188 if $date >= 15210823;
				$return = 189 if $date >= 15280820;
				$return = 190 if $date >= 15320729;
				$return = 191 if $date >= 15551023;
				$return = 192 if $date >= 15580228;
				$return = 193 if $date >= 15700423;
				$return = 194 if $date >= 15730728;
				$return = 195 if $date >= 15921208;
				$return = 196 if $date >= 15961027;
				$return = 197 if $date >= 16150713;
				$return = 198 if $date >= 16240230;
				$return = 199 if $date >= 16441216;
				$return = 200 if $date >= 16480215;
				$return = 201 if $date >= 16520918;
				$return = 202 if $date >= 16550413;
				$return = 203 if $date >= 16580723;
				$return = 204 if $date >= 16610425;
				$return = 205 if $date >= 16730921;
				$return = 206 if $date >= 16810929;
				$return = 207 if $date >= 16840221;
				$return = 208 if $date >= 16880930;
				$return = 209 if $date >= 17040313;
				$return = 210 if $date >= 17110425;
				$return = 211 if $date >= 17160622;
				$return = 212 if $date >= 17360428;
				$return = 213 if $date >= 17410227;
				$return = 214 if $date >= 17440221;
				$return = 215 if $date >= 17480712;
				$return = 216 if $date >= 17511027;
				$return = 217 if $date >= 17640602;
				$return = 218 if $date >= 17721116;
				$return = 219 if $date >= 17810402;
				$return = 220 if $date >= 17890125;
				$return = 221 if $date >= 18010205;
				$return = 222 if $date >= 18040211;
				$return = 223 if $date >= 18180422;
				$return = 224 if $date >= 18301210;
				$return = 225 if $date >= 18441202;
				$return = 226 if $date >= 18480228;
				$return = 227 if $date >= 18541127;
				$return = 228 if $date >= 18600318;
				$return = 229 if $date >= 18610219;
				$return = 230 if $date >= 18640220;
				$return = 231 if $date >= 18650407;
				$return = 232 if $date >= 18680908;
				$return = 233 if $date >= 19120730;
				$return = 234 if $date >= 19261225;
				$return = 235 if $date >= 19890108;
			last SWITCH
			}
			if ($_ eq 'islamic') {
				$return = 0 if $date >= 6220715;
			last SWITCH
			}
			if ($_ eq 'islamic-civil') {
				$return = 0 if $date >= 6220716;
			last SWITCH
			}
			if ($_ eq 'islamic-rgsa') {
				$return = 0 if $date >= 6220715;
			last SWITCH
			}
			if ($_ eq 'islamic-tbla') {
				$return = 0 if $date >= 6220715;
			last SWITCH
			}
			if ($_ eq 'islamic-umalqura') {
				$return = 0 if $date >= 6220715;
			last SWITCH
			}
			if ($_ eq 'chinese') {
				$return = 0 if $date >= 263601;
			last SWITCH
			}
			if ($_ eq 'hebrew') {
				$return = 0 if $date >= 376010;
			last SWITCH
			}
			if ($_ eq 'buddhist') {
				$return = 0 if $date >= 54201;
			last SWITCH
			}
			if ($_ eq 'coptic') {
				$return = 0 if $date <= 2840828;
				$return = 1 if $date >= 2840829;
			last SWITCH
			}
			if ($_ eq 'persian') {
				$return = 0 if $date >= 6220101;
			last SWITCH
			}
			if ($_ eq 'dangi') {
				$return = 0 if $date >= 233201;
			last SWITCH
			}
			if ($_ eq 'ethiopic') {
				$return = 0 if $date <= 80828;
				$return = 1 if $date >= 80829;
			last SWITCH
			}
			if ($_ eq 'ethiopic-amete-alem') {
				$return = 0 if $date <= 549208;
			last SWITCH
			}
			if ($_ eq 'indian') {
				$return = 0 if $date >= 790101;
			last SWITCH
			}
			if ($_ eq 'roc') {
				$return = 0 if $date <= 19111231;
				$return = 1 if $date >= 19120101;
			last SWITCH
			}
		} return $return; }
	}
);

no Moo::Role;

1;

# vim: tabstop=4
