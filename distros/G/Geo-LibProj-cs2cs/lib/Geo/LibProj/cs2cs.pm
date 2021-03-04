use 5.014;
use strict;
use warnings;

package Geo::LibProj::cs2cs;
# ABSTRACT: IPC interface to PROJ cs2cs
$Geo::LibProj::cs2cs::VERSION = '1.03';

use Carp qw(carp croak);
use File::Basename qw(basename);
use File::Spec;
use Scalar::Util 1.10 qw(looks_like_number);

use IPC::Run3 qw(run3);


our $CMD = 'cs2cs';
our @PATH = ();
BEGIN {
	# optional modules
	eval "require Alien::proj" or eval "require Alien::Proj4";
}
eval { unshift @PATH, File::Spec->catdir(Alien::proj->dist_dir, 'bin') };
eval { push @PATH, undef, File::Spec->catdir(Alien::Proj4->dist_dir, 'bin') };


# default stringification formats for cs2cs stdin and stdout
our $FORMAT_IN  = '%.15g';
our $FORMAT_OUT = '%.12g';

our %PARAMS = (
	-f => $FORMAT_OUT,
);


sub new {
	my $class = shift;
	
	my ($source_crs, $target_crs, $user_params);
	if ( ref($_[0]) eq 'HASH' ) {
		($user_params, $source_crs, $target_crs) = @_;
	}
	else {
		($source_crs, $target_crs, $user_params) = @_;
	}
	
	my $self = bless {}, $class;
	
	my $params = { %PARAMS, defined $user_params ? %$user_params : () };
	$self->_special_params($params);
	$self->{format_in} = $FORMAT_IN;
	
	# assemble cs2cs call line
	for my $key (keys %$params) {
		delete $params->{$key} unless defined $params->{$key};
	}
	my @source_crs = split m/ /, $source_crs // 'undef';
	my @target_crs = split m/ /, $target_crs // 'undef';
	$self->{cmd} = $self->_cmd();
	$self->{call} = [$self->{cmd}, %$params, @source_crs, '+to', @target_crs, '-'];
	
	$self->_ffi_init($source_crs, $target_crs, $params);
	
	return $self;
}


sub _special_params {
	my ($self, $params) = @_;
	
	# support -d even for older cs2cs versions
	if (defined $params->{-d} && defined $params->{-f}) {
		$params->{-f} = '%.' . (0 + $params->{-d}) . 'f';
		delete $params->{-d};
	}
	
	croak "-E is unsupported" if defined $params->{'-E'};
	croak "-t is unsupported" if defined $params->{'-t'};
	croak "-v is unsupported" if defined $params->{'-v'};
	
	# -w3 must be supplied as a single parameter to cs2cs
	if (defined $params->{-w}) {
		$params->{"-w$params->{-w}"} = '';
		delete $params->{-w};
	}
	if (defined $params->{-W}) {
		$params->{"-W$params->{-W}"} = '';
		delete $params->{-W};
	}
	
	$self->{ffi} = $INC{'Geo/LibProj/FFI.pm'}
	               && ( $params->{XS} || ! defined $params->{XS} );
	$self->{ffi_warn} = $params->{XS};
	delete $params->{XS};
}


sub _cmd {
	# try to find the cs2cs binary
	foreach my $path (@PATH) {
		if (defined $path) {
			my $cmd = File::Spec->catfile($path, $CMD);
			return $cmd if -e $cmd;
		}
		else {
			# when the @PATH element is undefined, try the env PATH
			eval { run3 [$CMD, '-lp'], \undef, \undef, \undef };
			return $CMD if ! $@ && $? == 0;
		}
	}
	
	# no luck; let's just hope it'll be on the PATH somewhere
	return $CMD;
}


