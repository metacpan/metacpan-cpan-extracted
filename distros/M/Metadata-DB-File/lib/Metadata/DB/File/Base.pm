package Metadata::DB::File::Base;
use strict;
use warnings;
use Carp;
use LEOCHARRE::DEBUG;
use base 'Metadata::DB::Base';
use LEOCHARRE::Class::Accessors single => [
'table_files_name',
'table_files_column_name_id',
'table_files_column_name_location',
'table_files_column_name_host_id',
];

#use vars qw(%EXPORT_TAGS);
#%EXPORT_TAGS = (
#single => qw(none),
#database => qw(table_files_name
#table_files_column_name_id
#table_files_column_name_location
#table_files_column_name_host_id
#table_files_check
#table_files_exists
#table_files_create
#table_files_layout
#table_files_dump
#table_files_count
#table_all_reset),
#);



no warnings 'redefine';
*_file_id_lookup = \&_filesystem_args_get;
# if we only have a file id to load with, instead of abs path and host id
sub _filesystem_args_get {
   my($self,$id) =@_;
   defined $id or croak('missing id arg');
   
   my $q = sprintf
      "SELECT %s,%s FROM %s WHERE %s=? LIMIT 1",
      $self->table_files_column_name_location,
      $self->table_files_column_name_host_id,
      $self->table_files_name,            
      $self->table_files_column_name_id,
      
      ;
   my $sel = $self->dbh->prepare($q);
   $sel->execute($id);
   
   my ( $abs_path, $host_id)  = $sel->fetchrow_array; # this just gets first one
   #$self->id or warn('id is not set');   
   #use Smart::Comments '###';
   ## @got
   defined $abs_path
      or warn("id $id is not in files table")
      and return;
   return ($abs_path,$host_id);
}


sub _file_entry_exists {
   my($self,$id,$abs_path,$host_id) = @_;
   
   my $q = sprintf
      "SELECT %s FROM %s WHERE %s='%s' AND %s='%s'",
      $self->table_files_column_name_id,
      $self->table_files_name,
      $self->table_files_column_name_location,
      $abs_path,      
      $self->table_files_column_name_id,
      $id     
      ;
   
   if ($host_id){ # if we have host_id as arg
      $q.= sprintf " AND %s='%s'",
      $self->table_files_column_name_host_id,
      $host_id,
      ;
   }
   $q.=" LIMIT 1";
   debug("query $q\n");
   
   my $result = $self->dbh->selectcol($q);   

   scalar @$result or return 0;
   return $result->[0];
}

sub _file_id_clear {
   my($self,$id) = @_;
   defined $id or croak('missing id arg');
   
   $self->{_file_id_clear_0} ||= 
      $self->dbh->prepare( sprintf "DELETE FROM %s WHERE %s = ?",
         $self->table_files_name,
         $self->table_files_column_name_id,
         );

   $self->{_file_id_clear_1} ||= 
      $self->dbh->prepare( sprintf "DELETE FROM %s WHERE %s = ?",
         $self->table_metadata_name,
         $self->table_metadata_column_name_id,
         );

   $self->{_file_id_clear_0}->execute($id);
   $self->{_file_id_clear_1}->execute($id);
   return 1;

}

# if we cant find id for file, create one
sub _file_id_request {
   my($self,$abs_path,$host_id) = @_;
   defined $abs_path or croak('missing arg');   
   
  # my $id = 
      $self->_file_id_get($abs_path,$host_id)
      or $self->_file_id_create($abs_path,$host_id)
      or die("cant get or create id?!");
}


# look up id by abs path
sub _file_id_get {   
   my($self,$abs_path,$host_id) = @_;
   defined $abs_path or croak('missing arg');
   
   my $q = sprintf
      "SELECT %s FROM %s WHERE %s='%s'",
      $self->table_files_column_name_id,
      $self->table_files_name,
      $self->table_files_column_name_location,
      $abs_path,      
      ;
   
   if ($host_id){ # if we have host_id as arg
      $q.= sprintf " AND %s='%s'",
      $self->table_files_column_name_host_id,
      $host_id,
      ;
   }
   $q.=" LIMIT 1";
   debug("query $q\n");
   
   my $result = $self->dbh->selectcol($q);   

   scalar @$result or return 0;
   return $result->[0];
}


# force creation of file id in files table
# later this is the id you use in the metadata table.
sub _file_id_create {
   my($self,$abs_path,$host_id) = @_;
   defined $abs_path or croak('missing abs path');

      local $self->dbh->{PrintError} = 0;
   
   my $lid;
   
   if (defined $host_id){
   
      my $q = sprintf
         "INSERT INTO %s (%s,%s) values (?,?)",
         $self->table_files_name,
         $self->table_files_column_name_location,
         $self->table_files_column_name_host_id,
         ;
         
      my $_ins = $self->dbh->prepare($q);
      
      
      $_ins->execute($abs_path,$host_id) or confess(" cannot execute , ".$self->dbh->errstr);
      $lid = $self->dbh->lid($self->table_files_name) 
      or confess('cant get last insert id, table ['.$self->table_files_name
      ."] - ".$self->dbh->errstr);   

   }

   else { # no host id

      my $q = sprintf
         "INSERT INTO %s (%s) values (?)",
         $self->table_files_name,
         $self->table_files_column_name_location,
         ;

      my $_ins = $self->dbh->prepare($q);
      
      
      $_ins->execute($abs_path) or confess(" cannot execute , ".$self->dbh->errstr);
      
      $lid = $self->dbh->lid($self->table_files_name) 
      or confess('cant get last insert id, table ['.$self->table_files_name
      ."] - ".$self->dbh->errstr);   
   }


   return $lid;  
}




# SETUP

# we need the metadata table, AND the files table
*table_all_reset = \&_table_all_reset;
sub table_files_check {
   my $self = shift;
   if( ! $self->table_files_exists ){
      debug("table files does not exist");
      $self->table_files_create;
   }
   debug("table files exists");
   return 1;
}

sub table_files_exists {
   my $self = shift;
   return $self->dbh->table_exists( $self->table_files_name );  
}

sub table_files_create {
   my $self = shift;
   my $dbh = $self->dbh;
   
   my $create = $self->table_files_layout;
   $dbh->do( $create );
   debug("ok, created table:\n$create\n");
   return 1;
}

sub _table_all_reset {
  my $self = shift;
  defined $self or confess('missing self');
  $self->dbh or die('dbh not returning');
  $self->dbh->drop_table($self->table_files_name);
  $self->dbh->drop_table($self->table_metadata_name);

  $self->table_metadata_create;
  $self->table_files_create;  
  return 1;
}

sub table_files_layout {
   my $self = shift;

   my $auto_increment=
      $self->dbh->is_mysql 
      ? ' AUTO_INCREMENT'
      : ''
      ;
   
   
   my $current = sprintf 
     "CREATE TABLE %s (\n"
     ."  %s INTEGER PRIMARY KEY$auto_increment,\n" # make this autp increment # IS THIS ALSO OK WITH MYSQL???
     ."  %s varchar(255),\n"
     ."  %s varchar(11)\n"       
     .");\n",
      $self->table_files_name,
      $self->table_files_column_name_id,
      $self->table_files_column_name_location,
      $self->table_files_column_name_host_id,     
     ;
   return $current;  
}


sub table_files_name {
   my $self = shift;
   unless( $self->table_files_name_get ){
      $self->table_files_name_set('files_resource');
   }
   return $self->table_files_name_get;
}
sub table_files_column_name_id {
   my $self = shift;
   unless( $self->table_files_column_name_id_get ){
      $self->table_files_column_name_id_set('id');
   }
   return $self->table_files_column_name_id_get;
}
sub table_files_column_name_location {
   my $self = shift;
   unless( $self->table_files_column_name_location_get ){
      $self->table_files_column_name_location_set('abs_path');
   }
   return $self->table_files_column_name_location_get;
}
sub table_files_column_name_host_id {
   my $self = shift;
   unless( $self->table_files_column_name_host_id_get ){
      $self->table_files_column_name_host_id_set('host_id');
   }
   return $self->table_files_column_name_host_id_get;
}


sub table_files_dump {
   my $self = shift;
   my $limit = shift;
   if (defined $limit){
      $limit = " LIMIT $limit";
   }
   
   my $dbh = $self->dbh;

   my $_dump;
   $limit||='';
   
   my $_query = sprintf 
      "SELECT %s, %s, %s FROM %s $limit",
      $self->table_files_column_name_id,
      $self->table_files_column_name_location,
      $self->table_files_column_name_host_id,
      $self->table_files_name,
      ;
   
   debug("query [[ $_query ]]\n");
   
   my $r = $dbh->selectall_arrayref($_query) or die($dbh->errstr);
   
   my $out = sprintf " # DUMP for %s\n",$self->table_files_name;

   my $_id;
   
   for(@$r){
      my ($id,$key,$val) = @$_;
      $val||='';
      if(!$_id or ($id ne $_id)){
         $out.="\n$id: ";
         $_id = $id;
      }

      $out.=" $key:$val";
      $_dump->{$id}->{$key} = $val;      
   }
   $out.="\n\n";
   return $out;
}


# STATS

sub table_files_count {
   my $self = shift;
   my $c = $self->dbh->rows_count( $self->table_files_name );
   $c||=0;
   return $c;
}


# tree subs

sub tree_clear {
   my($self,$abs_path) = @_;
   defined $abs_path or croak('missing abs path arg');
   
   # get the ids 
   my $ids = $self->tree_ids($abs_path);
   
   for(@$ids){
      $self->_file_id_clear($_);
   }
   return 1;
}


sub tree_ids {
   my($self,$_abs_path) = @_;   
   defined $_abs_path or croak('missing abs path arg');
   require Cwd;
   my $abs_path = Cwd::abs_path($_abs_path) or confess("cant resolve $_abs_path");

   my $q = sprintf "SELECT %s from %s WHERE %s LIKE '%s%%'",
      $self->table_files_column_name_id,
      $self->table_files_name,
      $self->table_files_column_name_location,
      $abs_path,
      ;
   my @ids = map { $_->[0] } @{$self->dbh->selectall_arrayref($q)};
   debug("total ids in $abs_path: $#ids");
   return \@ids; 
}

1;

__END__

=pod

=head1 NAME

Metadata::File::DB:Base

=head1 DESCRIPTION

This module is mostly about setting up the database, and setting default
parameters, like the table name, the id column name, etc.

=head1 REQUIRES

Metadata::DB::Base

=head1 FILE SUBS

These are the base methods to interact with a record.

One is to create a record id, one to retrieve a record id.
The third is to provide an id as argument, and to get back where the file *is*-
this is essentially for when you get back search results from Metadata::DB::Search


=head2 _filesystem_args_get() and _file_id_lookup()

argument is the file id, returns abs path and host id

=head2 _file_id_request()

argument is abs path and optionally host_id of machine file is on
returns id for this file resource.
If it does not exist in the database, it is created/inserted.

=head2 _file_id_get()

argument is abs_path and optionally host_id
returns id of file or 0 if it's not in the files table

=head2 _file_id_create()

argument is abs_path and optionally host_id
inserts data and returns id


=head2 _file_entry_exists()

argument is id, abs path, and optionally host id
returns boolean

   $self->_file_entry_exists( 5, '/home/this/that',3);   
   $self->_file_entry_exists( 5, '/home/this/that');
   
=head2 _file_id_clear()

argument is id of a file
deletes all data from files table and metadata table


=head1 SETUP AND DATABSE SUBS

=head2 table_all_reset()

will drop ALL metatada and files locations table and rebuild
this is called for re-indexing an entire archive

=head2 table_files_check()

checks if table files exists if not creates.

=head2 table_files_exists()

returns boolean

=head2 table_files_create()

creates files table

=head2 table_files_layout()

returns string for creating files table

=head2 table_files_dump()

optional argument is limit (number)
returns string dump for STDERR

=head2 table_files_count()

returns number of entries in files table


=head1 SUBS FOR MESSING WITH THE DB

Imagine you have a path, and you want to clear all indexed data fromthere down.
Maybe you indexed /home/myself/this/ and you want to drop everything in /home/myself/this/here/

=head2 tree_clear()

argument is abs path
clears all entries for that path, argument would be a directory on disk

=head2 tree_ids()

argument is abs path, returns all ids for files indexed in that path
used by tree_clear to easily deduce what should be cleared
will use Cwd::abs_path to resolve

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut


