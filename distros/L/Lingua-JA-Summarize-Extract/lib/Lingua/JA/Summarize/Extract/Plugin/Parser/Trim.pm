package Lingua::JA::Summarize::Extract::Plugin::Parser::Trim;

use strict;
use base qw( Lingua::JA::Summarize::Extract::Plugin );
__PACKAGE__->mk_accessors(qw/ han_size kana_size latin_size /);

sub parse {
    my ($self) = @_;
    my $han_size = $self->han_size || 2;
    my $kana_size = $self->kana_size || 3;
    my $latin_size = $self->latin_size || 3;

    my $term_list = {};
    my $text = $self->text;
    while ($text =~ /(\p{Katakana}{$kana_size,}|\p{Han}{$han_size,}|\p{Latin}{$latin_size,})/g) {
        $term_list->{$1}++;
    }

    $term_list;
}

1;
__END__

=head1 NAME

Lingua::JA::Summarize::Extract::Plugin::Parser::Trim - a simple word parser

=head1 SYNOPSIS

    use strict;
    use warnings;
    use utf8;
    use Lingua::JA::Summarize::Extract;

    my $text = '';
    my $text = '日本語の文章を適当に書く。';
    my $summary = Lingua::JA::Summarize::Extract->extract($text, { plugins => [ 'Parser::Trim' ] });
    print "$summary";

=head1 DESCRIPTION

sentences are divided by the character kind.
you can change the small size of the string.

=head1 OPTIONS

=over 4

=item latin_size

latin character

=item kana_size

katakana character

=item han_size

kanji character

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
