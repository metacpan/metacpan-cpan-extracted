package Linux::Event::Kernel;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.114';

1;

__END__

=head1 NAME

Linux::Event::Kernel - kernel event and state namespace

=head1 DESCRIPTION

C<Linux::Event::Kernel> is a namespace category for Linux::Event abstractions
over Linux kernel notification and state facilities. Applications choose a
concrete leaf such as L<Linux::Event::Kernel::Timer>,
L<Linux::Event::Kernel::Signal>, L<Linux::Event::Kernel::Event>, or
L<Linux::Event::Kernel::Process>.

Each leaf accepts its application callbacks as constructor coderefs or cached
subclass methods. Process subclasses may also centralize cached pipe-I/O tuning.

=cut
