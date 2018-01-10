package Graph::Feather;
use strict;
use warnings;
use DBI;

our $VERSION = '0.01';

sub new {
  my ($class, %options) = @_;

  my $self = bless {
  }, $class;

  my $db_file = ':memory:';

  $self->{dbh} = DBI
    ->connect("dbi:SQLite:dbname=$db_file", "", "");

  local $self->{dbh}->{sqlite_allow_multiple_statements} = 1;

  ###################################################################
  # Deploy DB schema

  $self->{dbh}->do(q{

    -----------------------------------------------------------------
    -- Pragmata
    -----------------------------------------------------------------

    PRAGMA foreign_keys=ON;
    PRAGMA synchronous=OFF;
    PRAGMA journal_mode = OFF;
    PRAGMA locking_mode = EXCLUSIVE;

    -----------------------------------------------------------------
    -- Graph
    -----------------------------------------------------------------

    CREATE TABLE Graph_Attribute(
      attribute_name NOT NULL,
      attribute_value NOT NULL
    );

    CREATE UNIQUE INDEX idx_Graph_Attribute_name_unique
      ON Graph_Attribute (attribute_name);

    -----------------------------------------------------------------
    -- Vertices
    -----------------------------------------------------------------

    CREATE TABLE Vertex(
      vertex_name NOT NULL
    );

    CREATE UNIQUE INDEX idx_Vertex_name_unique
      ON Vertex (vertex_name);

    CREATE TABLE Vertex_Attribute(
      vertex NOT NULL,
      attribute_name NOT NULL,
      attribute_value NOT NULL,
      FOREIGN KEY (vertex)
        REFERENCES Vertex(vertex_name)
        ON DELETE CASCADE
        ON UPDATE NO ACTION
    );

    CREATE UNIQUE INDEX idx_Vertex_Attribute_vertex_name_unique
      ON Vertex_Attribute (vertex, attribute_name);

    -----------------------------------------------------------------
    -- Edges
    -----------------------------------------------------------------

    CREATE TABLE Edge(
      src NOT NULL,
      dst NOT NULL,
      FOREIGN KEY (src)
        REFERENCES Vertex(vertex_name)
        ON DELETE CASCADE
        ON UPDATE NO ACTION
      FOREIGN KEY (dst)
        REFERENCES Vertex(vertex_name)
        ON DELETE CASCADE 
        ON UPDATE NO ACTION
    );

    CREATE UNIQUE INDEX idx_Edge_src_dst_unique
      ON Edge (src, dst);

    CREATE INDEX idx_Edge_src
      ON Edge (src);

    CREATE INDEX idx_Edge_dst
      ON Edge (dst);

    CREATE TABLE Edge_Attribute(
      src NOT NULL,
      dst NOT NULL,
      attribute_name NOT NULL,
      attribute_value NOT NULL,
      FOREIGN KEY (src,dst)
        REFERENCES Edge(src,dst)
        ON DELETE CASCADE
        ON UPDATE NO ACTION
    );

    CREATE UNIQUE INDEX idx_Edge_Attribute_edge_name_unique
      ON Edge_Attribute (src, dst, attribute_name);

    -----------------------------------------------------------------
    -- Triggers to synchronise attribute values in Perl land
    -----------------------------------------------------------------

    CREATE TRIGGER trigger_Vertex_Attribute_delete
      AFTER DELETE ON Vertex_Attribute
      BEGIN
        SELECT _delete_vertex_av(OLD.rowid);
      END;

    CREATE TRIGGER trigger_Edge_Attribute_delete
      AFTER DELETE ON Edge_Attribute
      BEGIN
        SELECT _delete_edge_av(OLD.rowid);
      END;

    CREATE TRIGGER trigger_Graph_Attribute_delete
      AFTER DELETE ON Graph_Attribute
      BEGIN
        SELECT _delete_graph_av(OLD.rowid);
      END;

    -----------------------------------------------------------------
    -- Triggers that add vertices and edges when needed elsewhere
    -----------------------------------------------------------------

    CREATE TRIGGER trigger_Edge_insert
      BEFORE INSERT ON Edge
      BEGIN
        INSERT OR IGNORE
        INTO Vertex(vertex_name)
        VALUES(NEW.src);

        INSERT OR IGNORE
        INTO Vertex(vertex_name)
        VALUES(NEW.dst);
      END;

    CREATE TRIGGER trigger_Vertex_Attribute_insert
      BEFORE INSERT ON Vertex_Attribute
      BEGIN
        INSERT OR IGNORE
        INTO Vertex(vertex_name)
        VALUES(NEW.vertex);
      END;

    CREATE TRIGGER trigger_Edge_Attribute_insert
      BEFORE INSERT ON Edge_Attribute
      BEGIN
        INSERT OR IGNORE
        INTO Edge(src, dst)
        VALUES(NEW.src, NEW.dst);
      END;

  });

  ###################################################################
  # Register trigger functions to synchronise attribute Perl objects

  $self->{dbh}->sqlite_create_function( '_delete_vertex_av', 1, sub {
    delete $self->{vertex_attribute}{ $_[0] };
  });

  $self->{dbh}->sqlite_create_function( '_delete_edge_av', 1, sub {
    delete $self->{edge_attribute}{ $_[0] };
  });

  $self->{dbh}->sqlite_create_function( '_delete_graph_av', 1, sub {
    delete $self->{graph_attribute}{ $_[0] };
  });

  ###################################################################
  # Process options

  $self->add_vertices(@{ $options{vertices} })
    if exists $options{vertices};

  $self->add_edges(@{ $options{edges} })
    if exists $options{edges};

  return $self;
};

