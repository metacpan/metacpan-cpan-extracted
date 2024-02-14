package Lingua::JA::Moji;

use warnings;
use strict;
use utf8;

require Exporter;
our @ISA = qw(Exporter);

our $VERSION = '0.60';

use Carp 'croak';
use Convert::Moji qw/make_regex length_one unambiguous/;
use JSON::Parse 'read_json';

our @EXPORT_OK = qw/
    InHankakuKatakana
    InKana
    InWideAscii
    ascii2wide
    bad_kanji
    bracketed2kanji
    braille2kana
    circled2kana
    circled2kanji
    cleanup_kana
    cyrillic2katakana
    hangul2kana
    hentai2kana
    hentai2kanji
    hira2kata
    hw2katakana
    is_hiragana
    is_kana
    is_katakana
    is_romaji
    is_romaji_semistrict
    is_romaji_strict
    is_small
    is_voiced
    join_sound_marks
    kana2braille
    kana2circled
    kana2cyrillic
    kana2hangul
    kana2hentai
    kana2hw
    kana2katakana
    kana2morse
    kana2romaji
    kana_consonant
    kana_to_large
    kanji2bracketed
    kanji2circled
    kanji2hentai
    kata2hira
    katakana2hw
    katakana2square
    katakana2syllable
    morse2kana
    new2old_kanji
    nigori_first
    normalize_romaji
    old2new_kanji
    romaji2hiragana
    romaji2kana
    romaji_styles
    romaji_vowel_styles
    smallize_kana
    split_sound_marks
    strip_sound_marks
    square2katakana
    wide2ascii
    yurei_moji
/;

our %EXPORT_TAGS = (
    'all' => \@EXPORT_OK,
);

# Load a specified convertor from the shared directory.

sub load_convertor
{
    my ($in, $out) = @_;
    my $filename = $in."2".$out;
    my $file = getdistfile ($filename);
    if (! $file || ! -f $file) {
	croak "Could not find distribution file '$filename'";
    }
    my $convertor = Convert::Moji::load_convertor ($file);
    return $convertor;
}

sub add_boilerplate
{
    my ($code, $name) = @_;
    $code =<<EOSUB;
sub convert_$name
{
    my (\$conv,\$input,\$convert_type) = \@_;
    $code
    return \$input;
}
EOSUB
    $code .= "\\\&".__PACKAGE__."::convert_$name;";
    return $code;
}

sub ambiguous_reverse
{
    my ($table) = @_;
    my %inverted;
    for (keys %$table) {
	my $val = $table->{$_};
	push @{$inverted{$val}}, $_;
    }
    return \%inverted;
}

# Callback

sub split_match
{
    my ($conv, $input, $convert_type) = @_;
    if (!$convert_type) {
        $convert_type = "all";
    }
    my @input = split '', $input;
    my @output;
    for (@input) {
	my $in = $conv->{out2in}->{$_};
	# No conversion defined.
	if (! $in) {
	    push @output, $_;
	    next;
	}
	# Unambigous case
	if (@{$in} == 1) {
	    push @output, $in->[0];
	    next;
	}
	if ($convert_type eq 'all') {
	    push @output, $in;
	}
        elsif ($convert_type eq 'first') {
	    push @output, $in->[0];
	}
        elsif ($convert_type eq 'random') {
	    my $pos = int rand @$in;
	    push @output, $in->[$pos];
	}
    }
    return \@output;
}

sub make_convertors
{
    my ($in, $out, $table) = @_;
    my $conv = {};
    if (!$table) {
	$table = load_convertor ($in, $out);
    }
    $conv->{in2out} = $table;
    my @keys = keys %{$table};
    my @values = values %{$table};
    my $sub_in2out;
    my $sub_out2in;
    if (length_one (@keys)) {
	my $lhs = join '', @keys;

	# Improvement: one way tr/// for the ambiguous case lhs/rhs only.

	if (length_one (@values) && unambiguous ($table)) {
	    # can use tr///;
	    my $rhs = join '', @values;
	    $sub_in2out = "\$input =~ tr/$lhs/$rhs/;";
	    $sub_out2in = "\$input =~ tr/$rhs/$lhs/;";
	}
        else {
	    $sub_in2out = "\$input =~ s/([$lhs])/\$conv->{in2out}->{\$1}/eg;";
	    my $rhs = make_regex (@values);
	    if (unambiguous($conv->{in2out})) {
		my %out2in_table = reverse %{$conv->{in2out}};
		$conv->{out2in} = \%out2in_table;
		$sub_out2in = "\$input =~ s/($rhs)/\$conv->{out2in}->{\$1}/eg;";
	    }
            else {
		$conv->{out2in} = ambiguous_reverse ($conv->{in2out});
		$sub_out2in = "\$input = \$conv->split_match (\$input, \$convert_type);";
	    }
	}
    }
    else {
	my $lhs = make_regex (@keys);
	$sub_in2out = "\$input =~ s/($lhs)/\$conv->{in2out}->{\$1}/eg;";
	my $rhs = make_regex (@values);
	if (unambiguous($conv->{in2out})) {
	    my %out2in_table = reverse %{$conv->{in2out}};
	    $conv->{out2in} = \%out2in_table;
	    $sub_out2in = "    \$input =~ s/($rhs)/\$conv->{out2in}->{\$1}/eg;";
	}
    }
    $sub_in2out = add_boilerplate ($sub_in2out, "${in}2$out");
    my $sub1 = eval $sub_in2out;
    $conv->{in2out_sub} = $sub1;
    if ($sub_out2in) {
	$sub_out2in = add_boilerplate ($sub_out2in, "${out}2$in");
	my $sub2 = eval $sub_out2in;
	if ($@) {
	    print "Errors are ",$@,"\n";
	    print "\$sub2 = ",$sub2,"\n";
	}
	$conv->{out2in_sub} = $sub2;
    }
    bless $conv;
    return $conv;
}

sub convert
{
    my ($conv, $input) = @_;
    return &{$conv->{in2out_sub}}($conv, $input);
}

