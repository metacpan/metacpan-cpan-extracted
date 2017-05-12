# $Id: Flame-Palette.t 121 2010-12-28 23:15:37Z daniel $ -*- perl -*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Flame-Palette.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 2308;
BEGIN { use_ok('Flame::Palette') };

use XML::Writer;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub create_empty {
    my $subject = Flame::Palette->new;

    ok(ref($subject) eq 'Flame::Palette', 'empty object');
}

sub create_gray {
    my $subject = Flame::Palette->new;

    foreach(0...255) {
	ok($subject->set(index => $_,
			 red => $_,
			 green => $_,
			 blue => $_), "set gray #$_");
    }

    foreach(0...255) {
	my($r, $g, $b) = $subject->get(index => $_);

	ok($r == $_ && $g == $_ && $b == $_, "compare gray #$_");
    }
}

sub create_red {
    my $subject = Flame::Palette->new;

    foreach(0...255) {
	ok($subject->set(index => 255 - $_,
			 red => $_,
			 green => 0,
			 blue => 0), "set red #$_");
    }

    foreach(0...255) {
	my($r, $g, $b) = $subject->get(index => 255 - $_);

	ok($r == $_ && $g == 0 && $b == 0, "compare red #$_");
    }
}

sub do_parse {
    my $subject = Flame::Palette->new;

    # create some palette of the "I'm not connected to The Matrix" colors.

    open(my $stm, '<', \ '<?xml version="1.0"?>
<palette>
  <color index="0" rgb="210 105 30"/>
  <color index="1" rgb="210 105 30"/>
  <color index="2" rgb="210 105 30"/>
  <color index="3" rgb="210 106 31"/>
  <color index="4" rgb="210 106 31"/>
  <color index="5" rgb="210 107 32"/>
  <color index="6" rgb="210 107 32"/>
  <color index="7" rgb="210 108 33"/>
  <color index="8" rgb="210 108 33"/>
  <color index="9" rgb="211 109 33"/>
  <color index="10" rgb="211 109 34"/>
  <color index="11" rgb="211 110 34"/>
  <color index="12" rgb="211 110 35"/>
  <color index="13" rgb="211 111 35"/>
  <color index="14" rgb="211 111 36"/>
  <color index="15" rgb="211 112 36"/>
  <color index="16" rgb="211 112 36"/>
  <color index="17" rgb="211 113 37"/>
  <color index="18" rgb="212 113 37"/>
  <color index="19" rgb="212 114 38"/>
  <color index="20" rgb="212 114 38"/>
  <color index="21" rgb="212 115 39"/>
  <color index="22" rgb="212 115 39"/>
  <color index="23" rgb="212 116 39"/>
  <color index="24" rgb="212 116 40"/>
  <color index="25" rgb="212 117 40"/>
  <color index="26" rgb="213 117 41"/>
  <color index="27" rgb="213 118 41"/>
  <color index="28" rgb="213 118 42"/>
  <color index="29" rgb="213 119 42"/>
  <color index="30" rgb="213 119 42"/>
  <color index="31" rgb="213 120 43"/>
  <color index="32" rgb="213 120 43"/>
  <color index="33" rgb="213 121 44"/>
  <color index="34" rgb="213 121 44"/>
  <color index="35" rgb="214 122 45"/>
  <color index="36" rgb="214 122 45"/>
  <color index="37" rgb="214 123 45"/>
  <color index="38" rgb="214 123 46"/>
  <color index="39" rgb="214 124 46"/>
  <color index="40" rgb="214 124 47"/>
  <color index="41" rgb="214 125 47"/>
  <color index="42" rgb="214 125 48"/>
  <color index="43" rgb="215 125 48"/>
  <color index="44" rgb="215 126 48"/>
  <color index="45" rgb="215 126 49"/>
  <color index="46" rgb="215 127 49"/>
  <color index="47" rgb="215 127 50"/>
  <color index="48" rgb="215 128 50"/>
  <color index="49" rgb="215 128 51"/>
  <color index="50" rgb="215 129 51"/>
  <color index="51" rgb="215 129 51"/>
  <color index="52" rgb="216 130 52"/>
  <color index="53" rgb="216 130 52"/>
  <color index="54" rgb="216 131 53"/>
  <color index="55" rgb="216 131 53"/>
  <color index="56" rgb="216 132 54"/>
  <color index="57" rgb="216 132 54"/>
  <color index="58" rgb="216 133 54"/>
  <color index="59" rgb="216 133 55"/>
  <color index="60" rgb="217 134 55"/>
  <color index="61" rgb="217 134 56"/>
  <color index="62" rgb="217 135 56"/>
  <color index="63" rgb="217 135 57"/>
  <color index="64" rgb="217 136 57"/>
  <color index="65" rgb="217 136 57"/>
  <color index="66" rgb="217 137 58"/>
  <color index="67" rgb="217 137 58"/>
  <color index="68" rgb="217 138 59"/>
  <color index="69" rgb="218 138 59"/>
  <color index="70" rgb="218 139 60"/>
  <color index="71" rgb="218 139 60"/>
  <color index="72" rgb="218 140 60"/>
  <color index="73" rgb="218 140 61"/>
  <color index="74" rgb="218 141 61"/>
  <color index="75" rgb="218 141 62"/>
  <color index="76" rgb="218 142 62"/>
  <color index="77" rgb="219 142 63"/>
  <color index="78" rgb="219 143 63"/>
  <color index="79" rgb="219 143 63"/>
  <color index="80" rgb="219 144 64"/>
  <color index="81" rgb="219 144 64"/>
  <color index="82" rgb="219 145 65"/>
  <color index="83" rgb="219 145 65"/>
  <color index="84" rgb="219 146 66"/>
  <color index="85" rgb="219 146 66"/>
  <color index="86" rgb="220 146 66"/>
  <color index="87" rgb="220 147 67"/>
  <color index="88" rgb="220 147 67"/>
  <color index="89" rgb="220 148 68"/>
  <color index="90" rgb="220 148 68"/>
  <color index="91" rgb="220 149 69"/>
  <color index="92" rgb="220 149 69"/>
  <color index="93" rgb="220 150 69"/>
  <color index="94" rgb="221 150 70"/>
  <color index="95" rgb="221 151 70"/>
  <color index="96" rgb="221 151 71"/>
  <color index="97" rgb="221 152 71"/>
  <color index="98" rgb="221 152 72"/>
  <color index="99" rgb="221 153 72"/>
  <color index="100" rgb="221 153 72"/>
  <color index="101" rgb="221 154 73"/>
  <color index="102" rgb="221 154 73"/>
  <color index="103" rgb="222 155 74"/>
  <color index="104" rgb="222 155 74"/>
  <color index="105" rgb="222 156 75"/>
  <color index="106" rgb="222 156 75"/>
  <color index="107" rgb="222 157 75"/>
  <color index="108" rgb="222 157 76"/>
  <color index="109" rgb="222 158 76"/>
  <color index="110" rgb="222 158 77"/>
  <color index="111" rgb="223 159 77"/>
  <color index="112" rgb="223 159 78"/>
  <color index="113" rgb="223 160 78"/>
  <color index="114" rgb="223 160 78"/>
  <color index="115" rgb="223 161 79"/>
  <color index="116" rgb="223 161 79"/>
  <color index="117" rgb="223 162 80"/>
  <color index="118" rgb="223 162 80"/>
  <color index="119" rgb="223 163 81"/>
  <color index="120" rgb="224 163 81"/>
  <color index="121" rgb="224 164 81"/>
  <color index="122" rgb="224 164 82"/>
  <color index="123" rgb="224 165 82"/>
  <color index="124" rgb="224 165 83"/>
  <color index="125" rgb="224 166 83"/>
  <color index="126" rgb="224 166 84"/>
  <color index="127" rgb="224 167 84"/>
  <color index="128" rgb="225 167 85"/>
  <color index="129" rgb="225 167 85"/>
  <color index="130" rgb="225 168 85"/>
  <color index="131" rgb="225 168 86"/>
  <color index="132" rgb="225 169 86"/>
  <color index="133" rgb="225 169 87"/>
  <color index="134" rgb="225 170 87"/>
  <color index="135" rgb="225 170 88"/>
  <color index="136" rgb="225 171 88"/>
  <color index="137" rgb="226 171 88"/>
  <color index="138" rgb="226 172 89"/>
  <color index="139" rgb="226 172 89"/>
  <color index="140" rgb="226 173 90"/>
  <color index="141" rgb="226 173 90"/>
  <color index="142" rgb="226 174 91"/>
  <color index="143" rgb="226 174 91"/>
  <color index="144" rgb="226 175 91"/>
  <color index="145" rgb="226 175 92"/>
  <color index="146" rgb="227 176 92"/>
  <color index="147" rgb="227 176 93"/>
  <color index="148" rgb="227 177 93"/>
  <color index="149" rgb="227 177 94"/>
  <color index="150" rgb="227 178 94"/>
  <color index="151" rgb="227 178 94"/>
  <color index="152" rgb="227 179 95"/>
  <color index="153" rgb="227 179 95"/>
  <color index="154" rgb="228 180 96"/>
  <color index="155" rgb="228 180 96"/>
  <color index="156" rgb="228 181 97"/>
  <color index="157" rgb="228 181 97"/>
  <color index="158" rgb="228 182 97"/>
  <color index="159" rgb="228 182 98"/>
  <color index="160" rgb="228 183 98"/>
  <color index="161" rgb="228 183 99"/>
  <color index="162" rgb="228 184 99"/>
  <color index="163" rgb="229 184 100"/>
  <color index="164" rgb="229 185 100"/>
  <color index="165" rgb="229 185 100"/>
  <color index="166" rgb="229 186 101"/>
  <color index="167" rgb="229 186 101"/>
  <color index="168" rgb="229 187 102"/>
  <color index="169" rgb="229 187 102"/>
  <color index="170" rgb="229 188 103"/>
  <color index="171" rgb="230 188 103"/>
  <color index="172" rgb="230 188 103"/>
  <color index="173" rgb="230 189 104"/>
  <color index="174" rgb="230 189 104"/>
  <color index="175" rgb="230 190 105"/>
  <color index="176" rgb="230 190 105"/>
  <color index="177" rgb="230 191 106"/>
  <color index="178" rgb="230 191 106"/>
  <color index="179" rgb="230 192 106"/>
  <color index="180" rgb="231 192 107"/>
  <color index="181" rgb="231 193 107"/>
  <color index="182" rgb="231 193 108"/>
  <color index="183" rgb="231 194 108"/>
  <color index="184" rgb="231 194 109"/>
  <color index="185" rgb="231 195 109"/>
  <color index="186" rgb="231 195 109"/>
  <color index="187" rgb="231 196 110"/>
  <color index="188" rgb="232 196 110"/>
  <color index="189" rgb="232 197 111"/>
  <color index="190" rgb="232 197 111"/>
  <color index="191" rgb="232 198 112"/>
  <color index="192" rgb="232 198 112"/>
  <color index="193" rgb="232 199 112"/>
  <color index="194" rgb="232 199 113"/>
  <color index="195" rgb="232 200 113"/>
  <color index="196" rgb="232 200 114"/>
  <color index="197" rgb="233 201 114"/>
  <color index="198" rgb="233 201 115"/>
  <color index="199" rgb="233 202 115"/>
  <color index="200" rgb="233 202 115"/>
  <color index="201" rgb="233 203 116"/>
  <color index="202" rgb="233 203 116"/>
  <color index="203" rgb="233 204 117"/>
  <color index="204" rgb="233 204 117"/>
  <color index="205" rgb="234 205 118"/>
  <color index="206" rgb="234 205 118"/>
  <color index="207" rgb="234 206 118"/>
  <color index="208" rgb="234 206 119"/>
  <color index="209" rgb="234 207 119"/>
  <color index="210" rgb="234 207 120"/>
  <color index="211" rgb="234 208 120"/>
  <color index="212" rgb="234 208 121"/>
  <color index="213" rgb="234 209 121"/>
  <color index="214" rgb="235 209 121"/>
  <color index="215" rgb="235 209 122"/>
  <color index="216" rgb="235 210 122"/>
  <color index="217" rgb="235 210 123"/>
  <color index="218" rgb="235 211 123"/>
  <color index="219" rgb="235 211 124"/>
  <color index="220" rgb="235 212 124"/>
  <color index="221" rgb="235 212 124"/>
  <color index="222" rgb="236 213 125"/>
  <color index="223" rgb="236 213 125"/>
  <color index="224" rgb="236 214 126"/>
  <color index="225" rgb="236 214 126"/>
  <color index="226" rgb="236 215 127"/>
  <color index="227" rgb="236 215 127"/>
  <color index="228" rgb="236 216 127"/>
  <color index="229" rgb="236 216 128"/>
  <color index="230" rgb="236 217 128"/>
  <color index="231" rgb="237 217 129"/>
  <color index="232" rgb="237 218 129"/>
  <color index="233" rgb="237 218 130"/>
  <color index="234" rgb="237 219 130"/>
  <color index="235" rgb="237 219 130"/>
  <color index="236" rgb="237 220 131"/>
  <color index="237" rgb="237 220 131"/>
  <color index="238" rgb="237 221 132"/>
  <color index="239" rgb="238 221 132"/>
  <color index="240" rgb="238 222 133"/>
  <color index="241" rgb="238 222 133"/>
  <color index="242" rgb="238 223 133"/>
  <color index="243" rgb="238 223 134"/>
  <color index="244" rgb="238 224 134"/>
  <color index="245" rgb="238 224 135"/>
  <color index="246" rgb="238 225 135"/>
  <color index="247" rgb="238 225 136"/>
  <color index="248" rgb="239 226 136"/>
  <color index="249" rgb="239 226 136"/>
  <color index="250" rgb="239 227 137"/>
  <color index="251" rgb="239 227 137"/>
  <color index="252" rgb="239 228 138"/>
  <color index="253" rgb="239 228 138"/>
  <color index="254" rgb="239 229 139"/>
  <color index="255" rgb="239 229 139"/>
</palette>') || die "pleh: $!";

    ok($subject->parse_xml($stm), 'parse XML string');

    my($r, $g, $b);

    ($r, $g, $b) = $subject->get(index => 0);
    ok($r == 210 && $g == 105 && $b == 30, "compare parsed palette entry 0");
    ($r, $g, $b) = $subject->get(index => 1);
    ok($r == 210 && $g == 105 && $b == 30, "compare parsed palette entry 1");
    ($r, $g, $b) = $subject->get(index => 2);
    ok($r == 210 && $g == 105 && $b == 30, "compare parsed palette entry 2");
    ($r, $g, $b) = $subject->get(index => 3);
    ok($r == 210 && $g == 106 && $b == 31, "compare parsed palette entry 3");
    ($r, $g, $b) = $subject->get(index => 4);
    ok($r == 210 && $g == 106 && $b == 31, "compare parsed palette entry 4");
    ($r, $g, $b) = $subject->get(index => 5);
    ok($r == 210 && $g == 107 && $b == 32, "compare parsed palette entry 5");
    ($r, $g, $b) = $subject->get(index => 6);
    ok($r == 210 && $g == 107 && $b == 32, "compare parsed palette entry 6");
    ($r, $g, $b) = $subject->get(index => 7);
    ok($r == 210 && $g == 108 && $b == 33, "compare parsed palette entry 7");
    ($r, $g, $b) = $subject->get(index => 8);
    ok($r == 210 && $g == 108 && $b == 33, "compare parsed palette entry 8");
    ($r, $g, $b) = $subject->get(index => 9);
    ok($r == 211 && $g == 109 && $b == 33, "compare parsed palette entry 9");
    ($r, $g, $b) = $subject->get(index => 10);
    ok($r == 211 && $g == 109 && $b == 34, "compare parsed palette entry 10");
    ($r, $g, $b) = $subject->get(index => 11);
    ok($r == 211 && $g == 110 && $b == 34, "compare parsed palette entry 11");
    ($r, $g, $b) = $subject->get(index => 12);
    ok($r == 211 && $g == 110 && $b == 35, "compare parsed palette entry 12");
    ($r, $g, $b) = $subject->get(index => 13);
    ok($r == 211 && $g == 111 && $b == 35, "compare parsed palette entry 13");
    ($r, $g, $b) = $subject->get(index => 14);
    ok($r == 211 && $g == 111 && $b == 36, "compare parsed palette entry 14");
    ($r, $g, $b) = $subject->get(index => 15);
    ok($r == 211 && $g == 112 && $b == 36, "compare parsed palette entry 15");
    ($r, $g, $b) = $subject->get(index => 16);
    ok($r == 211 && $g == 112 && $b == 36, "compare parsed palette entry 16");
    ($r, $g, $b) = $subject->get(index => 17);
    ok($r == 211 && $g == 113 && $b == 37, "compare parsed palette entry 17");
    ($r, $g, $b) = $subject->get(index => 18);
    ok($r == 212 && $g == 113 && $b == 37, "compare parsed palette entry 18");
    ($r, $g, $b) = $subject->get(index => 19);
    ok($r == 212 && $g == 114 && $b == 38, "compare parsed palette entry 19");
    ($r, $g, $b) = $subject->get(index => 20);
    ok($r == 212 && $g == 114 && $b == 38, "compare parsed palette entry 20");
    ($r, $g, $b) = $subject->get(index => 21);
    ok($r == 212 && $g == 115 && $b == 39, "compare parsed palette entry 21");
    ($r, $g, $b) = $subject->get(index => 22);
    ok($r == 212 && $g == 115 && $b == 39, "compare parsed palette entry 22");
    ($r, $g, $b) = $subject->get(index => 23);
    ok($r == 212 && $g == 116 && $b == 39, "compare parsed palette entry 23");
    ($r, $g, $b) = $subject->get(index => 24);
    ok($r == 212 && $g == 116 && $b == 40, "compare parsed palette entry 24");
    ($r, $g, $b) = $subject->get(index => 25);
    ok($r == 212 && $g == 117 && $b == 40, "compare parsed palette entry 25");
    ($r, $g, $b) = $subject->get(index => 26);
    ok($r == 213 && $g == 117 && $b == 41, "compare parsed palette entry 26");
    ($r, $g, $b) = $subject->get(index => 27);
    ok($r == 213 && $g == 118 && $b == 41, "compare parsed palette entry 27");
    ($r, $g, $b) = $subject->get(index => 28);
    ok($r == 213 && $g == 118 && $b == 42, "compare parsed palette entry 28");
    ($r, $g, $b) = $subject->get(index => 29);
    ok($r == 213 && $g == 119 && $b == 42, "compare parsed palette entry 29");
    ($r, $g, $b) = $subject->get(index => 30);
    ok($r == 213 && $g == 119 && $b == 42, "compare parsed palette entry 30");
    ($r, $g, $b) = $subject->get(index => 31);
    ok($r == 213 && $g == 120 && $b == 43, "compare parsed palette entry 31");
    ($r, $g, $b) = $subject->get(index => 32);
    ok($r == 213 && $g == 120 && $b == 43, "compare parsed palette entry 32");
    ($r, $g, $b) = $subject->get(index => 33);
    ok($r == 213 && $g == 121 && $b == 44, "compare parsed palette entry 33");
    ($r, $g, $b) = $subject->get(index => 34);
    ok($r == 213 && $g == 121 && $b == 44, "compare parsed palette entry 34");
    ($r, $g, $b) = $subject->get(index => 35);
    ok($r == 214 && $g == 122 && $b == 45, "compare parsed palette entry 35");
    ($r, $g, $b) = $subject->get(index => 36);
    ok($r == 214 && $g == 122 && $b == 45, "compare parsed palette entry 36");
    ($r, $g, $b) = $subject->get(index => 37);
    ok($r == 214 && $g == 123 && $b == 45, "compare parsed palette entry 37");
    ($r, $g, $b) = $subject->get(index => 38);
    ok($r == 214 && $g == 123 && $b == 46, "compare parsed palette entry 38");
    ($r, $g, $b) = $subject->get(index => 39);
    ok($r == 214 && $g == 124 && $b == 46, "compare parsed palette entry 39");
    ($r, $g, $b) = $subject->get(index => 40);
    ok($r == 214 && $g == 124 && $b == 47, "compare parsed palette entry 40");
    ($r, $g, $b) = $subject->get(index => 41);
    ok($r == 214 && $g == 125 && $b == 47, "compare parsed palette entry 41");
    ($r, $g, $b) = $subject->get(index => 42);
    ok($r == 214 && $g == 125 && $b == 48, "compare parsed palette entry 42");
    ($r, $g, $b) = $subject->get(index => 43);
    ok($r == 215 && $g == 125 && $b == 48, "compare parsed palette entry 43");
    ($r, $g, $b) = $subject->get(index => 44);
    ok($r == 215 && $g == 126 && $b == 48, "compare parsed palette entry 44");
    ($r, $g, $b) = $subject->get(index => 45);
    ok($r == 215 && $g == 126 && $b == 49, "compare parsed palette entry 45");
    ($r, $g, $b) = $subject->get(index => 46);
    ok($r == 215 && $g == 127 && $b == 49, "compare parsed palette entry 46");
    ($r, $g, $b) = $subject->get(index => 47);
    ok($r == 215 && $g == 127 && $b == 50, "compare parsed palette entry 47");
    ($r, $g, $b) = $subject->get(index => 48);
    ok($r == 215 && $g == 128 && $b == 50, "compare parsed palette entry 48");
    ($r, $g, $b) = $subject->get(index => 49);
    ok($r == 215 && $g == 128 && $b == 51, "compare parsed palette entry 49");
    ($r, $g, $b) = $subject->get(index => 50);
    ok($r == 215 && $g == 129 && $b == 51, "compare parsed palette entry 50");
    ($r, $g, $b) = $subject->get(index => 51);
    ok($r == 215 && $g == 129 && $b == 51, "compare parsed palette entry 51");
    ($r, $g, $b) = $subject->get(index => 52);
    ok($r == 216 && $g == 130 && $b == 52, "compare parsed palette entry 52");
    ($r, $g, $b) = $subject->get(index => 53);
    ok($r == 216 && $g == 130 && $b == 52, "compare parsed palette entry 53");
    ($r, $g, $b) = $subject->get(index => 54);
    ok($r == 216 && $g == 131 && $b == 53, "compare parsed palette entry 54");
    ($r, $g, $b) = $subject->get(index => 55);
    ok($r == 216 && $g == 131 && $b == 53, "compare parsed palette entry 55");
    ($r, $g, $b) = $subject->get(index => 56);
    ok($r == 216 && $g == 132 && $b == 54, "compare parsed palette entry 56");
    ($r, $g, $b) = $subject->get(index => 57);
    ok($r == 216 && $g == 132 && $b == 54, "compare parsed palette entry 57");
    ($r, $g, $b) = $subject->get(index => 58);
    ok($r == 216 && $g == 133 && $b == 54, "compare parsed palette entry 58");
    ($r, $g, $b) = $subject->get(index => 59);
    ok($r == 216 && $g == 133 && $b == 55, "compare parsed palette entry 59");
    ($r, $g, $b) = $subject->get(index => 60);
    ok($r == 217 && $g == 134 && $b == 55, "compare parsed palette entry 60");
    ($r, $g, $b) = $subject->get(index => 61);
    ok($r == 217 && $g == 134 && $b == 56, "compare parsed palette entry 61");
    ($r, $g, $b) = $subject->get(index => 62);
    ok($r == 217 && $g == 135 && $b == 56, "compare parsed palette entry 62");
    ($r, $g, $b) = $subject->get(index => 63);
    ok($r == 217 && $g == 135 && $b == 57, "compare parsed palette entry 63");
    ($r, $g, $b) = $subject->get(index => 64);
    ok($r == 217 && $g == 136 && $b == 57, "compare parsed palette entry 64");
    ($r, $g, $b) = $subject->get(index => 65);
    ok($r == 217 && $g == 136 && $b == 57, "compare parsed palette entry 65");
    ($r, $g, $b) = $subject->get(index => 66);
    ok($r == 217 && $g == 137 && $b == 58, "compare parsed palette entry 66");
    ($r, $g, $b) = $subject->get(index => 67);
    ok($r == 217 && $g == 137 && $b == 58, "compare parsed palette entry 67");
    ($r, $g, $b) = $subject->get(index => 68);
    ok($r == 217 && $g == 138 && $b == 59, "compare parsed palette entry 68");
    ($r, $g, $b) = $subject->get(index => 69);
    ok($r == 218 && $g == 138 && $b == 59, "compare parsed palette entry 69");
    ($r, $g, $b) = $subject->get(index => 70);
    ok($r == 218 && $g == 139 && $b == 60, "compare parsed palette entry 70");
    ($r, $g, $b) = $subject->get(index => 71);
    ok($r == 218 && $g == 139 && $b == 60, "compare parsed palette entry 71");
    ($r, $g, $b) = $subject->get(index => 72);
    ok($r == 218 && $g == 140 && $b == 60, "compare parsed palette entry 72");
    ($r, $g, $b) = $subject->get(index => 73);
    ok($r == 218 && $g == 140 && $b == 61, "compare parsed palette entry 73");
    ($r, $g, $b) = $subject->get(index => 74);
    ok($r == 218 && $g == 141 && $b == 61, "compare parsed palette entry 74");
    ($r, $g, $b) = $subject->get(index => 75);
    ok($r == 218 && $g == 141 && $b == 62, "compare parsed palette entry 75");
    ($r, $g, $b) = $subject->get(index => 76);
    ok($r == 218 && $g == 142 && $b == 62, "compare parsed palette entry 76");
    ($r, $g, $b) = $subject->get(index => 77);
    ok($r == 219 && $g == 142 && $b == 63, "compare parsed palette entry 77");
    ($r, $g, $b) = $subject->get(index => 78);
    ok($r == 219 && $g == 143 && $b == 63, "compare parsed palette entry 78");
    ($r, $g, $b) = $subject->get(index => 79);
    ok($r == 219 && $g == 143 && $b == 63, "compare parsed palette entry 79");
    ($r, $g, $b) = $subject->get(index => 80);
    ok($r == 219 && $g == 144 && $b == 64, "compare parsed palette entry 80");
    ($r, $g, $b) = $subject->get(index => 81);
    ok($r == 219 && $g == 144 && $b == 64, "compare parsed palette entry 81");
    ($r, $g, $b) = $subject->get(index => 82);
    ok($r == 219 && $g == 145 && $b == 65, "compare parsed palette entry 82");
    ($r, $g, $b) = $subject->get(index => 83);
    ok($r == 219 && $g == 145 && $b == 65, "compare parsed palette entry 83");
    ($r, $g, $b) = $subject->get(index => 84);
    ok($r == 219 && $g == 146 && $b == 66, "compare parsed palette entry 84");
    ($r, $g, $b) = $subject->get(index => 85);
    ok($r == 219 && $g == 146 && $b == 66, "compare parsed palette entry 85");
    ($r, $g, $b) = $subject->get(index => 86);
    ok($r == 220 && $g == 146 && $b == 66, "compare parsed palette entry 86");
    ($r, $g, $b) = $subject->get(index => 87);
    ok($r == 220 && $g == 147 && $b == 67, "compare parsed palette entry 87");
    ($r, $g, $b) = $subject->get(index => 88);
    ok($r == 220 && $g == 147 && $b == 67, "compare parsed palette entry 88");
    ($r, $g, $b) = $subject->get(index => 89);
    ok($r == 220 && $g == 148 && $b == 68, "compare parsed palette entry 89");
    ($r, $g, $b) = $subject->get(index => 90);
    ok($r == 220 && $g == 148 && $b == 68, "compare parsed palette entry 90");
    ($r, $g, $b) = $subject->get(index => 91);
    ok($r == 220 && $g == 149 && $b == 69, "compare parsed palette entry 91");
    ($r, $g, $b) = $subject->get(index => 92);
    ok($r == 220 && $g == 149 && $b == 69, "compare parsed palette entry 92");
    ($r, $g, $b) = $subject->get(index => 93);
    ok($r == 220 && $g == 150 && $b == 69, "compare parsed palette entry 93");
    ($r, $g, $b) = $subject->get(index => 94);
    ok($r == 221 && $g == 150 && $b == 70, "compare parsed palette entry 94");
    ($r, $g, $b) = $subject->get(index => 95);
    ok($r == 221 && $g == 151 && $b == 70, "compare parsed palette entry 95");
    ($r, $g, $b) = $subject->get(index => 96);
    ok($r == 221 && $g == 151 && $b == 71, "compare parsed palette entry 96");
    ($r, $g, $b) = $subject->get(index => 97);
    ok($r == 221 && $g == 152 && $b == 71, "compare parsed palette entry 97");
    ($r, $g, $b) = $subject->get(index => 98);
    ok($r == 221 && $g == 152 && $b == 72, "compare parsed palette entry 98");
    ($r, $g, $b) = $subject->get(index => 99);
    ok($r == 221 && $g == 153 && $b == 72, "compare parsed palette entry 99");
    ($r, $g, $b) = $subject->get(index => 100);
    ok($r == 221 && $g == 153 && $b == 72, "compare parsed palette entry 100");
    ($r, $g, $b) = $subject->get(index => 101);
    ok($r == 221 && $g == 154 && $b == 73, "compare parsed palette entry 101");
    ($r, $g, $b) = $subject->get(index => 102);
    ok($r == 221 && $g == 154 && $b == 73, "compare parsed palette entry 102");
    ($r, $g, $b) = $subject->get(index => 103);
    ok($r == 222 && $g == 155 && $b == 74, "compare parsed palette entry 103");
    ($r, $g, $b) = $subject->get(index => 104);
    ok($r == 222 && $g == 155 && $b == 74, "compare parsed palette entry 104");
    ($r, $g, $b) = $subject->get(index => 105);
    ok($r == 222 && $g == 156 && $b == 75, "compare parsed palette entry 105");
    ($r, $g, $b) = $subject->get(index => 106);
    ok($r == 222 && $g == 156 && $b == 75, "compare parsed palette entry 106");
    ($r, $g, $b) = $subject->get(index => 107);
    ok($r == 222 && $g == 157 && $b == 75, "compare parsed palette entry 107");
    ($r, $g, $b) = $subject->get(index => 108);
    ok($r == 222 && $g == 157 && $b == 76, "compare parsed palette entry 108");
    ($r, $g, $b) = $subject->get(index => 109);
    ok($r == 222 && $g == 158 && $b == 76, "compare parsed palette entry 109");
    ($r, $g, $b) = $subject->get(index => 110);
    ok($r == 222 && $g == 158 && $b == 77, "compare parsed palette entry 110");
    ($r, $g, $b) = $subject->get(index => 111);
    ok($r == 223 && $g == 159 && $b == 77, "compare parsed palette entry 111");
    ($r, $g, $b) = $subject->get(index => 112);
    ok($r == 223 && $g == 159 && $b == 78, "compare parsed palette entry 112");
    ($r, $g, $b) = $subject->get(index => 113);
    ok($r == 223 && $g == 160 && $b == 78, "compare parsed palette entry 113");
    ($r, $g, $b) = $subject->get(index => 114);
    ok($r == 223 && $g == 160 && $b == 78, "compare parsed palette entry 114");
    ($r, $g, $b) = $subject->get(index => 115);
    ok($r == 223 && $g == 161 && $b == 79, "compare parsed palette entry 115");
    ($r, $g, $b) = $subject->get(index => 116);
    ok($r == 223 && $g == 161 && $b == 79, "compare parsed palette entry 116");
    ($r, $g, $b) = $subject->get(index => 117);
    ok($r == 223 && $g == 162 && $b == 80, "compare parsed palette entry 117");
    ($r, $g, $b) = $subject->get(index => 118);
    ok($r == 223 && $g == 162 && $b == 80, "compare parsed palette entry 118");
    ($r, $g, $b) = $subject->get(index => 119);
    ok($r == 223 && $g == 163 && $b == 81, "compare parsed palette entry 119");
    ($r, $g, $b) = $subject->get(index => 120);
    ok($r == 224 && $g == 163 && $b == 81, "compare parsed palette entry 120");
    ($r, $g, $b) = $subject->get(index => 121);
    ok($r == 224 && $g == 164 && $b == 81, "compare parsed palette entry 121");
    ($r, $g, $b) = $subject->get(index => 122);
    ok($r == 224 && $g == 164 && $b == 82, "compare parsed palette entry 122");
    ($r, $g, $b) = $subject->get(index => 123);
    ok($r == 224 && $g == 165 && $b == 82, "compare parsed palette entry 123");
    ($r, $g, $b) = $subject->get(index => 124);
    ok($r == 224 && $g == 165 && $b == 83, "compare parsed palette entry 124");
    ($r, $g, $b) = $subject->get(index => 125);
    ok($r == 224 && $g == 166 && $b == 83, "compare parsed palette entry 125");
    ($r, $g, $b) = $subject->get(index => 126);
    ok($r == 224 && $g == 166 && $b == 84, "compare parsed palette entry 126");
    ($r, $g, $b) = $subject->get(index => 127);
    ok($r == 224 && $g == 167 && $b == 84, "compare parsed palette entry 127");
    ($r, $g, $b) = $subject->get(index => 128);
    ok($r == 225 && $g == 167 && $b == 85, "compare parsed palette entry 128");
    ($r, $g, $b) = $subject->get(index => 129);
    ok($r == 225 && $g == 167 && $b == 85, "compare parsed palette entry 129");
    ($r, $g, $b) = $subject->get(index => 130);
    ok($r == 225 && $g == 168 && $b == 85, "compare parsed palette entry 130");
    ($r, $g, $b) = $subject->get(index => 131);
    ok($r == 225 && $g == 168 && $b == 86, "compare parsed palette entry 131");
    ($r, $g, $b) = $subject->get(index => 132);
    ok($r == 225 && $g == 169 && $b == 86, "compare parsed palette entry 132");
    ($r, $g, $b) = $subject->get(index => 133);
    ok($r == 225 && $g == 169 && $b == 87, "compare parsed palette entry 133");
    ($r, $g, $b) = $subject->get(index => 134);
    ok($r == 225 && $g == 170 && $b == 87, "compare parsed palette entry 134");
    ($r, $g, $b) = $subject->get(index => 135);
    ok($r == 225 && $g == 170 && $b == 88, "compare parsed palette entry 135");
    ($r, $g, $b) = $subject->get(index => 136);
    ok($r == 225 && $g == 171 && $b == 88, "compare parsed palette entry 136");
    ($r, $g, $b) = $subject->get(index => 137);
    ok($r == 226 && $g == 171 && $b == 88, "compare parsed palette entry 137");
    ($r, $g, $b) = $subject->get(index => 138);
    ok($r == 226 && $g == 172 && $b == 89, "compare parsed palette entry 138");
    ($r, $g, $b) = $subject->get(index => 139);
    ok($r == 226 && $g == 172 && $b == 89, "compare parsed palette entry 139");
    ($r, $g, $b) = $subject->get(index => 140);
    ok($r == 226 && $g == 173 && $b == 90, "compare parsed palette entry 140");
    ($r, $g, $b) = $subject->get(index => 141);
    ok($r == 226 && $g == 173 && $b == 90, "compare parsed palette entry 141");
    ($r, $g, $b) = $subject->get(index => 142);
    ok($r == 226 && $g == 174 && $b == 91, "compare parsed palette entry 142");
    ($r, $g, $b) = $subject->get(index => 143);
    ok($r == 226 && $g == 174 && $b == 91, "compare parsed palette entry 143");
    ($r, $g, $b) = $subject->get(index => 144);
    ok($r == 226 && $g == 175 && $b == 91, "compare parsed palette entry 144");
    ($r, $g, $b) = $subject->get(index => 145);
    ok($r == 226 && $g == 175 && $b == 92, "compare parsed palette entry 145");
    ($r, $g, $b) = $subject->get(index => 146);
    ok($r == 227 && $g == 176 && $b == 92, "compare parsed palette entry 146");
    ($r, $g, $b) = $subject->get(index => 147);
    ok($r == 227 && $g == 176 && $b == 93, "compare parsed palette entry 147");
    ($r, $g, $b) = $subject->get(index => 148);
    ok($r == 227 && $g == 177 && $b == 93, "compare parsed palette entry 148");
    ($r, $g, $b) = $subject->get(index => 149);
    ok($r == 227 && $g == 177 && $b == 94, "compare parsed palette entry 149");
    ($r, $g, $b) = $subject->get(index => 150);
    ok($r == 227 && $g == 178 && $b == 94, "compare parsed palette entry 150");
    ($r, $g, $b) = $subject->get(index => 151);
    ok($r == 227 && $g == 178 && $b == 94, "compare parsed palette entry 151");
    ($r, $g, $b) = $subject->get(index => 152);
    ok($r == 227 && $g == 179 && $b == 95, "compare parsed palette entry 152");
    ($r, $g, $b) = $subject->get(index => 153);
    ok($r == 227 && $g == 179 && $b == 95, "compare parsed palette entry 153");
    ($r, $g, $b) = $subject->get(index => 154);
    ok($r == 228 && $g == 180 && $b == 96, "compare parsed palette entry 154");
    ($r, $g, $b) = $subject->get(index => 155);
    ok($r == 228 && $g == 180 && $b == 96, "compare parsed palette entry 155");
    ($r, $g, $b) = $subject->get(index => 156);
    ok($r == 228 && $g == 181 && $b == 97, "compare parsed palette entry 156");
    ($r, $g, $b) = $subject->get(index => 157);
    ok($r == 228 && $g == 181 && $b == 97, "compare parsed palette entry 157");
    ($r, $g, $b) = $subject->get(index => 158);
    ok($r == 228 && $g == 182 && $b == 97, "compare parsed palette entry 158");
    ($r, $g, $b) = $subject->get(index => 159);
    ok($r == 228 && $g == 182 && $b == 98, "compare parsed palette entry 159");
    ($r, $g, $b) = $subject->get(index => 160);
    ok($r == 228 && $g == 183 && $b == 98, "compare parsed palette entry 160");
    ($r, $g, $b) = $subject->get(index => 161);
    ok($r == 228 && $g == 183 && $b == 99, "compare parsed palette entry 161");
    ($r, $g, $b) = $subject->get(index => 162);
    ok($r == 228 && $g == 184 && $b == 99, "compare parsed palette entry 162");
    ($r, $g, $b) = $subject->get(index => 163);
    ok($r == 229 && $g == 184 && $b == 100, "compare parsed palette entry 163");
    ($r, $g, $b) = $subject->get(index => 164);
    ok($r == 229 && $g == 185 && $b == 100, "compare parsed palette entry 164");
    ($r, $g, $b) = $subject->get(index => 165);
    ok($r == 229 && $g == 185 && $b == 100, "compare parsed palette entry 165");
    ($r, $g, $b) = $subject->get(index => 166);
    ok($r == 229 && $g == 186 && $b == 101, "compare parsed palette entry 166");
    ($r, $g, $b) = $subject->get(index => 167);
    ok($r == 229 && $g == 186 && $b == 101, "compare parsed palette entry 167");
    ($r, $g, $b) = $subject->get(index => 168);
    ok($r == 229 && $g == 187 && $b == 102, "compare parsed palette entry 168");
    ($r, $g, $b) = $subject->get(index => 169);
    ok($r == 229 && $g == 187 && $b == 102, "compare parsed palette entry 169");
    ($r, $g, $b) = $subject->get(index => 170);
    ok($r == 229 && $g == 188 && $b == 103, "compare parsed palette entry 170");
    ($r, $g, $b) = $subject->get(index => 171);
    ok($r == 230 && $g == 188 && $b == 103, "compare parsed palette entry 171");
    ($r, $g, $b) = $subject->get(index => 172);
    ok($r == 230 && $g == 188 && $b == 103, "compare parsed palette entry 172");
    ($r, $g, $b) = $subject->get(index => 173);
    ok($r == 230 && $g == 189 && $b == 104, "compare parsed palette entry 173");
    ($r, $g, $b) = $subject->get(index => 174);
    ok($r == 230 && $g == 189 && $b == 104, "compare parsed palette entry 174");
    ($r, $g, $b) = $subject->get(index => 175);
    ok($r == 230 && $g == 190 && $b == 105, "compare parsed palette entry 175");
    ($r, $g, $b) = $subject->get(index => 176);
    ok($r == 230 && $g == 190 && $b == 105, "compare parsed palette entry 176");
    ($r, $g, $b) = $subject->get(index => 177);
    ok($r == 230 && $g == 191 && $b == 106, "compare parsed palette entry 177");
    ($r, $g, $b) = $subject->get(index => 178);
    ok($r == 230 && $g == 191 && $b == 106, "compare parsed palette entry 178");
    ($r, $g, $b) = $subject->get(index => 179);
    ok($r == 230 && $g == 192 && $b == 106, "compare parsed palette entry 179");
    ($r, $g, $b) = $subject->get(index => 180);
    ok($r == 231 && $g == 192 && $b == 107, "compare parsed palette entry 180");
    ($r, $g, $b) = $subject->get(index => 181);
    ok($r == 231 && $g == 193 && $b == 107, "compare parsed palette entry 181");
    ($r, $g, $b) = $subject->get(index => 182);
    ok($r == 231 && $g == 193 && $b == 108, "compare parsed palette entry 182");
    ($r, $g, $b) = $subject->get(index => 183);
    ok($r == 231 && $g == 194 && $b == 108, "compare parsed palette entry 183");
    ($r, $g, $b) = $subject->get(index => 184);
    ok($r == 231 && $g == 194 && $b == 109, "compare parsed palette entry 184");
    ($r, $g, $b) = $subject->get(index => 185);
    ok($r == 231 && $g == 195 && $b == 109, "compare parsed palette entry 185");
    ($r, $g, $b) = $subject->get(index => 186);
    ok($r == 231 && $g == 195 && $b == 109, "compare parsed palette entry 186");
    ($r, $g, $b) = $subject->get(index => 187);
    ok($r == 231 && $g == 196 && $b == 110, "compare parsed palette entry 187");
    ($r, $g, $b) = $subject->get(index => 188);
    ok($r == 232 && $g == 196 && $b == 110, "compare parsed palette entry 188");
    ($r, $g, $b) = $subject->get(index => 189);
    ok($r == 232 && $g == 197 && $b == 111, "compare parsed palette entry 189");
    ($r, $g, $b) = $subject->get(index => 190);
    ok($r == 232 && $g == 197 && $b == 111, "compare parsed palette entry 190");
    ($r, $g, $b) = $subject->get(index => 191);
    ok($r == 232 && $g == 198 && $b == 112, "compare parsed palette entry 191");
    ($r, $g, $b) = $subject->get(index => 192);
    ok($r == 232 && $g == 198 && $b == 112, "compare parsed palette entry 192");
    ($r, $g, $b) = $subject->get(index => 193);
    ok($r == 232 && $g == 199 && $b == 112, "compare parsed palette entry 193");
    ($r, $g, $b) = $subject->get(index => 194);
    ok($r == 232 && $g == 199 && $b == 113, "compare parsed palette entry 194");
    ($r, $g, $b) = $subject->get(index => 195);
    ok($r == 232 && $g == 200 && $b == 113, "compare parsed palette entry 195");
    ($r, $g, $b) = $subject->get(index => 196);
    ok($r == 232 && $g == 200 && $b == 114, "compare parsed palette entry 196");
    ($r, $g, $b) = $subject->get(index => 197);
    ok($r == 233 && $g == 201 && $b == 114, "compare parsed palette entry 197");
    ($r, $g, $b) = $subject->get(index => 198);
    ok($r == 233 && $g == 201 && $b == 115, "compare parsed palette entry 198");
    ($r, $g, $b) = $subject->get(index => 199);
    ok($r == 233 && $g == 202 && $b == 115, "compare parsed palette entry 199");
    ($r, $g, $b) = $subject->get(index => 200);
    ok($r == 233 && $g == 202 && $b == 115, "compare parsed palette entry 200");
    ($r, $g, $b) = $subject->get(index => 201);
    ok($r == 233 && $g == 203 && $b == 116, "compare parsed palette entry 201");
    ($r, $g, $b) = $subject->get(index => 202);
    ok($r == 233 && $g == 203 && $b == 116, "compare parsed palette entry 202");
    ($r, $g, $b) = $subject->get(index => 203);
    ok($r == 233 && $g == 204 && $b == 117, "compare parsed palette entry 203");
    ($r, $g, $b) = $subject->get(index => 204);
    ok($r == 233 && $g == 204 && $b == 117, "compare parsed palette entry 204");
    ($r, $g, $b) = $subject->get(index => 205);
    ok($r == 234 && $g == 205 && $b == 118, "compare parsed palette entry 205");
    ($r, $g, $b) = $subject->get(index => 206);
    ok($r == 234 && $g == 205 && $b == 118, "compare parsed palette entry 206");
    ($r, $g, $b) = $subject->get(index => 207);
    ok($r == 234 && $g == 206 && $b == 118, "compare parsed palette entry 207");
    ($r, $g, $b) = $subject->get(index => 208);
    ok($r == 234 && $g == 206 && $b == 119, "compare parsed palette entry 208");
    ($r, $g, $b) = $subject->get(index => 209);
    ok($r == 234 && $g == 207 && $b == 119, "compare parsed palette entry 209");
    ($r, $g, $b) = $subject->get(index => 210);
    ok($r == 234 && $g == 207 && $b == 120, "compare parsed palette entry 210");
    ($r, $g, $b) = $subject->get(index => 211);
    ok($r == 234 && $g == 208 && $b == 120, "compare parsed palette entry 211");
    ($r, $g, $b) = $subject->get(index => 212);
    ok($r == 234 && $g == 208 && $b == 121, "compare parsed palette entry 212");
    ($r, $g, $b) = $subject->get(index => 213);
    ok($r == 234 && $g == 209 && $b == 121, "compare parsed palette entry 213");
    ($r, $g, $b) = $subject->get(index => 214);
    ok($r == 235 && $g == 209 && $b == 121, "compare parsed palette entry 214");
    ($r, $g, $b) = $subject->get(index => 215);
    ok($r == 235 && $g == 209 && $b == 122, "compare parsed palette entry 215");
    ($r, $g, $b) = $subject->get(index => 216);
    ok($r == 235 && $g == 210 && $b == 122, "compare parsed palette entry 216");
    ($r, $g, $b) = $subject->get(index => 217);
    ok($r == 235 && $g == 210 && $b == 123, "compare parsed palette entry 217");
    ($r, $g, $b) = $subject->get(index => 218);
    ok($r == 235 && $g == 211 && $b == 123, "compare parsed palette entry 218");
    ($r, $g, $b) = $subject->get(index => 219);
    ok($r == 235 && $g == 211 && $b == 124, "compare parsed palette entry 219");
    ($r, $g, $b) = $subject->get(index => 220);
    ok($r == 235 && $g == 212 && $b == 124, "compare parsed palette entry 220");
    ($r, $g, $b) = $subject->get(index => 221);
    ok($r == 235 && $g == 212 && $b == 124, "compare parsed palette entry 221");
    ($r, $g, $b) = $subject->get(index => 222);
    ok($r == 236 && $g == 213 && $b == 125, "compare parsed palette entry 222");
    ($r, $g, $b) = $subject->get(index => 223);
    ok($r == 236 && $g == 213 && $b == 125, "compare parsed palette entry 223");
    ($r, $g, $b) = $subject->get(index => 224);
    ok($r == 236 && $g == 214 && $b == 126, "compare parsed palette entry 224");
    ($r, $g, $b) = $subject->get(index => 225);
    ok($r == 236 && $g == 214 && $b == 126, "compare parsed palette entry 225");
    ($r, $g, $b) = $subject->get(index => 226);
    ok($r == 236 && $g == 215 && $b == 127, "compare parsed palette entry 226");
    ($r, $g, $b) = $subject->get(index => 227);
    ok($r == 236 && $g == 215 && $b == 127, "compare parsed palette entry 227");
    ($r, $g, $b) = $subject->get(index => 228);
    ok($r == 236 && $g == 216 && $b == 127, "compare parsed palette entry 228");
    ($r, $g, $b) = $subject->get(index => 229);
    ok($r == 236 && $g == 216 && $b == 128, "compare parsed palette entry 229");
    ($r, $g, $b) = $subject->get(index => 230);
    ok($r == 236 && $g == 217 && $b == 128, "compare parsed palette entry 230");
    ($r, $g, $b) = $subject->get(index => 231);
    ok($r == 237 && $g == 217 && $b == 129, "compare parsed palette entry 231");
    ($r, $g, $b) = $subject->get(index => 232);
    ok($r == 237 && $g == 218 && $b == 129, "compare parsed palette entry 232");
    ($r, $g, $b) = $subject->get(index => 233);
    ok($r == 237 && $g == 218 && $b == 130, "compare parsed palette entry 233");
    ($r, $g, $b) = $subject->get(index => 234);
    ok($r == 237 && $g == 219 && $b == 130, "compare parsed palette entry 234");
    ($r, $g, $b) = $subject->get(index => 235);
    ok($r == 237 && $g == 219 && $b == 130, "compare parsed palette entry 235");
    ($r, $g, $b) = $subject->get(index => 236);
    ok($r == 237 && $g == 220 && $b == 131, "compare parsed palette entry 236");
    ($r, $g, $b) = $subject->get(index => 237);
    ok($r == 237 && $g == 220 && $b == 131, "compare parsed palette entry 237");
    ($r, $g, $b) = $subject->get(index => 238);
    ok($r == 237 && $g == 221 && $b == 132, "compare parsed palette entry 238");
    ($r, $g, $b) = $subject->get(index => 239);
    ok($r == 238 && $g == 221 && $b == 132, "compare parsed palette entry 239");
    ($r, $g, $b) = $subject->get(index => 240);
    ok($r == 238 && $g == 222 && $b == 133, "compare parsed palette entry 240");
    ($r, $g, $b) = $subject->get(index => 241);
    ok($r == 238 && $g == 222 && $b == 133, "compare parsed palette entry 241");
    ($r, $g, $b) = $subject->get(index => 242);
    ok($r == 238 && $g == 223 && $b == 133, "compare parsed palette entry 242");
    ($r, $g, $b) = $subject->get(index => 243);
    ok($r == 238 && $g == 223 && $b == 134, "compare parsed palette entry 243");
    ($r, $g, $b) = $subject->get(index => 244);
    ok($r == 238 && $g == 224 && $b == 134, "compare parsed palette entry 244");
    ($r, $g, $b) = $subject->get(index => 245);
    ok($r == 238 && $g == 224 && $b == 135, "compare parsed palette entry 245");
    ($r, $g, $b) = $subject->get(index => 246);
    ok($r == 238 && $g == 225 && $b == 135, "compare parsed palette entry 246");
    ($r, $g, $b) = $subject->get(index => 247);
    ok($r == 238 && $g == 225 && $b == 136, "compare parsed palette entry 247");
    ($r, $g, $b) = $subject->get(index => 248);
    ok($r == 239 && $g == 226 && $b == 136, "compare parsed palette entry 248");
    ($r, $g, $b) = $subject->get(index => 249);
    ok($r == 239 && $g == 226 && $b == 136, "compare parsed palette entry 249");
    ($r, $g, $b) = $subject->get(index => 250);
    ok($r == 239 && $g == 227 && $b == 137, "compare parsed palette entry 250");
    ($r, $g, $b) = $subject->get(index => 251);
    ok($r == 239 && $g == 227 && $b == 137, "compare parsed palette entry 251");
    ($r, $g, $b) = $subject->get(index => 252);
    ok($r == 239 && $g == 228 && $b == 138, "compare parsed palette entry 252");
    ($r, $g, $b) = $subject->get(index => 253);
    ok($r == 239 && $g == 228 && $b == 138, "compare parsed palette entry 253");
    ($r, $g, $b) = $subject->get(index => 254);
    ok($r == 239 && $g == 229 && $b == 139, "compare parsed palette entry 254");
    ($r, $g, $b) = $subject->get(index => 255);
    ok($r == 239 && $g == 229 && $b == 139, "compare parsed palette entry 255");
}

sub unparse_empty {
    my $subject = Flame::Palette->new;

    open(my $output, '>', \my $string);
    $subject->unparse_xml($output);

    my $expect = '<palette>' . join("", map { qq[<color index="$_" rgb="0 0 0" />] } 0...255) . '</palette>';

    ok($string eq $expect, 'unparse empty palette');
}

sub test_interpol {
    my $subject = Flame::Palette->new;

    $subject->set(qw(index   0 red 255 green 0 blue   0));
    $subject->set(qw(index 255 red   0 green 0 blue 255));
    $subject->interpolate;

    foreach(0...255) {
	my($r, $g, $b) = $subject->get(index => $_);

	ok($r == 255 - $_ && $g == 0 && $b == $_, "check interpolated palette #0 entry #$_");
    }
}

sub test_interpol_multi {
    my $subject = Flame::Palette->new;

    $subject->set(qw(index   0 red 255 green   0 blue   0));
    $subject->set(qw(index  63 red   0 green 255 blue   0));
    $subject->set(qw(index 127 red   0 green   0 blue 255));
    $subject->set(qw(index 191 red   0 green 255 blue   0));
    $subject->set(qw(index 255 red 255 green   0 blue   0));
    $subject->interpolate;

    my($r, $g, $b);

    ($r, $g, $b) = $subject->get(index => 0);
    ok($r == 255 && $g == 0 && $b == 0, "check interpolated palette #1 entry #0");
    ($r, $g, $b) = $subject->get(index => 1);
    ok($r == 250 && $g == 4 && $b == 0, "check interpolated palette #1 entry #1");
    ($r, $g, $b) = $subject->get(index => 2);
    ok($r == 246 && $g == 8 && $b == 0, "check interpolated palette #1 entry #2");
    ($r, $g, $b) = $subject->get(index => 3);
    ok($r == 242 && $g == 12 && $b == 0, "check interpolated palette #1 entry #3");
    ($r, $g, $b) = $subject->get(index => 4);
    ok($r == 238 && $g == 16 && $b == 0, "check interpolated palette #1 entry #4");
    ($r, $g, $b) = $subject->get(index => 5);
    ok($r == 234 && $g == 20 && $b == 0, "check interpolated palette #1 entry #5");
    ($r, $g, $b) = $subject->get(index => 6);
    ok($r == 230 && $g == 24 && $b == 0, "check interpolated palette #1 entry #6");
    ($r, $g, $b) = $subject->get(index => 7);
    ok($r == 226 && $g == 28 && $b == 0, "check interpolated palette #1 entry #7");
    ($r, $g, $b) = $subject->get(index => 8);
    ok($r == 222 && $g == 32 && $b == 0, "check interpolated palette #1 entry #8");
    ($r, $g, $b) = $subject->get(index => 9);
    ok($r == 218 && $g == 36 && $b == 0, "check interpolated palette #1 entry #9");
    ($r, $g, $b) = $subject->get(index => 10);
    ok($r == 214 && $g == 40 && $b == 0, "check interpolated palette #1 entry #10");
    ($r, $g, $b) = $subject->get(index => 11);
    ok($r == 210 && $g == 44 && $b == 0, "check interpolated palette #1 entry #11");
    ($r, $g, $b) = $subject->get(index => 12);
    ok($r == 206 && $g == 48 && $b == 0, "check interpolated palette #1 entry #12");
    ($r, $g, $b) = $subject->get(index => 13);
    ok($r == 202 && $g == 52 && $b == 0, "check interpolated palette #1 entry #13");
    ($r, $g, $b) = $subject->get(index => 14);
    ok($r == 198 && $g == 56 && $b == 0, "check interpolated palette #1 entry #14");
    ($r, $g, $b) = $subject->get(index => 15);
    ok($r == 194 && $g == 60 && $b == 0, "check interpolated palette #1 entry #15");
    ($r, $g, $b) = $subject->get(index => 16);
    ok($r == 190 && $g == 64 && $b == 0, "check interpolated palette #1 entry #16");
    ($r, $g, $b) = $subject->get(index => 17);
    ok($r == 186 && $g == 68 && $b == 0, "check interpolated palette #1 entry #17");
    ($r, $g, $b) = $subject->get(index => 18);
    ok($r == 182 && $g == 72 && $b == 0, "check interpolated palette #1 entry #18");
    ($r, $g, $b) = $subject->get(index => 19);
    ok($r == 178 && $g == 76 && $b == 0, "check interpolated palette #1 entry #19");
    ($r, $g, $b) = $subject->get(index => 20);
    ok($r == 174 && $g == 80 && $b == 0, "check interpolated palette #1 entry #20");
    ($r, $g, $b) = $subject->get(index => 21);
    ok($r == 170 && $g == 85 && $b == 0, "check interpolated palette #1 entry #21");
    ($r, $g, $b) = $subject->get(index => 22);
    ok($r == 165 && $g == 89 && $b == 0, "check interpolated palette #1 entry #22");
    ($r, $g, $b) = $subject->get(index => 23);
    ok($r == 161 && $g == 93 && $b == 0, "check interpolated palette #1 entry #23");
    ($r, $g, $b) = $subject->get(index => 24);
    ok($r == 157 && $g == 97 && $b == 0, "check interpolated palette #1 entry #24");
    ($r, $g, $b) = $subject->get(index => 25);
    ok($r == 153 && $g == 101 && $b == 0, "check interpolated palette #1 entry #25");
    ($r, $g, $b) = $subject->get(index => 26);
    ok($r == 149 && $g == 105 && $b == 0, "check interpolated palette #1 entry #26");
    ($r, $g, $b) = $subject->get(index => 27);
    ok($r == 145 && $g == 109 && $b == 0, "check interpolated palette #1 entry #27");
    ($r, $g, $b) = $subject->get(index => 28);
    ok($r == 141 && $g == 113 && $b == 0, "check interpolated palette #1 entry #28");
    ($r, $g, $b) = $subject->get(index => 29);
    ok($r == 137 && $g == 117 && $b == 0, "check interpolated palette #1 entry #29");
    ($r, $g, $b) = $subject->get(index => 30);
    ok($r == 133 && $g == 121 && $b == 0, "check interpolated palette #1 entry #30");
    ($r, $g, $b) = $subject->get(index => 31);
    ok($r == 129 && $g == 125 && $b == 0, "check interpolated palette #1 entry #31");
    ($r, $g, $b) = $subject->get(index => 32);
    ok($r == 125 && $g == 129 && $b == 0, "check interpolated palette #1 entry #32");
    ($r, $g, $b) = $subject->get(index => 33);
    ok($r == 121 && $g == 133 && $b == 0, "check interpolated palette #1 entry #33");
    ($r, $g, $b) = $subject->get(index => 34);
    ok($r == 117 && $g == 137 && $b == 0, "check interpolated palette #1 entry #34");
    ($r, $g, $b) = $subject->get(index => 35);
    ok($r == 113 && $g == 141 && $b == 0, "check interpolated palette #1 entry #35");
    ($r, $g, $b) = $subject->get(index => 36);
    ok($r == 109 && $g == 145 && $b == 0, "check interpolated palette #1 entry #36");
    ($r, $g, $b) = $subject->get(index => 37);
    ok($r == 105 && $g == 149 && $b == 0, "check interpolated palette #1 entry #37");
    ($r, $g, $b) = $subject->get(index => 38);
    ok($r == 101 && $g == 153 && $b == 0, "check interpolated palette #1 entry #38");
    ($r, $g, $b) = $subject->get(index => 39);
    ok($r == 97 && $g == 157 && $b == 0, "check interpolated palette #1 entry #39");
    ($r, $g, $b) = $subject->get(index => 40);
    ok($r == 93 && $g == 161 && $b == 0, "check interpolated palette #1 entry #40");
    ($r, $g, $b) = $subject->get(index => 41);
    ok($r == 89 && $g == 165 && $b == 0, "check interpolated palette #1 entry #41");
    ($r, $g, $b) = $subject->get(index => 42);
    ok($r == 85 && $g == 170 && $b == 0, "check interpolated palette #1 entry #42");
    ($r, $g, $b) = $subject->get(index => 43);
    ok($r == 80 && $g == 174 && $b == 0, "check interpolated palette #1 entry #43");
    ($r, $g, $b) = $subject->get(index => 44);
    ok($r == 76 && $g == 178 && $b == 0, "check interpolated palette #1 entry #44");
    ($r, $g, $b) = $subject->get(index => 45);
    ok($r == 72 && $g == 182 && $b == 0, "check interpolated palette #1 entry #45");
    ($r, $g, $b) = $subject->get(index => 46);
    ok($r == 68 && $g == 186 && $b == 0, "check interpolated palette #1 entry #46");
    ($r, $g, $b) = $subject->get(index => 47);
    ok($r == 64 && $g == 190 && $b == 0, "check interpolated palette #1 entry #47");
    ($r, $g, $b) = $subject->get(index => 48);
    ok($r == 60 && $g == 194 && $b == 0, "check interpolated palette #1 entry #48");
    ($r, $g, $b) = $subject->get(index => 49);
    ok($r == 56 && $g == 198 && $b == 0, "check interpolated palette #1 entry #49");
    ($r, $g, $b) = $subject->get(index => 50);
    ok($r == 52 && $g == 202 && $b == 0, "check interpolated palette #1 entry #50");
    ($r, $g, $b) = $subject->get(index => 51);
    ok($r == 48 && $g == 206 && $b == 0, "check interpolated palette #1 entry #51");
    ($r, $g, $b) = $subject->get(index => 52);
    ok($r == 44 && $g == 210 && $b == 0, "check interpolated palette #1 entry #52");
    ($r, $g, $b) = $subject->get(index => 53);
    ok($r == 40 && $g == 214 && $b == 0, "check interpolated palette #1 entry #53");
    ($r, $g, $b) = $subject->get(index => 54);
    ok($r == 36 && $g == 218 && $b == 0, "check interpolated palette #1 entry #54");
    ($r, $g, $b) = $subject->get(index => 55);
    ok($r == 32 && $g == 222 && $b == 0, "check interpolated palette #1 entry #55");
    ($r, $g, $b) = $subject->get(index => 56);
    ok($r == 28 && $g == 226 && $b == 0, "check interpolated palette #1 entry #56");
    ($r, $g, $b) = $subject->get(index => 57);
    ok($r == 24 && $g == 230 && $b == 0, "check interpolated palette #1 entry #57");
    ($r, $g, $b) = $subject->get(index => 58);
    ok($r == 20 && $g == 234 && $b == 0, "check interpolated palette #1 entry #58");
    ($r, $g, $b) = $subject->get(index => 59);
    ok($r == 16 && $g == 238 && $b == 0, "check interpolated palette #1 entry #59");
    ($r, $g, $b) = $subject->get(index => 60);
    ok($r == 12 && $g == 242 && $b == 0, "check interpolated palette #1 entry #60");
    ($r, $g, $b) = $subject->get(index => 61);
    ok($r == 8 && $g == 246 && $b == 0, "check interpolated palette #1 entry #61");
    ($r, $g, $b) = $subject->get(index => 62);
    ok($r == 4 && $g == 250 && $b == 0, "check interpolated palette #1 entry #62");
    ($r, $g, $b) = $subject->get(index => 63);
    ok($r == 0 && $g == 255 && $b == 0, "check interpolated palette #1 entry #63");
    ($r, $g, $b) = $subject->get(index => 64);
    ok($r == 0 && $g == 251 && $b == 3, "check interpolated palette #1 entry #64");
    ($r, $g, $b) = $subject->get(index => 65);
    ok($r == 0 && $g == 247 && $b == 7, "check interpolated palette #1 entry #65");
    ($r, $g, $b) = $subject->get(index => 66);
    ok($r == 0 && $g == 243 && $b == 11, "check interpolated palette #1 entry #66");
    ($r, $g, $b) = $subject->get(index => 67);
    ok($r == 0 && $g == 239 && $b == 15, "check interpolated palette #1 entry #67");
    ($r, $g, $b) = $subject->get(index => 68);
    ok($r == 0 && $g == 235 && $b == 19, "check interpolated palette #1 entry #68");
    ($r, $g, $b) = $subject->get(index => 69);
    ok($r == 0 && $g == 231 && $b == 23, "check interpolated palette #1 entry #69");
    ($r, $g, $b) = $subject->get(index => 70);
    ok($r == 0 && $g == 227 && $b == 27, "check interpolated palette #1 entry #70");
    ($r, $g, $b) = $subject->get(index => 71);
    ok($r == 0 && $g == 223 && $b == 31, "check interpolated palette #1 entry #71");
    ($r, $g, $b) = $subject->get(index => 72);
    ok($r == 0 && $g == 219 && $b == 35, "check interpolated palette #1 entry #72");
    ($r, $g, $b) = $subject->get(index => 73);
    ok($r == 0 && $g == 215 && $b == 39, "check interpolated palette #1 entry #73");
    ($r, $g, $b) = $subject->get(index => 74);
    ok($r == 0 && $g == 211 && $b == 43, "check interpolated palette #1 entry #74");
    ($r, $g, $b) = $subject->get(index => 75);
    ok($r == 0 && $g == 207 && $b == 47, "check interpolated palette #1 entry #75");
    ($r, $g, $b) = $subject->get(index => 76);
    ok($r == 0 && $g == 203 && $b == 51, "check interpolated palette #1 entry #76");
    ($r, $g, $b) = $subject->get(index => 77);
    ok($r == 0 && $g == 199 && $b == 55, "check interpolated palette #1 entry #77");
    ($r, $g, $b) = $subject->get(index => 78);
    ok($r == 0 && $g == 195 && $b == 59, "check interpolated palette #1 entry #78");
    ($r, $g, $b) = $subject->get(index => 79);
    ok($r == 0 && $g == 191 && $b == 63, "check interpolated palette #1 entry #79");
    ($r, $g, $b) = $subject->get(index => 80);
    ok($r == 0 && $g == 187 && $b == 67, "check interpolated palette #1 entry #80");
    ($r, $g, $b) = $subject->get(index => 81);
    ok($r == 0 && $g == 183 && $b == 71, "check interpolated palette #1 entry #81");
    ($r, $g, $b) = $subject->get(index => 82);
    ok($r == 0 && $g == 179 && $b == 75, "check interpolated palette #1 entry #82");
    ($r, $g, $b) = $subject->get(index => 83);
    ok($r == 0 && $g == 175 && $b == 79, "check interpolated palette #1 entry #83");
    ($r, $g, $b) = $subject->get(index => 84);
    ok($r == 0 && $g == 171 && $b == 83, "check interpolated palette #1 entry #84");
    ($r, $g, $b) = $subject->get(index => 85);
    ok($r == 0 && $g == 167 && $b == 87, "check interpolated palette #1 entry #85");
    ($r, $g, $b) = $subject->get(index => 86);
    ok($r == 0 && $g == 163 && $b == 91, "check interpolated palette #1 entry #86");
    ($r, $g, $b) = $subject->get(index => 87);
    ok($r == 0 && $g == 159 && $b == 95, "check interpolated palette #1 entry #87");
    ($r, $g, $b) = $subject->get(index => 88);
    ok($r == 0 && $g == 155 && $b == 99, "check interpolated palette #1 entry #88");
    ($r, $g, $b) = $subject->get(index => 89);
    ok($r == 0 && $g == 151 && $b == 103, "check interpolated palette #1 entry #89");
    ($r, $g, $b) = $subject->get(index => 90);
    ok($r == 0 && $g == 147 && $b == 107, "check interpolated palette #1 entry #90");
    ($r, $g, $b) = $subject->get(index => 91);
    ok($r == 0 && $g == 143 && $b == 111, "check interpolated palette #1 entry #91");
    ($r, $g, $b) = $subject->get(index => 92);
    ok($r == 0 && $g == 139 && $b == 115, "check interpolated palette #1 entry #92");
    ($r, $g, $b) = $subject->get(index => 93);
    ok($r == 0 && $g == 135 && $b == 119, "check interpolated palette #1 entry #93");
    ($r, $g, $b) = $subject->get(index => 94);
    ok($r == 0 && $g == 131 && $b == 123, "check interpolated palette #1 entry #94");
    ($r, $g, $b) = $subject->get(index => 95);
    ok($r == 0 && $g == 127 && $b == 127, "check interpolated palette #1 entry #95");
    ($r, $g, $b) = $subject->get(index => 96);
    ok($r == 0 && $g == 123 && $b == 131, "check interpolated palette #1 entry #96");
    ($r, $g, $b) = $subject->get(index => 97);
    ok($r == 0 && $g == 119 && $b == 135, "check interpolated palette #1 entry #97");
    ($r, $g, $b) = $subject->get(index => 98);
    ok($r == 0 && $g == 115 && $b == 139, "check interpolated palette #1 entry #98");
    ($r, $g, $b) = $subject->get(index => 99);
    ok($r == 0 && $g == 111 && $b == 143, "check interpolated palette #1 entry #99");
    ($r, $g, $b) = $subject->get(index => 100);
    ok($r == 0 && $g == 107 && $b == 147, "check interpolated palette #1 entry #100");
    ($r, $g, $b) = $subject->get(index => 101);
    ok($r == 0 && $g == 103 && $b == 151, "check interpolated palette #1 entry #101");
    ($r, $g, $b) = $subject->get(index => 102);
    ok($r == 0 && $g == 99 && $b == 155, "check interpolated palette #1 entry #102");
    ($r, $g, $b) = $subject->get(index => 103);
    ok($r == 0 && $g == 95 && $b == 159, "check interpolated palette #1 entry #103");
    ($r, $g, $b) = $subject->get(index => 104);
    ok($r == 0 && $g == 91 && $b == 163, "check interpolated palette #1 entry #104");
    ($r, $g, $b) = $subject->get(index => 105);
    ok($r == 0 && $g == 87 && $b == 167, "check interpolated palette #1 entry #105");
    ($r, $g, $b) = $subject->get(index => 106);
    ok($r == 0 && $g == 83 && $b == 171, "check interpolated palette #1 entry #106");
    ($r, $g, $b) = $subject->get(index => 107);
    ok($r == 0 && $g == 79 && $b == 175, "check interpolated palette #1 entry #107");
    ($r, $g, $b) = $subject->get(index => 108);
    ok($r == 0 && $g == 75 && $b == 179, "check interpolated palette #1 entry #108");
    ($r, $g, $b) = $subject->get(index => 109);
    ok($r == 0 && $g == 71 && $b == 183, "check interpolated palette #1 entry #109");
    ($r, $g, $b) = $subject->get(index => 110);
    ok($r == 0 && $g == 67 && $b == 187, "check interpolated palette #1 entry #110");
    ($r, $g, $b) = $subject->get(index => 111);
    ok($r == 0 && $g == 63 && $b == 191, "check interpolated palette #1 entry #111");
    ($r, $g, $b) = $subject->get(index => 112);
    ok($r == 0 && $g == 59 && $b == 195, "check interpolated palette #1 entry #112");
    ($r, $g, $b) = $subject->get(index => 113);
    ok($r == 0 && $g == 55 && $b == 199, "check interpolated palette #1 entry #113");
    ($r, $g, $b) = $subject->get(index => 114);
    ok($r == 0 && $g == 51 && $b == 203, "check interpolated palette #1 entry #114");
    ($r, $g, $b) = $subject->get(index => 115);
    ok($r == 0 && $g == 47 && $b == 207, "check interpolated palette #1 entry #115");
    ($r, $g, $b) = $subject->get(index => 116);
    ok($r == 0 && $g == 43 && $b == 211, "check interpolated palette #1 entry #116");
    ($r, $g, $b) = $subject->get(index => 117);
    ok($r == 0 && $g == 39 && $b == 215, "check interpolated palette #1 entry #117");
    ($r, $g, $b) = $subject->get(index => 118);
    ok($r == 0 && $g == 35 && $b == 219, "check interpolated palette #1 entry #118");
    ($r, $g, $b) = $subject->get(index => 119);
    ok($r == 0 && $g == 31 && $b == 223, "check interpolated palette #1 entry #119");
    ($r, $g, $b) = $subject->get(index => 120);
    ok($r == 0 && $g == 27 && $b == 227, "check interpolated palette #1 entry #120");
    ($r, $g, $b) = $subject->get(index => 121);
    ok($r == 0 && $g == 23 && $b == 231, "check interpolated palette #1 entry #121");
    ($r, $g, $b) = $subject->get(index => 122);
    ok($r == 0 && $g == 19 && $b == 235, "check interpolated palette #1 entry #122");
    ($r, $g, $b) = $subject->get(index => 123);
    ok($r == 0 && $g == 15 && $b == 239, "check interpolated palette #1 entry #123");
    ($r, $g, $b) = $subject->get(index => 124);
    ok($r == 0 && $g == 11 && $b == 243, "check interpolated palette #1 entry #124");
    ($r, $g, $b) = $subject->get(index => 125);
    ok($r == 0 && $g == 7 && $b == 247, "check interpolated palette #1 entry #125");
    ($r, $g, $b) = $subject->get(index => 126);
    ok($r == 0 && $g == 3 && $b == 251, "check interpolated palette #1 entry #126");
    ($r, $g, $b) = $subject->get(index => 127);
    ok($r == 0 && $g == 0 && $b == 255, "check interpolated palette #1 entry #127");
    ($r, $g, $b) = $subject->get(index => 128);
    ok($r == 0 && $g == 3 && $b == 251, "check interpolated palette #1 entry #128");
    ($r, $g, $b) = $subject->get(index => 129);
    ok($r == 0 && $g == 7 && $b == 247, "check interpolated palette #1 entry #129");
    ($r, $g, $b) = $subject->get(index => 130);
    ok($r == 0 && $g == 11 && $b == 243, "check interpolated palette #1 entry #130");
    ($r, $g, $b) = $subject->get(index => 131);
    ok($r == 0 && $g == 15 && $b == 239, "check interpolated palette #1 entry #131");
    ($r, $g, $b) = $subject->get(index => 132);
    ok($r == 0 && $g == 19 && $b == 235, "check interpolated palette #1 entry #132");
    ($r, $g, $b) = $subject->get(index => 133);
    ok($r == 0 && $g == 23 && $b == 231, "check interpolated palette #1 entry #133");
    ($r, $g, $b) = $subject->get(index => 134);
    ok($r == 0 && $g == 27 && $b == 227, "check interpolated palette #1 entry #134");
    ($r, $g, $b) = $subject->get(index => 135);
    ok($r == 0 && $g == 31 && $b == 223, "check interpolated palette #1 entry #135");
    ($r, $g, $b) = $subject->get(index => 136);
    ok($r == 0 && $g == 35 && $b == 219, "check interpolated palette #1 entry #136");
    ($r, $g, $b) = $subject->get(index => 137);
    ok($r == 0 && $g == 39 && $b == 215, "check interpolated palette #1 entry #137");
    ($r, $g, $b) = $subject->get(index => 138);
    ok($r == 0 && $g == 43 && $b == 211, "check interpolated palette #1 entry #138");
    ($r, $g, $b) = $subject->get(index => 139);
    ok($r == 0 && $g == 47 && $b == 207, "check interpolated palette #1 entry #139");
    ($r, $g, $b) = $subject->get(index => 140);
    ok($r == 0 && $g == 51 && $b == 203, "check interpolated palette #1 entry #140");
    ($r, $g, $b) = $subject->get(index => 141);
    ok($r == 0 && $g == 55 && $b == 199, "check interpolated palette #1 entry #141");
    ($r, $g, $b) = $subject->get(index => 142);
    ok($r == 0 && $g == 59 && $b == 195, "check interpolated palette #1 entry #142");
    ($r, $g, $b) = $subject->get(index => 143);
    ok($r == 0 && $g == 63 && $b == 191, "check interpolated palette #1 entry #143");
    ($r, $g, $b) = $subject->get(index => 144);
    ok($r == 0 && $g == 67 && $b == 187, "check interpolated palette #1 entry #144");
    ($r, $g, $b) = $subject->get(index => 145);
    ok($r == 0 && $g == 71 && $b == 183, "check interpolated palette #1 entry #145");
    ($r, $g, $b) = $subject->get(index => 146);
    ok($r == 0 && $g == 75 && $b == 179, "check interpolated palette #1 entry #146");
    ($r, $g, $b) = $subject->get(index => 147);
    ok($r == 0 && $g == 79 && $b == 175, "check interpolated palette #1 entry #147");
    ($r, $g, $b) = $subject->get(index => 148);
    ok($r == 0 && $g == 83 && $b == 171, "check interpolated palette #1 entry #148");
    ($r, $g, $b) = $subject->get(index => 149);
    ok($r == 0 && $g == 87 && $b == 167, "check interpolated palette #1 entry #149");
    ($r, $g, $b) = $subject->get(index => 150);
    ok($r == 0 && $g == 91 && $b == 163, "check interpolated palette #1 entry #150");
    ($r, $g, $b) = $subject->get(index => 151);
    ok($r == 0 && $g == 95 && $b == 159, "check interpolated palette #1 entry #151");
    ($r, $g, $b) = $subject->get(index => 152);
    ok($r == 0 && $g == 99 && $b == 155, "check interpolated palette #1 entry #152");
    ($r, $g, $b) = $subject->get(index => 153);
    ok($r == 0 && $g == 103 && $b == 151, "check interpolated palette #1 entry #153");
    ($r, $g, $b) = $subject->get(index => 154);
    ok($r == 0 && $g == 107 && $b == 147, "check interpolated palette #1 entry #154");
    ($r, $g, $b) = $subject->get(index => 155);
    ok($r == 0 && $g == 111 && $b == 143, "check interpolated palette #1 entry #155");
    ($r, $g, $b) = $subject->get(index => 156);
    ok($r == 0 && $g == 115 && $b == 139, "check interpolated palette #1 entry #156");
    ($r, $g, $b) = $subject->get(index => 157);
    ok($r == 0 && $g == 119 && $b == 135, "check interpolated palette #1 entry #157");
    ($r, $g, $b) = $subject->get(index => 158);
    ok($r == 0 && $g == 123 && $b == 131, "check interpolated palette #1 entry #158");
    ($r, $g, $b) = $subject->get(index => 159);
    ok($r == 0 && $g == 127 && $b == 127, "check interpolated palette #1 entry #159");
    ($r, $g, $b) = $subject->get(index => 160);
    ok($r == 0 && $g == 131 && $b == 123, "check interpolated palette #1 entry #160");
    ($r, $g, $b) = $subject->get(index => 161);
    ok($r == 0 && $g == 135 && $b == 119, "check interpolated palette #1 entry #161");
    ($r, $g, $b) = $subject->get(index => 162);
    ok($r == 0 && $g == 139 && $b == 115, "check interpolated palette #1 entry #162");
    ($r, $g, $b) = $subject->get(index => 163);
    ok($r == 0 && $g == 143 && $b == 111, "check interpolated palette #1 entry #163");
    ($r, $g, $b) = $subject->get(index => 164);
    ok($r == 0 && $g == 147 && $b == 107, "check interpolated palette #1 entry #164");
    ($r, $g, $b) = $subject->get(index => 165);
    ok($r == 0 && $g == 151 && $b == 103, "check interpolated palette #1 entry #165");
    ($r, $g, $b) = $subject->get(index => 166);
    ok($r == 0 && $g == 155 && $b == 99, "check interpolated palette #1 entry #166");
    ($r, $g, $b) = $subject->get(index => 167);
    ok($r == 0 && $g == 159 && $b == 95, "check interpolated palette #1 entry #167");
    ($r, $g, $b) = $subject->get(index => 168);
    ok($r == 0 && $g == 163 && $b == 91, "check interpolated palette #1 entry #168");
    ($r, $g, $b) = $subject->get(index => 169);
    ok($r == 0 && $g == 167 && $b == 87, "check interpolated palette #1 entry #169");
    ($r, $g, $b) = $subject->get(index => 170);
    ok($r == 0 && $g == 171 && $b == 83, "check interpolated palette #1 entry #170");
    ($r, $g, $b) = $subject->get(index => 171);
    ok($r == 0 && $g == 175 && $b == 79, "check interpolated palette #1 entry #171");
    ($r, $g, $b) = $subject->get(index => 172);
    ok($r == 0 && $g == 179 && $b == 75, "check interpolated palette #1 entry #172");
    ($r, $g, $b) = $subject->get(index => 173);
    ok($r == 0 && $g == 183 && $b == 71, "check interpolated palette #1 entry #173");
    ($r, $g, $b) = $subject->get(index => 174);
    ok($r == 0 && $g == 187 && $b == 67, "check interpolated palette #1 entry #174");
    ($r, $g, $b) = $subject->get(index => 175);
    ok($r == 0 && $g == 191 && $b == 63, "check interpolated palette #1 entry #175");
    ($r, $g, $b) = $subject->get(index => 176);
    ok($r == 0 && $g == 195 && $b == 59, "check interpolated palette #1 entry #176");
    ($r, $g, $b) = $subject->get(index => 177);
    ok($r == 0 && $g == 199 && $b == 55, "check interpolated palette #1 entry #177");
    ($r, $g, $b) = $subject->get(index => 178);
    ok($r == 0 && $g == 203 && $b == 51, "check interpolated palette #1 entry #178");
    ($r, $g, $b) = $subject->get(index => 179);
    ok($r == 0 && $g == 207 && $b == 47, "check interpolated palette #1 entry #179");
    ($r, $g, $b) = $subject->get(index => 180);
    ok($r == 0 && $g == 211 && $b == 43, "check interpolated palette #1 entry #180");
    ($r, $g, $b) = $subject->get(index => 181);
    ok($r == 0 && $g == 215 && $b == 39, "check interpolated palette #1 entry #181");
    ($r, $g, $b) = $subject->get(index => 182);
    ok($r == 0 && $g == 219 && $b == 35, "check interpolated palette #1 entry #182");
    ($r, $g, $b) = $subject->get(index => 183);
    ok($r == 0 && $g == 223 && $b == 31, "check interpolated palette #1 entry #183");
    ($r, $g, $b) = $subject->get(index => 184);
    ok($r == 0 && $g == 227 && $b == 27, "check interpolated palette #1 entry #184");
    ($r, $g, $b) = $subject->get(index => 185);
    ok($r == 0 && $g == 231 && $b == 23, "check interpolated palette #1 entry #185");
    ($r, $g, $b) = $subject->get(index => 186);
    ok($r == 0 && $g == 235 && $b == 19, "check interpolated palette #1 entry #186");
    ($r, $g, $b) = $subject->get(index => 187);
    ok($r == 0 && $g == 239 && $b == 15, "check interpolated palette #1 entry #187");
    ($r, $g, $b) = $subject->get(index => 188);
    ok($r == 0 && $g == 243 && $b == 11, "check interpolated palette #1 entry #188");
    ($r, $g, $b) = $subject->get(index => 189);
    ok($r == 0 && $g == 247 && $b == 7, "check interpolated palette #1 entry #189");
    ($r, $g, $b) = $subject->get(index => 190);
    ok($r == 0 && $g == 251 && $b == 3, "check interpolated palette #1 entry #190");
    ($r, $g, $b) = $subject->get(index => 191);
    ok($r == 0 && $g == 255 && $b == 0, "check interpolated palette #1 entry #191");
    ($r, $g, $b) = $subject->get(index => 192);
    ok($r == 3 && $g == 251 && $b == 0, "check interpolated palette #1 entry #192");
    ($r, $g, $b) = $subject->get(index => 193);
    ok($r == 7 && $g == 247 && $b == 0, "check interpolated palette #1 entry #193");
    ($r, $g, $b) = $subject->get(index => 194);
    ok($r == 11 && $g == 243 && $b == 0, "check interpolated palette #1 entry #194");
    ($r, $g, $b) = $subject->get(index => 195);
    ok($r == 15 && $g == 239 && $b == 0, "check interpolated palette #1 entry #195");
    ($r, $g, $b) = $subject->get(index => 196);
    ok($r == 19 && $g == 235 && $b == 0, "check interpolated palette #1 entry #196");
    ($r, $g, $b) = $subject->get(index => 197);
    ok($r == 23 && $g == 231 && $b == 0, "check interpolated palette #1 entry #197");
    ($r, $g, $b) = $subject->get(index => 198);
    ok($r == 27 && $g == 227 && $b == 0, "check interpolated palette #1 entry #198");
    ($r, $g, $b) = $subject->get(index => 199);
    ok($r == 31 && $g == 223 && $b == 0, "check interpolated palette #1 entry #199");
    ($r, $g, $b) = $subject->get(index => 200);
    ok($r == 35 && $g == 219 && $b == 0, "check interpolated palette #1 entry #200");
    ($r, $g, $b) = $subject->get(index => 201);
    ok($r == 39 && $g == 215 && $b == 0, "check interpolated palette #1 entry #201");
    ($r, $g, $b) = $subject->get(index => 202);
    ok($r == 43 && $g == 211 && $b == 0, "check interpolated palette #1 entry #202");
    ($r, $g, $b) = $subject->get(index => 203);
    ok($r == 47 && $g == 207 && $b == 0, "check interpolated palette #1 entry #203");
    ($r, $g, $b) = $subject->get(index => 204);
    ok($r == 51 && $g == 203 && $b == 0, "check interpolated palette #1 entry #204");
    ($r, $g, $b) = $subject->get(index => 205);
    ok($r == 55 && $g == 199 && $b == 0, "check interpolated palette #1 entry #205");
    ($r, $g, $b) = $subject->get(index => 206);
    ok($r == 59 && $g == 195 && $b == 0, "check interpolated palette #1 entry #206");
    ($r, $g, $b) = $subject->get(index => 207);
    ok($r == 63 && $g == 191 && $b == 0, "check interpolated palette #1 entry #207");
    ($r, $g, $b) = $subject->get(index => 208);
    ok($r == 67 && $g == 187 && $b == 0, "check interpolated palette #1 entry #208");
    ($r, $g, $b) = $subject->get(index => 209);
    ok($r == 71 && $g == 183 && $b == 0, "check interpolated palette #1 entry #209");
    ($r, $g, $b) = $subject->get(index => 210);
    ok($r == 75 && $g == 179 && $b == 0, "check interpolated palette #1 entry #210");
    ($r, $g, $b) = $subject->get(index => 211);
    ok($r == 79 && $g == 175 && $b == 0, "check interpolated palette #1 entry #211");
    ($r, $g, $b) = $subject->get(index => 212);
    ok($r == 83 && $g == 171 && $b == 0, "check interpolated palette #1 entry #212");
    ($r, $g, $b) = $subject->get(index => 213);
    ok($r == 87 && $g == 167 && $b == 0, "check interpolated palette #1 entry #213");
    ($r, $g, $b) = $subject->get(index => 214);
    ok($r == 91 && $g == 163 && $b == 0, "check interpolated palette #1 entry #214");
    ($r, $g, $b) = $subject->get(index => 215);
    ok($r == 95 && $g == 159 && $b == 0, "check interpolated palette #1 entry #215");
    ($r, $g, $b) = $subject->get(index => 216);
    ok($r == 99 && $g == 155 && $b == 0, "check interpolated palette #1 entry #216");
    ($r, $g, $b) = $subject->get(index => 217);
    ok($r == 103 && $g == 151 && $b == 0, "check interpolated palette #1 entry #217");
    ($r, $g, $b) = $subject->get(index => 218);
    ok($r == 107 && $g == 147 && $b == 0, "check interpolated palette #1 entry #218");
    ($r, $g, $b) = $subject->get(index => 219);
    ok($r == 111 && $g == 143 && $b == 0, "check interpolated palette #1 entry #219");
    ($r, $g, $b) = $subject->get(index => 220);
    ok($r == 115 && $g == 139 && $b == 0, "check interpolated palette #1 entry #220");
    ($r, $g, $b) = $subject->get(index => 221);
    ok($r == 119 && $g == 135 && $b == 0, "check interpolated palette #1 entry #221");
    ($r, $g, $b) = $subject->get(index => 222);
    ok($r == 123 && $g == 131 && $b == 0, "check interpolated palette #1 entry #222");
    ($r, $g, $b) = $subject->get(index => 223);
    ok($r == 127 && $g == 127 && $b == 0, "check interpolated palette #1 entry #223");
    ($r, $g, $b) = $subject->get(index => 224);
    ok($r == 131 && $g == 123 && $b == 0, "check interpolated palette #1 entry #224");
    ($r, $g, $b) = $subject->get(index => 225);
    ok($r == 135 && $g == 119 && $b == 0, "check interpolated palette #1 entry #225");
    ($r, $g, $b) = $subject->get(index => 226);
    ok($r == 139 && $g == 115 && $b == 0, "check interpolated palette #1 entry #226");
    ($r, $g, $b) = $subject->get(index => 227);
    ok($r == 143 && $g == 111 && $b == 0, "check interpolated palette #1 entry #227");
    ($r, $g, $b) = $subject->get(index => 228);
    ok($r == 147 && $g == 107 && $b == 0, "check interpolated palette #1 entry #228");
    ($r, $g, $b) = $subject->get(index => 229);
    ok($r == 151 && $g == 103 && $b == 0, "check interpolated palette #1 entry #229");
    ($r, $g, $b) = $subject->get(index => 230);
    ok($r == 155 && $g == 99 && $b == 0, "check interpolated palette #1 entry #230");
    ($r, $g, $b) = $subject->get(index => 231);
    ok($r == 159 && $g == 95 && $b == 0, "check interpolated palette #1 entry #231");
    ($r, $g, $b) = $subject->get(index => 232);
    ok($r == 163 && $g == 91 && $b == 0, "check interpolated palette #1 entry #232");
    ($r, $g, $b) = $subject->get(index => 233);
    ok($r == 167 && $g == 87 && $b == 0, "check interpolated palette #1 entry #233");
    ($r, $g, $b) = $subject->get(index => 234);
    ok($r == 171 && $g == 83 && $b == 0, "check interpolated palette #1 entry #234");
    ($r, $g, $b) = $subject->get(index => 235);
    ok($r == 175 && $g == 79 && $b == 0, "check interpolated palette #1 entry #235");
    ($r, $g, $b) = $subject->get(index => 236);
    ok($r == 179 && $g == 75 && $b == 0, "check interpolated palette #1 entry #236");
    ($r, $g, $b) = $subject->get(index => 237);
    ok($r == 183 && $g == 71 && $b == 0, "check interpolated palette #1 entry #237");
    ($r, $g, $b) = $subject->get(index => 238);
    ok($r == 187 && $g == 67 && $b == 0, "check interpolated palette #1 entry #238");
    ($r, $g, $b) = $subject->get(index => 239);
    ok($r == 191 && $g == 63 && $b == 0, "check interpolated palette #1 entry #239");
    ($r, $g, $b) = $subject->get(index => 240);
    ok($r == 195 && $g == 59 && $b == 0, "check interpolated palette #1 entry #240");
    ($r, $g, $b) = $subject->get(index => 241);
    ok($r == 199 && $g == 55 && $b == 0, "check interpolated palette #1 entry #241");
    ($r, $g, $b) = $subject->get(index => 242);
    ok($r == 203 && $g == 51 && $b == 0, "check interpolated palette #1 entry #242");
    ($r, $g, $b) = $subject->get(index => 243);
    ok($r == 207 && $g == 47 && $b == 0, "check interpolated palette #1 entry #243");
    ($r, $g, $b) = $subject->get(index => 244);
    ok($r == 211 && $g == 43 && $b == 0, "check interpolated palette #1 entry #244");
    ($r, $g, $b) = $subject->get(index => 245);
    ok($r == 215 && $g == 39 && $b == 0, "check interpolated palette #1 entry #245");
    ($r, $g, $b) = $subject->get(index => 246);
    ok($r == 219 && $g == 35 && $b == 0, "check interpolated palette #1 entry #246");
    ($r, $g, $b) = $subject->get(index => 247);
    ok($r == 223 && $g == 31 && $b == 0, "check interpolated palette #1 entry #247");
    ($r, $g, $b) = $subject->get(index => 248);
    ok($r == 227 && $g == 27 && $b == 0, "check interpolated palette #1 entry #248");
    ($r, $g, $b) = $subject->get(index => 249);
    ok($r == 231 && $g == 23 && $b == 0, "check interpolated palette #1 entry #249");
    ($r, $g, $b) = $subject->get(index => 250);
    ok($r == 235 && $g == 19 && $b == 0, "check interpolated palette #1 entry #250");
    ($r, $g, $b) = $subject->get(index => 251);
    ok($r == 239 && $g == 15 && $b == 0, "check interpolated palette #1 entry #251");
    ($r, $g, $b) = $subject->get(index => 252);
    ok($r == 243 && $g == 11 && $b == 0, "check interpolated palette #1 entry #252");
    ($r, $g, $b) = $subject->get(index => 253);
    ok($r == 247 && $g == 7 && $b == 0, "check interpolated palette #1 entry #253");
    ($r, $g, $b) = $subject->get(index => 254);
    ok($r == 251 && $g == 3 && $b == 0, "check interpolated palette #1 entry #254");
    ($r, $g, $b) = $subject->get(index => 255);
    ok($r == 255 && $g == 0 && $b == 0, "check interpolated palette #1 entry #255");
}

sub test_clear {
    my $subject = Flame::Palette->new;

    $subject->set(qw(index   0 red 255 green 0 blue   0));
    $subject->set(qw(index 255 red   0 green 0 blue 255));
    $subject->interpolate;
    $subject->clear;

    foreach(0...255) {
	my($r, $g, $b) = $subject->get(index => $_);

	ok($r == 0 && $g == 0 && $b == 0, "check cleared palette entry #$_");
    }
}

sub parse_flame {
    my $subject = Flame::Palette->new;

    open(my $stm, '<', \ '<?xml version="1.0"?>
<otajihuluj>
  <flame name="protos" time="0" size="800 500" center="0 -0.29" scale="325.9" zoom="0.67" oversample="1" filter="0.2" quality="5" batches="1" background="0.0627450980392157 0 0.0627450980392157" brightness="4" gamma="4" vibrancy="1">
    <xform weight="0.5" color="0" symmetry="0" polar="0.79" julia="0.21" coefs="0.849219 -0.053076 0.020621 0.758837 -0.31602 0.024864"/>
    <xform weight="0.5" color="1" symmetry="0" handkerchief="0.01" heart="0.99" ex="1.00" coefs="-0.100845 -0.976602 0.886685 -0.965043 -0.194069 0.495376"/>
    <color index="0" rgb="210 105 30"/>
    <color index="1" rgb="210 105 30"/>
    <color index="2" rgb="210 105 30"/>
    <color index="3" rgb="210 106 31"/>
    <color index="4" rgb="210 106 31"/>
    <color index="5" rgb="210 107 32"/>
    <color index="6" rgb="210 107 32"/>
    <color index="7" rgb="210 108 33"/>
    <color index="8" rgb="210 108 33"/>
    <color index="9" rgb="211 109 33"/>
    <color index="10" rgb="211 109 34"/>
    <color index="11" rgb="211 110 34"/>
    <color index="12" rgb="211 110 35"/>
    <color index="13" rgb="211 111 35"/>
    <color index="14" rgb="211 111 36"/>
    <color index="15" rgb="211 112 36"/>
    <color index="16" rgb="211 112 36"/>
    <color index="17" rgb="212 113 37"/>
    <color index="18" rgb="212 113 37"/>
    <color index="19" rgb="212 114 38"/>
    <color index="20" rgb="212 114 38"/>
    <color index="21" rgb="212 115 39"/>
    <color index="22" rgb="212 115 39"/>
    <color index="23" rgb="212 116 39"/>
    <color index="24" rgb="212 116 40"/>
    <color index="25" rgb="212 117 40"/>
    <color index="26" rgb="213 117 41"/>
    <color index="27" rgb="213 118 41"/>
    <color index="28" rgb="213 118 42"/>
    <color index="29" rgb="213 119 42"/>
    <color index="30" rgb="213 119 42"/>
    <color index="31" rgb="213 120 43"/>
    <color index="32" rgb="213 120 43"/>
    <color index="33" rgb="213 121 44"/>
    <color index="34" rgb="214 121 44"/>
    <color index="35" rgb="214 122 45"/>
    <color index="36" rgb="214 122 45"/>
    <color index="37" rgb="214 123 45"/>
    <color index="38" rgb="214 123 46"/>
    <color index="39" rgb="214 124 46"/>
    <color index="40" rgb="214 124 47"/>
    <color index="41" rgb="214 125 47"/>
    <color index="42" rgb="214 125 48"/>
    <color index="43" rgb="215 126 48"/>
    <color index="44" rgb="215 126 48"/>
    <color index="45" rgb="215 127 49"/>
    <color index="46" rgb="215 127 49"/>
    <color index="47" rgb="215 128 50"/>
    <color index="48" rgb="215 128 50"/>
    <color index="49" rgb="215 129 51"/>
    <color index="50" rgb="215 129 51"/>
    <color index="51" rgb="216 130 52"/>
    <color index="52" rgb="216 130 52"/>
    <color index="53" rgb="216 130 52"/>
    <color index="54" rgb="216 131 53"/>
    <color index="55" rgb="216 131 53"/>
    <color index="56" rgb="216 132 54"/>
    <color index="57" rgb="216 132 54"/>
    <color index="58" rgb="216 133 55"/>
    <color index="59" rgb="216 133 55"/>
    <color index="60" rgb="217 134 55"/>
    <color index="61" rgb="217 134 56"/>
    <color index="62" rgb="217 135 56"/>
    <color index="63" rgb="217 135 57"/>
    <color index="64" rgb="217 136 57"/>
    <color index="65" rgb="217 136 58"/>
    <color index="66" rgb="217 137 58"/>
    <color index="67" rgb="217 137 58"/>
    <color index="68" rgb="218 138 59"/>
    <color index="69" rgb="218 138 59"/>
    <color index="70" rgb="218 139 60"/>
    <color index="71" rgb="218 139 60"/>
    <color index="72" rgb="218 140 61"/>
    <color index="73" rgb="218 140 61"/>
    <color index="74" rgb="218 141 61"/>
    <color index="75" rgb="218 141 62"/>
    <color index="76" rgb="218 142 62"/>
    <color index="77" rgb="219 142 63"/>
    <color index="78" rgb="219 143 63"/>
    <color index="79" rgb="219 143 64"/>
    <color index="80" rgb="219 144 64"/>
    <color index="81" rgb="219 144 64"/>
    <color index="82" rgb="219 145 65"/>
    <color index="83" rgb="219 145 65"/>
    <color index="84" rgb="219 146 66"/>
    <color index="85" rgb="220 146 66"/>
    <color index="86" rgb="220 147 67"/>
    <color index="87" rgb="220 147 67"/>
    <color index="88" rgb="220 148 67"/>
    <color index="89" rgb="220 148 68"/>
    <color index="90" rgb="220 149 68"/>
    <color index="91" rgb="220 149 69"/>
    <color index="92" rgb="220 150 69"/>
    <color index="93" rgb="220 150 70"/>
    <color index="94" rgb="221 151 70"/>
    <color index="95" rgb="221 151 70"/>
    <color index="96" rgb="221 152 71"/>
    <color index="97" rgb="221 152 71"/>
    <color index="98" rgb="221 153 72"/>
    <color index="99" rgb="221 153 72"/>
    <color index="100" rgb="221 154 73"/>
    <color index="101" rgb="221 154 73"/>
    <color index="102" rgb="222 155 74"/>
    <color index="103" rgb="222 155 74"/>
    <color index="104" rgb="222 155 74"/>
    <color index="105" rgb="222 156 75"/>
    <color index="106" rgb="222 156 75"/>
    <color index="107" rgb="222 157 76"/>
    <color index="108" rgb="222 157 76"/>
    <color index="109" rgb="222 158 77"/>
    <color index="110" rgb="222 158 77"/>
    <color index="111" rgb="223 159 77"/>
    <color index="112" rgb="223 159 78"/>
    <color index="113" rgb="223 160 78"/>
    <color index="114" rgb="223 160 79"/>
    <color index="115" rgb="223 161 79"/>
    <color index="116" rgb="223 161 80"/>
    <color index="117" rgb="223 162 80"/>
    <color index="118" rgb="223 162 80"/>
    <color index="119" rgb="224 163 81"/>
    <color index="120" rgb="224 163 81"/>
    <color index="121" rgb="224 164 82"/>
    <color index="122" rgb="224 164 82"/>
    <color index="123" rgb="224 165 83"/>
    <color index="124" rgb="224 165 83"/>
    <color index="125" rgb="224 166 83"/>
    <color index="126" rgb="224 166 84"/>
    <color index="127" rgb="224 167 84"/>
    <color index="128" rgb="225 167 85"/>
    <color index="129" rgb="225 168 85"/>
    <color index="130" rgb="225 168 86"/>
    <color index="131" rgb="225 169 86"/>
    <color index="132" rgb="225 169 86"/>
    <color index="133" rgb="225 170 87"/>
    <color index="134" rgb="225 170 87"/>
    <color index="135" rgb="225 171 88"/>
    <color index="136" rgb="226 171 88"/>
    <color index="137" rgb="226 172 89"/>
    <color index="138" rgb="226 172 89"/>
    <color index="139" rgb="226 173 89"/>
    <color index="140" rgb="226 173 90"/>
    <color index="141" rgb="226 174 90"/>
    <color index="142" rgb="226 174 91"/>
    <color index="143" rgb="226 175 91"/>
    <color index="144" rgb="226 175 92"/>
    <color index="145" rgb="227 176 92"/>
    <color index="146" rgb="227 176 92"/>
    <color index="147" rgb="227 177 93"/>
    <color index="148" rgb="227 177 93"/>
    <color index="149" rgb="227 178 94"/>
    <color index="150" rgb="227 178 94"/>
    <color index="151" rgb="227 179 95"/>
    <color index="152" rgb="227 179 95"/>
    <color index="153" rgb="228 180 96"/>
    <color index="154" rgb="228 180 96"/>
    <color index="155" rgb="228 180 96"/>
    <color index="156" rgb="228 181 97"/>
    <color index="157" rgb="228 181 97"/>
    <color index="158" rgb="228 182 98"/>
    <color index="159" rgb="228 182 98"/>
    <color index="160" rgb="228 183 99"/>
    <color index="161" rgb="228 183 99"/>
    <color index="162" rgb="229 184 99"/>
    <color index="163" rgb="229 184 100"/>
    <color index="164" rgb="229 185 100"/>
    <color index="165" rgb="229 185 101"/>
    <color index="166" rgb="229 186 101"/>
    <color index="167" rgb="229 186 102"/>
    <color index="168" rgb="229 187 102"/>
    <color index="169" rgb="229 187 102"/>
    <color index="170" rgb="230 188 103"/>
    <color index="171" rgb="230 188 103"/>
    <color index="172" rgb="230 189 104"/>
    <color index="173" rgb="230 189 104"/>
    <color index="174" rgb="230 190 105"/>
    <color index="175" rgb="230 190 105"/>
    <color index="176" rgb="230 191 105"/>
    <color index="177" rgb="230 191 106"/>
    <color index="178" rgb="230 192 106"/>
    <color index="179" rgb="231 192 107"/>
    <color index="180" rgb="231 193 107"/>
    <color index="181" rgb="231 193 108"/>
    <color index="182" rgb="231 194 108"/>
    <color index="183" rgb="231 194 108"/>
    <color index="184" rgb="231 195 109"/>
    <color index="185" rgb="231 195 109"/>
    <color index="186" rgb="231 196 110"/>
    <color index="187" rgb="232 196 110"/>
    <color index="188" rgb="232 197 111"/>
    <color index="189" rgb="232 197 111"/>
    <color index="190" rgb="232 198 111"/>
    <color index="191" rgb="232 198 112"/>
    <color index="192" rgb="232 199 112"/>
    <color index="193" rgb="232 199 113"/>
    <color index="194" rgb="232 200 113"/>
    <color index="195" rgb="232 200 114"/>
    <color index="196" rgb="233 201 114"/>
    <color index="197" rgb="233 201 114"/>
    <color index="198" rgb="233 202 115"/>
    <color index="199" rgb="233 202 115"/>
    <color index="200" rgb="233 203 116"/>
    <color index="201" rgb="233 203 116"/>
    <color index="202" rgb="233 204 117"/>
    <color index="203" rgb="233 204 117"/>
    <color index="204" rgb="234 205 118"/>
    <color index="205" rgb="234 205 118"/>
    <color index="206" rgb="234 205 118"/>
    <color index="207" rgb="234 206 119"/>
    <color index="208" rgb="234 206 119"/>
    <color index="209" rgb="234 207 120"/>
    <color index="210" rgb="234 207 120"/>
    <color index="211" rgb="234 208 121"/>
    <color index="212" rgb="234 208 121"/>
    <color index="213" rgb="235 209 121"/>
    <color index="214" rgb="235 209 122"/>
    <color index="215" rgb="235 210 122"/>
    <color index="216" rgb="235 210 123"/>
    <color index="217" rgb="235 211 123"/>
    <color index="218" rgb="235 211 124"/>
    <color index="219" rgb="235 212 124"/>
    <color index="220" rgb="235 212 124"/>
    <color index="221" rgb="236 213 125"/>
    <color index="222" rgb="236 213 125"/>
    <color index="223" rgb="236 214 126"/>
    <color index="224" rgb="236 214 126"/>
    <color index="225" rgb="236 215 127"/>
    <color index="226" rgb="236 215 127"/>
    <color index="227" rgb="236 216 127"/>
    <color index="228" rgb="236 216 128"/>
    <color index="229" rgb="236 217 128"/>
    <color index="230" rgb="237 217 129"/>
    <color index="231" rgb="237 218 129"/>
    <color index="232" rgb="237 218 130"/>
    <color index="233" rgb="237 219 130"/>
    <color index="234" rgb="237 219 130"/>
    <color index="235" rgb="237 220 131"/>
    <color index="236" rgb="237 220 131"/>
    <color index="237" rgb="237 221 132"/>
    <color index="238" rgb="238 221 132"/>
    <color index="239" rgb="238 222 133"/>
    <color index="240" rgb="238 222 133"/>
    <color index="241" rgb="238 223 133"/>
    <color index="242" rgb="238 223 134"/>
    <color index="243" rgb="238 224 134"/>
    <color index="244" rgb="238 224 135"/>
    <color index="245" rgb="238 225 135"/>
    <color index="246" rgb="238 225 136"/>
    <color index="247" rgb="239 226 136"/>
    <color index="248" rgb="239 226 136"/>
    <color index="249" rgb="239 227 137"/>
    <color index="250" rgb="239 227 137"/>
    <color index="251" rgb="239 228 138"/>
    <color index="252" rgb="239 228 138"/>
    <color index="253" rgb="239 229 139"/>
    <color index="254" rgb="239 229 139"/>
    <color index="255" rgb="240 230 140"/>
  </flame>
</otajihuluj>') || die "$!";

    $subject->parse_flame($stm);

    my($r, $g, $b) = $subject->get(index => 0);
    ok($r == 210 && $g == 105 && $b == 30, "check flame parsed palette entry 0");

    ($r, $g, $b) = $subject->get(index => 1);
    ok($r == 210 && $g == 105 && $b == 30, "check flame parsed palette entry 1");

    ($r, $g, $b) = $subject->get(index => 2);
    ok($r == 210 && $g == 105 && $b == 30, "check flame parsed palette entry 2");

    ($r, $g, $b) = $subject->get(index => 3);
    ok($r == 210 && $g == 106 && $b == 31, "check flame parsed palette entry 3");

    ($r, $g, $b) = $subject->get(index => 4);
    ok($r == 210 && $g == 106 && $b == 31, "check flame parsed palette entry 4");

    ($r, $g, $b) = $subject->get(index => 5);
    ok($r == 210 && $g == 107 && $b == 32, "check flame parsed palette entry 5");

    ($r, $g, $b) = $subject->get(index => 6);
    ok($r == 210 && $g == 107 && $b == 32, "check flame parsed palette entry 6");

    ($r, $g, $b) = $subject->get(index => 7);
    ok($r == 210 && $g == 108 && $b == 33, "check flame parsed palette entry 7");

    ($r, $g, $b) = $subject->get(index => 8);
    ok($r == 210 && $g == 108 && $b == 33, "check flame parsed palette entry 8");

    ($r, $g, $b) = $subject->get(index => 9);
    ok($r == 211 && $g == 109 && $b == 33, "check flame parsed palette entry 9");

    ($r, $g, $b) = $subject->get(index => 10);
    ok($r == 211 && $g == 109 && $b == 34, "check flame parsed palette entry 10");

    ($r, $g, $b) = $subject->get(index => 11);
    ok($r == 211 && $g == 110 && $b == 34, "check flame parsed palette entry 11");

    ($r, $g, $b) = $subject->get(index => 12);
    ok($r == 211 && $g == 110 && $b == 35, "check flame parsed palette entry 12");

    ($r, $g, $b) = $subject->get(index => 13);
    ok($r == 211 && $g == 111 && $b == 35, "check flame parsed palette entry 13");

    ($r, $g, $b) = $subject->get(index => 14);
    ok($r == 211 && $g == 111 && $b == 36, "check flame parsed palette entry 14");

    ($r, $g, $b) = $subject->get(index => 15);
    ok($r == 211 && $g == 112 && $b == 36, "check flame parsed palette entry 15");

    ($r, $g, $b) = $subject->get(index => 16);
    ok($r == 211 && $g == 112 && $b == 36, "check flame parsed palette entry 16");

    ($r, $g, $b) = $subject->get(index => 17);
    ok($r == 212 && $g == 113 && $b == 37, "check flame parsed palette entry 17");

    ($r, $g, $b) = $subject->get(index => 18);
    ok($r == 212 && $g == 113 && $b == 37, "check flame parsed palette entry 18");

    ($r, $g, $b) = $subject->get(index => 19);
    ok($r == 212 && $g == 114 && $b == 38, "check flame parsed palette entry 19");

    ($r, $g, $b) = $subject->get(index => 20);
    ok($r == 212 && $g == 114 && $b == 38, "check flame parsed palette entry 20");

    ($r, $g, $b) = $subject->get(index => 21);
    ok($r == 212 && $g == 115 && $b == 39, "check flame parsed palette entry 21");

    ($r, $g, $b) = $subject->get(index => 22);
    ok($r == 212 && $g == 115 && $b == 39, "check flame parsed palette entry 22");

    ($r, $g, $b) = $subject->get(index => 23);
    ok($r == 212 && $g == 116 && $b == 39, "check flame parsed palette entry 23");

    ($r, $g, $b) = $subject->get(index => 24);
    ok($r == 212 && $g == 116 && $b == 40, "check flame parsed palette entry 24");

    ($r, $g, $b) = $subject->get(index => 25);
    ok($r == 212 && $g == 117 && $b == 40, "check flame parsed palette entry 25");

    ($r, $g, $b) = $subject->get(index => 26);
    ok($r == 213 && $g == 117 && $b == 41, "check flame parsed palette entry 26");

    ($r, $g, $b) = $subject->get(index => 27);
    ok($r == 213 && $g == 118 && $b == 41, "check flame parsed palette entry 27");

    ($r, $g, $b) = $subject->get(index => 28);
    ok($r == 213 && $g == 118 && $b == 42, "check flame parsed palette entry 28");

    ($r, $g, $b) = $subject->get(index => 29);
    ok($r == 213 && $g == 119 && $b == 42, "check flame parsed palette entry 29");

    ($r, $g, $b) = $subject->get(index => 30);
    ok($r == 213 && $g == 119 && $b == 42, "check flame parsed palette entry 30");

    ($r, $g, $b) = $subject->get(index => 31);
    ok($r == 213 && $g == 120 && $b == 43, "check flame parsed palette entry 31");

    ($r, $g, $b) = $subject->get(index => 32);
    ok($r == 213 && $g == 120 && $b == 43, "check flame parsed palette entry 32");

    ($r, $g, $b) = $subject->get(index => 33);
    ok($r == 213 && $g == 121 && $b == 44, "check flame parsed palette entry 33");

    ($r, $g, $b) = $subject->get(index => 34);
    ok($r == 214 && $g == 121 && $b == 44, "check flame parsed palette entry 34");

    ($r, $g, $b) = $subject->get(index => 35);
    ok($r == 214 && $g == 122 && $b == 45, "check flame parsed palette entry 35");

    ($r, $g, $b) = $subject->get(index => 36);
    ok($r == 214 && $g == 122 && $b == 45, "check flame parsed palette entry 36");

    ($r, $g, $b) = $subject->get(index => 37);
    ok($r == 214 && $g == 123 && $b == 45, "check flame parsed palette entry 37");

    ($r, $g, $b) = $subject->get(index => 38);
    ok($r == 214 && $g == 123 && $b == 46, "check flame parsed palette entry 38");

    ($r, $g, $b) = $subject->get(index => 39);
    ok($r == 214 && $g == 124 && $b == 46, "check flame parsed palette entry 39");

    ($r, $g, $b) = $subject->get(index => 40);
    ok($r == 214 && $g == 124 && $b == 47, "check flame parsed palette entry 40");

    ($r, $g, $b) = $subject->get(index => 41);
    ok($r == 214 && $g == 125 && $b == 47, "check flame parsed palette entry 41");

    ($r, $g, $b) = $subject->get(index => 42);
    ok($r == 214 && $g == 125 && $b == 48, "check flame parsed palette entry 42");

    ($r, $g, $b) = $subject->get(index => 43);
    ok($r == 215 && $g == 126 && $b == 48, "check flame parsed palette entry 43");

    ($r, $g, $b) = $subject->get(index => 44);
    ok($r == 215 && $g == 126 && $b == 48, "check flame parsed palette entry 44");

    ($r, $g, $b) = $subject->get(index => 45);
    ok($r == 215 && $g == 127 && $b == 49, "check flame parsed palette entry 45");

    ($r, $g, $b) = $subject->get(index => 46);
    ok($r == 215 && $g == 127 && $b == 49, "check flame parsed palette entry 46");

    ($r, $g, $b) = $subject->get(index => 47);
    ok($r == 215 && $g == 128 && $b == 50, "check flame parsed palette entry 47");

    ($r, $g, $b) = $subject->get(index => 48);
    ok($r == 215 && $g == 128 && $b == 50, "check flame parsed palette entry 48");

    ($r, $g, $b) = $subject->get(index => 49);
    ok($r == 215 && $g == 129 && $b == 51, "check flame parsed palette entry 49");

    ($r, $g, $b) = $subject->get(index => 50);
    ok($r == 215 && $g == 129 && $b == 51, "check flame parsed palette entry 50");

    ($r, $g, $b) = $subject->get(index => 51);
    ok($r == 216 && $g == 130 && $b == 52, "check flame parsed palette entry 51");

    ($r, $g, $b) = $subject->get(index => 52);
    ok($r == 216 && $g == 130 && $b == 52, "check flame parsed palette entry 52");

    ($r, $g, $b) = $subject->get(index => 53);
    ok($r == 216 && $g == 130 && $b == 52, "check flame parsed palette entry 53");

    ($r, $g, $b) = $subject->get(index => 54);
    ok($r == 216 && $g == 131 && $b == 53, "check flame parsed palette entry 54");

    ($r, $g, $b) = $subject->get(index => 55);
    ok($r == 216 && $g == 131 && $b == 53, "check flame parsed palette entry 55");

    ($r, $g, $b) = $subject->get(index => 56);
    ok($r == 216 && $g == 132 && $b == 54, "check flame parsed palette entry 56");

    ($r, $g, $b) = $subject->get(index => 57);
    ok($r == 216 && $g == 132 && $b == 54, "check flame parsed palette entry 57");

    ($r, $g, $b) = $subject->get(index => 58);
    ok($r == 216 && $g == 133 && $b == 55, "check flame parsed palette entry 58");

    ($r, $g, $b) = $subject->get(index => 59);
    ok($r == 216 && $g == 133 && $b == 55, "check flame parsed palette entry 59");

    ($r, $g, $b) = $subject->get(index => 60);
    ok($r == 217 && $g == 134 && $b == 55, "check flame parsed palette entry 60");

    ($r, $g, $b) = $subject->get(index => 61);
    ok($r == 217 && $g == 134 && $b == 56, "check flame parsed palette entry 61");

    ($r, $g, $b) = $subject->get(index => 62);
    ok($r == 217 && $g == 135 && $b == 56, "check flame parsed palette entry 62");

    ($r, $g, $b) = $subject->get(index => 63);
    ok($r == 217 && $g == 135 && $b == 57, "check flame parsed palette entry 63");

    ($r, $g, $b) = $subject->get(index => 64);
    ok($r == 217 && $g == 136 && $b == 57, "check flame parsed palette entry 64");

    ($r, $g, $b) = $subject->get(index => 65);
    ok($r == 217 && $g == 136 && $b == 58, "check flame parsed palette entry 65");

    ($r, $g, $b) = $subject->get(index => 66);
    ok($r == 217 && $g == 137 && $b == 58, "check flame parsed palette entry 66");

    ($r, $g, $b) = $subject->get(index => 67);
    ok($r == 217 && $g == 137 && $b == 58, "check flame parsed palette entry 67");

    ($r, $g, $b) = $subject->get(index => 68);
    ok($r == 218 && $g == 138 && $b == 59, "check flame parsed palette entry 68");

    ($r, $g, $b) = $subject->get(index => 69);
    ok($r == 218 && $g == 138 && $b == 59, "check flame parsed palette entry 69");

    ($r, $g, $b) = $subject->get(index => 70);
    ok($r == 218 && $g == 139 && $b == 60, "check flame parsed palette entry 70");

    ($r, $g, $b) = $subject->get(index => 71);
    ok($r == 218 && $g == 139 && $b == 60, "check flame parsed palette entry 71");

    ($r, $g, $b) = $subject->get(index => 72);
    ok($r == 218 && $g == 140 && $b == 61, "check flame parsed palette entry 72");

    ($r, $g, $b) = $subject->get(index => 73);
    ok($r == 218 && $g == 140 && $b == 61, "check flame parsed palette entry 73");

    ($r, $g, $b) = $subject->get(index => 74);
    ok($r == 218 && $g == 141 && $b == 61, "check flame parsed palette entry 74");

    ($r, $g, $b) = $subject->get(index => 75);
    ok($r == 218 && $g == 141 && $b == 62, "check flame parsed palette entry 75");

    ($r, $g, $b) = $subject->get(index => 76);
    ok($r == 218 && $g == 142 && $b == 62, "check flame parsed palette entry 76");

    ($r, $g, $b) = $subject->get(index => 77);
    ok($r == 219 && $g == 142 && $b == 63, "check flame parsed palette entry 77");

    ($r, $g, $b) = $subject->get(index => 78);
    ok($r == 219 && $g == 143 && $b == 63, "check flame parsed palette entry 78");

    ($r, $g, $b) = $subject->get(index => 79);
    ok($r == 219 && $g == 143 && $b == 64, "check flame parsed palette entry 79");

    ($r, $g, $b) = $subject->get(index => 80);
    ok($r == 219 && $g == 144 && $b == 64, "check flame parsed palette entry 80");

    ($r, $g, $b) = $subject->get(index => 81);
    ok($r == 219 && $g == 144 && $b == 64, "check flame parsed palette entry 81");

    ($r, $g, $b) = $subject->get(index => 82);
    ok($r == 219 && $g == 145 && $b == 65, "check flame parsed palette entry 82");

    ($r, $g, $b) = $subject->get(index => 83);
    ok($r == 219 && $g == 145 && $b == 65, "check flame parsed palette entry 83");

    ($r, $g, $b) = $subject->get(index => 84);
    ok($r == 219 && $g == 146 && $b == 66, "check flame parsed palette entry 84");

    ($r, $g, $b) = $subject->get(index => 85);
    ok($r == 220 && $g == 146 && $b == 66, "check flame parsed palette entry 85");

    ($r, $g, $b) = $subject->get(index => 86);
    ok($r == 220 && $g == 147 && $b == 67, "check flame parsed palette entry 86");

    ($r, $g, $b) = $subject->get(index => 87);
    ok($r == 220 && $g == 147 && $b == 67, "check flame parsed palette entry 87");

    ($r, $g, $b) = $subject->get(index => 88);
    ok($r == 220 && $g == 148 && $b == 67, "check flame parsed palette entry 88");

    ($r, $g, $b) = $subject->get(index => 89);
    ok($r == 220 && $g == 148 && $b == 68, "check flame parsed palette entry 89");

    ($r, $g, $b) = $subject->get(index => 90);
    ok($r == 220 && $g == 149 && $b == 68, "check flame parsed palette entry 90");

    ($r, $g, $b) = $subject->get(index => 91);
    ok($r == 220 && $g == 149 && $b == 69, "check flame parsed palette entry 91");

    ($r, $g, $b) = $subject->get(index => 92);
    ok($r == 220 && $g == 150 && $b == 69, "check flame parsed palette entry 92");

    ($r, $g, $b) = $subject->get(index => 93);
    ok($r == 220 && $g == 150 && $b == 70, "check flame parsed palette entry 93");

    ($r, $g, $b) = $subject->get(index => 94);
    ok($r == 221 && $g == 151 && $b == 70, "check flame parsed palette entry 94");

    ($r, $g, $b) = $subject->get(index => 95);
    ok($r == 221 && $g == 151 && $b == 70, "check flame parsed palette entry 95");

    ($r, $g, $b) = $subject->get(index => 96);
    ok($r == 221 && $g == 152 && $b == 71, "check flame parsed palette entry 96");

    ($r, $g, $b) = $subject->get(index => 97);
    ok($r == 221 && $g == 152 && $b == 71, "check flame parsed palette entry 97");

    ($r, $g, $b) = $subject->get(index => 98);
    ok($r == 221 && $g == 153 && $b == 72, "check flame parsed palette entry 98");

    ($r, $g, $b) = $subject->get(index => 99);
    ok($r == 221 && $g == 153 && $b == 72, "check flame parsed palette entry 99");

    ($r, $g, $b) = $subject->get(index => 100);
    ok($r == 221 && $g == 154 && $b == 73, "check flame parsed palette entry 100");

    ($r, $g, $b) = $subject->get(index => 101);
    ok($r == 221 && $g == 154 && $b == 73, "check flame parsed palette entry 101");

    ($r, $g, $b) = $subject->get(index => 102);
    ok($r == 222 && $g == 155 && $b == 74, "check flame parsed palette entry 102");

    ($r, $g, $b) = $subject->get(index => 103);
    ok($r == 222 && $g == 155 && $b == 74, "check flame parsed palette entry 103");

    ($r, $g, $b) = $subject->get(index => 104);
    ok($r == 222 && $g == 155 && $b == 74, "check flame parsed palette entry 104");

    ($r, $g, $b) = $subject->get(index => 105);
    ok($r == 222 && $g == 156 && $b == 75, "check flame parsed palette entry 105");

    ($r, $g, $b) = $subject->get(index => 106);
    ok($r == 222 && $g == 156 && $b == 75, "check flame parsed palette entry 106");

    ($r, $g, $b) = $subject->get(index => 107);
    ok($r == 222 && $g == 157 && $b == 76, "check flame parsed palette entry 107");

    ($r, $g, $b) = $subject->get(index => 108);
    ok($r == 222 && $g == 157 && $b == 76, "check flame parsed palette entry 108");

    ($r, $g, $b) = $subject->get(index => 109);
    ok($r == 222 && $g == 158 && $b == 77, "check flame parsed palette entry 109");

    ($r, $g, $b) = $subject->get(index => 110);
    ok($r == 222 && $g == 158 && $b == 77, "check flame parsed palette entry 110");

    ($r, $g, $b) = $subject->get(index => 111);
    ok($r == 223 && $g == 159 && $b == 77, "check flame parsed palette entry 111");

    ($r, $g, $b) = $subject->get(index => 112);
    ok($r == 223 && $g == 159 && $b == 78, "check flame parsed palette entry 112");

    ($r, $g, $b) = $subject->get(index => 113);
    ok($r == 223 && $g == 160 && $b == 78, "check flame parsed palette entry 113");

    ($r, $g, $b) = $subject->get(index => 114);
    ok($r == 223 && $g == 160 && $b == 79, "check flame parsed palette entry 114");

    ($r, $g, $b) = $subject->get(index => 115);
    ok($r == 223 && $g == 161 && $b == 79, "check flame parsed palette entry 115");

    ($r, $g, $b) = $subject->get(index => 116);
    ok($r == 223 && $g == 161 && $b == 80, "check flame parsed palette entry 116");

    ($r, $g, $b) = $subject->get(index => 117);
    ok($r == 223 && $g == 162 && $b == 80, "check flame parsed palette entry 117");

    ($r, $g, $b) = $subject->get(index => 118);
    ok($r == 223 && $g == 162 && $b == 80, "check flame parsed palette entry 118");

    ($r, $g, $b) = $subject->get(index => 119);
    ok($r == 224 && $g == 163 && $b == 81, "check flame parsed palette entry 119");

    ($r, $g, $b) = $subject->get(index => 120);
    ok($r == 224 && $g == 163 && $b == 81, "check flame parsed palette entry 120");

    ($r, $g, $b) = $subject->get(index => 121);
    ok($r == 224 && $g == 164 && $b == 82, "check flame parsed palette entry 121");

    ($r, $g, $b) = $subject->get(index => 122);
    ok($r == 224 && $g == 164 && $b == 82, "check flame parsed palette entry 122");

    ($r, $g, $b) = $subject->get(index => 123);
    ok($r == 224 && $g == 165 && $b == 83, "check flame parsed palette entry 123");

    ($r, $g, $b) = $subject->get(index => 124);
    ok($r == 224 && $g == 165 && $b == 83, "check flame parsed palette entry 124");

    ($r, $g, $b) = $subject->get(index => 125);
    ok($r == 224 && $g == 166 && $b == 83, "check flame parsed palette entry 125");

    ($r, $g, $b) = $subject->get(index => 126);
    ok($r == 224 && $g == 166 && $b == 84, "check flame parsed palette entry 126");

    ($r, $g, $b) = $subject->get(index => 127);
    ok($r == 224 && $g == 167 && $b == 84, "check flame parsed palette entry 127");

    ($r, $g, $b) = $subject->get(index => 128);
    ok($r == 225 && $g == 167 && $b == 85, "check flame parsed palette entry 128");

    ($r, $g, $b) = $subject->get(index => 129);
    ok($r == 225 && $g == 168 && $b == 85, "check flame parsed palette entry 129");

    ($r, $g, $b) = $subject->get(index => 130);
    ok($r == 225 && $g == 168 && $b == 86, "check flame parsed palette entry 130");

    ($r, $g, $b) = $subject->get(index => 131);
    ok($r == 225 && $g == 169 && $b == 86, "check flame parsed palette entry 131");

    ($r, $g, $b) = $subject->get(index => 132);
    ok($r == 225 && $g == 169 && $b == 86, "check flame parsed palette entry 132");

    ($r, $g, $b) = $subject->get(index => 133);
    ok($r == 225 && $g == 170 && $b == 87, "check flame parsed palette entry 133");

    ($r, $g, $b) = $subject->get(index => 134);
    ok($r == 225 && $g == 170 && $b == 87, "check flame parsed palette entry 134");

    ($r, $g, $b) = $subject->get(index => 135);
    ok($r == 225 && $g == 171 && $b == 88, "check flame parsed palette entry 135");

    ($r, $g, $b) = $subject->get(index => 136);
    ok($r == 226 && $g == 171 && $b == 88, "check flame parsed palette entry 136");

    ($r, $g, $b) = $subject->get(index => 137);
    ok($r == 226 && $g == 172 && $b == 89, "check flame parsed palette entry 137");

    ($r, $g, $b) = $subject->get(index => 138);
    ok($r == 226 && $g == 172 && $b == 89, "check flame parsed palette entry 138");

    ($r, $g, $b) = $subject->get(index => 139);
    ok($r == 226 && $g == 173 && $b == 89, "check flame parsed palette entry 139");

    ($r, $g, $b) = $subject->get(index => 140);
    ok($r == 226 && $g == 173 && $b == 90, "check flame parsed palette entry 140");

    ($r, $g, $b) = $subject->get(index => 141);
    ok($r == 226 && $g == 174 && $b == 90, "check flame parsed palette entry 141");

    ($r, $g, $b) = $subject->get(index => 142);
    ok($r == 226 && $g == 174 && $b == 91, "check flame parsed palette entry 142");

    ($r, $g, $b) = $subject->get(index => 143);
    ok($r == 226 && $g == 175 && $b == 91, "check flame parsed palette entry 143");

    ($r, $g, $b) = $subject->get(index => 144);
    ok($r == 226 && $g == 175 && $b == 92, "check flame parsed palette entry 144");

    ($r, $g, $b) = $subject->get(index => 145);
    ok($r == 227 && $g == 176 && $b == 92, "check flame parsed palette entry 145");

    ($r, $g, $b) = $subject->get(index => 146);
    ok($r == 227 && $g == 176 && $b == 92, "check flame parsed palette entry 146");

    ($r, $g, $b) = $subject->get(index => 147);
    ok($r == 227 && $g == 177 && $b == 93, "check flame parsed palette entry 147");

    ($r, $g, $b) = $subject->get(index => 148);
    ok($r == 227 && $g == 177 && $b == 93, "check flame parsed palette entry 148");

    ($r, $g, $b) = $subject->get(index => 149);
    ok($r == 227 && $g == 178 && $b == 94, "check flame parsed palette entry 149");

    ($r, $g, $b) = $subject->get(index => 150);
    ok($r == 227 && $g == 178 && $b == 94, "check flame parsed palette entry 150");

    ($r, $g, $b) = $subject->get(index => 151);
    ok($r == 227 && $g == 179 && $b == 95, "check flame parsed palette entry 151");

    ($r, $g, $b) = $subject->get(index => 152);
    ok($r == 227 && $g == 179 && $b == 95, "check flame parsed palette entry 152");

    ($r, $g, $b) = $subject->get(index => 153);
    ok($r == 228 && $g == 180 && $b == 96, "check flame parsed palette entry 153");

    ($r, $g, $b) = $subject->get(index => 154);
    ok($r == 228 && $g == 180 && $b == 96, "check flame parsed palette entry 154");

    ($r, $g, $b) = $subject->get(index => 155);
    ok($r == 228 && $g == 180 && $b == 96, "check flame parsed palette entry 155");

    ($r, $g, $b) = $subject->get(index => 156);
    ok($r == 228 && $g == 181 && $b == 97, "check flame parsed palette entry 156");

    ($r, $g, $b) = $subject->get(index => 157);
    ok($r == 228 && $g == 181 && $b == 97, "check flame parsed palette entry 157");

    ($r, $g, $b) = $subject->get(index => 158);
    ok($r == 228 && $g == 182 && $b == 98, "check flame parsed palette entry 158");

    ($r, $g, $b) = $subject->get(index => 159);
    ok($r == 228 && $g == 182 && $b == 98, "check flame parsed palette entry 159");

    ($r, $g, $b) = $subject->get(index => 160);
    ok($r == 228 && $g == 183 && $b == 99, "check flame parsed palette entry 160");

    ($r, $g, $b) = $subject->get(index => 161);
    ok($r == 228 && $g == 183 && $b == 99, "check flame parsed palette entry 161");

    ($r, $g, $b) = $subject->get(index => 162);
    ok($r == 229 && $g == 184 && $b == 99, "check flame parsed palette entry 162");

    ($r, $g, $b) = $subject->get(index => 163);
    ok($r == 229 && $g == 184 && $b == 100, "check flame parsed palette entry 163");

    ($r, $g, $b) = $subject->get(index => 164);
    ok($r == 229 && $g == 185 && $b == 100, "check flame parsed palette entry 164");

    ($r, $g, $b) = $subject->get(index => 165);
    ok($r == 229 && $g == 185 && $b == 101, "check flame parsed palette entry 165");

    ($r, $g, $b) = $subject->get(index => 166);
    ok($r == 229 && $g == 186 && $b == 101, "check flame parsed palette entry 166");

    ($r, $g, $b) = $subject->get(index => 167);
    ok($r == 229 && $g == 186 && $b == 102, "check flame parsed palette entry 167");

    ($r, $g, $b) = $subject->get(index => 168);
    ok($r == 229 && $g == 187 && $b == 102, "check flame parsed palette entry 168");

    ($r, $g, $b) = $subject->get(index => 169);
    ok($r == 229 && $g == 187 && $b == 102, "check flame parsed palette entry 169");

    ($r, $g, $b) = $subject->get(index => 170);
    ok($r == 230 && $g == 188 && $b == 103, "check flame parsed palette entry 170");

    ($r, $g, $b) = $subject->get(index => 171);
    ok($r == 230 && $g == 188 && $b == 103, "check flame parsed palette entry 171");

    ($r, $g, $b) = $subject->get(index => 172);
    ok($r == 230 && $g == 189 && $b == 104, "check flame parsed palette entry 172");

    ($r, $g, $b) = $subject->get(index => 173);
    ok($r == 230 && $g == 189 && $b == 104, "check flame parsed palette entry 173");

    ($r, $g, $b) = $subject->get(index => 174);
    ok($r == 230 && $g == 190 && $b == 105, "check flame parsed palette entry 174");

    ($r, $g, $b) = $subject->get(index => 175);
    ok($r == 230 && $g == 190 && $b == 105, "check flame parsed palette entry 175");

    ($r, $g, $b) = $subject->get(index => 176);
    ok($r == 230 && $g == 191 && $b == 105, "check flame parsed palette entry 176");

    ($r, $g, $b) = $subject->get(index => 177);
    ok($r == 230 && $g == 191 && $b == 106, "check flame parsed palette entry 177");

    ($r, $g, $b) = $subject->get(index => 178);
    ok($r == 230 && $g == 192 && $b == 106, "check flame parsed palette entry 178");

    ($r, $g, $b) = $subject->get(index => 179);
    ok($r == 231 && $g == 192 && $b == 107, "check flame parsed palette entry 179");

    ($r, $g, $b) = $subject->get(index => 180);
    ok($r == 231 && $g == 193 && $b == 107, "check flame parsed palette entry 180");

    ($r, $g, $b) = $subject->get(index => 181);
    ok($r == 231 && $g == 193 && $b == 108, "check flame parsed palette entry 181");

    ($r, $g, $b) = $subject->get(index => 182);
    ok($r == 231 && $g == 194 && $b == 108, "check flame parsed palette entry 182");

    ($r, $g, $b) = $subject->get(index => 183);
    ok($r == 231 && $g == 194 && $b == 108, "check flame parsed palette entry 183");

    ($r, $g, $b) = $subject->get(index => 184);
    ok($r == 231 && $g == 195 && $b == 109, "check flame parsed palette entry 184");

    ($r, $g, $b) = $subject->get(index => 185);
    ok($r == 231 && $g == 195 && $b == 109, "check flame parsed palette entry 185");

    ($r, $g, $b) = $subject->get(index => 186);
    ok($r == 231 && $g == 196 && $b == 110, "check flame parsed palette entry 186");

    ($r, $g, $b) = $subject->get(index => 187);
    ok($r == 232 && $g == 196 && $b == 110, "check flame parsed palette entry 187");

    ($r, $g, $b) = $subject->get(index => 188);
    ok($r == 232 && $g == 197 && $b == 111, "check flame parsed palette entry 188");

    ($r, $g, $b) = $subject->get(index => 189);
    ok($r == 232 && $g == 197 && $b == 111, "check flame parsed palette entry 189");

    ($r, $g, $b) = $subject->get(index => 190);
    ok($r == 232 && $g == 198 && $b == 111, "check flame parsed palette entry 190");

    ($r, $g, $b) = $subject->get(index => 191);
    ok($r == 232 && $g == 198 && $b == 112, "check flame parsed palette entry 191");

    ($r, $g, $b) = $subject->get(index => 192);
    ok($r == 232 && $g == 199 && $b == 112, "check flame parsed palette entry 192");

    ($r, $g, $b) = $subject->get(index => 193);
    ok($r == 232 && $g == 199 && $b == 113, "check flame parsed palette entry 193");

    ($r, $g, $b) = $subject->get(index => 194);
    ok($r == 232 && $g == 200 && $b == 113, "check flame parsed palette entry 194");

    ($r, $g, $b) = $subject->get(index => 195);
    ok($r == 232 && $g == 200 && $b == 114, "check flame parsed palette entry 195");

    ($r, $g, $b) = $subject->get(index => 196);
    ok($r == 233 && $g == 201 && $b == 114, "check flame parsed palette entry 196");

    ($r, $g, $b) = $subject->get(index => 197);
    ok($r == 233 && $g == 201 && $b == 114, "check flame parsed palette entry 197");

    ($r, $g, $b) = $subject->get(index => 198);
    ok($r == 233 && $g == 202 && $b == 115, "check flame parsed palette entry 198");

    ($r, $g, $b) = $subject->get(index => 199);
    ok($r == 233 && $g == 202 && $b == 115, "check flame parsed palette entry 199");

    ($r, $g, $b) = $subject->get(index => 200);
    ok($r == 233 && $g == 203 && $b == 116, "check flame parsed palette entry 200");

    ($r, $g, $b) = $subject->get(index => 201);
    ok($r == 233 && $g == 203 && $b == 116, "check flame parsed palette entry 201");

    ($r, $g, $b) = $subject->get(index => 202);
    ok($r == 233 && $g == 204 && $b == 117, "check flame parsed palette entry 202");

    ($r, $g, $b) = $subject->get(index => 203);
    ok($r == 233 && $g == 204 && $b == 117, "check flame parsed palette entry 203");

    ($r, $g, $b) = $subject->get(index => 204);
    ok($r == 234 && $g == 205 && $b == 118, "check flame parsed palette entry 204");

    ($r, $g, $b) = $subject->get(index => 205);
    ok($r == 234 && $g == 205 && $b == 118, "check flame parsed palette entry 205");

    ($r, $g, $b) = $subject->get(index => 206);
    ok($r == 234 && $g == 205 && $b == 118, "check flame parsed palette entry 206");

    ($r, $g, $b) = $subject->get(index => 207);
    ok($r == 234 && $g == 206 && $b == 119, "check flame parsed palette entry 207");

    ($r, $g, $b) = $subject->get(index => 208);
    ok($r == 234 && $g == 206 && $b == 119, "check flame parsed palette entry 208");

    ($r, $g, $b) = $subject->get(index => 209);
    ok($r == 234 && $g == 207 && $b == 120, "check flame parsed palette entry 209");

    ($r, $g, $b) = $subject->get(index => 210);
    ok($r == 234 && $g == 207 && $b == 120, "check flame parsed palette entry 210");

    ($r, $g, $b) = $subject->get(index => 211);
    ok($r == 234 && $g == 208 && $b == 121, "check flame parsed palette entry 211");

    ($r, $g, $b) = $subject->get(index => 212);
    ok($r == 234 && $g == 208 && $b == 121, "check flame parsed palette entry 212");

    ($r, $g, $b) = $subject->get(index => 213);
    ok($r == 235 && $g == 209 && $b == 121, "check flame parsed palette entry 213");

    ($r, $g, $b) = $subject->get(index => 214);
    ok($r == 235 && $g == 209 && $b == 122, "check flame parsed palette entry 214");

    ($r, $g, $b) = $subject->get(index => 215);
    ok($r == 235 && $g == 210 && $b == 122, "check flame parsed palette entry 215");

    ($r, $g, $b) = $subject->get(index => 216);
    ok($r == 235 && $g == 210 && $b == 123, "check flame parsed palette entry 216");

    ($r, $g, $b) = $subject->get(index => 217);
    ok($r == 235 && $g == 211 && $b == 123, "check flame parsed palette entry 217");

    ($r, $g, $b) = $subject->get(index => 218);
    ok($r == 235 && $g == 211 && $b == 124, "check flame parsed palette entry 218");

    ($r, $g, $b) = $subject->get(index => 219);
    ok($r == 235 && $g == 212 && $b == 124, "check flame parsed palette entry 219");

    ($r, $g, $b) = $subject->get(index => 220);
    ok($r == 235 && $g == 212 && $b == 124, "check flame parsed palette entry 220");

    ($r, $g, $b) = $subject->get(index => 221);
    ok($r == 236 && $g == 213 && $b == 125, "check flame parsed palette entry 221");

    ($r, $g, $b) = $subject->get(index => 222);
    ok($r == 236 && $g == 213 && $b == 125, "check flame parsed palette entry 222");

    ($r, $g, $b) = $subject->get(index => 223);
    ok($r == 236 && $g == 214 && $b == 126, "check flame parsed palette entry 223");

    ($r, $g, $b) = $subject->get(index => 224);
    ok($r == 236 && $g == 214 && $b == 126, "check flame parsed palette entry 224");

    ($r, $g, $b) = $subject->get(index => 225);
    ok($r == 236 && $g == 215 && $b == 127, "check flame parsed palette entry 225");

    ($r, $g, $b) = $subject->get(index => 226);
    ok($r == 236 && $g == 215 && $b == 127, "check flame parsed palette entry 226");

    ($r, $g, $b) = $subject->get(index => 227);
    ok($r == 236 && $g == 216 && $b == 127, "check flame parsed palette entry 227");

    ($r, $g, $b) = $subject->get(index => 228);
    ok($r == 236 && $g == 216 && $b == 128, "check flame parsed palette entry 228");

    ($r, $g, $b) = $subject->get(index => 229);
    ok($r == 236 && $g == 217 && $b == 128, "check flame parsed palette entry 229");

    ($r, $g, $b) = $subject->get(index => 230);
    ok($r == 237 && $g == 217 && $b == 129, "check flame parsed palette entry 230");

    ($r, $g, $b) = $subject->get(index => 231);
    ok($r == 237 && $g == 218 && $b == 129, "check flame parsed palette entry 231");

    ($r, $g, $b) = $subject->get(index => 232);
    ok($r == 237 && $g == 218 && $b == 130, "check flame parsed palette entry 232");

    ($r, $g, $b) = $subject->get(index => 233);
    ok($r == 237 && $g == 219 && $b == 130, "check flame parsed palette entry 233");

    ($r, $g, $b) = $subject->get(index => 234);
    ok($r == 237 && $g == 219 && $b == 130, "check flame parsed palette entry 234");

    ($r, $g, $b) = $subject->get(index => 235);
    ok($r == 237 && $g == 220 && $b == 131, "check flame parsed palette entry 235");

    ($r, $g, $b) = $subject->get(index => 236);
    ok($r == 237 && $g == 220 && $b == 131, "check flame parsed palette entry 236");

    ($r, $g, $b) = $subject->get(index => 237);
    ok($r == 237 && $g == 221 && $b == 132, "check flame parsed palette entry 237");

    ($r, $g, $b) = $subject->get(index => 238);
    ok($r == 238 && $g == 221 && $b == 132, "check flame parsed palette entry 238");

    ($r, $g, $b) = $subject->get(index => 239);
    ok($r == 238 && $g == 222 && $b == 133, "check flame parsed palette entry 239");

    ($r, $g, $b) = $subject->get(index => 240);
    ok($r == 238 && $g == 222 && $b == 133, "check flame parsed palette entry 240");

    ($r, $g, $b) = $subject->get(index => 241);
    ok($r == 238 && $g == 223 && $b == 133, "check flame parsed palette entry 241");

    ($r, $g, $b) = $subject->get(index => 242);
    ok($r == 238 && $g == 223 && $b == 134, "check flame parsed palette entry 242");

    ($r, $g, $b) = $subject->get(index => 243);
    ok($r == 238 && $g == 224 && $b == 134, "check flame parsed palette entry 243");

    ($r, $g, $b) = $subject->get(index => 244);
    ok($r == 238 && $g == 224 && $b == 135, "check flame parsed palette entry 244");

    ($r, $g, $b) = $subject->get(index => 245);
    ok($r == 238 && $g == 225 && $b == 135, "check flame parsed palette entry 245");

    ($r, $g, $b) = $subject->get(index => 246);
    ok($r == 238 && $g == 225 && $b == 136, "check flame parsed palette entry 246");

    ($r, $g, $b) = $subject->get(index => 247);
    ok($r == 239 && $g == 226 && $b == 136, "check flame parsed palette entry 247");

    ($r, $g, $b) = $subject->get(index => 248);
    ok($r == 239 && $g == 226 && $b == 136, "check flame parsed palette entry 248");

    ($r, $g, $b) = $subject->get(index => 249);
    ok($r == 239 && $g == 227 && $b == 137, "check flame parsed palette entry 249");

    ($r, $g, $b) = $subject->get(index => 250);
    ok($r == 239 && $g == 227 && $b == 137, "check flame parsed palette entry 250");

    ($r, $g, $b) = $subject->get(index => 251);
    ok($r == 239 && $g == 228 && $b == 138, "check flame parsed palette entry 251");

    ($r, $g, $b) = $subject->get(index => 252);
    ok($r == 239 && $g == 228 && $b == 138, "check flame parsed palette entry 252");

    ($r, $g, $b) = $subject->get(index => 253);
    ok($r == 239 && $g == 229 && $b == 139, "check flame parsed palette entry 253");

    ($r, $g, $b) = $subject->get(index => 254);
    ok($r == 239 && $g == 229 && $b == 139, "check flame parsed palette entry 254");

    ($r, $g, $b) = $subject->get(index => 255);
    ok($r == 240 && $g == 230 && $b == 140, "check flame parsed palette entry 255");
}

create_empty;
create_gray;
create_red;
do_parse;
unparse_empty;
test_interpol;
test_interpol_multi;
test_clear;
parse_flame;
