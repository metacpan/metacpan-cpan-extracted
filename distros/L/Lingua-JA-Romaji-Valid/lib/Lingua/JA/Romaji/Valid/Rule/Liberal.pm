package Lingua::JA::Romaji::Valid::Rule::Liberal;

use strict;
use warnings;
use base qw( Lingua::JA::Romaji::Valid::Rule );

__PACKAGE__->valid_consonants(qw(
  k s t n h m y r g z d b p
  ky sy ty ny hy my ry gy zy by py
  sh ch j jy dy l ly f v ts
));

__PACKAGE__->should_delete(qw());
__PACKAGE__->should_add(qw( wa wo shi chi tsu ji je ye fyu vyu ));

__PACKAGE__->filters(qw(
  normalize_n_with_apostrophe
  normalize_n_with_hyphen
  normalize_long_vowel_with_h
  normalize_long_vowel_with_symbols
  normalize_syllabic_nn
  normalize_syllabic_n
  normalize_syllabic_m
  normalize_geminate_cch
));

1;

__END__

=head1 NAME

Lingua::JA::Romaji::Valid::Rule::Liberal

=head1 DESCRIPTION

This allows several common but wrong (or vulgar) romanization
such as 'jya' and 'lyo'. 

=head1 SEE ALSO

L<Lingua::JA::Romaji::Valid::Rule>, L<http://en.wikipedia.org/wiki/Romaji>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

