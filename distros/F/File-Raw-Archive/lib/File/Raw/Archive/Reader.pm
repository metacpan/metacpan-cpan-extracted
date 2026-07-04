package File::Raw::Archive::Reader;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';


1;

__END__

=head1 NAME

File::Raw::Archive::Reader - Sequential archive iterator

=head1 SYNOPSIS

    my $r = File::Raw::Archive->open("foo.tar");
    while (my $entry = $r->next) {
        next if $entry->is_dir;
        my $bytes = $entry->slurp;
    }
    $r->close;

=head1 DESCRIPTION

A C<File::Raw::Archive::Reader> is returned by
L<File::Raw::Archive/open>. It wraps an open file descriptor and a
format plugin cursor, and emits L<File::Raw::Archive::Entry> objects
one at a time in archive order.

=head1 METHODS

=over 4

=item C<next>

Advance to the next entry in the archive. If the previous entry's
payload was never consumed it is drained automatically before
advancing.

Returns a L<File::Raw::Archive::Entry> object, or C<undef> when the
archive is exhausted. Croaks if the reader has already been closed or
if the archive data is malformed.

    while (my $entry = $r->next) {
        next if $entry->is_dir;
        process($entry->slurp);
    }

=item C<close>

Close the underlying file descriptor and release all resources.
Idempotent; called automatically by C<DESTROY> if the caller does not
close explicitly.

=back

=head1 SEE ALSO

L<File::Raw::Archive>, L<File::Raw::Archive::Entry>.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0
(GPL Compatible).

=cut
