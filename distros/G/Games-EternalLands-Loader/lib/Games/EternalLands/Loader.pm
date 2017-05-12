package Games::EternalLands::Loader;

use 5.006;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.03';

=head1 NAME

Games::EternalLands::Loader - Access Eternal Lands content files

=head1 SYNOPSIS

    use Games::EternalLands::Loader;

    my $loader = Games::EternalLands::Loader->new;
    $loader->content_path('/usr/share/games/eternal-lands');
    
    use Data::Dumper;

    my $map = $loader->load('maps/startmap.elm');
    print Dumper($map);

    my $entity = $loader->load('3dobjects/bag1.e3d');
    print Dumper($entity);

    ...

=head1 ABSTRACT

This module reads binary content files for the online game Eternal Lands
and unpacks them into perl data structures.

=cut

use Carp qw(croak confess);
use Convert::Binary::C;
use Digest::MD5 qw(md5_hex);
use IO::File;
use IO::Uncompress::AnyUncompress;
use File::Basename;
use File::Spec::Functions;
use Games::EternalLands::Binary::Float16;
use Games::EternalLands::Binary::Unitvec16;

use constant {
  _COMP_EXTS => [qw(gz zip bz2 Z xz)],
  _MAP_SIG => 'elmf',
  _ENT_SIG => 'e3dx',
};

sub _fail {
  my ($s, $m) = @_;
  croak "_FAILED_" . $m;
}

sub _setup_parser {
  my ($s) = @_;
  my $c = new Convert::Binary::C;
  $c->configure(
    ByteOrder => 'LittleEndian',
    Alignment => 1,
    CharSize => 1,
    ShortSize => 2,
    IntSize => 4,
    FloatSize => 4,
  );
  $c->parse(<<'EOS');
typedef unsigned char byte;
typedef unsigned short ushort;
typedef unsigned int uint;
typedef ushort float16;
typedef ushort unitvec16;

typedef struct {
  char signature[4];
  byte version[4];
  byte md5_digest[16];
  uint entity_data_offset;
} entity_header;

typedef struct {
  uint vertex_element_count;
  uint vertex_element_size;
  uint vertex_data_offset;
  uint index_element_count;
  uint index_element_size;
  uint index_data_offset;
  uint submesh_element_count;
  uint submesh_element_size;
  uint submesh_data_offset;
  struct {
    byte normals:1;
    byte tangents:1;
    byte twotextures:1;
    byte colors:1;
    byte :4;
  } vertex_field_flags;
  struct {
    byte float16_positions:1;
    byte float16_uv1s:1;
    byte float16_uv2s:1;
    byte quantized_unit_vectors:1;
    byte :4;
  } vertex_type_flags;
  byte __unused[2];
} mesh_header;

typedef struct {
  char entity_name[80];
  float position[3];
  float rotation[3];
  byte lighting_disabled;
  byte blending_level;
  byte __unused[2];
  float color[3];
  float scale;
  byte __unused[20];
} mesh_object;

typedef struct {
  char entity_name[80];
  float position[3];
  float rotation[3];
  byte __unused[24];
} quad_object;

typedef struct {
  float position[3];
  float color[3];
  byte __unused[16];
} light_object;

typedef struct {
  char entity_name[80];
  float position[3];
  byte __unused[12];
} fuzz_object;

typedef struct {
  char signature[4];
  uint terrain_map_length;
  uint terrain_map_breadth;
  uint terrain_map_offset;
  uint tile_map_offset;
  uint mesh_object_size;
  uint mesh_object_count;
  uint mesh_data_offset;
  uint quad_object_size;
  uint quad_object_count;
  uint quad_data_offset;
  uint light_object_size;
  uint light_object_count;
  uint light_data_offset;
  byte flag_indoors;
  byte __unused[3];
  float ambient_light[3];
  uint fuzz_object_size;
  uint fuzz_object_count;
  uint fuzz_data_offset;
  uint segment_data_offset;
  byte __unused[36];
} map_header;
EOS
  $c->tag($_, Format => 'String') for qw(
    entity_header.signature
    mesh_object.entity_name
    quad_object.entity_name
    fuzz_object.entity_name
    map_header.signature
  );
  $c->tag('float16', Hooks => { unpack => sub {
    Games::EternalLands::Binary::Float16::unpack_float16($_[0])
  }});
  $c->tag('unitvec16', Hooks => { unpack => sub {
    Games::EternalLands::Binary::Unitvec16::unpack_unitvec16($_[0])
  }});
  $c->tag('entity_header.version', Hooks => { unpack => sub {
    my $v = $_[0];
    return $v->[0] * 1000 + $v->[1] * 100 + $v->[2] * 10 + $v->[3];
  }});
  $s->{parser} = $c;
}