sub invert
{
    my ($conv, $input, $convert_type) = @_;
    return &{$conv->{out2in_sub}}($conv, $input, $convert_type);
}


# Kana ordered by consonant. Adds two bogus gyous, a "q" gyou for
# small vowels and an "xy" gyou for youon (ya, yu, yo), to the usual
# ones.

my @gyou = (
    a => [qw/ア イ ウ エ オ/],
    # Not a real gyou.
    q => [qw/ァ ィ ゥ ェ ォ/],
    k => [qw/カ キ ク ケ コ/],
    g => [qw/ガ ギ グ ゲ ゴ/],
    s => [qw/サ シ ス セ ソ/],
    z => [qw/ザ ジ ズ ゼ ゾ/],
    t => [qw/タ チ ツ テ ト/],
    d => [qw/ダ ヂ ヅ デ ド/],
    n => [qw/ナ ニ ヌ ネ ノ/],
    h => [qw/ハ ヒ フ ヘ ホ/],
    b => [qw/バ ビ ブ ベ ボ/],
    p => [qw/パ ピ プ ペ ポ/],
    m => [qw/マ ミ ム メ モ/],
    y => [qw/ヤ    ユ    ヨ/],
    xy => [qw/ャ    ュ    ョ/],
    r => [qw/ラ リ ル レ ロ/],
    w => [qw/ワ ヰ    ヱ ヲ/],
    v => [qw/ヴ/],
);

my %gyou = @gyou;

# Kana => consonant mapping.

my %siin;

for my $consonant (keys %gyou) {
    for my $kana (@{$gyou{$consonant}}) {
        if ($consonant eq 'a') {
            $siin{$kana} = '';
        }
	else {
            $siin{$kana} = $consonant;
        }
    }
}

# Vowel => kana mapping.

my %dan = (a => [qw/ア カ ガ サ ザ タ ダ ナ ハ バ パ マ ヤ ラ ワ ャ ァ/],
	   i => [qw/イ キ ギ シ ジ チ ヂ ニ ヒ ビ ピ ミ リ ヰ ィ/],
	   u => [qw/ウ ク グ ス ズ ツ ヅ ヌ フ ブ プ ム ユ ル ュ ゥ ヴ/],
	   e => [qw/エ ケ ゲ セ ゼ テ デ ネ ヘ ベ ペ メ レ ヱ ェ/],
	   o => [qw/オ コ ゴ ソ ゾ ト ド ノ ホ ボ ポ モ ヨ ロ ヲ ョ ォ/]);

# Kana => vowel mapping

my %boin;

# List of kana with a certain vowel.

my %vowelclass;

for my $vowel (keys %dan) {
    my @kana_list = @{$dan{$vowel}};
    for my $kana (@kana_list) {
	$boin{$kana} = $vowel;
    }
    $vowelclass{$vowel} = join '', @kana_list;
}

# Kana gyou which can be preceded by a sokuon (small tsu).

# Added d to the list for ウッド
# Added z for "badge" etc.
# Added g for ドッグ etc.

#my @takes_sokuon_gyou = qw/s t k p d z g/;
#my @takes_sokuon = (map {@{$gyou{$_}}} @takes_sokuon_gyou);
#my $takes_sokuon = join '', @takes_sokuon;
#die @takes_sokuon;
my $takes_sokuon = 'サシスセソタチツテトカキクケコパピプペポダヂヅデドザジズゼゾガギグゲゴ';

# Any kana except ん

#my@b4s;push@b4s,@{$gyou{$_}}for sort keys%gyou;@b4s=grep!/ん/,@b4s;die join'',@b4s;

my $before_sokuon = 'ヤユヨナニヌネノャュョガギグゲゴダヂヅデドカキクケコヴラリルレロワヰヱヲバビブベボタチツテトアイウエオパピプペポサシスセソァィゥェォマミムメモハヒフヘホザジズゼゾ';

# N

# Kana gyou which need an apostrophe when preceded by an "n" kana.

my $need_apostrophe = join '', (map {@{$gyou{$_}}} qw/a y/);

# Gyou which turn an "n" into an "m" in some kinds of romanization

my $need_m = join '', (map {@{$gyou{$_}}} qw/p b m/);

# YOUON

# Small ya, yu, yo.

my $youon = join '', (@{$gyou{xy}});
my %youon = qw/a ャ u ュ o ョ ou ョ/;

# HEPBURN

# Hepburn irregular romanization

my %hepburn = qw/シ sh ツ ts チ ch ジ j ヅ z ヂ j フ f/;

# Hepburn map from vowel to list of kana with that vowel.

my %hep_vowel = (i => 'シチジヂ', u => 'ヅツフ');
my $hep_list = join '', keys %hepburn;

# Hepburn irregular romanization of ッチ as "tch".

my %hepburn_sokuon = qw/チ t/;
my $hep_sok_list = join '', keys %hepburn_sokuon;

# Hepburn variants for the youon case.

my %hepburn_youon = qw/シ sh チ ch ジ j ヂ j/;
my $is_hepburn_youon = join '', keys %hepburn_youon;

# Kunrei romanization

my %kunrei = qw/ヅ z ヂ z/;

my $kun_list = join '', keys %kunrei;

my %kunrei_youon = qw/ヂ z/;
my $is_kunrei_youon = join '', keys %kunrei_youon;

# LONG VOWELS

# Long vowels, another bugbear of Japanese romanization.

my @aiueo = qw/a i u e o ou/;

# Various ways to display the long vowels.

my %chouonhyouki;
@{$chouonhyouki{circumflex}}{@aiueo} = qw/â  î  û  ê  ô  ô/;
@{$chouonhyouki{macron}}{@aiueo}     = qw/ā  ii  ū  ē  ō  ō/;
@{$chouonhyouki{wapuro}}{@aiueo}     = qw/aa ii uu ee oo ou/;
@{$chouonhyouki{passport}}{@aiueo}   = qw/a  i  u  e  oh oh/;
@{$chouonhyouki{none}}{@aiueo}       = qw/a  ii  u  e  o  o/;

