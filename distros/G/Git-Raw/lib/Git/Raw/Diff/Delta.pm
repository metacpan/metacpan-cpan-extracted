package Git::Raw::Diff::Delta;
$Git::Raw::Diff::Delta::VERSION = '0.90';
use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Diff::Delta - Git diff delta class

=head1 VERSION

version 0.90

=head1 DESCRIPTION

A L<Git::Raw::Diff::Delta> represents a delta in the diff between two entities.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 status( )

Retrieve the status of the delta. Returns one of the following:

=over 4

=item * "unmodified"

No changes.

=item * "added"

The entry does not exist in the old version.

=item * "deleted"

The entry does not exist in the new version.

=item * "modified"

The entry content changed between the old and new versions.

=item * "renamed"

The entry was renamed between the old and new versions.

=item * "copied"

The entry was copied from another old entry.

=item * "ignored"

The entry is an ignored item in the working directory.

=item * "untracked"

The entry is an untracked item in the working directory.

=item * "type_change"

The type of the entry changed between the old and new versions.

=item * "unreadable"

The entry is unreadable.

=item * "conflicted"

The entry represents a conflict.

=back

=head2 flags( )

Retrieve the flags associated with the delta. Returns an array reference
with zero or more of the following:

=over 4

=item * "binary"

Files treated as binary data.

=item * "valid_id"

C<"id"> value is known correct.

=back

=head2 similarity( )

Retrieve the similarity score between 0 and 100 between C<"old_file">
and C<"new_file">.

=head2 file_count( )

Retrieve the number of files in the delta.

=head2 old_file( )

The C<"old_file"> represents the C<"from"> side of the diff. Returns
a L<Git::Raw::Diff::File> object.

=head2 new_file( )

The C<"new_file"> represents to C<"to"> side of the diff. Returns
a L<Git::Raw::Diff::File> object.

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

1; # End of Git::Raw::Diff::Delta
