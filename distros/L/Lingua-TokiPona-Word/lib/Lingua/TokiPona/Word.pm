# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to interact with the words of Toki Pona


package Lingua::TokiPona::Word;

use v5.20;
use strict;
use warnings;

use Carp;
use Data::Identifier v0.34;
use Data::Identifier::Generate;
use Data::Displaycolour;

our $VERSION = v0.04;

use parent qw(Data::Identifier::Interface::Known Lingua::Generic::Interface::Word);

use constant {
    WK_WORD_GENERATOR => Data::Identifier->new(uuid => '45823114-5f38-47d8-a749-2e7f3ec819c3', tagname => 'toki-pona-word-generator')->register,
    WK_WORD_NAMESPACE => Data::Identifier->new(uuid => '8d043e5e-b7da-4a37-a87a-26bb361288a1', tagname => 'toki-pona-word-namespace')->register,
    WK_WORD_TYPE      => Data::Identifier->new(uuid => 'baf7bee1-0889-4a84-afc2-4904857d0571', tagname => 'toki-pona-word')->register,
    WK_LT_TOK         => Data::Identifier->new(uuid => 'f21986c8-baa1-5b7e-b357-2a76285c4778', displayname => 'Toki Pona', request => 'tok')->register,
};

my %_words;
my %_by_ise;
my %_by_ucsur;

__PACKAGE__->_new($_) foreach (
    # NOTE: Each list only contains the words not already in one of the lists above it.
    qw(
    a kin akesi ala alasa ale ali anpa ante anu awen e en esun ijo ike ilo insa jaki jan
    jelo jo kala kalama kama kasi ken kepeken kili kiwen ko kon kule kulupu kute la lape
    laso lawa len lete li lili linja lipu loje lon luka lukin oko lupa ma mama mani meli
    mi mije moku moli monsi mu mun musi mute nanpa nasa nasin nena ni nimi noka o olin ona
    open pakala pali palisa pan pana pi pilin pimeja pini pipi poka poki pona pu sama seli
    selo seme sewi sijelo sike sin namako sina sinpin sitelen sona soweli suli suno supa suwi
    tan taso tawa telo tenpo toki tomo tu unpa uta utala walo wan waso wawa weka wile
    ),
    qw(kijetesantakalu kin kipisi ku leko misikeke monsuta n soko tonsi), # Common
    qw(epiku jasima lanpan linluwi majuna meso nimisin su), # Uncommon
    qw(
    apeja isipin jami kamalawala kapesi kiki kokosila konwe kulijo melome mijomi misa nja
    ojuta oke omekapo owe pake penpo pika po powe puwa san soto sutopatikuna taki te teje
    to unu usawi wa wasoweli wekama wuwojiti yupekosi
    ), # Obscure
    qw(suke toma), # Typo
    qw(ete ewe kan ke kese kuntu likujo loka mulapisu neja pata peto polinpin pomotolo samu tuli umesu waleja), # nimi ku lili
    qw(ju lu nu u), # Reserved words
);

__PACKAGE__->new(string => $_)->{class}{stopword} = 1 foreach qw(a kin anu e en la li o pi seme);

my %_concepts = (
    loje    => 'c9ec3bea-558e-4992-9b76-91f128b6cf29', # red
    jelo    => '2892c143-2ae7-48f1-95f4-279e059e7fc3', # yellow
    laso    => 'abcbf48d-c302-4be1-8c5c-a8de4471bcbb', # cyan
    walo    => '1a2c23fa-2321-47ce-bf4f-5f08934502de', # white
    pimeja  => 'fade296d-c34f-4ded-abd5-d9adaf37c284', # black
);

foreach my $str (keys %_concepts) {
    my __PACKAGE__ $word = __PACKAGE__->new(string => $str);
    my Data::Identifier $word_id = $word->as('Data::Identifier')->register;
    my Data::Identifier $concept = Data::Identifier->new(uuid => $_concepts{$str})->register;

    $_concepts{$str} = $concept;

    $word->Data::Displaycolour::mark(for => $concept);
    $word_id->Data::Displaycolour::mark(for => $concept);
}