my $vowel_re = qr/[aeiouâêîôûāēōū]/i;
my $no_u_vowel_re = qr/[aeioâêîôāēō]/i;
my $u_re = qr/[uūû]/i;

sub kana2romaji
{
    my ($input, $options) = @_;
    $input = kana2katakana ($input);
    if (! $options) {
        $options = {};
    }
    # Parse the options
    my $kunrei;
    my $hepburn;
    my $passport;
    my $common;
    if ($options->{style}) {
        my $style = $options->{style};
        if ($style eq 'kunrei') {
            $kunrei   = 1;
        }
        if ($style eq 'passport') {
            $passport = 1;
        }
        if ($style eq 'hepburn') {
            $hepburn  = 1;
        }
        if ($style eq 'common') {
            $hepburn  = 1;
	    $common = 1;
        }
        if (!$kunrei && !$passport && !$hepburn && $style ne "nihon" &&
	    $style ne 'nippon') {
            croak "Unknown romanization style '$options->{style}'";
        }
    }
    my $wapuro;
    if ($options->{wapuro}) {
        $wapuro = 1;
    }
    my $use_m = 0;
    if ($hepburn || $passport) {
	$use_m = 1;
    }
    if (defined $options->{use_m}) {
	$use_m = $options->{use_m}
    }
    my $ve_type = 'circumflex'; # type of vowel extension to use.
    if ($hepburn) {
	$ve_type = 'macron';
    }
    if ($wapuro) {
        $ve_type = 'wapuro';
    }
    if ($passport) {
	$hepburn = 1;
	$ve_type = 'passport';
	$use_m = 1;
    }
    if ($options->{ve_type}) {
	$ve_type = $options->{ve_type};
    }
    if (! $chouonhyouki{$ve_type}) {
	print STDERR "Warning: unrecognized long vowel type '$ve_type'\n";
	$ve_type = 'circumflex';
    }
    my $wo;
    if ($options->{wo}) {
	$wo = 1;
    }
    # Start of conversion

    # 撥音 (ん)
    $input =~ s/ン(?=[$need_apostrophe])/n\'/g;
    if ($use_m) {
	$input =~ s/ン(?=[$need_m])/m/g;
    }
    $input =~ s/ン/n/g;
    # 促音 (っ)
    if ($hepburn) {
	$input =~ s/ッ([$hep_sok_list])/$hepburn_sokuon{$1}$1/g;
    }
    $input =~ s/ッ([$takes_sokuon])/$siin{$1}$1/g;
    if ($ve_type eq 'wapuro') {
	$input =~ s/ー/-/g;
    }
    if ($ve_type eq 'none') {
	$input =~ s/ー//g;
    }
    # 長音 (ー)
    for my $vowel (@aiueo) {
	my $ve = $chouonhyouki{$ve_type}->{$vowel};
	my $vowelclass;
	my $vowel_kana;
	if ($vowel eq 'ou') {
	    $vowelclass = $vowelclass{o};
	    $vowel_kana = 'ウ';
	}
	else {
	    $vowelclass = $vowelclass{$vowel};
	    $vowel_kana = $dan{$vowel}->[0];
	}
	# 長音 (ー) + 拗音 (きょ)
	my $y = $youon{$vowel};
	if ($y) {
	    if ($hepburn) {
		$input =~ s/([$is_hepburn_youon])${y}[ー$vowel_kana]/$hepburn_youon{$1}$ve/g;
	    }
	    $input =~ s/([$vowelclass{i}])${y}[ー$vowel_kana]/$siin{$1}y$ve/g;
	}
	if ($hepburn && $hep_vowel{$vowel}) {
	    $input =~ s/([$hep_vowel{$vowel}])[ー$vowel_kana]/$hepburn{$1}$ve/g;
	}
	$input =~ s/${vowel_kana}[ー$vowel_kana]/$ve/g;
	$input =~ s/([$vowelclass])[ー$vowel_kana]/$siin{$1}$ve/g;
    }
    # 拗音 (きょ)
    if ($hepburn) {
	$input =~ s/([$is_hepburn_youon])([$youon])/$hepburn_youon{$1}$boin{$2}/g;
    }
    elsif ($kunrei) {
	$input =~ s/([$is_kunrei_youon])([$youon])/$kunrei_youon{$1}y$boin{$2}/g;
    }
    $input =~ s/([$vowelclass{i}])([$youon])/$siin{$1}y$boin{$2}/g;
    # その他
    if ($wo) {
	$input =~ s/ヲ/wo/g;
	$input =~ s/([アイウエオ])/$boin{$1}/g;
    }
    else {
	$input =~ s/([アイウエオヲ])/$boin{$1}/g;
    }
    $input =~ s/([ァィゥェォ])/q$boin{$1}/g;
    $input =~ s/ヮ/xwa/g;
    if ($hepburn) {
	$input =~ s/([$hep_list])/$hepburn{$1}$boin{$1}/g;
    }
    elsif ($kunrei) {
	$input =~ s/([$kun_list])/$kunrei{$1}$boin{$1}/g;
    }
    $input =~ s/([カ-ヂツ-ヱヴ])/$siin{$1}$boin{$1}/g;
    $input =~ s/q($vowel_re)/x$1/g;
    if ($common) {
	# Convert kana + small vowel into thingumibob, if there is a
	# consonant before.
	$input =~ s/([^\Waiueo])$vowel_re[x]($vowel_re)/$1$2/;
	# Convert u + small kana into w + vowel
	$input =~ s/($vowel_re|\b)ux([iue])/$1w$2/i;
    }
    return $input;
}

sub romaji2hiragana
{
    my ($input, $options) = @_;
    if (! $options) {
        $options = {};
    }
    my $katakana = romaji2kana ($input, {wapuro => 1, %$options});
    return kata2hira ($katakana);
}

