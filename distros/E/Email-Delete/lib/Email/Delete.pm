package Email::Delete;
use strict;
## no critic RequireUseWarnings

=head1 NAME

Email::Delete - Delete Messages from Folders

=head1 VERSION

version 2.002

=cut

use base qw[Exporter];
use vars qw[@EXPORT_OK $VERSION];

@EXPORT_OK = qw[delete_message];
$VERSION = '2.002';

use Email::FolderType qw[folder_type];

=head1 SYNOPSIS

  use Email::Delete qw[delete_message];
  
  my $message_id = shift @ARGV;
  
  delete_message from     => $ENV{MAIL},
                 matching => sub {
                   my $message = shift;
                   $message->header('Message-ID') =~ $message_id;
                 };

=head1 DESCRIPTION

This software will delete messages from a given folder if the
test returns true.

=head2 delete_message

  delete_message from     => 'folder_name',
                 with     => 'My::Delete::Package',
                 matching => sub { return_true_for_delete() };

C<from> is a required parameter, a string containing the folder
name to delete from. By default C<Email::FolderType> is used
to determine what package to use when deleting a message. To
override the default, specify the C<with> parameter. Your
package's C<delete_message> function will be called with the
same arguments that C<delete_message> from Email::Delete is
called with.

C<matching> is a required argument. Its value is a code reference.
If the anonymouse subroutine returns a true value, the current
message is deleted. Each message is passed to the C<matching>
test in turn. The first and only argument to C<matching> is
an C<Email::Simple> object representing the message.

If you should ever want to stop processing a mailbox, just call
C<die> from your code reference. A proper deleting package will
not delete mail until all the messages have been scanned. So
if you throw an exception, your mail will be preserved and scanning
will be aborted.

=cut

sub delete_message {
    my %args = @_;
    my $with = $args{with};
    unless ( $with ) {
        my $type = folder_type $args{from};
        $with = __PACKAGE__ . "::$type";
    }

    eval "use $with"; die if $@;

    $with->can('delete_message')->(%args);
}

1;

=head1 SEE ALSO

L<Email::Simple>,
L<Email::Folder>,
L<Email::LocalDelivery>,
L<perl>.

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2004 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut
