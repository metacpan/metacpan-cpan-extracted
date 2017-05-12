package Linux::Sysfs;

use strict;
use warnings;
require Exporter;

our $VERSION = '0.03';
our @ISA     = qw(Exporter);

our @EXPORT_OK = qw(
        $FSTYPE_NAME
        $PROC_MNTS
        $BUS_NAME
        $CLASS_NAME
        $BLOCK_NAME
        $DEVICES_NAME
        $DRIVERS_NAME
        $MODULE_NAME
        $NAME_ATTRIBUTE
        $MOD_PARM_NAME
        $MOD_SECT_NAME
        $UNKNOWN
        $PATH_ENV
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

eval {
    require XSLoader;
    XSLoader::load( 'Linux::Sysfs', $VERSION );
    1;
} or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    Linux::Sysfs->bootstrap($VERSION);
};

1;

__END__
=head1 NAME

Linux::Sysfs - Perl interface to libsysfs

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Linux::Sysfs;

    my $path = Linux::Sysfs->get_mnt_path();

    my $module = Linux::Sysfs::Module->open('usbcore');
    my @parms  = $module->get_sections;

    $module->close;

=head1 DESCRIPTION

Linux::Sysfs' purpose is to provide a consistent and stable interface for
querying system device information exposed through the sysfs filesystem. The
library implements functions for querying filesystem information, such as
reading directories and files. It also contains routines for working with
buses, classes, and the device tree.

The functionality of this module is split up between several packages. See the
other packages under the Linux::Sysfs:: namespace for the full documentation.

=head1 EXPORT

The following libsysfs constants may be imported.

=over

=item C<$FSTYPE_NAME>

=item C<$PROC_MNTS>

=item C<$BUS_NAME>

=item C<$CLASS_NAME>

=item C<$BLOCK_NAME>

=item C<$DEVICES_NAME>

=item C<$DRIVERS_NAME>

=item C<$MODULE_NAME>

=item C<$NAME_ATTRIBUTE>

=item C<$MOD_PARM_NAME>

=item C<$MOD_SECT_NAME>

=item C<$UNKNOWN>

=item C<$PATH_ENV>

=back

All constants will be exported when using the ':all' tag when importing.

=head1 FUNCTIONS

=head2 get_mnt_path

  my $path = Linux::Sysfs->get_mnt_path();

Finds the mount path for filesystem type "sysfs". Returns undef on failure.

=head1 DEPENDENCIES

Linux::Sysfs requires libsysfs version 2.0.0 or later. See
L<http://linux-diag.sourceforge.net/Sysfsutils.html>.

=head1 INCOMPATIBILITIES

This module currently doesn't work with any version of libsysfs smaller than
2.0.0.

=head1 BUGS AND LIMITATIONS

In the current implementation of Linux::Sysfs it's not possible to free the
objects when they get destroyed automatically. Therefor you should care about
calling B<close()> for each object when you don't need it anymore.

=head1 SEE ALSO

L<Linux::Sysfs::Attribute>

L<Linux::Sysfs::Bus>

L<Linux::Sysfs::Class>

L<Linux::Sysfs::ClassDevice>

L<Linux::Sysfs::Device>

L<Linux::Sysfs::Driver>

L<Linux::Sysfs::Module>

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to
E<lt>bug-linux-sysfs@rt.cpan.orgE<gt>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Linux-Sysfs>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Linux::Sysfs

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Linux-Sysfs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Linux-Sysfs>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Linux-Sysfs>

=item * Search CPAN

L<http://search.cpan.org/dist/Linux-Sysfs>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Florian Ragwitz, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU Library General Public License as published
by the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307
USA.

=cut
