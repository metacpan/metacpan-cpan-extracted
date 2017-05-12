use strict;
use warnings;

package Gtk2::Phat;

use Gtk2;

our @ISA = qw(DynaLoader);
our $VERSION = '0.08';

require DynaLoader;

sub dl_load_flags { 0x01 };

Gtk2::Phat->bootstrap($VERSION);

=head1 NAME

Gtk2::Phat - Perl interface to the Phat widget collection

=head1 DESCRIPTION

This module allows a perl developer to access the widgets of the Phat widget
collection which is geared toward pro-audio apps. The goal is to eliminate
duplication of effort and provide some standardization.

=head1 SEE ALSO

L<Gtk2>(3pm), L<Gtk2::Phat::index>(3pm)

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Florian Ragwitz

This is free software, licensed under:

  The GNU Lesser General Public License Version 2.1, February 1999

=cut

1;
