package Lingua::FreeLing3;

use strict;
use warnings;

use v5.10;

use Carp;
use Try::Tiny;
use Lingua::FreeLing3::ConfigData;
use Lingua::FreeLing3::Bindings;
use File::Spec::Functions 'catfile';

our $VERSION = "0.09";

BEGIN {
    Lingua::FreeLing3::Bindings::util::init_locale('default');
}

sub _validate_option {
    my ($value, $type, $default) = @_;
    if (defined($value) && exists($type->{$value})) {
        return $type->{$value};
    } else {
        carp "Option '$value' not valid." if defined $value;
        return $type->{$default};
    }
}

sub _validate_bool {
    my ($value, $default) = @_;
    if (defined($value)) {
        $value = 1 if $value =~ /^yes$/i;
        $value = 1 if $value =~ /^true$/i;
        return $value eq "1" ? 1 : 0;
    } else {
        return $default;
    }
}

sub _validate_integer {
    my ($value, $default) = @_;
    if (defined($value) && $value =~ /^\d+$/) {
        $value
    } else {
        carp "Setting weird value as integer." if defined $value;
        return $default;
    }
}

sub _validate_real {
    my ($value, $default) = @_;
    if (defined($value) && $value =~ /^\d+(?:\.\d+)?|\d*\.\d+$/) {
        $value
    } else {
        carp "Setting weird value as a real." if defined $value;
        return $default;
    }
}

sub _validate_prob {
    my ($value, $default) = @_;
    if (defined($value) && $value =~ /(\d+(?:\.\d+)? | \.\d+)/x && $1 >= 0 && $1 <= 1) {
        return $1
    } else {
        carp "Setting weird value as a probability value." if defined $value;
        return $default;
    }
}

sub _is_word_list {
    my $l = shift;
    return undef unless ref($l) eq "ARRAY";
    for my $w (@$l) {
        try {
            return 0 unless $w->isa("Lingua::FreeLing3::Bindings::word");
        } catch {
            return 0;
        }
    }
    return 1;
}

sub _is_sentence_list {
    my $l = shift;
    return undef unless ref($l) eq "ARRAY";
    for my $w (@$l) {
        my $fail = 0;
        try {
            $fail = 1 unless $w->isa("Lingua::FreeLing3::Sentence");
        } catch {
            $fail = 1;
        };
        return 0 if $fail
    }
    return 1;
}

1

__END__

=head1 NAME

Lingua::FreeLing3 - a library for language analysis with FreeLing3.

=head1 DESCRIPTION

This module is a Perl wrapper to FreeLing C++ library.
You can check the details on this library visiting its webpage
L<http://nlp.lsi.upc.edu/freeling/>.

The module is divided into different submodules, each with different
purposes.

=head1 SEE ALSO

L<Lingua::FreeLing3::Word>

L<Lingua::FreeLing3::Splitter>

L<Lingua::FreeLing3::Sentence>

L<Lingua::FreeLing3::Paragraph>

L<Lingua::FreeLing3::Document>

L<Lingua::FreeLing3::Tokenizer>

L<Lingua::FreeLing3::Word::Analysis>

L<Lingua::FreeLing3::HMMTagger>

L<Lingua::FreeLing3::MorphAnalyzer>

L<Lingua::FreeLing3::RelaxTagger>

L<Lingua::FreeLing3::ChartParser>

L<Lingua::FreeLing3::ParseTree>

L<Lingua::FreeLing3::DepTxala>

L<Lingua::FreeLing3::NEC>

=cut

