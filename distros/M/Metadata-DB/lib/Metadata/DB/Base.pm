package Metadata::DB::Base;
use strict;
use LEOCHARRE::DEBUG;
use LEOCHARRE::DBI;
use LEOCHARRE::Class2;
use warnings;
use Carp;

__PACKAGE__->make_constructor;
__PACKAGE__->make_accessor_setget({
   table_metadata_name              => 'metadata',
   table_metadata_column_name_id    => 'id',
   table_metadata_column_name_key   => 'mkey',
   table_metadata_column_name_value => 'mval',
   errstr                           => undef,
});


no warnings 'redefine';




sub dbh {   
   $_[0]->{DBH} or confess('DBH argument must be provided to constructor.');
}


# setup

sub table_metadata_exists {
   my $self = shift;
   return $self->dbh->table_exists($self->table_metadata_name);   
}

sub table_metadata_create {
   my $self = shift;
   my $layout = $self->table_metadata_layout;
   debug("creating table:\n$layout\n");
   $self->dbh->do($layout)
      or die( $self->dbh->errstr );
   return 1;
}

sub table_metadata_layout {   
   my $self = shift;
   
   my $current = 
      sprintf
     "CREATE TABLE %s (\n"
    # ."  %s varchar(16),\n" # INSTEAD OF CHAR, USE INT, should be quicker
     ."  %s int,"
     ."  %s varchar(32),\n"
     ."  %s varchar(256)\n"       
     .");\n",
     $self->table_metadata_name,
     $self->table_metadata_column_name_id,
     $self->table_metadata_column_name_key,
     $self->table_metadata_column_name_value     
     ;
   # this is a strange and interesting layout
   return $current;     
}

sub table_metadata_drop {
   my $self = shift;
   my $table_name = $self->table_metadata_name;
   $self->dbh->drop_table($table_name)
      or die($self->dbh->errstr);
   return 1;
}

sub table_metadata_reset {
   my $self = shift;
     if( $self->table_metadata_exists ){
      $self->table_metadata_drop;
   }
   $self->table_metadata_create;
   return 1;   
}

# this is mostly debug
sub table_metadata_dump { # TODO, i think DBI has this now, alias to that method instead
   my $self = shift;
   my $limit = shift; # at most x extries??
   
   my $dbh = $self->dbh or die('no dbh() returned');
   if (defined $limit){
      $limit = " LIMIT $limit";
   }
   $limit||='';

   my $q = sprintf "SELECT * FROM %s $limit", $self->table_metadata_name;
   debug("q: $q\n");
   

   my $_dump;

   my $r = $dbh->selectall_arrayref( $q );
   
   my $out;

   my $_id;
   
   for(@$r){
      my ($id,$key,$val) = @$_;
      if(!$_id or ($id ne $_id)){
         $out.="\n$id: ";
         $_id = $id;
      }

      $out.=" $key:$val";
      $_dump->{$id}->{$key} = $val;      
   }
   $out.="\n\n";

   return $out;
 #  require Data::Dumper;
 #   my $string = Data::Dumper::Dumper($_dump);
  # return $string;
}

sub table_metadata_check { $_[0]->table_metadata_exists or $_[0]->table_metadata_create; 1 }




# SINGLE RECORD METHODS, ETC


# how many entries does a record hold in the metadata table
sub _record_entries_count {
   my ($self,$id) = @_;
   defined $id or die('missing id');
   my $count = $self->dbh->rows_count(
      $self->table_metadata_name,
      $self->table_metadata_column_name_id,
      $id,
   );
   return $count;
}

# delete all entries from db for one record
sub _record_entries_delete {
   my ($self,$id)=@_;
   defined $id or croak('missing id arg');
  
   my $sql = sprintf 
        "DELETE FROM %s WHERE %s=?", 
        $self->table_metadata_name,
        $self->table_metadata_column_name_id; 

	# what if the table is not there?

   $self->{_dsth} ||= 
      $self->dbh->prepare($sql)
        or confess("Could not prepare statement '$sql', ".$self->dbh->errstr);
        
   $self->{_dsth}->execute($id);
   # is do quicker ?

   # TODO,  return count of rows affected??
   return 1;
}


