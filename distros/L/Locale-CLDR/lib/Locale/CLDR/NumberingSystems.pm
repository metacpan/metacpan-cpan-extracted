package Locale::CLDR::NumberingSystems;
# This file auto generated from Data\common\supplemental\numberingSystems.xml
#	on Sun  5 Aug  5:49:08 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo::Role;

has 'numbering_system' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { return {
		'adlm'	=> {
			type	=> 'numeric',
			data	=> [qw(𞥐 𞥑 𞥒 𞥓 𞥔 𞥕 𞥖 𞥗 𞥘 𞥙)],
		},
		'ahom'	=> {
			type	=> 'numeric',
			data	=> [qw(𑜰 𑜱 𑜲 𑜳 𑜴 𑜵 𑜶 𑜷 𑜸 𑜹)],
		},
		'arab'	=> {
			type	=> 'numeric',
			data	=> [qw(٠ ١ ٢ ٣ ٤ ٥ ٦ ٧ ٨ ٩)],
		},
		'arabext'	=> {
			type	=> 'numeric',
			data	=> [qw(۰ ۱ ۲ ۳ ۴ ۵ ۶ ۷ ۸ ۹)],
		},
		'armn'	=> {
			type	=> 'algorithmic',
			data	=> 'armenian-upper',
		},
		'armnlow'	=> {
			type	=> 'algorithmic',
			data	=> 'armenian-lower',
		},
		'bali'	=> {
			type	=> 'numeric',
			data	=> [qw(᭐ ᭑ ᭒ ᭓ ᭔ ᭕ ᭖ ᭗ ᭘ ᭙)],
		},
		'beng'	=> {
			type	=> 'numeric',
			data	=> [qw(০ ১ ২ ৩ ৪ ৫ ৬ ৭ ৮ ৯)],
		},
		'bhks'	=> {
			type	=> 'numeric',
			data	=> [qw(𑱐 𑱑 𑱒 𑱓 𑱔 𑱕 𑱖 𑱗 𑱘 𑱙)],
		},
		'brah'	=> {
			type	=> 'numeric',
			data	=> [qw(𑁦 𑁧 𑁨 𑁩 𑁪 𑁫 𑁬 𑁭 𑁮 𑁯)],
		},
		'cakm'	=> {
			type	=> 'numeric',
			data	=> [qw(𑄶 𑄷 𑄸 𑄹 𑄺 𑄻 𑄼 𑄽 𑄾 𑄿)],
		},
		'cham'	=> {
			type	=> 'numeric',
			data	=> [qw(꩐ ꩑ ꩒ ꩓ ꩔ ꩕ ꩖ ꩗ ꩘ ꩙)],
		},
		'cyrl'	=> {
			type	=> 'algorithmic',
			data	=> 'cyrillic-lower',
		},
		'deva'	=> {
			type	=> 'numeric',
			data	=> [qw(० १ २ ३ ४ ५ ६ ७ ८ ९)],
		},
		'ethi'	=> {
			type	=> 'algorithmic',
			data	=> 'ethiopic',
		},
		'fullwide'	=> {
			type	=> 'numeric',
			data	=> [qw(０ １ ２ ３ ４ ５ ６ ７ ８ ９)],
		},
		'geor'	=> {
			type	=> 'algorithmic',
			data	=> 'georgian',
		},
		'gonm'	=> {
			type	=> 'numeric',
			data	=> [qw(𑵐 𑵑 𑵒 𑵓 𑵔 𑵕 𑵖 𑵗 𑵘 𑵙)],
		},
		'grek'	=> {
			type	=> 'algorithmic',
			data	=> 'greek-upper',
		},
		'greklow'	=> {
			type	=> 'algorithmic',
			data	=> 'greek-lower',
		},
		'gujr'	=> {
			type	=> 'numeric',
			data	=> [qw(૦ ૧ ૨ ૩ ૪ ૫ ૬ ૭ ૮ ૯)],
		},
		'guru'	=> {
			type	=> 'numeric',
			data	=> [qw(੦ ੧ ੨ ੩ ੪ ੫ ੬ ੭ ੮ ੯)],
		},
		'hanidays'	=> {
			type	=> 'algorithmic',
			data	=> 'zh/SpelloutRules/spellout-numbering-days',
		},
		'hanidec'	=> {
			type	=> 'numeric',
			data	=> [qw(〇 一 二 三 四 五 六 七 八 九)],
		},
		'hans'	=> {
			type	=> 'algorithmic',
			data	=> 'zh/SpelloutRules/spellout-cardinal',
		},
		'hansfin'	=> {
			type	=> 'algorithmic',
			data	=> 'zh/SpelloutRules/spellout-cardinal-financial',
		},
		'hant'	=> {
			type	=> 'algorithmic',
			data	=> 'zh_Hant/SpelloutRules/spellout-cardinal',
		},
		'hantfin'	=> {
			type	=> 'algorithmic',
			data	=> 'zh_Hant/SpelloutRules/spellout-cardinal-financial',
		},
		'hebr'	=> {
			type	=> 'algorithmic',
			data	=> 'hebrew',
		},
		'hmng'	=> {
			type	=> 'numeric',
			data	=> [qw(𖭐 𖭑 𖭒 𖭓 𖭔 𖭕 𖭖 𖭗 𖭘 𖭙)],
		},
		'java'	=> {
			type	=> 'numeric',
			data	=> [qw(꧐ ꧑ ꧒ ꧓ ꧔ ꧕ ꧖ ꧗ ꧘ ꧙)],
		},
		'jpan'	=> {
			type	=> 'algorithmic',
			data	=> 'ja/SpelloutRules/spellout-cardinal',
		},
		'jpanfin'	=> {
			type	=> 'algorithmic',
			data	=> 'ja/SpelloutRules/spellout-cardinal-financial',
		},
		'kali'	=> {
			type	=> 'numeric',
			data	=> [qw(꤀ ꤁ ꤂ ꤃ ꤄ ꤅ ꤆ ꤇ ꤈ ꤉)],
		},
		'khmr'	=> {
			type	=> 'numeric',
			data	=> [qw(០ ១ ២ ៣ ៤ ៥ ៦ ៧ ៨ ៩)],
		},
		'knda'	=> {
			type	=> 'numeric',
			data	=> [qw(೦ ೧ ೨ ೩ ೪ ೫ ೬ ೭ ೮ ೯)],
		},
		'lana'	=> {
			type	=> 'numeric',
			data	=> [qw(᪀ ᪁ ᪂ ᪃ ᪄ ᪅ ᪆ ᪇ ᪈ ᪉)],
		},
		'lanatham'	=> {
			type	=> 'numeric',
			data	=> [qw(᪐ ᪑ ᪒ ᪓ ᪔ ᪕ ᪖ ᪗ ᪘ ᪙)],
		},
		'laoo'	=> {
			type	=> 'numeric',
			data	=> [qw(໐ ໑ ໒ ໓ ໔ ໕ ໖ ໗ ໘ ໙)],
		},
		'latn'	=> {
			type	=> 'numeric',
			data	=> [qw(0 1 2 3 4 5 6 7 8 9)],
		},
		'lepc'	=> {
			type	=> 'numeric',
			data	=> [qw(᱀ ᱁ ᱂ ᱃ ᱄ ᱅ ᱆ ᱇ ᱈ ᱉)],
		},
		'limb'	=> {
			type	=> 'numeric',
			data	=> [qw(᥆ ᥇ ᥈ ᥉ ᥊ ᥋ ᥌ ᥍ ᥎ ᥏)],
		},
		'mathbold'	=> {
			type	=> 'numeric',
			data	=> [qw(𝟎 𝟏 𝟐 𝟑 𝟒 𝟓 𝟔 𝟕 𝟖 𝟗)],
		},
		'mathdbl'	=> {
			type	=> 'numeric',
			data	=> [qw(𝟘 𝟙 𝟚 𝟛 𝟜 𝟝 𝟞 𝟟 𝟠 𝟡)],
		},
		'mathmono'	=> {
			type	=> 'numeric',
			data	=> [qw(𝟶 𝟷 𝟸 𝟹 𝟺 𝟻 𝟼 𝟽 𝟾 𝟿)],
		},
		'mathsanb'	=> {
			type	=> 'numeric',
			data	=> [qw(𝟬 𝟭 𝟮 𝟯 𝟰 𝟱 𝟲 𝟳 𝟴 𝟵)],
		},
		'mathsans'	=> {
			type	=> 'numeric',
			data	=> [qw(𝟢 𝟣 𝟤 𝟥 𝟦 𝟧 𝟨 𝟩 𝟪 𝟫)],
		},
		'mlym'	=> {
			type	=> 'numeric',
			data	=> [qw(൦ ൧ ൨ ൩ ൪ ൫ ൬ ൭ ൮ ൯)],
		},
		'modi'	=> {
			type	=> 'numeric',
			data	=> [qw(𑙐 𑙑 𑙒 𑙓 𑙔 𑙕 𑙖 𑙗 𑙘 𑙙)],
		},
		'mong'	=> {
			type	=> 'numeric',
			data	=> [qw(᠐ ᠑ ᠒ ᠓ ᠔ ᠕ ᠖ ᠗ ᠘ ᠙)],
		},
		'mroo'	=> {
			type	=> 'numeric',
			data	=> [qw(𖩠 𖩡 𖩢 𖩣 𖩤 𖩥 𖩦 𖩧 𖩨 𖩩)],
		},
		'mtei'	=> {
			type	=> 'numeric',
			data	=> [qw(꯰ ꯱ ꯲ ꯳ ꯴ ꯵ ꯶ ꯷ ꯸ ꯹)],
		},
		'mymr'	=> {
			type	=> 'numeric',
			data	=> [qw(၀ ၁ ၂ ၃ ၄ ၅ ၆ ၇ ၈ ၉)],
		},
		'mymrshan'	=> {
			type	=> 'numeric',
			data	=> [qw(႐ ႑ ႒ ႓ ႔ ႕ ႖ ႗ ႘ ႙)],
		},
		'mymrtlng'	=> {
			type	=> 'numeric',
			data	=> [qw(꧰ ꧱ ꧲ ꧳ ꧴ ꧵ ꧶ ꧷ ꧸ ꧹)],
		},
		'newa'	=> {
			type	=> 'numeric',
			data	=> [qw(𑑐 𑑑 𑑒 𑑓 𑑔 𑑕 𑑖 𑑗 𑑘 𑑙)],
		},
		'nkoo'	=> {
			type	=> 'numeric',
			data	=> [qw(߀ ߁ ߂ ߃ ߄ ߅ ߆ ߇ ߈ ߉)],
		},
		'olck'	=> {
			type	=> 'numeric',
			data	=> [qw(᱐ ᱑ ᱒ ᱓ ᱔ ᱕ ᱖ ᱗ ᱘ ᱙)],
		},
		'orya'	=> {
			type	=> 'numeric',
			data	=> [qw(୦ ୧ ୨ ୩ ୪ ୫ ୬ ୭ ୮ ୯)],
		},
		'osma'	=> {
			type	=> 'numeric',
			data	=> [qw(𐒠 𐒡 𐒢 𐒣 𐒤 𐒥 𐒦 𐒧 𐒨 𐒩)],
		},
		'roman'	=> {
			type	=> 'algorithmic',
			data	=> 'roman-upper',
		},
		'romanlow'	=> {
			type	=> 'algorithmic',
			data	=> 'roman-lower',
		},
		'saur'	=> {
			type	=> 'numeric',
			data	=> [qw(꣐ ꣑ ꣒ ꣓ ꣔ ꣕ ꣖ ꣗ ꣘ ꣙)],
		},
		'shrd'	=> {
			type	=> 'numeric',
			data	=> [qw(𑇐 𑇑 𑇒 𑇓 𑇔 𑇕 𑇖 𑇗 𑇘 𑇙)],
		},
		'sind'	=> {
			type	=> 'numeric',
			data	=> [qw(𑋰 𑋱 𑋲 𑋳 𑋴 𑋵 𑋶 𑋷 𑋸 𑋹)],
		},
		'sinh'	=> {
			type	=> 'numeric',
			data	=> [qw(෦ ෧ ෨ ෩ ෪ ෫ ෬ ෭ ෮ ෯)],
		},
		'sora'	=> {
			type	=> 'numeric',
			data	=> [qw(𑃰 𑃱 𑃲 𑃳 𑃴 𑃵 𑃶 𑃷 𑃸 𑃹)],
		},
		'sund'	=> {
			type	=> 'numeric',
			data	=> [qw(᮰ ᮱ ᮲ ᮳ ᮴ ᮵ ᮶ ᮷ ᮸ ᮹)],
		},
		'takr'	=> {
			type	=> 'numeric',
			data	=> [qw(𑛀 𑛁 𑛂 𑛃 𑛄 𑛅 𑛆 𑛇 𑛈 𑛉)],
		},
		'talu'	=> {
			type	=> 'numeric',
			data	=> [qw(᧐ ᧑ ᧒ ᧓ ᧔ ᧕ ᧖ ᧗ ᧘ ᧙)],
		},
		'taml'	=> {
			type	=> 'algorithmic',
			data	=> 'tamil',
		},
		'tamldec'	=> {
			type	=> 'numeric',
			data	=> [qw(௦ ௧ ௨ ௩ ௪ ௫ ௬ ௭ ௮ ௯)],
		},
		'telu'	=> {
			type	=> 'numeric',
			data	=> [qw(౦ ౧ ౨ ౩ ౪ ౫ ౬ ౭ ౮ ౯)],
		},
		'thai'	=> {
			type	=> 'numeric',
			data	=> [qw(๐ ๑ ๒ ๓ ๔ ๕ ๖ ๗ ๘ ๙)],
		},
		'tibt'	=> {
			type	=> 'numeric',
			data	=> [qw(༠ ༡ ༢ ༣ ༤ ༥ ༦ ༧ ༨ ༩)],
		},
		'tirh'	=> {
			type	=> 'numeric',
			data	=> [qw(𑓐 𑓑 𑓒 𑓓 𑓔 𑓕 𑓖 𑓗 𑓘 𑓙)],
		},
		'vaii'	=> {
			type	=> 'numeric',
			data	=> [qw(꘠ ꘡ ꘢ ꘣ ꘤ ꘥ ꘦ ꘧ ꘨ ꘩)],
		},
		'wara'	=> {
			type	=> 'numeric',
			data	=> [qw(𑣠 𑣡 𑣢 𑣣 𑣤 𑣥 𑣦 𑣧 𑣨 𑣩)],
		},
	}},
);

has '_default_numbering_system' => ( 
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default	=> '',
	clearer	=> '_clear_default_nu',
	writer	=> '_set_default_numbering_system',
);

sub _set_default_nu {
	my ($self, $system) = @_;
	my $default = $self->_default_numbering_system // '';
	$self->_set_default_numbering_system("$default$system");
}

sub _test_default_nu {
	my $self = shift;
	return length $self->_default_numbering_system ? 1 : 0;
}

sub default_numbering_system {
	my $self = shift;
	
	if($self->_test_default_nu) {
		return $self->_default_numbering_system;
	}
	else {
		my $numbering_system = $self->_find_bundle('default_numbering_system')->default_numbering_system;
		$self->_set_default_nu($numbering_system);
		return $numbering_system
	}
}

no Moo::Role;

1;

# vim: tabstop=4
