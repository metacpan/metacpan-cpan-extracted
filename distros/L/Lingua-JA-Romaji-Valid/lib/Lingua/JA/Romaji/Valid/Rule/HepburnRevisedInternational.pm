package Lingua::JA::Romaji::Valid::Rule::HepburnRevisedInternational;

use strict;
use warnings;
use base qw( Lingua::JA::Romaji::Valid::Rule );

__PACKAGE__->valid_consonants(qw(
  k s t n h m y r w g z d b p
  ky sh ch ny hy my ry gy j by py
  f v ts fy vy
));

__PACKAGE__->should_delete(qw( si hu zi wu ));
__PACKAGE__->should_add(qw(
  shi chi ye ji
  tsi tsyu tyu dyu 
  ye je kye she che tse nye hye fye mye rye vye bye pye
  kwa kwi kwe kwo gwa gwi gwe gwo
));

__PACKAGE__->filters(qw(
  normalize_n_with_apostrophe
  normalize_syllabic_n
  normalize_geminate_tch
));

1;

__END__

=head1 NAME

Lingua::JA::Romaji::Valid::Rule::HepburnRevisedInternational

=head1 DESCRIPTION

Revised Hepburn romanization rules with international
words support. Note that it may be too loose to detect
generic Japanese words.

=head1 SEE ALSO

L<Lingua::JA::Romaji::Valid::Rule>, L<http://en.wikipedia.org/wiki/Hepburn_romanization>, L<http://www.halcat.com/roomazi/doc/ansiz3911.html>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