sub _locate {
  my ($s, $n) = @_;
  my $a = $s->{contpath};
  for my $p (@$a) {
    my $b = catfile $p, $n;
    return $b if -e $b;
    for my $e (_COMP_EXTS) {
      my $t = "$b.$e";
      return $t if -e $t;
    }
  }
  $s->_fail("Failed to find '$n' in search path: @$a");
}

sub _open {
  my ($s, $n) = @_;
  my $p = $s->_locate($n);
  my $f = new IO::Uncompress::AnyUncompress $p;
  $f = new IO::File $p if not $f;
  $s->_fail("Failed to open '$p': $!") if not $f;
  return $f;
}

sub _parse_c {
  my ($s, $x) = @_;
  eval {
    $s->{parser}->parse($x);
  };
  if ($@) {
    confess "Failed to parse c code: $@\nCode:\n$x\n";
  }
}

sub _unp {
  my ($s, $t, $d, $o, $x) = @_;
  my $c = $s->{parser};
  $o = 0 if not defined $o;
  $s->_parse_c($x) if defined $x;
  my $l = $c->sizeof($t);
  my $r = length $d;
  $s->_fail("Need to unpack $l bytes at offset $o,"
    . " but data has length only $r")
    if $o + $l > $r;
  my $p = substr $d, $o, $l;
  return $c->unpack($t, $p);
}

sub _unpa {
  my ($s, $t, $n, $d, $o) = @_;
  my $i = "_${t}_array_$n";
  my $x = $s->{parser}->def($i) ? undef : "typedef $t $i [$n];";
  return $s->_unp($i, $d, $o, $x);
}

sub _unpack_terrain {
  my ($s, $m, $h, $d) = @_;

  my $rl = $h->{terrain_map_length};
  my $rb = $h->{terrain_map_breadth};
  my $rc = $rl * $rb;
  my $ro = $h->{terrain_map_offset};
  my $rm = $s->_unpa(byte => $rc, $d, $ro);
  $m->{terrain_length} = $rl;
  $m->{terrain_breadth} = $rb;
  $m->{terrain_count} = $rc;
  $m->{terrain_map} = $rm;

  my $tl = $rl * 6;
  my $tb = $rb * 6;
  my $tc = $tl * $tb;
  my $to = $h->{tile_map_offset};
  my $tm = $s->_unpa(byte => $tc, $d, $to);
  $m->{tile_length} = $tl;
  $m->{tile_breadth} = $tb;
  $m->{tile_count} = $tc;
  $m->{tile_map} = $tm;
}

sub _unpack_objects {
  my ($s, $k, $m, $h, $d) = @_;
  my $kt = $k.'_object';
  my $ka = $k.'_objects';
  my $hs = $h->{$kt.'_size'};
  my $ts = $s->{parser}->sizeof($kt);
  $s->_fail("Size mismatch for '$kt': "
    . "header has $hs, but type is $ts")
    unless $hs == $ts;
  my $kc = $h->{$kt.'_count'};
  my $ko = $h->{$k.'_data_offset'};
  $m->{$ka} = $s->_unpa($kt, $kc, $d, $ko);
}

sub _assign_ids {
  my ($s, $m) = @_;
  for my $k (qw(mesh quad)) {
    my $i = 0;
    for my $o (@{$m->{$k."_objects"}}) {
      $o->{id} = $i;
      $i++;
    }
  }
}

