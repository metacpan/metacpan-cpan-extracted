#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use feature 'unicode_strings';
use open qw/ :encoding(UTF-8) :std /;
use charnames qw/ :full lao /;
use Test::More;
use Test::Fatal;
use Try::Tiny;
use Lingua::LO::NLP::Analyze;

use constant MAI_EK     => "\N{LAO TONE MAI EK}";
use constant MAI_THO    => "\N{LAO TONE MAI THO}";
use constant MAI_CATAWA => "\N{LAO TONE MAI CATAWA}";

my %tests = (
    # Generated syllables from some list or other
    'ກວກ' => { consonant => 'ກ', end_consonant => 'ກ', live => 0, tone => 'MID_FALLING', vowel => 'Xວ', vowel_length => 'long' },
    'ກວງ' => { consonant => 'ກ', end_consonant => 'ງ', live => 1, tone => 'LOW', vowel => 'Xວ', vowel_length => 'long' },
    'ກ່ວງ' => { consonant => 'ກ', end_consonant => 'ງ', live => 1, tone => 'MID', tone_mark => MAI_EK, vowel => 'Xວ', vowel_length => 'long' },
    'ກ່າ' => { consonant => 'ກ', tone => 'MID', live => 1, tone_mark => MAI_EK, vowel => 'Xາ', vowel_length => 'long' },
    'ກ່າຍ' => { consonant => 'ກ', end_consonant => 'ຍ', live => 1, tone => 'MID', tone_mark => MAI_EK, vowel => 'Xາ', vowel_length => 'long' },
    'ກໍ' => { consonant => 'ກ', live => 1, tone => 'LOW', vowel => 'Xໍ', vowel_length => 'long' },
    'ກໍ່' => { consonant => 'ກ', live => 1, tone => 'MID', tone_mark => MAI_EK, vowel => 'Xໍ', vowel_length => 'long' },
    'ກໍ໋' => { consonant => 'ກ', live => 1, tone => 'RISING', tone_mark => MAI_CATAWA, vowel => 'Xໍ', vowel_length => 'long' },
    'ແໜ' => { consonant => 'ໜ', live => 1, tone => 'RISING', vowel => 'ແX', vowel_length => 'long' },
    'ແຫນ' => { consonant => 'ຫ', end_consonant => 'ນ', live => 1, tone => 'RISING', vowel => 'ແX', vowel_length => 'long' },
    'ຫາມ' => { consonant => 'ຫ', end_consonant => 'ມ', live => 1, tone => 'RISING', vowel => 'Xາ', vowel_length => 'long' },
    'ເກິ່ຍ' => { consonant => 'ກ', end_consonant => 'ຍ', live => 1, tone => 'MID', tone_mark => MAI_EK, vowel => 'ເXິ', vowel_length => 'short' },

    # Constructed syllables with simple vowels
    'ກະ' => { consonant => 'ກ', live => 0, tone => 'HIGH', vowel => 'Xະ', vowel_length => 'short' },
    'ກາ' => { consonant => 'ກ', live => 1, tone => 'LOW', vowel => 'Xາ', vowel_length => 'long' },

    'ກິ' => { consonant => 'ກ', live => 0, tone => 'HIGH', vowel => 'Xິ', vowel_length => 'short' },
    'ກີ' => { consonant => 'ກ', live => 1, tone => 'LOW', vowel => 'Xີ', vowel_length => 'long' },

    'ກຶ' => { consonant => 'ກ', live => 0, tone => 'HIGH', vowel => 'Xຶ', vowel_length => 'short' },
    'ກື' => { consonant => 'ກ', live => 1, tone => 'LOW', vowel => 'Xື', vowel_length => 'long' },

    'ກຸ' => { consonant => 'ກ', live => 0, tone => 'HIGH', vowel => 'Xຸ', vowel_length => 'short' },
    'ກູ' => { consonant => 'ກ', live => 1, tone => 'LOW', vowel => 'Xູ', vowel_length => 'long' },

    'ເກະ' => { consonant => 'ກ', live => 0, tone => 'HIGH', vowel => 'ເXະ', vowel_length => 'short' },
    'ເກັນ' => { consonant => 'ກ', live => 1, end_consonant => 'ນ', tone => 'LOW', vowel => 'ເXັ', vowel_length => 'short' },
    'ເກ' => { consonant => 'ກ', live => 1, tone => 'LOW', vowel => 'ເX', vowel_length => 'long' },

    'ແກະ' => { consonant => 'ກ', live => 0, tone => 'HIGH', vowel => 'ແXະ', vowel_length => 'short' },
    'ແກັດ' => { consonant => 'ກ', end_consonant => 'ດ', live => 0, tone => 'HIGH', vowel => 'ແXັ', vowel_length => 'short' },
    'ແກ' => { consonant => 'ກ', live => 1, tone => 'LOW', vowel => 'ແX', vowel_length => 'long' },

    'ໂກະ' => { consonant => 'ກ', live => 0, tone => 'HIGH', vowel => 'ໂXະ', vowel_length => 'short' },
    'ໂກ' => { consonant => 'ກ', live => 1, tone => 'LOW', vowel => 'ໂX', vowel_length => 'long' },

    'ກັນ' => { consonant => 'ກ', end_consonant => 'ນ', live => 1, tone => 'LOW', vowel => 'Xັ', vowel_length => 'short' },
    'ກົດ' => { consonant => 'ກ', end_consonant => 'ດ', live => 0, tone => 'HIGH', vowel => 'Xົ', vowel_length => 'short' },

    'ເກາະ' => { consonant => 'ກ', live => 0, tone => 'HIGH', vowel => 'ເXາະ', vowel_length => 'short' },
    'ກອດ' => { consonant => 'ກ', end_consonant => 'ດ', live => 0, tone => 'MID_FALLING', vowel => 'Xອ', vowel_length => 'long' },

    'ເກິ' => { consonant => 'ກ', live => 0, tone => 'HIGH', vowel => 'ເXິ', vowel_length => 'short' },
    'ເກີ' => { consonant => 'ກ', live => 1, tone => 'LOW', vowel => 'ເXີ', vowel_length => 'long' },

    ###' Diphthongs
    # TODO 'ເກັຍ' => { consonant => 'ກ', end_consonant => 'ຍ', live => 1, tone => 'LOW', vowel => 'ເXັ', vowel_length => 'short' },
    'ເກຍ' => { consonant => 'ກ', end_consonant => 'ຍ', live => 1, tone => 'LOW', vowel => 'ເX', vowel_length => 'long' },

    'ເກົາ' => { consonant => 'ກ', live => 0, tone => 'HIGH', vowel => 'ເXົາ', vowel_length => 'short' },

    'ເກຶອ' => { consonant => 'ກ', live => 0, tone => 'HIGH', vowel => 'ເXຶອ', vowel_length => 'short' },
    'ເກືອ' => { consonant => 'ກ', live => 1, tone => 'LOW', vowel => 'ເXືອ', vowel_length => 'long' },

    'ກວດ' => { consonant => 'ກ', end_consonant => 'ດ', live => 0, tone => 'MID_FALLING', vowel => 'Xວ', vowel_length => 'long' },
    'ກັວກ' => { consonant => 'ກ', end_consonant => 'ກ', live => 0, tone => 'HIGH', vowel => 'Xັວ', vowel_length => 'short' },

    'ໄກ' => { consonant => 'ກ', live => 1, tone => 'LOW', vowel => 'ໄX', vowel_length => 'long' },
    'ໃນ' => { consonant => 'ນ', live => 1, tone => 'HIGH', vowel => 'ໃX', vowel_length => 'long' },
    'ກາຍ' => { consonant => 'ກ', end_consonant => 'ຍ', live => 1, tone => 'LOW', vowel => 'Xາ', vowel_length => 'long' },
    'ກັຍ' => { consonant => 'ກ', end_consonant => 'ຍ', live => 1, tone => 'LOW', vowel => 'Xັ', vowel_length => 'short' },

    'ແປຽ' => { consonant => 'ປ', live => 0, tone => 'HIGH', vowel => 'ແXຽ', vowel_length => 'short' },
    'ກໍາ' => { consonant => 'ກ', live => 0, tone => 'HIGH', vowel => 'Xໍາ', vowel_length => 'short' },  # /am/, decomposed
    'ກຳ' => { consonant => 'ກ', live => 0, tone => 'HIGH', vowel => 'Xຳ', vowel_length => 'short' },  # /am/, composed

    # Various cases that have looked problematic
    'ກຽດ' => { consonant => 'ກ', end_consonant => 'ດ', live => 0, tone => 'MID_FALLING', vowel => 'Xຽ', vowel_length => 'long' },
    'ຈື່ງ' => { consonant => 'ຈ', end_consonant => 'ງ', live => 1, tone => 'MID', tone_mark => MAI_EK, vowel => 'Xື', vowel_length => 'long' },
    'ຊັນ' => { consonant => 'ຊ', end_consonant => 'ນ', live => 1, tone => 'HIGH', vowel => 'Xັ', vowel_length => 'short' },
    'ຊົ່ວ' => { consonant => 'ຊ', end_consonant => 'ວ', live => 1, tone => 'MID', tone_mark => MAI_EK, vowel => 'Xົ', vowel_length => 'short' },
    'ຍະ' => { consonant => 'ຍ', live => 0, tone => 'MID', vowel => 'Xະ', vowel_length => 'short' },
    'ດີ' => { consonant => 'ດ', live => 1, tone => 'LOW', vowel => 'Xີ', vowel_length => 'long' },
    'ດ້ວຍ' => { consonant => 'ດ', end_consonant => 'ຍ', live => 1, tone => 'HIGH_FALLING', tone_mark => MAI_THO, vowel => 'Xວ', vowel_length => 'long' },
    'ຕິ' => { consonant => 'ຕ', live => 0, tone => 'HIGH', vowel => 'Xິ', vowel_length => 'short' },
    'ຕົນ' => { consonant => 'ຕ', end_consonant => 'ນ', live => 1, tone => 'LOW', vowel => 'Xົ', vowel_length => 'short' },
    'ຕ້ອງ' => { consonant => 'ຕ', end_consonant => 'ງ', live => 1, tone => 'HIGH_FALLING', tone_mark => MAI_THO, vowel => 'Xອ', vowel_length => 'long' },
    'ຕໍ່' => { consonant => 'ຕ', live => 1, tone => 'MID', tone_mark => MAI_EK, vowel => 'Xໍ', vowel_length => 'long' },
    'ທາງ' => { consonant => 'ທ', end_consonant => 'ງ', live => 1, tone => 'HIGH', vowel => 'Xາ', vowel_length => 'long' },
    'ທຳ' => { consonant => 'ທ', live => 0, tone => 'MID', vowel => 'Xຳ', vowel_length => 'short' },
    'ນຸດ' => { consonant => 'ນ', end_consonant => 'ດ', live => 0, tone => 'MID', vowel => 'Xຸ', vowel_length => 'short' },
    'ນ້ອງ' => { consonant => 'ນ', end_consonant => 'ງ', live => 1, tone => 'HIGH_FALLING', tone_mark => MAI_THO, vowel => 'Xອ', vowel_length => 'long' },
    'ປະ' => { consonant => 'ປ', live => 0, tone => 'HIGH', vowel => 'Xະ', vowel_length => 'short' },
    'ປັດ' => { consonant => 'ປ', end_consonant => 'ດ', live => 0, tone => 'HIGH', vowel => 'Xັ', vowel_length => 'short' },
    'ພາບ' => { consonant => 'ພ', end_consonant => 'ບ', live => 0, tone => 'HIGH_FALLING', vowel => 'Xາ', vowel_length => 'long' },
    'ພີ່' => { consonant => 'ພ', live => 1, tone => 'MID', tone_mark => MAI_EK, vowel => 'Xີ', vowel_length => 'long' },
    'ພຶດ' => { consonant => 'ພ', end_consonant => 'ດ', live => 0, tone => 'MID', vowel => 'Xຶ', vowel_length => 'short' },
    'ມະ' => { consonant => 'ມ', live => 0, tone => 'MID', vowel => 'Xະ', vowel_length => 'short' },
    'ມາ' => { consonant => 'ມ', live => 1, tone => 'HIGH', vowel => 'Xາ', vowel_length => 'long' },
    'ມີ' => { consonant => 'ມ', live => 1, tone => 'HIGH', vowel => 'Xີ', vowel_length => 'long' },
    'ສະ' => { consonant => 'ສ', live => 0, tone => 'HIGH', vowel => 'Xະ', vowel_length => 'short' },
    'ສັກ' => { consonant => 'ສ', end_consonant => 'ກ', live => 0, tone => 'HIGH', vowel => 'Xັ', vowel_length => 'short' },
    'ສຳ' => { consonant => 'ສ', live => 0, tone => 'HIGH', vowel => 'Xຳ', vowel_length => 'short' },
    'ສິດ' => { consonant => 'ສ', end_consonant => 'ດ', live => 0, tone => 'HIGH', vowel => 'Xິ', vowel_length => 'short' },
    'ຮູ້' => { consonant => 'ຮ', live => 1, tone => 'HIGH_FALLING', tone_mark => MAI_THO, vowel => 'Xູ', vowel_length => 'long' },
    'ເກີດ' => { consonant => 'ກ', end_consonant => 'ດ', live => 0, tone => 'MID_FALLING', vowel => 'ເXີ', vowel_length => 'long' },
    'ເໝີ' => { consonant => 'ໝ', live => 1, tone => 'RISING', vowel => 'ເXີ', vowel_length => 'long' },
    'ແລະ' => { consonant => 'ລ', live => 0, tone => 'MID', vowel => 'ແXະ', vowel_length => 'short' },
    'ໂນ' => { consonant => 'ນ', live => 1, tone => 'HIGH', vowel => 'ໂX', vowel_length => 'long' },
    'ໃກ' => { consonant => 'ກ', live => 1, tone => 'LOW', vowel => 'ໃX', vowel_length => 'long' },
    'ໜ້າ' => { consonant => 'ໜ', live => 1, tone => 'MID_FALLING', tone_mark => MAI_THO, vowel => 'Xາ', vowel_length => 'long' },
    'ເຫດ' => { consonant => 'ຫ', end_consonant => "ດ", live => 0, tone => 'MID_FALLING',  vowel => "ເX", vowel_length => 'long' },
    'ເອື້ອຢ' => { consonant => "ອ", end_consonant => "ຢ", live => 1, tone => "HIGH_FALLING", tone_mark => MAI_THO, vowel => "ເ◌ືອ", vowel_length => "long" },
    'ສວນ' => { consonant => "ສ", end_consonant => "ນ", live => 1, tone => "RISING", vowel => "◌ວ", vowel_length => "long" },
    #TODO 'ນ້ໍາ' => { consonant => "ນ", live => 0, tone => "HIGH_FALLING", tone_mark => MAI_THO, vowel => "◌ໍາ", vowel_length => "short" },

    # TODO verify
    #'ຢູ່ມ້ີ' => { consonant => "ຢ", syllable => "ຢູ່ມີ້", tone => "MID", tone_mark => MAI_EK, vowel => "◌ູ", vowel_length => "long" },
    #'ຫານ' => { consonant => "ຫ", end_consonant => "ນ", syllable => "ຫານ", tone => "RISING", vowel => "◌າ", vowel_length => "long" },
    #'ຫິວ' => { consonant => "ຫ", end_consonant => "ວ", syllable => "ຫິວ", tone => "HIGH", vowel => "◌ິ", vowel_length => "short" },
    #'ຫົດ' => { consonant => "ຫ", end_consonant => "ດ", syllable => "ຫົດ", tone => "HIGH", vowel => "◌ົ", vowel_length => "short" },
    #'ເຂ້ົາ' => { consonant => "ຂ", syllable => "ເຂົ້າ", tone => "HIGH", tone_mark => MAI_THO, vowel => "ເ◌ົາ", vowel_length => "short" },
    #'ເຈ້ົາ' => { consonant => "ຈ", syllable => "ເຈົ້າ", tone => "HIGH", tone_mark => MAI_THO, vowel => "ເ◌ົາ", vowel_length => "short" },
    #'ເຕີລ່ີ' => { consonant => "ຕ", syllable => "ເຕີລີ່", tone => "LOW", vowel => "ເ◌ີ", vowel_length => "long" },
    #'ເທົ່າ' => { consonant => "ທ", syllable => "ເທົ່າ", tone => "MID", tone_mark => MAI_EK, vowel => "ເ◌ົາ", vowel_length => "short" },
    #'ເທ່ືອ' => { consonant => "ທ", syllable => "ເທື່ອ", tone => "MID", tone_mark => MAI_EK, vowel => "ເ◌ືອ", vowel_length => "long" },
    #'ເລ້ືອຍໆ' => { consonant => "ລ", end_consonant => "ຍ", syllable => "ເລື້ອຍໆ", tone => "HIGH_FALLING", tone_mark => MAI_THO, vowel => "ເ◌ືອ", vowel_length => "long" },
    #'ເອ້ືອຢ' => { consonant => "ອ", end_consonant => "ຢ", syllable => "ເອື້ອຢ", tone => "HIGH_FALLING", tone_mark => MAI_THO, vowel => "ເ◌ືອ", vowel_length => "long" },

    #'ໄລນ໌' => {},
);

