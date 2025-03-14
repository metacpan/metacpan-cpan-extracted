package Klonk 0.01;
use Klonk::pragma;

1

__END__

=head1 NAME

Klonk - ad-hoc, informally-specified, bug-ridden, slow implementation of half of a web framework

=head1 DESCRIPTION

A rudimentary web framework, mainly built for experimenting and learning. Do
not use for anything important. Features are incomplete. There are no tests.
The API may change arbitrarily in the future.

=begin :README

=head1 INSTALLATION

To download and install this module, use your favorite CPAN client, e.g.
L<C<cpan>|cpan>:

=for highlighter language=sh

    cpan Klonk

Or L<C<cpanm>|cpanm>:

    cpanm Klonk

To do it manually, run the following commands (after downloading and unpacking
the tarball):

    perl Makefile.PL
    make
    make test
    make install

=end :README

=head1 COPYRIGHT & LICENSE

Copyright 2025 Lukas Mai.

This module is free software: you can redistribute it and/or modify it under
the terms of the L<GNU General Public License|https://www.gnu.org/licenses/gpl-3.0.html>
as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

=head1 SEE ALSO

=over

=item *

L<Klonk::Env>

=item *

L<Klonk::Handle>

=item *

L<Klonk::Routes>

=item *

L<Klonk::pragma>

=back
