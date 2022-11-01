package Git::Raw::Reflog::Entry;
$Git::Raw::Reflog::Entry::VERSION = '0.90';
use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Reflog::Entry - Git reflog entry class

=head1 VERSION

version 0.90

=head1 DESCRIPTION

A L<Git::Raw::Reflog::Entry> represents an entry in a Git reflog.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 new_id( )

Retrieve the new id for the entry.

=head2 old_id( )

Retrieve the old id for the entry.

=head2 committer( )

The committer of the entry, a L<Git::Raw::Signature> object.

=head2 message( )

The message for the entry.

=head1 AUTHOR

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Reflog::Entry
