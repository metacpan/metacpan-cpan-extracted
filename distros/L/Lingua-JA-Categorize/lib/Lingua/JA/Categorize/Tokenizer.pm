package Lingua::JA::Categorize::Tokenizer;
use strict;
use warnings;
use Lingua::JA::TFIDF;
use base qw( Lingua::JA::Categorize::Base );

__PACKAGE__->mk_accessors($_) for qw( calc user_extention);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->calc( Lingua::JA::TFIDF->new( %{ $self->config } ) );
    return $self;
}

sub tokenize {
    my $self      = shift;
    my $text_ref  = shift;
    my $threshold = shift;

    my $text = $$text_ref;
    my $http_URL_regex
        = q{\b(?:https?|shttp)://(?:(?:[-_.!~*'()a-zA-Z0-9;:&=+$,]|%[0-9A-Fa-f}
        . q{][0-9A-Fa-f])*@)?(?:(?:[a-zA-Z0-9](?:[-a-zA-Z0-9]*[a-zA-Z0-9])?\.)}
        . q{*[a-zA-Z](?:[-a-zA-Z0-9]*[a-zA-Z0-9])?\.?|[0-9]+\.[0-9]+\.[0-9]+\.}
        . q{[0-9]+)(?::[0-9]*)?(?:/(?:[-_.!~*'()a-zA-Z0-9:@&=+$,]|%[0-9A-Fa-f]}
        . q{[0-9A-Fa-f])*(?:;(?:[-_.!~*'()a-zA-Z0-9:@&=+$,]|%[0-9A-Fa-f][0-9A-}
        . q{Fa-f])*)*(?:/(?:[-_.!~*'()a-zA-Z0-9:@&=+$,]|%[0-9A-Fa-f][0-9A-Fa-f}
        . q{])*(?:;(?:[-_.!~*'()a-zA-Z0-9:@&=+$,]|%[0-9A-Fa-f][0-9A-Fa-f])*)*)}
        . q{*)?(?:\?(?:[-_.!~*'()a-zA-Z0-9;/?:@&=+$,]|%[0-9A-Fa-f][0-9A-Fa-f])}
        . q{*)?(?:#(?:[-_.!~*'()a-zA-Z0-9;/?:@&=+$,]|%[0-9A-Fa-f][0-9A-Fa-f])*}
        . q{)?};
    $text =~ s/$http_URL_regex//g;

    my $tfidf_result = $self->calc->tfidf($text);

    my %user_extention;
    while ( my ( $keyword, $ref ) = each %{ $tfidf_result->{data} } ) {
        my @f = split( ",", $ref->{info} );
        if ( $f[6] eq 'ユーザ設定' ) {
            $user_extention{$keyword} = $f[9];
        }
    }
    $self->user_extention( \%user_extention );

    my $list = $tfidf_result->list($threshold);
    my %hash;
    for (@$list) {
        my ( $word, $score ) = each(%$_);
        $hash{$word} = $score;
    }
    return \%hash;
}

1;
__END__

=head1 NAME

Lingua::JA::Categorize::Tokenizer - Extract featured words from a document 

=head1 SYNOPSIS

  use Lingua::JA::Categorize::Tokenizer;

  my $tokenizer = Lingua::JA::Categorize::Tokenizer->new;
  my $word_set = $tokenizer->tokenize($text_ref);

=head1 DESCRIPTION

Lingua::JA::Categorize::Tokenizer is a featured word extractor.

It is just a warpper of Lingua::JA::TFIDF.

=head1 METHODS

=head2 new

=head2 tokenize

=head2 calc

=head1 AUTHOR

takeshi miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
