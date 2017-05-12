package Lingua::LO::Romanize::Syllable;

use strict;
use utf8;

use Moose;

use constant{
    BGN_PCGN => {
        #consonants
        'ກ'   => 'k',
        'ຂ'   => 'kh',
        'ຄ'   => 'kh',
        'ງ'   => 'ng',
        'ຈ'   => 'ch',
        'ສ'   => 's',
        'ຊ'   => 'x',
        'ຕ'   => 't',
        'ຖ'   => 'th',
        'ທ'   => 'th',
        'ນ'   => 'n',
        'ໜ'   => 'n',
        'ປ'   => 'p',
        'ຜ'   => 'ph',
        'ຝ'   => 'f',
        'ພ'   => 'ph',
        'ຟ'   => 'f',
        'ມ'   => 'm',
        'ໝ'   => 'm',
        'ຢ'   => 'y',
        'ຣ'   => 'r',
        'ຣ໌'  => 'r',
        'ລ'   => 'l',
        'ຼ'   => 'l',
        'ຫ'   => 'h',
        'ຮ'   => 'h',
        #ຍ, ຽ, ດ, ບ, ວ, ອ special cases
        #vowels
        'ະ'       => 'a',
        'ັ'       => 'a',
        'າ'       => 'a',
        'ິ'       => 'i',
        'ີ'       => 'i',
        'ຶ'       => 'u',
        'ື'       => 'u',
        'ຸ'       => 'ou',
        'ູ'       => 'ou',
        'ເະ'      => 'é',
        'ເັ'      => 'é',
        'ເ'       => 'é',
        'ແະ'      => 'è',
        'ແັ'      => 'è',
        'ແ'       => 'è',
        'ໂະ'      => 'ô',
        'ົ'       => 'ô',
        'ໂ'       => 'ô',
        'ເາະ'     => 'o',
        'ັອ'      => 'o',
        'ໍ'       => 'o',
        'ອ'       => 'o',
        'ເັຽະ'    => 'ia',
        'ັຽ'      => 'ia',
        'ເັຽ'     => 'ia',
        'ຽ'       => 'ia',
        'ເັຍະ'    => 'ia', #?
        'ັຍ'      => 'ia', #?
        'ເັຍ'     => 'ia', #?
        'ຍ'       => 'ia', #?
        'ເຍ'      => 'ia',
        'ເຶອະ'    => 'ua',
        'ເຶອ'     => 'ua',
        'ເືອ'     => 'ua',
        'ເິະ'     => 'eu',
        'ເິ'      => 'eu',
        'ເີ'      => 'eu',
        'ເື'      => 'eu',
        'ໄ'       => 'ai',
        'ໃ'       => 'ai',
        'ເົາ'     => 'ao',
        'ຳ'       => 'am', #not needed?
        'ໍາ'      => 'am', #not needed?
        'ິວ'      => 'iou',
        'ີວ'      => 'iou',
        # special case: ົວະ, ັວ, ົວ, ວ
    },
};

=encoding utf-8

=head1 NAME

Lingua::LO::Romanize::Syllable - Class for syllables, used by Lingua::LO::Romanize::Word.

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

has 'syllable_str' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=head1 SYNOPSIS

L<Lingua::LO::Romanize::Syllable> is used by L<Lingua::LO::Romanize::Word> and L<Lingua::LO::Romanize> to syllables of words. It is recommended to use L<Lingua::LO::Romanize> instead of this class directly (even if it is possible).

    use Lingua::LO::Romanize::Syllable;

    my $foo = Lingua::LO::Romanize::Syllable->new(syllable_str => 'ລາວ');

    my $bar = $foo->romanize;           # $bar will hold the string 'lao'
    $bar = $foo->romanize;              # $bar will hold the string 'lao'
    $bar = $foo->syllable_str;              # $bar will hold the string 'ລາວ'
    
For more information, please see L<Lingua::LO::Romanize>

=head1 METHODS

=head2 new

Creates a new object, syllable_str is required.

=head2 romanize

Romanize a syllable accourding to the BGN/PCGN standard.

Please see L<Lingua::LO::Romanize> for more information.

=head2 syllable_str

Returns the original syllable in Lao characters.

=head2 BGN_PCGN

A constant hash reference for romanization mapping accourding to BGN/PCGN.

=cut

