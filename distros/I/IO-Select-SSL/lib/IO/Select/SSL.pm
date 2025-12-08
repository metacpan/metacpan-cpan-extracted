package IO::Select::SSL;

use 5.006;
use strict;
use warnings;
use base qw(IO::Select);

our $VERSION = '0.03';

# can_read( [ $timeout ] )
# Assume pending SSL handles have priority since no select() syscall is required
sub can_read {
  my $self = shift;
  if (my @ssl = $self->pending_handles) {
    return @ssl;
  }
  return $self->SUPER::can_read(@_);
}

# select ( READ, WRITE, ERROR [, TIMEOUT ] )
# Assume pending SSL read handles have priority since no select() syscall is required
sub select {
  my $class = shift;
  if (my $reader = $_[0]) {
    if (my @ssl = $reader->pending_handles) {
      return (\@ssl, [], []);
    }
  }
  return $class->SUPER::select(@_);
}

# pending_handles
# Return a list of handles that already have pending but unread data in its INPUT buffer.
sub pending_handles {
  my $self = shift;
  my @ssl = ();
  foreach my $handle ($self->handles) {
    if (ref($handle) =~ /::/ and
        $handle->can("pending") and
        $handle->pending) {
      push @ssl, $handle;
    }
  }
  if (@ssl) {
    return @ssl;
  }
  return ();
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

IO::Select::SSL - IO::Socket::SSL compatible IO::Select

=head1 SYNOPSIS

  use IO::Select::SSL;
  my $sel = new IO::Select::SSL;


=head1 DESCRIPTION

This module is intended to be a drop-in replacement for IO::Select.
However, the can_read method actually handles the very special IO::Socket::SSL
handles correctly by returning those handles that still have at least some
decrypted characters in the buffer.
Without this module, can_read will choke forever (or until timeout)
waiting for the socket to be ready to read even when there is still
something just sitting in the buffer ready to be immediately read.
Actually, this module will also correctly behave for any objects with any
tied Handle objects that implement the "pending" method to return true if
something is already in the buffer ready to read.
And if the objects used are real IO::Handle objects or real Perl blob
file handles, then of course this module will still work because it will
fall back to behave exactly like the normal IO::Select does.

=head1 METHODS

All IO::Select methods will also be valid here since IO::Select::SSL
isa IO::Select. Plus the following methods have been overloaded:

=head2 can_read ( [ $timeout ] )

Same as IO::Select except immediately returns handles with pending INPUT data.

=head2 select ( READ, WRITE, ERROR [, TIMEOUT ] )

Same as IO::Select except immediately returns handles with pending INPUT data.

=head2 pending_handles

Returns a list of readable handles with pending INPUT data.

=head1 INSTALLATION

  perl Makefile.PL
  make
  make test
  make install

=head1 DEPENDENCIES

  Requires IO::Select to be installed.

=head1 AUTHOR

Rob Brown E<lt>bbb@cpan.orgE<gt>

=head1 SEE ALSO

L<IO::Select>.
L<IO::Socket::SSL>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2025 by Rob Brown <bbb@cpan.org>

This library is free software; you can redistribute it and/or
modify it under the terms of The Artistic License 2.0.

=cut
