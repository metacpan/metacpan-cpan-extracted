package Lingua::JA::Gal;
use strict;
use warnings;
use utf8;
our $VERSION = '0.03';

use Exporter 'import';
use File::ShareDir 'dist_file';
use Unicode::Japanese;

our @EXPORT_OK = qw/gal/;

our $Lexicon ||= do {
    my $file = dist_file('Lingua-JA-Gal', 'lexicon.pl');
    do $file;
};

sub gal {
    my $class   = shift if $_[0] eq __PACKAGE__; ## no critic
    my $text    = shift || "";
    my $options = shift || {};
    
    $options->{rate} = 100 if not defined $options->{rate};
     
    $text =~ s{(.)}{ _gal_char($1, $options) }ge;
    $text;
}

sub _gal_char {
    my ($char, $options) = @_;
     
    my $suggestions = do {
        my $normalized = Unicode::Japanese->new($char)->z2h->h2zKana->getu;
        $Lexicon->{ $normalized } || [];
    };
     
    if (my $callback = $options->{callback}) {
        return $callback->($char, $suggestions, $options);
    }

    if (@$suggestions && int(rand 100) < $options->{rate}) {
        return $suggestions->[ int(rand @$suggestions) ];
    } else {
        return $char;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Lingua::JA::Gal - "ギャル文字" converter

=head1 SYNOPSIS

  use utf8;
  use Lingua::JA::Gal;

  $text = Lingua::JA::Gal->gal("こんにちは"); # => "⊇ｗ丨ﾆちﾚ￡"

=head1 DESCRIPTION

"ギャル文字" (gal's alphabet) is a Japanese writing style
that was popular with Japanese teenage girls in the early 2000s.

L<https://ja.wikipedia.org/wiki/%E3%82%AE%E3%83%A3%E3%83%AB%E6%96%87%E5%AD%97>

=head1 METHOD

=head2 gal( $text, [ \%options ] )

  Lingua::JA::Gal->gal("ギャルもじ"); # => "(ｷ〃ャlﾚ€Ｕ〃"

=head3 OPTIONS

=over 4

=item C<rate>

for converting rate. default is 100 (full).

  Lingua::JA::Gal->gal($text, { rate => 100 }); # full(default)
  Lingua::JA::Gal->gal($text, { rate =>  50 }); # half
  Lingua::JA::Gal->gal($text, { rate =>   0 }); # nothing

=item C<callback>

if you want to do your own gal way.

  Lingua::JA::Gal->gal($text, { callback => sub {
      my ($char, $suggestions, $options) = @_;
       
      # 漢字のみ変換する
      if ($char =~ /p{Han}/) {
          return $suggestions->[ int(rand @$suggestions) ];
      } else {
          return $char;
      }
  });

=back

=head1 EXPORT

no exports by default.

=head2 gal

  use Lingua::JA::Gal qw/gal/;

  print gal("...");

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=for stopwords 2000s

=cut