sub _load_map {
  my ($s, $n) = @_;
  my $f = $s->_open($n);
  my $d = join '', <$f>;
  my $h = $s->_unp(map_header => $d);
  my $g = $h->{signature};
  $s->_fail("Map '$n' has wrong file signature: \"$g\"")
    if $g ne _MAP_SIG;
  my $m = {
    name => $n,
    indoors => $h->{flag_indoors},
    ambient_light => $h->{ambient_light},
  };
  $s->_unpack_terrain($m, $h, $d);
  $s->_unpack_objects(mesh => $m, $h, $d);
  $s->_unpack_objects(quad => $m, $h, $d);
  $s->_assign_ids($m);
  $s->_unpack_objects(light => $m, $h, $d);
  $s->_unpack_objects(fuzz => $m, $h, $d);
  return $m;
}

sub _load_quad {
  my ($s, $n) = @_;
  my $f = $s->_open($n);
  my %d = split(/\s*[:\n]\s*/, join('', <$f>));
  my @v = qw(texture file_x_len file_y_len
    x_size y_size u_start u_end v_start v_end);
  for my $k (@v) {
    $s->_fail("Missing expected field '$k' in '$n'")
      unless exists $d{$k};
  }
  my $ix = $d{file_x_len};
  my $iy = $d{file_y_len};
  my $u0 = $d{u_start} / $ix;
  my $v0 = $d{v_start} / $iy;
  my $u1 = $d{u_end} / $ix;
  my $v1 = $d{v_end} / $iy;
  my $sx = $d{x_size};
  my $sy = $d{y_size};
  my $x0 = - $sx / 2.0;
  my $y0 = - $sy / 2.0;
  my $x1 = $x0 + $sx;
  my $y1 = $y0 + $sy;
  my $z = 0.001;
  my $nr = [0.0, 0.0, 1.0];
  my $e = {
    texture_name => $d{texture},
    vertices => [
      { position => [$x0, $y0, $z], uv => [$u0, $v0], normal => $nr, },
      { position => [$x0, $y1, $z], uv => [$u0, $v1], normal => $nr, },
      { position => [$x1, $y1, $z], uv => [$u1, $v1], normal => $nr, },
      { position => [$x1, $y0, $z], uv => [$u1, $v0], normal => $nr, },
    ],
    indices => [ 0, 1, 2, 0, 2, 3 ],
  };
  return $e;
}

sub _check_header {
  my ($s, $n, $h, $d) = @_;
  my $es = $h->{signature};
  $s->_fail("Wrong signature in entity file header for '$n': $es")
    unless $es eq _ENT_SIG;
  my $hc = join '', map { sprintf "%02x", $_ } @{$h->{md5_digest}};
  my $fc = md5_hex(substr $d, $h->{entity_data_offset});
  $s->_fail("Checksum mismatch for '$n':\n"
    . "  Expected from header: $hc\n"
    . "  Calculated from file: $fc\n")
    unless $hc eq $fc;
  my $v = $h->{version};
  $s->_fail("Unrecognized entity file version for '$n': $v")
    unless $v == 1000 or $v == 1100;
}

sub _adjust_vertex_flags {
  my ($s, $v, $h) = @_;
  my $f = $h->{vertex_field_flags};
  my $t = $h->{vertex_type_flags};
  if ($v == 1000) {
    $f->{$_} ^= 1 for keys %$f;
    $f->{colors} = 0;
    $t->{$_} = 0 for keys %$t;
  }
}

