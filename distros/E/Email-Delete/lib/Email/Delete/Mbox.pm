package Email::Delete::Mbox;
# $Id: Mbox.pm,v 1.3 2004/12/17 18:45:50 cwest Exp $
use strict;

{
    package Email::LocalDelivery::OverwriteMbox;
    use base qw[Email::LocalDelivery::Mbox];
    my $fh;
    sub _set_fh { $fh = $_[1] }
    sub _open_fh { $fh }
    sub _close_fh { 1 }
}

package Email::Delete::Mbox;
use base qw[Email::Folder::Mbox];

use vars qw[$VERSION];
$VERSION = '2.002';

use Email::Folder;
use IO::File;

sub delete_message {
    my %args = @_;
    
    my $fh     = IO::File->new($args{from}, '+<');
    flock $fh, 2;
    {
        local $^W = 0;
        *_get_fh = sub { $fh };
    }
    my $folder = Email::Folder->new(
                                    $args{from},
                                    reader => __PACKAGE__,
                                   );

    my (@keep, @delete);
    while ( my $message = $folder->next_message ) {
        my $trash_it = $args{matching}->($message);
        if ( $trash_it ) {
            push @delete, $message;
            next;
        }
        push @keep, $message;
    }
    
    return 0 unless @delete;

    seek $fh, 0, 0;
    Email::LocalDelivery::OverwriteMbox->_set_fh($fh);
    Email::LocalDelivery::OverwriteMbox->deliver($_->as_string, $fh)
        for @keep;
    Email::LocalDelivery::OverwriteMbox->_set_fh(undef);
    truncate $fh, tell $fh;
    close $fh;

    return scalar @delete;
}

1;

__END__

=head1 NAME

Email::Delete::Maildir - Delete Messages from a mbox Folder

=head1 SYNOPSIS

  use Email::Delete qw[delete_message];
  
  my $message_id = shift @ARGV;
  
  delete_message from     => 'some/mbox',
                 matching => sub {
                   my $message = shift;
                   $message->header('Message-ID') =~ $message_id;
                 };

=head1 DESCRIPTION

This software will delete messages from a given mbox folder.

You may be interested to know that every call to C<delete_message> will
lock properly (thus annoyingly) throughout the entire process of
scanning and rebuilding the mbox.

=head1 SEE ALSO

L<Email::Delete>,
L<perl>.

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2004 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut
