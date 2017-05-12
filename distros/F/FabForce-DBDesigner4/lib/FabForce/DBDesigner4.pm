package FabForce::DBDesigner4;

# ABSTRACT:  Parse/Analyse XML-Files created by DBDesigner 4 (FabForce)

use strict;
use warnings;
use Carp;
use FabForce::DBDesigner4::XML;
use FabForce::DBDesigner4::SQL;

our $VERSION     = '0.34';

sub new{
  my ($class,%args) = @_;
  croak "only one filetype" if(defined $args{sql} and defined $args{xml});
  my $self = {};
  bless $self,$class;

  $self->{sql} = $args{sql} if(defined $args{sql});
  $self->{xml} = $args{xml} if(defined $args{xml});

  return $self;
}# new

sub parsefile{
  my ($self,%args) = @_;
  
  $self->{xml} = $args{xml} if(defined $args{xml});

  if( defined $self->{xml} ) {
    my $xml = FabForce::DBDesigner4::XML->new;
    $self->{structure} = $xml->parsefile( $self->{xml} );
  }
  else{
    croak "No valid filetype defined!"
  }
}# parsefile

sub writeSQL{
  my ($self,$filename,$args) = @_;
  
  my $sql = FabForce::DBDesigner4::SQL->new();
  my $struct        = delete $args->{structure};
  $args->{type}   ||= 'other';
  my $structForFile = $struct || $self->{structure} || '';
  
  $sql->writeSQL($structForFile, $filename, $args);
}# writeSQL

sub getTables{
  my ($self) = @_;
  return @{$self->{structure}};
}# getTables

sub getSQL{
    my ($self,$args)  = @_;
    
    my $sql         = FabForce::DBDesigner4::SQL->new();
    $args->{type} ||= 'other';
    my @creates     = $sql->getSQL($self->{structure},$args);
    
    return @creates;
}

1;

__END__


=head1 SYNOPSIS

  use FabForce::DBDesigner4;

  my $designer = FabForce::DBDesigner4->new();
  $designer->parsefile(xml => 'KESS.xml');
  $designer->writeSQL('text_sql.sql',{ type => 'mysql' });

=head1 DESCRIPTION

FabForce::DBDesigner4 is a module to analyse xml-files created
by the Database-Design tool DBDesigner (Version 4) from
FabForce (http://www.fabforce.net).

B<NOTICE>: As of version 0.2 you can not parse sql files any longer. You just
can parse xml files created by DBDesigner. And you can't create XML files!

=head1 METHODS

=head2 new

  # create a new instance
  my $designer = FabForce::DBDesigner4->new();
  
=head2 parsefile

parse the input file (XML - FabForce format )

  # parse a xml-file
  $designer->parsefile(xml => 'KESS.xml');
  
=head2 writeSQL

print the structure into a sql-file

  $designer->writeSQL('foo.sql');
  
  # print "drop table statements"
  $designer->writeSQL( 'foo.sql', { drop_tables => 1 } );
  
=head2 getTables

returns an array of table-objects

  my @tables = $designer->getTables();

=head2 getSQL

returns an array of CREATE statements. One element for each table.

  my @creates = $designer->getSQL();
  
  # get "drop table" statements in extra elements
  my @creates = $designer->getSQL({ drop_table => 1 });

=head1 DBDesigner4::Table

Each table is an object which contains information about the columns,
the relations and the keys.

Methods of the table-objects

=head2 name

  # set the tablename
  $table->name('tablename');
  # get the tablename
  my $name = $table->name();
  
=head2 columns

  # set the tablecolumns
  my @array = ({'column1' => ['int','not null']});
  $table->columns(\@array);
  
  # get the columns
  print $_,"\n" for($table->columns());
  
=head2 columnType

  # get datatype of n-th column (i.e. 3rd column)
  my $datatype = $table->columnType(3);
  
=head2 columnInfo

  # get info about n-th column (i.e. 4th column)
  print Dumper($table->columnInfo(4));
  
=head2 stringsToTableCols

  # maps column information to hash (needed for columns())
  my @columns = ('col1 varchar(255) primary key', 'col2 int not null');
  my @array   = $table->stringsToTableCols(@columns);

=head2 addColumn

  # add the tablecolumn
  my $column = ['column1','int','not null'];
  $table->addColumn($column);
  
=head2 relations

  # set relations
  my @relations = ([1,'startTable.startCol','targetTable.targetCol']);
  $table->relations(\@relations);
  # get relations
  print $_,"\n" for($table->relations());

=head2 addRelation

  $table->addRelation([1,'startTable.startCol','targetTable.targetCol']);
  
=head2 removeRelation

  # removes a relation (i.e. 2nd relation)
  $table->removeRelation(2);

=head2 key

  # set the primary key
  $table->key(['prim1']);
  # get the primary key
  print "the primary key contains these columns:\n";
  print $_,"\n" for($table->key());

=head2 column_details

=head1 DEPENDENCIES

This module requires XML::Twig

=head1 BUGS and COMMENTS

This module is still in development so feel free to contact me and send me 
bugreports or comments on this module.

=head1 SEE ALSO

  XML::Twig and IO::File

=cut
