use strict;
use warnings;
package Email::Simple::FromHandle 0.055;
use Email::Simple 2.004;
use parent 'Email::Simple';
# ABSTRACT: an Email::Simple but from a handle

#pod =head1 SYNOPSIS
#pod
#pod   use Email::Simple::FileHandle;
#pod
#pod   open my $fh, "<", "email.msg";
#pod
#pod   my $email = Email::Simple::FromHandle->new($fh);
#pod
#pod   print $email->as_string;
#pod   # or
#pod   $email->stream_to(\*STDOUT);
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a subclass of Email::Simple which can accept filehandles as the source
#pod of an email.  It will keep a reference to the filehandle and read from it when
#pod it needs to access the body.  It does not load the entire body into memory and
#pod keep it there.
#pod
#pod =cut

use Carp ();
use IO::String;
use Fcntl qw(SEEK_SET);

my $crlf = qr/\x0a\x0d|\x0d\x0a|\x0a|\x0d/; # We are liberal in what we accept.

#pod =head1 METHODS
#pod
#pod In addition to the standard L<Email::Simple> interface, the following methods
#pod are provided:
#pod
#pod =head2 handle
#pod
#pod This returns the handle given to construct the message.  If the message was
#pod constructed with a string instead, it returns an IO::String object.
#pod
#pod =cut

sub handle { $_[0]->{handle} }

#pod =head2 body_pos
#pod
#pod This method returns the position in the handle at which the body begins.  This
#pod is used for seeking when re-reading the body.
#pod
#pod =cut

sub body_pos { $_[0]->{body_pos} }

#pod =head2 reset_handle
#pod
#pod This method seeks the handle to the body position and resets the header-line
#pod iterator.
#pod
#pod For unseekable handles (pipes, sockets), this will die.
#pod
#pod =cut

sub _is_seekable {
  my ($self) = @_;
  # on solaris, tell($pipe) == -1, and seeking on a pipe appears to discard the
  # data waiting
  return unless $self->body_pos >= 0;
  # on linux, seeking on a pipe is safe and returns ''
  return unless seek($self->handle, 0, 1);
  # fall through: it must be seekable
  return 1;
}

sub reset_handle {
  my ($self) = @_;

  # Don't die the first time we try to read from a pipe/socket/etc.
  # TODO: When reading from something non-seekable, should we
  # give the option to store data into a temp file, or something similar?
  return unless $self->_is_seekable || $self->{_seek}++;

  delete $self->{_get_head_lines};

  seek $self->handle, $self->body_pos, SEEK_SET
    or Carp::croak "can't seek: $!";
}

#pod =head2 getline
#pod
#pod   $str = $email->getline;
#pod
#pod This method returns either the next line from the headers or the next line from
#pod the underlying filehandle.  It only returns a single line, regardless of
#pod context.  Returns C<undef> on EOF.
#pod
#pod =cut

sub getline {
  my ($self) = @_;
  unless ($self->{_get_head_lines}) {
    $self->{_get_head_lines} = [
      split(/(?<=\n)/, $self->header_obj->as_string),
      $self->crlf,
    ];
  }
  my $handle = $self->handle;
  return shift @{$self->{_get_head_lines}} || <$handle>;
}

#pod =head2 stream_to
#pod
#pod   $email->stream_to($fh, [ \%arg ]);
#pod
#pod This method efficiently writes the message to the passed-in filehandle.  
#pod
#pod The second argument may be a hashref of options:
#pod
#pod =over 4
#pod
#pod =item B<reset_handle:>
#pod
#pod Whether or not to call C<< $self->reset_handle >> before reading the message
#pod (default true). 
#pod
#pod =item B<chunk_size:>
#pod
#pod Number of bytes to read from C<< $self->handle >> at once (default 65536).
#pod
#pod =item B<write:>
#pod
#pod Coderef to use to print instead of C<print $fh $chunk>.  This coderef will
#pod receive two arguments, the 'filehandle' (which need not be a real filehandle at
#pod all) and the current chunk of data.
#pod
#pod =back
#pod
#pod =cut

sub _stream_to_print {
  my $fh = shift;
  print {$fh} @_ or Carp::croak "can't print buffer: $!";
}

