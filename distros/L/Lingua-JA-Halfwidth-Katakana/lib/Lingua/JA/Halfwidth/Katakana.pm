package Lingua::JA::Halfwidth::Katakana;

use 5.008_001;
use strict;
use warnings;
use Exporter qw/import/;

our $VERSION   = '0.90';
our @EXPORT    = qw(InHalfwidthKatakana);
our @EXPORT_OK = qw();

sub InHalfwidthKatakana { "FF65\tFF9F"; }

1;
__END__

=head1 NAME

Lingua::JA::Halfwidth::Katakana - provides HalfwidthKatakana block

=for test_synopsis
my ($text);

=head1 SYNOPSIS

  use Lingua::JA::Halfwidth::Katakana;
  use utf8;

  if ($text =~ /\p{InHalfwidthKatakana}/)
  {
      print '$text contains HalfwidthKatakana';
  }

=head1 DESCRIPTION

Lingua::JA::Halfwidth::Katakana provides HalfwidthKatakana block.

The following chars are not contained:

  HALFWIDTH IDEOGRAPHIC FULL STOP
  HALFWIDTH LEFT CORNER BRACKET
  HALFWIDTH RIGHT CORNER BRACKET
  HALFWIDTH IDEOGRAPHIC COMMA

=head1 AUTHOR

pawa E<lt>pawapawa@cpan.orgE<gt>

=head1 SEE ALSO

L<Lingua::JA::Halfwidth>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