my %tests_normalize = (
    # Test tone mark order normalization
    # Regular order consonant-vowel-tone
    "\N{LAO VOWEL SIGN E}\N{LAO LETTER MO}\N{LAO VOWEL SIGN YY}\N{LAO TONE MAI EK}\N{LAO LETTER O}" =>
    { consonant => 'ມ', vowel => 'ເXືອ', live => 1, tone => 'MID', tone_mark => MAI_EK, vowel_length => 'long' },
    # Wrong order consonant-tone-vowel
    "\N{LAO VOWEL SIGN E}\N{LAO LETTER MO}\N{LAO TONE MAI EK}\N{LAO VOWEL SIGN YY}\N{LAO LETTER O}" =>
    {
        consonant => 'ມ', live => 1, vowel => 'ເXືອ', tone => 'MID',
        syllable => "\N{LAO VOWEL SIGN E}\N{LAO LETTER MO}\N{LAO VOWEL SIGN YY}\N{LAO TONE MAI EK}\N{LAO LETTER O}",
        tone_mark => MAI_EK, vowel_length => 'long'
    },
    "\N{LAO LETTER NO}\N{LAO TONE MAI THO}\N{LAO VOWEL SIGN AM}" =>
    { consonant => 'ນ', vowel => 'Xຳ', live => 0, tone => 'HIGH_FALLING', tone_mark => MAI_THO, vowel_length => 'short' },
);

