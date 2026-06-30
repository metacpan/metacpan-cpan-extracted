# -*- perl -*-
#
# Author: Gisbert W. Selke, TapirSoft Selke & Selke GbR.
#
# Copyright (C) 2025--2026 Gisbert W. Selke. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: gws@cpan.org
#
package Map::Tube::Generic;
use 5.14.0;
use strict;
use warnings;
use utf8;
use version 0.77 ( );

our $VERSION = version->declare('v0.1.0');

=encoding utf8

=head1 NAME

Map::Tube::Generic - Interface to a map specified at runtime.

=cut

use Carp;
use File::Spec;
use Moo;
use namespace::clean;

has location  => ( is     => 'rwp',
                   isa    => sub { carp( "$_[0] is not a string" ) if ref($_[0]) },
                   coerce => sub {
                     my($arg) = @_;
                     $arg     = $arg->( ) while ref($arg) eq 'CODE';
                     $arg     = "$arg" unless ( ref($_[0]) eq 'HASH' ) || ( ref($_[0]) eq 'ARRAY' );
                     return $arg;
                   },
                 );
has namespace => ( is      => 'rwp',
                   default => sub { return [ 'Map::Tube' ] },
                   isa     => sub { carp( "$_ is not a string" ) for grep { ref($_) } @{ $_[0] } },
                   coerce  => sub {
                     my($arg) = @_;
                     $arg     = $arg->( ) while ref($arg) eq 'CODE';
                     return ( ref($arg) eq 'ARRAY' ) ? $arg : [ $arg ];
                   },
                 );
has map       => ( is      => 'rwp',
                   isa     => sub { carp( "$_[0] does not do the Map::Tube role" ) unless $_[0]->DOES('Map::Tube') },
                   handles => [
                                # These are methods provided either directly by the Map::Tube::xxx class
                                # or by the Map::Tube role.
                                # We cannot just delegate to the Map::Tube::xxx class (because we
                                # do not know it yet) or to the Map::Tube role (because that creates
                                # an infinite recursion for some built-in methods).
                                # This construction is, of course, brittle.
                                # We could fix it by using Moose instead of Moo and using the
                                # meta protocol, but we don't want the big Moose in our living-room.
                                # Instead, it should be checked during module installation
                                # that we are still complete. (That has limited dynamics
                                # but is better than nothing).
                                # Using Module::PrintUsed or Class:Inspector?
                                qw(
                                    xml                 json
                                    get_shortest_route  get_all_routes
                                    get_node_by_id      get_node_by_name
                                    get_line_by_id      get_line_by_name
                                    get_lines           get_stations
                                    get_next_stations   get_linked_stations
                                    get_map_data
                                    name                name_to_id
                                    plugins             _active_link
                                    _other_links        _line_stations
                                    _line_station_index _common_lines
                                    nodes               lines
                                    tables              routes
                                    _lines              bgcolor
                                    as_graph
                                  )
                              ],
                 );

with 'Map::Tube';


# Private data member:
# Known non-map classes in the Map::Tube namespace. We exclude these quickly.
my %_exclude = map { $_ => 1 } qw( API  CLI  Cookbook  Exception Generic Graph GraphViz
                                   Line Node Pluggable Route     Table   Types Utils );
# Class or object method:
sub list_maps {
  my( $class, %args ) = @_;
  $args{namespace} //= [ 'Map::Tube' ];
  $args{namespace} = [ $args{namespace} ] unless ref( $args{namespace} );
  my( @namespaces, $name, $namepattern, $verify );
  @namespaces  = map { [ split( /::/, $_ ) ] } @{ $args{namespace} };
  $name        = uc( $args{name} ) if defined( $args{name} );
  $namepattern = $args{pattern}    if defined( $args{pattern} ) && !defined($name);
  $verify      = $args{verify}     if defined( $args{verify} );
  my %files;
  #
  # TODO: handle case-sensitive filesystems more efficiently (assuming correct spelling)
  # TODO: on case-sensitive filesystems, first try to find case-sensitive matching, only then
  #       fall back to case-insensitive matching.
  # TODO: handle not only module name but also namespaces in case-insensitive manner.
  #
  for my $dir(@INC) {
    my $mydir = $dir;
    for my $ns(@namespaces) {
      # We go through some hoops here in order to get proper results both
      # on case-sensitive and on case-insensitive file systems, while
      # Perl's module names are always case-sensitive.
      my @nsparts = @$ns;
      my $ok = 1;
      while (@nsparts) {
        my $p = shift(@nsparts);
        my $dh;
        if ( !opendir( $dh, $mydir ) ) {
          $ok = 0;
          last;
        }
        my($d) = grep { $_ eq $p } readdir($dh);
        closedir($dh);
        if ( !defined($d) ) {
          $ok = 0;
          last;
        }
        $mydir = File::Spec->catdir( $mydir, $d );
      }
      next unless $ok;

      my $pattern = File::Spec->catfile( $mydir, '*.pm' );
      for my $f ( glob($pattern) ) {
        my( undef, undef, $fname ) = File::Spec->splitpath($f);
        $fname =~ s/\.pm$//;
        next if exists( $_exclude{$fname} );
        next if defined($name) && ( uc($fname) ne $name );
        next if defined($namepattern) && ( $fname !~ $namepattern );
        my $modname = join( '::', @$ns, $fname );
        my $mapname;
        if ( $verify ) {
          $mapname = _loadable($modname);
          next unless defined $mapname;
        }

        $files{$modname} = { filepath => $f, location => $fname };
        $files{$modname}{name} = $mapname if defined($mapname);
      }
    }
  }

  return \%files;
}

