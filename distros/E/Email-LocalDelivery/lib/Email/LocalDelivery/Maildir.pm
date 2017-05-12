use strict;
use warnings;
package Email::LocalDelivery::Maildir;
{
  $Email::LocalDelivery::Maildir::VERSION = '1.200';
}
# ABSTRACT: deliver mail to a Maildir
use Email::Simple;
use File::Path;
use Symbol qw(gensym);


my $maildir_time    = 0;
my $maildir_counter = 0;
use Sys::Hostname;
(my $HOSTNAME = hostname) =~ s/\..*//;

sub deliver {
  my ($class, $mail, @files) = @_;

  $mail = Email::Simple->new($mail)
    unless eval { $mail->isa('Email::Simple') };  # For when we recurse

  $class->fix_lines($mail);
  $class->update_time();

  my $temp_file = $class->write_temp($mail, @files) or return;

  my @written = $class->write_links($mail, $temp_file, @files);
  unlink $temp_file;
  return @written;
}

sub fix_lines {
  my ($class, $mail) = @_;
  return if $mail->header("Lines");
  my @lines = split /\n/, $mail->body;
  $mail->header_set("Lines", scalar @lines);
}

sub update_time {
  if ($maildir_time != time) {
    $maildir_time    = time;
    $maildir_counter = 0;
  } else {
    $maildir_counter++;
  }
}

sub write_temp {
  my ($class, $mail, @files) = @_;
  for my $file (@files) {
    $file =~ s{/$}{};
    my $tmp_file = $class->get_filename_in($file . "/tmp");
    eval {
      mkpath([ map { "$file/$_" } qw(tmp new cur) ]);
      1;
    } or next;
    $class->write_message($mail, $tmp_file)
      and return $tmp_file;
  }
  return;
}

sub get_filename_in {
  my ($class, $tmpdir) = @_;
  my ($msg_file, $tmppath);
  do {
    $msg_file = join ".", ($maildir_time, $$ . "_$maildir_counter", $HOSTNAME);
    } while -e ($tmppath = "$tmpdir/$msg_file")
    and ++$maildir_counter;
  return $tmppath;
}

sub write_links {
  my ($class, $mail, $temp_file, @files) = @_;
  my @rv;
  for my $file (@files) {
    $file =~ s{/$}{};
    my $new_location = $class->get_filename_in($file . "/new");
    eval {
      mkpath([ map { "$file/$_" } qw(tmp new cur) ]);
      1;
    } or next;
    if (link $temp_file, $new_location) {
      push @rv, $new_location;
    } else {
      require Errno;
      import Errno qw(EXDEV);
      if ($! == &EXDEV) {
        push @rv, $class->deliver($mail, $file);
      }
    }
  }
  return @rv;
}

sub write_message {
  my ($class, $mail, $file) = @_;
  my $fh = gensym;
  open $fh, ">$file" or return;

  if (eval { $mail->can('stream_to') }) {
    eval { $mail->stream_to($fh); 1 } or return;
  } else {
    print $fh $mail->as_string or return;
  }

  return close $fh;
}

1;

__END__

=pod

=head1 NAME

Email::LocalDelivery::Maildir - deliver mail to a Maildir

=head1 VERSION

version 1.200

=head1 INSTEAD...

Instead, consider using L<Email::Sender::Transport::Maildir>.

=head1 AUTHORS

=over 4

=item *

Simon Cozens

=item *

Casey West <casey@geeknest.com>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Simon Cozens.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
