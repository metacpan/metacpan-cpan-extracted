package Lingua::Deva;

use v5.12.1;
use strict;
use warnings;
use utf8;
use charnames          qw( :full );
use open               qw( :encoding(UTF-8) :std );
use Unicode::Normalize qw( NFD NFC );
use Carp               qw( croak carp );

use Lingua::Deva::Aksara;
use Lingua::Deva::Maps qw( %Consonants %Vowels %Diacritics %Finals
                           $Inherent $Virama $Avagraha );

=encoding UTF-8

=head1 NAME

Lingua::Deva - Convert between Latin and Devanagari Sanskrit text

=cut

our $VERSION = '1.20';

=head1 SYNOPSIS

    use v5.12.1;
    use strict;
    use utf8;
    use charnames ':full';
    use Lingua::Deva;

    # Basic usage
    my $d = Lingua::Deva->new();
    say $d->to_latin('आसीद्राजा'); # prints 'āsīdrājā'
    say $d->to_deva('Nalo nāma'); # prints 'नलो नाम'

    # With configuration: strict, allow Danda, 'w' for 'v'
    my %c = %Lingua::Deva::Maps::Consonants;
    $d = Lingua::Deva->new(
        strict => 1,
        allow  => [ "\N{DEVANAGARI DANDA}" ],
        C      => do { $c{'w'} = delete $c{'v'}; \%c },
    );
    say $d->to_deva('ziwāya'); # 'zइवाय', warning for 'z'
    say $d->to_latin('सर्वम्।'); # 'sarwam।', no warnings

=head1 DESCRIPTION

The C<Lingua::Deva> module provides facilities for converting Sanskrit in
various Latin transliterations to Devanagari and vice-versa.  "Deva" is the
name for the Devanagari (I<devanāgarī>) script according to ISO 15924.

The facilities of this module are exposed through a simple interface in the
form of instances of the L<Lingua::Deva> class.  A number of configuration
options can be passed to it during initialization.

Using the module is as simple as creating a C<Lingua::Deva> instance and
calling its methods L<to_deva()> or L<to_latin()> with appropriate string
arguments.

    my $d = Lingua::Deva->new();
    say $d->to_latin('कामसूत्र');
    say $d->to_deva('Kāmasūtra');

By default, transliteration follows the widely used IAST conventions.  Three
other ready-made transliteration schemes are also included with this module,
ISO 15919 (C<ISO15919>), Harvard-Kyoto (C<HK>), and ITRANS.

    my $d = Lingua::Deva->new(map => 'HK');
    say $d->to_latin('कामसूत्र'); # prints 'kAmasUtra'

For additional flexibility all mappings can be completely customized; users
can also provide their own.

    use Lingua::Deva::Maps::ISO15919;
    my %f = %Lingua::Deva::Maps::ISO15919::Finals;
    my $d = Lingua::Deva->new(
        map           => 'IAST', # use IAST transliteration
        casesensitive => 1,      # do not case fold
        F             => \%f,    # ISO 15919 mappings for finals
    );
    say $d->to_deva('Vṛtraṁ'); # prints 'Vऋत्रं'

For more information on customization see L<Lingua::Deva::Maps>.

Behind the scenes, all translation is done via an intermediate object
representation called "Aksara" (Sanskrit I<akṣara>).  These objects are
instances of L<Lingua::Deva::Aksara>, which provides an interface to inspect
and manipulate individual Aksaras.

    # Create an array of Aksaras
    my $a = $d->l_to_aksaras('Kāmasūtra');

    # Print vowel in the fourth Aksara
    say $a->[3]->vowel();

The methods and options of C<Lingua::Deva> are described below.

=head2 Methods

=over 4

=item new()

Constructor.  Takes the following optional arguments.

=over 4

=item C<< map => 'IAST'|'ISO15919'|'HK'|'ITRANS' >>

Selects one of the ready-made transliteration schemes.

=item C<< casesensitive => (0|1) >>

Determines whether case is treated as distinctive or not.  Some schemes (eg.
Harvard-Kyoto) set this to C<1> while others (eg. IAST) set it to C<0>.

Default is C<0>.

=item C<< strict => (0|1) >>

In I<strict> mode invalid input is flagged with warnings.  Invalid means
either not a Devanagari token (eg. I<q>) or structurally ill-formed (eg. a
Devanagari diacritic vowel following an independent vowel).

Default is C<0>.

=item C<< allow => [ ... ] >>