*{_record_entries_hashref} = \&_record_entries_hashref_3; # THIS IS THE BEST ONE
*{record_entries_hashref}  = \&_record_entries_hashref_3; # DONT CHANGE THIS ONE 

# TODO this needs to be redone to be faster.. somehow
sub _record_entries_hashref_1 {
   my($self,$id)=@_;
   defined $id or croak('missing id');
   
   my $meta={};

   
   unless( $self->{_selectall_id} ){
      my $attribute_return_limit = 100;      
      
      my $prepped = $self->dbh->prepare(
         sprintf 'SELECT %s,%s FROM %s WHERE %s = ? LIMIT %s',
         $self->table_metadata_column_name_key, $self->table_metadata_column_name_value,
         $self->table_metadata_name, $self->table_metadata_column_name_id, $attribute_return_limit
      );
      $self->{_selectall_id} = $prepped;
   }      
  
   $self->{_selectall_id}->execute($id);

   
   while ( my @row = $self->{_selectall_id}->fetchrow_array ){
      push @{ $meta->{$row[0]} }, $row[1];
   }
   if(DEBUG){
      my @e = keys %$meta;
      debug("got elements[@e]\n");
   }
   #$self->{_selectall_id}->finish; # maybe this is what's slowing it down
   # DONT USE finish(), it closes up the statement, means no more will be used of this statement!!!

   return $meta;
}

# attempt at making this faster 2 ..
sub _record_entries_hashref_2 {
   my ($self,$id)=@_;
   defined $id or confess('missing id');   
   
   my $meta ={};
   

      my $sth = $self->dbh->prepare_cached(

         sprintf 'SELECT %s,%s FROM %s WHERE %s = ?',
         $self->table_metadata_column_name_key, $self->table_metadata_column_name_value,
         $self->table_metadata_name, $self->table_metadata_column_name_id
      );
 
   $sth->execute($id);

   
   my ($key,$val);
   # USE BIND COLUMNS, SUPPOSEDLY THE MOST EFFICIENT WAY TO FETCH DATA ACCORDING TO DBI.pm
   $sth->bind_columns(\$key,\$val);

   while( $sth->fetch ){
      push @{$meta->{$key}},$val;
   }
   return $meta;
}


# attempt at making this faster 3 ..
sub _record_entries_hashref_3 {
   my ($self,$id)=@_;
   defined $id or confess('missing id');   
   
   my $meta ={};
   
   my $_limit = 500; # expect at most how much meta
   # actually limit is useless unless it is really reached.. :-(
   
   $self->{_record_entries_hashref_3} ||=   
      $self->dbh->prepare_cached(
         sprintf 'SELECT %s,%s FROM %s WHERE %s = ? LIMIT %s',
         $self->table_metadata_column_name_key, $self->table_metadata_column_name_value,
         $self->table_metadata_name, $self->table_metadata_column_name_id,
         $_limit
      );

   my $sth = $self->{_record_entries_hashref_3} or die('sth not present');
   
   $sth->execute($id);
   
   my $_rows = $sth->fetchall_arrayref;    

   for ( @$_rows ){
      push @{$meta->{$_->[0]}}, $_->[1];
   }
   
   return $meta;
}




