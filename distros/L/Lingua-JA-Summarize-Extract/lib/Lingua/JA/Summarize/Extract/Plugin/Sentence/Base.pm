package Lingua::JA::Summarize::Extract::Plugin::Sentence::Base;

use strict;
use base qw( Lingua::JA::Summarize::Extract::Plugin );

sub sentence {
    my $self = shift;
    my $text = $self->text;

    $text =~ s/[ \x{3000}]+/ /g;
    $text =~ s/\x{3002}/\x{3002}\n/g;
    $text =~ s/[\r\n]+/\n/g;

    my $i = 1;
    my @sentence = map { { line => $i++, text => $_ } } split /\n/, $text;
    \@sentence;
}

1;
__END__

=head1 NAME

Lingua::JA::Summarize::Extract::Plugin::Parser::Trim - a simple line parser

=head1 DESCRIPTION

。で文章を区切ります。

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