sub _make_vertex_type {
  my ($s, $h) = @_;
  my $f = $h->{vertex_field_flags};
  my $t = $h->{vertex_type_flags};
  my $g = join '_', (values %$f, values %$t);
  my $v = "_vertex_type_$g";
  return $v if $s->{parser}->def($v);

  my $f_nor = $f->{normals};
  my $f_tan = $f->{tangents};
  my $f_uv2 = $f->{twotextures};
  my $f_col = $f->{colors};
  my $t_pos = $t->{float16_positions} ? 'float16' : 'float';
  my $t_uv1 = $t->{float16_uv1s} ? 'float16' : 'float';
  my $t_uv2 = $t->{float16_uv2s} ? 'float16' : 'float';
  my $t_vec = $t->{quantized_unit_vectors} ? 'unitvec16' : 'float';
  my $a_vec = $t->{quantized_unit_vectors} ? 0 : 3;
  my @r = (
    [1,      $t_uv1, 'uv',       2],
    [$f_uv2, $t_uv2, 'uv2',      2],
    [$f_nor, $t_vec, 'normal',   $a_vec],
    [$f_tan, $t_vec, 'tangent',  $a_vec],
    [1,      $t_pos, 'position', 3],
    [$f_col, 'byte', 'color',    4],
  );
  my $d = "typedef struct {\n";
  for (@r) {
    my ($e, $k, $n, $a) = @$_;
    $d .= "  $k $n ".($a?"[$a]":'').";\n" if $e;
  }
  $d .= "} $v;\n";
  $s->_parse_c($d);
  return $v;
}

sub _make_submesh_type {
  my ($s, $h) = @_;
  my $c = $s->{parser};
  my $f = $h->{vertex_field_flags};
  my $x = $f->{twotextures};
  my $t = "_submesh$x";
  return $t if $c->def($t);
  my $d = <<'EOS';
typedef struct {
  uint texture_flags;
  char texture_name[128];
  float minimum_position[3];
  float maximum_position[3];
  uint minimum_vertex_index;
  uint maximum_vertex_index;
  uint index_element_offset;
  uint index_element_count;
EOS
  $d .= "  char texture2_name[128];" if $x;
  $d .= "} $t;\n";
  $s->_parse_c($d);
  my @n = ("$t.texture_name");
  push @n, "$t.texture2_name" if $x;
  $c->tag($_, Format => 'String') for @n;
  return $t;
}

sub _load_mesh {
  my ($s, $n) = @_;
  my $f = $s->_open($n);
  my $d = join '', <$f>;
  my $c = $s->{parser};
  my $e = { name => $n };
  my $eh = $s->_unp(entity_header => $d);
  $s->_check_header($n, $eh, $d);

  my $mh = $s->_unp(mesh_header => $d, $eh->{entity_data_offset});
  $s->_adjust_vertex_flags($eh->{version}, $mh);

  my $vt = $s->_make_vertex_type($mh);
  my $ve = $c->sizeof($vt);
  my $vs = $mh->{vertex_element_size};
  $s->_fail("Unexpected vertex element size"
    . " for mesh entity '$n': $vs (expected $ve)")
    unless $ve == $vs;
  my $vn = $mh->{vertex_element_count};
  my $vo = $mh->{vertex_data_offset};
  $e->{vertices} = $s->_unpa($vt, $vn, $d, $vo);

  my $it = $mh->{index_element_size} == 2 ? 'ushort' : 'uint';
  my $in = $mh->{index_element_count};
  my $io = $mh->{index_data_offset};
  $e->{indices} = $s->_unpa($it, $in, $d, $io);

  my $st = $s->_make_submesh_type($mh);
  my $se = $c->sizeof($st);
  my $ss = $mh->{submesh_element_size};
  $s->_fail("Unexpected submesh element size"
    . " for mesh entity '$n': $ss (expected $se)")
    unless $se == $ss;
  my $sn = $mh->{submesh_element_count};
  my $so = $mh->{submesh_data_offset};
  $e->{submeshes} = $s->_unpa($st, $sn, $d, $so);

  return $e;
}

=head1 METHODS

=head2 new

Creates a new Games::EternalLands::Loader object.

=cut

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $s = bless {}, $class;
  $s->{contpath} = [curdir];
  $s->{loaders} = {
    'elm' => \&_load_map,
    'e3d' => \&_load_mesh,
    '2d0' => \&_load_quad,
  };
  $s->{errstr} = '';
  $s->_setup_parser;
  return $s;
}

=head2 content_path

