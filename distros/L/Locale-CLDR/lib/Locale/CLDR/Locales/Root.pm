package Locale::CLDR::Locales::Root;
# This file auto generated from Data\common\main\root.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

has 'segmentation_parent' => (
	is => 'ro',
	isa => Str,
	init_arg => undef,
	default => sub {
    my $self = shift;
    my $mod_ref = ref $self;
    no strict 'refs';
    return ${ "${mod_ref}::ISA" }[0];
},
);

has 'GraphemeClusterBreak_variables' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[
		'$CR' => '\p{Grapheme_Cluster_Break=CR}',
		'$LF' => '\p{Grapheme_Cluster_Break=LF}',
		'$Control' => '\p{Grapheme_Cluster_Break=Control}',
		'$Extend' => '\p{Grapheme_Cluster_Break=Extend}',
		'$ZWJ' => '\p{Grapheme_Cluster_Break=ZWJ}',
		'$RI' => '\p{Grapheme_Cluster_Break=Regional_Indicator}',
		'$Prepend' => '\p{Grapheme_Cluster_Break=Prepend}',
		'$SpacingMark' => '\p{Grapheme_Cluster_Break=SpacingMark}',
		'$L' => '\p{Grapheme_Cluster_Break=L}',
		'$V' => '\p{Grapheme_Cluster_Break=V}',
		'$T' => '\p{Grapheme_Cluster_Break=T}',
		'$LV' => '\p{Grapheme_Cluster_Break=LV}',
		'$LVT' => '\p{Grapheme_Cluster_Break=LVT}',
		'$ConjunctLinkingScripts' => '[\p{Gujr}\p{sc=Telu}\p{sc=Mlym}\p{sc=Orya}\p{sc=Beng}\p{sc=Deva}]',
		'$ConjunctLinker' => '\p{Indic_Conjunct_Break=Linker}',
		'$LinkingConsonant' => '\p{Indic_Conjunct_Break=Consonant}',
		'$ExtPict' => '\p{Extended_Pictographic}',
		'$ExtCccZwj' => '[\p{Indic_Conjunct_Break=Linker}\p{Indic_Conjunct_Break=Extend}]',
	]}
);

has 'GraphemeClusterBreak_rules' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { {
		'3' => ' $CR × $LF ',
		'4' => ' ( $Control | $CR | $LF ) ÷ ',
		'5' => ' ÷ ( $Control | $CR | $LF ) ',
		'6' => ' $L × ( $L | $V | $LV | $LVT ) ',
		'7' => ' ( $LV | $V ) × ( $V | $T ) ',
		'8' => ' ( $LVT | $T) × $T ',
		'9' => ' × ($Extend | $ZWJ) ',
		'9.1' => ' × $SpacingMark ',
		'9.2' => ' $Prepend × ',
		'9.3' => ' $LinkingConsonant $ExtCccZwj* $ConjunctLinker $ExtCccZwj* × $LinkingConsonant ',
		'11' => ' $ExtPict $Extend* $ZWJ × $ExtPict ',
		'12' => ' ^ ($RI $RI)* $RI × $RI ',
		'13' => ' [^$RI] ($RI $RI)* $RI × $RI ',
	}}
);
has 'WordBreak_variables' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[
		'$CR' => '\p{Word_Break=CR}',
		'$LF' => '\p{Word_Break=LF}',
		'$Newline' => '\p{Word_Break=Newline}',
		'$Extend' => '\p{Word_Break=Extend}',
		'$Format' => '[\p{Word_Break=Format}]',
		'$Katakana' => '\p{Word_Break=Katakana}',
		'$ALetter' => '\p{Word_Break=ALetter}',
		'$MidLetter' => '[\p{Word_Break = MidLetter} - [\: ﹕ ：]]',
		'$MidNum' => '\p{Word_Break=MidNum}',
		'$MidNumLet' => '\p{Word_Break=MidNumLet}',
		'$Numeric' => '\p{Word_Break=Numeric}',
		'$ExtendNumLet' => '\p{Word_Break=ExtendNumLet}',
		'$RI' => '\p{Word_Break=Regional_Indicator}',
		'$Hebrew_Letter' => '\p{Word_Break=Hebrew_Letter}',
		'$Double_Quote' => '\p{Word_Break=Double_Quote}',
		'$Single_Quote' => '\p{Word_Break=Single_Quote}',
		'$ZWJ' => '\p{Word_Break=ZWJ}',
		'$ExtPict' => '\p{Extended_Pictographic}',
		'$WSegSpace' => '\p{Word_Break=WSegSpace}',
		'$AHLetter' => '($ALetter | $Hebrew_Letter)',
		'$MidNumLetQ' => '($MidNumLet | $Single_Quote)',
		'$FE' => '[$Format $Extend $ZWJ]',
		'$NotBreak_' => '[^ $Newline $CR $LF ]',
		'$Katakana' => '($Katakana $FE*)',
		'$ALetter' => '($ALetter $FE*)',
		'$MidLetter' => '($MidLetter $FE*)',
		'$MidNum' => '($MidNum $FE*)',
		'$MidNumLet' => '($MidNumLet $FE*)',
		'$Numeric' => '($Numeric $FE*)',
		'$ExtendNumLet' => '($ExtendNumLet $FE*)',
		'$RI' => '($RI $FE*)',
		'$Hebrew_Letter' => '($Hebrew_Letter $FE*)',
		'$Double_Quote' => '($Double_Quote $FE*)',
		'$Single_Quote' => '($Single_Quote $FE*)',
		'$AHLetter' => '($AHLetter $FE*)',
		'$MidNumLetQ' => '($MidNumLetQ $FE*)',
	]}
);

has 'WordBreak_rules' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { {
		'3' => ' $CR × $LF ',
		'3.1' => ' ($Newline | $CR | $LF) ÷ ',
		'3.2' => ' ÷ ($Newline | $CR | $LF) ',
		'3.3' => ' $ZWJ × $ExtPict ',
		'3.4' => ' $WSegSpace × $WSegSpace ',
		'4' => ' $NotBreak_ × [$Format $Extend $ZWJ] ',
		'5' => ' $AHLetter × $AHLetter ',
		'6' => ' $AHLetter × ($MidLetter | $MidNumLetQ) $AHLetter ',
		'7' => ' $AHLetter ($MidLetter | $MidNumLetQ) × $AHLetter ',
		'7.1' => ' $Hebrew_Letter × $Single_Quote ',
		'7.2' => ' $Hebrew_Letter × $Double_Quote $Hebrew_Letter ',
		'7.3' => ' $Hebrew_Letter $Double_Quote × $Hebrew_Letter ',
		'8' => ' $Numeric × $Numeric ',
		'9' => ' $AHLetter × $Numeric ',
		'10' => ' $Numeric × $AHLetter ',
		'11' => ' $Numeric ($MidNum | $MidNumLetQ) × $Numeric ',
		'12' => ' $Numeric × ($MidNum | $MidNumLetQ) $Numeric ',
		'13' => ' $Katakana × $Katakana ',
		'13.1' => ' ($AHLetter | $Numeric | $Katakana | $ExtendNumLet) × $ExtendNumLet ',
		'13.2' => ' $ExtendNumLet × ($AHLetter | $Numeric | $Katakana) ',
		'15' => ' ^ ($RI $RI)* $RI × $RI ',
		'16' => ' [^$RI] ($RI $RI)* $RI × $RI ',
	}}
);
has 'SentenceBreak_variables' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[
		'$CR' => '\p{Sentence_Break=CR}',
		'$LF' => '\p{Sentence_Break=LF}',
		'$Extend' => '\p{Sentence_Break=Extend}',
		'$Format' => '\p{Sentence_Break=Format}',
		'$Sep' => '\p{Sentence_Break=Sep}',
		'$Sp' => '\p{Sentence_Break=Sp}',
		'$Lower' => '\p{Sentence_Break=Lower}',
		'$Upper' => '\p{Sentence_Break=Upper}',
		'$OLetter' => '\p{Sentence_Break=OLetter}',
		'$Numeric' => '\p{Sentence_Break=Numeric}',
		'$ATerm' => '\p{Sentence_Break=ATerm}',
		'$STerm' => '\p{Sentence_Break=STerm}',
		'$Close' => '\p{Sentence_Break=Close}',
		'$SContinue' => '\p{Sentence_Break=SContinue}',
		'$Any' => '.',
		'$FE' => '[$Format $Extend]',
		'$NotPreLower_' => '[^ $OLetter $Upper $Lower $Sep $CR $LF $STerm $ATerm]',
		'$Sp' => '($Sp $FE*)',
		'$Lower' => '($Lower $FE*)',
		'$Upper' => '($Upper $FE*)',
		'$OLetter' => '($OLetter $FE*)',
		'$Numeric' => '($Numeric $FE*)',
		'$ATerm' => '($ATerm $FE*)',
		'$STerm' => '($STerm $FE*)',
		'$Close' => '($Close $FE*)',
		'$SContinue' => '($SContinue $FE*)',
		'$ParaSep' => '($Sep | $CR | $LF)',
		'$SATerm' => '($STerm | $ATerm)',
	]}
);

has 'SentenceBreak_rules' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { {
		'3' => ' $CR × $LF ',
		'4' => ' $ParaSep ÷ ',
		'5' => ' × [$Format $Extend] ',
		'6' => ' $ATerm × $Numeric ',
		'7' => ' ($Upper | $Lower) $ATerm × $Upper ',
		'8' => ' $ATerm $Close* $Sp* × $NotPreLower_* $Lower ',
		'8.1' => ' $SATerm $Close* $Sp* × ($SContinue | $SATerm) ',
		'9' => ' $SATerm $Close* × ( $Close | $Sp | $ParaSep ) ',
		'10' => ' $SATerm $Close* $Sp* × ( $Sp | $ParaSep ) ',
		'11' => ' $SATerm $Close* $Sp* $ParaSep? ÷ ',
		'998' => ' × $Any ',
	}}
);
has 'LineBreak_variables' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[
		'$AI' => '\p{Line_Break=Ambiguous}',
		'$AK' => '\p{Line_Break=Aksara}',
		'$AL' => '\p{Line_Break=Alphabetic}',
		'$AP' => '\p{Line_Break=Aksara_Prebase}',
		'$AS' => '\p{Line_Break=Aksara_Start}',
		'$B2' => '\p{Line_Break=Break_Both}',
		'$BA' => '\p{Line_Break=Break_After}',
		'$BB' => '\p{Line_Break=Break_Before}',
		'$BK' => '\p{Line_Break=Mandatory_Break}',
		'$CB' => '\p{Line_Break=Contingent_Break}',
		'$CL' => '\p{Line_Break=Close_Punctuation}',
		'$CP' => '\p{Line_Break=CP}',
		'$CM1' => '\p{Line_Break=Combining_Mark}',
		'$CR' => '\p{Line_Break=Carriage_Return}',
		'$EX' => '\p{Line_Break=Exclamation}',
		'$GL' => '\p{Line_Break=Glue}',
		'$H2' => '\p{Line_Break=H2}',
		'$H3' => '\p{Line_Break=H3}',
		'$HL' => '\p{Line_Break=HL}',
		'$HY' => '\p{Line_Break=Hyphen}',
		'$ID' => '\p{Line_Break=Ideographic}',
		'$IN' => '\p{Line_Break=Inseparable}',
		'$IS' => '\p{Line_Break=Infix_Numeric}',
		'$JL' => '\p{Line_Break=JL}',
		'$JT' => '\p{Line_Break=JT}',
		'$JV' => '\p{Line_Break=JV}',
		'$LF' => '\p{Line_Break=Line_Feed}',
		'$NL' => '\p{Line_Break=Next_Line}',
		'$NS' => '\p{Line_Break=Nonstarter}',
		'$NU' => '\p{Line_Break=Numeric}',
		'$OP' => '\p{Line_Break=Open_Punctuation}',
		'$PO' => '\p{Line_Break=Postfix_Numeric}',
		'$PR' => '\p{Line_Break=Prefix_Numeric}',
		'$QU' => '\p{Line_Break=Quotation}',
		'$SA' => '\p{Line_Break=Complex_Context}',
		'$SG' => '\p{Line_Break=Surrogate}',
		'$SP' => '\p{Line_Break=Space}',
		'$SY' => '\p{Line_Break=Break_Symbols}',
		'$VF' => '\p{Line_Break=Virama_Final}',
		'$VI' => '\p{Line_Break=Virama}',
		'$WJ' => '\p{Line_Break=Word_Joiner}',
		'$XX' => '\p{Line_Break=Unknown}',
		'$ZW' => '\p{Line_Break=ZWSpace}',
		'$CJ' => '\p{Line_Break=Conditional_Japanese_Starter}',
		'$RI' => '\p{Line_Break=Regional_Indicator}',
		'$EB' => '\p{Line_Break=E_Base}',
		'$EM' => '\p{Line_Break=E_Modifier}',
		'$ZWJ_O' => '\p{Line_Break=ZWJ}',
		'$ZWJ' => '\p{Line_Break=ZWJ}',
		'$QU_Pi' => '[$QU & \p{gc=Pi}]',
		'$QU_Pf' => '[$QU & \p{gc=Pf}]',
		'$DottedCircle' => '◌',
		'$CP30' => '[$CP-[\p{ea=F}\p{ea=W}\p{ea=H}]]',
		'$OP30' => '[$OP-[\p{ea=F}\p{ea=W}\p{ea=H}]]',
		'$ExtPictUnassigned' => '[\p{Extended_Pictographic}&\p{gc=Cn}]',
		'$sot' => '^',
		'$eot' => '(?!.)',
		'$CM' => '[$CM1 $ZWJ]',
		'$AL' => '[$AI $AL $SG $XX $SA]',
		'$NS' => '[$NS $CJ]',
		'$X' => '$CM*',
		'$Spec1_' => '[$SP $BK $CR $LF $NL $ZW]',
		'$Spec2_' => '[^ $SP $BK $CR $LF $NL $ZW]',
		'$Spec3a_' => '[^ $SP $BA $HY $CM]',
		'$Spec3b_' => '[^ $BA $HY $CM]',
		'$Spec4_' => '[^ $NU $CM]',
		'$AI' => '($AI $X)',
		'$AK' => '($AK $X)',
		'$AL' => '($AL $X)',
		'$AP' => '($AP $X)',
		'$AS' => '($AS $X)',
		'$B2' => '($B2 $X)',
		'$BA' => '($BA $X)',
		'$BB' => '($BB $X)',
		'$CB' => '($CB $X)',
		'$CL' => '($CL $X)',
		'$CP' => '($CP $X)',
		'$CM' => '($CM $X)',
		'$EX' => '($EX $X)',
		'$GL' => '($GL $X)',
		'$H2' => '($H2 $X)',
		'$H3' => '($H3 $X)',
		'$HL' => '($HL $X)',
		'$HY' => '($HY $X)',
		'$ID' => '($ID $X)',
		'$IN' => '($IN $X)',
		'$IS' => '($IS $X)',
		'$JL' => '($JL $X)',
		'$JT' => '($JT $X)',
		'$JV' => '($JV $X)',
		'$NS' => '($NS $X)',
		'$NU' => '($NU $X)',
		'$OP' => '($OP $X)',
		'$PO' => '($PO $X)',
		'$PR' => '($PR $X)',
		'$QU' => '($QU $X)',
		'$SA' => '($SA $X)',
		'$SG' => '($SG $X)',
		'$SY' => '($SY $X)',
		'$VF' => '($VF $X)',
		'$VI' => '($VI $X)',
		'$WJ' => '($WJ $X)',
		'$XX' => '($XX $X)',
		'$RI' => '($RI $X)',
		'$EB' => '($EB $X)',
		'$EM' => '($EM $X)',
		'$ZWJ' => '($ZWJ $X)',
		'$QU_Pi' => '($QU_Pi $X)',
		'$QU_Pf' => '($QU_Pf $X)',
		'$DottedCircle' => '($DottedCircle $X)',
		'$CP30' => '($CP30 $X)',
		'$OP30' => '($OP30 $X)',
		'$AL' => '($AL | ^ $CM | (?<=$Spec1_) $CM)',
	]}
);

