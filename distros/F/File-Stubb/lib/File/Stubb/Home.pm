package File::Stubb::Home;
use 5.016;
our $VERSION = '0.03';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(home);

my $HOME = $^O eq 'Win32' ? $ENV{ USERPROFILE } : (<~>)[0];
undef $HOME if defined $HOME and ! -d $HOME;

sub home { $HOME // die "Could not determine home directory\n" }

1;

=head1 NAME

File::Stubb::Home - Find user's home directory

=head1 SYNOPSIS

  use EBook::Stub::Home;

  my $home = home;

=head1 DESCRIPTION

B<File::Stubb::Home> is a module that provides the C<home()> subroutine,
which returns the running user's home directory. This is developer
documentation, for L<stubb> user documentation you should consult its
manual.

=head1 SUBROUTINES

All subroutines are exported automatically.

=over 4

=item $home = home()

Returns the running user's home directory. If the home directory cannot be
found, C<home()> C<die>s.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/stubb>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<stubb>

=cut

# vim: expandtab shiftwidth=4