In strict mode, the C<allow> array can be used to exempt certain characters
from being flagged as invalid even though they normally would be.

=item C<< avagraha => "'" >>

Specifies the Latin character used for the transcription of I<avagraha> (ऽ).

Default is C<"'"> (apostrophe).

=item C<< C => { consonants map } >>

=item C<< V => { independent vowels map } >>

=item C<< D => { diacritic vowels map } >>

=item C<< F => { finals map } >>

Transliteration maps in the direction from Latin to Devanagari script.

=item C<< DC => { consonants map } >>

=item C<< DV => { independent vowels map } >>

=item C<< DD => { diacritic vowels map } >>

=item C<< DF => { finals map } >>

Transliteration maps in the direction from Devanagari to Latin script.  When
these are not given, reversed versions of the Latin to Devanagari maps are
used.

The default maps are in L<Lingua::Deva::Maps>.  To customize, make a copy of
an existing mapping hash (or create your own) and pass it to one of these
parameters.

=back

=cut

sub new {
    my ($class, %opts) = @_;

    my $self = {
        casesensitive => 0,
        strict        => 0,
        allow         => [], # converted to a hash for efficiency
        avagraha      => "'",
        C             => \%Consonants,
        V             => \%Vowels,
        D             => \%Diacritics,
        F             => \%Finals,
        %opts,
    };

    # Transliteration scheme setup
    if (defined $self->{map}) {
        if ($self->{map} =~ /^(ISO15919|ITRANS|IAST|HK)$/) {
            no strict 'refs';
            my $pkg = "Lingua::Deva::Maps::$1";
            eval "require $pkg";
            for (qw(Consonants Vowels Diacritics Finals)) {
                my $k = substr $_, 0, 1;
                $self->{$k} = do { my %c = %{"${pkg}::$_"}; \%c } unless defined $opts{$k};
            }
            if (!defined $opts{casesensitive} and defined ${"${pkg}::CASE"}) {
                $self->{casesensitive} = ${"${pkg}::CASE"};
            }
        }
        else {
            carp("Invalid transliteration map, using default");
        }
    }

    # By default use reversed maps for the opposite direction (DC DV DD DF)
    for (qw( C V D F )) {
        $self->{"D$_"} = do { my %m = reverse %{$self->{$_}}; \%m } if !defined $self->{"D$_"};
    }

    # Make the inherent vowel translate to '' in the D map
    $self->{D}->{$Inherent} = '';

    # Convert the 'allow' array to a hash for fast lookup
    my %allow = map { $_ => 1 } @{ $self->{allow} };
    $self->{allow} = \%allow;

    # Make consonants, vowels, and finals available as tokens
    my %tokens = (%{ $self->{C} }, %{ $self->{V} }, %{ $self->{F} });
    $self->{T} = \%tokens;

    return bless $self, $class;
}

=item l_to_tokens()

Converts a string of Latin characters into tokens and returns a reference to
an array of tokens.  A "token" is either a character sequence which may
constitute a single Devanagari grapheme or a single non-Devanagari character.
In the first sense, a token is simply any key in the transliteration maps.

    my $t = $d->l_to_tokens("Bhārata\n");
    # $t now refers to the array ['Bh','ā','r','a','t','a',"\n"]

The input string is normalized with
L<Unicode::Normalize::NFD|Unicode::Normalize>.  No chomping takes place.
Upper case and lower case distinctions are preserved.

=cut

sub l_to_tokens {
    my ($self, $text) = @_;
    return unless defined $text;

    my $nfdtext = NFD($text);

    my $re = join '|', reverse sort { length $a <=> length $b } keys %{$self->{T}};
    my $reobject = $self->{casesensitive} ? qr/($re|.)/s : qr/($re|.)/is;

    my @tokens;
    while ($nfdtext =~ /$reobject/gc) {
        push @tokens, $1;
    }

    return \@tokens;
}

=item l_to_aksaras()

Converts a Latin string (or a reference to an array of tokens) into
L<Aksaras|Lingua::Deva::Aksara> and returns a reference to an array of
Aksaras.

    my $a = $d->l_to_aksaras('hyaḥ');
    is( ref($a->[0]), 'Lingua::Deva::Aksara', 'one aksara object' );
    done_testing();

Input tokens which can not be part of an Aksara pass through untouched.  Thus,
the resulting array can contain both C<Lingua::Deva::Aksara> objects and
separate tokens.

In I<strict> mode warnings for invalid tokens are output.

