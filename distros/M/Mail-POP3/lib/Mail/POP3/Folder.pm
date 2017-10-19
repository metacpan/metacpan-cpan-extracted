package Mail::POP3::Folder;

1;

__END__

=head1 NAME

Mail::POP3::Folder - superclass that defines interface for Folder classes

=head1 DESCRIPTION

This class's subclasses manage a mailbox in accordance with the
requirements of a POP3 server.

=head1 METHODS

=head2 new

  $class->new($user_name, $password, $user_id, @other_args);

=head2 delete

=head2 flush_delete

=head2 is_deleted

=head2 is_valid

=head2 lock_acquire

Lock-handling.

=head2 lock_release

Lock-handling.

=head2 messages

=head2 octets

=head2 reset

=head2 retrieve

=head2 top

=head2 uidl

=head2 uidl_list

=head1 SEE ALSO

RFC 1939, L<Mail::POP3::Folder::mbox>.
