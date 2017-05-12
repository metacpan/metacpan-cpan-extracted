# Image::SubImageFind ($Id$)
# 
# Copyright (C) 2010-2011  Dennis K. Paulsen <ctrondlp@cpan.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://www.gnu.org/licenses>.
#
package Image::SubImageFind;

use 5.012003;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Image::SubImageFind ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 
	'all' => [ qw(
		FindSubImage
	) ],
	'CONST' => [qw(CM_DWVB CM_GPC)],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
push(@EXPORT_OK, @{ $EXPORT_TAGS{'CONST'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';

# Available compare methods
sub CM_DWVB() { 0; };
sub CM_GPC() { 1; };

require XSLoader;
XSLoader::load('Image::SubImageFind', $VERSION);

# Preloaded methods go here.

sub FindSubImage {
    my $hayfile = shift;
    my $needlefile = shift;
	my $method = shift || 0;
    my $finder = new Image::SubImageFind($hayfile, $needlefile, $method);
    my ($x, $y, $retval) = $finder->GetCoordinates();
    return ($x, $y, $retval);
}

1;
__END__

=head1 NAME

Image::SubImageFind - Perl extension for locating a sub-image within an image

=head1 SYNOPSIS

  use Image::SubImageFind qw/FindSubImage/;

  #  First parameter is the larger image file (HayStack)
  #  Second parameter is the sub-image file to locate within the larger image (Needle)
  my ($x, $y) = FindSubImage("./haystackfile.png", "./needlefile.jpg");
  if ($x > 0 || $y > 0) {
      print "Found sub-image at: $x X $y\n";
  } else {
      print "Could not find sub-image.\n";
  }

  #  Alternatively, you can use the emerging object oriented syntax.
  my $finder = new Image::SubImageFind("./haystackfile.png", "./needlefile.png");
  my ($x, $y) = $finder->GetCoordinates();
  print "$x X $yn";

  #  Another example; which may allow for more flexibility.
  my $finder = new Image::SubImageFind("./haystackfile.png");
  my ($x, $y) = $finder->GetCoordinates("./needlefile.png");
  print "$x X $yn";

  #  You can also specify an alternate comparison method.  The default is DWVB; which
  #  uses an adaptive filter for the correct localization of subimages.  
  #
  #  Another is called GPC; which is just a generic pixel compare, but also supports a
  #  delta threshold (using GetMaxDelta and SetMaxDelta).
  use Image::SubImageFind qw/:CONST/;

  my $finder = new Image::SubImageFind("./haystackfile.png", "./needlefile.png", CM_DWVB);
  # OR
  my $finder = new Image::SubImageFind("./haystackfile.png", "./needlefile.png", CM_GPC);
  # $finder->GetMaxDelta();
  # $finder->SetMaxDelta([DeltaValue]);   # 0 or greater, where 0 means no pixel difference
 
  
=head1 DESCRIPTION

Perl module to aide in locating a sub-image within an image.

=head2 EXPORT

None by default.


=head1 SEE ALSO

One of the underlying algorithms and originating code by Dr. Werner Van Belle (http://werner.yellowcouch.org/Papers/subimg/index.html)

=head1 AUTHOR

Dennis K. Paulsen, E<lt>ctrondlp@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 by Dennis K. Paulsen

Other portions are copyright their respective owners.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 of the License.

=cut
