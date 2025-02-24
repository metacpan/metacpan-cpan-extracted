package Git::Raw::Diff::File;
$Git::Raw::Diff::File::VERSION = '0.90';
use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Diff::File - Git diff file class

=head1 VERSION

version 0.90

=head1 DESCRIPTION

A L<Git::Raw::Diff::File> represents one side of a diff delta.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 id( )

Retrieve the id of the diff file as a string.

=head2 path( )

Retrieve the path of the diff file.

=head2 size( )

Retrieve the size of the diff file.

=head2 flags( )

Retrieve the flags associated with the delta. Returns an array reference
with zero or more of the following:

=over 4

=item * "binary"

Files treated as binary data.

=item * "valid_id"

C<"id"> value is known correct.

=back

=head2 mode( )

Retrieve the diff file mode. Returns one of the following:

=over 4

=item * "unreadable"

=item * "tree"

=item * "blob"

=item * "blob_executable"

=item * "link"

=item * "commit"

=back

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

1; # End of Git::Raw::Diff::File
