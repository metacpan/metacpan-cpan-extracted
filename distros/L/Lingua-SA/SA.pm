package Lingua::SA;

use 5.008;
use strict;
use warnings;
use English qw{-no_match_vars};
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::SA ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	transliterate
	vibhakti
	sandhi
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.08';

# Preloaded methods go here.
###########################################################
sub sandhi{
my ($in)=@_;
$in=~s/ \+ ([^\[])/$1/g;	# replace + and surround spaces with nothing
$in=~s/aa/A/g;				# replace aa with A
$in=~s/ii/I/g;				# replace ii with I
$in=~s/uu/U/g;				# replace uu with U
$in=~s/Ru/R/g;				# replace Ru with R
return $in;
}
###########################################################
sub vibhakti {
####### This is currently only for svaraanta (halant will be 8000+)
# USAGE: my $response=vibhakti({naam=>$noun, vibhakti=>$vibhakti,
# 						linga=>$linga, vachana=>$vachana});

# 2008-06-05 Fixed 3351 and 3361 from inaaH to inaH (v 0.06)

my ($arg_ref) = @_;

confess "Argument naam not passed to vibhakti()" if !defined $arg_ref->{naam};
confess "Argument linga not passed to vibhakti()" if !defined $arg_ref->{linga};
confess "Argument vibhakti not passed to vibhakti()" if !defined $arg_ref->{vibhakti};
confess "Argument vachana not passed to vibhakti()" if !defined $arg_ref->{vachana};

my ( $noun, $vibhakti, $linga, $vachana ) =
		( $arg_ref -> {naam}, $arg_ref -> {vibhakti}, $arg_ref -> {linga},
		$arg_ref -> {vachana});

# The last character of noun is chopped to be aakaar
# (what happens when halant nouns are included?)
$noun = sandhi($noun);
my $aakaar = chop($noun);

$vibhakti = sandhi($vibhakti);
$linga = sandhi($linga);

my %aakaar   = qw(0 0 a 1 A 2 i 3 I 4 u 5 U 6 R 7);
my %linga    = qw(puM 1 strI 2 napuMsaka 3 1 1 2 2 3 3);
my %vachana  = qw(ekavachana 1 dvivachana 2 bahuvachana 3 1 1 2 2 3 3);
my %vibhakti = qw#prathamA 1 dvitIyA 2 tRtIyA 3 chaturthI 4 paJchamI 5
			     	ShaShThI 6 saptamI 7 sambodhana 8
					1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8#;

confess "Unsupported noun supplied to vibhakti(): $noun$aakaar ending in $aakaar"
	if !defined $aakaar{$aakaar};
confess "Invalid linga $linga supplied to vibhakti()"
	if !defined $linga{$linga};
confess "Invalid vibhakti $vibhakti supplied to vibhakti()"
	if !defined $vibhakti{$vibhakti};
confess "Invalid vachana $vachana supplied to vibhakti()"
	if !defined $vachana{$vachana};

# coef for swarAnt nouns range from 1111 to 7373
# with 7 sets of 72 coefs posible (not all taken)
my $coef =
      $aakaar{$aakaar} * 1000 +
      $linga{$linga} * 100 +
      $vibhakti{$vibhakti} * 10 +
      $vachana{$vachana};

#### 1000 through 7000 aakaar. 1=a 2=A 3=i 4=I 5=u 6=U 7=Ru
##### 100 puM 200 strI 300 na
###### 10 through 80 8 vibhakti (8th being sambodhan)
####### 1 through 3 eka, dwi, bahuvachan
## possibilities for nouns are in the following series:
# Masculine:1100,       3100,       5100,       7100 # examples of 2100?
# Feminine:	      2200, 3200, 4200, 5200, 6200, 7200
# Neutar:	1300,       3300,       5300,       7300
# 2100, 4100 exist, but I do not know the examples.
# not sure of 6100, 6300
# 1200, 2300, 4300 do not exist

# These are the noun suffixes
my %ending = qw(

      1111 aH                   1112 au                   1113 AH
      1121 am                   1122 au                   1123 An
      1131 ena                  1132 Abhyaam             1133 aiH
      1141 Aya                 1142 Abhyaam             1143 ebhyaH
      1151 At                  1152 Abhyaam             1153 ebhyaH
      1161 asya                 1162 ayoH                 1163 Anaam
      1171 e                    1172 ayoH                 1173 eSu
      1181 a                    1182 au                   1183 AH

      2111 AH                  2112 au                   2113 AH
      2121 Am                  2122 au                   2123 aH
      2131 A                   2132 Abhyaam             2133 AbhiH
      2141 e                    2142 Abhyaam             2143 AbhyaH
      2151 aH                   2152 Abhyaam             2153 AbhyaH
      2161 aH                   2162 oH                   2163 Am
      2171 i                    2172 oH                   2173 Asu
      2181 Am                  2182 au                   2183 AH

      3111 iH                   3112 I                    3113 ayaH
      3121 im                   3122 I                    3123 In
      3131 inaa                 3132 ibhyaam              3133 ibhiH
      3141 aye                  3142 ibhyaam              3143 ibhyaH
      3151 eH                   3152 ibhyaam              3153 ibhyaH
      3161 eH                   3162 yoH                  3163 Inaam
      3171 au                   3172 yoH                  3173 iSu
      3181 e                    3182 I                    3183 ayaH

      5111 uH                   5112 U                    5113 avaH
      5121 um                   5122 U                    5123 Un
      5131 unaa                 5132 ubhyaam              5133 ubhiH
      5141 ave                  5142 ubhyaam              5143 ubhyaH
      5151 oH                   5152 ubhyaam              5153 ubhyaH
      5161 oH                   5162 voH                  5163 Unaam
      5171 au                   5172 voH                  5173 uSu
      5181 o                    5182 U                    5183 avaH

      7111 A                    7112 Arau                 7113 AraH
      7121 Aram                 7122 Arau                 7123 RRn
      7131 raa                  7132 Rbhyaam             7133 RbhiH
      7141 re                   7142 Rbhyaam             7143 RbhyaH
      7151 uH                   7152 Rbhyaam             7153 RbhyaH
      7161 uH                   7162 roH                  7163 RRNaam
      7171 ari                  7172 roH                  7173 RSu
      7181 aH|ar                7182 Arau                 7183 AraH

      2211 A                   2212 e                    2213 AH
      2221 Am                  2222 e                    2223 AH
      2231 ayaa                 2232 Abhyaam             2233 AbhiH
      2241 Ayai                2242 Abhyaam             2243 AbhyaaH
      2251 AyaaH               2252 Abhyaam             2253 AbhyaaH
      2261 AyaaH               2262 ayoH                 2263 Anaam
      2271 Ayaam               2272 ayoH                 2273 Asu
      2281 e                    2282 e                    2283 AH

      3211 iH                   3212 I                    3213 ayaH
      3221 im                   3222 I                    3223 IH
      3231 yaa                  3232 ibhyaam              3233 ibhiH
      3241 yai|aye              3242 ibhyaam              3243 ibhyaH
      3251 yaaH|eH              3252 ibhyaam              3253 ibhyaH
      3261 yaaH|eH              3262 yoH                  3263 Inaam
      3271 yaam|au              3272 yoH                  3273 iSu
      3281 e                    3282 I                    3283 ayaH

      4211 I                    4212 yau                  4213 yaH
      4221 Im                   4222 yau                  4223 IH
      4231 yaa                  4232 Ibhyaam              4233 IbhiH
      4241 yai                  4242 Ibhyaam              4243 IbhyaH
      4251 yaaH                 4252 Ibhyaam              4253 IbhyaH
      4261 yaaH                 4262 yoH                  4263 Inaam
      4271 yaam                 4272 yoH                  4273 ISu
      4281 i                    4282 yau                  4283 yaH

      5211 uH                   5212 U                    5213 avaH
      5221 um                   5222 U                    5223 UH
      5231 vaa                  5232 ubhyaam              5233 ubhiH
      5241 ave|vai              5242 ubhyaam              5243 ubhyaH
      5251 oH|vaaH              5252 ubhyaam              5253 ubhyaH
      5261 oH|vaaH              5262 voH                  5263 Unaam
      5271 au|vaam              5272 voH                  5273 uSu
      5281 o                    5282 U                    5283 avaH

      6211 UH                   6212 vau                  6213 vaH
      6221 Um                   6222 vau                  6223 UH
      6231 vaa                  6232 Ubhyaam              6233 UbhiH
      6241 vai                  6242 Ubhyaam              6243 UbhyaH
      6251 vaaH                 6252 Ubhyaam              6253 UbhyaH
      6261 vaaH                 6262 voH                  6263 Unaam
      6271 vaam                 6272 voH                  6273 USu
      6281 u                    6282 vau                  6283 vaH

      7211 A                    7212 arau                 7213 araH
      7221 aram                 7222 arau                 7223 RRH
      7231 raa                  7232 Rbhyaam             7233 RbhiH
      7241 re                   7242 Rbhyaam             7243 RbhyaH
      7251 uH                   7252 Rbhyaam             7253 RbhyaH
      7261 uH                   7262 roH                  7263 RRNaam
      7271 ari                  7272 roH                  7273 RSu
      7281 aH|ar                7282 arau                 7283 araH

      1311 am                   1312 e                    1313 Ani
      1321 am                   1322 e                    1323 Ani
      1331 ena                  1332 Abhyaam             1333 aiH
      1341 Aya                 1342 Abhyaam             1343 ebhyaH
      1351 At                  1352 Abhyaam             1353 ebhyaH
      1361 asya                 1362 ayoH                 1363 Anaam
      1371 e                    1372 ayoH                 1373 eSu
      1381 a                    1382 e                    1383 Ani

      3311 i                    3312 inI                  3313 Ini
      3321 i                    3322 inI                  3323 Ini
      3331 inaa                 3332 ibhyaam              3333 ibhiH
      3341 ine                  3342 ibhyaam              3343 ibhyaH
      3351 inaH                3352 ibhyaam              3353 ibhyaH
      3361 inaH                3362 inoH                 3363 Inaam
      3371 ini                  3372 inoH                 3373 iSu
      3381 i|e                  3382 inI                  3383 Ini

      5311 u                    5312 unI                  5313 Uni
      5321 u                    5322 unI                  5323 Uni
      5331 unaa                 5332 ubhyaam              5333 ubhiH
      5341 une                  5342 ubhyaam              5343 ubhyaH
      5351 unaH                 5352 ubhyaam              5353 ubhyaH
      5361 unaH                 5362 unoH                 5363 Unaam
      5371 uni                  5372 unoH                 5373 uSu
      5381 o|u                  5382 unI                  5383 Uni

      7311 R                    7312 RNI                  7313 RRNi
      7321 R                    7322 RNI                  7323 RRNi
      7331 raa|RNA              7332 Rbhyaam             7333 RbhiH
      7341 re|RNe               7342 Rbhyaam             7343 RbhyaH
      7351 uH|RNaH              7352 Rbhyaam             7353 RbhyaH
      7361 uH|RNaH              7362 roH|RNoH             7363 RRNaam
      7371 ari|RNi              7372 roH|RNoH             7373 RSu
      7381 aH|R                 7382 RNI                  7383 RRNi
    );

# Is 3263 above dirgha as stated?	## Yes, it is

confess "$linga nouns ending in $aakaar not supported"
	if !defined $ending{$coef};

###	This part can cater to irregular nouns

# ambA, akkA, allA have a-kaaraant sambodhana
if($noun eq "amb" or $noun eq "akk" or $noun eq "all"){
	$ending{2281} = 'a';
	}

my $endcoef = $ending{$coef};

# Natva results in converting n to N when an r, R, RR, or S are encountered in
# the noun, and the only letters between there and end are what are in Natva
# here (h y v k kh g gh ~N p ph b bh m and a pratyay (aa~N - not implemented)
# Additionally, n can not be halant

my $Natva = "h|y|v|k(h)?|g(h)?|G|p(h)?|b(h)?|m";

#	vowel is as defined in split_word
my $vowel = "(A|H|I|M|R(R|u)?|U|a(a|i|u)?|i(i)?|e|lR|o(M)?|u(u)?|\\:|\\|(\\|)?)";

my $inflected;

###	This part can be expanded to include exceptions/options

if ($noun =~ m/[rRS][$Natva|$vowel]*$/ ) {
        $endcoef =~ s/n([a-zA-Z])/N$1/;	
        }
if ( $endcoef =~ m/\|/ ) {
        my @foo = split( /\|/, $endcoef );
        $inflected = "$noun + $foo[0]";
        for my $counter ( 1 .. $#foo ) {
            $inflected.= " | $noun + $foo[$counter]";
            }
        }
else {
        $inflected = "$noun + $endcoef";
        }
## if sambodhan, prepend he
    if ( $coef % 100 > 80 ) {
        if ( $endcoef =~ m/\|/ ) {
            $inflected = "he \[ $inflected ]";
            }
        else {
            $inflected = "he $inflected";
            }
        }
return $inflected;
} ## end sub vibhakti
###############################
sub transliterate {

# Takes a string as input. Separate it into words.
# Splits each word into syllables, and for each syllable appends its
# unicode to an array that is finally flattened and returned

my ($english) = @_;
my @transliterated;
my @x = split( /\s+/, $english );    # splt input string in to words
for my $x (@x) {    # get unicoded syllables for each word
        push( @transliterated, map( match_code($_), split_word($x) ), " " );
        }
return join( "", @transliterated );   # flatten the array before returning
}
###############################
sub match_code {
    my ($syllable_mcc) = @_;
    my %letter_codes = (
        "~a",  "&#2309;", "~aa", "&#2310;", "~A",  "&#2310;",
        "~i",  "&#2311;", "~ii",  "&#2312;", "~uu",  "&#2314;",
        "ii",  "&#2368;", "~I",  "&#2312;", "~u",  "&#2313;",
        "~U",  "&#2314;", "~R",  "&#2315;", "~Ru", "&#2315;",
        "~lR", "&#2316",  "~RR", "&#2400",  "~e",  "&#2319;",
        "~ai", "&#2320;", "~o",  "&#2323;", "~au", "&#2324;",
        "a",   "",        "aa",  "&#2366;", "A",   "&#2366;",
        "i",   "&#2367;", "I",   "&#2368;", "u",   "&#2369;",
        "uu",   "&#2370;", "R",   "&#2371;", "lR", "&#2402;",
        "e",   "&#2375;", "ai",  "&#2376;",
        "U",   "&#2370;", "R",   "&#2371;", "Ru",  "&#2371;",
        "RR",  "&#2372;", "o",   "&#2379;", "au",  "&#2380;",
        "k",   "&#2325;", "kh",  "&#2326;", "g",   "&#2327;",
        "gh",  "&#2328;", "G",   "&#2329;", "c",   "&#2330;",
        "ch",  "&#2330;", "C",   "&#2331;", "Ch",  "&#2331;",
        "j",   "&#2332;", "jh",  "&#2333;", "J",   "&#2334;",
        "T",   "&#2335;", "Th",  "&#2336;", "D",   "&#2337;",
        "Dh",  "&#2338;", "N",   "&#2339;", "t",   "&#2340;",
        "th",  "&#2341;", "d",   "&#2342;", "dh",  "&#2343;",
        "n",   "&#2344;", "p",   "&#2346;", "ph",  "&#2347;",
        "b",   "&#2348;", "bh",  "&#2349;", "m",   "&#2350;",
        "y",   "&#2351;", "r",   "&#2352;", "l",   "&#2354;",
        "L",   "&#2355;",
        "v",   "&#2357;", "z",   "&#2358;", "sh",  "&#2358;",
        "S",   "&#2359;", "Sh",  "&#2359;", "s",   "&#2360;",
        "h",   "&#2361;", "H",   "&#2307;", ":",   "&#2307;",
        "M",   "&#2306;", "|",   "&#2404;", "||",  "&#2405;",
        "oM",  "&#2384;", "~H",  "&#2307;", "~:",  "&#2307;",
        "~M",  "&#2306;", "~|",  "&#2404;", "~||", "&#2405;",
        "\$",  "&#2365;", "^",  "&#2385;", "_", "&#2386;",
        "`",  "&#2387;", "'",  "&#2388;",  "\@",  "&#2416;", 
        "~oM", "&#2384;", "*",   "&#2381;", "CB", "&#2305;",
    );
# RR 2400 lRR 2401 _lR 2402 _lRR 2403 chandra-bindu 2305
    if ( defined $letter_codes{$syllable_mcc} ) {
        return $letter_codes{$syllable_mcc};
        }
    else {
        return $syllable_mcc;
        }
    } ## end sub match_code
########################################
sub split_word {
    my ($word) = @_;
	# vowels is copied as is in vibhakti
    my $vowels = "(A|H|I|M|R(R|u)?|U|a(a|i|u)?|i(i)?|e|lR|o(M)?|u(u)?|\\:|\\|(\\|)?)";
    my $consonants =
"(C(h|B)?|D(h)?|G|J|N|S(h)?|T(h)?|b(h)?|c(h)?|d(h)?|g(h)?|h|j(h)?|k(h)?|l|m|n|p(h)?|r|s(h)?|t(h)?|v|y|z|L)";
    my @syllables;
    my $vowel_start_p = 1;
    my $matched;
    my $index;
    while ($word) {    # begin out
        unless ( $word =~ m/$vowels/ ) { $index = length($word); }
        else                           { $index = length($`); }
        if ( $index == 0 ) {    # begin 3A
            $matched = $1;
            if ($vowel_start_p) {    # begin 0A
                push( @syllables, "~$matched" );
                }     # end 0A
            else {    # begin 0B
                push( @syllables, $matched );
                }    # end 0B
            $vowel_start_p = 1;
            $word = substr( $word, length($matched) );
            }     # end 3A
        else {    # begin 3B
            unless ( $word =~ m/$consonants/ ) { $index = length($word); }
            else                               { $index = length($`); }
            if ( $index == 0 ) {    # begin 2A
                $matched = $1;
                push( @syllables, $matched );
                $vowel_start_p = 0;
                $word = substr( $word, length($matched) );
                unless ( $word =~ m/$vowels/ ) { $index = length($word); }
                else                           { $index = length($`); }
                if ( $index or length($word) == 0 ) {    # begin 1A
                    push( @syllables, "*" );
                    }     # end 1A
                else {    # begin 1B
                    ;
                    }    # end 1B
                }     # end 2A
            else {    # begin 2B
                push( @syllables, substr( $word, 0, 1 ) );
                $word = substr( $word, 1 );
                }    # end 2B
            }    # end 3B
        }    # end out
    return @syllables;
    } ## end sub split_word
###########################
1;
__END__
# Below is stub documentation for Lingua::SA

=head1 NAME

Lingua::SA - Perl extension for the language Sanskrit

=head1 SYNOPSIS

use Lingua::SA qw(transliterate vibhakti sandhi);

print transliterate("raamaH");

# outputs: &#2352;&#2366;&#2350;&#2307;

=head1 DESCRIPTION

The module exports functions to 
       (1) Obtain declinations of Sanskrit nouns
       (2) Convert Roman into Unicode Sanskrit

print vibhakti({naam=>"raama", vibhakti=>"prathamA",
	linga=>"puM", vachana=>"ekavachana"}),"\n";

# outputs: rAm + aH

print sandhi(vibhakti({naam=>"raama", vibhakti=>"prathamA",
    linga=>"puM", vachana=>"ekavachana"})),"\n";

# outputs: rAmaH

print transliterate(sandhi(vibhakti({naam=>"raama",
	vibhakti=>"prathamA", linga=>"puM",
	vachana=>"ekavachana"}))),"\n";

or,

print transliterate(sandhi(vibhakti({naam=>"raama",
	vibhakti=>1, linga=>1, vachana=>1}))),"\n";

# outputs: &#2352;&#2366;&#2350;&#2307;

=head2 EXPORT

None by default.

The module optionally exports three functions:

(1) transliterate: This takes roman text as input and depicts it in UNICODE
devanAgarI. The character set used is that of Sanskrit. Ideal for use in cgi
scripts.

(2) vibhakti: This returns the declinations of nouns. Takes as input a noun
(naam), a case (vibhakti), a gender (linga) and number/plurality (vachana) and
returns the corresponding declination if the inputs are valid.

The vibhakti has to be one of:
prathamA dvitIyA tRutIyA chaturthI paJchamI ShaShThI saptamI sambodhana 
Alternately, the numbers 1 through 8 are also allowed.

The vachana has to be one of: ekavachana dvivachana bahuvachana or 1 2 3

The linga has to be one of: puM strI napuMsaka  or 1 2 3

The naam has to end in one of: a A i I u U R (aa, ii, uu are internally
converted to A, I, U respectively). Other endings not supported yet.

(3) sandhi: Merely "straightens" the output by doing a few minor operations to
make it look more like a proper "word". In particular, it removes ' + ' from
the "word + inflection" combinations. It also replaces aa with A, ii with I and
uu with U.

=head1 SEE ALSO

Currently write-only mailing list for feedback:
http://groups.google.com/group/sanskrit-module-feedback

You can see the module in operation through various cgi-bin links at:
http://www.astro.caltech.edu/~aam/sanskrit
You will also find there links to other Sanskrit resources including some from
which I have borrowed. You will also find there the transliteration mapping
used.

=head1 AUTHOR

Ashish Mahabal, E<lt>mahabal.ashish@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ashish Mahabal

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