for my $analysis (values %tests, values %tests_normalize) {
    s/X/\N{DOTTED CIRCLE}/ for values %$analysis;
}

my @tone_tests = (
    ກາ => 'LOW',
    ຄາ => 'HIGH',
    ຂາ => 'RISING',

    ກ່າ => 'MID',
    ຄ່າ => 'MID',
    ຂ່າ => 'MID',

    ກ້າ => 'HIGH_FALLING',
    ຄ້າ => 'HIGH_FALLING',
    ຂ້າ => 'MID_FALLING',

    ກ໊າ => 'HIGH',
    ຄ໊າ => 'HIGH',
    ຂ໊າ => 'HIGH',

    ກ໋າ => 'RISING',
    ຄ໋າ => 'RISING',
    ຂ໋າ => 'RISING',

    ກະ => 'HIGH',
    ຄະ => 'MID',
    ຂະ => 'HIGH',
);
@tone_tests % 2 and die 'BUG: @tone_tests must have an even number of elements!';

isa_ok(Lingua::LO::NLP::Analyze->new('ສະ'), 'Lingua::LO::NLP::Analyze');
like(
    exception { Lingua::LO::NLP::Analyze->new },
    qr/`syllable' argument missing or undefined/,
    'Dies w/o syllable argument'
);

test_syllable($_, $tests{$_}) for sort keys %tests;
test_syllable($_, $tests_normalize{$_}, normalize => 1) for sort keys %tests_normalize;

for my $syllable (sort keys %tests) {
    my $c = undef;
    try {
        $c = Lingua::LO::NLP::Analyze->new($syllable, normalize => 1);
    } catch {
        fail("`$syllable' caused exception: $_ ".Dumper($tests{$syllable}));
    };
    next unless defined $c;
    #print "'$syllable' => " . print_struct(%c) . "\n";
    #next;
    delete $c->{parse};
    delete $c->{$_} for grep { not defined $c->{$_} } keys %$c;
    # trivial, doesn't need to be mentioned above unless it was subject to normalization
    $tests{$syllable}{syllable} //= $syllable;
    is_deeply($c, $tests{$syllable}, "`$syllable' analyzed correctly")
        or print "Result for '$syllable': ", (map { "$_ => \"$c->{$_}\", " } sort keys %$c) , "\n";
}