sub romanize {
    my $self = shift;
    my $syllable = $self->syllable_str;
    my $romanized_str;
    
    $syllable =~ s/[່-໋]//;
    
    return '...' if $syllable =~ /^ຯ$/;
    
    if ($syllable =~ /^[໐-໙]+$/) {
        foreach (split //, $syllable) {
            $romanized_str .= (ord($_) - 3792) if /^[໐-໙]$/;
        }
        return $romanized_str;
    }
    
    $syllable =~ s/^ຫ([ເ-ໄ]?[ນມ])/$1/;
    
    return $syllable
        unless $syllable =~ /^[ເ-ໄ]?([ກຂຄງຈສຊຍຽດຕຖທນບປຜຝພຟມຢຣລຼວຫອຮໜໝ])/;
    
    my $consonant = $1;
    
    #ຍ, ຽ, ດ, ບ, ວ, ອ
    if ($consonant =~ /^[ຍຽ]$/) {
        $romanized_str = 'gn';
    } elsif ($consonant =~ /^ດ$/) {
        $romanized_str = 'd';
    } elsif ($consonant =~ /^ບ$/) {
        $romanized_str = 'b';
    } elsif ($consonant =~ /^ວ$/) {
        $romanized_str = 'v';
    } elsif ($consonant =~ /^ອ$/) {
        $romanized_str = '-';
    } elsif (defined (BGN_PCGN->{$consonant})) {
        $romanized_str = BGN_PCGN->{$consonant};
    }
    
    if ($consonant =~ /^ຫ$/ && $syllable =~ /^[ເ-ໄ]?ຫ([ຍຣລຼວ])/) {
        my $sec_consonant = $1;
        $consonant .= $1;
        if ($sec_consonant =~ /ຍ/) {
            $romanized_str = 'gn';
        } elsif ($sec_consonant =~ /ວ/) {
            $romanized_str = 'v';
        } elsif (defined (BGN_PCGN->{$sec_consonant})) {
            $romanized_str = BGN_PCGN->{$sec_consonant};
        }
    } elsif ($syllable =~ /^[ເ-ໄ]?$consonant(ວ)./) {
        $consonant .= $1;
        $romanized_str .= 'o';
    } 
    elsif ($syllable =~ /^[ເ-ໄ]?$consonant([ຣລຼ])/) { # ວ, ຣ, or ລ (also ຼ) can be used in combination with another consonant
        my $sec_consonant = $1;
        $consonant .= $sec_consonant;
        if (defined (BGN_PCGN->{$sec_consonant})) {
            $romanized_str .= BGN_PCGN->{$sec_consonant};
        }
    }
    
    #vowel
    my $vowel = '';
    my $final_consonant;
    if ($syllable =~ /^([ເ-ໄ]?)$consonant/) {
        $vowel .= $1 if $1;
    }
    if ($syllable =~ /^[ເ-ໄ]?$consonant([ະັາິີຶືຸູະັົອໍວຽຍຳ]*)/) {
        $vowel .= $1 if $1;
    }
    if ($syllable =~ /^[ເ-ໄ]?$consonant(?:[ະັາິີຶືຸູະັົອໍວຽຍຳ]*)([ກງຍຽດນບມຣວ]|ຣ໌)?$/) {
        $final_consonant = $1 if $1;
    }
        
    return $romanized_str . 'am' if ($vowel =~ /^(?:ໍາ|ຳ)/);
    
    if (defined (BGN_PCGN->{$vowel})) {
        $romanized_str .= BGN_PCGN->{$vowel};
    } elsif ($vowel =~ /^ົວະ$/ || $vowel =~ /^ັວ$/ || $vowel =~ /^ົວ$/ || $vowel =~ /^ວ$/) {
        $romanized_str .= 'oua';
    } elsif ($vowel =~ s/([ອວຽຍ])$// && defined (BGN_PCGN->{$vowel})) {
        $final_consonant = $1;
        $romanized_str .= BGN_PCGN->{$vowel};
    } 
    
    # last character
    if ($final_consonant) {
        if ($final_consonant =~ /ວ/) {
            $romanized_str .= 'o';
        } elsif ($final_consonant =~ /ດ/) {
            $romanized_str .= 't';
        } elsif ($final_consonant =~ /ບ/) {
            $romanized_str .= 'p';
        } elsif ($final_consonant =~ /[ຍຽ]/) {
            $romanized_str .= 'y';
        } elsif (defined (BGN_PCGN->{$final_consonant})) {
            $romanized_str .= BGN_PCGN->{$final_consonant};
        }
    }
    
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

1; # End of Lingua::LO::Romanize::Syllable
