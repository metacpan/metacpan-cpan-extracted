package MIME::Detect::FreeDesktopOrgDB;
use strict;
use File::ShareDir 'dist_file';
our $VERSION = '0.10';

=head1 NAME

MIME::Detect::FreeDesktopOrgDB - default freedesktop.org database

=head1 NOTICE

This distribution contains a verbatim copy of the freedesktop.org
MIME database available from
L<https://www.freedesktop.org/wiki/Software/shared-mime-info/>
.
That database is licensed under the General Public License v2,
see the accompanying COPYING file distributed with the file
for its exact terms.

=cut

sub url {'https://www.freedesktop.org/wiki/Software/shared-mime-info/'}

=head2 C<< get_xml >>

    my $xml = MIME::Detect::FreeDesktopOrgDB->get_xml;

Returns a reference to the XML string from C<freedesktop.org.xml> distributed
with this module.

=cut

sub get_xml {
    (my $xml_name = dist_file('MIME-Detect', 'mime-info/freedesktop.org.xml'));
    open my $fh, '<', $xml_name
        or die "Couldn't read '$xml_name': $!";
    binmode $fh;
    local $/;
    return \<$fh>
}

1;

=head1 REPOSITORY

The public repository of this module is 
L<http://github.com/Corion/mime-detect>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=MIME-Detect>
or via mail to L<filter-signatures-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2015-2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