=cut

sub l_to_aksaras {
    my ($self, $input) = @_;

    # Input can be either a string (scalar) or an array reference
    my $tokens = ref($input) eq '' ? $self->l_to_tokens($input) : $input;

    my @aksaras;
    my $a;
    my $state = 0;
    my ($C, $V, $F) = ($self->{C}, $self->{V}, $self->{F});

    # Aksarization is implemented with a state machine.
    # State 0: Not currently constructing an aksara, ready for any input
    # State 1: Constructing consonantal onset
    # State 2: Onset and vowel read, ready for final or end of aksara

    for my $t (@$tokens) {
        my $lct = $self->{casesensitive} ? $t : lc $t;
        if ($state == 0) {
            if (exists $C->{$lct}) {         # consonant: new aksara
                $a = Lingua::Deva::Aksara->new( onset => [ $lct ] );
                $state = 1;
            }
            elsif (exists $V->{$lct}) {      # vowel: vowel-initial aksara
                $a = Lingua::Deva::Aksara->new( vowel => $lct );
                $state = 2;
            }
            else {                           # final/space/avagraha/other
                if ($t !~ /\p{Space}/ and $t ne $self->{avagraha}
                        and $self->{strict} and !exists $self->{allow}->{$t}) {
                    carp("Invalid token $t read");
                }
                push @aksaras, $t;
            }
        }
        elsif ($state == 1) {
            if (exists $C->{$lct}) {         # consonant: part of onset
                push @{ $a->onset() }, $lct;
            }
            elsif (exists $V->{$lct}) {      # vowel: vowel nucleus
                $a->vowel( $lct );
                $state = 2;
            }
            else {                           # final/space/avagraha/other
                if ($t !~ /\p{Space}/ and $t ne $self->{avagraha}
                        and $self->{strict} and !exists $self->{allow}->{$t}) {
                    carp("Invalid token $t read");
                }
                push @aksaras, $a, $t;
                $state = 0;
            }
        }
        elsif ($state == 2) {
            if (exists $C->{$lct}) {         # consonant: new aksara
                push @aksaras, $a;
                $a = Lingua::Deva::Aksara->new( onset => [ $lct ] );
                $state = 1;
            }
            elsif (exists $V->{$lct}) {      # vowel: new vowel-initial aksara
                push @aksaras, $a;
                $a = Lingua::Deva::Aksara->new( vowel => $lct );
                $state = 2;
            }
            elsif (exists $F->{$lct}) {      # final: end of aksara
                $a->final( $lct );
                push @aksaras, $a;
                $state = 0;
            }
            else {                           # space/avagraha/other
                if ($t !~ /\p{Space}/ and $t ne $self->{avagraha}
                        and $self->{strict} and !exists $self->{allow}->{$t}) {
                    carp("Invalid token $t read");
                }
                push @aksaras, $a, $t;
                $state = 0;
            }
        }
    }

    # Finish aksara currently under construction
    push @aksaras, $a if $state == 1 or $state == 2;

    return \@aksaras;
}

*l_to_aksara = \&l_to_aksaras; # alias

=item d_to_aksaras()

Converts a Devanagari string into L<Aksaras|Lingua::Deva::Aksara> and returns
a reference to an array of Aksaras.

    my $aksaras = $d->d_to_aksaras('बुद्धः');
    my $onset = $aksaras->[1]->onset();
    is_deeply( $onset, ['d', 'dh'], 'onset of second aksara' );
    done_testing();

Input tokens which can not be part of an Aksara pass through untouched.  Thus,
the resulting array can contain both C<Lingua::Deva::Aksara> objects and
separate tokens.

In I<strict> mode warnings for invalid tokens are output.

=cut