#####################################################################
# Basics
#####################################################################

sub add_vertex {
  my ($self, $v) = @_;
  add_vertices($self, $v);
}

sub add_edge {
  my ($self, $src, $dst) = @_;
  add_edges($self, [$src, $dst]);
}

sub has_vertex {
  my ($self, $v) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    SELECT 1 FROM Vertex WHERE vertex_name = ?
  });

  $sth->execute($v);

  my $result = !! $sth->fetchrow_arrayref();

  $sth->finish();

  return $result;
}

sub has_edge {
  my ($self, $src, $dst) = @_;
  
  my $sth = $self->{dbh}->prepare_cached(q{
    SELECT 1 FROM Edge WHERE src = ? AND dst = ?
  });

  $sth->execute($src, $dst);

  my $result = !! $sth->fetchrow_arrayref();

  $sth->finish();

  return $result;
}

sub delete_vertex {
  my ($self, $v) = @_;

  delete_vertices($self, $v);
}

sub delete_vertices {
  my ($self, @vertices) = @_;
  
#  delete_vertex_attributes($self, $_) for @vertices;

  my $sth = $self->{dbh}->prepare_cached(q{
    DELETE FROM Vertex WHERE vertex_name = ?
  });

  $self->{dbh}->begin_work();
  $sth->execute($_) for @vertices;
  $self->{dbh}->commit();
}

sub delete_edge {
  my ($self, $src, $dst) = @_;
  delete_edges($self, [$src, $dst]);
}

sub delete_edges {
  my ($self, @edges) = @_;
  
  delete_edge_attributes($self, @$_) for @edges;

  my $sth = $self->{dbh}->prepare_cached(q{
    DELETE FROM Edge WHERE src = ? AND dst = ?
  });

  $self->{dbh}->begin_work();
  $sth->execute(@$_) for @edges;
  $self->{dbh}->commit();
}

#####################################################################
# Mutators
#####################################################################

sub add_vertices {
  my ($self, @vertices) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    INSERT OR IGNORE INTO Vertex(vertex_name) VALUES (?)
  });

  $self->{dbh}->begin_work();
  $sth->execute($_) for @vertices;
  $self->{dbh}->commit;
}

sub add_edges { 
  my ($self, @edges) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    INSERT OR IGNORE INTO Edge(src, dst) VALUES (?, ?)
  });

  $self->{dbh}->begin_work();
  $sth->execute(@$_) for @edges;
  $self->{dbh}->commit();
}

#####################################################################
# Accessors
#####################################################################

sub vertices {
  my ($self) = @_;

  return map { @$_ } $self->{dbh}->selectall_array(q{
    SELECT vertex_name FROM Vertex;
  });
}

sub edges {
  my ($self) = @_;

  return $self->{dbh}->selectall_array(q{
    SELECT src, dst FROM Edge;
  });
}

