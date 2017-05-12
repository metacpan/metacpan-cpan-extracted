package Metadata::DB::File::Indexer;
use strict;
use LEOCHARRE::Class::Accessors single => [ 'files_to_index' ];
use base 'Metadata::DB::File::Base';
use LEOCHARRE::DEBUG;
use Carp;
use warnings;




*run = \&_run;
sub _run {
   my $self = shift;

   local $self->dbh->{AutoCommit} = 0;
   $self->files_to_index_count or croak("No files set.. call files_to_index_set()");

   while( my $_abs_path = $self->_get_next_to_index ){      
      $self->_index_one_file($_abs_path);
      debug($self->files_indexed_count."\n");      
   }
   
   $self->dbh->commit;
   debug('done and commited');
   return 1;
}

sub files_indexed_count {
   my $self = shift;
   $self->{_files_indexed} ||=0;
   return $self->{_files_indexed};
}

sub files_to_index_count {
   my $self = shift; 
   $self->files_to_index or return ;
   my $x = scalar @{$self->files_to_index};
   return $x;

}





# privates..

sub _index_one_file {
   my ( $self, $abs_path,$host_id )= @_;
   defined $abs_path or croak('missing file to index abs_path arg');   


   # make an insert into the files table
   my $file_id = $self->_file_id_create($abs_path,$host_id);
   debug("created id [$file_id] for $abs_path\n");

   
   # get the metadata
   my $meta_to_save = _abs_path_to_metadata($abs_path);
   ref $meta_to_save eq 'HASH' or croak("_abs_path_to_metadata() must return hash ref");
   debug('called _abs_path_to_metadata and got hash ref with '.	keys %$meta_to_save);



   # inject all that into the metadata table
   $self->_table_metadata_insert_multiple($file_id, $meta_to_save);
   
   
   debug("saved metadata\n");
   $self->{_files_indexed}++;

   return 1;
}

sub _get_next_to_index {
   my $self = shift;

   # shift it out of there
   
   my $next = shift @{$self->files_to_index};
   defined $next or return;
   return $next;
}







# -------------------------

# EMPIRICAL/FUNCTIONAL SUBROUTINE, NOT OO
#  override ME for diff settings
sub _abs_path_to_metadata {
   my($file_to_index) = @_;

   my $meta = {};
   
   ($meta->{dev},$meta->{ino},$meta->{mode},$meta->{nlink},$meta->{uid},$meta->{gid},$meta->{rdev},$meta->{size},
       $meta->{atime},$meta->{mtime},$meta->{ctime},$meta->{blksize},$meta->{blocks})
           = stat($file_to_index);

   return $meta;
}




1;

__END__

=pod

=head1 NAME

Metadata::DB::File::Indexer

=head1 DESCRIPTION

The indexer object is a main interface to creating and managing metadata tables about many files.
This object does not manage child instances of Metadata::DB::File, code that elsewhere.


=head1 SYNOPSIS

   # start a database handle 
   my $dbh;

   my $i = Metadata::DB::File::Indexer->new({ DBH => $dbh });

   $i->table_all_reset; # clear everything

   # You are left to figure out on your own what files to index 
   my @files;   
   $i->files_to_index(\@files);

   # you should determine what metadata will be stored for each
   # by overriding Metadata::DB::File::Indexer::_abs_path_to_metadata()

   no warnings 'redefine';
   *Metadata::DB::File::Indexer::_abs_path_to_metadata = \&mysub;
   
   sub mysub {
      my $abs_path = shift;

      my $meta = {}; #whatever you want
      return $meta;      
   }
   
   $i->run;


=head1 REINDEXING ALL

If you want to reindex an entire archive you should

   1) reset/clear the tables

      $i->table_all_reset;

   2) determine the files you want to index, abs paths
   
      my @files;
      $i->files_to_index_set(\@files);

   3) define a method to turn one of the paths to metadata
   
      &Metadata::DB::File::Indexer::_abs_path_to_metadata = 
         sub { my $abs_path = shift; my hash = {} ; return $hash; }

=head1 REINDEXING A PORTION

What if you only want to reindex a section?
Maybe you indexed /home/myself/mp3s but you just want to reindex a subpath...

   1) reset that portion
      $i->tree_clear('/home/myself/mp3s');

   2) determine the files you will index, used File::Find::Rule etc
      my @files
   
   3) determine how to convert into a metadata hash
       &Metadata::DB::File::Indexer::_abs_path_to_metadata = 
         sub { my $abs_path = shift; my hash = {} ; return $hash; }

  
      
   3) set and run
      $i->files_to_index_set(\@files);
      $i->run;   
   
   
=head1 METHODS

=head2 new()

required arg is hashref with key DBH to open database handle

   my $i = Metadata::DB::File::Indexer({ DBH => $dbh });

=head2 table_all_reset()

you'll have to call for the first time

=head2 files_indexed_count()

returns number

=head2 files_to_index()

=head2 files_to_index_set()

arg is array ref with abs paths to files on disk

=head2 files_to_index_count()

returns count of files indexed

=head2 run()

takes no args
runs the indexing procedure

=head1 WHAT IF I WANT TO CHANGE THE NAME OF THE TABLE

What if you want to store in another table?

Data is stored in two tables, the metadata table, and the files table.
to rename these..

(To read more: Metadata::DB::Base and Metadat::DB::File::Base )

=head2 table_metadata_name_set()

arg is string

=head2 table_files_name_set()

arg is string

=head1 CAVEAT

Before you index, make sure the entries are cleared.. you can do this:

   $i->tree_clear('/lowest/common/denominator/base');
   $i->run;

If you know will reindex the entire achive tree(everything you want to be in the db),
then you can simple reset the metadata and files table:

   $i->table_all_reset;
   $i->run;



=head1 SEE ALSO


Metadata::DB
Metadata::DB::Base
Metadata::DB::Search
Metadata::DB::Analizer
Metadata::DB::File
Metadata::DB::File::Base

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut
