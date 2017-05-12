package Lingua::LO::Romanize::Word;

use strict;
use utf8;

use Moose;
use MooseX::AttributeHelpers;

use Lingua::LO::Romanize::Types;
use Lingua::LO::Romanize::Word;

=encoding utf-8

=head1 NAME

Lingua::LO::Romanize::Word - Class for words, used by Lingua::LO::Romanize.

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

has 'word_str' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);


has 'syllables' => (
    metaclass   => 'Collection::Array',
    coerce      => 1,
    is          => 'ro',
    isa         => 'Lingua::LO::Romanize::Types::SyllableArr',
    init_arg    => undef,
    builder     => '_build_syllables',
    lazy        => 1,
    provides    => {
        elements    => 'all_syllables',
    },
);

has 'hyphen' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

# private builder method for syllables
# parsing out lao syllables, lao numbers and unrecognized characters

sub _build_syllables {
    my $self = shift;
    my $word = $self->word_str;
    my @syllables;
    
    while ($word) {
        if ($word =~ s/^[^ກ-ໝ]+//s) {
            push @syllables, $&;
        } elsif ($word =~ s/^[໐-໙]+//s) {
            push @syllables, $&;
        } elsif ($word =~ s/^ໆ//) {
            if (scalar(@syllables)) {
                my $prev_syllable = $syllables[-1];
                push @syllables, $prev_syllable;
            }
        } elsif ($word =~ s/^ຯ//) { #... or perhaps it should be together with a lao syllable
            push @syllables, $&;
        } elsif (my $syllable = _find_lao_syllable($word)) {
            $word =~ s/^$syllable// or $word =~ s/^.//; #just so that we don't loop forever
            push @syllables, $syllable;
        } else { #just so we don't loop forever
            $word =~ s/.//;
        }
    }
    \@syllables;
}

# private sub routine to find a lao syllable from a string and return the syllable
sub _find_lao_syllable {
    my $word = shift;
    my $syllable;
    return 
        unless $word =~ /^[ເ-ໄ]?([ກຂຄງຈສຊຍຽດຕຖທນບປຜຝພຟມຢຣລຼວຫອຮໜໝ])/;
    
    my $consonant = $1;

    if ($word =~ /^[ເ-ໄ]?$consonant[ເ-ໄ]?([ວຣລຼ])/) { # ວ, ຣ, or ລ (also ຼ) can be used in combination with another consonant
        my $extra = $1;
        unless ($extra eq 'ວ' && $word =~ /^$consonant(?:ວ)[^ະັາິີຶືຸູະັົອໍວຽຍຳ]/) {
            $consonant .= $extra;
        }
    }
    
    my $vowels = '';
    
    if ($consonant =~ /^ຫ$/ && $word =~ /^ຫ[ເ-ໄ]?([ຍນມ])/) {
        my $extra = $1;
        #fetch the surounding vowels and tone mark if any
        $word =~ /^$consonant([ເ-ໄ])?$extra([ະັາິີຶືຸູະັົອໍວຽຍຳ່້໊໋]*)/;
        $consonant .= $extra;
        $vowels .= $1 if $1;
        $vowels .= $2 if $2;
    } else {
        #fetch the surounding vowels and tone mark if any
        $word =~ /^([ເ-ໄ])?$consonant([ະັາິີຶືຸູະັົອໍວຽຍຳ່້໊໋]*)/;
        
        $vowels .= $1 if $1;
        $vowels .= $2 if $2;
    }
    
    my $tone;
    if ($vowels =~ s/([່-໋])//) {
        $tone = $1;
    }
    
    #find first vowel
    if ($vowels =~ /^(?:ໍາ|ຳ)/) { #'sala am' is always the end of a syllable
        my $found = $&;
        $syllable = $consonant;
        $found =~ s/^ໍ// and $syllable .= 'ໍ';
        $syllable .= $tone if defined ($tone);
        $syllable .= $found;
        return $syllable;
    } elsif ($vowels =~ /^(?:ເັຍະ|ເຶອະ|ເັຽະ)/ || $vowels =~ /^(?:ເາະ|ົວະ|ເັຽ|ເັຍ|ເືອ|ເິະ|ເົາ)/) {
        # trying to match the largest vowel first, then go to shorter (less characters)
        # doing 4 and 3 character vowels
        my $found = $&;
        $found =~ /^ເ/ and $syllable = 'ເ';
        $syllable .= $consonant;
        $found =~ /^ເ?([ົັືິຶ])/ and $syllable .= $1;
        $syllable .= $tone if defined ($tone);
        if ($found =~ /(ຍະ|ອະ|ຽະ|າະ|ວະ)$/ || $found =~/([ຽຍອະາ])$/) {
            $syllable .= $1;
        }
    } elsif ($vowels =~ /^(?:ເະ|ເັ|ແະ|ແັ|ໂະ|ັອ|ັວ|ົວ|ັຽ|ັຍ|ເິ|ເຍ|ເຽ|ເີ|ເື|ີວ|ິວ)/) {
        # doing 2 character vowels
        my $found = $&;
        $found =~ /^([ເແໂ])/ and $syllable .= $1;
        $syllable .= $consonant;
        $found =~ /^[ເແ]?([ັົິີື])/ and $syllable .= $1;
        $syllable .= $tone if defined ($tone);
        $found =~ /([ະອວຽຍ])$/ and $syllable .= $1;
    } elsif ($vowels =~ /^[ະັາິີຶືຸູເແົໂໍອວຽຍໄໃ]/) {
        # doing single character vowels
        my $found = $&;
        if ($found =~ /^([ເ-ໄ])$/) {
            $syllable = $1 . $consonant;
            $syllable .= $tone if defined ($tone);
        } elsif ($found =~ /^([ັິີຶືຸູົໍ])$/) {
            $syllable = $consonant;
            $syllable .= $found;
            $syllable .= $tone if defined ($tone);
        } else {
            $syllable = $consonant;
            $syllable .= $tone if defined ($tone);
            $syllable .= $found;
        }
    } else { #lonely constant, just return it (with possible tone)
        $syllable = $consonant;
        $syllable .= $tone if defined ($tone);
        return $syllable;
    }
    
    my $regexp = qr{$syllable([ກງຍຽດນບມຣວ]໌?)(?:([^່້໊໋ະັາິີຶືຸູະັົໍຳ])(.?)|$)};
    
    # checking for a possible closing consonant
    if ($word =~ /^$regexp/) {
        my $last_consonant = $1;
        my $possible_vowel = $2 if $2;
        my $continued_vowel = $3 if defined $3;
        if (!(defined $2) || # end of string
            $possible_vowel =~ /[^ຽວອຍ]/ || #for sure a consonant
            (defined $continued_vowel && $continued_vowel =~/[ະັາິີຶືຸູະັົອໍວຽຍຳ່້໊໋]/)) {#post vowels and tones
            $syllable .= $last_consonant;
        }
    }
    return $syllable;
}

