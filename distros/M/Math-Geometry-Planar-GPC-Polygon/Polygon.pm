package Math::Geometry::Planar::GPC::Polygon;
our $VERSION = '0.05';

use 5.006;
use strict;
use warnings;


BEGIN {
	my $dir = __FILE__;
	$dir =~ s#.pm$#/#;
	our $functions = $dir . "functions.c";
	our $include = $dir . "include/";
	# print "functions at begin: $functions\n";
}


our $include;
use Inline (
	C => Config =>
	NAME => 'Math::Geometry::Planar::GPC::Polygon',
	INC => "-I$include",
	VERSION => '0.05',
	# BUILD_NOISY => 1,
	# FORCE_BUILD => 1,
	# CLEAN_AFTER_BUILD => 0,
	# WARNINGS => 1,
	# CCFLAGS => '-Wall',
	);
our $functions;
#print "functions in: $functions\n";
use Inline C => "$functions";

require Exporter;
our @ISA='Exporter';
our @EXPORT_OK = qw(
	new_gpc
	);

=pod

=head1 NAME

Math::Geometry::Planar::GPC::Polygon - OO wrapper to gpc library

=head1 Status

Successfully used in minor production use under perl 5.6.1 and 5.8.3.
Your mileage may vary  (see NO WARRANTY.)

=head1 AUTHOR

  Eric L. Wilhelm
  ewilhelm at sbcglobal dot net
  http://pages.sbcglobal.net/mycroft/

=head1 Copyright

Copyright 2004 Eric L. Wilhelm

=head1 License

This module and its C source code (functions.c) are distributed under
the same terms as Perl.  See the Perl source package for details.

You may use this software under one of the following licenses:

  (1) GNU General Public License
    (found at http://www.gnu.org/copyleft/gpl.html)
  (2) Artistic License
    (found at http://www.perl.com/pub/language/misc/Artistic.html)


The General Polygon Clipping library (gpc.c and gpc.h) is distributed as
"free for non-commercial use".  See gpc.c for details.  A copy of these
files has been included with this distribution strictly for convenience
purposes, but YOU ARE RESPONSIBLE FOR ADHERING TO BOTH THE GPC LICENSE
AND THE LICENSE OF THIS MODULE.  Note that the C library is authored by
Alan Murta.

You may want to check the GPC home page for a more current version:

  http://www.cs.man.ac.uk/aig/staff/alan/software/

=head1 Portability

This module successfully compiles on i386 and solaris architectures
according to the cpan testers results.  Hopefully, versions after 0.04
will work on WIN32.  I don't have any non-linux machines, so feel free
to send patches.

=head1 NO WARRANTY

This code comes with ABSOLUTELY NO WARRANTY of any kind.

=head1 Changes

  0.01 - First public release.
  0.02 - Added API documentation.
  0.03 - Fix to allocation error.
         Possibly Fixed WIN32 compile problem?
  0.04 - Twiddling with WIN32 compile problem (last try)
  0.05 - Corrected license statements.

=cut
########################################################################

=head1 Constructors

=head2 new

Traditional constructor, returns a blessed reference to the underlying C struct. 

  use Math::Geometry::Planar::GPC::Polygon;
  my $gpc = Math::Geometry::Planar::GPC::Polygon->new();

=head2 new_gpc

An optionally imported constructor, for those of you who don't like to
type so much.

  use Math::Geometry::Planar::GPC::Polygon qw(new_gpc);
  my $gpc = new_gpc();

=cut
sub new_gpc {
	my $class = __PACKAGE__;
	return(new($class));
} # end subroutine new_gpc definition
########################################################################

=head1 Bound Functions

These are the functions provide by the Inline-C code.  See functions.c
in the source package for intimate details.

=cut
########################################################################

=head2 from_file

Loads a from a file into your gpc object.  See the GPC library
documentation for details.

  $gpc->from_file($filename, $want_hole);

=cut

=head2 to_file

Writes to a file.

  $gpc->to_file($filename, $want_hole);

=cut

=head2 clip_to

Clips the $gpc object to the $othergpc object.

$action may be any of the following:

  INTERSECT
  DIFFERENCE
  UNION

  $gpc->clip_to($othergpc, $action);

Be wary.  This interface may need to change.

=cut

=head2 add_polygon

Adds a polygon to the gpc object.  @points is a list of array references
which describe the point of the polygon.  $hole is 1 or 0 (0 to not add
a hole.)

  $gpc->add_polygon(\@points, $hole);

=cut

=head2 get_polygons

Gets the polygons from the gpc object.  I'm not sure how to tell you if
they are holes or not.  @pgons will be a list of refs to lists of refs.

  @pgons = $gpc->get_polygons();

=cut

########################################################################


=head1 Helper Functions

Pure-perl implementation from here down.

=cut
########################################################################

=head2 as_string

  $gpc->as_string();

=cut
sub as_string {
	my $self = shift;
	my @pgons = $self->get_polygons();
	my @strings;
	foreach my $pgon (@pgons) {
		# print "pgon is $pgon\n";
		# print "@$pgon\n";
		my @pts;
		foreach my $pt (@$pgon) {
			push(@pts, join(", ", map({sprintf("%0.3f", $_)} @$pt)));
		}
		push(@strings, "\t" . join("\n\t", @pts));
	}
	return(join("\n\n", @strings));
} # end subroutine as_string definition
########################################################################
1;
__END__
