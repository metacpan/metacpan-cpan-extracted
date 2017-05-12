package Lingua::JA::Summarize::Extract::Plugin::Sentence::Tiny;

use strict;
use base qw( Lingua::JA::Summarize::Extract::Plugin );

sub sentence {
    my $self = shift;
    my $text = $self->text;

    $text =~ s/[ \x{3000}]+/ /g;
    $text =~ s/[\x{3001}\x{3002}]/\n/g;
    $text =~ s/[\r\n]+/\n/g;

    my $i = 1;
    my @sentence = map { { line => $i++, text => $_ } } split /\n/, $text;
    \@sentence;
}

1;
