package Lingua::RU::Inflect;

use warnings;
use strict;
use utf8;

=encoding utf8

=head1 NAME

Lingua::RU::Inflect - Inflect russian names.

=head1 VERSION

Version 0.05

=head1 DESCRIPTION

Lingua::RU::Inflect is a perl module
that provides Russian linguistic procedures
such as declension of given names (with some nouns and adjectives too),
and gender detection by given name.

Choosing of proper forms of varying prepositions
which added in 0.02 now is unavailable because it moved to L<Lingua::RU::Preposition>.

=cut

our ($REVISION, $DATE);
($REVISION) = q$Revision$ =~ /(\d+)/g;
($DATE)
    = q$Date$ =~ /: (\d+)\s*$/g;


BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION     = 0.05;

    @ISA         = qw(Exporter);
    @EXPORT      = qw(
        inflect_given_name detect_gender_by_given_name
    );

    # exported package globals
    @EXPORT_OK   = qw(
        NOMINATIVE GENITIVE     DATIVE
        ACCUSATIVE INSTRUMENTAL PREPOSITIONAL
        %CASES
        MASCULINE FEMININE
    );

    %EXPORT_TAGS = (
        'subs'    => [ qw(
            inflect_given_name detect_gender_by_given_name
            choose_preposition_by_next_word
        ) ],
        'genders' => [ qw( MASCULINE  FEMININE ) ],
        'cases'   => [ qw(
            NOMINATIVE GENITIVE DATIVE ACCUSATIVE INSTRUMENTAL PREPOSITIONAL
            %CASES
        ) ],
        'all'     => [ @EXPORT, @EXPORT_OK ],
    )

}

# Cases
# Why I can't use loop?!
use constant {
    NOMINATIVE    => -1,
    GENITIVE      => 0,
    DATIVE        => 1,
    ACCUSATIVE    => 2,
    INSTRUMENTAL  => 3,
    PREPOSITIONAL => 4,
};

my  @CASE_NAMES = qw(
    NOMINATIVE GENITIVE DATIVE ACCUSATIVE INSTRUMENTAL PREPOSITIONAL
);
my  @CASE_NUMBERS = ( -1 .. 4 );

use List::MoreUtils 'mesh';
our %CASES = mesh @CASE_NAMES, @CASE_NUMBERS;

# Gender
use constant {
    FEMININE  => 0,
    MASCULINE => 1,
};

=head1 SYNOPSIS

Inflects russian names which represented in UTF-8.

Perhaps a little code snippet.

    use Lingua::RU::Inflect;

    my @name = qw/Петрова Любовь Степановна/;
    # Transliteration of above line is: Petrova Lyubov' Stepanovna

    my $gender = detect_gender_by_given_name(@name);
    # $gender == FEMININE

    my @genitive = inflect_given_name(GENITIVE, @name);
    # $genitive == qw/Петровой Любови Степановны/;
    # Transliteration of above line is: Petrovoy Lyubovi Stepanovny

=head1 TO DO

1. Inflect any nouns, any words, anything...

=head1 EXPORT

Function C<detect_gender_by_given_name> and
C<detect_gender_by_given_name> are exported by default.

Also you can export only case names:

    use Lingua::RU::Inflect qw/:cases/;

Or only subs and genders

    use Lingua::RU::Inflect qw/:subs :genders/;

Or only short aliases for subs

    use Lingua::RU::Inflect qw/:short/;

Or everything: subs, aliases, genders and case names:

    use Lingua::RU::Inflect qw/:all/; # or
    use Lingua::RU::Inflect qw/:cases :genders :subs :short/;

=head1 FUNCTIONS

=head2 detect_gender_by_given_name

Try to detect gender by name. Up to three arguments expected:
lastname, firstname, patronym.

Return C<MASCULINE>, C<FEMININE> for successful detection
or C<undef> when function can't detect gender.

=head3 Detection rules

When name match some rule, rest of rules are ignored.

=over 4

=item 1

Patronym (russian отчество — otchestvo), if presented, gives unambiguous
detection rules: feminine patronyms ends with “na”, masculine ones ends
with “ich” and  “ych”.

