package Metadata::DB::Indexer;
use strict;
use base 'Metadata::DB::Base';
use LEOCHARRE::DEBUG;
use LEOCHARRE::Class2;
use Carp;
use vars qw($VERSION);
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /(\d+)/g;

__PACKAGE__->make_constructor;
__PACKAGE__->make_accessor_setget({
   records_to_index => [],
   records_indexed_count => 0,
});


sub records_to_index_count {
   my $self = shift;
  
   my $records = $self->records_to_index
      or warn('records_to_index was not set yet, cant get count')
      and return;
   ref $records eq 'ARRAY' or confess('records to index must be array ref');

   my $count = scalar @$records;
   return $count;
}


# overrite me
sub record_identifier_to_metadata {
   warn ( __PACKAGE__."::record_to_metadata() overrite me please, see Metadata::DB::Indexer");
   return;
}

sub run {
   my $self = shift;

   my $count = $self->records_to_index_count
      or return;

   debug("will index $count records");


   my $autocommit_original_setting = $self->dbh->{AutoCommit};
      
   # should we localize?
   $self->dbh->{AutoCommit} = 0;
   

   # drop/reset/create the table
   my $name = $self->table_metadata_name;
   
   debug("reseting '$name' table");
   $self->table_metadata_reset;


   my $record_identifiers = $self->records_to_index;
   
   ITERATION: for my $identifier ( @$record_identifiers ){      
   
       $self->_index_one_record($identifier);
   }
  
   # commit and set back the autocommit setting to what it was
   debug("Done. Committing changes to db..");
   $self->dbh->commit;
   $self->dbh->{AutoCommit} = $autocommit_original_setting;

  
   debug( sprintf "Indexed %s/%s records", $self->records_indexed_count, $count );
   
   return 1;  
}


sub _index_one_record {
   my($self,$identifier) = @_;
   defined $identifier or confess;
  
   no strict 'refs';
   my $meta = &{__PACKAGE__.'::record_identifier_to_metadata'}($identifier);
   
   if( ! defined $meta ){
      warn("record_identifier_to_metadata() returns undef for [$identifier]");
      return;
   }
   
   elsif( ! ((ref $meta) and (ref $meta eq 'HASH')) ){   
      warn("record_identifier_to_metadata() does not return hash ref");
      return;
   }
   elsif( ! ( keys %$meta ) ){
      warn("record_identified_to_metadata() has ref has nothing?");
      return;
   }
   
   my $id = ( $self->records_indexed_count + 1 );

   unless( $self->_table_metadata_insert_multiple($id,$meta) ){
      warn("could not insert record[$id],[meta ref:$meta], ".$self->dbh->errstr);
      return;
   }

  # hack:
  $self->records_indexed_count($id); #increment, we only get here if we inserter properly
  
  return 1;
}





1;


__END__

=pod

=head1 NAME

Metadata::DB::Indexer

=head1 SYNOPSIS

   use Metadata::DB::Indexer;
   use File::Find::Rule;

   no strict 'refs';
   *{Metadata::DB::Indexer::record_identifier_to_metadata} = \&get_mp3_meta;
   

   my $finder = File::Find::Rule->file()->name( qr/\.mp3$/i );
   my @music_files = $finder->in('/home/myself');

   my $absdb = '/home/myself/music.db';
   my $dbh = DBI->connect("dbi:SQLite:dbname=$absdb","","");

   my $indexer = Metadata::DB::Indexer({ DBH => $dbh });

   $indexer->records_to_index(\@music_files);

   $indexer->run;


   sub get_mp3_meta {
      my $record_identifier = shift;

      my $abs_path = $record_identifier;

      my $meta = my_sub_that_turns_mp3s_to_hashref_meta($abs_path);

      $meta or return; # this registers a fail, and continues

      return $meta;   
   }

   my $total   = $indexed->records_to_index_count;
   my $indexed = $indexer->records_indexed_count;

   print STDERR "Done, indexed $indexed of $total records.\n";

=head1 DESCRIPTION

This facilitates indexing records for use with Metadata::DB and sub packages.
This is meant to completely recreate a metadata table for records.
Useful for indexing files, or any sort of record that may be timely.

=head2 NOTE

The purpose of Metadata::DB::Analizer and Metadata::DB::WUI are to provide a means to
autoregenerate search interfaces without a developer's intervention.
The interface regenerates by itself, depending on the data available.
This package provides an iterator for indexing groups of data.

If you are dealing with metadata that a computer can deduce from a record set, then this
package is useful.

If you are working with metadata that is randomly inserted, this module is not useful.

=head1 METHODS

=head2 new()

