use 5.012;
use warnings;

# ABSTRACT: Foreign function interface to PROJ coordinate transformation software
package Geo::LibProj::FFI 0.04;


use Alien::proj 1.07;
use FFI::Platypus 1.00;
use FFI::C 0.08;
use Convert::Binary::C 0.04;

use Exporter::Easy (TAGS => [
	context => [qw(
		proj_context_create
		proj_context_destroy
		proj_context_use_proj4_init_rules
	)],
	setup => [qw(
		proj_create
		proj_create_argv
		proj_create_crs_to_crs
		proj_create_crs_to_crs_from_pj
		proj_normalize_for_visualization
		proj_destroy
	)],
	area => [qw(
		proj_area_create
		proj_area_set_bbox
		proj_area_destroy
	)],
	transform => [qw(
		proj_trans
	)],
	error => [qw(
		proj_context_errno
		proj_errno
		proj_errno_set
		proj_errno_reset
		proj_errno_restore
		proj_errno_string
		proj_context_errno_string
	)],
	logging => [qw(
		proj_log_level
		proj_log_func
	)],
	info => [qw(
		proj_info
		proj_pj_info
		proj_grid_info
		proj_init_info
	)],
	lists => [qw(
		proj_list_operations
		proj_list_ellps
		proj_list_units
		proj_list_angular_units
		proj_list_prime_meridians
	)],
	distance => [qw(
		proj_lp_dist
		proj_lpz_dist
		proj_xy_dist
		proj_xyz_dist
		proj_geod
	)],
	misc => [qw(
		proj_coord
	)],
	const => [qw(
		PJ_DEFAULT_CTX
		PJ_LOG_NONE PJ_LOG_ERROR PJ_LOG_DEBUG PJ_LOG_TRACE PJ_LOG_TELL
		PJ_FWD PJ_IDENT PJ_INV
	)],
	all => [qw(
		:context
		:setup
		:area
		:transform
		:error
		:logging
		:info
		:lists
		:distance
		:misc
		:const
		proj_cleanup
	)],
]);

my $ffi = FFI::Platypus->new(
	api => 1,
	lang => 'C',
	lib => [Alien::proj->dynamic_libs],
);
FFI::C->ffi($ffi);

my $c = Convert::Binary::C->new;

$ffi->load_custom_type('::StringPointer' => 'string_pointer');
# string* should also work, but doesn't in $ffi->cast
$ffi->load_custom_type('::StringArray' => 'string_array');
# string[] should also work, but causes strlen in proj_create_crs_to_crs_from_pj to segfault



# based on proj.h version 8.0.0

# ***************************************************************************
# Copyright (c) 2016, 2017, Thomas Knudsen / SDFE
# Copyright (c) 2018, Even Rouault
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO COORD SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
# ***************************************************************************

# C API new generation

$ffi->type('opaque' => 'PJ_AREA');

# Data type for projection/transformation information
$ffi->type('opaque' => 'PJ');  # the PJ object herself

# Data types for list of operations, ellipsoids, datums and units used in PROJ.4
$c->parse(<<ENDC);
struct PJ_LIST {
	const char  *id;                /* projection keyword */
	void        *(*proj)(void *);   /* projection entry point */
	const char  * const *descr;     /* description text */
};
ENDC
$ffi->custom_type( 'PJ_OPERATIONS' => {
	native_to_perl => sub {
		my ($ptr) = @_;
		my $size = $c->sizeof('PJ_LIST');
		my @list;
		while () {
			$ptr += $size;
			my $item = $c->unpack('PJ_LIST', $ffi->cast( 'opaque' => "record($size)*", $ptr ));
			last unless $item->{id};
			$item->{id} = $ffi->cast( 'opaque' => 'string', $item->{id} );
			$item->{descr} = $ffi->cast( 'opaque' => 'string_pointer', $item->{descr} );
			push @list, $item;
		}
		return \@list;
	},
});

sub _unpack_list {
	my ($type, $ptr) = @_;
	my $size = $c->sizeof($type);
	my @list;
	while () {
		my $item = $c->unpack($type, $ffi->cast( 'opaque' => "record($size)*", $ptr ));
		last unless $item->{id};
		$item->{$_} = $ffi->cast( 'opaque' => 'string', $item->{$_} )
			for grep { $c->typeof("$type.$_") eq 'char *' } keys %$item;
		push @list, $item;
		$ptr += $size;
	}
	return \@list;
}