Sets the directory where the content files are located. The
argument may be a string to set a single path, or an array
reference to set multiple paths to be used in turn. If no
argument is given the current value (an array reference)
is returned.

=cut

sub content_path {
  my ($s, $p) = @_;
  return $s->{contpath} if not defined $p;
  if (ref $p eq 'ARRAY') {
    $s->{contpath} = [@$p];
  } elsif (ref $p eq '') {
    $s->{contpath} = [$p];
  } else {
    croak "Expecting a string or array reference.";
  }
}

sub _load {
  my ($s, $n) = @_;
  my $l;
  for my $e (reverse split /\./, $n) {
    last if $l = $s->{loaders}{$e};
  }
  $s->_fail("No loader found for '$n'") unless $l;
  return $s->$l($n);
}

=head2 load

=over

=item load NAME

Finds, opens, reads and constructs the game asset identified by the
given name.

In case there is some error opening the file or parsing its contents,
undef is returned. A description of the error can be retrieved using
the L</errstr> method.

See L</"DATA STRUCTURES"> for what exactly is returned in each case.

=back

=cut

sub load {
  my ($s, $n) = @_;
  croak "Content name argument expected" if not defined $n;
  my $e = eval { $s->_load($n); };
  if ($@) {
    my $x = $@;
    if ($x =~ s/^_FAILED_//) {
      chomp $x;
      $s->{errstr} = $x;
      return;
    }
    confess $x;
  }
  return $e;
}

=head2 errstr

Returns a string describing the last error that occurred.

=cut

sub errstr {
  return $_[0]->{errstr};
}

1;
__END__


=head1 DATA STRUCTURES

The returned value from L</"load"> is a hash reference with the
following data in each case.

=head1 Maps

The maps used by Eternal Lands are tile-based with each C<6x6>
square of tiles grouped into one terrain square. Each tile
has side length C<0.5> units in world coordinates. Thus each
terrain square has an area in world coordinates of C<3 * 3 = 9>
square units. A tile represents the smallest unit of space that
a dynamic entity (e.g. a player or a creature) can occupy.

Maps returned by L</"load"> have at least the following fields:

=over

=item B<name>

The argument passed to load that resulted in this map.

=item B<indoors>

A boolean flag indicating whether this is map represents a location
inside a building, cave, etc., or outside.

=item B<ambient_light>

A 3 element array containing floating-point RGB values.

=item B<terrain_length>

Number of terrain squares in the first linear dimension of the map
(corresponding to the world x-axis).

=item B<terrain_breadth>

Number of terrain squares in the second linear dimension of the map
(corresponding to the world y-axis).

=item B<terrain_count>

Total number of terrain squares on the map.

=item B<terrain_map>

A one-dimensional array containing the terrain number for each
terrain coordinate. It contains exactly C<terrain_count> elements.
Given a terrain coordinate pair C<($tx, $ty)>, the terrain at that
location is
  
  $num = $map->{terrain_map}->[$map->{terrain_length} * $ty + $tx];

The terrain number maps to a texture asset name as

  $tex = "3dobjects/tile$num." . $extension;

where C<$extension> is an image file extension (usually I<"dds">).

NOTE: Terrain number 0 and all numbers between 230 and 255 (not
inclusive) are treated as "water" and are drawn at C<z = -0.25>
in world coordinates (rather than at C<z = 0> like all other
terrain squares).

Terrain 255 is the "empty terrain" (a.k.a. "null")
and is not drawn at all.

If the map is an indoor map then terrain number 0 is replaced
by 231 every time it occurs.

Some maps will refer to missing terrain textures; these are
simply ignored rather than being a fatal error. Depending on
your application you may wish to notify the user with a warning.

=item B<tile_length>

Number of tiles in the first linear dimension of the map
(corresponding to the world x-axis).

=item B<tile_breadth>

Number of tiles in the second linear dimension of the map
(corresponding to the world y-axis).

=item B<tile_count>

Total number of tiles on the map.

=item B<tile_map>