sub successors {
  my ($self, $v) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    SELECT dst FROM Edge WHERE src = ?
  });

  $sth->execute($v);

  return map { @$_ } @{ $sth->fetchall_arrayref() };
}

sub all_successors {
  my ($self, $v) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    WITH RECURSIVE all_successors(v) AS (
      SELECT dst FROM Edge WHERE src = ?
      
      UNION
      
      SELECT dst
      FROM Edge
        INNER JOIN all_successors
          ON (Edge.src = all_successors.v)
    )
    SELECT v FROM all_successors
  });

  $sth->execute($v);

  return map { @$_ } @{ $sth->fetchall_arrayref() };
}

sub successorless_vertices {
  my ($self) = @_;

  return map { @$_ } $self->{dbh}->selectall_array(q{
    SELECT vertex_name
    FROM Vertex
      LEFT JOIN Edge
        ON (Vertex.vertex_name = Edge.src)
    WHERE Edge.dst IS NULL
  });
}

sub predecessors {
  my ($self, $v) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    SELECT src FROM Edge WHERE dst = ?
  });

  $sth->execute($v);

  return map { @$_ } @{ $sth->fetchall_arrayref() };
}

sub all_predecessors {
  my ($self, $v) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    WITH RECURSIVE all_predecessors(v) AS (
      SELECT src FROM Edge WHERE dst = ?
      
      UNION
      
      SELECT src
      FROM Edge
        INNER JOIN all_predecessors
          ON (Edge.dst = all_predecessors.v)
    )
    SELECT v FROM all_predecessors
  });

  $sth->execute($v);

  return map { @$_ } @{ $sth->fetchall_arrayref() };
}

sub predecessorless_vertices {
  my ($self) = @_;

  return map { @$_ } $self->{dbh}->selectall_array(q{
    SELECT vertex_name
    FROM Vertex
      LEFT JOIN Edge
        ON (Vertex.vertex_name = Edge.dst)
    WHERE Edge.src IS NULL
  });
}

#####################################################################
# Degree
#####################################################################

sub edges_at {
  my ($self, $v) = @_;

  return $self->{dbh}->selectall_array(q{
    SELECT src, dst
    FROM Edge
    WHERE (?) IN (src, dst)
  }, {}, $v);
}

sub edges_to {
  my ($self, $v) = @_;

  return $self->{dbh}->selectall_array(q{
    SELECT src, dst
    FROM Edge
    WHERE dst = ?
  }, {}, $v);
}

sub edges_from {
  my ($self, $v) = @_;

  return $self->{dbh}->selectall_array(q{
    SELECT src, dst
    FROM Edge
    WHERE src = ?
  }, {}, $v);
}

#####################################################################
# Attributes
#####################################################################

#####################################################################
# Vertex Attributes
#####################################################################

sub set_vertex_attribute {
  my ($self, $v, $name, $value) = @_;

  delete_vertex_attribute($self, $v, $name);

  my $sth = $self->{dbh}->prepare_cached(q{
    INSERT INTO Vertex_Attribute(
      vertex, attribute_name, attribute_value
    )
    VALUES (?, ?, ?)
  });

  $sth->execute($v, $name, $value);

  my $id = $self->{dbh}->sqlite_last_insert_rowid();

  $self->{vertex_attribute}{ $id } = $value;
}

sub _get_vertex_attribute_value_id {
  my ($self, $v, $name) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    SELECT rowid
    FROM Vertex_Attribute
    WHERE vertex = ?
      AND attribute_name = ?
  });

  $sth->execute($v, $name);

  my ($rowid) = $sth->fetchrow_array();

  $sth->finish();
  
  return $rowid;
}

sub get_vertex_attribute {
  my ($self, $v, $name) = @_;

  my $rowid = _get_vertex_attribute_value_id($self, $v, $name);
  return unless defined $rowid;
  return $self->{vertex_attribute}{ $rowid };
}

sub has_vertex_attribute {
  my ($self, $v, $name) = @_;
  my $rowid = _get_vertex_attribute_value_id($self, $v, $name);
  return defined $rowid;
}

sub delete_vertex_attribute {
  my ($self, $v, $name) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    DELETE
    FROM Vertex_Attribute
    WHERE vertex = ?
      AND attribute_name = ?
  });

  $sth->execute($v, $name);
}

