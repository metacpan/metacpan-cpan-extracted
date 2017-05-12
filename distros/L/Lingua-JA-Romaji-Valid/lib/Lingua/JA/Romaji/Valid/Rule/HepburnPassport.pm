package Lingua::JA::Romaji::Valid::Rule::HepburnPassport;

use strict;
use warnings;
use base qw( Lingua::JA::Romaji::Valid::Rule );

__PACKAGE__->valid_consonants(qw(
  k s t n h m y r g z d b p
  ky sh ch ny hy my ry gy j by py
));

__PACKAGE__->should_delete(qw( si ti tu hu zi di du ));
__PACKAGE__->should_add(qw( shi chi tsu fu wa ji ));

__PACKAGE__->filters(qw(
  normalize_oh
  normalize_syllabic_n_m
  normalize_geminate_tch
));

1;

__END__

=head1 NAME

Lingua::JA::Romaji::Valid::Rule::HepburnPassport

=head1 DESCRIPTION

Variant of Hepburn romanization rules. Note that syllabic 'n'
is written 'm' before other labial consonants ('b', 'm', 'p').
Also this allows 'oh' to render long 'o' (since Apr. 1, 2000).

Macrons are simply ignored.

=head1 SEE ALSO

L<Lingua::JA::Romaji::Valid::Rule>, L<http://en.wikipedia.org/wiki/Hepburn_romanization>, L<http://www.seikatubunka.metro.tokyo.jp/hebon/index.html>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

