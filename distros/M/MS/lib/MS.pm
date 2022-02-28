package MS;

our $VERSION = 0.207001;
$VERSION = eval $VERSION;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS - Namespace for mass spectrometry-related libraries

=head1 DESCRIPTION

The C<MS::> namespace is intended as a hub for mass spectrometry-related
development in Perl. This core package includes a number of parsers for HUPO
PSI standards and other common file formats, as well as core functionality for
mass spectrometry and proteomics work. Developers are encouraged to put their
work under the C<MS::> namespace. The following namespace hierarchy is
suggested:

=over

=item * C<MS::Reader::> — format-specific file readers/parsers 

=item * C<MS::Writer::> — format-specific file writers/formatters

=item * C<MS::Search::> — search-related modules (front-ends, etc)

=item * C<MS::Algo::> — algorithm implementations (prototyping, etc)

=back

=head1 MAILING LIST

Please join the discussion at L<https://groups.google.com/d/forum/ms-perl>.

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2022 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