=head1 SYNOPSIS

L<Lingua::LO::Romanize::Word> is used by L<Lingua::LO::Romanize> to divide a string to a collection of words. It is recommended to use L<Lingua::LO::Romanize> instead of this class directly (even if it is possible).

    use Lingua::LO::Romanize::Word;

    my $foo = Lingua::LO::Romanize::Word->new(word_str => 'ພາສາລາວ');

    my $bar = $foo->romanize;           # $bar will hold the string 'phasalao'
    $foo->hyphen(1);                    # set hyphenation between syllables
    $bar = $foo->romanize;              # $bar will hold the string 'pha-sa-lao'
    $bar = $foo->word_str;              # $bar will hold the string 'ພາສາລາວ'
    
    my $syllables_array_ref = $foo->all_syllables; # will return an array reference to all syllables;

For more information, please see L<Lingua::LO::Romanize>

=head1 METHODS

=head2 new

Creates a new L<Lingua::LO::Romanize::Word> object, a word_str is required.

=head2 hyphen

If set to 1 (TRUE), the syllables will be hyphenated when romanized is called. Default is 0 (FALSE), not hyphenated.

=head2 romanize

Romanize the 'word' and return the romanized string accourding to the BGN/PCGN standard.

=head2 word_str

Returns the word as the original string.

=head2 all_syllables

Returns an array reference to all L<Lingua::LO::Romanize::Syllable>

=cut

sub romanize {
    my $self = shift;
    
    my @romanized_arr;
    my $romanized_str;
    
    foreach my $syllable ($self->all_syllables) {
        push @romanized_arr, $syllable->romanize;
    }
    
    my $join_str = '';
    
    $join_str = '-' if $self->hyphen;
    
    $romanized_str = join $join_str, @romanized_arr;
    
    $romanized_str =~ s/^-//;
    
    $romanized_str =~ s/--/-/g if $self->hyphen;
    
    return $romanized_str;
}

=head1 AUTHOR

Joakim Lagerqvist, C<< <jokke at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lingua-lo-romanize at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-LO-Romanize>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<Lingua::LO::Romanize>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Joakim Lagerqvist, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1; # End of Lingua::LO::Romanize::Word