$c->parse(<<ENDC);
struct PJ_ELLPS {
	const char  *id;    /* ellipse keyword name */
	const char  *major; /* a= value */
	const char  *ell;   /* elliptical parameter */
	const char  *name;  /* comments */
};
ENDC
$ffi->custom_type( 'PJ_ELLPS' => {
	native_to_perl => sub { _unpack_list(PJ_ELLPS => @_) },
});

$c->parse(<<ENDC);
struct PJ_UNITS {
	const char  *id;        /* units keyword */
	const char  *to_meter;  /* multiply by value to get meters */
	const char  *name;      /* comments */
	double      factor;     /* to_meter factor in actual numbers */
};
ENDC
$ffi->custom_type( 'PJ_UNITS' => {
	native_to_perl => sub { _unpack_list(PJ_UNITS => @_) },
});

$c->parse(<<ENDC);
struct PJ_PRIME_MERIDIANS {
	const char  *id;        /* prime meridian keyword */
	const char  *defn;      /* offset from greenwich in DMS format. */
};
ENDC
$ffi->custom_type( 'PJ_PRIME_MERIDIANS' => {
	native_to_perl => sub { _unpack_list(PJ_PRIME_MERIDIANS => @_) },
});


# Geodetic, mostly spatiotemporal coordinate types
{
	package Geo::LibProj::FFI::PJ_XYZT 0.04;
	sub new { Geo::LibProj::FFI::PJ_COORD->_new($_[1], qw{ x y z t }) }
	package Geo::LibProj::FFI::PJ_UVWT 0.04;
	sub new { Geo::LibProj::FFI::PJ_COORD->_new($_[1], qw{ u v w t })->uvwt }
	package Geo::LibProj::FFI::PJ_LPZT 0.04;
	sub new { Geo::LibProj::FFI::PJ_COORD->_new($_[1], qw{ lam phi z t }) }
	package Geo::LibProj::FFI::PJ_OPK 0.04;
	sub new { Geo::LibProj::FFI::PJ_COORD->_new($_[1], qw{ o p k 0 }) }
	# Rotations: omega, phi, kappa
	package Geo::LibProj::FFI::PJ_ENU 0.04;
	sub new { Geo::LibProj::FFI::PJ_COORD->_new($_[1], qw{ e n u 0 }) }
	# East, North, Up
	package Geo::LibProj::FFI::PJ_GEOD 0.04;
	sub new { Geo::LibProj::FFI::PJ_COORD->_new($_[1], qw{ s a1 a2 0 }) }
	# Geodesic length, fwd azi, rev azi
}

# Classic proj.4 pair/triplet types - moved into the PJ_ name space
{
	package Geo::LibProj::FFI::PJ_UV 0.04;
	sub new { Geo::LibProj::FFI::PJ_COORD->_new($_[1], qw{ u v 0 0 })->uv }
	package Geo::LibProj::FFI::PJ_XY 0.04;
	sub new { Geo::LibProj::FFI::PJ_COORD->_new($_[1], qw{ x y 0 0 }) }
	package Geo::LibProj::FFI::PJ_LP 0.04;
	sub new { Geo::LibProj::FFI::PJ_COORD->_new($_[1], qw{ lam phi 0 0 }) }
	
	package Geo::LibProj::FFI::PJ_XYZ 0.04;
	sub new { Geo::LibProj::FFI::PJ_COORD->_new($_[1], qw{ x y z 0 }) }
	package Geo::LibProj::FFI::PJ_UVW 0.04;
	sub new { Geo::LibProj::FFI::PJ_COORD->_new($_[1], qw{ u v w 0 })->uvw }
	package Geo::LibProj::FFI::PJ_LPZ 0.04;
	sub new { Geo::LibProj::FFI::PJ_COORD->_new($_[1], qw{ lam phi z 0 }) }
}