=item 2

Most of russian feminine firstnames ends to vowels “a” and “ya”.
Most of russian masculine firstnames ends to consonants.

There's exists exceptions for both rules: feminine names such as russian
name Lubov' (Любовь) and foreign names Ruf' (Руфь), Rachil' (Рахиль)
etc. Masculine names also often have affectionate diminutive forms:
Alyosha (Алёша) for Alexey (Алексей), Kolya (Коля) for Nickolay
(Николай) etc. Some affectionate diminutive names are ambiguous: Sasha
(Саша) is diminutive name for feminine name Alexandra (Александра) and
for masculine name Alexander (Александр), Zhenya (Женя) is diminutive
name for feminine name Eugenia (Евгения) and for masculine name Eugene
(Евгений) etc.

These exceptions are processed.

When got ambiguous result, function try to use next rule.

=item 3

Most of russian lastnames derived from possessive nouns (and names).
Feminine forms of these lastnames ends to “a”.
Some lastnames derived from adjectives. Feminine forms of these
lastnames ends to “ya”.

=back

=cut

sub detect_gender_by_given_name {
    my ( $lastname, $firstname, $patronym ) = @_;
    map { $_ ||= '' } ( $lastname, $firstname, $patronym );
    my $ambiguous = 0;

    # Detect by patronym
    return FEMININE if $patronym =~ /на$/;
    return MASCULINE if $patronym =~ /[иы]ч$/;

    # Detect by firstname
    # Drop all names except first
    $firstname =~ s/[\s\-].*//;

    # Process exceptions
    map {
        return MASCULINE if $firstname eq $_;
    } ( &_MASCULINE_NAMES );

    map {
        return FEMININE if $firstname eq $_;
    } ( &_FEMININE_NAMES );

    map {
        $ambiguous++ && last if $firstname eq $_;
    } ( &_AMBIGUOUS_NAMES );

    unless ( $ambiguous ) {
        # Feminine firstnames ends to vowels
        return FEMININE  if $firstname =~ /[ая]$/;
        # Masculine firstnames ends to consonants
        return MASCULINE if $firstname !~ /[аеёиоуыэюя]$/;
    } # unless

    # Detect by lastname
    # possessive names
    return FEMININE  if $lastname =~ /(ев|ин|ын|ёв|ов)а$/;
    return MASCULINE if $lastname =~ /(ев|ин|ын|ёв|ов)$/;
    # adjectives
    return FEMININE  if $lastname =~ /(ая|яя)$/;
    return MASCULINE if $lastname =~ /(ий|ый)$/;

    # Unknown or ambiguous name
    return undef;
}

=head2 _inflect_given_name

Inflects name of given gender to given case.
Up to 5 arguments expected:
I<gender>, I<case>, I<lastname>, I<firstname>, I<patronym>.
I<Lastname>, I<firstname>, I<patronym> must be in Nominative.

Returns list which contains inflected I<lastname>, I<firstname>, I<patronym>.

=cut