# #######################################################################
#
# Private methods
#
# #######################################################################


sub _builder_map {
  # Find the concrete map module and instantiate it.
  # Argument:
  #   The name of a Map::Tube module containing map data
  #   This may be a fully qualified module name (properly written, respecting case)
  #   (e.g., 'Map::Tube::London'), or a "location" (e.g., 'London'). For the latter
  #   case does not matter.
  # Returns an instance of the specified map.
  # Croaks if the Map::Tube module cannot be found or cannot be instantiated.

  my( $self, $args ) = @_;

  my $modname = $self->location( );
  if ( $modname !~ /::/ ) {
    my $candidates = $self->list_maps( name => $modname, namespace => $self->namespace( ) );
    croak "Cannot find Map::Tube class '$modname' in namespace(s) @{ $self->namespace( ) }" unless keys %{ $candidates };
    ($modname) = sort keys %{ $candidates };
  }
  eval "require $modname;";
  croak($@) if $@;

  my $map = eval "$modname->new( \$args )";
  croak "Cannot instantiate $modname" unless $map;

  $self->_set_location($1) if $modname =~ /.*::(.*)$/;

  return $map;
}


sub BUILD {
  # Final check on arguments, and storing the map instance for future use.
  # No return value.
  # Carps or croaks if the argument check finds problems.

  my( $self, $args ) = @_;

  if ( exists($args->{location}) && exists($args->{map}) ) {
    carp 'Both location and map specified -- ignoring location';
  } elsif ( !exists($args->{location}) && !exists($args->{map}) ) {
    croak 'Either location or map need to be specified';
  }

  if ($self->map( ) ) {
    # If the map argument has been specified, the Map::Tube instance
    # is already where it should be. We'll just backfill our location attribute
    # as a nicety, using the "base name" of the class of the map module.
    my $classname = ref( $self->map( ) );
    $classname =~ s/__WITH__.*$//;
    $classname =~ s/^.*:://;
    $self->_set_location($classname);
  } else {
    # We cannot rely on the built-in Moo lazy builder mechanism
    # because that will not have been executed by the time the Map::Tube role
    # BUILD will be executed. So we need to do it here in time.
    $self->_set_map( $self->_builder_map($args) );
  }
  return;
}

my %own_methods = map { $_ => 1 } qw( list_maps location map namespace );
around can => sub {
  # Make the "can" method cleverer to make sure that the underlying concrete Map::Tube
  # module, to which almost everything is delegated, "can".
  my( $orig, $self, $method ) = @_;
  my $ret = $orig->( $self, $method );
  # manually delegate can( ) to the underlying map object, if we have one:
  return can( $self->map( ), $method ) if ref($self) && $self->map( ) && !exists( $own_methods{$method} );
  # ... else rely on ourselves, which is all we've got:
  return $orig->( $self, $method );
};


sub _loadable {
  # Helper function: takes a fully qualified module name and checks whether
  # it can be instantiated and does the Map::Tube role. Returns undef if not,
  # and otherwise the internal name of the map (if it exists) or the module name itself.
  my($modname) = @_;
  eval "require $modname;";
  return if $@;

  # Map::Tube object.
  my $map = eval "$modname->new( )";
  return unless $map;

  return unless $map->does( 'Map::Tube' );

  return $map->name( ) // $modname;
}

1;

__END__


=head1 SYNOPSIS

    use Map::Tube::Generic;
    my $tube = Map::Tube::Generic->new('London');

    my $route = $tube->get_shortest_route( 'Embankment', 'Whitechapel');

    print "Route: $route\n";

=head1 DESCRIPTION

This module allows to find the shortest route between any two given
stations in some metro network. The name of the network is specified at runtime.
Most interesting methods are provided by the role L<Map::Tube>.

=head1 METHODS

=head2 CONSTRUCTOR

    use Map::Tube::Generic;
    my $tube = Map::Tube::Generic->new( location  => <map_name>,
                                        namespace => <namespace>,
                                        map       => <map_object>,
                                        xml       => <not implemented yet>,
                                        json      => <not implemented yet>,
                                        ...
                                      );

The constructor takes arguments specifying which concrete module will supply
the information on the metro map. The module must do the L<Map::Tube> role.
Almost all method calls will just be delegated to that underlying module, so
they are not documented here.