sub get_vertex_attribute_names {
  my ($self, $v) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    SELECT attribute_name
    FROM Vertex_Attribute
    WHERE vertex = ?
  });

  $sth->execute($v);

  return map { @$_ } @{ $sth->fetchall_arrayref() };
}

sub delete_vertex_attributes {
  my ($self, $v) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    DELETE
    FROM Vertex_Attribute
    WHERE vertex = ?
  });

  $sth->execute($v);
  $sth->finish();
}

#####################################################################
# Edge Attributes
#####################################################################

sub set_edge_attribute {
  my ($self, $src, $dst, $name, $value) = @_;

  delete_edge_attribute($self, $src, $dst, $name);

  my $sth = $self->{dbh}->prepare_cached(q{
    INSERT INTO Edge_Attribute(
      src, dst, attribute_name, attribute_value
    )
    VALUES (?, ?, ?, ?)
  });

  $sth->execute($src, $dst, $name, $value);

  my $id = $self->{dbh}->sqlite_last_insert_rowid();

  $self->{edge_attribute}{ $id } = $value;
}

sub _get_edge_attribute_value_id {
  my ($self, $src, $dst, $name) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    SELECT rowid
    FROM Edge_Attribute
    WHERE src = ?
      AND dst = ?
      AND attribute_name = ?
  });

  $sth->execute($src, $dst, $name);

  my ($rowid) = $sth->fetchrow_array();

  $sth->finish();
  
  return $rowid;
}

sub get_edge_attribute {
  my ($self, $src, $dst, $name) = @_;

  my $rowid = _get_edge_attribute_value_id($self, $src, $dst, $name);
  return unless defined $rowid;
  return $self->{edge_attribute}{ $rowid };
}

sub has_edge_attribute {
  my ($self, $src, $dst, $name) = @_;
  my $rowid = _get_edge_attribute_value_id($self, $src, $dst, $name);
  return defined $rowid;
}

sub delete_edge_attribute {
  my ($self, $src, $dst, $name) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    DELETE
    FROM Edge_Attribute
    WHERE src = ?
      AND dst = ?
      AND attribute_name = ?
  });

  $sth->execute($src, $dst, $name);
  $sth->finish();
}

sub get_edge_attribute_names {
  my ($self, $src, $dst) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    SELECT attribute_name
    FROM Edge_Attribute
    WHERE src = ?
      AND dst = ?
  });

  $sth->execute($src, $dst);
  return map { @$_ } @{ $sth->fetchall_arrayref() };
}

sub delete_edge_attributes {
  my ($self, $src, $dst) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    DELETE
    FROM Edge_Attribute
    WHERE src = ?
      AND dst = ?
  });

  $sth->execute($src, $dst);
}

#####################################################################
# Graph Attributes
#####################################################################

sub set_graph_attribute {
  my ($self, $name, $value) = @_;

  delete_graph_attribute($self, $name);

  my $sth = $self->{dbh}->prepare_cached(q{
    INSERT INTO Graph_Attribute(
      attribute_name, attribute_value
    )
    VALUES (?, ?)
  });

  $sth->execute($name, $value);

  my $id = $self->{dbh}->sqlite_last_insert_rowid();

  $self->{graph_attribute}{ $id } = $value;
}

sub _get_graph_attribute_value_id {
  my ($self, $name) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    SELECT rowid
    FROM Graph_Attribute
    WHERE attribute_name = ?
  });

  $sth->execute($name);

  my ($rowid) = $sth->fetchrow_array();

  $sth->finish();
  
  return $rowid;
}

sub get_graph_attribute {
  my ($self, $name) = @_;

  my $rowid = _get_graph_attribute_value_id($self, $name);
  return unless defined $rowid;
  return $self->{graph_attribute}{ $rowid };
}

sub has_graph_attribute {
  my ($self, $name) = @_;
  my $rowid = _get_graph_attribute_value_id($self, $name);
  return defined $rowid;
}

sub delete_graph_attribute {
  my ($self, $name) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    DELETE
    FROM Graph_Attribute
    WHERE attribute_name = ?
  });

  $sth->execute($name);
}

