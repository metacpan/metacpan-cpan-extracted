package Lingua::LO::NLP::Romanize::PCGN;
use strict;
use warnings;
use 5.012000;
use utf8;
use feature qw/ unicode_strings say /;
use charnames qw/ :full lao /;
use version 0.77; our $VERSION = version->declare('v0.2.0');
use Carp;
use List::Util 1.33 'none';
use Lingua::LO::NLP::Analyze;
use parent 'Lingua::LO::NLP::Romanize';

=encoding utf8

=head1 NAME

Lingua::LO::NLP::Romanize::PCGN - Romanize Lao syllables according to the PCGN standard

=head1 FUNCTION

This class is not supposed to be used directly. Rather use
L<Lingua::LO::NLP::Romanize> as a factory:

    my $o = Lingua::LO::NLP::Romanize->new(variant => 'PCGN');

=cut

my %CONSONANTS = (
   'ກ'  => 'k',
   'ຂ'  => 'kh',
   'ຄ'  => 'kh',
   'ງ'  => 'ng',
   'ຈ'  => 'ch',
   'ສ'  => 's',
   'ຊ'  => 'x',
   'ຍ'  => [qw/ gn y /],
   'ດ'  => [qw/ d t /],
   'ຕ'  => 't',
   'ຖ'  => 'th',
   'ທ'  => 'th',
   'ນ'  => 'n',
   'ບ'  => [qw/ b p /],
   'ປ'  => 'p',
   'ຜ'  => 'ph',
   'ຝ'  => 'f',
   'ພ'  => 'ph',
   'ຟ'  => 'f',
   'ມ'  => 'm',
   'ຢ'  => 'y',
   'ລ'  => 'l',
   "\N{LAO SEMIVOWEL SIGN LO}"  => 'l',
   'ວ'  => [qw/ v o /],
   'ຫ'  => 'h',
   'ອ'  => '',
   'ຮ'  => 'h',
   'ຣ'  => 'r',
   'ໜ' => 'n',
   'ໝ' => 'm',
   'ຫຼ' => 'l',
   'ຫຍ' => 'gn',
   'ຫນ' => 'n',
   'ຫມ' => 'm',
   'ຫຣ' => 'r',
   'ຫລ' => 'l',
   'ຫວ' => 'v',
);

my %CONS_VOWELS = map { $_ => 1 } qw/ ຍ ຽ ອ ວ /;

my %VOWELS = (
    ### Monophthongs
    'Xະ'   => 'a',
    'Xັ'    => 'a',
    'Xາ'   => 'a',
    'Xາວ'  => 'ao',

    'Xິ'    => 'i',
    'Xີ'    => 'i',
    'Xິວ'   => 'iou', # TODO correct?
    'Xີວ'   => 'iou', # TODO correct?

    'Xຶ'    => 'u',
    'Xື'    => 'u',

    'Xຸ'    => 'ou',
    'Xູ'    => 'ou',

    'ເXະ'  => 'é',
    'ເXັ'   => 'é',
    'ເX'   => 'é',

    'ແXະ'  => 'è',
    'ແXັ'   => 'è',
    'ແX'   => 'è',
    'ແXວ'  => 'èo',

    'ໂXະ'  => 'ô',
    'Xົ'    => 'ô',
    'ໂX'   => 'ô',
    'ໂXຍ'  => 'ôy', # TODO correct?
    'Xອຍ'  => 'oy',

    'ເXາະ' => 'o',
    'Xັອ'   => 'o',
    'Xໍ'    => 'o',
    'Xອ'   => 'o',

    'ເXິ'   => 'eu',
    'ເXີ'   => 'eu',
    'ເXື'   => 'eu', # TODO correct?

    'ເXັຍ'  => 'ia',  # /iə/
    'Xັຽ'   => 'ia',  # /iə/
    'ເXຍ'  => 'ia',  # /iːə/
    'Xຽ'   => 'ia',  # /iːə/
    'Xຽວ'  => 'iao',

    'ເXີຍ'  => 'euy',
    'ເXຶອ'  => 'ua',
    'ເXືອ'  => 'ua',
    'ເXືອຍ' => 'uai',
    'Xົວະ'  => 'oua',
    'Xັວ '  => 'oua',
    'Xົວ'   => 'oua',
    'Xວ'   => 'oua',
    'Xວຍ'  => 'ouai',

    'ໄX'   => 'ai',
    'ໃX'   => 'ai',
    'Xາຍ'  => 'ay',
    'Xັຍ'   => 'ay',  # /aj/

    'ເXົາ'  => 'ao',
    'Xຳ'   => 'am', # composed U+0EB3
    'Xໍາ'   => 'am',
);
{
    # Replace "X" in %VOWELS keys with DOTTED CIRCLE. Makes code easier to edit.
    my %v;
    foreach my $v (keys %VOWELS) {
        (my $w = $v) =~ s/X/\N{DOTTED CIRCLE}/;
        $v{$w} = $VOWELS{$v};
    }
    %VOWELS = %v;
}