has 'LineBreak_rules' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { {
		'4' => ' $BK ÷ ',
		'5.01' => ' $CR × $LF ',
		'5.02' => ' $CR ÷ ',
		'5.03' => ' $LF ÷ ',
		'5.04' => ' $NL ÷ ',
		'6' => ' × ( $BK | $CR | $LF | $NL ) ',
		'7.01' => ' × $SP ',
		'7.02' => ' × $ZW ',
		'8' => ' $ZW $SP* ÷ ',
		'8.1' => ' $ZWJ_O × ',
		'9' => ' $Spec2_ × $CM ',
		'11.01' => ' × $WJ ',
		'11.02' => ' $WJ × ',
		'12' => ' $GL × ',
		'12.1' => ' $Spec3a_ × $GL ',
		'12.2' => ' $Spec3b_ $CM+ × $GL ',
		'12.3' => ' ^ $CM+ × $GL ',
		'13.01' => ' × $EX ',
		'13.02' => ' $Spec4_ × ($CL | $CP | $IS | $SY) ',
		'13.03' => ' $Spec4_ $CM+ × ($CL | $CP | $IS | $SY) ',
		'13.04' => ' ^ $CM+ × ($CL | $CP | $IS | $SY) ',
		'14' => ' $OP $SP* × ',
		'15.11' => ' ( $sot | $BK | $CR | $LF | $NL | $OP | $QU | $GL | $SP | $ZW ) $QU_Pi $SP* × ',
		'15.21' => ' × $QU_Pf ( $SP | $GL | $WJ | $CL | $QU | $CP | $EX | $IS | $SY | $BK | $CR | $LF | $NL | $ZW | $eot ) ',
		'16' => ' ($CL | $CP) $SP* × $NS ',
		'17' => ' $B2 $SP* × $B2 ',
		'18' => ' $SP ÷ ',
		'19.01' => ' × $QU ',
		'19.02' => ' $QU × ',
		'20.01' => ' ÷ $CB ',
		'20.02' => ' $CB ÷ ',
		'21.01' => ' × $BA ',
		'21.02' => ' × $HY ',
		'21.03' => ' × $NS ',
		'21.04' => ' $BB × ',
		'21.1' => ' $HL ($HY | $BA) × ',
		'21.2' => ' $SY × $HL ',
		'22' => ' × $IN ',
		'23.02' => ' ($AL | $HL) × $NU ',
		'23.03' => ' $NU × ($AL | $HL) ',
		'23.12' => ' $PR × ($ID | $EB | $EM) ',
		'23.13' => ' ($ID | $EB | $EM) × $PO ',
		'24.02' => ' ($PR | $PO) × ($AL | $HL) ',
		'24.03' => ' ($AL | $HL) × ($PR | $PO) ',
		'25.01' => ' ($PR | $PO) × ( $OP | $HY )? $NU ',
		'25.02' => ' ( $OP | $HY ) × $NU ',
		'25.03' => ' $NU × ($NU | $SY | $IS) ',
		'25.04' => ' $NU ($NU | $SY | $IS)* × ($NU | $SY | $IS | $CL | $CP) ',
		'25.05' => ' $NU ($NU | $SY | $IS)* ($CL | $CP)? × ($PO | $PR) ',
		'26.01' => ' $JL × $JL | $JV | $H2 | $H3 ',
		'26.02' => ' $JV | $H2 × $JV | $JT ',
		'26.03' => ' $JT | $H3 × $JT ',
		'27.01' => ' $JL | $JV | $JT | $H2 | $H3 × $PO ',
		'27.02' => ' $PR × $JL | $JV | $JT | $H2 | $H3 ',
		'28' => ' ($AL | $HL) × ($AL | $HL) ',
		'28.11' => ' $AP × ($AK | $DottedCircle | $AS) ',
		'28.12' => ' ($AK | $DottedCircle | $AS) × ($VF | $VI) ',
		'28.13' => ' ($AK | $DottedCircle | $AS) $VI × ($AK | $DottedCircle) ',
		'28.14' => ' ($AK | $DottedCircle | $AS) × ($AK | $DottedCircle | $AS) $VF ',
		'29' => ' $IS × ($AL | $HL) ',
		'30.01' => ' ($AL | $HL | $NU) × $OP30 ',
		'30.02' => ' $CP30 × ($AL | $HL | $NU) ',
		'30.11' => ' $sot ($RI $RI)* $RI × $RI ',
		'30.12' => ' [^$RI] ($RI $RI)* $RI × $RI ',
		'30.13' => ' $RI ÷ $RI ',
		'30.21' => ' $EB × $EM ',
		'30.22' => ' $ExtPictUnassigned × $EM ',
	}}
);
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'armenian-lower','armenian-upper','cyrillic-lower','ethiopic','georgian','greek-lower','greek-upper','hebrew','hebrew-item','roman-lower','roman-upper','tamil','zz-default','digits-ordinal','spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'armenian-lower' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(0),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.00=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ա),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(բ),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(գ),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(դ),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(ե),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(զ),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(է),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ը),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(թ),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(ժ[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(ի[→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(լ[→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(խ[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(ծ[→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(կ[→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(հ[→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ձ[→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(ղ[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(ճ[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(մ[→→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(յ[→→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(ն[→→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(շ[→→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(ո[→→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(չ[→→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(պ[→→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(ջ[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(ռ[→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(ս[→→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(վ[→→]),
				},
				'4000' => {
					base_value => q(4000),
					divisor => q(1000),
					rule => q(տ[→→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(ր[→→]),
				},
				'6000' => {
					base_value => q(6000),
					divisor => q(1000),
					rule => q(ց[→→]),
				},
				'7000' => {
					base_value => q(7000),
					divisor => q(1000),
					rule => q(ւ[→→]),
				},
				'8000' => {
					base_value => q(8000),
					divisor => q(1000),
					rule => q(փ[→→]),
				},
				'9000' => {
					base_value => q(9000),
					divisor => q(1000),
					rule => q(ք[→→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=#,##0=),
				},
			},
		},
		'armenian-upper' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(0),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.00=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(Ա),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(Բ),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(Գ),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(Դ),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(Ե),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(Զ),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(Է),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(Ը),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(Թ),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(Ժ[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(Ի[→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(Լ[→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(Խ[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(Ծ[→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(Կ[→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(Հ[→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(Ձ[→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(Ղ[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(Ճ[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(Մ[→→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(Յ[→→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(Ն[→→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(Շ[→→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(Ո[→→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(Չ[→→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(Պ[→→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(Ջ[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(Ռ[→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(Ս[→→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(Վ[→→]),
				},
				'4000' => {
					base_value => q(4000),
					divisor => q(1000),
					rule => q(Տ[→→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(Ր[→→]),
				},
				'6000' => {
					base_value => q(6000),
					divisor => q(1000),
					rule => q(Ց[→→]),
				},
				'7000' => {
					base_value => q(7000),
					divisor => q(1000),
					rule => q(Ւ[→→]),
				},
				'8000' => {
					base_value => q(8000),
					divisor => q(1000),
					rule => q(Փ[→→]),
				},
				'9000' => {
					base_value => q(9000),
					divisor => q(1000),
					rule => q(Ք[→→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=#,##0=),
				},
			},
		},
		'cyrillic-lower' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(0҃),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←←.→→→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%%cyrillic-lower-1-10=҃),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(а҃і),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(в҃і),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(г҃і),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(д҃і),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(є҃і),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(ѕ҃і),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(з҃і),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(и҃і),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(ѳ҃і),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(к→%%cyrillic-lower-final→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(л→%%cyrillic-lower-final→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(м→%%cyrillic-lower-final→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(н→%%cyrillic-lower-final→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(ѯ→%%cyrillic-lower-final→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(ѻ→%%cyrillic-lower-final→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(п→%%cyrillic-lower-final→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(ч→%%cyrillic-lower-final→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(р→%%cyrillic-lower-final→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(с→%%cyrillic-lower-final→),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(т→%%cyrillic-lower-final→),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(у→%%cyrillic-lower-final→),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(ф→%%cyrillic-lower-final→),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(х→%%cyrillic-lower-final→),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(ѱ→%%cyrillic-lower-final→),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(ѿ҃),
				},
				'801' => {
					base_value => q(801),
					divisor => q(100),
					rule => q(ѿ→→),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(ц→%%cyrillic-lower-final→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(҂←%%cyrillic-lower-1-10←→%%cyrillic-lower-post→),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(1000),
					rule => q(҂←←[ →→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%%cyrillic-lower-thousands←[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(҂҂←←[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(҂҂҂←←[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(҂҂҂҂←←[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(҂҂҂҂҂←←[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'cyrillic-lower-1-10' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(а),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(в),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(г),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(д),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(є),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(ѕ),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(з),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(и),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(ѳ),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(і),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(і),
				},
			},
		},
		'cyrillic-lower-final' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(҃),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(҃=%%cyrillic-lower-1-10=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(а҃і),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(в҃і),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(г҃і),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(д҃і),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(є҃і),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(ѕ҃і),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(з҃і),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(и҃і),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(ѳ҃і),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(҃к),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(к→→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(҃л),
				},
				'31' => {
					base_value => q(31),
					divisor => q(10),
					rule => q(л→→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(҃м),
				},
				'41' => {
					base_value => q(41),
					divisor => q(10),
					rule => q(м→→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(҃н),
				},
				'51' => {
					base_value => q(51),
					divisor => q(10),
					rule => q(н→→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(҃ѯ),
				},
				'61' => {
					base_value => q(61),
					divisor => q(10),
					rule => q(ѯ→→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(҃ѻ),
				},
				'71' => {
					base_value => q(71),
					divisor => q(10),
					rule => q(ѻ→→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(҃п),
				},
				'81' => {
					base_value => q(81),
					divisor => q(10),
					rule => q(п→→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(҃ч),
				},
				'91' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(ч→→),
				},
				'max' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(ч→→),
				},
			},
		},
		'cyrillic-lower-post' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(҃),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%cyrillic-lower=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%cyrillic-lower=),
				},
			},
		},
		'cyrillic-lower-thousands' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(҃),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(҃҂а),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(҃҂в),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(҃҂г),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(҃҂д),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(҃҂є),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(҃҂ѕ),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(҃҂з),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(҃҂и),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(҃҂ѳ),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(҃҂і),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(҂а҃҂і),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(҂в҃҂і),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(҂г҃҂і),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(҂д҃҂і),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(҂є҃҂і),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(҂ѕ҃҂і),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(҂з҃҂і),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(҂и҃҂і),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(҂ѳ҃҂і),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(҂к→→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(҂л→→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(҂м→→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(҂н→→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(҂ѯ→→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(҂ѻ→→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(҂п→→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(҂ч→→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(҂р→→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(҂с→→),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(҂т→→),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(҂у→→),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(҂ф→→),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(҂х→→),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(҂ѱ→→),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(҂ѿ→→),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(҂ц→→),
				},
				'max' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(҂ц→→),
				},
			},
		},
		'digits-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=.),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=.),
				},
			},
		},
		'ethiopic' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ባዶ),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←←፡→→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(፩),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(፪),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(፫),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(፬),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(፭),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(፮),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(፯),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(፰),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(፱),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(፲[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(፳[→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(፴[→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(፵[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(፶[→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(፷[→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(፸[→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(፹[→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(፺[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(፻[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←፻[→→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(፼[→→]),
				},
				'20000' => {
					base_value => q(20000),
					divisor => q(10000),
					rule => q(←←፼[→→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(፼→%%ethiopic-p1→),
				},
				'200000000' => {
					base_value => q(200000000),
					divisor => q(100000000),
					rule => q(←←፼→%%ethiopic-p1→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(፼→%%ethiopic-p2→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←←፼→%%ethiopic-p2→),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(፼→%%ethiopic-p3→),
				},
				'20000000000000000' => {
					base_value => q(20000000000000000),
					divisor => q(10000000000000000),
					rule => q(←←፼→%%ethiopic-p3→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'ethiopic-p' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%ethiopic=),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(←←፼[→→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←←፼→%%ethiopic-p1→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←←፼→%%ethiopic-p2→),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←←፼→%%ethiopic-p3→),
				},
				'max' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←←፼→%%ethiopic-p3→),
				},
			},
		},
		'ethiopic-p1' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(፼),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(፼=%%ethiopic-p=),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(←%ethiopic←፼[→%ethiopic→]),
				},
				'max' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(←%ethiopic←፼[→%ethiopic→]),
				},
			},
		},
		'ethiopic-p2' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(፼፼),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(፼፼=%%ethiopic-p=),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←%ethiopic←፼→%%ethiopic-p1→),
				},
				'max' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←%ethiopic←፼→%%ethiopic-p1→),
				},
			},
		},
		'ethiopic-p3' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(፼፼፼),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(፼፼፼=%%ethiopic-p=),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%ethiopic←፼→%%ethiopic-p2→),
				},
				'max' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%ethiopic←፼→%%ethiopic-p2→),
				},
			},
		},
		'georgian' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.00=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ა),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(ბ),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(გ),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(დ),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(ე),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(ვ),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(ზ),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ჱ),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(თ),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(ი[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(კ[→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(ლ[→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(მ[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(ნ[→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(ჲ[→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(ო[→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(პ[→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(ჟ[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(რ[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(ს[→→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(ტ[→→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(უ[→→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(ჳ[→→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(ფ[→→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(ქ[→→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(ღ[→→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(ყ[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(შ[→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(ჩ[→→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(ც[→→]),
				},
				'4000' => {
					base_value => q(4000),
					divisor => q(1000),
					rule => q(ძ[→→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(წ[→→]),
				},
				'6000' => {
					base_value => q(6000),
					divisor => q(1000),
					rule => q(ჭ[→→]),
				},
				'7000' => {
					base_value => q(7000),
					divisor => q(1000),
					rule => q(ხ[→→]),
				},
				'8000' => {
					base_value => q(8000),
					divisor => q(1000),
					rule => q(ჴ[→→]),
				},
				'9000' => {
					base_value => q(9000),
					divisor => q(1000),
					rule => q(ჵ[→→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(ჯ[→→]),
				},
				'20000' => {
					base_value => q(20000),
					divisor => q(10000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(20000),
					divisor => q(10000),
					rule => q(=#,##0=),
				},
			},
		},
		'greek-lower' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%greek-numeral-minuscules=´),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←←.→→→),
				},
				'max' => {
					divisor => q(1),
					rule => q(←←.→→→),
				},
			},
		},
		'greek-numeral-majuscules' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(𐆊),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(Α),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(Β),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(Γ),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(Δ),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(Ε),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(Ϝ),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(Ζ),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(Η),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(Θ),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(Ι[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(Κ[→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(Λ[→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(Μ[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(Ν[→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(Ξ[→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(Ο[→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(Π[→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(Ϟ[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(Ρ[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(Σ[→→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(Τ[→→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(Υ[→→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(Φ[→→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(Χ[→→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(Ψ[→→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(Ω[→→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(Ϡ[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(͵←←[→→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(←←Μ[ →→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←←ΜΜ[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←←ΜΜΜ[ →→]),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←←ΜΜΜΜ[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'greek-numeral-minuscules' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(𐆊),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(α),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(β),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(γ),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(δ),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(ε),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(ϝ),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(ζ),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(η),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(θ),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(ι[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(κ[→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(λ[→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(μ[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(ν[→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(ξ[→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(ο[→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(π[→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(ϟ[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(ρ[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(σ[→→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(τ[→→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(υ[→→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(φ[→→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(χ[→→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(ψ[→→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(ω[→→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(ϡ[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(͵←←[→→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(←←μ[ →→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←←μμ[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←←μμμ[ →→]),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←←μμμμ[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'greek-upper' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%greek-numeral-majuscules=´),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←←.→→→),
				},
				'max' => {
					divisor => q(1),
					rule => q(←←.→→→),
				},
			},
		},
		'hebrew' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%hebrew-item=׳),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.00=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(י״→%hebrew-item→),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(ט״ו),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(ט״ז),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(י״→%hebrew-item→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(כ׳),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(כ״→%hebrew-item→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(ל׳),
				},
				'31' => {
					base_value => q(31),
					divisor => q(10),
					rule => q(ל״→%hebrew-item→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(מ׳),
				},
				'41' => {
					base_value => q(41),
					divisor => q(10),
					rule => q(מ״→%hebrew-item→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(נ׳),
				},
				'51' => {
					base_value => q(51),
					divisor => q(10),
					rule => q(נ״→%hebrew-item→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(ס׳),
				},
				'61' => {
					base_value => q(61),
					divisor => q(10),
					rule => q(ס״→%hebrew-item→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(ע׳),
				},
				'71' => {
					base_value => q(71),
					divisor => q(10),
					rule => q(ע״→%hebrew-item→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(פ׳),
				},
				'81' => {
					base_value => q(81),
					divisor => q(10),
					rule => q(פ״→%hebrew-item→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(צ׳),
				},
				'91' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(צ״→%hebrew-item→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(ק→%%hebrew-0-99→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(ר→%%hebrew-0-99→),
				},
				'298' => {
					base_value => q(298),
					divisor => q(100),
					rule => q(רח״צ),
				},
				'299' => {
					base_value => q(299),
					divisor => q(100),
					rule => q(ר→%%hebrew-0-99→),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(ש→%%hebrew-0-99→),
				},
				'304' => {
					base_value => q(304),
					divisor => q(100),
					rule => q(ד״ש),
				},
				'305' => {
					base_value => q(305),
					divisor => q(100),
					rule => q(ש→%%hebrew-0-99→),
				},
				'344' => {
					base_value => q(344),
					divisor => q(100),
					rule => q(שד״מ),
				},
				'345' => {
					base_value => q(345),
					divisor => q(100),
					rule => q(ש→%%hebrew-0-99→),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(ת→%%hebrew-0-99→),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(ת״ק),
				},
				'501' => {
					base_value => q(501),
					divisor => q(100),
					rule => q(תק→%%hebrew-0-99→),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(ת״ר),
				},
				'601' => {
					base_value => q(601),
					divisor => q(100),
					rule => q(תר→%%hebrew-0-99→),
				},
				'698' => {
					base_value => q(698),
					divisor => q(100),
					rule => q(תרח״צ),
				},
				'699' => {
					base_value => q(699),
					divisor => q(100),
					rule => q(תר→%%hebrew-0-99→),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(ת״ש),
				},
				'701' => {
					base_value => q(701),
					divisor => q(100),
					rule => q(תש→%%hebrew-0-99→),
				},
				'744' => {
					base_value => q(744),
					divisor => q(100),
					rule => q(תשד״מ),
				},
				'745' => {
					base_value => q(745),
					divisor => q(100),
					rule => q(תש→%%hebrew-0-99→),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(ת״ת),
				},
				'801' => {
					base_value => q(801),
					divisor => q(100),
					rule => q(תת→%%hebrew-0-99→),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(תת״ק),
				},
				'901' => {
					base_value => q(901),
					divisor => q(100),
					rule => q(תתק→%%hebrew-0-99→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(אלף),
				},
				'1001' => {
					base_value => q(1001),
					divisor => q(1000),
					rule => q(←%%hebrew-thousands←[→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(אלפיים),
				},
				'2001' => {
					base_value => q(2001),
					divisor => q(1000),
					rule => q(←%%hebrew-thousands←[→→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(←← אלפים),
				},
				'3001' => {
					base_value => q(3001),
					divisor => q(1000),
					rule => q(←%%hebrew-thousands←[→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(אלף אלפים),
				},
				'1000001' => {
					base_value => q(1000001),
					divisor => q(1000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000001),
					divisor => q(1000000),
					rule => q(=#,##0=),
				},
			},
		},
		'hebrew-0-99' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(׳),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(״=%hebrew-item=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(י״→%hebrew-item→),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(ט״ו),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(ט״ז),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(י״→%hebrew-item→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(״כ),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(כ״→%hebrew-item→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(״ל),
				},
				'31' => {
					base_value => q(31),
					divisor => q(10),
					rule => q(ל״→%hebrew-item→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(״מ),
				},
				'41' => {
					base_value => q(41),
					divisor => q(10),
					rule => q(מ״→%hebrew-item→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(״נ),
				},
				'51' => {
					base_value => q(51),
					divisor => q(10),
					rule => q(נ״→%hebrew-item→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(״ס),
				},
				'61' => {
					base_value => q(61),
					divisor => q(10),
					rule => q(ס״→%hebrew-item→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(״ע),
				},
				'71' => {
					base_value => q(71),
					divisor => q(10),
					rule => q(ע״→%hebrew-item→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(״ף),
				},
				'81' => {
					base_value => q(81),
					divisor => q(10),
					rule => q(פ״→%hebrew-item→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(״צ),
				},
				'91' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(צ״→%hebrew-item→),
				},
				'max' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(צ״→%hebrew-item→),
				},
			},
		},
		'hebrew-item' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(״),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.00=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(א),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(ב),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(ג),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(ד),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(ה),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(ו),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(ז),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ח),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(ט),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(י[→→]),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(טו),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(טז),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(י→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(כ[→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(ל[→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(מ[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(נ[→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(ס[→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(ע[→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(פ[→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(צ[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%%hebrew-item-hundreds=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%%hebrew-item-hundreds=),
				},
			},
		},
		'hebrew-item-hundreds' => {
			'private' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(״),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.00=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(א),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(ב),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(ג),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(ד),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(ה),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(ו),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(ז),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ח),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(ט),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(י[→→]),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(טו),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(טז),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(י→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(כ[→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(ל[→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(מ[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(נ[→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(ס[→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(ע[→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ף),
				},
				'81' => {
					base_value => q(81),
					divisor => q(10),
					rule => q(פ[→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(צ[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(ק[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(ר[→→]),
				},
				'298' => {
					base_value => q(298),
					divisor => q(100),
					rule => q(רחצ),
				},
				'299' => {
					base_value => q(299),
					divisor => q(100),
					rule => q(ר→→),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(ש[→→]),
				},
				'304' => {
					base_value => q(304),
					divisor => q(100),
					rule => q(דש),
				},
				'305' => {
					base_value => q(305),
					divisor => q(100),
					rule => q(ש→→),
				},
				'344' => {
					base_value => q(344),
					divisor => q(100),
					rule => q(שדמ),
				},
				'345' => {
					base_value => q(345),
					divisor => q(100),
					rule => q(ש→→),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(ת[→→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(תק[→→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(תר[→→]),
				},
				'698' => {
					base_value => q(698),
					divisor => q(100),
					rule => q(תרחצ),
				},
				'699' => {
					base_value => q(699),
					divisor => q(100),
					rule => q(תר→→),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(תש[→→]),
				},
				'744' => {
					base_value => q(744),
					divisor => q(100),
					rule => q(תשדמ),
				},
				'745' => {
					base_value => q(745),
					divisor => q(100),
					rule => q(תש→→),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(תת[→→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(תתק[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(100),
					rule => q(תתר[→→]),
				},
				'1100' => {
					base_value => q(1100),
					divisor => q(100),
					rule => q(תתש[→→]),
				},
				'1200' => {
					base_value => q(1200),
					divisor => q(100),
					rule => q(תתת[→→]),
				},
				'1300' => {
					base_value => q(1300),
					divisor => q(100),
					rule => q(תתתק[→→]),
				},
				'1400' => {
					base_value => q(1400),
					divisor => q(100),
					rule => q(תתתר[→→]),
				},
				'1500' => {
					base_value => q(1500),
					divisor => q(100),
					rule => q(תתתש[→→]),
				},
				'1600' => {
					base_value => q(1600),
					divisor => q(100),
					rule => q(תתתת[→→]),
				},
				'1700' => {
					base_value => q(1700),
					divisor => q(100),
					rule => q(תתתתק[→→]),
				},
				'1800' => {
					base_value => q(1800),
					divisor => q(100),
					rule => q(תתתתר[→→]),
				},
				'1900' => {
					base_value => q(1900),
					divisor => q(100),
					rule => q(תתתתש[→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(100),
					rule => q(תתתתת[→→]),
				},
				'2100' => {
					base_value => q(2100),
					divisor => q(1000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(2100),
					divisor => q(1000),
					rule => q(=#,##0=),
				},
			},
		},
		'hebrew-thousands' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%hebrew=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%hebrew=[׳]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%hebrew=[׳]),
				},
				'401' => {
					base_value => q(401),
					divisor => q(100),
					rule => q(=%hebrew=׳),
				},
				'max' => {
					base_value => q(401),
					divisor => q(100),
					rule => q(=%hebrew=׳),
				},
			},
		},
		'roman-lower' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(n),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.00=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(i),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(ii),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(iii),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(iv),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(v),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(vi),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(vii),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(viii),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(ix),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(x[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(xx[→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(xxx[→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(xl[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(l[→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(lx[→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(lxx[→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(lxxx[→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(xc[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(c[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(cc[→→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(ccc[→→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(cd[→→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(d[→→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(dc[→→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(dcc[→→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(dccc[→→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(cm[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(m[→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(mm[→→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(mmm[→→]),
				},
				'4000' => {
					base_value => q(4000),
					divisor => q(1000),
					rule => q(mmmm[→→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(=#,##0=),
				},
			},
		},
		'roman-upper' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(N),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.00=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(I),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(II),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(III),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(IV),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(V),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(VI),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(VII),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(VIII),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(IX),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(X[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(XX[→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(XXX[→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(XL[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(L[→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(LX[→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(LXX[→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(LXXX[→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(XC[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(C[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(CC[→→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(CCC[→→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(CD[→→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(D[→→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(DC[→→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(DCC[→→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(DCCC[→→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(CM[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(M[→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(MM[→→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(MMM[→→]),
				},
				'4000' => {
					base_value => q(4000),
					divisor => q(1000),
					rule => q(Mↁ[→→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(ↁ[→→]),
				},
				'6000' => {
					base_value => q(6000),
					divisor => q(1000),
					rule => q(ↁM[→→]),
				},
				'7000' => {
					base_value => q(7000),
					divisor => q(1000),
					rule => q(ↁMM[→→]),
				},
				'8000' => {
					base_value => q(8000),
					divisor => q(1000),
					rule => q(ↁMMM[→→]),
				},
				'9000' => {
					base_value => q(9000),
					divisor => q(1000),
					rule => q(Mↂ[→→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(ↂ[→→]),
				},
				'20000' => {
					base_value => q(20000),
					divisor => q(10000),
					rule => q(ↂↂ[→→]),
				},
				'30000' => {
					base_value => q(30000),
					divisor => q(10000),
					rule => q(ↂↂↂ[→→]),
				},
				'40000' => {
					base_value => q(40000),
					divisor => q(10000),
					rule => q(ↂↇ[→→]),
				},
				'50000' => {
					base_value => q(50000),
					divisor => q(10000),
					rule => q(ↇ[→→]),
				},
				'60000' => {
					base_value => q(60000),
					divisor => q(10000),
					rule => q(ↇↂ[→→]),
				},
				'70000' => {
					base_value => q(70000),
					divisor => q(10000),
					rule => q(ↇↂↂ[→→]),
				},
				'80000' => {
					base_value => q(80000),
					divisor => q(10000),
					rule => q(ↇↂↂↂ[→→]),
				},
				'90000' => {
					base_value => q(90000),
					divisor => q(10000),
					rule => q(ↂↈ[→→]),
				},
				'100000' => {
					base_value => q(100000),
					divisor => q(100000),
					rule => q(ↈ[→→]),
				},
				'200000' => {
					base_value => q(200000),
					divisor => q(100000),
					rule => q(ↈↈ[→→]),
				},
				'300000' => {
					base_value => q(300000),
					divisor => q(100000),
					rule => q(ↈↈↈ[→→]),
				},
				'400000' => {
					base_value => q(400000),
					divisor => q(100000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(400000),
					divisor => q(100000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=0=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
			},
		},
		'spellout-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0.#=.),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0.#=.),
				},
			},
		},
		'tamil' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(௦),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.00=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(௧),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(௨),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(௩),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(௪),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(௫),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(௬),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(௭),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(௮),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(௯),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(௰[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←௰[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(௱[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←௱[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(௲[→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←௲[→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(100000),
					rule => q(←←௱௲[→%%tamil-thousands→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(=#,##,##0=),
				},
				'max' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(=#,##,##0=),
				},
			},
		},
		'tamil-thousands' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%tamil=),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←←௲[→→]),
				},
				'max' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←←௲[→→]),
				},
			},
		},
		'zz-default' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=),
				},
			},
		},
    } },
);

# Need to add code for Key type pattern
sub display_name_pattern {
	my ($self, $name, $region, $script, $variant) = @_;

	my $display_pattern = '{0} ({1})';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0}, {1}', grep {$_} (
		$region,
		$script,
		$variant,
	);

	$display_pattern =~s/\{1\}/$subtags/g;
	return $display_pattern;
}

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'metric' => q{Metric},
 			'UK' => q{UK},
 			'US' => q{US},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => '{0}',
 			'script' => '{0}',
 			'region' => '{0}',

		}
	},
);

has 'text_orientation' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { return {
			lines => 'top-to-bottom',
			characters => 'left-to-right',
		}}
);

has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			numbers => qr{[\- ‑ , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‑ , ; \: ! ? . ( ) \[ \] \{ \}]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'final' => '{0}…',
			'initial' => '…{0}',
			'medial' => '{0}…{1}',
			'word-final' => '{0} …',
			'word-initial' => '… {0}',
			'word-medial' => '{0} … {1}',
		};
	},
);

has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{?},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h:mm',
				hms => 'h:mm:ss',
				ms => 'm:ss',
			} }
);

has 'unit_alias' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				long => 'short',
				narrow => 'short',
				short => {
					'duration-day-person' => 'duration-day',
					'duration-month-person' => 'duration-month',
					'duration-week-person' => 'duration-week',
					'duration-year-person' => 'duration-year',
					'energy-foodcalorie' => 'energy-kilocalorie',
					'graphics-dot' => 'graphics-pixel',
					'graphics-dot-per-centimeter' => 'graphics-pixel-per-centimeter',
					'graphics-dot-per-inch' => 'graphics-pixel-per-inch',
				},
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direction),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direction),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(Ki{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(Ki{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(Mi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(Mi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(Gi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(Gi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(Ti{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(Ti{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(Pi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(Pi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(Ei{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(Ei{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(Zi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(Zi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(Yi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(Yi{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(d{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(d{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(p{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(p{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(f{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(f{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(a{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(a{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(c{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(c{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(z{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(z{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(y{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(y{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(r{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(r{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(m{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(m{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(q{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(q{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(μ{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(μ{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(n{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(n{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(da{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(da{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(T{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(T{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(E{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(E{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(h{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(h{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(Z{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(Z{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(Y{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(Y{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(R{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(R{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(Q{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(Q{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(M{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(M{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(G{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(G{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(g-force),
						'other' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(g-force),
						'other' => q({0} G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'other' => q({0} m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'other' => q({0} m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arcmin),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcmin),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcsec),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcsec),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(deg),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(deg),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rad),
						'other' => q({0} rad),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad),
						'other' => q({0} rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(rev),
						'other' => q({0} rev),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(rev),
						'other' => q({0} rev),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acre),
						'other' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acre),
						'other' => q({0} ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunam),
						'other' => q({0} dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunam),
						'other' => q({0} dunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hectare),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hectare),
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ft²),
						'other' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ft²),
						'other' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yd²),
						'other' => q({0} yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yd²),
						'other' => q({0} yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(item),
						'other' => q({0} item),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(item),
						'other' => q({0} item),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kt),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'other' => q({0} mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'other' => q({0} mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/L),
						'other' => q({0} mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'other' => q({0} mmol/L),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mol),
						'other' => q({0} mol),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mol),
						'other' => q({0} mol),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'other' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(‰),
						'other' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
						'other' => q({0}‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ppm),
						'other' => q({0} ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
						'other' => q({0} ppm),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(‱),
						'other' => q({0}‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(‱),
						'other' => q({0}‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'other' => q({0} L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'other' => q({0} L/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(L/km),
						'other' => q({0} L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'other' => q({0} L/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg US),
						'other' => q({0} mpg US),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg US),
						'other' => q({0} mpg US),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(byte),
						'other' => q({0} byte),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(byte),
						'other' => q({0} byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gb),
						'other' => q({0} Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
						'other' => q({0} Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
						'other' => q({0} GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
						'other' => q({0} GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
						'other' => q({0} kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
						'other' => q({0} kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
						'other' => q({0} kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
						'other' => q({0} kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
						'other' => q({0} Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
						'other' => q({0} Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MB),
						'other' => q({0} MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MB),
						'other' => q({0} MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PB),
						'other' => q({0} PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
						'other' => q({0} PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
						'other' => q({0} Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
						'other' => q({0} Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TB),
						'other' => q({0} TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TB),
						'other' => q({0} TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(c),
						'other' => q({0} c),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(c),
						'other' => q({0} c),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(day),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(day),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dec),
						'other' => q({0} dec),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dec),
						'other' => q({0} dec),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(hr),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(hr),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μs),
						'other' => q({0} μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μs),
						'other' => q({0} μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mon),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mon),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ns),
						'other' => q({0} ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ns),
						'other' => q({0} ns),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(qtr),
						'other' => q({0} q),
						'per' => q({0}/q),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(qtr),
						'other' => q({0} q),
						'per' => q({0}/q),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sec),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sec),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(wk),
						'other' => q({0} w),
						'per' => q({0}/w),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(wk),
						'other' => q({0} w),
						'per' => q({0}/w),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(yr),
						'other' => q({0} y),
						'per' => q({0}/y),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(yr),
						'other' => q({0} y),
						'per' => q({0}/y),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amp),
						'other' => q({0} A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amp),
						'other' => q({0} A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mA),
						'other' => q({0} mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mA),
						'other' => q({0} mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohm),
						'other' => q({0} Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohm),
						'other' => q({0} Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volt),
						'other' => q({0} V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volt),
						'other' => q({0} V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(Btu),
						'other' => q({0} Btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(Btu),
						'other' => q({0} Btu),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(cal),
						'other' => q({0} cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(cal),
						'other' => q({0} cal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(eV),
						'other' => q({0} eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(eV),
						'other' => q({0} eV),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joule),
						'other' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joule),
						'other' => q({0} J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kcal),
						'other' => q({0} kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kcal),
						'other' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kJ),
						'other' => q({0} kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kJ),
						'other' => q({0} kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kWh),
						'other' => q({0} kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kWh),
						'other' => q({0} kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(US therm),
						'other' => q({0} US therm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(US therm),
						'other' => q({0} US therm),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100km),
						'other' => q({0} kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100km),
						'other' => q({0} kWh/100km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(N),
						'other' => q({0} N),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(N),
						'other' => q({0} N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(lbf),
						'other' => q({0} lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(lbf),
						'other' => q({0} lbf),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(GHz),
						'other' => q({0} GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(GHz),
						'other' => q({0} GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(Hz),
						'other' => q({0} Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(Hz),
						'other' => q({0} Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kHz),
						'other' => q({0} kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kHz),
						'other' => q({0} kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(MHz),
						'other' => q({0} MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(MHz),
						'other' => q({0} MHz),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em),
						'other' => q({0} em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em),
						'other' => q({0} em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(MP),
						'other' => q({0} MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(MP),
						'other' => q({0} MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(px),
						'other' => q({0} px),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(px),
						'other' => q({0} px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(ppcm),
						'other' => q({0} ppcm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(ppcm),
						'other' => q({0} ppcm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(ppi),
						'other' => q({0} ppi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(ppi),
						'other' => q({0} ppi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(au),
						'other' => q({0} au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(au),
						'other' => q({0} au),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(dm),
						'other' => q({0} dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(dm),
						'other' => q({0} dm),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(R⊕),
						'other' => q({0} R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(R⊕),
						'other' => q({0} R⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fm),
						'other' => q({0} fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fm),
						'other' => q({0} fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fur),
						'other' => q({0} fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fur),
						'other' => q({0} fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ly),
						'other' => q({0} ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ly),
						'other' => q({0} ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(meter),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(meter),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μm),
						'other' => q({0} μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μm),
						'other' => q({0} μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mi),
						'other' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mi),
						'other' => q({0} mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(smi),
						'other' => q({0} smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(smi),
						'other' => q({0} smi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mm),
						'other' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mm),
						'other' => q({0} mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nm),
						'other' => q({0} nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nm),
						'other' => q({0} nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(nmi),
						'other' => q({0} nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(nmi),
						'other' => q({0} nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(pc),
						'other' => q({0} pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(pc),
						'other' => q({0} pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pm),
						'other' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pm),
						'other' => q({0} pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pt),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pt),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(R☉),
						'other' => q({0} R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(R☉),
						'other' => q({0} R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yd),
						'other' => q({0} yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
						'other' => q({0} yd),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(cd),
						'other' => q({0} cd),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(cd),
						'other' => q({0} cd),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lm),
						'other' => q({0} lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lm),
						'other' => q({0} lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lx),
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lx),
						'other' => q({0} lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(L☉),
						'other' => q({0} L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(L☉),
						'other' => q({0} L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(CD),
						'other' => q({0} CD),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(CD),
						'other' => q({0} CD),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(Da),
						'other' => q({0} Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(Da),
						'other' => q({0} Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(M⊕),
						'other' => q({0} M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(M⊕),
						'other' => q({0} M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(grain),
						'other' => q({0} grain),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(grain),
						'other' => q({0} grain),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gram),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gram),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(μg),
						'other' => q({0} μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(μg),
						'other' => q({0} μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(mg),
						'other' => q({0} mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(mg),
						'other' => q({0} mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz t),
						'other' => q({0} oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz t),
						'other' => q({0} oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(M☉),
						'other' => q({0} M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(M☉),
						'other' => q({0} M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(st),
						'other' => q({0} st),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(st),
						'other' => q({0} st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tn),
						'other' => q({0} tn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tn),
						'other' => q({0} tn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(t),
						'other' => q({0} t),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(t),
						'other' => q({0} t),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(GW),
						'other' => q({0} GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(GW),
						'other' => q({0} GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hp),
						'other' => q({0} hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hp),
						'other' => q({0} hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kW),
						'other' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kW),
						'other' => q({0} kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(MW),
						'other' => q({0} MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(MW),
						'other' => q({0} MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(mW),
						'other' => q({0} mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(mW),
						'other' => q({0} mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watt),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watt),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0}²),
						'other' => q({0}²),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0}²),
						'other' => q({0}²),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0}³),
						'other' => q({0}³),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0}³),
						'other' => q({0}³),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atm),
						'other' => q({0} atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atm),
						'other' => q({0} atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(bar),
						'other' => q({0} bar),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(bar),
						'other' => q({0} bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hPa),
						'other' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hPa),
						'other' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inHg),
						'other' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inHg),
						'other' => q({0} inHg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kPa),
						'other' => q({0} kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kPa),
						'other' => q({0} kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(MPa),
						'other' => q({0} MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(MPa),
						'other' => q({0} MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mbar),
						'other' => q({0} mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mbar),
						'other' => q({0} mbar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mm Hg),
						'other' => q({0} mm Hg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mm Hg),
						'other' => q({0} mm Hg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(Pa),
						'other' => q({0} Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(Pa),
						'other' => q({0} Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(psi),
						'other' => q({0} psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(psi),
						'other' => q({0} psi),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Bft),
						'other' => q(B {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Bft),
						'other' => q(B {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/h),
						'other' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'other' => q({0} km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(kn),
						'other' => q({0} kn),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(kn),
						'other' => q({0} kn),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/s),
						'other' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/s),
						'other' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mi/h),
						'other' => q({0} mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mi/h),
						'other' => q({0} mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(K),
						'other' => q({0} K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(K),
						'other' => q({0} K),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(N⋅m),
						'other' => q({0} N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(N⋅m),
						'other' => q({0} N⋅m),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(lbf⋅ft),
						'other' => q({0} lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(lbf⋅ft),
						'other' => q({0} lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ac ft),
						'other' => q({0} ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ac ft),
						'other' => q({0} ac ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(bbl),
						'other' => q({0} bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bbl),
						'other' => q({0} bbl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bu),
						'other' => q({0} bu),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bu),
						'other' => q({0} bu),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cL),
						'other' => q({0} cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cL),
						'other' => q({0} cL),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ft³),
						'other' => q({0} ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ft³),
						'other' => q({0} ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(in³),
						'other' => q({0} in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(in³),
						'other' => q({0} in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(km³),
						'other' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(km³),
						'other' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mi³),
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yd³),
						'other' => q({0} yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yd³),
						'other' => q({0} yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(cup),
						'other' => q({0} c),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(cup),
						'other' => q({0} c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mcup),
						'other' => q({0} mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mcup),
						'other' => q({0} mc),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dL),
						'other' => q({0} dL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dL),
						'other' => q({0} dL),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dstspn),
						'other' => q({0} dstspn),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dstspn),
						'other' => q({0} dstspn),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dstspn Imp),
						'other' => q({0} dstspn Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dstspn Imp),
						'other' => q({0} dstspn Imp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram fluid),
						'other' => q({0} dram fl),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram fluid),
						'other' => q({0} dram fl),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(drop),
						'other' => q({0} drop),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(drop),
						'other' => q({0} drop),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(US fl oz),
						'other' => q({0} fl oz US),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(US fl oz),
						'other' => q({0} fl oz US),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. fl oz),
						'other' => q({0} fl oz Imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. fl oz),
						'other' => q({0} fl oz Imp.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(US gal),
						'other' => q({0} gal US),
						'per' => q({0}/gal US),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(US gal),
						'other' => q({0} gal US),
						'per' => q({0}/gal US),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Imp. gal),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Imp. gal),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hL),
						'other' => q({0} hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hL),
						'other' => q({0} hL),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(jigger),
						'other' => q({0} jigger),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(jigger),
						'other' => q({0} jigger),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(liter),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(liter),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(ML),
						'other' => q({0} ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(ML),
						'other' => q({0} ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mL),
						'other' => q({0} mL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mL),
						'other' => q({0} mL),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pinch),
						'other' => q({0} pinch),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pinch),
						'other' => q({0} pinch),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pt),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pt),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(mpt),
						'other' => q({0} mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(mpt),
						'other' => q({0} mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qt),
						'other' => q({0} qt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qt),
						'other' => q({0} qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt Imp),
						'other' => q({0} qt Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt Imp),
						'other' => q({0} qt Imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(tbsp),
						'other' => q({0} tbsp),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(tbsp),
						'other' => q({0} tbsp),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tsp),
						'other' => q({0} tsp),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tsp),
						'other' => q({0} tsp),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
				2 => q({0}, {1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 1,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'adlm' => { 'alias' => 'latn' },
		'ahom' => { 'alias' => 'latn' },
		'arab' => {
			'decimal' => q(٫),
			'exponential' => q(اس),
			'group' => q(٬),
			'infinity' => q(∞),
			'list' => q(؛),
			'minusSign' => q(؜-),
			'nan' => q(NaN),
			'perMille' => q(؉),
			'percentSign' => q(٪؜),
			'plusSign' => q(؜+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(:),
		},
		'arabext' => {
			'decimal' => q(٫),
			'exponential' => q(×۱۰^),
			'group' => q(٬),
			'infinity' => q(∞),
			'list' => q(؛),
			'minusSign' => q(‎-‎),
			'nan' => q(NaN),
			'perMille' => q(؉),
			'percentSign' => q(٪),
			'plusSign' => q(‎+‎),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(٫),
		},
		'bali' => { 'alias' => 'latn' },
		'beng' => { 'alias' => 'latn' },
		'bhks' => { 'alias' => 'latn' },
		'brah' => { 'alias' => 'latn' },
		'cakm' => { 'alias' => 'latn' },
		'cham' => { 'alias' => 'latn' },
		'deva' => { 'alias' => 'latn' },
		'diak' => { 'alias' => 'latn' },
		'fullwide' => { 'alias' => 'latn' },
		'gong' => { 'alias' => 'latn' },
		'gonm' => { 'alias' => 'latn' },
		'gujr' => { 'alias' => 'latn' },
		'guru' => { 'alias' => 'latn' },
		'hanidec' => { 'alias' => 'latn' },
		'hmng' => { 'alias' => 'latn' },
		'hmnp' => { 'alias' => 'latn' },
		'java' => { 'alias' => 'latn' },
		'kali' => { 'alias' => 'latn' },
		'kawi' => { 'alias' => 'latn' },
		'khmr' => { 'alias' => 'latn' },
		'knda' => { 'alias' => 'latn' },
		'lana' => { 'alias' => 'latn' },
		'lanatham' => { 'alias' => 'latn' },
		'laoo' => { 'alias' => 'latn' },
		'latn' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(:),
		},
		'lepc' => { 'alias' => 'latn' },
		'limb' => { 'alias' => 'latn' },
		'mathbold' => { 'alias' => 'latn' },
		'mathdbl' => { 'alias' => 'latn' },
		'mathmono' => { 'alias' => 'latn' },
		'mathsanb' => { 'alias' => 'latn' },
		'mathsans' => { 'alias' => 'latn' },
		'mlym' => { 'alias' => 'latn' },
		'modi' => { 'alias' => 'latn' },
		'mong' => { 'alias' => 'latn' },
		'mroo' => { 'alias' => 'latn' },
		'mtei' => { 'alias' => 'latn' },
		'mymr' => { 'alias' => 'latn' },
		'mymrshan' => { 'alias' => 'latn' },
		'mymrtlng' => { 'alias' => 'latn' },
		'nagm' => { 'alias' => 'latn' },
		'newa' => { 'alias' => 'latn' },
		'nkoo' => { 'alias' => 'latn' },
		'olck' => { 'alias' => 'latn' },
		'orya' => { 'alias' => 'latn' },
		'osma' => { 'alias' => 'latn' },
		'rohg' => { 'alias' => 'latn' },
		'saur' => { 'alias' => 'latn' },
		'segment' => { 'alias' => 'latn' },
		'shrd' => { 'alias' => 'latn' },
		'sind' => { 'alias' => 'latn' },
		'sinh' => { 'alias' => 'latn' },
		'sora' => { 'alias' => 'latn' },
		'sund' => { 'alias' => 'latn' },
		'takr' => { 'alias' => 'latn' },
		'talu' => { 'alias' => 'latn' },
		'tamldec' => { 'alias' => 'latn' },
		'telu' => { 'alias' => 'latn' },
		'thai' => { 'alias' => 'latn' },
		'tibt' => { 'alias' => 'latn' },
		'tirh' => { 'alias' => 'latn' },
		'tnsa' => { 'alias' => 'latn' },
		'vaii' => { 'alias' => 'latn' },
		'wara' => { 'alias' => 'latn' },
		'wcho' => { 'alias' => 'latn' },
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		adlm => {
			'alias' => 'latn',
		},
		ahom => {
			'alias' => 'latn',
		},
		arab => {
			'alias' => 'latn',
		},
		arabext => {
			'alias' => 'latn',
		},
		bali => {
			'alias' => 'latn',
		},
		beng => {
			'alias' => 'latn',
		},
		bhks => {
			'alias' => 'latn',
		},
		brah => {
			'alias' => 'latn',
		},
		cakm => {
			'alias' => 'latn',
		},
		cham => {
			'alias' => 'latn',
		},
		decimalFormat => {
			'default' => {
				'1000' => {
					'other' => '0K',
				},
				'10000' => {
					'other' => '00K',
				},
				'100000' => {
					'other' => '000K',
				},
				'1000000' => {
					'other' => '0M',
				},
				'10000000' => {
					'other' => '00M',
				},
				'100000000' => {
					'other' => '000M',
				},
				'1000000000' => {
					'other' => '0G',
				},
				'10000000000' => {
					'other' => '00G',
				},
				'100000000000' => {
					'other' => '000G',
				},
				'1000000000000' => {
					'other' => '0T',
				},
				'10000000000000' => {
					'other' => '00T',
				},
				'100000000000000' => {
					'other' => '000T',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'short' => {
				'1000' => {
					'other' => '0K',
				},
				'10000' => {
					'other' => '00K',
				},
				'100000' => {
					'other' => '000K',
				},
				'1000000' => {
					'other' => '0M',
				},
				'10000000' => {
					'other' => '00M',
				},
				'100000000' => {
					'other' => '000M',
				},
				'1000000000' => {
					'other' => '0G',
				},
				'10000000000' => {
					'other' => '00G',
				},
				'100000000000' => {
					'other' => '000G',
				},
				'1000000000000' => {
					'other' => '0T',
				},
				'10000000000000' => {
					'other' => '00T',
				},
				'100000000000000' => {
					'other' => '000T',
				},
			},
		},
		default => {
			'alias' => 'latn',
		},
		deva => {
			'alias' => 'latn',
		},
		diak => {
			'alias' => 'latn',
		},
		fullwide => {
			'alias' => 'latn',
		},
		gong => {
			'alias' => 'latn',
		},
		gonm => {
			'alias' => 'latn',
		},
		gujr => {
			'alias' => 'latn',
		},
		guru => {
			'alias' => 'latn',
		},
		hanidec => {
			'alias' => 'latn',
		},
		hmng => {
			'alias' => 'latn',
		},
		hmnp => {
			'alias' => 'latn',
		},
		java => {
			'alias' => 'latn',
		},
		kali => {
			'alias' => 'latn',
		},
		kawi => {
			'alias' => 'latn',
		},
		khmr => {
			'alias' => 'latn',
		},
		knda => {
			'alias' => 'latn',
		},
		lana => {
			'alias' => 'latn',
		},
		lanatham => {
			'alias' => 'latn',
		},
		laoo => {
			'alias' => 'latn',
		},
		lepc => {
			'alias' => 'latn',
		},
		limb => {
			'alias' => 'latn',
		},
		mathbold => {
			'alias' => 'latn',
		},
		mathdbl => {
			'alias' => 'latn',
		},
		mathmono => {
			'alias' => 'latn',
		},
		mathsanb => {
			'alias' => 'latn',
		},
		mathsans => {
			'alias' => 'latn',
		},
		mlym => {
			'alias' => 'latn',
		},
		modi => {
			'alias' => 'latn',
		},
		mong => {
			'alias' => 'latn',
		},
		mroo => {
			'alias' => 'latn',
		},
		mtei => {
			'alias' => 'latn',
		},
		mymr => {
			'alias' => 'latn',
		},
		mymrshan => {
			'alias' => 'latn',
		},
		mymrtlng => {
			'alias' => 'latn',
		},
		nagm => {
			'alias' => 'latn',
		},
		newa => {
			'alias' => 'latn',
		},
		nkoo => {
			'alias' => 'latn',
		},
		olck => {
			'alias' => 'latn',
		},
		orya => {
			'alias' => 'latn',
		},
		osma => {
			'alias' => 'latn',
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
				},
			},
		},
		rohg => {
			'alias' => 'latn',
		},
		saur => {
			'alias' => 'latn',
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'default' => '#E0',
				},
			},
		},
		segment => {
			'alias' => 'latn',
		},
		shrd => {
			'alias' => 'latn',
		},
		sind => {
			'alias' => 'latn',
		},
		sinh => {
			'alias' => 'latn',
		},
		sora => {
			'alias' => 'latn',
		},
		sund => {
			'alias' => 'latn',
		},
		takr => {
			'alias' => 'latn',
		},
		talu => {
			'alias' => 'latn',
		},
		tamldec => {
			'alias' => 'latn',
		},
		telu => {
			'alias' => 'latn',
		},
		thai => {
			'alias' => 'latn',
		},
		tibt => {
			'alias' => 'latn',
		},
		tirh => {
			'alias' => 'latn',
		},
		tnsa => {
			'alias' => 'latn',
		},
		vaii => {
			'alias' => 'latn',
		},
		wara => {
			'alias' => 'latn',
		},
		wcho => {
			'alias' => 'latn',
		},
} },
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'adlm' => {
			'alias' => 'latn',
		},
		'ahom' => {
			'alias' => 'latn',
		},
		'arab' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'alias' => 'standard',
					},
					'standard' => {
						'positive' => '#,##0.00 ¤',
					},
				},
			},
		},
		'arabext' => {
			'alias' => 'latn',
		},
		'bali' => {
			'alias' => 'latn',
		},
		'beng' => {
			'alias' => 'latn',
		},
		'bhks' => {
			'alias' => 'latn',
		},
		'brah' => {
			'alias' => 'latn',
		},
		'cakm' => {
			'alias' => 'latn',
		},
		'cham' => {
			'alias' => 'latn',
		},
		'deva' => {
			'alias' => 'latn',
		},
		'diak' => {
			'alias' => 'latn',
		},
		'fullwide' => {
			'alias' => 'latn',
		},
		'gong' => {
			'alias' => 'latn',
		},
		'gonm' => {
			'alias' => 'latn',
		},
		'gujr' => {
			'alias' => 'latn',
		},
		'guru' => {
			'alias' => 'latn',
		},
		'hanidec' => {
			'alias' => 'latn',
		},
		'hmng' => {
			'alias' => 'latn',
		},
		'hmnp' => {
			'alias' => 'latn',
		},
		'java' => {
			'alias' => 'latn',
		},
		'kali' => {
			'alias' => 'latn',
		},
		'kawi' => {
			'alias' => 'latn',
		},
		'khmr' => {
			'alias' => 'latn',
		},
		'knda' => {
			'alias' => 'latn',
		},
		'lana' => {
			'alias' => 'latn',
		},
		'lanatham' => {
			'alias' => 'latn',
		},
		'laoo' => {
			'alias' => 'latn',
		},
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'alias' => 'standard',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
			'possion' => {
				'afterCurrency' => {
					'currencyMatch' => '[[:^S:]&[:^Z:]]',
					'insertBetween' => ' ',
					'surroundingMatch' => '[:digit:]',
				},
				'beforeCurrency' => {
					'currencyMatch' => '[[:^S:]&[:^Z:]]',
					'insertBetween' => ' ',
					'surroundingMatch' => '[:digit:]',
				},
			},
		},
		'lepc' => {
			'alias' => 'latn',
		},
		'limb' => {
			'alias' => 'latn',
		},
		'mathbold' => {
			'alias' => 'latn',
		},
		'mathdbl' => {
			'alias' => 'latn',
		},
		'mathmono' => {
			'alias' => 'latn',
		},
		'mathsanb' => {
			'alias' => 'latn',
		},
		'mathsans' => {
			'alias' => 'latn',
		},
		'mlym' => {
			'alias' => 'latn',
		},
		'modi' => {
			'alias' => 'latn',
		},
		'mong' => {
			'alias' => 'latn',
		},
		'mroo' => {
			'alias' => 'latn',
		},
		'mtei' => {
			'alias' => 'latn',
		},
		'mymr' => {
			'alias' => 'latn',
		},
		'mymrshan' => {
			'alias' => 'latn',
		},
		'mymrtlng' => {
			'alias' => 'latn',
		},
		'nagm' => {
			'alias' => 'latn',
		},
		'newa' => {
			'alias' => 'latn',
		},
		'nkoo' => {
			'alias' => 'latn',
		},
		'olck' => {
			'alias' => 'latn',
		},
		'orya' => {
			'alias' => 'latn',
		},
		'osma' => {
			'alias' => 'latn',
		},
		'rohg' => {
			'alias' => 'latn',
		},
		'saur' => {
			'alias' => 'latn',
		},
		'segment' => {
			'alias' => 'latn',
		},
		'shrd' => {
			'alias' => 'latn',
		},
		'sind' => {
			'alias' => 'latn',
		},
		'sinh' => {
			'alias' => 'latn',
		},
		'sora' => {
			'alias' => 'latn',
		},
		'sund' => {
			'alias' => 'latn',
		},
		'takr' => {
			'alias' => 'latn',
		},
		'talu' => {
			'alias' => 'latn',
		},
		'tamldec' => {
			'alias' => 'latn',
		},
		'telu' => {
			'alias' => 'latn',
		},
		'thai' => {
			'alias' => 'latn',
		},
		'tibt' => {
			'alias' => 'latn',
		},
		'tirh' => {
			'alias' => 'latn',
		},
		'tnsa' => {
			'alias' => 'latn',
		},
		'vaii' => {
			'alias' => 'latn',
		},
		'wara' => {
			'alias' => 'latn',
		},
		'wcho' => {
			'alias' => 'latn',
		},
} },
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AFN' => {
			symbol => '؋',
		},
		'AMD' => {
			symbol => '֏',
		},
		'AOA' => {
			symbol => 'Kz',
		},
		'ARS' => {
			symbol => '$',
		},
		'AUD' => {
			symbol => 'A$',
		},
		'AZN' => {
			symbol => '₼',
		},
		'BAM' => {
			symbol => 'KM',
		},
		'BBD' => {
			symbol => '$',
		},
		'BDT' => {
			symbol => '৳',
		},
		'BMD' => {
			symbol => '$',
		},
		'BND' => {
			symbol => '$',
		},
		'BOB' => {
			symbol => 'Bs',
		},
		'BRL' => {
			symbol => 'R$',
		},
		'BSD' => {
			symbol => '$',
		},
		'BWP' => {
			symbol => 'P',
		},
		'BZD' => {
			symbol => '$',
		},
		'CAD' => {
			symbol => 'CA$',
		},
		'CLP' => {
			symbol => '$',
		},
		'CNY' => {
			symbol => 'CN¥',
		},
		'COP' => {
			symbol => '$',
		},
		'CRC' => {
			symbol => '₡',
		},
		'CUC' => {
			symbol => '$',
		},
		'CUP' => {
			symbol => '$',
		},
		'CZK' => {
			symbol => 'Kč',
		},
		'DKK' => {
			symbol => 'kr',
		},
		'DOP' => {
			symbol => '$',
		},
		'EGP' => {
			symbol => 'E£',
		},
		'ESP' => {
			symbol => '₧',
		},
		'EUR' => {
			symbol => '€',
		},
		'FJD' => {
			symbol => '$',
		},
		'FKP' => {
			symbol => '£',
		},
		'GBP' => {
			symbol => '£',
		},
		'GEL' => {
			symbol => '₾',
		},
		'GHS' => {
			symbol => 'GH₵',
		},
		'GIP' => {
			symbol => '£',
		},
		'GNF' => {
			symbol => 'FG',
		},
		'GTQ' => {
			symbol => 'Q',
		},
		'GYD' => {
			symbol => '$',
		},
		'HKD' => {
			symbol => 'HK$',
		},
		'HNL' => {
			symbol => 'L',
		},
		'HRK' => {
			symbol => 'kn',
		},
		'HUF' => {
			symbol => 'Ft',
		},
		'IDR' => {
			symbol => 'Rp',
		},
		'ILS' => {
			symbol => '₪',
		},
		'INR' => {
			symbol => '₹',
		},
		'ISK' => {
			symbol => 'kr',
		},
		'JMD' => {
			symbol => '$',
		},
		'JPY' => {
			symbol => 'JP¥',
		},
		'KGS' => {
			symbol => '⃀',
		},
		'KHR' => {
			symbol => '៛',
		},
		'KMF' => {
			symbol => 'CF',
		},
		'KPW' => {
			symbol => '₩',
		},
		'KRW' => {
			symbol => '₩',
		},
		'KYD' => {
			symbol => '$',
		},
		'KZT' => {
			symbol => '₸',
		},
		'LAK' => {
			symbol => '₭',
		},
		'LBP' => {
			symbol => 'L£',
		},
		'LKR' => {
			symbol => 'Rs',
		},
		'LRD' => {
			symbol => '$',
		},
		'LTL' => {
			symbol => 'Lt',
		},
		'LVL' => {
			symbol => 'Ls',
		},
		'MGA' => {
			symbol => 'Ar',
		},
		'MMK' => {
			symbol => 'K',
		},
		'MNT' => {
			symbol => '₮',
		},
		'MUR' => {
			symbol => 'Rs',
		},
		'MXN' => {
			symbol => 'MX$',
		},
		'MYR' => {
			symbol => 'RM',
		},
		'NAD' => {
			symbol => '$',
		},
		'NGN' => {
			symbol => '₦',
		},
		'NIO' => {
			symbol => 'C$',
		},
		'NOK' => {
			symbol => 'kr',
		},
		'NPR' => {
			symbol => 'Rs',
		},
		'NZD' => {
			symbol => 'NZ$',
		},
		'PHP' => {
			symbol => '₱',
		},
		'PKR' => {
			symbol => 'Rs',
		},
		'PLN' => {
			symbol => 'zł',
		},
		'PYG' => {
			symbol => '₲',
		},
		'RON' => {
			symbol => 'lei',
		},
		'RUB' => {
			symbol => '₽',
		},
		'RWF' => {
			symbol => 'RF',
		},
		'SBD' => {
			symbol => '$',
		},
		'SEK' => {
			symbol => 'kr',
		},
		'SGD' => {
			symbol => '$',
		},
		'SHP' => {
			symbol => '£',
		},
		'SRD' => {
			symbol => '$',
		},
		'SSP' => {
			symbol => '£',
		},
		'STN' => {
			symbol => 'Db',
		},
		'SYP' => {
			symbol => '£',
		},
		'THB' => {
			symbol => '฿',
		},
		'TOP' => {
			symbol => 'T$',
		},
		'TRY' => {
			symbol => '₺',
		},
		'TTD' => {
			symbol => '$',
		},
		'TWD' => {
			symbol => 'NT$',
		},
		'UAH' => {
			symbol => '₴',
		},
		'USD' => {
			symbol => 'US$',
		},
		'UYU' => {
			symbol => '$',
		},
		'VEF' => {
			symbol => 'Bs',
		},
		'VND' => {
			symbol => '₫',
		},
		'XAF' => {
			symbol => 'FCFA',
		},
		'XCD' => {
			symbol => 'EC$',
		},
		'XOF' => {
			symbol => 'F CFA',
		},
		'XPF' => {
			symbol => 'CFPF',
		},
		'XXX' => {
			symbol => '¤',
		},
		'ZAR' => {
			symbol => 'R',
		},
		'ZMW' => {
			symbol => 'ZK',
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'buddhist' => {
				'alias' => 'gregorian',
			},
			'chinese' => {
				'format' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
					'narrow' => {
						'alias' => {
							context	=> q{stand-alone},
							type	=> q{narrow},
						},
					},
					wide => {
						nonleap => [
							'M01',
							'M02',
							'M03',
							'M04',
							'M05',
							'M06',
							'M07',
							'M08',
							'M09',
							'M10',
							'M11',
							'M12'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{abbreviated},
						},
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					'wide' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
				},
			},
			'coptic' => {
				'format' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
					'narrow' => {
						'alias' => {
							context	=> q{stand-alone},
							type	=> q{narrow},
						},
					},
					wide => {
						nonleap => [
							'Tout',
							'Baba',
							'Hator',
							'Kiahk',
							'Toba',
							'Amshir',
							'Baramhat',
							'Baramouda',
							'Bashans',
							'Paona',
							'Epep',
							'Mesra',
							'Nasie'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{abbreviated},
						},
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
						],
						leap => [
							
						],
					},
					'wide' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
				},
			},
			'dangi' => {
				'alias' => 'chinese',
			},
			'ethiopic' => {
				'format' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
					'narrow' => {
						'alias' => {
							context	=> q{stand-alone},
							type	=> q{narrow},
						},
					},
					wide => {
						nonleap => [
							'Meskerem',
							'Tekemt',
							'Hedar',
							'Tahsas',
							'Ter',
							'Yekatit',
							'Megabit',
							'Miazia',
							'Genbot',
							'Sene',
							'Hamle',
							'Nehasse',
							'Pagumen'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{abbreviated},
						},
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
						],
						leap => [
							
						],
					},
					'wide' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
				},
			},
			'ethiopic-amete-alem' => {
				'alias' => 'ethiopic',
			},
			'generic' => {
				'format' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
					'narrow' => {
						'alias' => {
							context	=> q{stand-alone},
							type	=> q{narrow},
						},
					},
					wide => {
						nonleap => [
							'M01',
							'M02',
							'M03',
							'M04',
							'M05',
							'M06',
							'M07',
							'M08',
							'M09',
							'M10',
							'M11',
							'M12'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{abbreviated},
						},
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					'wide' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
				},
			},
			'gregorian' => {
				'format' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
					'narrow' => {
						'alias' => {
							context	=> q{stand-alone},
							type	=> q{narrow},
						},
					},
					wide => {
						nonleap => [
							'M01',
							'M02',
							'M03',
							'M04',
							'M05',
							'M06',
							'M07',
							'M08',
							'M09',
							'M10',
							'M11',
							'M12'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{abbreviated},
						},
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					'wide' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
				},
			},
			'hebrew' => {
				'format' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
					'narrow' => {
						'alias' => {
							context	=> q{stand-alone},
							type	=> q{narrow},
						},
					},
					wide => {
						nonleap => [
							'Tishri',
							'Heshvan',
							'Kislev',
							'Tevet',
							'Shevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Iyar',
							'Sivan',
							'Tamuz',
							'Av',
							'Elul'
						],
						leap => [
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							
						],
					},
				},
				'stand-alone' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{abbreviated},
						},
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
						],
						leap => [
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							
						],
					},
					'wide' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
				},
			},
			'indian' => {
				'format' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
					'narrow' => {
						'alias' => {
							context	=> q{stand-alone},
							type	=> q{narrow},
						},
					},
					wide => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{abbreviated},
						},
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					'wide' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
				},
			},
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Muh.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Jum. I',
							'Jum. II',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shaw.',
							'Dhuʻl-Q.',
							'Dhuʻl-H.'
						],
						leap => [
							
						],
					},
					'narrow' => {
						'alias' => {
							context	=> q{stand-alone},
							type	=> q{narrow},
						},
					},
					wide => {
						nonleap => [
							'Muharram',
							'Safar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Jumada I',
							'Jumada II',
							'Rajab',
							'Shaʻban',
							'Ramadan',
							'Shawwal',
							'Dhuʻl-Qiʻdah',
							'Dhuʻl-Hijjah'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{abbreviated},
						},
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					'wide' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
				},
			},
			'islamic-civil' => {
				'alias' => 'islamic',
			},
			'islamic-rgsa' => {
				'alias' => 'islamic',
			},
			'islamic-tbla' => {
				'alias' => 'islamic',
			},
			'islamic-umalqura' => {
				'alias' => 'islamic',
			},
			'japanese' => {
				'alias' => 'gregorian',
			},
			'persian' => {
				'format' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
					'narrow' => {
						'alias' => {
							context	=> q{stand-alone},
							type	=> q{narrow},
						},
					},
					wide => {
						nonleap => [
							'Farvardin',
							'Ordibehesht',
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
							'Dey',
							'Bahman',
							'Esfand'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{abbreviated},
						},
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					'wide' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
				},
			},
			'roc' => {
				'alias' => 'gregorian',
			},
	} },
);

has 'calendar_days' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'buddhist' => {
				'alias' => q{gregorian},
			},
			'chinese' => {
				'alias' => q{gregorian},
			},
			'coptic' => {
				'alias' => q{gregorian},
			},
			'dangi' => {
				'alias' => q{chinese},
			},
			'ethiopic' => {
				'alias' => q{gregorian},
			},
			'ethiopic-amete-alem' => {
				'alias' => q{ethiopic},
			},
			'generic' => {
				'alias' => q{gregorian},
			},
			'gregorian' => {
				'format' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
					'narrow' => {
						'alias' => {
							context	=> q{stand-alone},
							type	=> q{narrow},
						},
					},
					'short' => {
						'alias' => {
							context	=> q{format},
							type	=> q{abbreviated},
						},
					},
					wide => {
						mon => 'Mon',
						tue => 'Tue',
						wed => 'Wed',
						thu => 'Thu',
						fri => 'Fri',
						sat => 'Sat',
						sun => 'Sun'
					},
				},
				'stand-alone' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{abbreviated},
						},
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					'short' => {
						'alias' => {
							context	=> q{format},
							type	=> q{short},
						},
					},
					'wide' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
				},
			},
			'hebrew' => {
				'alias' => q{gregorian},
			},
			'indian' => {
				'alias' => q{gregorian},
			},
			'islamic' => {
				'alias' => q{gregorian},
			},
			'islamic-civil' => {
				'alias' => q{islamic},
			},
			'islamic-rgsa' => {
				'alias' => q{islamic},
			},
			'islamic-tbla' => {
				'alias' => q{islamic},
			},
			'islamic-umalqura' => {
				'alias' => q{islamic},
			},
			'japanese' => {
				'alias' => q{gregorian},
			},
			'persian' => {
				'alias' => q{gregorian},
			},
			'roc' => {
				'alias' => q{gregorian},
			},
	} },
);

has 'calendar_quarters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'buddhist' => {
				'alias' => q{gregorian},
			},
			'chinese' => {
				'alias' => q{gregorian},
			},
			'coptic' => {
				'alias' => q{gregorian},
			},
			'dangi' => {
				'alias' => q{chinese},
			},
			'ethiopic' => {
				'alias' => q{gregorian},
			},
			'ethiopic-amete-alem' => {
				'alias' => q{ethiopic},
			},
			'generic' => {
				'alias' => q{gregorian},
			},
			'gregorian' => {
				'format' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
					'narrow' => {
						'alias' => {
							context	=> q{stand-alone},
							type	=> q{narrow},
						},
					},
					wide => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
				},
				'stand-alone' => {
					'abbreviated' => {
						'alias' => {
							context	=> q{format},
							type	=> q{abbreviated},
						},
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					'wide' => {
						'alias' => {
							context	=> q{format},
							type	=> q{wide},
						},
					},
				},
			},
			'hebrew' => {
				'alias' => q{gregorian},
			},
			'indian' => {
				'alias' => q{gregorian},
			},
			'islamic' => {
				'alias' => q{gregorian},
			},
			'islamic-civil' => {
				'alias' => q{islamic},
			},
			'islamic-rgsa' => {
				'alias' => q{islamic},
			},
			'islamic-tbla' => {
				'alias' => q{islamic},
			},
			'islamic-umalqura' => {
				'alias' => q{islamic},
			},
			'japanese' => {
				'alias' => q{gregorian},
			},
			'persian' => {
				'alias' => q{gregorian},
			},
			'roc' => {
				'alias' => q{gregorian},
			},
	} },
);

has 'day_period_data' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { sub {
		# Time in hhmm format
		my ($self, $type, $time, $day_period_type) = @_;
		$day_period_type //= 'default';
		SWITCH:
		for ($type) {
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'dangi') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic-amete-alem') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic-civil') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic-rgsa') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic-tbla') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic-umalqura') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'am' if $time >= 0
						&& $time < 1200;
					return 'pm' if $time >= 1200
						&& $time < 2400;
				}
				last SWITCH;
				}
		}
	} },
);

around day_period_data => sub {
    my ($orig, $self) = @_;
    return $self->$orig;
};

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			'alias' => 'gregorian',
		},
		'chinese' => {
			'alias' => 'gregorian',
		},
		'coptic' => {
			'alias' => 'gregorian',
		},
		'dangi' => {
			'alias' => 'chinese',
		},
		'ethiopic' => {
			'alias' => 'gregorian',
		},
		'ethiopic-amete-alem' => {
			'alias' => 'ethiopic',
		},
		'generic' => {
			'alias' => 'gregorian',
		},
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'narrow' => {
					'alias' => {
						'context' => 'format',
						'width' => 'abbreviated',
					},
				},
				'wide' => {
					'alias' => {
						'context' => 'format',
						'width' => 'abbreviated',
					},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'alias' => {
						'context' => 'format',
						'width' => 'abbreviated',
					},
				},
				'narrow' => {
					'alias' => {
						'context' => 'stand-alone',
						'width' => 'abbreviated',
					},
				},
				'wide' => {
					'alias' => {
						'context' => 'stand-alone',
						'width' => 'abbreviated',
					},
				},
			},
		},
		'hebrew' => {
			'alias' => 'gregorian',
		},
		'indian' => {
			'alias' => 'gregorian',
		},
		'islamic' => {
			'alias' => 'gregorian',
		},
		'islamic-civil' => {
			'alias' => 'islamic',
		},
		'islamic-rgsa' => {
			'alias' => 'islamic',
		},
		'islamic-tbla' => {
			'alias' => 'islamic',
		},
		'islamic-umalqura' => {
			'alias' => 'islamic',
		},
		'japanese' => {
			'alias' => 'gregorian',
		},
		'persian' => {
			'alias' => 'gregorian',
		},
		'roc' => {
			'alias' => 'gregorian',
		},
	} },
);

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			abbreviated => {
				'0' => 'BE'
			},
			narrow => {
				'alias' => 'abbreviated'
			},
			wide => {
				'alias' => 'abbreviated'
			},
		},
		'chinese' => {
		},
		'coptic' => {
			abbreviated => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			narrow => {
				'alias' => 'abbreviated'
			},
			wide => {
				'alias' => 'abbreviated'
			},
		},
		'dangi' => {
		},
		'ethiopic' => {
			abbreviated => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			narrow => {
				'alias' => 'abbreviated'
			},
			wide => {
				'alias' => 'abbreviated'
			},
		},
		'ethiopic-amete-alem' => {
			abbreviated => {
				'0' => 'ERA0'
			},
			narrow => {
				'alias' => 'abbreviated'
			},
			wide => {
				'alias' => 'abbreviated'
			},
		},
		'generic' => {
			abbreviated => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			narrow => {
				'alias' => 'abbreviated'
			},
			wide => {
				'alias' => 'abbreviated'
			},
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'BCE',
				'1' => 'CE'
			},
			narrow => {
				'alias' => 'abbreviated'
			},
			wide => {
				'alias' => 'abbreviated'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'AM'
			},
			narrow => {
				'alias' => 'abbreviated'
			},
			wide => {
				'alias' => 'abbreviated'
			},
		},
		'indian' => {
			abbreviated => {
				'0' => 'Saka'
			},
			narrow => {
				'alias' => 'abbreviated'
			},
			wide => {
				'alias' => 'abbreviated'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'AH'
			},
			narrow => {
				'alias' => 'abbreviated'
			},
			wide => {
				'alias' => 'abbreviated'
			},
		},
		'islamic-civil' => {
			'alias' => 'islamic',
		},
		'islamic-rgsa' => {
			'alias' => 'islamic',
		},
		'islamic-tbla' => {
			'alias' => 'islamic',
		},
		'islamic-umalqura' => {
			'alias' => 'islamic',
		},
		'japanese' => {
			abbreviated => {
				'0' => 'Taika (645–650)',
				'1' => 'Hakuchi (650–671)',
				'2' => 'Hakuhō (672–686)',
				'3' => 'Shuchō (686–701)',
				'4' => 'Taihō (701–704)',
				'5' => 'Keiun (704–708)',
				'6' => 'Wadō (708–715)',
				'7' => 'Reiki (715–717)',
				'8' => 'Yōrō (717–724)',
				'9' => 'Jinki (724–729)',
				'10' => 'Tenpyō (729–749)',
				'11' => 'Tenpyō-kampō (749–749)',
				'12' => 'Tenpyō-shōhō (749–757)',
				'13' => 'Tenpyō-hōji (757–765)',
				'14' => 'Tenpyō-jingo (765–767)',
				'15' => 'Jingo-keiun (767–770)',
				'16' => 'Hōki (770–780)',
				'17' => 'Ten-ō (781–782)',
				'18' => 'Enryaku (782–806)',
				'19' => 'Daidō (806–810)',
				'20' => 'Kōnin (810–824)',
				'21' => 'Tenchō (824–834)',
				'22' => 'Jōwa (834–848)',
				'23' => 'Kajō (848–851)',
				'24' => 'Ninju (851–854)',
				'25' => 'Saikō (854–857)',
				'26' => 'Ten-an (857–859)',
				'27' => 'Jōgan (859–877)',
				'28' => 'Gangyō (877–885)',
				'29' => 'Ninna (885–889)',
				'30' => 'Kanpyō (889–898)',
				'31' => 'Shōtai (898–901)',
				'32' => 'Engi (901–923)',
				'33' => 'Enchō (923–931)',
				'34' => 'Jōhei (931–938)',
				'35' => 'Tengyō (938–947)',
				'36' => 'Tenryaku (947–957)',
				'37' => 'Tentoku (957–961)',
				'38' => 'Ōwa (961–964)',
				'39' => 'Kōhō (964–968)',
				'40' => 'Anna (968–970)',
				'41' => 'Tenroku (970–973)',
				'42' => 'Ten’en (973–976)',
				'43' => 'Jōgen (976–978)',
				'44' => 'Tengen (978–983)',
				'45' => 'Eikan (983–985)',
				'46' => 'Kanna (985–987)',
				'47' => 'Eien (987–989)',
				'48' => 'Eiso (989–990)',
				'49' => 'Shōryaku (990–995)',
				'50' => 'Chōtoku (995–999)',
				'51' => 'Chōhō (999–1004)',
				'52' => 'Kankō (1004–1012)',
				'53' => 'Chōwa (1012–1017)',
				'54' => 'Kannin (1017–1021)',
				'55' => 'Jian (1021–1024)',
				'56' => 'Manju (1024–1028)',
				'57' => 'Chōgen (1028–1037)',
				'58' => 'Chōryaku (1037–1040)',
				'59' => 'Chōkyū (1040–1044)',
				'60' => 'Kantoku (1044–1046)',
				'61' => 'Eishō (1046–1053)',
				'62' => 'Tengi (1053–1058)',
				'63' => 'Kōhei (1058–1065)',
				'64' => 'Jiryaku (1065–1069)',
				'65' => 'Enkyū (1069–1074)',
				'66' => 'Shōho (1074–1077)',
				'67' => 'Shōryaku (1077–1081)',
				'68' => 'Eihō (1081–1084)',
				'69' => 'Ōtoku (1084–1087)',
				'70' => 'Kanji (1087–1094)',
				'71' => 'Kahō (1094–1096)',
				'72' => 'Eichō (1096–1097)',
				'73' => 'Jōtoku (1097–1099)',
				'74' => 'Kōwa (1099–1104)',
				'75' => 'Chōji (1104–1106)',
				'76' => 'Kashō (1106–1108)',
				'77' => 'Tennin (1108–1110)',
				'78' => 'Ten-ei (1110–1113)',
				'79' => 'Eikyū (1113–1118)',
				'80' => 'Gen’ei (1118–1120)',
				'81' => 'Hōan (1120–1124)',
				'82' => 'Tenji (1124–1126)',
				'83' => 'Daiji (1126–1131)',
				'84' => 'Tenshō (1131–1132)',
				'85' => 'Chōshō (1132–1135)',
				'86' => 'Hōen (1135–1141)',
				'87' => 'Eiji (1141–1142)',
				'88' => 'Kōji (1142–1144)',
				'89' => 'Ten’yō (1144–1145)',
				'90' => 'Kyūan (1145–1151)',
				'91' => 'Ninpei (1151–1154)',
				'92' => 'Kyūju (1154–1156)',
				'93' => 'Hōgen (1156–1159)',
				'94' => 'Heiji (1159–1160)',
				'95' => 'Eiryaku (1160–1161)',
				'96' => 'Ōho (1161–1163)',
				'97' => 'Chōkan (1163–1165)',
				'98' => 'Eiman (1165–1166)',
				'99' => 'Nin’an (1166–1169)',
				'100' => 'Kaō (1169–1171)',
				'101' => 'Shōan (1171–1175)',
				'102' => 'Angen (1175–1177)',
				'103' => 'Jishō (1177–1181)',
				'104' => 'Yōwa (1181–1182)',
				'105' => 'Juei (1182–1184)',
				'106' => 'Genryaku (1184–1185)',
				'107' => 'Bunji (1185–1190)',
				'108' => 'Kenkyū (1190–1199)',
				'109' => 'Shōji (1199–1201)',
				'110' => 'Kennin (1201–1204)',
				'111' => 'Genkyū (1204–1206)',
				'112' => 'Ken’ei (1206–1207)',
				'113' => 'Jōgen (1207–1211)',
				'114' => 'Kenryaku (1211–1213)',
				'115' => 'Kenpō (1213–1219)',
				'116' => 'Jōkyū (1219–1222)',
				'117' => 'Jōō (1222–1224)',
				'118' => 'Gennin (1224–1225)',
				'119' => 'Karoku (1225–1227)',
				'120' => 'Antei (1227–1229)',
				'121' => 'Kanki (1229–1232)',
				'122' => 'Jōei (1232–1233)',
				'123' => 'Tenpuku (1233–1234)',
				'124' => 'Bunryaku (1234–1235)',
				'125' => 'Katei (1235–1238)',
				'126' => 'Ryakunin (1238–1239)',
				'127' => 'En’ō (1239–1240)',
				'128' => 'Ninji (1240–1243)',
				'129' => 'Kangen (1243–1247)',
				'130' => 'Hōji (1247–1249)',
				'131' => 'Kenchō (1249–1256)',
				'132' => 'Kōgen (1256–1257)',
				'133' => 'Shōka (1257–1259)',
				'134' => 'Shōgen (1259–1260)',
				'135' => 'Bun’ō (1260–1261)',
				'136' => 'Kōchō (1261–1264)',
				'137' => 'Bun’ei (1264–1275)',
				'138' => 'Kenji (1275–1278)',
				'139' => 'Kōan (1278–1288)',
				'140' => 'Shōō (1288–1293)',
				'141' => 'Einin (1293–1299)',
				'142' => 'Shōan (1299–1302)',
				'143' => 'Kengen (1302–1303)',
				'144' => 'Kagen (1303–1306)',
				'145' => 'Tokuji (1306–1308)',
				'146' => 'Enkyō (1308–1311)',
				'147' => 'Ōchō (1311–1312)',
				'148' => 'Shōwa (1312–1317)',
				'149' => 'Bunpō (1317–1319)',
				'150' => 'Genō (1319–1321)',
				'151' => 'Genkō (1321–1324)',
				'152' => 'Shōchū (1324–1326)',
				'153' => 'Karyaku (1326–1329)',
				'154' => 'Gentoku (1329–1331)',
				'155' => 'Genkō (1331–1334)',
				'156' => 'Kenmu (1334–1336)',
				'157' => 'Engen (1336–1340)',
				'158' => 'Kōkoku (1340–1346)',
				'159' => 'Shōhei (1346–1370)',
				'160' => 'Kentoku (1370–1372)',
				'161' => 'Bunchū (1372–1375)',
				'162' => 'Tenju (1375–1379)',
				'163' => 'Kōryaku (1379–1381)',
				'164' => 'Kōwa (1381–1384)',
				'165' => 'Genchū (1384–1392)',
				'166' => 'Meitoku (1384–1387)',
				'167' => 'Kakei (1387–1389)',
				'168' => 'Kōō (1389–1390)',
				'169' => 'Meitoku (1390–1394)',
				'170' => 'Ōei (1394–1428)',
				'171' => 'Shōchō (1428–1429)',
				'172' => 'Eikyō (1429–1441)',
				'173' => 'Kakitsu (1441–1444)',
				'174' => 'Bun’an (1444–1449)',
				'175' => 'Hōtoku (1449–1452)',
				'176' => 'Kyōtoku (1452–1455)',
				'177' => 'Kōshō (1455–1457)',
				'178' => 'Chōroku (1457–1460)',
				'179' => 'Kanshō (1460–1466)',
				'180' => 'Bunshō (1466–1467)',
				'181' => 'Ōnin (1467–1469)',
				'182' => 'Bunmei (1469–1487)',
				'183' => 'Chōkyō (1487–1489)',
				'184' => 'Entoku (1489–1492)',
				'185' => 'Meiō (1492–1501)',
				'186' => 'Bunki (1501–1504)',
				'187' => 'Eishō (1504–1521)',
				'188' => 'Taiei (1521–1528)',
				'189' => 'Kyōroku (1528–1532)',
				'190' => 'Tenbun (1532–1555)',
				'191' => 'Kōji (1555–1558)',
				'192' => 'Eiroku (1558–1570)',
				'193' => 'Genki (1570–1573)',
				'194' => 'Tenshō (1573–1592)',
				'195' => 'Bunroku (1592–1596)',
				'196' => 'Keichō (1596–1615)',
				'197' => 'Genna (1615–1624)',
				'198' => 'Kan’ei (1624–1644)',
				'199' => 'Shōho (1644–1648)',
				'200' => 'Keian (1648–1652)',
				'201' => 'Jōō (1652–1655)',
				'202' => 'Meireki (1655–1658)',
				'203' => 'Manji (1658–1661)',
				'204' => 'Kanbun (1661–1673)',
				'205' => 'Enpō (1673–1681)',
				'206' => 'Tenna (1681–1684)',
				'207' => 'Jōkyō (1684–1688)',
				'208' => 'Genroku (1688–1704)',
				'209' => 'Hōei (1704–1711)',
				'210' => 'Shōtoku (1711–1716)',
				'211' => 'Kyōhō (1716–1736)',
				'212' => 'Genbun (1736–1741)',
				'213' => 'Kanpō (1741–1744)',
				'214' => 'Enkyō (1744–1748)',
				'215' => 'Kan’en (1748–1751)',
				'216' => 'Hōreki (1751–1764)',
				'217' => 'Meiwa (1764–1772)',
				'218' => 'An’ei (1772–1781)',
				'219' => 'Tenmei (1781–1789)',
				'220' => 'Kansei (1789–1801)',
				'221' => 'Kyōwa (1801–1804)',
				'222' => 'Bunka (1804–1818)',
				'223' => 'Bunsei (1818–1830)',
				'224' => 'Tenpō (1830–1844)',
				'225' => 'Kōka (1844–1848)',
				'226' => 'Kaei (1848–1854)',
				'227' => 'Ansei (1854–1860)',
				'228' => 'Man’en (1860–1861)',
				'229' => 'Bunkyū (1861–1864)',
				'230' => 'Genji (1864–1865)',
				'231' => 'Keiō (1865–1868)',
				'232' => 'Meiji',
				'233' => 'Taishō',
				'234' => 'Shōwa',
				'235' => 'Heisei',
				'236' => 'Reiwa'
			},
			narrow => {
				'0' => 'Taika (645–650)',
				'1' => 'Hakuchi (650–671)',
				'2' => 'Hakuhō (672–686)',
				'3' => 'Shuchō (686–701)',
				'4' => 'Taihō (701–704)',
				'5' => 'Keiun (704–708)',
				'6' => 'Wadō (708–715)',
				'7' => 'Reiki (715–717)',
				'8' => 'Yōrō (717–724)',
				'9' => 'Jinki (724–729)',
				'10' => 'Tenpyō (729–749)',
				'11' => 'Tenpyō-kampō (749–749)',
				'12' => 'Tenpyō-shōhō (749–757)',
				'13' => 'Tenpyō-hōji (757–765)',
				'14' => 'Tenpyō-jingo (765–767)',
				'15' => 'Jingo-keiun (767–770)',
				'16' => 'Hōki (770–780)',
				'17' => 'Ten-ō (781–782)',
				'18' => 'Enryaku (782–806)',
				'19' => 'Daidō (806–810)',
				'20' => 'Kōnin (810–824)',
				'21' => 'Tenchō (824–834)',
				'22' => 'Jōwa (834–848)',
				'23' => 'Kajō (848–851)',
				'24' => 'Ninju (851–854)',
				'25' => 'Saikō (854–857)',
				'26' => 'Ten-an (857–859)',
				'27' => 'Jōgan (859–877)',
				'28' => 'Gangyō (877–885)',
				'29' => 'Ninna (885–889)',
				'30' => 'Kanpyō (889–898)',
				'31' => 'Shōtai (898–901)',
				'32' => 'Engi (901–923)',
				'33' => 'Enchō (923–931)',
				'34' => 'Jōhei (931–938)',
				'35' => 'Tengyō (938–947)',
				'36' => 'Tenryaku (947–957)',
				'37' => 'Tentoku (957–961)',
				'38' => 'Ōwa (961–964)',
				'39' => 'Kōhō (964–968)',
				'40' => 'Anna (968–970)',
				'41' => 'Tenroku (970–973)',
				'42' => 'Ten’en (973–976)',
				'43' => 'Jōgen (976–978)',
				'44' => 'Tengen (978–983)',
				'45' => 'Eikan (983–985)',
				'46' => 'Kanna (985–987)',
				'47' => 'Eien (987–989)',
				'48' => 'Eiso (989–990)',
				'49' => 'Shōryaku (990–995)',
				'50' => 'Chōtoku (995–999)',
				'51' => 'Chōhō (999–1004)',
				'52' => 'Kankō (1004–1012)',
				'53' => 'Chōwa (1012–1017)',
				'54' => 'Kannin (1017–1021)',
				'55' => 'Jian (1021–1024)',
				'56' => 'Manju (1024–1028)',
				'57' => 'Chōgen (1028–1037)',
				'58' => 'Chōryaku (1037–1040)',
				'59' => 'Chōkyū (1040–1044)',
				'60' => 'Kantoku (1044–1046)',
				'61' => 'Eishō (1046–1053)',
				'62' => 'Tengi (1053–1058)',
				'63' => 'Kōhei (1058–1065)',
				'64' => 'Jiryaku (1065–1069)',
				'65' => 'Enkyū (1069–1074)',
				'66' => 'Shōho (1074–1077)',
				'67' => 'Shōryaku (1077–1081)',
				'68' => 'Eihō (1081–1084)',
				'69' => 'Ōtoku (1084–1087)',
				'70' => 'Kanji (1087–1094)',
				'71' => 'Kahō (1094–1096)',
				'72' => 'Eichō (1096–1097)',
				'73' => 'Jōtoku (1097–1099)',
				'74' => 'Kōwa (1099–1104)',
				'75' => 'Chōji (1104–1106)',
				'76' => 'Kashō (1106–1108)',
				'77' => 'Tennin (1108–1110)',
				'78' => 'Ten-ei (1110–1113)',
				'79' => 'Eikyū (1113–1118)',
				'80' => 'Gen’ei (1118–1120)',
				'81' => 'Hōan (1120–1124)',
				'82' => 'Tenji (1124–1126)',
				'83' => 'Daiji (1126–1131)',
				'84' => 'Tenshō (1131–1132)',
				'85' => 'Chōshō (1132–1135)',
				'86' => 'Hōen (1135–1141)',
				'87' => 'Eiji (1141–1142)',
				'88' => 'Kōji (1142–1144)',
				'89' => 'Ten’yō (1144–1145)',
				'90' => 'Kyūan (1145–1151)',
				'91' => 'Ninpei (1151–1154)',
				'92' => 'Kyūju (1154–1156)',
				'93' => 'Hōgen (1156–1159)',
				'94' => 'Heiji (1159–1160)',
				'95' => 'Eiryaku (1160–1161)',
				'96' => 'Ōho (1161–1163)',
				'97' => 'Chōkan (1163–1165)',
				'98' => 'Eiman (1165–1166)',
				'99' => 'Nin’an (1166–1169)',
				'100' => 'Kaō (1169–1171)',
				'101' => 'Shōan (1171–1175)',
				'102' => 'Angen (1175–1177)',
				'103' => 'Jishō (1177–1181)',
				'104' => 'Yōwa (1181–1182)',
				'105' => 'Juei (1182–1184)',
				'106' => 'Genryaku (1184–1185)',
				'107' => 'Bunji (1185–1190)',
				'108' => 'Kenkyū (1190–1199)',
				'109' => 'Shōji (1199–1201)',
				'110' => 'Kennin (1201–1204)',
				'111' => 'Genkyū (1204–1206)',
				'112' => 'Ken’ei (1206–1207)',
				'113' => 'Jōgen (1207–1211)',
				'114' => 'Kenryaku (1211–1213)',
				'115' => 'Kenpō (1213–1219)',
				'116' => 'Jōkyū (1219–1222)',
				'117' => 'Jōō (1222–1224)',
				'118' => 'Gennin (1224–1225)',
				'119' => 'Karoku (1225–1227)',
				'120' => 'Antei (1227–1229)',
				'121' => 'Kanki (1229–1232)',
				'122' => 'Jōei (1232–1233)',
				'123' => 'Tenpuku (1233–1234)',
				'124' => 'Bunryaku (1234–1235)',
				'125' => 'Katei (1235–1238)',
				'126' => 'Ryakunin (1238–1239)',
				'127' => 'En’ō (1239–1240)',
				'128' => 'Ninji (1240–1243)',
				'129' => 'Kangen (1243–1247)',
				'130' => 'Hōji (1247–1249)',
				'131' => 'Kenchō (1249–1256)',
				'132' => 'Kōgen (1256–1257)',
				'133' => 'Shōka (1257–1259)',
				'134' => 'Shōgen (1259–1260)',
				'135' => 'Bun’ō (1260–1261)',
				'136' => 'Kōchō (1261–1264)',
				'137' => 'Bun’ei (1264–1275)',
				'138' => 'Kenji (1275–1278)',
				'139' => 'Kōan (1278–1288)',
				'140' => 'Shōō (1288–1293)',
				'141' => 'Einin (1293–1299)',
				'142' => 'Shōan (1299–1302)',
				'143' => 'Kengen (1302–1303)',
				'144' => 'Kagen (1303–1306)',
				'145' => 'Tokuji (1306–1308)',
				'146' => 'Enkyō (1308–1311)',
				'147' => 'Ōchō (1311–1312)',
				'148' => 'Shōwa (1312–1317)',
				'149' => 'Bunpō (1317–1319)',
				'150' => 'Genō (1319–1321)',
				'151' => 'Genkō (1321–1324)',
				'152' => 'Shōchū (1324–1326)',
				'153' => 'Karyaku (1326–1329)',
				'154' => 'Gentoku (1329–1331)',
				'155' => 'Genkō (1331–1334)',
				'156' => 'Kenmu (1334–1336)',
				'157' => 'Engen (1336–1340)',
				'158' => 'Kōkoku (1340–1346)',
				'159' => 'Shōhei (1346–1370)',
				'160' => 'Kentoku (1370–1372)',
				'161' => 'Bunchū (1372–1375)',
				'162' => 'Tenju (1375–1379)',
				'163' => 'Kōryaku (1379–1381)',
				'164' => 'Kōwa (1381–1384)',
				'165' => 'Genchū (1384–1392)',
				'166' => 'Meitoku (1384–1387)',
				'167' => 'Kakei (1387–1389)',
				'168' => 'Kōō (1389–1390)',
				'169' => 'Meitoku (1390–1394)',
				'170' => 'Ōei (1394–1428)',
				'171' => 'Shōchō (1428–1429)',
				'172' => 'Eikyō (1429–1441)',
				'173' => 'Kakitsu (1441–1444)',
				'174' => 'Bun’an (1444–1449)',
				'175' => 'Hōtoku (1449–1452)',
				'176' => 'Kyōtoku (1452–1455)',
				'177' => 'Kōshō (1455–1457)',
				'178' => 'Chōroku (1457–1460)',
				'179' => 'Kanshō (1460–1466)',
				'180' => 'Bunshō (1466–1467)',
				'181' => 'Ōnin (1467–1469)',
				'182' => 'Bunmei (1469–1487)',
				'183' => 'Chōkyō (1487–1489)',
				'184' => 'Entoku (1489–1492)',
				'185' => 'Meiō (1492–1501)',
				'186' => 'Bunki (1501–1504)',
				'187' => 'Eishō (1504–1521)',
				'188' => 'Taiei (1521–1528)',
				'189' => 'Kyōroku (1528–1532)',
				'190' => 'Tenbun (1532–1555)',
				'191' => 'Kōji (1555–1558)',
				'192' => 'Eiroku (1558–1570)',
				'193' => 'Genki (1570–1573)',
				'194' => 'Tenshō (1573–1592)',
				'195' => 'Bunroku (1592–1596)',
				'196' => 'Keichō (1596–1615)',
				'197' => 'Genna (1615–1624)',
				'198' => 'Kan’ei (1624–1644)',
				'199' => 'Shōho (1644–1648)',
				'200' => 'Keian (1648–1652)',
				'201' => 'Jōō (1652–1655)',
				'202' => 'Meireki (1655–1658)',
				'203' => 'Manji (1658–1661)',
				'204' => 'Kanbun (1661–1673)',
				'205' => 'Enpō (1673–1681)',
				'206' => 'Tenna (1681–1684)',
				'207' => 'Jōkyō (1684–1688)',
				'208' => 'Genroku (1688–1704)',
				'209' => 'Hōei (1704–1711)',
				'210' => 'Shōtoku (1711–1716)',
				'211' => 'Kyōhō (1716–1736)',
				'212' => 'Genbun (1736–1741)',
				'213' => 'Kanpō (1741–1744)',
				'214' => 'Enkyō (1744–1748)',
				'215' => 'Kan’en (1748–1751)',
				'216' => 'Hōreki (1751–1764)',
				'217' => 'Meiwa (1764–1772)',
				'218' => 'An’ei (1772–1781)',
				'219' => 'Tenmei (1781–1789)',
				'220' => 'Kansei (1789–1801)',
				'221' => 'Kyōwa (1801–1804)',
				'222' => 'Bunka (1804–1818)',
				'223' => 'Bunsei (1818–1830)',
				'224' => 'Tenpō (1830–1844)',
				'225' => 'Kōka (1844–1848)',
				'226' => 'Kaei (1848–1854)',
				'227' => 'Ansei (1854–1860)',
				'228' => 'Man’en (1860–1861)',
				'229' => 'Bunkyū (1861–1864)',
				'230' => 'Genji (1864–1865)',
				'231' => 'Keiō (1865–1868)',
				'232' => 'M',
				'233' => 'T',
				'234' => 'S',
				'235' => 'H',
				'236' => 'R'
			},
			wide => {
				'alias' => 'abbreviated'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => 'AP'
			},
			narrow => {
				'alias' => 'abbreviated'
			},
			wide => {
				'alias' => 'abbreviated'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'Before R.O.C.',
				'1' => 'R.O.C.'
			},
			narrow => {
				'alias' => 'abbreviated'
			},
			wide => {
				'alias' => 'abbreviated'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			'alias' => q{generic},
		},
		'chinese' => {
			'full' => q{r(U) MMMM d, EEEE},
			'long' => q{r(U) MMMM d},
			'medium' => q{r MMM d},
			'short' => q{r-MM-dd},
		},
		'coptic' => {
			'alias' => q{generic},
		},
		'dangi' => {
			'alias' => q{chinese},
		},
		'ethiopic' => {
			'alias' => q{generic},
		},
		'ethiopic-amete-alem' => {
			'alias' => q{ethiopic},
		},
		'generic' => {
			'full' => q{G y MMMM d, EEEE},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{y MMMM d, EEEE},
			'long' => q{y MMMM d},
			'medium' => q{y MMM d},
			'short' => q{y-MM-dd},
		},
		'hebrew' => {
			'alias' => q{generic},
		},
		'indian' => {
			'alias' => q{generic},
		},
		'islamic' => {
			'alias' => q{generic},
		},
		'islamic-civil' => {
			'alias' => q{islamic},
		},
		'islamic-rgsa' => {
			'alias' => q{islamic},
		},
		'islamic-tbla' => {
			'alias' => q{islamic},
		},
		'islamic-umalqura' => {
			'alias' => q{islamic},
		},
		'japanese' => {
			'alias' => q{generic},
		},
		'persian' => {
			'alias' => q{generic},
		},
		'roc' => {
			'alias' => q{generic},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			'alias' => q{gregorian},
		},
		'chinese' => {
			'alias' => q{gregorian},
		},
		'coptic' => {
			'alias' => q{gregorian},
		},
		'dangi' => {
			'alias' => q{chinese},
		},
		'ethiopic' => {
			'alias' => q{gregorian},
		},
		'ethiopic-amete-alem' => {
			'alias' => q{ethiopic},
		},
		'generic' => {
			'alias' => q{gregorian},
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
		},
		'hebrew' => {
			'alias' => q{gregorian},
		},
		'indian' => {
			'alias' => q{gregorian},
		},
		'islamic' => {
			'alias' => q{gregorian},
		},
		'islamic-civil' => {
			'alias' => q{islamic},
		},
		'islamic-rgsa' => {
			'alias' => q{islamic},
		},
		'islamic-tbla' => {
			'alias' => q{islamic},
		},
		'islamic-umalqura' => {
			'alias' => q{islamic},
		},
		'japanese' => {
			'alias' => q{gregorian},
		},
		'persian' => {
			'alias' => q{gregorian},
		},
		'roc' => {
			'alias' => q{gregorian},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			'alias' => q{generic},
		},
		'chinese' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'coptic' => {
			'alias' => q{generic},
		},
		'dangi' => {
			'alias' => q{chinese},
		},
		'ethiopic' => {
			'alias' => q{generic},
		},
		'ethiopic-amete-alem' => {
			'alias' => q{ethiopic},
		},
		'generic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'hebrew' => {
			'alias' => q{generic},
		},
		'indian' => {
			'alias' => q{generic},
		},
		'islamic' => {
			'alias' => q{generic},
		},
		'islamic-civil' => {
			'alias' => q{islamic},
		},
		'islamic-rgsa' => {
			'alias' => q{islamic},
		},
		'islamic-tbla' => {
			'alias' => q{islamic},
		},
		'islamic-umalqura' => {
			'alias' => q{islamic},
		},
		'japanese' => {
			'alias' => q{generic},
		},
		'persian' => {
			'alias' => q{generic},
		},
		'roc' => {
			'alias' => q{generic},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			'alias' => q{generic},
		},
		'chinese' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			Ed => q{d, E},
			Gy => q{r U},
			GyMMM => q{r MMM},
			GyMMMEd => q{r MMM d, E},
			GyMMMM => q{r(U) MMMM},
			GyMMMMEd => q{r(U) MMMM d, E},
			GyMMMMd => q{r(U) MMMM d},
			GyMMMd => q{r MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{MM-dd, E},
			MMM => q{LLL},
			MMMEd => q{MMM d, E},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{MM-dd},
			UM => q{U MM},
			UMMM => q{U MMM},
			UMMMd => q{U MMM d},
			UMd => q{U MM-d},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{r(U)},
			yMd => q{r-MM-dd},
			yyyy => q{r(U)},
			yyyyM => q{r-MM},
			yyyyMEd => q{r-MM-dd, E},
			yyyyMMM => q{r MMM},
			yyyyMMMEd => q{r MMM d, E},
			yyyyMMMM => q{r(U) MMMM},
			yyyyMMMMEd => q{r(U) MMMM d, E},
			yyyyMMMMd => q{r(U) MMMM d},
			yyyyMMMd => q{r MMM d},
			yyyyMd => q{r-MM-dd},
			yyyyQQQ => q{r(U) QQQ},
			yyyyQQQQ => q{r(U) QQQQ},
		},
		'coptic' => {
			'alias' => q{generic},
		},
		'dangi' => {
			'alias' => q{chinese},
		},
		'ethiopic' => {
			'alias' => q{generic},
		},
		'ethiopic-amete-alem' => {
			'alias' => q{ethiopic},
		},
		'generic' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			GyMd => q{GGGGG y-MM-dd},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{MM-dd, E},
			MMM => q{LLL},
			MMMEd => q{MMM d, E},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{MM-dd},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{G y},
			yyyy => q{G y},
			yyyyM => q{GGGGG y-MM},
			yyyyMEd => q{GGGGG y-MM-dd, E},
			yyyyMMM => q{G y MMM},
			yyyyMMMEd => q{G y MMM d, E},
			yyyyMMMM => q{G y MMMM},
			yyyyMMMd => q{G y MMM d},
			yyyyMd => q{GGGGG y-MM-dd},
			yyyyQQQ => q{G y QQQ},
			yyyyQQQQ => q{G y QQQQ},
		},
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			GyMd => q{GGGGG y-MM-dd},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{MM-dd, E},
			MMM => q{LLL},
			MMMEd => q{MMM d, E},
			MMMMW => q{'week' W 'of' MMMM},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{MM-dd},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{y-MM},
			yMEd => q{y-MM-dd, E},
			yMMM => q{y MMM},
			yMMMEd => q{y MMM d, E},
			yMMMM => q{y MMMM},
			yMMMd => q{y MMM d},
			yMd => q{y-MM-dd},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
			yw => q{'week' w 'of' Y},
		},
		'hebrew' => {
			'alias' => q{generic},
		},
		'indian' => {
			'alias' => q{generic},
		},
		'islamic' => {
			'alias' => q{generic},
		},
		'islamic-civil' => {
			'alias' => q{islamic},
		},
		'islamic-rgsa' => {
			'alias' => q{islamic},
		},
		'islamic-tbla' => {
			'alias' => q{islamic},
		},
		'islamic-umalqura' => {
			'alias' => q{islamic},
		},
		'japanese' => {
			'alias' => q{generic},
		},
		'persian' => {
			'alias' => q{generic},
		},
		'roc' => {
			'alias' => q{generic},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			'alias' => q{generic},
		},
		'chinese' => {
			'Day' => '{0} ({2}: {1})',
			'Day-Of-Week' => '{0} {1}',
			'Era' => '{1} {0}',
			'Hour' => '{0} ({2}: {1})',
			'Minute' => '{0} ({2}: {1})',
			'Month' => '{0} ({2}: {1})',
			'Quarter' => '{0} ({2}: {1})',
			'Second' => '{0} ({2}: {1})',
			'Timezone' => '{0} {1}',
			'Week' => '{0} ({2}: {1})',
			'Year' => '{1} {0}',
		},
		'coptic' => {
			'alias' => q{generic},
		},
		'dangi' => {
			'alias' => q{chinese},
		},
		'ethiopic' => {
			'alias' => q{generic},
		},
		'ethiopic-amete-alem' => {
			'alias' => q{ethiopic},
		},
		'generic' => {
			'Day' => '{0} ({2}: {1})',
			'Day-Of-Week' => '{0} {1}',
			'Era' => '{1} {0}',
			'Hour' => '{0} ({2}: {1})',
			'Minute' => '{0} ({2}: {1})',
			'Month' => '{0} ({2}: {1})',
			'Quarter' => '{0} ({2}: {1})',
			'Second' => '{0} ({2}: {1})',
			'Timezone' => '{0} {1}',
			'Week' => '{0} ({2}: {1})',
			'Year' => '{1} {0}',
		},
		'gregorian' => {
			'Day' => '{0} ({2}: {1})',
			'Day-Of-Week' => '{0} {1}',
			'Era' => '{1} {0}',
			'Hour' => '{0} ({2}: {1})',
			'Minute' => '{0} ({2}: {1})',
			'Month' => '{0} ({2}: {1})',
			'Quarter' => '{0} ({2}: {1})',
			'Second' => '{0} ({2}: {1})',
			'Timezone' => '{0} {1}',
			'Week' => '{0} ({2}: {1})',
			'Year' => '{1} {0}',
		},
		'hebrew' => {
			'alias' => q{generic},
		},
		'indian' => {
			'alias' => q{generic},
		},
		'islamic' => {
			'alias' => q{generic},
		},
		'islamic-civil' => {
			'alias' => q{islamic},
		},
		'islamic-rgsa' => {
			'alias' => q{islamic},
		},
		'islamic-tbla' => {
			'alias' => q{islamic},
		},
		'islamic-umalqura' => {
			'alias' => q{islamic},
		},
		'japanese' => {
			'alias' => q{generic},
		},
		'persian' => {
			'alias' => q{generic},
		},
		'roc' => {
			'alias' => q{generic},
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			'alias' => q{generic},
		},
		'chinese' => {
			Bh => {
				B => q{h B – h B},
				h => q{h–h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{U–U},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{U MMM–MMM},
				y => q{U MMM – U MMM},
			},
			yMMMEd => {
				M => q{U MMM d, E – MMM d, E},
				d => q{U MMM d, E – MMM d, E},
				y => q{U MMM d, E – U MMM d, E},
			},
			yMMMM => {
				M => q{U MMMM–MMMM},
				y => q{U MMMM – U MMMM},
			},
			yMMMd => {
				M => q{U MMM d – MMM d},
				d => q{U MMM d–d},
				y => q{U MMM d – U MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
		'coptic' => {
			'alias' => q{generic},
		},
		'dangi' => {
			'alias' => q{chinese},
		},
		'ethiopic' => {
			'alias' => q{generic},
		},
		'ethiopic-amete-alem' => {
			'alias' => q{ethiopic},
		},
		'generic' => {
			Bh => {
				B => q{h B – h B},
				h => q{h–h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
			Gy => {
				G => q{G y – G y},
				y => q{G y–y},
			},
			GyM => {
				G => q{GGGGG y-MM – GGGGG y-MM},
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			GyMEd => {
				G => q{GGGGG y-MM-dd, E – GGGGG y-MM-dd, E},
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			GyMMM => {
				G => q{G y MMM – G y MMM},
				M => q{G y MMM–MMM},
				y => q{G y MMM – y MMM},
			},
			GyMMMEd => {
				G => q{G y MMM d, E – G y MMM d, E},
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			GyMMMd => {
				G => q{G y MMM d – G y MMM d},
				M => q{G y MMM d – MMM d},
				d => q{G y MMM d–d},
				y => q{G y MMM d – y MMM d},
			},
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{G y–y},
			},
			yM => {
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			yMEd => {
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{G y MMM–MMM},
				y => q{G y MMM – y MMM},
			},
			yMMMEd => {
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{G y MMMM–MMMM},
				y => q{G y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{G y MMM d – MMM d},
				d => q{G y MMM d–d},
				y => q{G y MMM d – y MMM d},
			},
			yMd => {
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B – h B},
				h => q{h–h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
			Gy => {
				G => q{G y – G y},
				y => q{G y–y},
			},
			GyM => {
				G => q{GGGGG y-MM – GGGGG y-MM},
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			GyMEd => {
				G => q{GGGGG y-MM-dd, E – GGGGG y-MM-dd, E},
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			GyMMM => {
				G => q{G y MMM – G y MMM},
				M => q{G y MMM–MMM},
				y => q{G y MMM – y MMM},
			},
			GyMMMEd => {
				G => q{G y MMM d, E – G y MMM d, E},
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			GyMMMd => {
				G => q{G y MMM d – G y MMM d},
				M => q{G y MMM d – MMM d},
				d => q{G y MMM d–d},
				y => q{G y MMM d – y MMM d},
			},
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{y MMM–MMM},
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				M => q{y MMM d, E – MMM d, E},
				d => q{y MMM d, E – MMM d, E},
				y => q{y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{y MMMM–MMMM},
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				d => q{y MMM d–d},
				y => q{y MMM d – y MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
		'hebrew' => {
			'alias' => q{generic},
		},
		'indian' => {
			'alias' => q{generic},
		},
		'islamic' => {
			'alias' => q{generic},
		},
		'islamic-civil' => {
			'alias' => q{islamic},
		},
		'islamic-rgsa' => {
			'alias' => q{islamic},
		},
		'islamic-tbla' => {
			'alias' => q{islamic},
		},
		'islamic-umalqura' => {
			'alias' => q{islamic},
		},
		'japanese' => {
			'alias' => q{generic},
		},
		'persian' => {
			'alias' => q{generic},
		},
		'roc' => {
			'alias' => q{generic},
		},
	} },
);

has 'month_patterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'format' => {
				'abbreviated' => {
                    alias => {
                        context => 'format',
                        width    => 'wide',
                    },

				},
				'narrow' => {
                    alias => {
                        context => 'stand-alone',
                        width    => 'narrow',
                    },

				},
				'wide' => {
					'leap' => q{{0}bis},
				},
			},
			'numeric' => {
				'all' => {
					'leap' => q{{0}bis},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
                    alias => {
                        context => 'format',
                        width    => 'abbreviated',
                    },

				},
				'narrow' => {
					'leap' => q{{0}b},
				},
				'wide' => {
                    alias => {
                        context => 'format',
                        width    => 'wide',
                    },

				},
			},
		},
		'dangi' => {
			alias => 'chinese'
		},
	} },
);

has 'cyclic_name_sets' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'dayParts' => {
				'format' => {
					'abbreviated' => {
						0 => q(zi),
						1 => q(chou),
						2 => q(yin),
						3 => q(mao),
						4 => q(chen),
						5 => q(si),
						6 => q(wu),
						7 => q(wei),
						8 => q(shen),
						9 => q(you),
						10 => q(xu),
						11 => q(hai),
					},
					'narrow' => {
						alias => {
							context	=> q{format},
							name_set	=> q{dayParts},
							type	=> q{abbreviated},
						},
					},
					'wide' => {
						alias => {
							context	=> q{format},
							name_set	=> q{dayParts},
							type	=> q{abbreviated},
						},
					},
				},
			},
			'days' => {
				alias => q(years),
			},
			'months' => {
				alias => q(years),
			},
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(spring begins),
						1 => q(rain water),
						2 => q(insects awaken),
						3 => q(spring equinox),
						4 => q(bright and clear),
						5 => q(grain rain),
						6 => q(summer begins),
						7 => q(grain full),
						8 => q(grain in ear),
						9 => q(summer solstice),
						10 => q(minor heat),
						11 => q(major heat),
						12 => q(autumn begins),
						13 => q(end of heat),
						14 => q(white dew),
						15 => q(autumn equinox),
						16 => q(cold dew),
						17 => q(frost descends),
						18 => q(winter begins),
						19 => q(minor snow),
						20 => q(major snow),
						21 => q(winter solstice),
						22 => q(minor cold),
						23 => q(major cold),
					},
					'narrow' => {
						alias => {
							context	=> q{format},
							name_set	=> q{solarTerms},
							type	=> q{abbreviated},
						},
					},
					'wide' => {
						alias => {
							context	=> q{format},
							name_set	=> q{solarTerms},
							type	=> q{abbreviated},
						},
					},
				},
			},
			'years' => {
				'format' => {
					'abbreviated' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
					'narrow' => {
						alias => {
							context	=> q{format},
							name_set	=> q{years},
							type	=> q{abbreviated},
						},
					},
					'wide' => {
						alias => {
							context	=> q{format},
							name_set	=> q{years},
							type	=> q{abbreviated},
						},
					},
				},
			},
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						alias => {
							context	=> q{format},
							name_set	=> q{dayParts},
							type	=> q{abbreviated},
						},
					},
					'narrow' => {
						alias => {
							context	=> q{format},
							name_set	=> q{zodiacs},
							type	=> q{abbreviated},
						},
					},
					'wide' => {
						alias => {
							context	=> q{format},
							name_set	=> q{zodiacs},
							type	=> q{abbreviated},
						},
					},
				},
			},
		},
		'dangi' => {
			alias => 'chinese',
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0}),
		regionFormat => q({0} (+1)),
		regionFormat => q({0} (+0)),
		fallbackFormat => q({1} ({0})),
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahía de Banderas#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancún#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Ciudad Juárez#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokan#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox, Indiana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indiana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg, Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City, Indiana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay, Indiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac, Indiana#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello, Kentucky#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Merida' => {
			exemplarCity => q#Mérida#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, North Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, North Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, North Dakota#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St. Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St. Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St. Vincent#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Kathmandu#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macao#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangon#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroe#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#St. Helena#,
		},
		'Etc/UTC' => {
			short => {
				'standard' => q#UTC#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Unknown#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kyiv#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Chuuk#,
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