{
    my %ucsur = (
        0xF1900 => 'SITELEN PONA IDEOGRAPH A',
        0xF1901 => 'SITELEN PONA IDEOGRAPH AKESI',
        0xF1902 => 'SITELEN PONA IDEOGRAPH ALA',
        0xF1903 => 'SITELEN PONA IDEOGRAPH ALASA',
        0xF1904 => 'SITELEN PONA IDEOGRAPH ALE',
        0xF1905 => 'SITELEN PONA IDEOGRAPH ANPA',
        0xF1906 => 'SITELEN PONA IDEOGRAPH ANTE',
        0xF1907 => 'SITELEN PONA IDEOGRAPH ANU',
        0xF1908 => 'SITELEN PONA IDEOGRAPH AWEN',
        0xF1909 => 'SITELEN PONA IDEOGRAPH E',
        0xF190A => 'SITELEN PONA IDEOGRAPH EN',
        0xF190B => 'SITELEN PONA IDEOGRAPH ESUN',
        0xF190C => 'SITELEN PONA IDEOGRAPH IJO',
        0xF190D => 'SITELEN PONA IDEOGRAPH IKE',
        0xF190E => 'SITELEN PONA IDEOGRAPH ILO',
        0xF190F => 'SITELEN PONA IDEOGRAPH INSA',
        0xF1910 => 'SITELEN PONA IDEOGRAPH JAKI',
        0xF1911 => 'SITELEN PONA IDEOGRAPH JAN',
        0xF1912 => 'SITELEN PONA IDEOGRAPH JELO',
        0xF1913 => 'SITELEN PONA IDEOGRAPH JO',
        0xF1914 => 'SITELEN PONA IDEOGRAPH KALA',
        0xF1915 => 'SITELEN PONA IDEOGRAPH KALAMA',
        0xF1916 => 'SITELEN PONA IDEOGRAPH KAMA',
        0xF1917 => 'SITELEN PONA IDEOGRAPH KASI',
        0xF1918 => 'SITELEN PONA IDEOGRAPH KEN',
        0xF1919 => 'SITELEN PONA IDEOGRAPH KEPEKEN',
        0xF191A => 'SITELEN PONA IDEOGRAPH KILI',
        0xF191B => 'SITELEN PONA IDEOGRAPH KIWEN',
        0xF191C => 'SITELEN PONA IDEOGRAPH KO',
        0xF191D => 'SITELEN PONA IDEOGRAPH KON',
        0xF191E => 'SITELEN PONA IDEOGRAPH KULE',
        0xF191F => 'SITELEN PONA IDEOGRAPH KULUPU',
        0xF1920 => 'SITELEN PONA IDEOGRAPH KUTE',
        0xF1921 => 'SITELEN PONA IDEOGRAPH LA',
        0xF1922 => 'SITELEN PONA IDEOGRAPH LAPE',
        0xF1923 => 'SITELEN PONA IDEOGRAPH LASO',
        0xF1924 => 'SITELEN PONA IDEOGRAPH LAWA',
        0xF1925 => 'SITELEN PONA IDEOGRAPH LEN',
        0xF1926 => 'SITELEN PONA IDEOGRAPH LETE',
        0xF1927 => 'SITELEN PONA IDEOGRAPH LI',
        0xF1928 => 'SITELEN PONA IDEOGRAPH LILI',
        0xF1929 => 'SITELEN PONA IDEOGRAPH LINJA',
        0xF192A => 'SITELEN PONA IDEOGRAPH LIPU',
        0xF192B => 'SITELEN PONA IDEOGRAPH LOJE',
        0xF192C => 'SITELEN PONA IDEOGRAPH LON',
        0xF192D => 'SITELEN PONA IDEOGRAPH LUKA',
        0xF192E => 'SITELEN PONA IDEOGRAPH LUKIN',
        0xF192F => 'SITELEN PONA IDEOGRAPH LUPA',
        0xF1930 => 'SITELEN PONA IDEOGRAPH MA',
        0xF1931 => 'SITELEN PONA IDEOGRAPH MAMA',
        0xF1932 => 'SITELEN PONA IDEOGRAPH MANI',
        0xF1933 => 'SITELEN PONA IDEOGRAPH MELI',
        0xF1934 => 'SITELEN PONA IDEOGRAPH MI',
        0xF1935 => 'SITELEN PONA IDEOGRAPH MIJE',
        0xF1936 => 'SITELEN PONA IDEOGRAPH MOKU',
        0xF1937 => 'SITELEN PONA IDEOGRAPH MOLI',
        0xF1938 => 'SITELEN PONA IDEOGRAPH MONSI',
        0xF1939 => 'SITELEN PONA IDEOGRAPH MU',
        0xF193A => 'SITELEN PONA IDEOGRAPH MUN',
        0xF193B => 'SITELEN PONA IDEOGRAPH MUSI',
        0xF193C => 'SITELEN PONA IDEOGRAPH MUTE',
        0xF193D => 'SITELEN PONA IDEOGRAPH NANPA',
        0xF193E => 'SITELEN PONA IDEOGRAPH NASA',
        0xF193F => 'SITELEN PONA IDEOGRAPH NASIN',
        0xF1940 => 'SITELEN PONA IDEOGRAPH NENA',
        0xF1941 => 'SITELEN PONA IDEOGRAPH NI',
        0xF1942 => 'SITELEN PONA IDEOGRAPH NIMI',
        0xF1943 => 'SITELEN PONA IDEOGRAPH NOKA',
        0xF1944 => 'SITELEN PONA IDEOGRAPH O',
        0xF1945 => 'SITELEN PONA IDEOGRAPH OLIN',
        0xF1946 => 'SITELEN PONA IDEOGRAPH ONA',
        0xF1947 => 'SITELEN PONA IDEOGRAPH OPEN',
        0xF1948 => 'SITELEN PONA IDEOGRAPH PAKALA',
        0xF1949 => 'SITELEN PONA IDEOGRAPH PALI',
        0xF194A => 'SITELEN PONA IDEOGRAPH PALISA',
        0xF194B => 'SITELEN PONA IDEOGRAPH PAN',
        0xF194C => 'SITELEN PONA IDEOGRAPH PANA',
        0xF194D => 'SITELEN PONA IDEOGRAPH PI',
        0xF194E => 'SITELEN PONA IDEOGRAPH PILIN',
        0xF194F => 'SITELEN PONA IDEOGRAPH PIMEJA',
        0xF1950 => 'SITELEN PONA IDEOGRAPH PINI',
        0xF1951 => 'SITELEN PONA IDEOGRAPH PIPI',
        0xF1952 => 'SITELEN PONA IDEOGRAPH POKA',
        0xF1953 => 'SITELEN PONA IDEOGRAPH POKI',
        0xF1954 => 'SITELEN PONA IDEOGRAPH PONA',
        0xF1955 => 'SITELEN PONA IDEOGRAPH PU',
        0xF1956 => 'SITELEN PONA IDEOGRAPH SAMA',
        0xF1957 => 'SITELEN PONA IDEOGRAPH SELI',
        0xF1958 => 'SITELEN PONA IDEOGRAPH SELO',
        0xF1959 => 'SITELEN PONA IDEOGRAPH SEME',
        0xF195A => 'SITELEN PONA IDEOGRAPH SEWI',
        0xF195B => 'SITELEN PONA IDEOGRAPH SIJELO',
        0xF195C => 'SITELEN PONA IDEOGRAPH SIKE',
        0xF195D => 'SITELEN PONA IDEOGRAPH SIN',
        0xF195E => 'SITELEN PONA IDEOGRAPH SINA',
        0xF195F => 'SITELEN PONA IDEOGRAPH SINPIN',
        0xF1960 => 'SITELEN PONA IDEOGRAPH SITELEN',
        0xF1961 => 'SITELEN PONA IDEOGRAPH SONA',
        0xF1962 => 'SITELEN PONA IDEOGRAPH SOWELI',
        0xF1963 => 'SITELEN PONA IDEOGRAPH SULI',
        0xF1964 => 'SITELEN PONA IDEOGRAPH SUNO',
        0xF1965 => 'SITELEN PONA IDEOGRAPH SUPA',
        0xF1966 => 'SITELEN PONA IDEOGRAPH SUWI',
        0xF1967 => 'SITELEN PONA IDEOGRAPH TAN',
        0xF1968 => 'SITELEN PONA IDEOGRAPH TASO',
        0xF1969 => 'SITELEN PONA IDEOGRAPH TAWA',
        0xF196A => 'SITELEN PONA IDEOGRAPH TELO',
        0xF196B => 'SITELEN PONA IDEOGRAPH TENPO',
        0xF196C => 'SITELEN PONA IDEOGRAPH TOKI',
        0xF196D => 'SITELEN PONA IDEOGRAPH TOMO',
        0xF196E => 'SITELEN PONA IDEOGRAPH TU',
        0xF196F => 'SITELEN PONA IDEOGRAPH UNPA',
        0xF1970 => 'SITELEN PONA IDEOGRAPH UTA',
        0xF1971 => 'SITELEN PONA IDEOGRAPH UTALA',
        0xF1972 => 'SITELEN PONA IDEOGRAPH WALO',
        0xF1973 => 'SITELEN PONA IDEOGRAPH WAN',
        0xF1974 => 'SITELEN PONA IDEOGRAPH WASO',
        0xF1975 => 'SITELEN PONA IDEOGRAPH WAWA',
        0xF1976 => 'SITELEN PONA IDEOGRAPH WEKA',
        0xF1977 => 'SITELEN PONA IDEOGRAPH WILE',
        0xF1978 => 'SITELEN PONA IDEOGRAPH NAMAKO',
        0xF1979 => 'SITELEN PONA IDEOGRAPH KIN',
        0xF197A => 'SITELEN PONA IDEOGRAPH OKO',
        0xF197B => 'SITELEN PONA IDEOGRAPH KIPISI',
        0xF197C => 'SITELEN PONA IDEOGRAPH LEKO',
        0xF197D => 'SITELEN PONA IDEOGRAPH MONSUTA',
        0xF197E => 'SITELEN PONA IDEOGRAPH TONSI',
        0xF197F => 'SITELEN PONA IDEOGRAPH JASIMA',
        0xF1980 => 'SITELEN PONA IDEOGRAPH KIJETESANTAKALU',
        0xF1981 => 'SITELEN PONA IDEOGRAPH SOKO',
        0xF1982 => 'SITELEN PONA IDEOGRAPH MESO',
        0xF1983 => 'SITELEN PONA IDEOGRAPH EPIKU',
        0xF1984 => 'SITELEN PONA IDEOGRAPH KOKOSILA',
        0xF1985 => 'SITELEN PONA IDEOGRAPH LANPAN',
        0xF1986 => 'SITELEN PONA IDEOGRAPH N',
        0xF1987 => 'SITELEN PONA IDEOGRAPH MISIKEKE',
        0xF1988 => 'SITELEN PONA IDEOGRAPH KU',
        0xF1989 => 'SITELEN PONA IDEOGRAPH LEFTWARDS NI',
        0xF198A => 'SITELEN PONA IDEOGRAPH UPWARDS NI',
        0xF198B => 'SITELEN PONA IDEOGRAPH RIGHTWARDS NI',
        0xF198C => 'SITELEN PONA IDEOGRAPH ALTERNATE SEWI',
        0xF1990 => 'SITELEN PONA START OF CARTOUCHE',
        0xF1991 => 'SITELEN PONA END OF CARTOUCHE',
        0xF1992 => 'SITELEN PONA COMBINING CARTOUCHE EXTENSION',
        0xF1993 => 'SITELEN PONA START OF LONG PI',
        0xF1994 => 'SITELEN PONA COMBINING LONG PI EXTENSION',
        0xF1995 => 'SITELEN PONA STACKING JOINER',
        0xF1996 => 'SITELEN PONA SCALING JOINER',
        0xF1997 => 'SITELEN PONA START OF LONG GLYPH',
        0xF1998 => 'SITELEN PONA END OF LONG GLYPH',
        0xF1999 => 'SITELEN PONA COMBINING LONG GLYPH EXTENSION',
        0xF199A => 'SITELEN PONA START OF REVERSE LONG GLYPH',
        0xF199B => 'SITELEN PONA END OF REVERSE LONG GLYPH',
        0xF199C => 'SITELEN PONA MIDDLE DOT',
        0xF199D => 'SITELEN PONA COLON',
        0xF199E => 'SITELEN PONA COMBINING TALLY MARK',
        0xF19A0 => 'SITELEN PONA IDEOGRAPH PAKE',
        0xF19A1 => 'SITELEN PONA IDEOGRAPH APEJA',
        0xF19A2 => 'SITELEN PONA IDEOGRAPH MAJUNA',
        0xF19A3 => 'SITELEN PONA IDEOGRAPH POWE',
        0xF19A4 => 'SITELEN PONA IDEOGRAPH LINLUWI',
        0xF19A5 => 'SITELEN PONA IDEOGRAPH KIKI',
        0xF19A6 => 'SITELEN PONA IDEOGRAPH SU',
        0xF19A7 => 'SITELEN PONA IDEOGRAPH ISIPIN',
        0xF19A8 => 'SITELEN PONA IDEOGRAPH KAMALAWALA',
        0xF19A9 => 'SITELEN PONA IDEOGRAPH KAPESI',
        0xF19AA => 'SITELEN PONA IDEOGRAPH MELOME',
        0xF19AB => 'SITELEN PONA IDEOGRAPH MIJOMI',
        0xF19AC => 'SITELEN PONA IDEOGRAPH MISA',
        0xF19AD => 'SITELEN PONA IDEOGRAPH NIMISIN',
        0xF19AE => 'SITELEN PONA IDEOGRAPH NJA',
        0xF19AF => 'SITELEN PONA IDEOGRAPH OKE',
        0xF19B0 => 'SITELEN PONA IDEOGRAPH OMEKAPO',
        0xF19B1 => 'SITELEN PONA IDEOGRAPH PUWA',
        0xF19B2 => 'SITELEN PONA IDEOGRAPH SAN',
        0xF19B3 => 'SITELEN PONA IDEOGRAPH TAKI',
        0xF19B4 => 'SITELEN PONA IDEOGRAPH TE',
        0xF19B5 => 'SITELEN PONA IDEOGRAPH TO',
        0xF19B6 => 'SITELEN PONA IDEOGRAPH UNU',
        0xF19B7 => 'SITELEN PONA IDEOGRAPH USAWI',
        0xF19B8 => 'SITELEN PONA IDEOGRAPH WA',
        0xF19B9 => 'SITELEN PONA IDEOGRAPH WUWOJITI',
        0xF19BA => 'SITELEN PONA IDEOGRAPH YUPEKOSI',
    );
    foreach my $cp (keys %ucsur) {
        my ($str) = $ucsur{$cp} =~ /^SITELEN PONA IDEOGRAPH ([A-Z]+)\z/ or next;
        my $word = $_words{lc $str} // next;
        $word->{ucsur} = int $cp;
        $_by_ucsur{$cp} = $word;
    }
}


