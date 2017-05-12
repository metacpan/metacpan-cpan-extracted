#---------------------------------------------------------------------
package Dist::Zilla::Role::ModuleInfo;
#
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 25 Sep 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Create Module::Metadata object from Dist::Zilla::File
#---------------------------------------------------------------------

our $VERSION = '4.22';
# This file is part of Dist-Zilla-Plugins-CJM 4.27 (August 29, 2015)

use Moose::Role;

use autodie ':io';
use File::Temp 0.19 ();         # need newdir
use Module::Metadata ();
use Path::Class qw(dir file);


sub get_module_info
{
  my $self = shift;
  my $file = shift;
  # Any additional parameters get passed to M::Metadata->new_from_file

  # To be safe, reset the global variables controlling IO to their defaults:
  local ($/, $,, $\) = "\n";

  # Module::Metadata doesn't have a new_from_string method,
  # so we'll write the current contents to a temporary file:

  my $tempdirObject = File::Temp->newdir();
  my $dir     = dir("$tempdirObject");
  my $modPath = file($file->name);

  # Module::Metadata only cares about the basename of the file:
  my $tempname = $dir->file($modPath->basename);

  open(my $temp, '>:raw', $tempname);
  print $temp Dist::Zilla->VERSION < 5 ? $file->content : $file->encoded_content;
  close $temp;

  return(Module::Metadata->new_from_file("$tempname", @_)
         or die "Unable to get module info from " . $file->name . "\n");
} # end get_module_info

no Moose::Role;
1;

__END__

=head1 NAME

Dist::Zilla::Role::ModuleInfo - Create Module::Metadata object from Dist::Zilla::File

=head1 VERSION

This document describes version 4.22 of
Dist::Zilla::Role::ModuleInfo, released August 29, 2015
as part of Dist-Zilla-Plugins-CJM version 4.27.

=head1 DESCRIPTION

Plugins implementing ModuleInfo may call their own C<get_module_info>
method to construct a L<Module::Metadata> object.  (Module::Metadata
is the new name for Module::Build::ModuleInfo, now that it's been
split from the Module-Build distribution.)

=head1 METHODS

=head2 get_module_info

  my $info = $plugin->get_module_info($file);

This constructs a Module::Metadata object from the contents
of a C<$file> object that does Dist::Zilla::Role::File.  Any additional
arguments are passed along to C<< Module::Metadata->new_from_file >>.

=head1 CONFIGURATION AND ENVIRONMENT

Dist::Zilla::Role::ModuleInfo requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Module::Metadata>.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Dist-Zilla-Plugins-CJM AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Dist-Zilla-Plugins-CJM >>.

You can follow or contribute to Dist-Zilla-Plugins-CJM's development at
L<< https://github.com/madsen/dist-zilla-plugins-cjm >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