sub romaji_styles
{
    my ($check) = @_;
    my @styles = (
    {
        abbrev    => "hepburn",
        full_name => "Hepburn",
    }, {
        abbrev    => 'nihon',
        full_name => 'Nihon-shiki',
    }, {
        abbrev    => 'kunrei',
        full_name => 'Kunrei-shiki',
    }, {
	abbrev => 'common',
	full_name => 'common',
    });
    if (! defined ($check)) {
        return (@styles);
    }
    else {
        for my $style (@styles) {
            if ($check eq $style->{abbrev}) {
                return 1;
            }
        }
        return;
    }
}

my %styles = (
    macron => 1,
    circumflex => 1,
    wapuro => 1,
    passport => 1,
    none => 1,
);

# Check whether this vowel style is allowed.

sub romaji_vowel_styles
{
    my ($check) = @_;
    if (! defined ($check)) {
        return [keys %styles];
    }
    else {
	return $styles{$check};
    }
}

my $romaji2katakana;
my $romaji_regex;

my %longvowels;
@longvowels{qw/â  î  û  ê  ô/}  = qw/aー iー uー eー oー/;
@longvowels{qw/ā  ī  ū  ē  ō/}  = qw/aー iー uー eー oー/;
my $longvowels = join '|', sort {length($a)<=>length($b)} keys %longvowels;

sub romaji2kana
{
    my ($input, $options) = @_;
    if (! defined $romaji2katakana) {
	$romaji2katakana = load_convertor ('romaji', 'katakana');
	$romaji_regex = make_regex (keys %$romaji2katakana);
    }
    # Set to true if we want long o to be オウ rather than オー
    my $wapuro;
    # Set to true if we want gumma to be ぐっま and onnna to be おんな.
    my $ime;
    if ($options) {
	$wapuro = $options->{wapuro};
	$ime = $options->{ime};
    }

    if (! defined $input) {
        return;
    }
    $input = lc $input;
    # Deal with long vowels
    if ($wapuro) {
        $input =~ s/[âā]/aa/g;
        $input =~ s/[îī]/ii/g;
        $input =~ s/[êē]/ee/g;
	$input =~ s/[ûū]/uu/g;
	$input =~ s/[ôō]/ou/g;
    }
    else {
	$input =~ s/($longvowels)/$longvowels{$1}/g;
        # Doubled vowels to chouon
        $input =~ s/([aiueo])\1/$1ー/g;
    }
    # Deal with double consonants
    # danna -> だんな
    if ($ime) {
	# IME romaji rules:
	# Allow double n for ん:
	# gunnma -> グンマ, dannna -> ダンナ
	$input =~ s/n{1,2}(?=[nm][aiueo])/ン/g;
	# Substitute sokuon for mm + vowel:
	# gumma -> グッマ
	$input =~ s/m(?=[nm][aiueo])/ッ/g;
    }
    else {
	# Usual romaji rules: Don't allow double n for ん, change
	# gumma to グンマ.
	$input =~ s/[nm](?=[nm][aiueo])/ン/g;
    }
    # shimbun -> しんぶん
    $input =~ s/m(?=[pb]y?[aiueo])/ン/g;
    # tcha -> っちゃ
    $input =~ s/t(?=ch[aiueo])/ッ/g;
    # ccha -> っちゃ
    $input =~ s/c(?=ch[aiueo])/ッ/g;
    # kkya -> っきゃ etc.
    $input =~ s/([kstfhmrgzdbpjqvwy])(?=\1y?[aiueo])/ッ/g;
    # kkya -> っきゃ etc.
    $input =~ s/ttsu/ッツ/g;
    # xtsu -> っ
    $input =~ s/xtsu/ッ/g;
    # ssha -> っしゃ
    $input =~ s/([s])(?=\1h[aiueo])/ッ/g;
    # Passport romaji,
    # oh{consonant} -> oo
    if (! $ime) {
	# IMEs do not recognize passport romaji.
	if ($wapuro) {
	    $input =~ s/oh(?=[ksthmrgzdbp])/オウ/g;
	}
	else {
	    $input =~ s/oh(?=[ksthmrgzdbp])/オー/g;
	}
    }
    # All the special cases have been dealt with, now substitute all
    # the kana.
    $input =~ s/($romaji_regex)/$romaji2katakana->{$1}/g;
    return $input;
}

sub is_small
{
    my ($input) = @_;
    if ($input =~/[ぁぃぅぇぉっゃゅょゕゖゎヮァィゥェォッャュョヵヶ]/) {
	return 1;
    }
    return undef;
}


sub is_voiced
{
    my ($sound) = @_;
    if (is_kana ($sound)) {
        $sound = kana2romaji ($sound);
    }
    elsif (my $romaji = is_romaji ($sound)) {
        # Normalize to nihon shiki so that we don't have to worry
        # about ch, j, ts, etc. at the start of the sound.
        $sound = $romaji;
    }
    if ($sound =~ /^[aiueogzbpmnry]/) {
        return 1;
    }
    else {
        return undef;
    }
}

