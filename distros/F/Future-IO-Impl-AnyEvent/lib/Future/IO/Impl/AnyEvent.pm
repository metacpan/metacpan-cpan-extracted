package Future::IO::Impl::AnyEvent;

use strict;
use warnings;
use 5.014;

use base 'Future::IO::ImplBase';

use AnyEvent;
use Future::IO::Impl::AnyEvent::Future;

our $VERSION = 0.02;

__PACKAGE__->APPLY;

sub sleep {  ## no critic (ProhibitBuiltinHomonyms)
  my (undef, $sec) = @_;
  my $f = Future::IO::Impl::AnyEvent::Future->new;
  my $w;
  $w = AE::timer $sec, 0, sub { undef $w; $f->done };
  $f->on_cancel(sub { undef $w });
  return $f;
}

sub ready_for_read {
  my (undef, $fh) = @_;
  my $f = Future::IO::Impl::AnyEvent::Future->new;
  my $w;
  $w = AE::io $fh, 0, sub { undef $w; $f->done };
  $f->on_cancel(sub { undef $w });
  return $f;
}

sub ready_for_write {
  my (undef, $fh) = @_;
  my $f = Future::IO::Impl::AnyEvent::Future->new;
  my $w;
  $w = AE::io $fh, 1, sub { undef $w; $f->done };
  $f->on_cancel(sub { undef $w });
  return $f;
}

sub waitpid {  ## no critic (ProhibitBuiltinHomonyms)
  my (undef, $pid) = @_;
  my $f = Future::IO::Impl::AnyEvent::Future->new;
  my $w;
  $w = AE::child $pid, sub { undef $w; $f->done($_[1]) };
  $f->on_cancel(sub { undef $w });
  return $f;
}

1;

__END__

=head1 NAME

Future::IO::Impl::AnyEvent - L<Future::IO> Implementation using L<AnyEvent>.

=head1 DESCRIPTION

This module provides an implementation for L<Future::IO> which uses L<AnyEvent>
which, in turn, might be using any compatible event loop (in particular L<EV>).

There are no additional methods to use in this module; it simply has to be
loaded, and it will provide the C<Future::IO> implementation methods:

   use Future::IO;
   use Future::IO::Impl::AnyEvent;

   my $f = Future::IO->sleep(5);
   ...

=head1 AUTHOR

Mathias Kende <mathias@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Mathias Kende

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

=over 4

=item *

L<Future::IO>

=item *

L<AnyEvent>

=back

=cut