sub stream_to {
  my ($self, $fh, $arg) = @_;
  $arg ||= {};
  $arg->{reset_handle} = 1 unless exists $arg->{reset_handle};
  # 65536 is a randomly-chosen magical number that's large enough to be a win
  # over line-by-line reading but small enough not to impinge very much upon
  # ram usage -- hdp, 2006-11-27
  $arg->{chunk_size} ||= 65536;
  $arg->{write}      ||= \&_stream_to_print;
  $arg->{write}->($fh, $self->header_obj->as_string . $self->crlf);
  $self->reset_handle if $arg->{reset_handle};
  my $buf;
  while (read($self->handle, $buf, $arg->{chunk_size}) > 0) {
    $arg->{write}->($fh, $buf);
  }
}

#### Methods that override Email::Simple below

sub new {
    my ($class, $handle, $arg) = @_;

    $arg ||= {};
    $arg->{header_class} ||= $class->default_header_class;

    return Email::Simple->new($handle, $arg) unless ref $handle;

    my ($head, $mycrlf) = $class->_split_head_from_body($handle);

    my $self = bless {
        handle   => $handle,
        body_pos => tell($handle),
        mycrlf   => $mycrlf,
    }, $class;

    $self->header_obj_set(
        $arg->{header_class}->new($head, { crlf => $self->crlf })
    );

    return $self;
}

sub _split_head_from_body {
    my ($class, $handle) = @_;

    my $text = q{};

    # XXX it is stupid to use <> if we're really going to have multiple forms
    # of crlf, but it is expedient to keep doing so for now. -- hdp, 2006-11-28
    # theoretically, this should be ok, because it will only fail if lines are
    # terminated with \x0d, which wouldn't be ok for network transport anyway.
    my $mycrlf;
    while (<$handle>) {
        last if $mycrlf and /\A$mycrlf\z/;
        $text .= $_;
        ($mycrlf) = /($crlf)\z/;
    }

    return ($text, $mycrlf || "\n");
}

sub body_set {
  my $self = shift;
  my $body = shift;

  my $handle = IO::String->new(\$body);
  $self->{handle} = $handle;
  $self->{body_pos} = 0;
}

sub body {
  my $self = shift;
  scalar do {
    local $/; ## no critic Local, Punctuation
    $self->reset_handle;
    my $handle = $self->handle;
    <$handle>;
  };
}

#pod =head1 CREDITS
#pod
#pod Ricardo SIGNES wrote Email::Simple.
#pod
#pod Numerous improvement, especially streamability the handling of pipes, were made
#pod by Hans Dieter Pearcey.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::Simple::FromHandle - an Email::Simple but from a handle

=head1 VERSION

version 0.055

=head1 SYNOPSIS

  use Email::Simple::FileHandle;

  open my $fh, "<", "email.msg";

  my $email = Email::Simple::FromHandle->new($fh);

  print $email->as_string;
  # or
  $email->stream_to(\*STDOUT);

=head1 DESCRIPTION

This is a subclass of Email::Simple which can accept filehandles as the source
of an email.  It will keep a reference to the filehandle and read from it when
it needs to access the body.  It does not load the entire body into memory and
keep it there.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

In addition to the standard L<Email::Simple> interface, the following methods
are provided:

=head2 handle

This returns the handle given to construct the message.  If the message was
constructed with a string instead, it returns an IO::String object.

=head2 body_pos

This method returns the position in the handle at which the body begins.  This
is used for seeking when re-reading the body.

=head2 reset_handle

This method seeks the handle to the body position and resets the header-line
iterator.

For unseekable handles (pipes, sockets), this will die.

=head2 getline

  $str = $email->getline;

This method returns either the next line from the headers or the next line from
the underlying filehandle.  It only returns a single line, regardless of
context.  Returns C<undef> on EOF.

=head2 stream_to

  $email->stream_to($fh, [ \%arg ]);

This method efficiently writes the message to the passed-in filehandle.  

The second argument may be a hashref of options:

=over 4

=item B<reset_handle:>

Whether or not to call C<< $self->reset_handle >> before reading the message
(default true). 

=item B<chunk_size:>

Number of bytes to read from C<< $self->handle >> at once (default 65536).

=item B<write:>

Coderef to use to print instead of C<print $fh $chunk>.  This coderef will
receive two arguments, the 'filehandle' (which need not be a real filehandle at
all) and the current chunk of data.

=back

=head1 CREDITS

Ricardo SIGNES wrote Email::Simple.

Numerous improvement, especially streamability the handling of pipes, were made
by Hans Dieter Pearcey.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Hans Dieter Pearcey Ricardo Signes

=over 4

=item *

Hans Dieter Pearcey <hdp@cpan.org>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