=head2 new

You don't call this constructor directly bu via L<Lingua::LO::NLP::Romanize>.

=cut

sub new {
    my ($class, %args) = @_;
    return bless {
        romanize_vowel =>  sub { $VOWELS{ $_[0] } },
    }, $class;
}

=head2 romanize_syllable

    romanize_syllable( $syllable )

Return the romanization of a single C<$syllable>. See L<Lingua::LO::NLP::Romanize/romanize_syllable>

=cut

sub romanize_syllable {
    my ($self, $syllable) = @_;
    my ($endcons, $result);
    my $c = Lingua::LO::NLP::Analyze->new($syllable);
    my $parse = $c->parse;
    my $vowel = $c->vowel;
    
    my $cons = $c->consonant;
    my $h = $c->h;
    my $sv = $c->semivowel;
    if($cons eq 'ຫ' and $sv) {
        # ຫ with semivowel. Drop the ຫ and use the semivowel as consonant
        $result = $self->romanize_consonant($sv, 0);
        undef $sv;
    } else {
        # The regular case
        $result = $self->romanize_consonant($cons, 0);
        $sv = $self->romanize_consonant($sv, 1) if $sv;
    }

    $endcons = $c->end_consonant;
    if(defined $endcons) {
        if(exists $CONS_VOWELS{ $endcons } and not defined $parse->{vowel3}) {
            $vowel .= $endcons;   # consonant can be used as a vowel
            $endcons = '';
        } else {
            $endcons = $self->romanize_consonant($endcons, 1);
        }
    } else {
        $endcons = '';  # avoid special-casing later
    }

    # TODO remove debug
    carp sprintf("Missing VOWELS def for `%s' in `%s'", $vowel, $c->syllable) unless defined $VOWELS{ $vowel };

    $sv //= '';
    my $rom_vowel = $self->{romanize_vowel}->($vowel, $c->tone);
    if($parse->{vowel0} and none { defined } @$parse{qw/ vowel1 vowel2 vowel3 /}) {
        $result .= $rom_vowel . $sv . $endcons;
    } else {
        $result .= $sv . $rom_vowel . $endcons;
    }
    # Duplication sign
    if(defined $parse->{extra}  and $parse->{extra} eq 'ໆ') {
        $result .= ($self->{hyphen} eq ' ' ? '-' : $self->{hyphen}) . "$result";
    }
    return $result;
}

=head2 romanize_consonant

    $o->romanize_consonant($consonant, $position_in_syllable);

Get the appropriate consonant romanization for its position in the syllable.
Implemented as a method so it can be overridden in subclasses. C<$position>
must be 0 for initial/core position, 1 for end consonants.

=cut

sub romanize_consonant {
    my (undef, $cons, $position) = @_;
    my $consdata = $CONSONANTS{ $cons };
    return ref $consdata ? $consdata->[$position] : $consdata;
}

1;