sub get_graph_attribute_names {
  my ($self) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    SELECT attribute_name
    FROM Graph_Attribute
  });

  $sth->execute();
  return map { @$_ } @{ $sth->fetchall_arrayref() };
}

sub delete_graph_attributes {
  my ($self) = @_;

  my $sth = $self->{dbh}->prepare_cached(q{
    DELETE
    FROM Graph_Attribute
  });

  $sth->execute();
}

#####################################################################
# Extensions not provided by Graph::Directed
#####################################################################

sub _copy_vertices_edges_attributes {
  my ($lhs, $rhs) = @_;

  # copy vertices 
  $rhs->add_vertices($lhs->vertices);

  # copy edges
  $rhs->add_edges($lhs->edges);

  # copy graph attributes
  for my $n ($lhs->get_graph_attribute_names) {
    $rhs->set_graph_attribute($n,
      $lhs->get_graph_attribute($n));
  }

  # copy vertex attributes
  for my $v ($lhs->vertices) {
    for my $n ($lhs->get_vertex_attribute_names($v)) {
      $rhs->set_vertex_attribute($v, $n,
        $lhs->get_vertex_attribute($v, $n));
    }
  }

  # copy edge attributes
  for my $e ($lhs->edges) {
    my ($src, $dst) = @$e;
    for my $n ($lhs->get_edge_attribute_names($src, $dst)) {
      $rhs->set_edge_attribute($src, $dst, $n,
        $lhs->get_edge_attribute($src, $dst, $n));
    }
  }
}

sub feather_export_to {
  my ($self, $target) = @_;
  _copy_vertices_edges_attributes($self, $target);
}

sub feather_import_from {
  my ($self, $source) = @_;
  _copy_vertices_edges_attributes($source, $self);
}

1;

__END__

=head1 NAME

Graph::Feather - Like Graph::Directed basics, but with SQLite backend

=head1 SYNOPSIS

  use Graph::Feather;
  my $g = Graph::Feather->new;

  $g->add_edge(...);
  $g->has_edge(...)
  $g->delete_edge(...);
  ...

=head1 DESCRIPTION

Light-weight drop-in replacement for Graph::Directed using SQLite to
store directed graph data. Only basic graph manipulation functions
are supported. Some applications may find this module faster and/or
use less memory than Graph::Directed, particularily when using edge
or vertex attributes.

The test suite ensures the behavior of each method is equivalent to
those in Graph::Directed when called with legal arguments.

=head1 CONSTRUCTOR

=over

=item new(%options)

The C<%options> hash supports the following keys:

=over

=item vertices

Array of vertices.

=item edges

Array of edges.

=back

=back

=head1 METHODS

See the documentation of Graph::Directed for details:

=over

=item add_vertex

=item add_edge

=item has_vertex

=item has_edge

=item delete_vertex

=item delete_vertices

=item delete_edge

=item delete_edges

=item add_vertices

=item add_edges

=item vertices

=item edges

=item successors

=item all_successors

=item successorless_vertices

=item predecessors

=item all_predecessors

=item predecessorless_vertices

=item edges_at

=item edges_to

=item edges_from

=item set_vertex_attribute

=item get_vertex_attribute

=item has_vertex_attribute

=item delete_vertex_attribute

=item get_vertex_attribute_names

=item delete_vertex_attributes

=item set_edge_attribute

=item get_edge_attribute

=item has_edge_attribute

=item delete_edge_attribute

=item get_edge_attribute_names

=item delete_edge_attributes

=item set_graph_attribute

=item get_graph_attribute

=item has_graph_attribute

=item delete_graph_attribute

=item get_graph_attribute_names

=item delete_graph_attributes

=back

=head1 EXTENSIONS

=over

=item feather_export_to($compatible_graph)

Adds vertices, edges, their attributes, and any graph attributes
to the target graph, overwriting any existing attributes.

=item feather_import_from($compatible_graph)

Adds vertices, edges, their attributes, and any graph attributes
from the other graphs, overwriting any existing attributes.

=back

=head1 TODO

=over

=item * ...

=back

=head1 BUG REPORTS

Please report bugs in this module via
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Graph-Feather>

=head1 SEE ALSO

  * Graph::Directed

=head1 ACKNOWLEDGEMENTS

Thanks to the people on #perl on Freenode for a discussion on how to
name the module.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2017-2018 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
