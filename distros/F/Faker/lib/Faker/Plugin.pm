package Faker::Plugin;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'with';

with 'Venus::Role::Buildable';
with 'Venus::Role::Optional';

# VERSION

our $VERSION = '1.17';

# ATTRIBUTES

attr 'faker';

# DEFAULTS

sub coerce_faker {
  return 'Faker';
}

sub default_faker {
  return {};
}

# METHODS

sub execute {
  my ($self, $data) = @_;

  return '';
}

sub process {
  my ($self, $data, @types) = @_;

  return $self->process_format($self->process_markers($data, @types));
}

sub process_format {
  my ($self, $data) = @_;

  $data = join ' ', @$data if ref $data eq 'ARRAY';

  $data =~ s/\{\{\s?([#\.\w]+)\s?\}\}/$self->resolve($1)/eg;

  return $data;
}

sub process_markers {
  my ($self, $data, @types) = @_;

  my @methods = map "process_markers_for_${_}", (
    @types ? @types : qw(letters newlines numbers)
  );

  for my $method (@methods) {
    $data = $self->$method($data);
  }

  return $data;
}

sub process_markers_for_letters {
  my ($self, $data) = @_;

  my $random = $self->faker->random;

  $data =~ s/\?/$random->letter/eg;

  return $data;
}

sub process_markers_for_newlines {
  my ($self, $data) = @_;

  $data =~ s/\\n/\n/g;

  return $data;
}

sub process_markers_for_numbers {
  my ($self, $data) = @_;

  my $random = $self->faker->random;

  $data =~ s/\#/$random->digit/eg;
  $data =~ s/\%/$random->nonzero('digit')/eg;

  return $data;
}

sub resolve {
  my ($self, $method) = @_;

  return $self->faker->$method;
}

sub transliterate {
  my ($self, $data) = @_;

  state $table = {
    "'" => '',
    '/' => '',
    'À' => 'A',
    'Á' => 'A',
    'Â' => 'A',
    'Ã' => 'A',
    'Ä' => 'A',
    'Å' => 'A',
    'Æ' => 'A',
    'Ç' => 'C',
    'È' => 'E',
    'É' => 'E',
    'Ê' => 'E',
    'Ë' => 'E',
    'Ì' => 'I',
    'Í' => 'I',
    'Î' => 'I',
    'Ï' => 'I',
    'Ð' => 'D',
    'Ñ' => 'N',
    'Ò' => 'O',
    'Ó' => 'O',
    'Ô' => 'O',
    'Õ' => 'O',
    'Ö' => 'O',
    'Ø' => 'O',
    'Ù' => 'U',
    'Ú' => 'U',
    'Û' => 'U',
    'Ü' => 'U',
    'Ý' => 'Y',
    'Þ' => 'T',
    'ß' => 's',
    'à' => 'a',
    'á' => 'a',
    'â' => 'a',
    'ã' => 'a',
    'ä' => 'a',
    'å' => 'a',
    'æ' => 'a',
    'ç' => 'c',
    'è' => 'e',
    'é' => 'e',
    'ê' => 'e',
    'ë' => 'e',
    'ì' => 'i',
    'í' => 'i',
    'î' => 'i',
    'ï' => 'i',
    'ð' => 'd',
    'ñ' => 'n',
    'ò' => 'o',
    'ó' => 'o',
    'ô' => 'o',
    'õ' => 'o',
    'ö' => 'o',
    'ø' => 'o',
    'ù' => 'u',
    'ú' => 'u',
    'û' => 'u',
    'ü' => 'u',
    'ý' => 'y',
    'þ' => 't',
    'ÿ' => 'y',
    'Ā' => 'A',
    'ā' => 'a',
    'Ă' => 'A',
    'ă' => 'a',
    'Ą' => 'A',
    'ą' => 'a',
    'Ć' => 'C',
    'ć' => 'c',
    'Ĉ' => 'C',
    'ĉ' => 'c',
    'Ċ' => 'C',
    'ċ' => 'c',
    'Č' => 'C',
    'č' => 'c',
    'Ď' => 'D',
    'ď' => 'd',
    'Đ' => 'D',
    'đ' => 'd',
    'Ē' => 'E',
    'ē' => 'e',
    'Ĕ' => 'E',
    'ĕ' => 'e',
    'Ė' => 'E',
    'ė' => 'e',
    'Ę' => 'E',
    'ę' => 'e',
    'Ě' => 'E',
    'ě' => 'e',
    'Ĝ' => 'G',
    'ĝ' => 'g',
    'Ğ' => 'G',
    'ğ' => 'g',
    'Ġ' => 'G',
    'ġ' => 'g',
    'Ģ' => 'G',
    'ģ' => 'g',
    'Ĥ' => 'H',
    'ĥ' => 'h',
    'Ħ' => 'H',
    'ħ' => 'h',
    'Ĩ' => 'I',
    'ĩ' => 'i',
    'Ī' => 'I',
    'ī' => 'i',
    'Ĭ' => 'I',
    'ĭ' => 'i',
    'Į' => 'I',
    'į' => 'i',
    'İ' => 'I',
    'ı' => 'i',
    'Ĳ' => 'I',
    'ĳ' => 'i',
    'Ĵ' => 'J',
    'ĵ' => 'j',
    'Ķ' => 'K',
    'ķ' => 'k',
    'ĸ' => 'k',
    'Ĺ' => 'K',
    'ĺ' => 'l',
    'Ļ' => 'K',
    'ļ' => 'l',
    'Ľ' => 'K',
    'ľ' => 'l',
    'Ŀ' => 'K',
    'ŀ' => 'l',
    'Ł' => 'L',
    'ł' => 'l',
    'Ń' => 'N',
    'ń' => 'n',
    'Ņ' => 'N',
    'ņ' => 'n',
    'Ň' => 'N',
    'ň' => 'n',
    'ŉ' => 'n',
    'Ŋ' => 'N',
    'ŋ' => 'n',
    'Ō' => 'O',
    'ō' => 'o',
    'Ŏ' => 'O',
    'ŏ' => 'o',
    'Ő' => 'O',
    'ő' => 'o',
    'Œ' => 'O',
    'œ' => 'o',
    'Ŕ' => 'R',
    'ŕ' => 'r',
    'Ŗ' => 'R',
    'ŗ' => 'r',
    'Ř' => 'R',
    'ř' => 'r',
    'Ś' => 'S',
    'ś' => 's',
    'Ŝ' => 'S',
    'Ş' => 'S',
    'ş' => 's',
    'Š' => 'S',
    'š' => 's',
    'Ţ' => 'T',
    'ţ' => 't',
    'Ť' => 'T',
    'ť' => 't',
    'Ŧ' => 'T',
    'Ũ' => 'U',
    'ũ' => 'u',
    'Ū' => 'U',
    'ū' => 'u',
    'Ŭ' => 'U',
    'ŭ' => 'u',
    'Ů' => 'U',
    'ů' => 'u',
    'Ű' => 'U',
    'ű' => 'u',
    'Ų' => 'U',
    'ų' => 'u',
    'Ŵ' => 'W',
    'ŵ' => 'w',
    'Ŷ' => 'Y',
    'ŷ' => 'y',
    'Ÿ' => 'Y',
    'Ź' => 'Z',
    'ź' => 'z',
    'Ż' => 'Z',
    'ż' => 'z',
    'Ž' => 'Z',
    'ž' => 'z',
    'ſ' => 's',
    'ƒ' => 'f',
    'ơ' => 'o',
    'ư' => 'u',
    'Ș' => 'S',
    'ș' => 's',
    'Ț' => 'T',
    'ț' => 't',
    'ʼ' => "'",
    '̧' => '',
    'Ά' => 'A',
    'Έ' => 'E',
    'Ή' => 'I',
    'Ί' => 'I',
    'Ό' => 'O',
    'Ύ' => 'Y',
    'Ώ' => 'O',
    'ΐ' => 'i',
    'Α' => 'A',
    'Β' => 'B',
    'Γ' => 'G',
    'Δ' => 'D',
    'Ε' => 'E',
    'Ζ' => 'Z',
    'Η' => 'I',
    'Θ' => 'T',
    'Ι' => 'I',
    'Κ' => 'K',
    'Λ' => 'L',
    'Μ' => 'M',
    'Ν' => 'N',
    'Ξ' => 'K',
    'Ο' => 'O',
    'Π' => 'P',
    'Ρ' => 'R',
    'Σ' => 'S',
    'Τ' => 'T',
    'Υ' => 'Y',
    'Φ' => 'F',
    'Χ' => 'X',
    'Ψ' => 'P',
    'Ω' => 'O',
    'Ϊ' => 'I',
    'Ϋ' => 'Y',
    'ά' => 'a',
    'έ' => 'e',
    'ή' => 'i',
    'ί' => 'i',
    'ΰ' => 'y',
    'α' => 'a',
    'β' => 'b',
    'γ' => 'g',
    'δ' => 'd',
    'ε' => 'e',
    'ζ' => 'z',
    'η' => 'i',
    'θ' => 't',
    'ι' => 'i',
    'κ' => 'k',
    'λ' => 'l',
    'μ' => 'm',
    'ν' => 'n',
    'ξ' => 'k',
    'ο' => 'o',
    'π' => 'p',
    'ρ' => 'r',
    'ς' => 's',
    'σ' => 's',
    'τ' => 't',
    'υ' => 'y',
    'φ' => 'f',
    'χ' => 'x',
    'ψ' => 'p',
    'ω' => 'o',
    'ϊ' => 'i',
    'ϋ' => 'y',
    'ό' => 'o',
    'ύ' => 'y',
    'ώ' => 'o',
    'Ё' => 'E',
    'А' => 'A',
    'Б' => 'B',
    'В' => 'V',
    'Г' => 'G',
    'Д' => 'D',
    'Е' => 'E',
    'Ж' => 'Z',
    'З' => 'Z',
    'И' => 'I',
    'Й' => 'I',
    'К' => 'K',
    'Л' => 'L',
    'М' => 'M',
    'Н' => 'N',
    'О' => 'O',
    'П' => 'P',
    'Р' => 'R',
    'С' => 'S',
    'Т' => 'T',
    'У' => 'U',
    'Ф' => 'F',
    'Х' => 'K',
    'Ц' => 'T',
    'Ч' => 'C',
    'Ш' => 'S',
    'Щ' => 'S',
    'Ы' => 'Y',
    'Э' => 'E',
    'Ю' => 'Y',
    'Я' => 'Y',
    'а' => 'A',
    'б' => 'B',
    'в' => 'V',
    'г' => 'G',
    'д' => 'D',
    'е' => 'E',
    'ж' => 'Z',
    'з' => 'Z',
    'и' => 'I',
    'й' => 'I',
    'к' => 'K',
    'л' => 'L',
    'м' => 'M',
    'н' => 'N',
    'о' => 'O',
    'п' => 'P',
    'р' => 'R',
    'с' => 'S',
    'т' => 'T',
    'у' => 'U',
    'ф' => 'F',
    'х' => 'K',
    'ц' => 'T',
    'ч' => 'C',
    'ш' => 'S',
    'щ' => 'S',
    'ы' => 'Y',
    'э' => 'E',
    'ю' => 'Y',
    'я' => 'Y',
    'ё' => 'E',
    'ա' => 'a',
    'բ' => 'b',
    'գ' => 'g',
    'դ' => 'd',
    'ե' => 'e',
    'զ' => 'z',
    'է' => 'e',
    'ը' => 'y',
    'թ' => 't',
    'ժ' => 'zh',
    'ի' => 'i',
    'լ' => 'l',
    'խ' => 'kh',
    'ծ' => 'ts',
    'կ' => 'k',
    'հ' => 'h',
    'ձ' => 'dz',
    'ղ' => 'gh',
    'ճ' => 'ch',
    'մ' => 'm',
    'յ' => 'y',
    'ն' => 'n',
    'շ' => 'sh',
    'ո' => 'o',
    'ու' => 'u',
    'չ' => 'ch',
    'պ' => 'p',
    'ջ' => 'j',
    'ռ' => 'r',
    'ս' => 's',
    'վ' => 'v',
    'տ' => 't',
    'ր' => 'r',
    'ց' => 'ts',
    'փ' => 'p',
    'ք' => 'q',
    'օ' => 'o',
    'ֆ' => 'f',
    'և' => 'ev',
    'ა' => 'a',
    'ბ' => 'b',
    'გ' => 'g',
    'დ' => 'd',
    'ე' => 'e',
    'ვ' => 'v',
    'ზ' => 'z',
    'თ' => 't',
    'ი' => 'i',
    'კ' => 'k',
    'ლ' => 'l',
    'მ' => 'm',
    'ნ' => 'n',
    'ო' => 'o',
    'პ' => 'p',
    'ჟ' => 'z',
    'რ' => 'r',
    'ს' => 's',
    'ტ' => 't',
    'უ' => 'u',
    'ფ' => 'p',
    'ქ' => 'k',
    'ღ' => 'g',
    'ყ' => 'q',
    'შ' => 's',
    'ჩ' => 'c',
    'ც' => 't',
    'ძ' => 'd',
    'წ' => 't',
    'ჭ' => 'c',
    'ხ' => 'k',
    'ჯ' => 'j',
    'ჰ' => 'h',
    'Ḑ' => 'D',
    'ḑ' => 'd',
    'Ḩ' => 'H',
    'ḩ' => 'h',
    'ạ' => 'a',
    'ả' => 'a',
    'ầ' => 'a',
    'ậ' => 'a',
    'ắ' => 'a',
    'ằ' => 'a',
    'ẵ' => 'a',
    'ế' => 'e',
    'ề' => 'e',
    'ệ' => 'e',
    'ỉ' => 'i',
    'ị' => 'i',
    'ồ' => 'o',
    'ộ' => 'o',
    'ừ' => 'u',
    'ἀ' => 'a',
    'ἁ' => 'a',
    'ἂ' => 'a',
    'ἃ' => 'a',
    'ἄ' => 'a',
    'ἅ' => 'a',
    'ἆ' => 'a',
    'ἇ' => 'a',
    'Ἀ' => 'A',
    'Ἁ' => 'A',
    'Ἂ' => 'A',
    'Ἃ' => 'A',
    'Ἄ' => 'A',
    'Ἅ' => 'A',
    'Ἆ' => 'A',
    'Ἇ' => 'A',
    'ἐ' => 'e',
    'ἑ' => 'e',
    'ἒ' => 'e',
    'ἓ' => 'e',
    'ἔ' => 'e',
    'ἕ' => 'e',
    'Ἐ' => 'E',
    'Ἑ' => 'E',
    'Ἒ' => 'E',
    'Ἓ' => 'E',
    'Ἔ' => 'E',
    'Ἕ' => 'E',
    'ἠ' => 'i',
    'ἡ' => 'i',
    'ἢ' => 'i',
    'ἣ' => 'i',
    'ἤ' => 'i',
    'ἥ' => 'i',
    'ἦ' => 'i',
    'ἧ' => 'i',
    'Ἠ' => 'I',
    'Ἡ' => 'I',
    'Ἢ' => 'I',
    'Ἣ' => 'I',
    'Ἤ' => 'I',
    'Ἥ' => 'I',
    'Ἦ' => 'I',
    'Ἧ' => 'I',
    'ἰ' => 'i',
    'ἱ' => 'i',
    'ἲ' => 'i',
    'ἳ' => 'i',
    'ἴ' => 'i',
    'ἵ' => 'i',
    'ἶ' => 'i',
    'ἷ' => 'i',
    'Ἰ' => 'I',
    'Ἱ' => 'I',
    'Ἲ' => 'I',
    'Ἳ' => 'I',
    'Ἴ' => 'I',
    'Ἵ' => 'I',
    'Ἶ' => 'I',
    'Ἷ' => 'I',
    'ὀ' => 'o',
    'ὁ' => 'o',
    'ὂ' => 'o',
    'ὃ' => 'o',
    'ὄ' => 'o',
    'ὅ' => 'o',
    'Ὀ' => 'O',
    'Ὁ' => 'O',
    'Ὂ' => 'O',
    'Ὃ' => 'O',
    'Ὄ' => 'O',
    'Ὅ' => 'O',
    'ὐ' => 'y',
    'ὑ' => 'y',
    'ὒ' => 'y',
    'ὓ' => 'y',
    'ὔ' => 'y',
    'ὕ' => 'y',
    'ὖ' => 'y',
    'ὗ' => 'y',
    'Ὑ' => 'Y',
    'Ὓ' => 'Y',
    'Ὕ' => 'Y',
    'Ὗ' => 'Y',
    'ὠ' => 'o',
    'ὡ' => 'o',
    'ὢ' => 'o',
    'ὣ' => 'o',
    'ὤ' => 'o',
    'ὥ' => 'o',
    'ὦ' => 'o',
    'ὧ' => 'o',
    'Ὠ' => 'O',
    'Ὡ' => 'O',
    'Ὢ' => 'O',
    'Ὣ' => 'O',
    'Ὤ' => 'O',
    'Ὥ' => 'O',
    'Ὦ' => 'O',
    'Ὧ' => 'O',
    'ὰ' => 'a',
    'ὲ' => 'e',
    'ὴ' => 'i',
    'ὶ' => 'i',
    'ὸ' => 'o',
    'ὺ' => 'y',
    'ὼ' => 'o',
    'ᾀ' => 'a',
    'ᾁ' => 'a',
    'ᾂ' => 'a',
    'ᾃ' => 'a',
    'ᾄ' => 'a',
    'ᾅ' => 'a',
    'ᾆ' => 'a',
    'ᾇ' => 'a',
    'ᾈ' => 'A',
    'ᾉ' => 'A',
    'ᾊ' => 'A',
    'ᾋ' => 'A',
    'ᾌ' => 'A',
    'ᾍ' => 'A',
    'ᾎ' => 'A',
    'ᾏ' => 'A',
    'ᾐ' => 'i',
    'ᾑ' => 'i',
    'ᾒ' => 'i',
    'ᾓ' => 'i',
    'ᾔ' => 'i',
    'ᾕ' => 'i',
    'ᾖ' => 'i',
    'ᾗ' => 'i',
    'ᾘ' => 'I',
    'ᾙ' => 'I',
    'ᾚ' => 'I',
    'ᾛ' => 'I',
    'ᾜ' => 'I',
    'ᾝ' => 'I',
    'ᾞ' => 'I',
    'ᾟ' => 'I',
    'ᾠ' => 'o',
    'ᾡ' => 'o',
    'ᾢ' => 'o',
    'ᾣ' => 'o',
    'ᾤ' => 'o',
    'ᾥ' => 'o',
    'ᾦ' => 'o',
    'ᾧ' => 'o',
    'ᾨ' => 'O',
    'ᾩ' => 'O',
    'ᾪ' => 'O',
    'ᾫ' => 'O',
    'ᾬ' => 'O',
    'ᾭ' => 'O',
    'ᾮ' => 'O',
    'ᾯ' => 'O',
    'ᾰ' => 'a',
    'ᾱ' => 'a',
    'ᾲ' => 'a',
    'ᾳ' => 'a',
    'ᾴ' => 'a',
    'ᾶ' => 'a',
    'ᾷ' => 'a',
    'Ᾰ' => 'A',
    'Ᾱ' => 'A',
    'Ὰ' => 'A',
    'ᾼ' => 'A',
    'ῂ' => 'i',
    'ῃ' => 'i',
    'ῄ' => 'i',
    'ῆ' => 'i',
    'ῇ' => 'i',
    'Ὲ' => 'E',
    'Ὴ' => 'I',
    'ῌ' => 'I',
    'ῐ' => 'i',
    'ῑ' => 'i',
    'ῒ' => 'i',
    'ῖ' => 'i',
    'ῗ' => 'i',
    'Ῐ' => 'I',
    'Ῑ' => 'I',
    'Ὶ' => 'I',
    'ῠ' => 'y',
    'ῡ' => 'y',
    'ῢ' => 'y',
    'ῤ' => 'r',
    'ῥ' => 'r',
    'ῦ' => 'y',
    'ῧ' => 'y',
    'Ῠ' => 'Y',
    'Ῡ' => 'Y',
    'Ὺ' => 'Y',
    'Ῥ' => 'R',
    'ῲ' => 'o',
    'ῳ' => 'o',
    'ῴ' => 'o',
    'ῶ' => 'o',
    'ῷ' => 'o',
    'Ὸ' => 'O',
    'Ὼ' => 'O',
    'ῼ' => 'O',
    '‘' => "'",
    '’' => "'",
  };

  $data =~ s/$_/$$table{$_}/gue for keys %$table;

  return $data;
}

1;



=head1 NAME

Faker::Plugin - Fake Data Plugin

=cut

=head1 ABSTRACT

Fake Data Plugin Base

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin;

  my $plugin = Faker::Plugin->new;

  # bless(..., "Faker::Plugin")

  # my $result = $plugin->execute;

  # ""

=cut

=head1 DESCRIPTION

This distribution provides a library of fake data generators and a framework
for extending the library via plugins.

=encoding utf8

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 faker

  faker(Object $data) (Object)

The faker attribute holds the L<Faker> object.

I<Since C<1.10>>

=over 4

=item faker example 1

  # given: synopsis

  package main;

  my $faker = $plugin->faker;

  # bless(..., "Faker")

=back

=over 4

=item faker example 2

  # given: synopsis

  package main;

  my $faker = $plugin->faker({});

  # bless(..., "Faker")

=back

=over 4

=item faker example 3

  # given: synopsis

  package main;

  use Faker;

  my $faker = $plugin->faker(Faker->new);

  # bless(..., "Faker")

=back

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Buildable>

L<Venus::Role::Optional>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method should be overridden by a plugin subclass, and should
generate and return a random string.

I<Since C<1.10>>

=over 4

=item execute example 1

  # given: synopsis

  package main;

  my $data = $plugin->execute;

  # ""

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin;

  my $plugin = Faker::Plugin->new;

  # bless(... "Faker::Plugin")

=back

=over 4

=item new example 2

  package main;

  use Faker::Plugin;

  my $plugin = Faker::Plugin->new({faker => ['en-us', 'es-es']});

  # bless(... "Faker::Plugin")

=back

=over 4

=item new example 3

  package main;

  use Faker::Plugin;

  my $plugin = Faker::Plugin->new({faker => Faker->new('ja-jp')});

  # bless(... "Faker::Plugin")

=back

=cut

=head2 process

  process(Str $data) (Str)

The process method accepts a data template and calls L</process_format> and
L</process_markers> with the arguments provided and returns the result.

I<Since C<1.10>>

=over 4

=item process example 1

  # given: synopsis

  package main;

  $plugin->faker->locales(['en-us']);

  my $process = $plugin->process('@?{{person_last_name}}####');

  # "\@ZWilkinson4226"

=back

=cut

=head2 process_format

  process_format(Str $data) (Str)

The process_format method accepts a data template replacing any tokens found
with the return value from L</resolve>.

I<Since C<1.10>>

=over 4

=item process_format example 1

  # given: synopsis

  package main;

  my $process_format = $plugin->process_format('Version {{software_version}}');

  # "Version 0.78"

=back

=cut

=head2 process_markers

  process_markers(Str $data, Str @types) (Str)

The process_markers method accepts a string with markers, replaces the markers
(i.e. special symbols) and returns the result. This method also, optionally,
accepts a list of the types of replacements to be performed. The markers are:
C<#> (see L<Venus::Random/digit>), C<%> (see L<Venus::Random/nonzero>), C<?>
(see L<Venus::Random/letter>), and C<\n>. The replacement types are:
I<"letters">, I<"numbers">, and I<"newlines">.

I<Since C<1.10>>

=over 4

=item process_markers example 1

  # given: synopsis

  package main;

  my $process_markers = $plugin->process_markers('Version %##');

  # "Version 342"

=back

=over 4

=item process_markers example 2

  # given: synopsis

  package main;

  my $process_markers = $plugin->process_markers('Version %##', 'numbers');

  # "Version 185"

=back

=over 4

=item process_markers example 3

  # given: synopsis

  package main;

  my $process_markers = $plugin->process_markers('Dept. %-??', 'letters', 'numbers');

  # "Dept. 6-EL"

=back

=over 4

=item process_markers example 4

  # given: synopsis

  package main;

  my $process_markers = $plugin->process_markers('root\nsecret', 'newlines');

  # "root\nsecret"

=back

=cut

=head2 resolve

  resolve(Str $name) (Str)

The resolve method replaces tokens from L</process_format> with the return
value from their corresponding plugins.

I<Since C<1.10>>

=over 4

=item resolve example 1

  # given: synopsis

  package main;

  my $color_hex_code = $plugin->resolve('color_hex_code');

  # "#adfc4b"

=back

=over 4

=item resolve example 2

  # given: synopsis

  package main;

  my $internet_ip_address = $plugin->resolve('internet_ip_address');

  # "edb6:0311:c3e3:fdc1:597d:115c:c179:3998"

=back

=over 4

=item resolve example 3

  # given: synopsis

  package main;

  my $color_name = $plugin->resolve('color_name');

  # "MintCream"

=back

=cut

=head1 FEATURES

This package provides the following features:

=cut

=over 4

=item subclass-feature

This package is meant to be subclassed.

B<example 1>

  package Faker::Plugin::UserId;

  use base 'Faker::Plugin';

  sub execute {
    my ($self) = @_;

    return $self->process('####-####');
  }

  package main;

  use Faker;

  my $faker = Faker->new;

  # bless(..., "Faker")

  my $result = $faker->user_id;

  # "8359-6325"

=back