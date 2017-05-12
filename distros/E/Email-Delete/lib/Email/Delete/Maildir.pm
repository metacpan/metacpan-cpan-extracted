package Email::Delete::Maildir;
# $Id: Maildir.pm,v 1.1 2004/12/17 18:03:16 cwest Exp $
use strict;

use vars qw[$VERSION];
$VERSION = '2.002';

use Email::Simple;

sub delete_message {
    my %args = @_;
    
    my @files;
# Whatever in F<tmp/> is undelivered yet, right?
    foreach my $sect ( qw( new cur ) ) {
# What if C<$args{from}> is something but directory?  Never mind, just skip it.
        opendir my($dh), "$args{from}/$sect" or next;
        while(my $mail = readdir $dh) {
# Faild to open subfolder?  Here?  Immaterial, go away.
            -f "$args{from}/$sect/$mail"                          or next;
            open my $fh, '<', "$args{from}/$sect/$mail"           or next;
            my $msg = Email::Simple->new(do { local $/; <$fh>; }) or next;
            $args{matching}->($msg) and push @files, "$args{from}/$sect/$mail";
        };
    };
    return unlink @files;
}

1;

__END__

=head1 NAME

Email::Delete::Maildir - Delete Messages from a Maildir Folder

=head1 SYNOPSIS

  use Email::Delete qw[delete_message];
  
  my $message_id = shift @ARGV;
  
  delete_messages from     => 'some/Maildir/',
                  matching => sub {
                      my $message = shift;
                      $message->header('Message-ID') =~ $message_id;
                  };

=head1 DESCRIPTION

This software will delete messages from a given Maildir folder.

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
