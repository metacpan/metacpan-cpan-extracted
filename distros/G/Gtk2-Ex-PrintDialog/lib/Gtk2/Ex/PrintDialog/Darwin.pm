# $Id: Darwin.pm,v 1.1 2005/10/05 12:15:05 jodrell Exp $
# Copyright (c) 2005 Gavin Brown. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms as
# Perl itself.
package Gtk2::Ex::PrintDialog::Darwin;
use Gtk2::Ex::PrintDialog::Unix;
use base qw(Gtk2::Ex::PrintDialog::Unix);
use strict;

1;

__END__

=pod

=head1 NAME

Gtk2::Ex::PrintDialog::darwin - MacOS X/Darwin backend for L<Gtk2::Ex::PrintDialog>

=head1 DESCRIPTION

This module is a printing backend for L<Gtk2::Ex::PrintDialog>. You should
never need to access it directly. It is just a wrapper around
L<Gtk2::Ex::PrintDialog::Unix>.

=head1 AUTHOR

Gavin Brown (gavin dot brown at uk dot com)  

=head1 COPYRIGHT

(c) 2005 Gavin Brown. All rights reserved. This program is free software; you
can redistribute it and/or modify it under the same terms as Perl itself.     

=cut