# Data type for generic geodetic 3D data plus epoch information
# Avoid preprocessor renaming and implicit type-punning: Use a union to make it explicit
{
	# FFI::C::Union can't be passed by value due to limitations within
	# FFI::Platypus. Workaround: Use a Record with some additional Perl
	# glue. The performance may not be perfect, but seems satisfactory.
	
	package Geo::LibProj::FFI::PJ_COORD 0.04;
	use FFI::Platypus::Record;
	record_layout_1(qw{ double x double y double z double t });
	sub _new {
		my ($class, $values, @params) = @_;
		$values //= {};
		@params = map { $values->{$_} // 0 } @params;
		return $class->new({ 'x' => $params[0], 'y' => $params[1], 'z' => $params[2], 't' => $params[3] });
	}
	sub _set {
		my ($self, $values, @params) = @_;
		if (ref $values eq 'HASH') {
			@params = map { $values->{$_} } @params;
		}
		else {
			@params = map { eval "\$values->$_" } grep !/^0$/, @params;  ## no critic (ProhibitStringyEval)
		}
		$self->v(\@params);
	}
	
	# union members:
	sub v {  # First and foremost, it really is "just 4 numbers in a vector"
		my ($self, $vector) = @_;
		return [ $self->x(), $self->y(), $self->z(), $self->t() ] unless $vector;
		$self->x($vector->[0] // 0);
		$self->y($vector->[1] // 0);
		$self->z($vector->[2] // 0);
		$self->t($vector->[3] // 0);
	}
	sub xyzt { $_[1] ? $_[0]->_set($_[1], qw{ x   y   z  t }) : shift }
	sub uvwt { $_[1] ? $_[0]->_set($_[1], qw{ u   v   w  t }) : Geo::LibProj::FFI::PJ_UVWT->_new(shift) }
	sub lpzt { $_[1] ? $_[0]->_set($_[1], qw{ lam phi z  t }) : shift }
	sub geod { $_[1] ? $_[0]->_set($_[1], qw{ s   a1  a2 0 }) : shift }
	sub opk  { $_[1] ? $_[0]->_set($_[1], qw{ o   p   k  0 }) : shift }
	sub enu  { $_[1] ? $_[0]->_set($_[1], qw{ e   n   u  0 }) : shift }
	sub xyz  { $_[1] ? $_[0]->_set($_[1], qw{ x   y   z  0 }) : shift }
	sub uvw  { $_[1] ? $_[0]->_set($_[1], qw{ u   v   w  0 }) : Geo::LibProj::FFI::PJ_UVWT->_new(shift) }
	sub lpz  { $_[1] ? $_[0]->_set($_[1], qw{ lam phi z  0 }) : shift }
	sub xy   { $_[1] ? $_[0]->_set($_[1], qw{ x   y   0  0 }) : shift }
	sub uv   { $_[1] ? $_[0]->_set($_[1], qw{ u   v   0  0 }) : Geo::LibProj::FFI::PJ_UVWT->_new(shift) }
	sub lp   { $_[1] ? $_[0]->_set($_[1], qw{ lam phi 0  0 }) : shift }
	
	# struct members:
	# PJ_UV* need their own package due to name collisions.
	# The other types are implemented by the PJ_COORD package.
	
	sub lam { shift->x( @_ ) }
	sub o   { shift->x( @_ ) }
	sub e   { shift->x( @_ ) }
	sub s   { shift->x( @_ ) }
	
	sub phi { shift->y( @_ ) }
	sub p   { shift->y( @_ ) }
	sub n   { shift->y( @_ ) }
	sub a1  { shift->y( @_ ) }
	
	sub k   { shift->z( @_ ) }
	sub u   { shift->z( @_ ) }
	sub a2  { shift->z( @_ ) }
	
	package Geo::LibProj::FFI::PJ_UVWT;
	sub _new { bless \$_[1], $_[0] }
	sub u { ${shift()}->x( @_ ) }
	sub v { ${shift()}->y( @_ ) }
	sub w { ${shift()}->z( @_ ) }
	sub t { ${shift()}->t( @_ ) }
	
}
$ffi->type('record(Geo::LibProj::FFI::PJ_COORD)' => 'PJ_COORD');


{
	package Geo::LibProj::FFI::PJ_INFO 0.04;
	use FFI::Platypus::Record;
	record_layout_1(
		int    => 'major',       # Major release number
		int    => 'minor',       # Minor release number
		int    => 'patch',       # Patch level
		string => 'release',     # Release info. Version + date
		string => 'version',     # Full version number
		string => 'searchpath',  # Paths where init and grid files are
		                         # looked for. Paths are separated by
		                         # semi-colons on Windows, and colons
		                         # on non-Windows platforms.
		opaque => 'paths',
		size_t => 'path_count',
	);
}
$ffi->type('record(Geo::LibProj::FFI::PJ_INFO)' => 'PJ_INFO');

{
	package Geo::LibProj::FFI::PJ_PROJ_INFO 0.04;
	use FFI::Platypus::Record;
	record_layout_1(
		string => 'id',           # Name of the projection in question
		string => 'description',  # Description of the projection
		string => 'definition',   # Projection definition
		int    => 'has_inverse',  # 1 if an inverse mapping exists, 0 otherwise
		double => 'accuracy',     # Expected accuracy of the transformation. -1 if unknown.
	);
}
$ffi->type('record(Geo::LibProj::FFI::PJ_PROJ_INFO)' => 'PJ_PROJ_INFO');

{
	package Geo::LibProj::FFI::PJ_GRID_INFO 0.04;
	use FFI::Platypus::Record;
	record_layout_1(
		'string(32)'  => 'gridname_NUL',         # name of grid
		'string(260)' => 'filename_NUL',         # full path to grid
		'string(8)'   => 'format_NUL',           # file format of grid
		double => 'left',   double => 'lower',   # Coordinates of lower left corner
		double => 'right',  double => 'upper',   # Coordinates of upper right corner
		int    => 'n_lon',  int    => 'n_lat',   # Grid size
		double => 'cs_lon', double => 'cs_lat',  # Cell size of grid
	);
	sub gridname { my $s = shift->gridname_NUL; $s =~ s/\0+$//; $s }
	sub filename { my $s = shift->filename_NUL; $s =~ s/\0+$//; $s }
	sub format   { my $s = shift->format_NUL;   $s =~ s/\0+$//; $s }
	sub lowerleft  { Geo::LibProj::FFI::PJ_LP->new({ lam => $_[0]->left,  phi => $_[0]->lower }) }
	sub upperright { Geo::LibProj::FFI::PJ_LP->new({ lam => $_[0]->right, phi => $_[0]->upper }) }
}
$ffi->type('record(Geo::LibProj::FFI::PJ_GRID_INFO)' => 'PJ_GRID_INFO');

{
	package Geo::LibProj::FFI::PJ_INIT_INFO 0.04;
	use FFI::Platypus::Record;
	record_layout_1(
		'string(32)'  => 'name_NUL',        # name of init file
		'string(260)' => 'filename_NUL',    # full path to the init file.
		'string(32)'  => 'version_NUL',     # version of the init file
		'string(32)'  => 'origin_NUL',      # origin of the file, e.g. EPSG
		'string(16)'  => 'lastupdate_NUL',  # Date of last update in YYYY-MM-DD format
	);
	sub name       { my $s = shift->name_NUL;       $s =~ s/\0+$//; $s }
	sub filename   { my $s = shift->filename_NUL;   $s =~ s/\0+$//; $s }
	sub version    { my $s = shift->version_NUL;    $s =~ s/\0+$//; $s }
	sub origin     { my $s = shift->origin_NUL;     $s =~ s/\0+$//; $s }
	sub lastupdate { my $s = shift->lastupdate_NUL; $s =~ s/\0+$//; $s }
}
$ffi->type('record(Geo::LibProj::FFI::PJ_INIT_INFO)' => 'PJ_INIT_INFO');

FFI::C->enum('PJ_LOG_LEVEL', [
	[PJ_LOG_NONE  => 0],
	[PJ_LOG_ERROR => 1],
	[PJ_LOG_DEBUG => 2],
	[PJ_LOG_TRACE => 3],
	[PJ_LOG_TELL  => 4],
	[PJ_LOG_DEBUG_MAJOR => 2],  # for proj_api.h compatibility
	[PJ_LOG_DEBUG_MINOR => 3],  # for proj_api.h compatibility
], {rev => 'int'});

# The context type - properly namespaced synonym for pj_ctx
$ffi->type('opaque' => 'PJ_CONTEXT');

# A P I

# The objects returned by the functions defined in this section have minimal
# interaction with the functions of the
# iso19111_functions section, and vice versa. See its introduction
# paragraph for more details.

# Functionality for handling thread contexts
use constant PJ_DEFAULT_CTX => 0;
$ffi->attach( proj_context_create => [] => 'PJ_CONTEXT');
$ffi->attach( proj_context_destroy => ['PJ_CONTEXT'] => 'void');

$ffi->attach( proj_context_use_proj4_init_rules => [qw( PJ_CONTEXT int )] => 'void' );

# Manage the transformation definition object PJ
$ffi->attach( proj_create => [qw( PJ_CONTEXT string )] => 'PJ' );
$ffi->attach( proj_create_argv => [qw( PJ_CONTEXT int string_array )] => 'PJ');
$ffi->attach( proj_create_crs_to_crs => [qw( PJ_CONTEXT string string PJ_AREA )] => 'PJ');
$ffi->attach( proj_create_crs_to_crs_from_pj => [qw( PJ_CONTEXT PJ PJ PJ_AREA string_array )] => 'PJ', sub{
	$_[0]->( @_[1..4], $_[5] || [] );  # StringArray won't accept NULL
});
$ffi->attach( proj_normalize_for_visualization => ['PJ_CONTEXT', 'PJ'] => 'PJ');
$ffi->attach( proj_destroy => ['PJ'] => 'void');


$ffi->attach( proj_area_create => [] => 'PJ_AREA');
$ffi->attach( proj_area_set_bbox => [qw( PJ_AREA double double double double )] => 'void');
$ffi->attach( proj_area_destroy => [qw( PJ_AREA )] => 'void');

# Apply transformation to observation - in forward or inverse direction
FFI::C->enum('PJ_DIRECTION', [
	[PJ_FWD   =>  1],  # Forward
	[PJ_IDENT =>  0],  # Do nothing
	[PJ_INV   => -1],  # Inverse
]);


$ffi->attach( proj_trans => ['PJ', 'PJ_DIRECTION', 'PJ_COORD'] => 'PJ_COORD');

# non-standard method (now discouraged; originally used by Perl cs2cs)
# (expects and returns a single point as array ref)
$ffi->attach( [proj_trans => '_trans'] => ['PJ', 'PJ_DIRECTION', 'PJ_COORD'] => 'PJ_COORD', sub {
	my ($sub, $pj, $dir, $coord) = @_;
	$sub->( $pj, $dir, proj_coord($coord->[0] // 0, $coord->[1] // 0, $coord->[2] // 0, $coord->[3] // 0) )->v;
});


# Initializers
$ffi->attach( proj_coord => [qw( double double double double )] => 'PJ_COORD');

# Geodesic distance between two points with angular 2D coordinates
$ffi->attach( proj_lp_dist => [qw( PJ PJ_COORD PJ_COORD )] => 'double');

# The geodesic distance AND the vertical offset
$ffi->attach( proj_lpz_dist => [qw( PJ PJ_COORD PJ_COORD )] => 'double');

# Euclidean distance between two points with linear 2D coordinates
$ffi->attach( proj_xy_dist => [qw( PJ_COORD PJ_COORD )] => 'double');

# Euclidean distance between two points with linear 3D coordinates
$ffi->attach( proj_xyz_dist => [qw( PJ_COORD PJ_COORD )] => 'double');

# Geodesic distance (in meter) + fwd and rev azimuth between two points on the ellipsoid
$ffi->attach( proj_geod => [qw( PJ PJ_COORD PJ_COORD )] => 'PJ_COORD');

# Set or read error level
$ffi->attach( proj_context_errno => ['PJ_CONTEXT'] => 'int');
$ffi->attach( proj_errno => ['PJ_CONTEXT'] => 'int');
$ffi->attach( proj_errno_set => ['PJ_CONTEXT', 'int'] => 'int');
$ffi->attach( proj_errno_reset => ['PJ_CONTEXT'] => 'int');
$ffi->attach( proj_errno_restore => ['PJ_CONTEXT', 'int'] => 'int');
$ffi->attach( proj_errno_string => ['int'] => 'string');  # deprecated. use proj_context_errno_string()
eval { $ffi->attach( proj_context_errno_string => ['PJ_CONTEXT', 'int'] => 'string'); 1 }
	or do { *proj_context_errno_string = sub { proj_errno_string($_[1]); } };

$ffi->attach( proj_log_level => ['PJ_CONTEXT', 'PJ_LOG_LEVEL'] => 'PJ_LOG_LEVEL');
$ffi->attach( proj_log_func => ['PJ_CONTEXT', 'opaque', '(opaque,int,string)->void'] => 'void', sub {
	my ($sub, $ctx, $app_data, $logf) = @_;
	my $closure = $ffi->closure( $app_data ? sub {
		my (undef, $level, $msg) = @_;
		$logf->($app_data, $level, $msg);
	} : $logf );
	$closure->sticky;
	$sub->($ctx, 0, $closure);
});

# Info functions - get information about various PROJ.4 entities
$ffi->attach( proj_info => [] => 'PJ_INFO');
$ffi->attach( proj_pj_info => ['PJ'] => 'PJ_PROJ_INFO');
$ffi->attach( proj_grid_info => ['string'] => 'PJ_GRID_INFO');
$ffi->attach( proj_init_info => ['string'] => 'PJ_INIT_INFO');

# List functions:
# Get lists of operations, ellipsoids, units and prime meridians.
$ffi->attach( proj_list_operations => [] => 'PJ_OPERATIONS');
$ffi->attach( proj_list_ellps => [] => 'PJ_ELLPS');
$ffi->attach( proj_list_units => [] => 'PJ_UNITS');
$ffi->attach( proj_list_angular_units => [] => 'PJ_UNITS');
$ffi->attach( proj_list_prime_meridians => [] => 'PJ_PRIME_MERIDIANS');

$ffi->attach( proj_cleanup => [] => 'void');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geo::LibProj::FFI - Foreign function interface to PROJ coordinate transformation software

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Geo::LibProj::FFI qw(:all);
 use Syntax::Keyword::Defer;
 
 my $ctx = proj_context_create()
     or die "Cannot create threading context";
 defer { proj_context_destroy($ctx); }
 
 my $pj = proj_create_crs_to_crs($ctx, "EPSG:25833", "EPSG:2198", undef)
     or die "Cannot create proj";
 defer { proj_destroy($pj); }
 
 ($easting, $northing) = ( 500_000, 6094_800 );
 $a = proj_coord( $easting, $northing, 0, 'Inf' );
 $b = proj_trans( $pj, PJ_FWD, $a );
 
 printf "Target: easting %.2f, northing %.2f\n",
     $b->enu->e, $b->enu->n;

See also the example script F<eg/pj_obs_api_mini_demo.pl>
in this distribution.

=head1 DESCRIPTION

This module is a foreign function interface to the
L<PROJ|https://proj.org/> coordinate transformation library.
Please see the PROJ library's
L<C function reference|https://proj.org/development/reference/functions.html>
for further documentation. You should be able to use those
S<C functions> as if they were Perl.

This module is functional, but incomplete.

=head1 FUNCTIONS

L<Geo::LibProj::FFI> currently offers the following functions.

Import all functions and constants by using the tag C<:all>.

=over

=item L<Threading contexts|https://proj.org/development/reference/functions.html#threading-contexts>

=over

=item * C<proj_context_create>

=item * C<proj_context_destroy>

=item * C<proj_context_use_proj4_init_rules>

=back

=item L<Transformation setup|https://proj.org/development/reference/functions.html#transformation-setup>

=over

=item * C<proj_create>

=item * C<proj_create_argv>

=item * C<proj_create_crs_to_crs>

=item * C<proj_create_crs_to_crs_from_pj>

=item * C<proj_normalize_for_visualization>

=item * C<proj_destroy>

=back

=item L<Area of interest|https://proj.org/development/reference/functions.html#area-of-interest>

=over

=item * C<proj_area_create>

=item * C<proj_area_set_bbox>

=item * C<proj_area_destroy>

=back

=item L<Coordinate transformation|https://proj.org/development/reference/functions.html#coordinate-transformation>

=over

=item * C<proj_trans>

=back

=item L<Error reporting|https://proj.org/development/reference/functions.html#error-reporting>

=over

=item * C<proj_context_errno>

=item * C<proj_errno>

=item * C<proj_errno_set>

=item * C<proj_errno_reset>

=item * C<proj_errno_restore>

=item * C<proj_errno_string>

=item * C<proj_context_errno_string>

=back

=item L<Logging|https://proj.org/development/reference/functions.html#logging>

=over

=item * C<proj_log_level>

=item * C<proj_log_func>

=back

=item L<Info functions|https://proj.org/development/reference/functions.html#info-functions>

=over

=item * C<proj_info>

=item * C<proj_pj_info>

=item * C<proj_grid_info>

=item * C<proj_init_info>

=back

=item L<Lists|https://proj.org/development/reference/functions.html#lists>

=over

=item * C<proj_list_operations>

=item * C<proj_list_ellps>

=item * C<proj_list_units>

=item * C<proj_list_angular_units>

=item * C<proj_list_prime_meridians>

=back

=item L<Distances|https://proj.org/development/reference/functions.html#distances>

=over

=item * C<proj_lp_dist>

=item * C<proj_lpz_dist>

=item * C<proj_xy_dist>

=item * C<proj_xyz_dist>

=item * C<proj_geod>

=back

=item L<Various|https://proj.org/development/reference/functions.html#various>

=over

=item * C<proj_coord>

=back

=item L<Cleanup|https://proj.org/development/reference/functions.html#cleanup>

=over

=item * C<proj_cleanup>

=back

=back

=head1 DATA TYPES

The PROJ library uses numerous composite data types. When
working with L<Geo::LibProj::FFI>, members of S<C C<struct>>
and C<union> types may be accessed B<for reading> by calling
methods on these composites. For example, to output the
S<X coordinate> of a C<PJ_COORD> value, you could simply
do C<< print $coord->xyz->x(); >>. Please see the
L<PROJ data type reference|https://proj.org/development/reference/datatypes.html>
for further documentation.

As of version 0.04 of this module, the interface I<for modifying>
values of composite types from Perl is still evolving. Therefore,
values of S<C C<struct>> and C<union> types are best treated as
B<immutable> by Perl users. For the same reason, it is not
recommended to try and create new values of such types using Perl
constructors; instead, users should use PROJ functions to create
such values wherever possible.

That said, it is already now fully I<possible> to modify such
values and to construct them using C<new()>; it's just not yet
I<recommended> to do so. Consider this code example to create
and modify a C<PJ_COORD> value:

 # discouraged:
 # (not guaranteed to work in future versions)
 $coord = Geo::LibProj::FFI::PJ_COORD->new({
     xy => { x => 12, y => 34 }
 });
 $coord->xyz->z( 100 );
 
 # recommended:
 $coord = proj_coord( 12, 34, 0, 0 );
 $vector = $coord->v;
 $vector->[2] = 100;
 $coord = proj_coord( @$vector );

=head1 BUGS AND LIMITATIONS

PROJ makes heavy use of S<C C<union>> pass-by-value, which is
unsupported by L<FFI::Platypus>. In earlier versions of this module,
the workaround for working with C<PJ_COORD> values was quite slow.
This performance issue has been addressed as of S<version 0.03.>

Some implementation details of the glue this module provides
may change in future, for example to better match the API or to
increase performance. Should you decide to
use this module in production, it would be wise to watch the
L<GitHub project|https://github.com/johannessen/proj-perl-ffi>
for changes, at least until the version has reached 1.00.

This module is designed to be used with PROJ S<version 8>.
PROJ versions as far back as 6.2.0 should work as well;
please report any issues.

=head1 SEE ALSO

=over

=item * L<Geo::LibProj::cs2cs>

=item * L<Geo::Proj4>

=item * PROJ C API Reference:
L<Data types|https://proj.org/development/reference/datatypes.html>,
L<Functions|https://proj.org/development/reference/functions.html>

=back

=head1 API LICENSE

The API this module gives access to is the C<proj.h> API,
which is available under the terms of the Expat MIT license.

 Copyright (c) 2016, 2017, Thomas Knudsen / SDFE
 Copyright (c) 2018, Even Rouault

The API designers didn't write this Perl module,
and the module author didn't design the API.

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