sub _inflect_given_name {
    my $gender = shift;
    my $case   = shift;

    return @_ if $case eq NOMINATIVE;
    return
        if $case < GENITIVE
        || $case > PREPOSITIONAL;

    my ( $lastname, $firstname, $patronym ) = @_;
    map { $_ ||= '' } ( $lastname, $firstname, $patronym );

    # Patronyms
    {
        last unless $patronym;

        last if $patronym =~ s/на$/qw(ны не ну ной не)[$case]/e;
        last if $patronym =~ s/ыч$/qw(ыча ычу ыча ычем ыче)[$case]/e;
        $patronym =~ s/ич$/qw(ича ичу ича ичем иче)[$case]/e;
        $patronym =~ s/(Иль|Кузьм|Фом)ичем$/$1ичом/;
    }

    # Firstnames
    {
        last unless $firstname;

        # Exceptions
        $firstname =~ s/^Пётр$/Петр/;
        $firstname =~ s/^Христос$/Христ/;

        # Names which ends to vowels “o”, “yo”, “u”, “yu”, “y”, “i”, “e”, “ye”
        # and to pairs of vowels except “yeya”, “iya”
        # can not be inflected

        last if $firstname =~ /[еёиоуыэю]$/i;
        last if $firstname =~ /[аеёиоуыэюя]а$/i;
        last if $firstname =~ /[аёоуыэюя]я$/i;
        last
            if (
                !defined $gender
                || $gender == FEMININE
            )
            && $firstname =~ /[бвгджзклмнйпрстфхцчшщ]$/i;

        last if $firstname =~ s/ия$/qw(ии ии ию ией ие)[$case]/e;
        last if $firstname =~ s/([гжйкхчшщ])а$/$1.qw(и е у ой е)[$case]/e;
        last if $firstname =~ s/а$/qw(ы е у ой е)[$case]/e;
        last if $firstname =~ s/мя$/qw(мени мени мя менем мени)[$case]/e; # common nouns such as “Imya” (Name)
        last if $firstname =~ s/я$/qw(и е ю ей е)[$case]/e;
        last if $firstname =~ s/й$/qw(я ю я ем е)[$case]/e;

        # Same endings, but different gender
        if ( $gender == MASCULINE ) {
            last if $firstname =~ s/ь$/qw(я ю я ем е)[$case]/e;
        }
        elsif ( $gender == FEMININE ) {
            last if $firstname =~ s/ь$/qw(и и ь ью и)[$case]/e;
        }

        # Rest of names which ends to consonants
        $firstname .= qw(а у а ом е)[$case];
    } # Firstnames

    # Lastnames
    {
        last unless $lastname;
        last unless defined $gender;

        # Exception
        $lastname =~ s/^Христос$/Христ/;

        # Indeclinable
        last if $lastname =~ /[еёиоуыэю]$/i;
        last if $lastname =~ /[аеёиоуыэюя]а$/i;
        # Lastnames such as “Belaya” and “Sinyaya”
        #  which ends to “aya” and “yaya” must be inflected
        last if $lastname =~ /[ёоуыэю]я$/i;
        last if $lastname =~ /[иы]х$/i;

        # Feminine lastnames
        last
            if $lastname =~ /(ин|ын|ев|ёв|ов)а$/
            && $lastname =~ s/а$/qw(ой ой у ой ой)[$case]/e;
        # TODO Does not process usual worls: Podkova, Sova etc
        # TODO Decide/search what can I do with ambigous names: Mashina, Vagina etc

        # And masculine ones
        last
            if $lastname =~ /(ин|ын|ев|ёв|ов)$/
            && ( $lastname .= qw(а у а ым е)[$case] );

        # As adjectives
        last if $lastname =~ s/ая$/qw(ой ой ую ой ой)[$case]/e;
        last if $lastname =~ s/яя$/qw(ей ей юю ей ей)[$case]/e;
        last if $lastname =~ s/кий$/qw(кого кому кого ким ком)[$case]/e;
        last if $lastname =~ s/ий$/qw(его ему его им ем)[$case]/e;
        last if $lastname =~ s/ый$/qw(ого ому ого ым ом)[$case]/e;
        last if $lastname =~ s/ой$/qw(ого ому ого ым ом)[$case]/e;

        # Rest of masculine lastnames
        if ( $gender == MASCULINE ) {
            last if $lastname =~ s/а$/qw(ы е у ой е)[$case]/e;
            last if $lastname =~ s/мя$/qw(мени мени мя менем мени)[$case]/e;
            last if $lastname =~ s/я$/qw(и е ю ёй е)[$case]/e;
            last if $lastname =~ s/й$/qw(я ю й ем е)[$case]/e;
            last if $lastname =~ s/ь$/qw(я ю я ем е)[$case]/e;
            $lastname .= qw(а у а ом е)[$case];
        } # if
    } # Lastnames

    return ( $lastname, $firstname, $patronym );
} # sub _inflect_given_name


=head2 inflect_given_name

Detects gender by given name and inflect parts of this name.

Expects for up to 4 arguments:
I<case>, I<lastname>, I<firstname>, I<patronym>

Available I<cases> are: C<NOMINATIVE>, C<GENITIVE>, C<DATIVE>,
C<ACCUSATIVE>, C<INSTRUMENTAL>, C<PREPOSITIONAL>.

