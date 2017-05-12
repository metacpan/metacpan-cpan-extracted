package GraphViz::DBI::General;
#                                doom@kzsu.stanford.edu
#                                31 Mar 2005

=head1 NAME

GraphViz::DBI::General - graph table relationships from a DBI handle

=head1 SYNOPSIS

   use GraphViz::DBI::General;

   my $gbdh = GraphViz::DBI::General->new($dbh);
   $gbdh->schema('public');  # default used by Postgresql
   $gbdh->catalog( undef );  
   open my $fh, ">", $diagram_file or die "Couldn't open $diagram_file: $!";
   $gbdh->graph_tables->as_png($fh);

=head1 DESCRIPTION

This is a subclass of GraphViz::DBI. It can be used to generate
a graph of foreign key relationships between the tables of a
database, given a database handle (and perhaps a schema name
and/or a catalog name). It should work for any database with a
driver that supports the foreign_key_info method (such as
Postgresql, versions 7.3 and later).

Note that foreign_key_info is labeled as "experimental" in the
DBI documentation: if it's behavior changes in the future, 
it may cause problems for this code. 

=head2 Known Compatibility

Currently this module has been tested with:

               Version    
  -----------|--------            
  Postgresql |  8.0.1
  DBI        |  1.48
  DBD::Pg    |  1.40
  Linux      |  2.4.20

If you're so inclined, please do report your experiences with
using it in other environments.  Future versions will include a
summary of this information.  

Please send the output of the version_report method along with your 
reports:

  my $gbdh = GraphViz::DBI::General->new($dbh);
  print $gbdh->version_report;

=head2 Schema and Catalog settings

The settings you will most likely want to use with the postgresql 
database are as indicated in the SYNOPSIS above:

   $gbdh->schema('public');  
   $gbdh->catalog( undef );  

You might, however have a different schema name you need to work
with (your login name is a common choice on many systems). 

In postgresql there is not concept of the "catalog", so it's set to 
undef, this may be different for your own database. 

For some databases you might not need any schema or catalog setting,
and both should be undef.  


=head2 MOTIVATION

This module was inspired by GraphViz::DBI, which generates a
graph of table relationships given only a DBI handle.
Unfortunately, however, it relies on a naming convention to find
foreign key relationships, and has no concept of schemas (or
catalogs), which makes it unusable with a database such as
Postgresql (for Postgresql, it draws tables for the entire
pg_catalog and information_schema, generating huge output
graphs).

GraphViz::DBI::General behaves exactly like GraphViz::DBI, except
that it restricts it's scope to a given catalog and schema (if
these are applicable), and also uses the DBI method
foreign_key_info to find foreign keys rather than relying on some
arbitrary naming convention.

In theory, this makes GraphViz::DBI::General more general, and it
should be usable with any database with a fully-featured DBD
driver; but in fact, I'm not certain how widespread foreign_key_info
support is (or will be).  At the very least GraphViz::DBI::General 
works with Postgresql, which the original GraphViz::DBI definitely 
does not.

=head2 METHODS

GraphViz::DBI::General provides:

 o  Methods for specifying the schema and catalog (when applicable).
 o  A get_tables method with scope restricted by schema & catalog.
 o  A version of the is_foreign_key method that does not rely on naming conventions.

See L<GraphViz::DBI> and L<GraphViz> for documentation of the other 
available methods.

In detail, the methods provided by GraphViz::DBI::General are:

=over

=cut

use 5.006;
use strict; 
use warnings;
use Carp;
use Data::Dumper;

our $VERSION = '0.1';

use base 'GraphViz::DBI';

sub _init { 
  my $self = shift;
  my $dbh = shift;
  my %args = @_;
  $self->{schema} = $args{schema};
  $self->{catalog} = $args{catalog};
  $self->SUPER::_init( $dbh );
}

=item set_schema - set the schema attribute (only required 
  for some databases, e.g. typically 'public' for Postgresql)

=cut 

sub set_schema { 
  my ($self, $schema) = @_;
  $self->{schema} = $schema;
}

=item set_catalog - set the catalog attribute (not needed if the 
  database in use does not support the feature, e.g. Postgresql 
  does not).

=cut 

sub set_catalog { 
  my ($self, $catalog) = @_;
  $self->{catalog} = $catalog;
}

=item get_schema - returns the value of the schema attribute.

=cut 

sub get_schema { 
  my $self = shift; 
  $self->{schema};
}

=item get_catalog - returns the value of the catalog attribute.

=cut 

sub get_catalog { 
  my $self = shift; 
  $self->{catalog};
}


=item get_tables - determines a listing of all tables (for the
   current schema and/or catalog, which should be specified if
   applicable to the database in use).  Returns the list, and saves a
   reference to it as the attribute "tables".  

=cut 

sub get_tables {
	my $self = shift;
        my $schema = $self->get_schema;
        my $catalog = $self->get_catalog;
        my @tables = $self->get_dbh->tables( $catalog, $schema, undef, undef);
        local $_;
        foreach (@tables) { 
          s/^$schema\.//  if $schema;  # Needed to work with postgresql.
          s/^$catalog\.// if $catalog; # Possibly needed for JDBC, etc. (TODO Check that this works.)
        }
 	$self->{tables} ||= \@tables;
	return @tables;
}

