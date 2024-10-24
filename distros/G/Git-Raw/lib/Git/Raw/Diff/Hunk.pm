package Git::Raw::Diff::Hunk;
$Git::Raw::Diff::Hunk::VERSION = '0.90';
use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Diff::Hunk - Git diff hunk class

=head1 VERSION

version 0.90

=head1 DESCRIPTION

A L<Git::Raw::Diff::Hunk> represents a hunk in a patch.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 old_start( )

Starting line number in C<"old_file">.

=head2 old_lines( )

Number of lines in C<"old_file">.

=head2 new_start( )

Starting line number in C<"new_file">.

=head2 new_lines( )

Number of lines in C<"new_file">.

=head2 header( )

Header text.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Diff::Hunk