# Not our actual constructor, see _new(). This is for the public API only
sub new {
    my ($pkg, $type, $value, @opts) = @_;

    croak 'No type given' unless defined $type;
    croak 'No value given' unless defined $value;
    croak 'Stray options passed' if scalar @opts;

    if ($type eq 'from') {
        if (ref $value) {
            if ($value->isa(__PACKAGE__)) {
                return $value;
            } elsif ($value->isa('Data::Identifier')) {
                $type = 'Data::Identifier';
            } elsif ($value->isa('Lingua::famibeib::Word')) {
                $value = $value->as(__PACKAGE__);
                return $value if scalar(@opts) == 0;
                $value = $value->as('Data::Identifier');
                $type = 'Data::Identifier';
            } else {
                $type = 'Data::Identifier';
                $value = Data::Identifier->new(from => $value);
            }
        } else {
            $type = 'string';
        }
    } elsif ($type eq 'ise') {
        $type = 'Data::Identifier';
        $value = Data::Identifier->new(ise => $value);
    }

    if ($type eq 'string') {
        return $_words{lc $value} // croak 'No such word';
    } elsif ($type eq 'ucsur') {
        if ($value =~ /^U\+([0-9a-fA-F]{4,6})\z/) {
            $value = hex($1);
        }
        return $_by_ucsur{$value} // croak 'No such word';
    } elsif ($type eq 'Data::Identifier') {
        return $_by_ise{$value->uuid(default => undef, no_defaults => 1) // $value->ise} // croak 'No such word';
    } else {
        croak 'Bad type: '.$type;
    }
}


# NOTE: Implemented via Lingua::Generic::Interface::Word


sub ucsur {
    my ($self, %opts) = @_;
    my $has_default = exists $opts{default};
    my $default     = delete $opts{default};
    my $as          = delete $opts{as};
    my $ucsur       = $self->{ucsur};

    delete $opts{no_defaults};

    croak 'Stray options passed' if scalar keys %opts;

    unless (defined $ucsur) {
        return $opts{default} if exists $opts{default};
        croak 'No value found';
    }

    return $ucsur unless defined $as;

    $self->{ucsur_id} //= Data::Identifier::Generate->unicode_character(unicode => $ucsur)->register;

    return $self->{ucsur_id}->as($as, so => $self);
}


# NOTE: Implemented via Lingua::Generic::Interface::Word


# NOTE: Implemented via Lingua::Generic::Interface::Word


sub has_type {
    my ($self, %opts) = @_;
    my $as = delete $opts{as};

    delete $opts{default};
    delete $opts{no_defaults};

    croak 'Stray options passed' if scalar keys %opts;

    return WK_WORD_TYPE if !defined($as) || WK_WORD_TYPE->isa($as);

    return WK_WORD_TYPE->as($as, so => $self);
}


#@returns Data::Identifier
sub natural_language {
    my ($self, @opts) = @_;
    croak 'Stray options passed' if scalar @opts;
    return WK_LT_TOK;
}


#@returns __PACKAGE__
sub register {
    my ($self, @opts) = @_;
    croak 'Stray options passed' if scalar @opts;
    return $self;
}


#@returns __PACKAGE__
sub stem {
    my ($self, @opts) = @_;
    croak 'Stray options passed' if scalar @opts;
    return $self;
}


sub concepts {
    my ($self, @opts) = @_;
    my $concept = $_concepts{$self->as_string};
    croak 'Stray options passed' if scalar @opts;
    return () unless defined $concept;
    return ($concept);
}

# ---- Overridden methods ----



# ---- Private helpers ----

#@returns __PACKAGE__
sub _new {
    my ($pkg, $str) = @_;
    my $self = bless {class => {}}, $pkg;
    my $id;

    $str = lc($str); # just to be on the safe side

    $self->{string} = $str;

    $id = Data::Identifier::Generate->generic(
        request => $str,
        displayname => $str,
        tagname => $str,
        style => 'id-based',
        namespace => WK_WORD_NAMESPACE,
        generator => WK_WORD_GENERATOR,
    )->register;

    $self->{id} = $id;

    $_words{$str} = $self;
    $_by_ise{$id->uuid} = $self;
    return $self;
}

sub as {
    my ($self, $as, @opts) = @_;
    my Data::Identifier $id = $self->{id};

    if (scalar(@opts) == 0) {
        return $self if $self->isa($as);
        return $id if $as eq 'Data::Identifier';

        if ($as eq 'Lingua::famibeib::Word') {
            require Lingua::famibeib::Word;
            return Lingua::famibeib::Word->new(from => $self);
        }
    }

    return $id->as($as, @opts);
}

sub ise { goto &Data::Identifier::Interface::Simple::ise } # overridden using tail-call

sub _known_provider {
    my ($pkg, $class, %opts) = @_;

    croak 'Unsupported options passed' if scalar(keys %opts);

    if ($class eq 'word' || $class eq 'words') {
        return ([values %_words], rawtype => __PACKAGE__);
    } elsif ($class eq 'stopword') {
        return ([grep {$_->{class}{$class}} values %_words], rawtype => __PACKAGE__);
    } elsif ($class eq ':all') {
        return ([
                values(%_words),
                WK_WORD_GENERATOR, WK_WORD_NAMESPACE,
                WK_WORD_TYPE,
                WK_LT_TOK,
            ], rawtype => 'Data::Identifier::Interface::Simple');
    }

    croak 'Unsupported class';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::TokiPona::Word - module to interact with the words of Toki Pona

=head1 VERSION

version v0.04

=head1 SYNOPSIS

    use Lingua::TokiPona::Word;

    my Lingua::TokiPona::Word $word = Lingua::TokiPona::Word->new(string => 'mi');

    say $word->as_string;

This module inherits from
L<Lingua::Generic::Interface::Word> (since v0.03),
L<Data::Identifier::Interface::Known> (since v0.01),
L<Data::Identifier::Interface::Simple> (since v0.01),
and L<Data::Identifier::Interface::Subobjects> (since v0.01).

=head1 OVERVIEW

Toki Pona is a constructed language that features a specifically small set of vocables.
This module abstracts those words. It aims to contain all known words (as of v0.02: which is currently not yet fully true).

As the vocabulary is so limited, this module does hold all the words in memory at all times.
This means that there are never two different object instances for the same words.
(Note that this may limit the usefulness of L<Data::Identifier::Interface::Subobjects>).

That said, synonyms are consider different words.
So this is round-trip safe (you always get the word you asked for, not one of it's synonyms).

To get a list of all known words use L</known>.

=head1 METHODS

=head2 new

    my Lingua::TokiPona::Word $word = Lingua::TokiPona::Word->new($type => $value);
    # e.g.:
    my Lingua::TokiPona::Word $word = Lingua::TokiPona::Word->new(string => 'mi');

(since v0.01)

Constructs a new word.
The word is normalised as part of this.
This method deduplicate instances.

Currently the following types (C<$type>) are supported:

=over

=item C<from>

(since v0.01)

Constructs a word from an object.
C<$value> should be a reference.

Currently references to the following types are supported:
L<Lingua::TokiPona::Word>,
or anything L<Data::Identifier/new> accepts via C<from>.
More types might be supported.

If C<$value> is not a reference the value is parsed as per C<string> if it looks like a word string (experimental since v0.01).

=item C<ise>

(since v0.02)

Constructs a word from a ISE (such as returned by L<Data::Identifier::Interface::Simple/ise>).

=item C<string>

(since v0.01)

Constructs a word from it's (latin) string representation.

=item C<ucsur>

(since v0.02)

Constructs a word from the UCSUR code point.

See L</ucsur> for details.

Accepts the numerical code point or standard Unicode notation (C<U+xxxx>).

=back

=head2 as_string

    my $str = $word->as_string;

(since v0.01)

Returns the string representation of the word.

See also: L<Lingua::Generic::Interface::Word/as_string>.

=head2 ucsur

    my $ucsur = $word->ucsur( [ %opts ] );

(since v0.02)

Returns the Under-ConScript Unicode Registry (UCSUR) code point of the word or C<die>s if there is none.

Returns the numerical Unicode code point unless C<as> is given.

The following options are supported:

=over

=item C<as>

Returns the value as the passed type.
All types supported by L<Data::Identifier/as> are supported.

=item C<default>

The default value to return if no other value is available.
This can be set to C<undef> to let this method return C<undef> (not C<die>).

=item C<no_defaults>

This option is accepted but ignored.

=back

=head2 eq

    my $bool = $word->eq($other); # $word must be non-undef
    # or:
    my $bool = Lingua::TokiPona::Word::eq($word, $other); # $word can be undef

(since v0.01)

Compares two words to be equal.

If both words are C<undef> they are considered equal.

If C<$word> or C<$other> is not an instance of L<Lingua::TokiPona::Word> or C<undef>
L</new> with the type C<from> is used.

The operators L<perlop/eq> and L<perlop/ne> are overloaded to this method.

See also: L<Lingua::Generic::Interface::Word/eq>.

=head2 cmp

    my $val = $word->cmp($other); # $word must be non-undef
    # or:
    my $val = Lingua::TokiPona::Word::cmp($word, $other); # $word can be undef

(experimental since v0.01)

Compares the words similar to C<cmp>. This method can be used to order words.
To check for them to be equal see L</eq>.

The parameters are parsed the same way as L</eq>.

The operator L<perlop/cmp> is overloaded to this method.

If this method is used for sorting the exact resulting order is not defined. However:

=over

=item *

The order is stable

=item *

The order is the same for C<$a-E<gt>cmp($b)> as for C<- $b-E<gt>cmp($a)>.

=back

See also: L<Lingua::Generic::Interface::Word/cmp>.

=head2 has_type

    my $type = $word->has_type( [ %opts ] );

(since v0.02)

Returns the type of the word which will always be the same for all words: a Toki Pona word.

B<Note:>
If you want to know about other roles (e.g. particle vs. noun) this is the wrong method for you.

The following options are accepted:

=over

=item C<as>

Returns the value as the passed type.
All types supported by L<Data::Identifier/as> are supported.

=item C<default>

This option is accepted but ignored.

=item C<no_defaults>

This option is accepted but ignored.

=back

=head2 natural_language

    my Data::Identifier $natural_language = $word->natural_language;

(since v0.03)

Returns the natural language this word is in.

For Toki Pona words it will always return Toki Pona.
However this method might be useful together with other modules from the C<Lingua> namespace.

See also: L<Lingua::Generic::Interface::Word/natural_language>.

=head2 register

    $word->register

(since v0.04)

Implements L<Lingua::Generic::Interface::Word/register>.
As all words known by this module are always registered anyway this is a no-op.

=head2 stem

    my Lingua::TokiPona::Word $stem = $word->stem

(since v0.04)

Implements L<Lingua::Generic::Interface::Word/stem>.
As all Toki Pona words are stems anyway this is a no-op.

=head2 concepts

    my @concepts = $word->concepts;

(experimental since v0.04)

Implements L<Lingua::Generic::Interface::Word/stem>.
Returns a list of related concepts.

=head2 known

    my @list = Lingua::TokiPona::Word->known($class [, %opts ] );

(since v0.01)

Returns the known items for the given class.

For details and supported options see L<Data::Identifier::Interface::Known/known>.

The following classes are supported:

=over

=item C<:all>

(since v0.01)

Returns all known things.

=item C<word>

(since v0.03)

Returns all known words.

=item C<words>

(since v0.02, deprecated since 0.03)

Deprecated alias for C<word>.

=item C<stopword>

(since v0.02)

Returns all known stopwords.

=back

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