=item is_foreign_key - given two args "table" and "field" determines if table.field 
   is a foreign key for some other table, and if so returns the name of the 
   table, otherwise a false value ('').
   This version should override the one in GraphViz::DBI.

=cut 

sub is_foreign_key {
  my ($self, $fk_table_candidate, $fk_field_candidate) = @_;
  my $schema = $self->get_schema;
  my $catalog = $self->get_catalog;

  my ($dbh, $sth, $aref);
  $dbh = $self->get_dbh;

  # Use the foreign_key_info DBI method to look up *all* fk fields in the candidate table:

  my $fk_catalog = $catalog;
  my $fk_schema = $schema;
  my $fk_table = $fk_table_candidate;

  if ( $sth = 
       $dbh->foreign_key_info( undef, undef, undef,
                               $fk_catalog, $fk_schema, $fk_table ) 
     ) { 

    while ($aref = $sth->fetchrow_arrayref) { 

      my $pktable_schem = $aref->[1]; # TODO have no use for this? 
      my $pktable_name = $aref->[2];
      my $pkcolumn_name = $aref->[3];

      my $fktable_name = $aref->[6];    
      my $fkcolumn_name = $aref->[7];    

      # if the key from foreign_key_info has a column name 
      # that matches the one we're looking up, then we've got one

      if ( $fkcolumn_name eq $fk_field_candidate 
           && $fktable_name eq $fk_table_candidate ) { 
        return $pktable_name; 
      } 
    }
  }
  return ''; 
}

=item version_report - report on the versions of different
  software packages in use by this module. 

=cut 

sub version_report { 
  my $self = shift;
  my $dbh = $self->get_dbh;

  my ($sql_dbms_name, $sql_dbms_ver, $os_name, $os_version, @piece);
  my ($dbd_name, $dbd_version, @dbd_name_candidates);
  my ($report, @results);

  $sql_dbms_name = $dbh->get_info( 17 );  # SQL_DBMS_NAME
  $sql_dbms_ver =  $dbh->get_info( 18 );  # SQL_DBMS_VER 

  # Get the OS name, and version if possible
  # TODO - look for standard solution to this (CPAN?)
  @piece = split /\s+/, `uname -a`; 
  if (@piece) { 
    $os_name = $piece[0];
    $os_version = $piece[2];
  } else { # if "uname" isn't available
    $os_name = $^O;
    $os_version = '???';
  }

  # Hash to relate the DBD::* form of a database name with 
  # the more official form reported by the DBI "get_info" method.
  my %dbd = ( 
             PostgreSQL => 'Pg',
             MySQL      => 'mysql',
             Mysql      => 'mysql',
             msql       => 'mSQL',
             oracle     => 'Oracle',
            );

  # TODO - Does this need more entires?  With luck only "DBD::Pg"
  # will have the problem of "SQL_DBMS_NAME" being different from the DBD name.
  # (Naming in general is a mess in the postgres/Pg/postgresql/PostgreSQL 
  # world... postmaster? psql?)

  @dbd_name_candidates = ('DBD::' . $dbd{$sql_dbms_name} , 
                          'DBD::' .      $sql_dbms_name  , 
                          $sql_dbms_name);
  for my $candidate (@dbd_name_candidates) { 
    if ( $dbd_version = eval('$' . $candidate . '::VERSION') ) { 
      $dbd_name = $candidate;
      last; 
    }
  }

  @results = (
               {$sql_dbms_name              => $sql_dbms_ver},
               {'DBI'                       => $DBI::VERSION},
               {"DBD::$dbd_name"            => $dbd_version}, 
               {'GraphViz'                  => $GraphViz::VERSION},
               {'GraphViz::DBI'             => $GraphViz::DBI::VERSION},
               {$os_name                    => $os_version},
             );

  $report = "Software in use with GraphViz::DBI::General v. $GraphViz::DBI::General::VERSION:\n";

  $report .= "                | Version        \n";
  $report .= "----------------|----------------\n";

  foreach my $rec (@results) { 
    my $label = ( keys( %{ $rec } ) )[0];
    my $value = $rec->{ $label };
    $report .= sprintf("%15s | %-12s\n", $label, $value);
  }

  return $report;
}

1;

__END__

=back 

=head1 TODO

This module is sadly lacking in tests, because it's difficult to
write portable tests for it: What databases exist?  Do I have
access permissions to do a "CREATE DATABASE"?  (On what databases
is a "CREATE DATABASE" supported?) Does the system have the
necessary fonts to generate the same graph image that I have?
(Do fonts of the same name always look the same on different
systems? I've seen signs that the answer to that is "no, not
always".) Still, I ought to be able to do better than no tests 
at all, e.g. I ought to be able to write postgresql specific 
tests that are just skipped if not applicable.  

=head1 SEE ALSO

This module inherits from:

L<GraphViz::DBI>

It uses a GraphViz handle (you can look up alternatives to
"as_png" in the GraphViz documentation):

L<GraphViz>

The constructor for this module takes a DBI database handle as an
argument:

L<DBI>

Additional information about GraphViz::DBI::General may be
available at the web site:

L<http://obsidianrook.com\/graphviz_dbi_general>


Note that there's another module that performs a similar job,
though it's restricted to projects implemented with
L<Class::DBI>:

L<Class::DBI::Loader::GraphViz>


=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
