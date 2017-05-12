package Log::Unrotate::Cursor;
{
  $Log::Unrotate::Cursor::VERSION = '1.32';
}

use strict;
use warnings;

=head1 NAME

Log::Unrotate::Cursor - abstract class for unrotate cursors

=head1 VERSION

version 1.32

=head1 DECRIPTION

C<Log::Unrotate> keeps its position in persistent objects called cursors.

See C<Log::Unrotate::Cursor::File> for the default cursor implementation.

=head1 METHODS

=over

=item B<read()>

Get the hashref with a position data.

Data usually includes I<Position>, I<Inode>, I<LastLine> and I<LogFile> keys.

=cut
sub read($) {
    die 'not implemented';
}

=item B<commit($position)>

Save a new position into the cursor.

=cut
sub commit($$) {
    die 'not implemented';
}

=item B<clean()>

Clean all data from the cursor.

=cut
sub clean($) {
    die 'not implemented';
}

=item B<rollback()>

Rollback the cursor to some previous value.

Returns 1 on success, 0 on fail.

=cut

sub rollback($) {
    return 0;
}

=back

=cut

1;
