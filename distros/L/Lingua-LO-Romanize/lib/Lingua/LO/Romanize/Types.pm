package Lingua::LO::Romanize::Types;

use strict;
use utf8;

use Moose::Util::TypeConstraints;

use Lingua::LO::Romanize::Syllable;

=encoding utf-8

=head1 NAME

Lingua::LO::Romanize::Types - Types used in Lingua::LO::Romanize

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head2 Lingua::LO::Romanize::Types::WordArr

An array reference of Word

=cut

subtype 'Lingua::LO::Romanize::Types::WordArr'
      => as 'ArrayRef[Lingua::LO::Romanize::Word]';

coerce 'Lingua::LO::Romanize::Types::WordArr'
    => from 'Str'
    => via {
        my $text_str = $_;
        my $words;
        foreach (split /\b/s, $text_str) {
            push @$words, Lingua::LO::Romanize::Word->new(word_str => $_);
        }
        $words;
    };

=head2 Lingua::LO::Romanize::Types::SyllableArr

An array reference of Syllable

=cut

subtype 'Lingua::LO::Romanize::Types::SyllableArr'
      => as 'ArrayRef[Lingua::LO::Romanize::Syllable]';

coerce 'Lingua::LO::Romanize::Types::SyllableArr'
    => from 'ArrayRef[Str]'
    => via {
        my $arr_ref = $_;
        my $syllables;
        foreach (@$arr_ref) {
            push @$syllables, Lingua::LO::Romanize::Syllable->new(syllable_str => $_);
        }
        $syllables;
    };

no Moose::Util::TypeConstraints;
1;
