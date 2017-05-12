package Lingua::JA::Romaji::Valid::Rule::HepburnRevised;

use strict;
use warnings;
use base qw( Lingua::JA::Romaji::Valid::Rule );

__PACKAGE__->valid_consonants(qw(
  k s t n h m y r g z d b p
  ky sh ch ny hy my ry gy j by py
));

__PACKAGE__->should_delete(qw( si ti tu hu zi di du ));
__PACKAGE__->should_add(qw( shi chi tsu fu ye wa wo ji ));

__PACKAGE__->filters(qw(
  normalize_n_with_apostrophe
  normalize_syllabic_n
  normalize_geminate_tch
));

1;

__END__

=head1 NAME

Lingua::JA::Romaji::Valid::Rule::HepburnRevised

=head1 DESCRIPTION

Revised Hepburn romanization rules. Note that syllabic 'n'
is written 'n' even before labial consonants, and 'n' with an
apostrophe before vowels and 'y'.

=head1 SEE ALSO

L<Lingua::JA::Romaji::Valid::Rule>, L<http://en.wikipedia.org/wiki/Hepburn_romanization>, L<http://www.halcat.com/roomazi/doc/ansiz3911.html>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