# for lookup
# pass it a metadata struct or part of one, and it tries to find ONE 
# record that matches that one thing
sub _find_record_id_via_record_entries_hashref {
   my ($self, $metaref) = @_;
   defined $metaref or croak('missing hashref argument');

   ref $metaref and ref $metaref eq 'HASH' or croak('arg not meta hash ref');
   # how do we look up if key value is a array ref instead of a  single element!!!???   
   # HACK just use first value only for now

   my ($table,$colk,$colv,$coli) = ( 
         $self->table_metadata_name, 
         $self->table_metadata_column_name_key, 
         $self->table_metadata_column_name_value, 
         $self->table_metadata_column_name_id );


   # subselects

   # we iterate through the individual att values, the whole array
   # and build a subquery for each
   my $sql;
   my @vals;
   ATTRIBUTE: for my $att ( keys %$metaref ){  
      ref $metaref->{$att} and ref $metaref->{$att} eq 'ARRAY' 
         or croak("meta ref elements must be array refs, as returned by get_all()");



      VALUE: for my $val ( @{$metaref->{$att}} ){
         defined $val or warn("not defined '$att'") and next VALUE;
         
      
         if( !$sql ){ # first entry not yet made, this will be inner select
            $sql = "SELECT $coli FROM $table WHERE $colk=? AND $colv=?";
         }

         else { # deeper level, thus subselect
            # http://dev.mysql.com/doc/refman/5.0/en/subquery-restrictions.html
            $sql = "SELECT $coli FROM $table WHERE $colk=? AND $colv=? AND $coli IN ( $sql )";

         }

         push @vals, $att, $val;
      }

   }

   # add limit
   $sql.=" LIMIT 2"; # because if we have more than one we know the search is too lose
   # also without a limit, will keep searching. we just want to know if there's only one
   # that matches these params.

   debug("query: \n $sql\nvals: \n@vals\n");
   my $sth = $self->dbh->prepare( $sql ) or die();
   debug("prepared.");
   $sth->execute(@vals);
   my @ids;
   while ( my $row = $sth->fetch ){
      push @ids, $row->[0];   
   }

   my $hits = scalar @ids;

   $hits or $self->errstr('None found') and return;
   $hits == 1 or $self->errstr("Too many found [$hits], narrow your search.") and return;
   
   $ids[0];
}







sub _table_metadata_insert {
   my($self,$id,$key,$val)=@_;
   defined $val or confess('missing value arg');

   unless ( $self->{_table_metadata_insert} ){
   
      my $q = sprintf 
         'INSERT INTO %s (%s,%s,%s) values (?,?,?)',
         $self->table_metadata_name,
         $self->table_metadata_column_name_id,
         $self->table_metadata_column_name_key,
         $self->table_metadata_column_name_value;
   
      $self->{_table_metadata_insert} = $self->dbh->prepare( $q );

   }

   
   $self->{_table_metadata_insert}->execute( $id, $key, $val);
   return 1;
}


# inject metadata hashref for an id
sub _table_metadata_insert_multiple {
   my($self,$id,$meta_hashref) = @_;
   ref $meta_hashref eq 'HASH' or croak('missing meta hash ref arg');

   my @atts = keys %$meta_hashref
      or  croak("there are no key value pairs in the hashref");  

   ATTRIBUTE : for my $att ( @atts ){
      my $_val = $meta_hashref->{$att};
      defined $_val or debug("att $att was not defined\n") and next ATTRIBUTE;
      if ( ref $_val eq 'ARRAY' ){
         debug("$att is array ref");
         for ( @$_val ){
            $self->_table_metadata_insert( $id, $att, $_ );
         }
         next ATTRIBUTE;
      }
      elsif( ref $_val ){
         confess(__PACKAGE__.' _table_metadata_insert_multiple(), the value you want to insert into the metadata table is not an array or scalar');
      }
      
      debug("$att is scalar");
      $self->_table_metadata_insert( $id, $att, $_val );    
   }
   return 1;   
}


sub create_index_id {
   my $self = shift;
   $self->create_index(
      $self->table_metadata_name, 
      $self->table_metadata_column_name_id 
   );
   debug('created index 1');
   return 1;
}

sub create_index {
   my($self, $tablename, $colname) = @_;
   
   defined $colname or croak('missing colum name argument');
   my $cmd = "CREATE INDEX $colname\_index ON $tablename($colname);";
   debug($cmd);
   $self->dbh->do($cmd) or die("Could not dbh do '$cmd',".$self->dbh->errstr);
   return 1;
}

sub table_metadata_last_record_id {
   my $self = shift;
   my ( $col_id, $table_name) = ( $self->table_metadata_column_name_id, $self->table_metadata_name );

   my $sql = "SELECT $col_id FROM $table_name ORDER BY $col_id DESC LIMIT 1";
   my $aref = $self->dbh->selectall_arrayref($sql) or croak("Could not '$sql', ".$self->dbh->errstr);
   $aref and scalar @$aref or $self->errstr("Didn't find anything, no records?") and return;
   $aref->[0]->[0];
}


1;


__END__


=pod

=head1 NAME

Metadata::DB::Base

=head1 DESCRIPION

Base class for some Metadata::DB::* objects.

=head1 CONSTRUCTOR