sub _ffi_init {
	my ($self, $source_crs, $target_crs, $params) = @_;
	
	carp "Geo::LibProj::FFI is not loaded; falling back to IPC mode" if $self->{ffi_warn} && ! $self->{ffi};
	return unless $self->{ffi};
	
	my @params = grep {
		$_ eq '-f'
		? defined $params->{$_} && $params->{$_} ne $FORMAT_OUT
		: defined $params->{$_}
	} keys %$params;
	carp "cs2cs control parameters are unsupported in XS mode; falling back to IPC mode" if $self->{ffi_warn} && @params;
	return $self->{ffi} = 0 if @params;
	
	my $ctx = $self->{ffi_ctx} = Geo::LibProj::FFI::proj_context_create();
	carp "proj_context_create() failed; falling back to IPC mode" if $self->{ffi_warn} && ! $ctx;
	return $self->{ffi} = 0 if ! $ctx;
	
	Geo::LibProj::FFI::proj_context_use_proj4_init_rules($ctx, 1);
	
	my $pj = $self->{ffi_pj} = Geo::LibProj::FFI::proj_create_crs_to_crs(
			$ctx, $source_crs, $target_crs, undef );
	carp "proj_create_crs_to_crs() failed; falling back to IPC mode" if $self->{ffi_warn} && ! $pj;
	return $self->{ffi} = 0 if ! $pj;
}


sub DESTROY {
	my ($self) = @_;
	
	Geo::LibProj::FFI::proj_destroy($self->{ffi_pj}) if $self->{ffi_pj};
	Geo::LibProj::FFI::proj_context_destroy($self->{ffi_ctx}) if $self->{ffi_ctx};
	$self->{ffi_pj} = $self->{ffi_ctx} = 0;
}


sub _ipc_error_check {
	my ($self, $eval_err, $os_err, $code, $stderr) = @_;
	
	my $cmd = $CMD;
	if (ref $self) {
		$self->{stderr} = $stderr;
		$self->{status} = $code >> 8;
	}
	
	$stderr =~ s/^(.*\S)\s*\z/: $1/s if length $stderr;
	croak "`$cmd` failed to execute: $os_err" if $code == -1;
	croak "`$cmd` died with signal " . ($code & 0x7f) . $stderr if $code & 0x7f;
	croak "`$cmd` exited with status " . ($code >> 8) . $stderr if $code;
	croak $eval_err =~ s/\s+\z//r if $eval_err;
}


sub _format {
	my ($self, $value) = @_;
	
	return sprintf $self->{format_in}, $value if looks_like_number $value;
	return $value;
}


sub transform {
	my ($self, @source_points) = @_;
	
	return $self->_ffi_transform(@source_points) if $self->{ffi};
	
	my @in = ();
	foreach my $i (0 .. $#source_points) {
		my $p = $source_points[$i];
		push @in,   $self->_format($p->[0] || 0) . " "
		          . $self->_format($p->[1] || 0) . " "
		          . $self->_format($p->[2] || 0) . " $i";
	}
	my $in = join "\n", @in;
	
	my @out = ();
	my $err = '';
	eval {
		local $/ = "\n";
		run3 $self->{call}, \$in, \@out, \$err;
	};
	$self->_ipc_error_check($@, $!, $?, $err);
	
	my @target_points = ();
	foreach my $line (@out) {
		next unless $line =~ m{\s(\d+)\s*$}xa;
		my $aux = $source_points[$1]->[3];
		next unless $line =~ m{^\s* (\S+) \s+ (\S+) \s+ (\S+) \s}xa;
		my @p = defined $aux ? ($1, $2, $3, $aux) : ($1, $2, $3);
		
		foreach my $j (0..2) {
			$p[$j] = 0 + $p[$j] if looks_like_number $p[$j];
		}
		
		push @target_points, \@p;
	}
	
	if ( (my $s = @source_points) != (my $t = @target_points) ) {
		croak "Source/target point count doesn't match ($s/$t): Assertion failed";
	}
	
	return @target_points if wantarray;
	return $target_points[0] if @target_points < 2;
	croak "transform() with list argument prohibited in scalar context";
}


