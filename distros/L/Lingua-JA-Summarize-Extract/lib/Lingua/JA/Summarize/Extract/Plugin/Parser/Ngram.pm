package Lingua::JA::Summarize::Extract::Plugin::Parser::Ngram;

use strict;
use base qw( Lingua::JA::Summarize::Extract::Plugin );
__PACKAGE__->mk_accessors(qw/ latin_gram kana_gram han_gram /);

sub parse {
    my ($self) = @_;
    my $latin_gram = $self->latin_gram || 2;
    my $kana_gram = $self->kana_gram || 3;
    my $han_gram = $self->han_gram || 2;

    my $term_list = {};
    $self->_gram($term_list, 'Latin', $latin_gram);
    $self->_gram($term_list, 'Katakana', $kana_gram);
    $self->_gram($term_list, 'Han', $han_gram);

    $term_list;
}

sub _gram {
    my($self, $list, $block, $gram) = @_;

    my $text = $self->text;
    while ($text =~ /(\p{$block}+)/g) {
        my $word = $1;
        my @part;
        for (my $i = 0;$i + $gram <= length $word;$i++) {
            push @part, substr $word, $i, $gram;
        }
        $list->{join ' ', @part}++ if @part;
    }
}

1;

__END__

=head1 NAME

Lingua::JA::Summarize::Extract::Plugin::Parser::Ngram - a word parser by N-gram

=head1 SYNOPSIS

    use strict;
    use warnings;
    use utf8;
    use Lingua::JA::Summarize::Extract;

    my $text = '';
    my $text = '日本語の文章を適当に書く。';
    my $summary = Lingua::JA::Summarize::Extract->extract($text); # default plugin
    print "$summary";

=head1 DESCRIPTION

parse dose the word by using N-gram.
the number of N can be changed by KATAKANA, KANJI, and the Latin character.

=head1 OPTIONS

=over 4

=item latin_gram

latin character

=item kana_gram

katakana character

=item han_gram

kanji character

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