=head2 new()

Argument is hash ref.
You must pass DBH, database handle, to the object.
This is a database handle you opened before instancing the object
If you wanted to change the name of the table..

   my $m = Metadata::DB::Base({ DBH => $dbh });
   $m->table_metadata_name('other_metadata_table'); # default is 'metadata'
   $m->table_metadata_check; # make sure the table is there, if you wanted to setup


=head2 errstr()

May contain message.

=head1 SETUP AND DB METHODS

=head2 dbh()

Returns database handle
The DBI handle is passed to the CONSTRUCTOR

=head2 table_metadata_exists()

Does the metadata table exist or not?
Returns boolean. 

=head2 table_metadata_create()

Creates metadata table, does not check for existance.

=head2 table_metadata_dump()

Optional argument is limit.
Returns debug string with a pseudo metadata table dump, suitable for printing to STDERR
for debug purposes.

=head2 table_metadata_layout()

Returns what the metadata table is expected to look according to current params.
Could be useful if you're having a hard time with all of this.
If you turn DEBUG to on, this is printed to STDERR .

=head2 table_metadata_check()

Create table if not exists.

=head2 table_metadata_drop()

Drops metadata table.
Erases all records.

=head2 table_metadata_reset()

Drops and rebuilds metadata table.
Erases all records.

=head2 create_index_id()

Creates an index for id col.

=head2 create_index()

Args are table name and column name. Mostly meant to be used internal.

=head2 table_metadata_last_record_id()

Returns the highest record id number in the table.
If none, returns undef- check errstr().
This is similar to a last_insert_id procedure, but checks the id.

=head1 RECORD METHODS

=head2 _record_entries_delete()

arg is id
deletes all metadata entries for this record from metadata table
(does not commit, etc)

=head2 _record_entries_count()

arg is id, returns number of record entries in metadata table

=head2 _table_metadata_insert()

arg is id, key, val

=head2 _table_metadata_insert_multiple()

arg is id and hashref
the hash ref is the metadata key value pairs
this is mostly used for indexing

   $self->_table_metadata_insert_mutiple(
      5,
      {
         name_first => 'jim',
         name_middle => 'raynor',
         name_last => 'waltzman',
         phone_number => '208-479-1515',
      },
   );

=head2 _record_entries_hashref() and record_entries_hashref()

arg is id
returns hashref


=head2 _find_record_id_via_record_entries_hashref()

Argument is a metadata struct ( a hashref, each element is an anon array with values)
or part of one. 
This attempts to match ONE record.

Used by Metadata::DB::lookup(), for example.

Returns record id.
If there is more than one hit, or no hits, returns undef.

   my $record_id = $self->_find_record_id_via_record_entries_hashref({
      first_name => [ 'jimmy' ],
      middle_name => ['jose','mercado'],
   });

   $record_id or print "Did not find, because: ".$self->errstr;

This is probably only meant for a single record and thus reside in Metadata::DB, but.. 
it takes a struct and returns an id. It could be useful elsewhere, thus it is in Metadata::DB::Base.



=head1 CREATE INDEXES

This is to VASTLY improve the speeds of searches.

Call method create_index_id() after running an indexing run for example.

=head1 DEBUG

   $Metadata::DB::DEBUG = 1;

=head1 SEE ALSO

Metadata::DB
Metadata::DB::Indexer
Metadata::DB::Search
Metadata::DB::WUI
Metadata::Base

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 CAVEATS

Still in development
Make sure you have the latest versions of DBI and DBD::mysql

=head1 BUGS

Please contact the AUTHOR for any issues, suggestions, bugs etc.

=head1 COPYRIGHT

Copyright (c) Leo Charre. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This means that you can, at your option, redistribute it and/or modify it under either the terms the GNU Public License (GPL) version 1 or later, or under the Perl Artistic License.

See http://dev.perl.org/licenses/

=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

Use of this software in any way or in any form, source or binary, is not allowed in any country which prohibits disclaimers of any implied warranties of merchantability or fitness for a particular purpose or any disclaimers of a similar nature.

IN NO EVENT SHALL I BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION (INCLUDING, BUT NOT LIMITED TO, LOST PROFITS) EVEN IF I HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE

=cut

