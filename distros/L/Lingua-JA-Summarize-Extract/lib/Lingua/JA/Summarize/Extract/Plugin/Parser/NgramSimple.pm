package Lingua::JA::Summarize::Extract::Plugin::Parser::NgramSimple;

use strict;
use base qw( Lingua::JA::Summarize::Extract::Plugin );
__PACKAGE__->mk_accessors(qw/ gram /);

sub parse {
    my ($self) = @_;
    my $gram = $self->gram || 2;

    my $term_list = {};
    my $text = $self->text;
    while ($text =~ /([^\p{Common}]+)/g) {
        my $word = $1;
        my @part;
        for (my $i = 0;$i + $gram <= length $word;$i++) {
            push @part, substr $word, $i, $gram;
        }
        $term_list->{join ' ', @part}++ if @part;
    }
    $term_list;
}

1;

__END__

=head1 NAME

Lingua::JA::Summarize::Extract::Plugin::Parser::NgramSimple - a word parser by N-gram Simply

=head1 SYNOPSIS

    use strict;
    use warnings;
    use utf8;
    use Lingua::JA::Summarize::Extract;

    my $text = '';
    my $text = '日本語の文章を適当に書く。';
    my $summary = Lingua::JA::Summarize::Extract->extract($text, { plugins => [ 'ParserNgramSimple' ], gram => 2 });
    print "$summary";

=head1 DESCRIPTION

parse dose the word by using N-gram.
all the character kinds are similarly treated.
the number of N can be changed.

=head1 OPTIONS

=over 4

=item gram

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
