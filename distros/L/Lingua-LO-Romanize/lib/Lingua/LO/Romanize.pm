package Lingua::LO::Romanize;

use strict;
use utf8;

use Moose;
use MooseX::AttributeHelpers;
use MooseX::Params::Validate;

use Lingua::LO::Romanize::Types;
use Lingua::LO::Romanize::Word;

=encoding utf-8

=head1 NAME

Lingua::LO::Romanize - Romanization of Lao language

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

has 'text' => (
    metaclass   => 'Collection::Array',
    is          => 'rw',
    isa         => 'Lingua::LO::Romanize::Types::WordArr',
    coerce      => 1,
    required    => 1,
    provides    => {
        elements    => 'all_words',
    },
);

=head1 SYNOPSIS

This module romanizes Lao text using the BGN/PCGN standard from 1966 (with some modifications, see below).

    use Lingua::LO::Romanize;

    my $foo = Lingua::LO::Romanize->new(text => 'ພາສາລາວ');
    
    my $bar = $foo->romanize;           # $bar will hold the string 'phasalao'
    $bar = $foo->romanize(hyphen => 1); # $bar will hold the string 'pha-sa-lao'

=head1 DESCRIPTION

L<Lingua::LO::Romanize> romanizes lao text using the BGN/PCGN standard from 1966 (also know as the 'French style') with some modifications for post-revolutionary spellings (spellings introduced from 1975). One such modification is that Lao words has to be spelled out. For example, 'ສະຫວັນນະເຂດ' will be romanized correctly into 'savannakhét' while the older spelling 'ສວັນນະເຂດ' will not be romanized correctly due to lack of characters.

Furthermore, 'ຯ' will be romanized to '...', Lao numbers will be 'romanized' to Arabic numbers (0,1,2,3 etc.), and 'ໆ' will repeat the previous syllable. Se below for more romanization rules.

Note that all charcters are treated as UTF-8.

=head2 Romanization Rules

Consonants and vowels are generally romanized accourding to the following rules:

=head3 Consonants

=over

=item ກ 

initial and final position 'k'

=item ຂ

initial position 'kh'

=item ຄ

initial position 'kh'

=item ງ

initial and final position 'ng'

=item ຈ

initial postion 'ch'

=item ສ

initial position 's'

=item ຊ

intial position 'x'

=item ຍ,ຽ

initial postion 'gn', final postion 'y'. Could also be a vowel. ຽ is not used in initial position

=item ດ

intitial postion 'd', final postion 't'

=item ຕ

initial postion 't'

=item ຖ

initial postition 'th'

=item ທ

initial postion 'th'

=item ນ 

initial and final position 'n'

=item ບ

intitial position 'b', final position 'p'

=item ປ

initial postion 'p'

=item ຜ

initial postion 'ph'

=item ຝ 

initial postion 'f'

=item ພ

initial postion 'ph'

=item ຟ

initial positon 'f'

=item ມ

initial and final position 'm'

=item ຢ

initial postion 'y'

=item ຣ,ຣ໌

initial and final postion 'r'. ຣ໌ is rarely used and only in final position of words for example 'ເບີຣ໌'

=item ລ,◌ຼ

initial postion 'l'

=item ວ

initial postion 'v' or 'o', final postion 'o','iou', or 'oua'. ວ can also be a vowel depending on it's position. The character ວ at the beginning of a syllable should be romanized v. As the second character of a combination in initial position, ວ should be romanized o. The character ວ at the end of a syllable should be romanized in the following manner.  The syllables  ◌ິ ວ and ◌ີ ວ should be romanized iou. The syllable ◌ົ ວ (treated as a vowel) should be romanized oua. Otherwise, at the end of a syllable, ວ should be  romanized o.

=item ຫ 

initial postion 'h'. At the beginning of a syllable, the character ຫ unaccompanied by a vowel or tone mark and  occurring immediately before ຍ gn, ນ n, ມ m, ຣ r, ລ l, or ວ v should generally not be romanized. Note that the character combinations ຫນ, ຫມ and ຫລ are often written in abbreviated form:  ໜ n, ໝ m, and  ຫຼ l, respectively. ແຫນ is romanized to hèn and ແໜ romanized to nè.