=head3 ARGUMENTS

=over 4

=item * C<location>

The easiest way to specify a metro map is to pass its name via the C<location>
argument. This can be just the "base name", e.g., C<"London">. Case does not
matter, so C<"london"> or C<"LONDON"> will also do. The module implementing
the metro map will be looked for in all the namespaces provided by the
C<namespace> argument (q.v.). If more than one module is found, one will be
picked at random.

Alternatively, the C<location> may also be a fully qualified module name,
e.g., C<"Map::Tube::London">. In this form, case matters. (I<This is bound to
change in a future version.>)

In any case, the module chosen must do the L<Map::Tube> role.

The value of the argument must be a string or a code reference that will
produce a string.

Either C<location> or C<map> (but not both) must be specified.

=item * C<namespace>

Optionally, this is a string providing the "namespace" under which the module
may reside, e.g., C<"Map::Tube">. (This is also the default value.) In all
likelihood, the default value will always suffice, but here you can change it,
should the need arise. You may also specify a reference to an array of strings
so that multiple namespaces will be searched, or a code reference that will
return a string or a reference to an array of strings.

Note that the namespace(s) will be ignored if the C<location> is given as the
fully qualified module name, or if the C<map> argument is used.

=item * C<map>

If you already have an instance of the concrete map network you may pass this
in via this argument. It must do the L<Map::Tube> role. Frankly, though, if
you already have an instantiated map, you can use it directly, and there is no
advantage to wrapping it in a L<Map::Tube::Generic> object.

=item * C<xml>

Not yet implemented.

=item * C<json>

Not yet implemented.

=item * C<...>

Further arguments may be specified. These will be passed through to the
underlying module if and when instantiating it.

=back

=head2 C<location>

The "base name" of the underlying module will be returned (e.g., for a L<Map::Tube::London>,
it would return C<"London">).

=head2 C<BUILD>

If on construction the C<location> argument was used, this will be the value
returned. If the C<map> argument was used, the "base name" of the underlying
module will be returned (e.g., for a L<Map::Tube::London>, it would return
C<"London">).

=head2 C<namespace>

Returns the value of the C<namespace> argument from the constructor call
(or the default C<"Map::Tube">), always as a reference to an array of strings.

=head2 C<map>

Returns the instance of the underlying concrete metro map.

=head2 C<list_maps( E<lt>args...E<gt> )>

This method may be called either as a class or as an instance method. It returns
a reference to a hash whose keys are the module names of available metro maps,
optionally filtered by some criteria specified in the optional arguments:

=over 4

=item * C<name =E<gt> ...>

If the name of the module implementing the metro map for an area of interest
is known, it can be specified here. (Case does not matter.)

=item * C<namepattern =E<gt> ...>

If the exact name is not known, the "base names" may instead be filtered by a
regular expression, e.g., C<namepattern =E<gt> qr/^K/> for locations starting with
the letter C<"K">. For the pattern, in general, case does matter, but you can
easily supply a case-independent pattern.

=item * C<namespace =E<gt> ...>

The "namespaces" under which to search, specified as a string or a reference
to an array of strings. The default is C<"Map::Tube">, which will suffice
in practically all cases. (Note that this argument is completely unrelated
to what you may, or may not, have given as the C<namespace> argument for
the constructor.)

=item * C<verify =E<gt> ...>

Ordinarily, the search process just goes by the name of the modules but does
not check whether the modules found really implement metro maps, because this
requires loading each candidate module and is thus somewhat time-consuming.
If the option C<verify> with a true value is used, then the additional checks
will take place.

=back

The return value is a reference to a hash, where the keys are the fully
qualified module names.  The values are references to hashes with the
keys C<"filepath">, stating the C<@INC>-based path in the file system
from where this module would be loaded, and C<"location">, stating the
"basename" of the module.  If the C<verify> argument was true, there
will also be a key C<"name>", which will reflect the name of the metro
network as specified in the data for the metro network.  (This may be
C<undef>.)  If the same fully qualified module is found under different
paths as per C<@INC>, only the last one will be returned.

=head2 C<can>

This method can be used in order to find out which methods are supported by the
underlying Map::Tube object. E.g., it can be used to find out whether the
tube data are avaialble through the C<xml( )> or the C<json( )> method.

=head2 C<BUILD>

This is an internal method used in constructing the Map::Tube object.


=head1 ERRORS

If something goes wrong, maybe because the specified Map::Tube module was not found,
the constructor will die.

=head1 CONTRIBUTING

If you find a bug or have an idea for a useful extension, your contribution via
this module's issue tracker at L<https://github.com/gwselke/Map-Tube-Generic/issues>
is welcome! Pull requests are also appreciated!

=head1 AUTHOR

Gisbert W. Selke, TapirSoft Selke & Selke GbR.

=head1 COPYRIGHT AND LICENCE

The module is free software; you may redistribute and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Map::Tube>

