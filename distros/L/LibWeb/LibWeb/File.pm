#==============================================================================
# LibWeb::File -- File manipulations for libweb applications.

package LibWeb::File;

# Copyright (C) 2000  Colin Kong
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#=============================================================================

# $Id: File.pm,v 1.4 2000/07/18 06:33:30 ckyc Exp $

#-##############################
# Use standard library.
use Carp;
use strict;
use vars qw($VERSION @ISA);
require FileHandle;

#-##############################
# Use custom library.
require LibWeb::Class;

#-##############################
# Version.
$VERSION = '0.02';

#-##############################
# Inheritance.
@ISA = qw(LibWeb::Class);

#-##############################
# Methods.
sub new {
    my($class, $Class, $self); 
    $class = shift;
    $Class = ref($class) || $class;
    $self = $Class->SUPER::new();
    bless( $self, $Class );
}

sub DESTROY {}

sub read_lines_from_file {
    #
    # Params: -file => $file
    #
    # Open, read all lines, close the file and return lines in an ARRAY ref.
    #
    my ($self, $file, $fh, @lines);
    $self = shift;
    ($file) = $self->rearrange(['FILE'], @_);

    $fh = FileHandle->new($file) or
      croak "LibWeb::File::read_lines_from_file() error (the file is $file): $!";

    @lines = $fh->getlines() or
      croak "LibWeb::File::read_lines_from_file() error (the file is $file): $!";

    $fh->close();
    return \@lines;
}

sub write_lines_to_file {
    #
    # Params: -file => 'abs_path_to_file', -lines => $lines
    #
    # Pre:
    # - $lines is an ARRAY ref. to lines which are scalars.
    #
    # Post:
    # - Overwrite the file with the lines.
    #
    my ($self, $lines, $old_file, $new_file, $NEW);
    $self = shift;
    ($old_file, $lines) = $self->rearrange(['FILE', 'LINES'], @_);

    $new_file = "${old_file}." . time();

    $NEW = new FileHandle($new_file, 'w') ||
      croak "LibWeb::File::write_lines_to_file(): cannot open new file";

    foreach (@$lines) {
	print $NEW $_;
    }
    $NEW->close();

    rename($new_file, $old_file) ||
      croak "LibWeb::File::write_lines_to_file(): could not rename files.";

    chmod(0644, $old_file);
    return 1;
}

1;
__END__

=head1 NAME

LibWeb::File - File manipulations for libweb applications

=head1 SUPPORTED PLATFORMS

=over 2

=item BSD, Linux, Solaris and Windows.

=back

=head1 REQUIRE

=over 2

=item *

No non-standard Perl's library is required.

=back

=head1 ISA

=over 2

=item *

LibWeb::Class

=back

=head1 SYNOPSIS

  use LibWeb::File;
  my $fh = new LibWeb::File();

  $lines = $fh->read_lines_from_file( -file => '/home/me/file1' );

  $fh->write_lines_to_file(
                            -file => '/home/me/file2',
                            -lines => $lines
                          );

=head1 ABSTRACT

This class provides several methods to manipulate text files.

The current version of LibWe LibWeb::File is available at

   http://libweb.sourceforge.net

Several LibWeb applications (LEAPs) have be written, released and are
available at

   http://leaps.sourceforge.net

=head1 DESCRIPTION

=head2 METHODS

B<read_lines_from_file()>

Params:

  -file =>

Open, read all lines, close C<-file> and return the lines in an ARRAY
reference.

B<write_lines_to_file()>

Params:

  -file =>, -lines =>

Pre:

=over 2

=item *

C<-lines> is an ARRAY reference to lines which are scalars.

=back

Post:

=over 2

=item *

Overwrite C<-file> with the lines.

=back

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS

=head1 BUGS

=head1 SEE ALSO

L<LibWeb::Class>.

=cut