=item ອ

initial postion '-'. ອ can also be a vowel. At the beginning of a word, ອ should not be romanized. At the beginning of a syllable within a word, ອ should be romanized by a hyphen.

=item ຮ

initial positon 'h'

=back


=head3 Vowels

'◌' represent any consonant character.

=over

=item ◌ະ,◌ັ,◌າ,◌າ

a

=item ◌ິ,◌ິ,◌ີ,◌ີ

i

=item ◌ຶ,◌ຶ,◌ື,◌ື

u

=item ◌ຸ,◌ຸ,◌ູ,◌ູ

ou

=item ເ◌ະ,ເ◌ັ,ເ◌,ເ◌

é

=item ແ◌ະ,ແ◌ັ,ແ◌,ແ◌

è

=item ໂ◌ະ,◌ົ,ໂ◌,ໂ◌

ô

=item ເ◌າະ,◌ັອ,◌ໍ,◌ອ

o

=item ◌ົວະ,◌ັວ,◌ົວ,◌ວ

oua

=item ເ◌ ັຽະ,◌ັຽ,ເ◌ັຽ,◌ຽ

ia

=item ເ◌ຶອະ,ເ◌ຶອ,ເ◌ືອ,ເ◌ືອ

ua

=item ເ◌ິະ,ເ◌ິ,ເ◌ີ,ເ◌ື

eu

=item ໄ◌,ໃ◌

ai

=item ເ◌ົາ,

ao

=item ◌ຳ

am

=back

=head3 Tones

Tonal marks (່້໊໋) are not romanized. 

=head3 Numbers

The Lao numbers ໐, ໑, ໒, ໓, ໔, ໕, ໖, ໗, ໘, and ໙ are romanized to the Arabic numbers 0, 1, 2, 3, 4, 5, 6, 7, 8, and 9.

=head3 Special characters

ໆ is romanized to repeat the previous syllable, for example ແຊວໆ → xèoxèo.

ຯ (the Lao ellipsis) is 'romanized' to '...'


=head1 METHODS

=head2 new

Creates a new object, a Lao text string is required
    
    my $foo = Lingua::LO::Romanize->new(text => 'ພາສາລາວ');

=head2 text

If a string is passed as argument, this string will be used to romanized from.

    $foo->text('ເບຍ');

If no arguments as passed, an array reference of L<Lingua::LO::Romanize::Word> from the current text will be returned.

=head2 all_words

Will return an array reference of L<Lingua::LO::Romanize::Word> from the current text.

=head2 romanize

Returns the current text as a romanized string. If hyphen is true, the syllables will be hyphenated.

    my $string = $foo->romanize;
    
    my $string_with_hyphen = $foo->romanize(hyphen => 1);

=cut

sub romanize {
    my $self = shift;
    my ( $hyphen ) = validated_list( \@_,
              hyphen   => { isa => 'Bool', optional => 1 });
    
    my @romanized_arr;
    
    foreach my $word ($self->all_words) {
        $word->hyphen(1) if $hyphen;
        push @romanized_arr, $word->romanize;
    }
    return join '', @romanized_arr;
}

=head2 syllable_array

Returns the current text as an array of hash references. The key 'lao' represents the original syllable and 'romanized' the romanized syllable.

    foreach my $syllable ($foo->syllable_array) {
        my $lao_syllable = $syllable->{lao};
        my $romanized_syllable = $syllable->{romanized};
        ...
    }

=cut

sub syllable_array {
    my $self = shift;
    
    my @syllable_array;
    
    foreach my $word ($self->all_words) {
        foreach my $syllable ($word->all_syllables) {
            my $romanized_syll = $syllable->romanize;
            $romanized_syll =~ s/^-//;
            push @syllable_array, { lao => $syllable->syllable_str, romanized => $romanized_syll };
        }
    }
    return @syllable_array;
}

=head1 AUTHOR

Joakim Lagerqvist, C<< <jokke at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lingua-lo-romanize at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-LO-Romanize>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::LO::Romanize


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-LO-Romanize>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-LO-Romanize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-LO-Romanize>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-LO-Romanize/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Joakim Lagerqvist, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1; # End of Lingua::LO::Romanize