It returns list which contains
inflected I<lastname>, I<firstname>, I<patronym>

=cut

sub inflect_given_name {
    my $case = shift;
    return @_ if $case eq NOMINATIVE;
    my @name = _inflect_given_name(
        detect_gender_by_given_name( @_ ), $case, @_
    );
} # sub inflect_given_name


# Exceptions:

# Masculine names which ends to vowels “a” and “ya”
sub _MASCULINE_NAMES () {
    return qw(
        Аба Азарья Акива Аккужа Аникита Алёша Андрюха Андрюша Аса Байгужа Боря
        Вафа Ваня Вася Витя Вова Володя Габдулла Габидулла Гаврила Гадельша
        Гайнулла Гайса Гайфулла Галиулла Гарри Гата Гдалья Гийора Гиля Гога Гоша Гошеа
        Данила Джиханша Дима Жора Зайнулла Закария Зия Зосима Зхарья Зыя Идельгужа
        Иешуа Изя Ильмурза Илья Иона Исайя Иуда Йегошуа Йегуда Йедидья Карагужа Коля
        Костя Кузьма Лёва Лёха Лёша Лука Ларри Марданша Микола Мирза Миха Миша Мойша Моня
        Муртаза Муса Мусса Мустафа Никита Нэта Нэхэмья Овадья Петя Птахья
        Рахматулла Риза Рома Савва Сафа Серёга Серёжа Сила Симха Сэадья Товия
        Толя Федя Фима Фока Фома Хамза Хананья Цфанья Шалва Шахна Шрага Эзра
        Элиша Элькана Юмагужа Юра Ярулла Яхья Яша
    )
}

# Feminine names which ends to consonants
sub _FEMININE_NAMES () {
    return qw(
        Айгуль Айгюль Айзиряк Айрис Альфинур Асылгюль Бадар Бадиян Банат Бедер
        Бибикамал Бибинур Гайниджамал Гайникамал Гаухар Гиффат Гулендем
        Гульбадиян Гульдар Гульджамал Гульджихан Гульехан Гульзар Гулькей
        Гульназ Гульнар Гульнур Гульсем Гульсесек Гульсибар Гульчачак Гульшат
        Гульшаян Гульюзум Гульямал Гюзель Джамал Джаухар Джихан Дильбар Диляфруз
        Зайнаб Зайнап Зейнаб Зубарджат Зуберьят Ильсёяр Камяр Карасес Кейт
        Кэролайн Кэт Кэтрин Кямар Любовь Ляйсан Магинур Магруй Марьям Минджихан
        Минлегюль Миньеган Наркас Нинель Нурджиган Райхан Раушан Рахель Рахиль
        Рут Руфь Рэйчел Сагадат Сагдат Сарбиназ Сарвар Сафин Сахибджамал Сулпан
        Сумбуль Сурур Сюмбель Сясак Тамар Тансулпан Умегульсум Уммегюльсем
        Фарваз Фархинур Фирдаус Хаджар Хажар Хаят Хуршид Чечек Чулпан Шамсинур
        Элис Энн Юдифь Юндуз Ямал
    )
}

# Ambiguous names which can be masculine and feminine
sub _AMBIGUOUS_NAMES () {
    return qw(
        Валя Женя Мина Паша Саша Шура
    )
}

=head1 AUTHOR

Alexander Sapozhnikov, C<< <shoorick at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests
to C<bug-lingua-ru-inflect at rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-RU-Inflect>.
I will be notified, and then
you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::RU::Inflect

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-RU-Inflect>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-RU-Inflect>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-RU-Inflect>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-RU-Inflect/>

=item * Public repository at github

L<https://github.com/shoorick/lingua-ru-inflect>

=back

=head1 SEE ALSO

Russian translation of this documentation available
at F<RU/Lingua/RU/Inflect.pod>

=head1 ACKNOWLEDGEMENTS

L<http://www.imena.org/declension.html> (in Russian) for rules of declension.

=head1 COPYRIGHT & LICENSE

Copyright 2009-2014 Alexander Sapozhnikov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