An array of length C<tile_count> containing an integer height
value for each tile. Given tile coordinates C<($x, $y)>, the
corresponding height is found using

  $h = $map->{tile_map}->[$map->{tile_length} * $y + $x];

A value of B<zero> indicates that the tile is impassable.
Otherwise the value maps to a coordinate along the world z-axis as

  $z = $h * 0.2 - 2.2;

NOTE: When drawing the map the tile's height value affects only
where dynamic entities such as players, bags, etc. are drawn;
terrain squares are always drawn at C<z = 0> in world space
(except for water terrains, which are drawn at C<z = -0.25>).

=item B<mesh_objects>

An array of hashes each containing at least the fields:

=over

=item B<entity_name> - Entity this object is an instance of.

=item B<id> - Numeric identifier for this object.

=item B<position> - 3-element array containing world coordinates.

=item B<rotation> - 3-element array containing degree rotations about each axis.

=item B<scale> - Scaling factor for all three dimensions.

=back

=item B<quad_objects>

An array of hashes each containing at least the fields:

=over

=item B<entity_name> - Entity this object is an instance of.

=item B<id> - Numeric identifier for this object.

=item B<position> - 3-element array containing world coordinates.

=item B<rotation> - 3-element array containing degree rotations about each axis.

=back

=item B<light_objects>

An array of hashes each containing at least the fields:

=over

=item B<position> - 3-element array containing world coordinates.

=item B<color> - Floating-point RGB vector.

=back

=item B<fuzz_objects>

An array of hashes representing particle systems
each containing at least the fields:

=over

=item B<entity_name> - Entity this object is an instance of.

=item B<position> - 3-element array containing world coordinates.

=back

=back


=head1 Mesh Entities

Static 3D objects on the map are represented using triangular
face-vertex meshes. Each mesh is further subdivided into a
small number of submeshes each with its own texture (or two
textures in some cases).

=over

=item B<vertices>

An array of hashes each containing:

=over

=item B<position> - 3-element array containing the world coordinates of this vertex.

=item B<uv> - 2-element array containing texture coordinates.

=item B<uv2> - 2-element array containing secondary texture coordinates I<(OPTIONAL)>.

=item B<normal> - 3-element array representing the normal vector for this vertex I<(OPTIONAL)>.

=item B<tangent> - 3-element array representing the tangent vector for this vertex I<(OPTIONAL)>.

=item B<color> - 4-element floating-point RGBA color vector I<(OPTIONAL)>.

=back

B<NOTE:> Some fields may not appear, but for any given mesh all vertices will
have the same fields present.

=item B<indices>

An array containing indices into the C<vertices> array for each
triangular face. So the first three elements correspond to the three
vertices making up the first triangle, the second three the second
triangle, and so on.

=item B<submeshes>

An array of hashes each containing at least:

=over

=item B<texture_name> - Image file containing the texture applied to this submesh. I<NOTE:>
It is given relative to the full path of the entity, without the leading content
sub-directories.

=item B<minimum_vertex_index> - The smallest index into the C<vertices> array of any
vertex in this submesh.

=item B<maximum_vertex_index> - The largest index into the C<vertices> array of any
vertex in this submesh.

=item B<index_element_count> - The number of elements of the C<indices> array used
by this submesh.

=item B<index_element_offset> - Where this submesh starts in the C<indices> array.

=item B<texture2_name> - Name of the secondary texture I<(OPTIONAL)>.

=back

=back

=head1 Quad Entities

These are static rectangular map objects generally used for ground
details. For consistency with L</"Mesh Entities"> their geometric
data is also given in a triangular face-vertex format, albeit without
submeshes.

=over

=item B<texture_name> - Image file containing the texture applied to this submesh. I<NOTE:>
It is given relative to the full path of the entity, without the leading content
sub-directories.

=item B<vertices> - Array of hashes each containing fields B<position>, B<uv> and B<normal>.

=item B<indices> - Array of integers giving the vertices in each triangle face.

=back


=head1 AUTHOR

Cole Minor, C<< <coleminor at hush.ai> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 Cole Minor. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
