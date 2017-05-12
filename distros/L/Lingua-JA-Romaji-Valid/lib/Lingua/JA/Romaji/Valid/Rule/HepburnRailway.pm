package Lingua::JA::Romaji::Valid::Rule::HepburnRailway;

use strict;
use warnings;
use base qw( Lingua::JA::Romaji::Valid::Rule );

__PACKAGE__->valid_consonants(qw(
  k s t n h m y r g z d b p
  ky sh ch ny hy my ry gy j by py
));

__PACKAGE__->should_delete(qw( si ti tu zi di du ));
__PACKAGE__->should_add(qw( shi chi tsu wa ji ));

__PACKAGE__->filters(qw(
  normalize_n_with_hyphen
  normalize_syllabic_n_m
  normalize_geminate_tch
));

1;

__END__

=head1 NAME

Lingua::JA::Romaji::Valid::Rule::HepburnRailway

=head1 DESCRIPTION

Variation of Hepburn romanization rules. Note that syllabic 'n'
is written 'm' before other labial consonants ('b', 'm', 'p'),
and 'n' with an hyphen before vowels and 'y'. Though this is
one of the revised Hepburn variations, this uses 'hu', instead
of 'fu'.

=head1 SEE ALSO

L<Lingua::JA::Romaji::Valid::Rule>, L<http://en.wikipedia.org/wiki/Hepburn_romanization>, L<http://www.halcat.com/roomazi/doc/TetudouKeiziKitei.html>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