sub d_to_aksaras {
    my ($self, $input) = @_;

    my @chars = split //, $input;
    my @aksaras;
    my $a;
    my $state = 0;
    my ($DC, $DV, $DD, $DF) = ( $self->{DC}, $self->{DV},
                                $self->{DD}, $self->{DF} );

    # Aksarization is implemented with a state machine.
    # State 0: Not currently constructing an aksara, ready for any input
    # State 1: Consonant with inherent vowel, ready for vowel, Virama, final
    # State 2: Virama read, ready for consonant or end of aksara
    # State 3: Vowel read, ready for final or end of aksara
    # The inherent vowel needs to be taken into account specially

    for my $c (@chars) {
        if ($state == 0) {
            if (exists $DC->{$c}) {          # consonant: new aksara
                $a = Lingua::Deva::Aksara->new( onset => [ $DC->{$c} ] );
                $state = 1;
            }
            elsif (exists $DV->{$c}) {       # vowel: vowel-initial aksara
                $a = Lingua::Deva::Aksara->new( vowel => $DV->{$c} );
                $state = 3;
            }
            elsif ($c =~ /$Avagraha/) {      # Avagraha
                push @aksaras, $self->{avagraha};
            }
            else {                           # final or other: invalid
                if ($c !~ /\p{Space}/ and $self->{strict} and !exists $self->{allow}->{$c}) {
                    carp("Invalid character $c read");
                }
                push @aksaras, $c;
            }
        }
        elsif ($state == 1) {
            if ($c =~ /$Virama/) {           # Virama: consonant-final
                $state = 2;
            }
            elsif (exists $DD->{$c}) {       # diacritic: vowel nucleus
                $a->vowel( $DD->{$c} );
                $state = 3;
            }
            elsif (exists $DV->{$c}) {       # vowel: new vowel-initial aksara
                $a->vowel( $Inherent );
                push @aksaras, $a;
                $a = Lingua::Deva::Aksara->new( vowel => $DV->{$c} );
                $state = 3;
            }
            elsif (exists $DC->{$c}) {       # consonant: new aksara
                $a->vowel( $Inherent );
                push @aksaras, $a;
                $a = Lingua::Deva::Aksara->new( onset => [ $DC->{$c} ] );
            }
            elsif (exists $DF->{$c}) {       # final: end of aksara
                $a->vowel( $Inherent );
                $a->final( $DF->{$c} );
                push @aksaras, $a;
                $state = 0;
            }
            elsif ($c =~ /$Avagraha/) {      # Avagraha
                $a->vowel( $Inherent );
                push @aksaras, $a, $self->{avagraha};
                $state = 0;
            }
            else {                           # other: invalid
                $a->vowel( $Inherent );
                if ($c !~ /\p{Space}/ and $self->{strict} and !exists $self->{allow}->{$c}) {
                    carp("Invalid character $c read");
                }
                push @aksaras, $a, $c;
                $state = 0;
            }
        }
        elsif ($state == 2) {
            if (exists $DC->{$c}) {          # consonant: cluster
                push @{ $a->onset() }, $DC->{$c};
                $state = 1;
            }
            elsif (exists $DV->{$c}) {       # vowel: new vowel-initial aksara
                push @aksaras, $a;
                $a = Lingua::Deva::Aksara->new( vowel => $DV->{$c} );
                $state = 3;
            }
            elsif ($c =~ /$Avagraha/) {      # Avagraha
                push @aksaras, $a, $self->{avagraha};
                $state = 0;
            }
            else {                           # other: invalid
                if ($c !~ /\p{Space}/ and $self->{strict} and !exists $self->{allow}->{$c}) {
                    carp("Invalid character $c read");
                }
                push @aksaras, $a, $c;
                $state = 0;
            }
        }
        elsif ($state == 3) {                # final: end of aksara
            if (exists $DF->{$c}) {
                $a->final( $DF->{$c} );
                push @aksaras, $a;
                $state = 0;
            }
            elsif (exists $DC->{$c}) {       # consonant: new aksara
                push @aksaras, $a;
                $a = Lingua::Deva::Aksara->new( onset => [ $DC->{$c} ] );
                $state = 1;
            }
            elsif (exists $DV->{$c}) {       # vowel: new vowel-initial aksara
                push @aksaras, $a;
                $a = Lingua::Deva::Aksara->new( vowel => $DV->{$c} );
                $state = 3;
            }
            elsif ($c =~ /$Avagraha/) {      # Avagraha
                push @aksaras, $a, $self->{avagraha};
                $state = 0;
            }
            else {                           # other: invalid
                if ($c !~ /\p{Space}/ and $self->{strict} and !exists $self->{allow}->{$c}) {
                    carp("Invalid character $c read");
                }
                push @aksaras, $a, $c;
                $state = 0;
            }
        }
    }

    # Finish aksara currently under construction
    given ($state) {
        when (1)      { $a->vowel( $Inherent ); continue }
        when ([1..3]) { push @aksaras, $a }
    }

    return \@aksaras;
}

*d_to_aksara = \&d_to_aksaras; # alias

=item to_deva()