sub is_romaji
{
    my ($romaji) = @_;
    if (length ($romaji) == 0) {
	return undef;
    }
    # Test that $romaji contains only characters which may be
    # romanized Japanese.
    if ($romaji =~ /[^\sa-zāīūēōâîûêô'-]|^-/i) {
        return undef;
    }
    my $kana = romaji2kana ($romaji, {wapuro => 1});
    if ($kana =~ /^[ア-ンッー\s]+$/) {
        return kana2romaji ($kana, {wapuro => 1});
    }
    return undef;
}


sub is_romaji_semistrict
{
    my ($romaji) = @_;
    if (! is_romaji ($romaji)) {
	return undef;
    }
    if ($romaji =~ /
	# Don't allow small vowels, small tsu, or fya,
	# fye etc.
	(fy|l|x|v)y?($vowel_re|ts?u|wa|ka|ke)
    |
	# Don't allow hyi, hye, yi, ye.
	[zh]?y[ieêîē]
    |
	# Don't allow tye
	ty[eêē]
    |
	# Don't allow wh-, kw-, gw-, dh-, etc.
	(wh|kw|gw|dh|thy)$vowel_re
    |
	# Don't allow "t'i"
	[dt]'(i|y?$u_re)
    |
	# Don't allow dwu, twu
	[dt](w$u_re)
    |
	hwy$u_re
    |
	# Don't allow "wi" or "we".
	w(i|e)
    |
	# Don't allow some non-Japanese double consonants.
	(?:rr|yy)
    |
	# Don't allow 'thi'
	thi
    /ix) {
        return undef;
    }
    return 1;
}

sub is_romaji_strict
{
    my ($romaji) = @_;
    my $canonical = is_romaji ($romaji);
    if (! $canonical) {
	return undef;
    }
    my $kana = romaji2kana ($romaji);
    if ($kana =~ m!
	# Don't allow tanggono
	ンッ
    |
	# Don't allow "nmichi".
	^ン
    |
	# Don't allow ffun etc.
	^ッ
    !x) {
	return undef;
    }
    if ($romaji =~ m!
	(fy|l|x|v)y?($vowel_re|ts?u|wa|ka|ke)
    |
	# Don't allow hyi, hye, yi, ye.
	[zh]?y[ieêîē]
    |
	# Don't allow tye
	ty[eêē]
    |
	# Don't allow wh-, kw-, gw-, dh-, etc.
	(wh|kw|gw|dh|thy)$vowel_re
    |
	# Don't allow tsa, tsi, tse, tso, fa, fe, fi, fo.
	(ts|f)$no_u_vowel_re
    |
	# Don't allow "t'i"
	[dt]'(i|y?$u_re)
    |
	# Don't allow dwu, twu
	[dt](w$u_re)
    |
	hwy$u_re
    |
	# Don't allow "wi" or "we".
	w(i|e)
    |
	# Don't allow 'je', 'che', 'she'
	(?:[cs]h|j)e
    |
	# Don't allow some non-Japanese double consonants.
	(?:rr|yy)
    |
	# Don't allow 'thi'/'thu'
	th[iu]
    |
	# Don't allow 'johann'
	nn$
    |
	# Don't allow 'ridzuan' etc.
	dz
    |
	# Qs are out.
	q
    |
	# Double ws, hs, etc. are out
	ww|hh|bb
    |
	# This is allowed by IMEs as "ちゃ" etc.
	cy
    !ix) {
        return undef;
    }
    return $canonical;
}

sub hira2kata
{
    my (@input) = @_;
    if (!@input) {
        return;
    }
    for (@input) {
	if ($_) {
	    tr/ぁ-んゔ/ァ-ンヴ/;
	}
    }
    return wantarray ? @input : "@input";
}

sub kata2hira
{
    my (@input) = @_;
    for (@input) {tr/ァ-ンヴ/ぁ-んゔ/}
    return wantarray ? @input : "@input";
}

# Make the list of dakuon stuff.

sub make_dak_list
{
    my @dak_list;
    for (@_) {
	push @dak_list, @{$gyou{$_}};
	push @dak_list, hira2kata (@{$gyou{$_}});
    }
    return @dak_list;
}

sub load_kana2hw2
{
    my $conv = Convert::Moji->new (
	["oneway", "tr", "あ-ん", "ア-ン"],
	["file",
	 getdistfile ("katakana2hw_katakana")]
    );
    return $conv;
}

my $kata2hw;

sub make_kata2hw
{
   if (!$kata2hw) {
       $kata2hw = make_convertors ('katakana','hw_katakana');
   }
}

my $kana2hw;

sub kana2hw
{
   my ($input) = @_;
   if (! $kana2hw) {
       $kana2hw = load_kana2hw2 ();
   }
   return $kana2hw->convert ($input);
}

sub katakana2hw
{
    my ($input) = @_;
    make_kata2hw ();
    return $kata2hw->convert ($input);
}

sub hw2katakana
{
    my ($input) = @_;
    if (!$kata2hw) {
        $kata2hw = make_convertors ('katakana','hw_katakana');
    }
    return $kata2hw->invert ($input);
}

sub InHankakuKatakana
{
    return <<'END';
+utf8::Katakana
&utf8::InHalfwidthAndFullwidthForms
END
}

# The two lists in wide2ascii and ascii2wide have exactly the same
# length.
#
# The warnings produced by Perl versions later than 22 are bugs in
# Perl:
#
# https://rt.perl.org/Public/Bug/Display.html?id=125493
#
# To save problems for users, switch off warnings in these routines.
#
# I have no idea what command to use to switch off just the
# "Replacement list is longer than search list" warning and leave the
# others intact.

no warnings 'misc';

sub wide2ascii
{
    my ($input) = @_;
    $input =~ tr/\x{3000}\x{FF01}-\x{FF5E}/ -~/;
    return $input;
}

sub ascii2wide
{
    my ($input) = @_;
    $input =~ tr/ -~/\x{3000}\x{FF01}-\x{FF5E}/;
    return $input;
}

use warnings;

sub InWideAscii
{
    return <<'END';
FF01 FF5E
3000
END
}

my $kana2morse;

sub load_kana2morse
{
    if (!$kana2morse) {
	$kana2morse = make_convertors ('katakana', 'morse');
    }
}

sub kana2morse
{
    my ($input) = @_;
    load_kana2morse;
    $input = hira2kata ($input);
    $input =~ tr/ァィゥェォャュョッ/アイウエオヤユヨツ/;
    $input = split_sound_marks ($input);
    $input = join ' ', (split '', $input);
    $input = $kana2morse->convert ($input);
    return $input;
}


sub getdistfile
{
    my ($filename) = @_;
    my $dir = __FILE__;
    $dir =~ s!\.pm$!/!;
    my $file = "$dir$filename.txt";
    return $file;
}

sub morse2kana
{
    my ($input) = @_;
    load_kana2morse;
    my @input = split ' ',$input;
    for (@input) {
	$_ = $kana2morse->invert ($_);
    }
    $input = join '', @input;
    $input = join_sound_marks ($input);
    return $input;
}

my $kana2braille;

sub load_kana2braille
{
    if (!$kana2braille) {
	$kana2braille = make_convertors ('katakana', 'braille');
    }
}

my %nippon2kana;

for my $k (keys %gyou) {
    for my $ar (@{$gyou{$k}}) {
	my $vowel = $boin{$ar};
	my $nippon = $k.$vowel;
	$nippon2kana{$nippon} = $ar;
    }
}

sub is_kana
{
    my ($may_be_kana) = @_;
    if ($may_be_kana =~ /^[あ-んア-ン]+$/) {
        return 1;
    }
    return;
}

sub is_katakana
{
    my ($may_be_kana) = @_;
    if ($may_be_kana =~ /^[ア-ン]+$/) {
        return 1;
    }
    return;
}

sub is_hiragana
{
    my ($may_be_kana) = @_;
    if ($may_be_kana =~ /^[あ-ん]+$/) {
        return 1;
    }
    return;
}

my %daku2not = (qw/
が か
ぎ き
ぐ く
げ け
ご こ
だ た
ぢ ち
づ つ
で て
ど と
ざ さ
じ し
ず す
ぜ せ
ぞ そ
ば は
び ひ
ぶ ふ
べ へ
ぼ ほ
ガ カ
ギ キ
グ ク
ゲ ケ
ゴ コ
ダ タ
ヂ チ
ヅ ツ
デ テ
ド ト
ザ サ
ジ シ
ズ ス
ゼ セ
ゾ ソ
バ ハ
ビ ヒ
ブ フ
ベ ヘ
ボ ホ
/);

my %not2daku = reverse %daku2not;

my $daku = qr![がぎぐげごだぢづでどざじずぜぞばびぶべぼガギグゲゴダヂヅデドザジズゼゾバビブベボ]!;

my $nodaku = qr![かきくけこたしつてとさしすせそはひふへほカキクケコタシツテトサシスセソハヒフヘホ]!;

my %handaku2not = (qw!
ぱ は
ぴ ひ
ぷ ふ
ぺ へ
ぽ ほ
パ ハ
ピ ヒ
プ フ
ペ ヘ
ポ ホ
!);

my %not2handaku = reverse %handaku2not;

my $handaku = qr![ぱぴぷぺぽパピプペポ]!;

my $nohandaku = qr![はひふへほハヒフヘホ]!;

sub join_sound_marks
{
    my ($input) = @_;
    $input =~ s!($nohandaku)(゚|゜)!$not2handaku{$1}!g;
    $input =~ s!($nodaku)(゙|゛)!$not2daku{$1}!g;
    # Remove strays.
    $input =~ s![゙゛゚゜]!!g;
    return $input;
}

sub split_sound_marks
{
    my ($input) = @_;
    $input =~ s!($handaku)!$handaku2not{$1}゜!g;
    $input =~ s!($daku)!$daku2not{$1}゛!g;
    return $input;
}

sub strip_sound_marks
{
    my ($input) = @_;
    $input =~ s!($handaku)!$handaku2not{$1}!g;
    $input =~ s!($daku)!$daku2not{$1}!g;
    return $input;
}

sub kana2katakana
{
    my ($input) = @_;
    $input = join_sound_marks ($input);
    $input = hira2kata($input);
    if ($input =~ /\p{InHankakuKatakana}/) {
	$input = hw2katakana($input);
    }
    return $input;
}

sub kana2braille
{
    my ($input) = @_;
    load_kana2braille;
    $input = kana2katakana ($input);
    $input = split_sound_marks ($input);
    $input =~ s/([キシチヒ])゛([ャュョ])/'⠘'.$nippon2kana{$siin{$1}.$boin{$2}}/eg;
    $input =~ s/(ヒ)゜([ャュョ])/'⠨'.$nippon2kana{$siin{$1}.$boin{$2}}/eg;
    $input =~ s/([キシチニヒミリ])([ャュョ])/'⠈'.$nippon2kana{$siin{$1}.$boin{$2}}/eg;
    $input =~ s/([$vowelclass{o}])ウ/$1ー/g;
    $input = $kana2braille->convert ($input);
    $input =~ s/(.)([⠐⠠])/$2$1/g;
    return $input;
}

sub braille2kana
{
    my ($input) = @_;
    load_kana2braille;
    $input =~ s/([⠐⠠])(.)/$2$1/g;
    $input = $kana2braille->invert ($input);
    $input =~ s/⠘(.)/$nippon2kana{$siin{$1}.'i'}.'゛'.$youon{$boin{$1}}/eg;
    $input =~ s/⠨(.)/$nippon2kana{$siin{$1}.'i'}.'゜'.$youon{$boin{$1}}/eg;
    $input =~ s/⠈(.)/$nippon2kana{$siin{$1}.'i'}.$youon{$boin{$1}}/eg;
    $input = join_sound_marks ($input);
    return $input;
}

my $circled_conv;

sub load_circled_conv
{
    if (!$circled_conv) {
	$circled_conv = make_convertors ("katakana", "circled");
    }
}

sub kana2circled
{
    my ($input) = @_;
    $input = kana2katakana($input);
    $input = split_sound_marks ($input);
    load_circled_conv;
    $input = $circled_conv->convert ($input);
    return $input;
}

sub circled2kana
{
    my ($input) = @_;
    load_circled_conv;
    $input = $circled_conv->invert ($input);
    $input = join_sound_marks ($input);
    return $input;
}

sub normalize_romaji
{
    my ($romaji) = @_;
    my $kana = romaji2kana ($romaji, {wapuro => 1});
    $kana =~ s/[っッ]/xtu/g;
    my $romaji_out = kana2romaji ($kana, {ve_type => 'wapuro'});
    return $romaji_out;
}

my $new2old_kanji;

sub load_new2old_kanji
{
    $new2old_kanji = Convert::Moji->new (
        ['file', getdistfile ('new_kanji2old_kanji')],
    );
}

sub new2old_kanji
{
    my ($new_kanji) = @_;
    if (! $new2old_kanji) {
        load_new2old_kanji ();
    }
    my $old_kanji = $new2old_kanji->convert ($new_kanji);
    return $old_kanji;
}

sub old2new_kanji
{
    my ($old_kanji) = @_;
    if (! $new2old_kanji) {
        load_new2old_kanji ();
    }
    my $new_kanji = $new2old_kanji->invert ($old_kanji);
    return $new_kanji;
}

my $katakana2cyrillic;

sub load_katakana2cyrillic
{
    $katakana2cyrillic = Convert::Moji->new (['file', getdistfile ('katakana2cyrillic')]);
}

sub kana2cyrillic
{
    my ($kana) = @_;
    my $katakana = kana2katakana ($kana);
    $katakana =~ s/ン([アイウエオヤユヨ])/ンъ$1/g;
    if (! $katakana2cyrillic) {
        load_katakana2cyrillic ();
    }
    my $cyrillic = $katakana2cyrillic->convert ($katakana);
    $cyrillic =~ s/н([пбм])/м$1/g;
    return $cyrillic;
}

sub cyrillic2katakana
{
    my ($cyrillic) = @_;
    # Convert the Cyrillic letters to lower case versions of the
    # letters. This table of conversions was made from the one in
    # Wikipedia at <http://en.wikipedia.org/wiki/Cyrillic_alphabets>
    # using Emacs, the revision being
    # <http://en.wikipedia.org/w/index.php?title=Cyrillic_alphabets&oldid=482154809>.
    # I do not know if it covers the alphabets perfectly.
    $cyrillic =~ tr/АБВГДЕЖЗИЙIКЛМНОПРСТУФХЦЧШЩЬЮЯ/абвгдежзийiклмнопрстуфхцчшщьюя/;
    if (! $katakana2cyrillic) {
        load_katakana2cyrillic ();
    }
    my $katakana = $katakana2cyrillic->invert ($cyrillic);
    $katakana =~ s/м/ン/g;
    $katakana =~ s/ンъ([アイウエオヤユヨ])/ン$1/g;
    return $katakana;
}

my $first2hangul;
my $rest2hangul;

my $first2hangul_re;
my $rest2hangul_re;

sub load_kana2hangul
{
    $first2hangul = load_convertor ('first', 'hangul');
    $rest2hangul = load_convertor ('rest', 'hangul');
    $first2hangul_re = '\b' . make_regex (keys %$first2hangul);
    $rest2hangul_re = make_regex (keys %$rest2hangul);
}

sub kana2hangul
{
    my ($kana) = @_;
    my $katakana = kana2katakana ($kana);
    if (! $first2hangul) {
        load_kana2hangul ();
    }
    $katakana =~ s/($first2hangul_re)/$first2hangul->{$1}/g;
    $katakana =~ s/($rest2hangul_re)/$rest2hangul->{$1}/g;
    return $katakana;
}

my $firsth2k_re;
my $resth2k_re;
my $firsth2k;
my $resth2k;

sub load_hangul2kana
{
    load_kana2hangul ();
    $firsth2k = { reverse %$first2hangul };
    $resth2k = { reverse %$rest2hangul };
    $firsth2k_re = '\b' . make_regex (keys %$firsth2k);
    $resth2k_re = make_regex (keys %$resth2k);
}

sub hangul2kana
{
    my ($hangul) = @_;
    if (! $firsth2k) {
	load_hangul2kana ();
    }
    $hangul =~ s/($firsth2k_re)/$firsth2k->{$1}/;
    $hangul =~ s/($resth2k_re)/$resth2k->{$1}/;
    return $hangul;
}

my %small2large = qw!
    ゃ や
    ゅ ゆ
    ょ よ
    ぁ あ
    ぃ い
    ぅ う
    ぇ え
    ぉ お
    っ つ
    ゎ わ
!;

sub kana_to_large
{
    my ($kana) = @_;
    $kana =~ tr/ゃゅょぁぃぅぇぉっゎ/やゆよあいうえおつわ/;
    $kana =~ tr/ャュョァィゥェォッヮ/ヤユヨアイウエオツワ/;
    # Katakana phonetic extensions.
    $kana =~ tr/ㇰㇱㇲㇳㇴㇵㇶㇷㇸㇹㇺㇻㇼㇽㇾㇿ/クシストヌハヒフヘホムラリルレロ/;
    return $kana;
}

my $circled2kanji;

sub load_circled2kanji
{
    if (! $circled2kanji) {
        $circled2kanji =
        Convert::Moji->new (["file",
                             getdistfile ('circled2kanji')]);
    }
    if (! $circled2kanji) {
        die "ERROR";
    }
}

sub circled2kanji
{
    my ($input) = @_;
    load_circled2kanji ();
    return $circled2kanji->convert ($input);
}

sub kanji2circled
{
    my ($input) = @_;
    load_circled2kanji ();
    return $circled2kanji->invert ($input);
}

my $bracketed2kanji;

sub load_bracketed2kanji
{
    if (! $bracketed2kanji) {
        $bracketed2kanji =
        Convert::Moji->new (["file",
                             getdistfile ('bracketed2kanji')]);
    }
}

sub bracketed2kanji
{
    my ($input) = @_;
    load_bracketed2kanji ();
    return $bracketed2kanji->convert ($input);
}

sub kanji2bracketed
{
    my ($input) = @_;
    load_bracketed2kanji ();
    return $bracketed2kanji->invert ($input);
}

sub InKana
{
    return <<"END";
+utf8::Katakana
+utf8::InKatakana
+utf8::InHiragana
FF9E\tFF9F
FF70
-utf8::IsCn
-30FB
END
    # Explanation of the above gibberish: The funny hex is for dakuten
    # and handakuten half width. The "Katakana" catches halfwidth
    # katakana, and the "InKatakana" catches the chouon mark. "IsCn"
    # means "other, not assigned", so we remove this to prevent
    # matching non-kana characters floating around near to real
    # ones. 30FB is "Katakana middle dot", which is not kana as far as
    # I know, so that's also removed.
}

# お

# Match zero or one sokuons, one full-sized kana character, then zero
# or one each of small kana, chouon, and syllabic n, in that order.

my $kana2syllable_re = qr/ッ?[アイウエオ-モヤユヨ-ヴ](?:[ャュョァィゥェォ])?ー?ン?/;

sub katakana2syllable
{
    my ($kana) = @_;
    my @pieces;
    while ($kana =~ /($kana2syllable_re)/g) {
        push @pieces, $1;
    }
    return \@pieces;
}

my $square2katakana;

sub load_square2katakana
{
    if (! $square2katakana) {
        $square2katakana =
        Convert::Moji->new (["file",
                             getdistfile ('square-katakana')]);
    }
}

sub square2katakana
{
    load_square2katakana ();
    return $square2katakana->convert (@_);
}

sub katakana2square
{
    load_square2katakana ();
    return $square2katakana->invert (@_);
}

sub nigori_first
{
    my ($list) = @_;
    my @nigori;
    for my $kana (@$list) {
	my ($first, $remaining) = split //, $kana, 2;
	my $nf = $not2daku{$first};
	if ($nf) {
	    push @nigori, $nf.$remaining;
	}
	my $hf = $not2handaku{$first};
	if ($hf) {
	    push @nigori, $hf.$remaining;
	}
    }
    if (@nigori) {
	push @$list, @nigori;
    }
}

# Hentaigana (Unicode 10.0) related

my $hentai_file = __FILE__;
$hentai_file =~ s!\.pm$!/!;
$hentai_file .= "hentaigana.json";
# Hentai to hiragana (one to one)
my %hen2hi;
# Hiragana to hentai (one to many)
my %hi2hen;
# Hentaigana to kanji
my %hen2k;
# Kanji to hentaigana
my %k2hen;
my $k2hen_re;
# Hentai to hiragana/kanji regex (recycled for the kanji case).
my $hen_re;
# Hiragana to hentai regex
my $hi2hen_re;
# Hentai data
my $hendat;

sub load_hentai
{
    $hendat = read_json ($hentai_file);
    for my $h (@$hendat) {
	my $hi = $h->{hi};
	my $hen = chr ($h->{u});
	$hen2hi{$hen} = $hi;
	for my $hiragana (@$hi) {
	    push @{$hi2hen{$hiragana}}, $hen;
	}
	$hen2k{$hen} = $h->{ka};
	push @{$k2hen{$h->{ka}}}, $hen;
    }
    $hen_re = make_regex (keys %hen2hi);
    $hi2hen_re = make_regex (keys %hi2hen);
    $k2hen_re = make_regex (keys %k2hen);
}

sub hentai2kana
{
    my ($text) = @_;
    if (! $hendat) {
	load_hentai ();
    }
    $text =~ s/$hen_re/join ('・', @{$hen2hi{$1}})/ge;
    return $text;
}

sub kana2hentai
{
    my ($text) = @_;
    if (! $hendat) {
	load_hentai ();
    }
    # Make it all-hiragana.
    $text = split_sound_marks ($text);
    $text = kata2hira ($text);
    $text =~ s/$hi2hen_re/join ('・', @{$hi2hen{$1}})/ge;
    return $text;
    # what to do?
}

sub hentai2kanji
{
    my ($text) = @_;
    if (! $hendat) {
	load_hentai ();
    }
    # This uses the same regex as the kanji case.
    $text =~ s/$hen_re/$hen2k{$1}/g;
    return $text;
}

sub kanji2hentai
{
    my ($text) = @_;
    if (! $hendat) {
	load_hentai ();
    }
    $text =~ s/$k2hen_re/join ('・', @{$k2hen{$1}})/ge;
    return $text;
}

my %yayuyo = (qw/
    ヤ ャ
    ユ ュ
    ヨ ョ
/);

my %l2s = qw!ア ァ イ ィ ウ ゥ エ ェ オ ォ!;

sub smallize_kana
{
    my ($kana) = @_;
    my $orig = $kana;
    $kana =~ s/([キギシジチヂニヒビピミリ])([ヤユヨ])/$1$yayuyo{$2}/g;
    # Don't make "ツル" into "ッル".
    $kana =~ s/([$before_sokuon])ツ([$takes_sokuon])/$1ッ$2/g;
    $kana =~ s/フ([アイエオ])/フ$l2s{$1}/g;
    if ($kana ne $orig) {
	return $kana;
    }
    return undef;
}

sub cleanup_kana
{
    my ($kana) = @_;
    if (! $kana) {
	return $kana;
    }
    if ($kana =~ /[\x{ff01}-\x{ff5e}]/) {
	$kana = wide2ascii ($kana);
	$kana = romaji2kana ($kana);
    }
    elsif ($kana =~ /[a-zâîûêôôāūēō]/i) {
	$kana = romaji2kana ($kana);
    }
    # This calls join_sound_marks, so that call is not necessary.
    $kana = kana2katakana ($kana);
    # Translate kanjis into katakana where a "naive user" has inserted
    # kanji not kana.  Because the following expression is visually
    # confusing, note that the LHS are all kanji, and the RHS are all
    # kana/chouon
    $kana =~ tr/囗口八力二一/ロロハカニー/;
    # Turn silly small youon kana into big ones
    $kana =~ s/([^きぎしじちぢにひびぴみり]|^)([ゃゅょ])/$1$small2large{$2}/g;
    return $kana;
}

sub load_kanji
{
    my ($file) = @_;
    my $bkfile = getdistfile ($file);
    open my $in, "<:encoding(utf8)", $bkfile
        or die "Error opening '$bkfile': $!";
    my @bk;
    while (<$in>) {
	while (/(\p{InCJKUnifiedIdeographs})/g) {
	    push @bk, $1;
	}
    }
    close $in or die $!;
    return @bk;
}

sub yurei_moji
{
    return load_kanji ('yurei-moji')
}

sub bad_kanji
{
    return load_kanji ('bad-kanji');
}

sub kana_consonant
{
    my ($kana) = @_;
    if (length ($kana) < 1) {
	croak "Empty input to kana_consonant";
    }
    my $first = substr ($kana, 0, 1);
    if ($first !~ /\p{InKana}/) {
	croak "First character '$first' of '$kana' is not kana";
    }
    $first = kana2katakana ($first);
    my $not = $daku2not{$first};
    if (defined $not) {
	$first = $not;
    }
    my $con = $siin{$first};
    return $con;
}

1;
