package Future::IO::Impl::AnyEvent::Future;

use strict;
use warnings;
use 5.014;

use base 'Future';

use AnyEvent;

our $VERSION = 0.01;

sub await {
  my ($self) = @_;
  my $cv = AnyEvent->condvar;
  $self->on_ready(sub { $cv->send });
  $cv->recv;
  return $self;
}

1;

__END__

=head1 NAME

Future::IO::Impl::AnyEvent::Future - Specialization of L<Future> for
L<Future::IO::Impl::AnyEvent>.

=head1 DESCRIPTION

See L<Future::IO::Impl::AnyEvent>.

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

L<Future::IO::Impl::AnyEvent>

=item *

L<Future>

=back

=cut