while(@tone_tests) {
    my $syllable = shift @tone_tests;
    my $tone = shift @tone_tests;
    is(Lingua::LO::NLP::Analyze->new($syllable)->tone, $tone, "$syllable has $tone tone");
}

done_testing;

sub test_syllable {
    my $syllable = shift;
    my %wanted = %{+shift};
    my @options = @_;

    my $c = undef;
    try {
        $c = Lingua::LO::NLP::Analyze->new( $syllable, @options );
    } catch {
        fail("`$syllable' caused exception: $_ ");
    };
    return unless defined $c;
    #print "'$syllable' => " . print_struct(%c) . "\n";
    #next;
    delete $c->{parse};
    delete $c->{$_} for grep { not defined $c->{$_} } keys %$c;
    # trivial, doesn't need to be mentioned above unless it was subject to normalization
    $wanted{syllable} //= $syllable;
    is_deeply($c, \%wanted, "`$syllable' analyzed correctly")
        or print "Result for '$syllable': ", (map { "$_ => \"$c->{$_}\", " } sort keys %$c) , "\n";
}

# Just for adding new tests
sub print_struct {
    my %s = @_;
    return sprintf('{ %s },',
        join(", ",
            map {
                sprintf "%s => %s", $_, ref($s{$_}) ? print_struct(%{$s{$_}}) : "'$s{$_}'"
            }
            grep {
                defined $s{$_} and !/^parse$/
            } sort keys %s
        )
    );
}