The contructor takes a hash ref as argument, the key DBH must be provided, with a database handle.

   my $x = Metadata::DB::Indexer->new({ DBH => $dbh });

=head2 records_to_index()

Argument is array ref of 'record identifier's.
A record identifier is the id- of sorts, that is sent to your method that generates the metadata.

=head2 records_to_index_count()

Returns number. You can call this after you set records_to_index().

=head2 record_identifier_to_metadata()

This method is meant to be overridden.
This method receives as argument a record identifier, and should return a hash ref where each key is 
a metadata attribute label. The value can be an array ref or a scalar.

=head2 run()

Takes no arguments.
Sets the gears in motion, iterates through your record identifiers provided to records_to_index().

=head2 records_indexed_count()

Returns number. This is the count of records sucessfully indexed.


=cut






=head1 AN EXAMPLE INDEXING RUN

A run will drop your entire database table for records.
Note, this package does not aid in incremental indexing.

Let's have an example where we are indexing files on disk.

=head2 INSTANCE

   my $dbh; # you have to provide an open database handle

   my $o = Metadata::DB::Indexer->new({ DBH => $dbh });

=head2 GENERATE A LIST OF WHAT TO INDEX

You must set the records to index as 'abs paths', because we are going to index files on disk.
If you wanted to index something else, like collect data from the web, you would maybe
set urls as a list, or something else.

it's up to you how you get that list
in this example we are using files, so I would suggest File::Find::Rule

   my @abs_paths; # list of abs paths to records on disk

Let's set the list

   $o->records_to_index(\@abs_paths);


=head2 DEFINE THE METHOD TO GENERATE METADATA FOR EACH RECORD

You should overrite or redefine record_identifier_to_metadata() to generate your own meta.

Example:

   *Metadata::DB::Indexer::record_identifier_to_metadata = \&abs_path_to_metadata;

	sub abs_path_to_metadata {
	   my($abs_path) = @_;

      # boring example that just records stat info
      
      my @stat = stat($abs_path) or warn("$abs_path  not on disk?") and return;
	
	   my $meta = {};
	
	   ( $meta->{dev}, $meta->{ino}, $meta->{mode}, $meta->{nlink},
        $meta->{uid}, $meta->{gid}, $meta->{rdev}, $meta->{atime},
        $meta->{mtime}, $meta->{ctime}, $meta->{blksize}, $meta->{blocks} ) =
	           @stat;
	
	   return $meta;
	}

The method record_identifier_to_metadata() receives one argument only, the list element from your
originally provided list. this basically acts as an iteration.

Your method must return a hash ref with keys and values to set as metadata for this 'record'
if it returns undef, the iteration is skipped and the run continues

You could do something more interesting like collect id3 tags from mp3s, and then
you could search by author, album, genre, a combination of any.
You will not have to design the the search form, if you want to use a web interface.
Metadata::DB::WUI will take care of generating it for you, so as you reindex, the possible
choices to search upon will automatically adapt to what you have indexed.
It's really like magic.

=head3 RUN

the run will set the db handle to AutoCommit 0, and then commit and set it back to 
what it was before.

   $o->run;
   
How many records were indexed succesfully?

   $o->records_indexed_count;

=head2 ANALIZE YOUR DATA

Let's see what we have, in the above example we used an sqlite db
open a terminal..

   mdri -A -a /home/myself/md_records.db

=cut







=head2 CREATE A WEB APP TO SEARCH

The whole point of using Metadata::DB is to automatically generate search interfaces
to data. The search interface recreates itself depending on 'what' is in there.
If you store info on people, you search by people meta, or music, or whatever.
This is a very flexible system!

See CGI::Application::Plugin::MetadataDB
for an example, see Metadata::DB::WUI


=head1 CHANGING THE TABLE

You may be keeping differenta metadata collections in different tables in on db

if so.. you can choose the table by..

   $o->table_metadata_name('mp3s'); # you should run check to make sure it is there

=head2 HOW TO SET UP A NEW COLLECTION OF META

   my $name = 'metadata_mp3s';

   $o->table_metadata_name($name);

If you want to just reset the table (drop if exists and create)

   $o->table_metadata_reset;

Note that calling a run() will automatically reset the metadata table by the name 
you have provided via table_metadata_name(), the default is 'metadata'.

=cut




=head1 DEBUG

You can turn on the debug flag via:

   $Metadata::DB::Indexer::DEBUG = 1;

=head1 BUGS

Please contact the AUTHOR for any bugs.

=head1 SEE ALSO

Metadata::DB
Metadata::DB::Search
Metadata::DB::Analizer

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut


