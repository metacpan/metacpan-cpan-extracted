package Lingua::JA::Romaji::Valid::Rule::ISO3602Strict;

use strict;
use warnings;
use base qw( Lingua::JA::Romaji::Valid::Rule );

__PACKAGE__->valid_consonants(qw(
  k s t n h m y r w g z d b p
  ky sy ty ny hy my ry gy zy dy by py
));

__PACKAGE__->should_delete(qw( wu ));
__PACKAGE__->should_add(qw( kwa gwa ));

__PACKAGE__->filters(qw(
  normalize_n_with_apostrophe
  normalize_syllabic_n
  normalize_geminate
));

1;

__END__

=head1 NAME

Lingua::JA::Romaji::Valid::Rule::ISO3602Strict

=head1 DESCRIPTION

So-called 'Nihon' romanization rules (ISO 3602 Strict).
This is rather historical and not used recently.

=head1 SEE ALSO

L<Lingua::JA::Romaji::Valid::Rule>, L<http://en.wikipedia.org/wiki/Nihon-shiki>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