Converts a Latin string (or a reference to an array of
L<Aksaras|Lingua::Deva::Aksara>) into Devanagari and returns a Devanagari
string.

    say $d->to_deva('Kāmasūtra');

    # same as
    my $a = $d->l_to_aksaras('Kāmasūtra');
    say $d->to_deva($a);

Aksaras are assumed to be well-formed.

=cut

sub to_deva {
    my ($self, $input) = @_;

    # Input can be either a string (scalar) or an array reference
    my $aksaras = ref($input) eq '' ? $self->l_to_aksaras($input) : $input;

    my $s = '';
    my ($C, $V, $D, $F) = ($self->{C}, $self->{V}, $self->{D}, $self->{F});

    for my $a (@$aksaras) {
        if (ref($a) ne 'Lingua::Deva::Aksara') {
            $s .= $a eq $self->{avagraha} ? $Avagraha : $a;
        }
        else {
            if (defined $a->{onset}) {
                $s .= join($Virama, map { $C->{$_} } @{ $a->onset() });
                $s .= defined $a->vowel() ? $D->{$a->vowel()} : $Virama;
            }
            elsif (defined $a->vowel()) {
                $s .= $V->{$a->vowel()};
            }
            $s .= $F->{$a->final()} if defined $a->final();
        }
    }

    return $s;
}

=item to_latin()

Converts a Devanagari string (or a reference to an array of
L<Aksaras|Lingua::Deva::Aksara>) into Latin transliteration and returns a
Latin string.

Aksaras are assumed to be well-formed.

=cut

sub to_latin {
    my ($self, $input) = @_;

    # Input can be either a string (scalar) or an array reference
    my $aksaras = ref($input) eq '' ? $self->d_to_aksaras($input) : $input;

    my $s = '';
    for my $a (@$aksaras) {
        if (ref($a) eq 'Lingua::Deva::Aksara') {
            $s .= join '', @{ $a->onset() } if defined $a->onset();
            $s .= $a->vowel() if defined $a->vowel();
            $s .= $a->final() if defined $a->final();
        }
        else {
            $s .= $a;
        }
    }

    return $s;
}

=back

=cut

1;
__END__

=head1 EXAMPLES

The synopsis gives the simplest usage patterns.  Here are a few more.

Use default transliteration, but use "ring below" instead of "dot below" for
syllabic I<r>:

    my %v = %Lingua::Deva::Maps::Vowels;
    $v{"r\x{0325}"}         = delete $v{"r\x{0323}"};
    $v{"r\x{0325}\x{0304}"} = delete $v{"r\x{0323}\x{0304}"};
    my %d = %Lingua::Deva::Maps::Diacritics;
    $d{"r\x{0325}"}         = delete $d{"r\x{0323}"};
    $d{"r\x{0325}\x{0304}"} = delete $d{"r\x{0323}\x{0304}"};

    my $d = Lingua::Deva->new( V => \%v, D => \%d );
    say $d->to_deva('Kr̥ṣṇa');

Use the Aksara objects to produce simple statistics.

    # Count distinct rhymes in @aksaras
    my %rhymes;
    for my $a (grep { defined $_->get_rhyme() } @aksaras) {
        $rhymes{ join '', @{$a->get_rhyme()} }++;
    }

    # Print number of 'au' rhymes
    say $rhymes{'au'};

The following script reads Latin input from a file and writes the converted
output into another file.

    #!/usr/bin/env perl
    use v5.12.1;
    use strict;
    use warnings;
    use open ':encoding(UTF-8)';
    use Lingua::Deva;

    open my $in,  '<', 'in.txt'  or die;
    open my $out, '>', 'out.txt' or die;

    my $d = Lingua::Deva->new();
    while (my $line = <$in>) {
        print $out $d->to_deva($line);
    }

On a Unicode-capable terminal one-liners are also possible:

    echo 'Himālaya' | perl -MLingua::Deva -e 'print Lingua::Deva->new()->to_deva(<>);'

=head1 DEPENDENCIES

There are no requirements apart from standard Perl modules, but a modern,
Unicode-capable version of Perl >= 5.12 is required.

=head1 AUTHOR

glts <676c7473@gmail.com>

=head1 BUGS

Report bugs to the author or at L<https://github.com/glts/Lingua-Deva/issues>.

=head1 COPYRIGHT

This program is free software.  You may copy or redistribute it under the same
terms as Perl itself.

Copyright (c) 2012 by glts <676c7473@gmail.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.12.1 or, at your option,
any later version of Perl 5 you may have available.

=cut