sub _ffi_transform {
	my ($self, @source_points) = @_;
	
	my @target_points = map {
		my $p = Geo::LibProj::FFI::_trans( $self->{ffi_pj}, 1, [$_->[0], $_->[1], $_->[2], 'Inf'] );
		$p->[3] = $_->[3];
		delete $p->[3] unless defined $p->[3];
		$p;
	} @source_points;
	
	return @target_points if wantarray;
	return $target_points[0] if @target_points < 2;
	croak "transform() with list argument prohibited in scalar context";
}


sub version {
	my ($self) = @_;
	
	my $ffi = ref $self ? $self->{ffi} : $INC{'Geo/LibProj/FFI.pm'};
	return Geo::LibProj::FFI::proj_info()->version if $ffi;
	
	my $out = '';
	eval {
		run3 [ $self->_cmd ], \undef, \$out, \$out;
	};
	$self->_ipc_error_check($@, $!, $?, '');
	
	return $1 if $out =~ m/\b(\d+\.\d+(?:\.\d\w*)?)\b/;
	return $out;
}


sub xs { shift->{ffi} }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geo::LibProj::cs2cs - IPC interface to PROJ cs2cs

=head1 VERSION

version 1.03

=head1 SYNOPSIS

 use Geo::LibProj::cs2cs;
 use Geo::LibProj::FFI;  # optional module - see below
 
 $cs2cs = Geo::LibProj::cs2cs->new("EPSG:25833" => "EPSG:4326");
 $point = $cs2cs->transform( [500_000, 6094_800] );  # UTM 33U
 # result geographic lat, lon: [55.0, 15.0]
 
 @points_utm = ([500_000, 6094_800], [504_760, 6093_880]);
 @points_geo = $cs2cs->transform( @points_geo );
 
 $params = {-r => ''};  # control parameter -r: reverse input coords
 $cs2cs = Geo::LibProj::cs2cs->new("EPSG:4326" => "EPSG:25833", $params);
 $point = $cs2cs->transform( [q(15d4'28"E), q(54d59'30"N)] );
 # result easting, northing: [504763.08827, 6093866.63099]
 
 # old PROJ string syntax
 $source_crs = '+init=epsg:4326';
 $target_crs = '+proj=merc +lon_0=110';
 $cs2cs = Geo::LibProj::cs2cs->new($source_crs => $target_crs);
 ...

=head1 DESCRIPTION

This module is a Perl L<interprocess communication|perlipc> interface
to the L<cs2cs(1)|https://proj.org/apps/cs2cs.html> utility, which
is a part of the L<PROJ|https://proj.org/> coordinate transformation
library.

Unlike L<Geo::Proj4>, this module is pure Perl. It does require the
PROJ library to be installed, but it does not use the PROJ API
S<via XS>. Instead, it communicates with the C<cs2cs> utility using
the standard input/output streams, just like you might do at a
command line. Data is formatted using C<sprintf> and parsed using
regular expressions.

As a result, this module may be expected to work with many different
versions of the PROJ library, whereas L<Geo::Proj4> is limited to
S<version 4> (at time of this writing).

Because the interprocess communication (IPC) with cs2cs(1) has
significant performance constraints, this module will try to emulate
the behaviour of cs2cs(1) using L<Geo::LibProj::FFI> if the latter
module is loaded. This emulation is much faster than IPC, but does
not support all features of cs2cs(1). See L</"XS MODE"> below.

=head1 METHODS

L<Geo::LibProj::cs2cs> implements the following methods.

=head2 new

 $cs2cs = Geo::LibProj::cs2cs->new($source_crs => $target_crs);

Construct a new L<Geo::LibProj::cs2cs> object that can transform
points from the specified source CRS to the target CRS (coordinate
reference system).

Each CRS may be specified using any method the PROJ version installed
on your system supports for the C<cs2cs> utility. The legacy "PROJ
string" format is currently supported on all PROJ versions:

 $source_crs = '+init=epsg:4326';
 $target_crs = '+proj=merc +lon_0=110';
 $cs2cs = Geo::LibProj::cs2cs->new($source_crs => $target_crs);

S<PROJ 6> and newer support additional formats to express a CRS,
such as a WKT string or an AUTHORITY:CODE. Note that the axis order
might differ between some of these choices. See your PROJ version's
L<cs2cs(1)|https://proj.org/apps/cs2cs.html> documentation for
details.

Control parameters may optionally be supplied to C<cs2cs> in a
hash ref using one of the following forms:

 $cs2cs = Geo::LibProj::cs2cs->new(\%params, $source_crs => $target_crs);
 $cs2cs = Geo::LibProj::cs2cs->new($source_crs => $target_crs, \%params);

Each of the C<%params> hash's keys represents a single control
parameter. Parameters are supplied exactly like in a C<cs2cs>
call on a command line, with a leading C<->. The value must be a
C<defined> value; a value of C<undef> will unset the parameter.

 %params = (
   -I => '',      # inverse ON (switch $source_crs and $target_crs)
   -f => '%.5f',  # output format (5 decimal digits)
   -r => undef,   # reverse coord input OFF (the default)
 );

See the L</"CONTROL PARAMETERS"> section below for implementation
details of specific control parameters.

=head2 transform

 $point_1 = [$x1, $y1];
 $point_2 = [$x2, $y2, $z2, $aux];
 @input_points  = ( $point_1, $point_2, ... );
 @output_points = $cs2cs->transform( @input_points );
 
 # transforming coordinates of just a single point:
 $output_point = $cs2cs->transform( [$x3, $y3, $z3] );

Execute C<cs2cs> to perform a CRS transformation of the specified
point or points. At least two coordinates (x/y) are required, a third
(z) may optionally be supplied.

Additionally, auxiliary data may be included in a fourth array
element. Just like C<cs2cs>, this value is simply passed through from
the input point to the output point. L<Geo::LibProj::cs2cs> doesn't
stringify this value for C<cs2cs>, so you can safely use Perl
references as auxiliary data, even blessed ones.

Coordinates are stringified for C<cs2cs> as numbers with I<at least>
the same precision as specified in the C<-f> control parameter.

Each point in a list is a simple unblessed array reference. When just
a single input point is given, C<transform()> may be called in scalar
context to directly obtain a reference to the output point. For lists
of multiple input points, calling in scalar context is prohibited.

Each call to C<transform()> creates a new C<cs2cs> process and runs
through the PROJ initialisation. Avoid calling this method in a loop
(except in L</"XS MODE">). See L</"PERFORMANCE CONSIDERATIONS"> for
details.

=head2 version

 $version = Geo::LibProj::cs2cs->version;

Attempt to determine the version of PROJ installed on your system.

=head2 xs

 $cs2cs = Geo::LibProj::cs2cs->new(...);
 $bool = $cs2cs->xs;

Indicates whether a L<Geo::LibProj::cs2cs> instance is using
L</"XS MODE">.

=head1 CONTROL PARAMETERS

L<Geo::LibProj::cs2cs> implements special handling for the following
control parameters. Parameters not mentioned here are passed on to
C<cs2cs> as-is. See your PROJ version's
L<cs2cs(1)|https://proj.org/apps/cs2cs.html> documentation for a
full list of supported options.

=head2 -d

 Geo::LibProj::cs2cs->new({-d => 7}, ...);

Fully supported shorthand to C<-f %f>. Specifies the number of
decimals in the output.

=head2 -f

 Geo::LibProj::cs2cs->new({-f => '%.7f'}, ...);

Fully supported (albeit with the limitations inherent in C<cs2cs>).
Specifies a printf format string to control the output values.

For L<Geo::LibProj::cs2cs>, the default value is currently C<'%.12g'>,
which allows easy further processing with Perl while keeping loss of
floating point precision low enough for any cartographic use case.
To enable the C<cs2cs> DMS string format (C<54d59'30.43"N>), you
need to explicitly unset this parameter by supplying C<undef>. This
will make C<cs2cs> use its built-in default format.

=head2 Unsupported parameters

 Geo::LibProj::cs2cs->new({-E => '' }, ...);  # fails
 Geo::LibProj::cs2cs->new({-t => '#'}, ...);  # fails
 Geo::LibProj::cs2cs->new({-v => '' }, ...);  # fails

The C<-E>, C<-t>, and C<-v> parameters disrupt parsing of the
transformation result and are unsupported.

=head2 XS

 Geo::LibProj::cs2cs->new({XS => 0}, ...);
 Geo::LibProj::cs2cs->new({XS => 1}, ...);
 Geo::LibProj::cs2cs->new({XS => undef}, ...);  # the default

By default, this module will in certain cases try to use a foreign
function interface provided by L<Geo::LibProj::FFI> to emulate
cs2cs, rather than use L<cs2cs(1)|https://proj.org/apps/cs2cs.html>
itself. This can give a dramatic performance boost, but does not
support all features of cs2cs(1). See L</"XS MODE"> for details.

To opt-out of this behaviour and force this module to only use an
actual cs2cs(1) utility through IPC, the internal parameter C<XS>
may be set to a defined non-truthy value (C<< XS => 0 >>).

The C<XS> parameter can also be set to a truthy value to indicate
a preference for the emulation. With C<< XS => 1 >> set, this
module will emit warnings if it must fall back to IPC due to an
error in the emulation's initialisation.

=head1 ENVIRONMENT

The C<cs2cs> binary is expected to be on the environment's C<PATH>.
However, if L<Alien::proj> is available, its C<share> install will
be preferred.

If this doesn't suit you, you can control the selection of the C<cs2cs>
binary by modifying the value of C<@Geo::LibProj::cs2cs::PATH>. The
directories listed will be tried in order, and the first match will
be used. An explicit value of C<undef> in the list will cause the
environment's C<PATH> to be used at that position in the search.

=head1 DIAGNOSTICS

When C<cs2cs> detects data errors (such as an input value of
S<C<91dN> latitude>), it returns an error string in place of
the result coordinates. The error string can be controlled
by the S<C<-e> parameter> as described in the
L<cs2cs(1)|https://proj.org/apps/cs2cs.html> documentation.

In L</"XS MODE">, C<Inf> is used instead of an error string.

L<Geo::LibProj::cs2cs> dies as soon as any other error condition is
discovered. Use C<eval>, L<Try::Tiny> or similar to catch this.

=head1 PERFORMANCE CONSIDERATIONS

B<Note:> This section does B<not> apply in L</"XS MODE">.

The C<L<transform()|/"transform">> method has enormous overhead.
Profiling shows the rate of C<transform()> calls you can expect to
be of the order of maybe 20/s or so, depending on your system.

The primary reason seems to be that each call to C<transform()>
spawns a new C<cs2cs> process, which must run through complete
PROJ initialisation each time. Additionally, this module could
probably improve the interprocess communication overhead, but so
far profiling suggests this is a minor problem by comparison.

Once C<transform()> is past that initialisation, it actually is
reasonably fast. This means that what you need to do in order to get
good performance is simply to keep the number of C<transform()>
calls in your code as low as possible. Obviously, it still won't be
quite as fast as XS code such as L<Geo::Proj4>, but it will be fast
enough that the difference likely won't matter to many applications.

You should never be calling C<transform()> from within a loop that
runs through all your coordinate pairs. That may be a typical pattern
in existing code for L<Geo::Proj4>, but if you try that with
L<Geo::LibProj::cs2cs>, it'll just take forever. (Well, almost.)

 # Don't do this!
 for my $p ( @thousands_of_points ) {
   push @result, $cs2cs->transform( $p );
 }

Instead, gather your points in a single list, and pass that one big
list to a single C<transform()> call.

 # Do this:
 @result = $cs2cs->transform( @thousands_of_points );

Depending on your data structure, however, it may not be as simple
as that. Imagine a structure looking like this, with coordinate
pairs you need to transform into another CRS:

 $r1 = bless {
   some_data => { ... },
   coords => { east => $e1, north => $n1 },
 }, 'Record';
 ...
 @records = ( $r1, $r2, ... $rN );
 #@result = $cs2cs->transform(@records);  # fails

You can't simply pass C<@records> to C<transform()> because it has
no way of knowing how to deal with C<Record> type objects. So, as a
first step, you need to create a list containing points in the proper
format:

 @points = map { [
   $_->{coords}->{east},   # x
   $_->{coords}->{north},  # y
   0,                      # z
   $_,                     # backref - see below
 ] } @records;
 @result = $cs2cs->transform(@points);  # succeeds

The C<@points> list can be passed to C<transform()>. To re-insert
the transformed coordinates into your original C<@records> data
structure, you could iterate over both lists at the same time, as
their length and order of elements should correspond to one another.

Alternatively, L<Geo::LibProj::cs2cs> allows for pass-through of Perl
references in the fourth field of a point array, so you can use it to
easily get back to the original C<Record> and insert the transformed
coordinates as required:

 for my $p ( @result ) {
   my $record = $p->[3];   # get the backref
   $record->{coords}->{lon} = $p->[0];
   $record->{coords}->{lat} = $p->[1];
 }

=head1 XS MODE

In order to improve performance, this module is able use a foreign
function interface provided by L<Geo::LibProj::FFI> to emulate
cs2cs. This is dramatically faster in most situations, and should
also be thread-safe.

In this document, the term "XS mode" is used for this emulation
due to historical reasons. L<perlxs> is not actually used by this
module at present.

XS mode will be used if, and only if, B<all> of the following
conditions are met:

=over

=item * L<Geo::LibProj::FFI> is loaded (e. g. with C<use>) before
the L<Geo::LibProj::cs2cs> instance is created with C<new()>.

=item * The internal L</"XS"> control parameter is either set to
a truthy value, set to C<undef>, or is missing entirely.

=item * No other control parameters are specified.

=item * Both the source CRS and the target CRS given to the
C<new()> method can be successfully interpreted as CRS by
L<proj_create()|https://proj.org/development/reference/functions.html#c.proj_create>.

=item * Creating a new PROJ threading context using
L<proj_context_create()|https://proj.org/development/reference/functions.html#c.proj_context_create>
succeeds.

=item * Creating a new PROJ transformation object using
L<proj_create_crs_to_crs()|https://proj.org/development/reference/functions.html#c.proj_create_crs_to_crs>
succeeds.

=back

For example, the following code should reliably result in the use
of S<XS mode>:

 use Geo::LibProj::cs2cs 1.02;
 use Geo::LibProj::FFI;
 
 $cs2cs = Geo::LibProj::cs2cs->new("EPSG:4326" => "EPSG:25833");
 $point = $cs2cs->transform( [54 + 59/60 + 30.43/3600, -4.2061] );
 
 say $cs2cs->xs ? "FFI/XS mode" : "IPC mode";

Note that XS mode doesn't support the C<cs2cs> DMS string format
(C<54d59'30.43"N>). You must use numbers, as shown in the example.

=head1 BUGS

To communicate with C<cs2cs>, this software uses L<IPC::Run3>.
On most platforms, that module is not L<threads>-safe.
Instead of directly interacting with the C<cs2cs> process,
L<IPC::Run3> creates temp files for every call to C<transform()>.
Except when using threads, this is reliable, but somewhat slow.

The C<-l...> list parameters have not been implemented.

This module doesn't seem to work on Win32. Try Cygwin.

Please report new issues on GitHub.

=head1 SEE ALSO

L<Alien::proj>

L<Geo::LibProj::FFI>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020-2021 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
