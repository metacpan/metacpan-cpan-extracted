package Metadata::DB::File;
use strict;
use warnings;
use Carp;
use base 'Metadata::DB';
use base 'Metadata::DB::File::Base';
# manages the id, etc
use LEOCHARRE::DEBUG;
use LEOCHARRE::Class::Accessors 
   single => [qw(abs_path host_id _file_resolved)];

our $VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /(\d+)/g;



no warnings 'redefine';

sub new {
   my($class,$self) = @_;
   $self||={};
   bless $self,$class;  
   
   debug('started');

   #$self->file_set({
    #  abs_path => ( $self->{abs_path} or undef ),
     # host_id  => ( $self->{host_id} or undef ),
     # id       => ( $self->{id} or undef ),
   #}) or return;
  

   $self->abs_path_set($self->{abs_path}) if $self->{abs_path};
   $self->host_id_set($self->{host_id}) if $self->{host_id};
   $self->id_set($self->{id}) if $self->{id};
      
   return $self;
}



# overrides Metadata::DB::load()
# load should NOT save, that is.. create an id!
sub load {
   my $self = shift;

   # IF WE ARE BEING RETARDED
   if( ! $self->abs_path and ! $self->id ){
      confess("There is no id or abs_path set, can't load()");  
   }




   # IF WE GOT ID FROM A SEARCH
   if( $self->id and !$self->abs_path ){
      

      # load abs path from files table
      
      my ($abs_path, $host_id) = $self->_filesystem_args_get($self->id)
         or warn($self->id ." is not valid, not in files table.")
         and return;     
      
      # warn and do NOT proceed to SUPER::load(), return false
      # this happens if they called id_set() (or via constructor)
      # but requested an invalid id, or one that is no longer in files table
   
      $self->abs_path_set($abs_path);
      $self->host_id_set($host_id) if defined $host_id;
      
      # load the metadata and return true, even if no metadata present.
      # we just care that it be in the files table.
      $self->SUPER::load(); #remember that this sets loaded() to true
      return 1;
   }





   # IF WE ARE QUERYING ABOUT A FILE WE KNOW WHERE IT IS
   if( $self->abs_path and !$self->id ){
      
      # then try to find out what the id 
      
      my $id = $self->_file_id_get( $self->abs_path, $self->host_id) # returns true or false
         or carp( $self->abs_path .' is not valid, not in files table. call save() before load()')
         and return;
      
      # if none, dont try to create one

      $self->id_set($id);
      

      $self->SUPER::load(); #remember that this sets loaded() to true
      return 1;   
   }
   




   # IF WE ARE JUST RELOADING

   # what if there is BOTH an id AND a abs_path set??????
   # then we already loaded???
   #if( $self->abs_path and $self->id ){

      # then just reload metadata
      $self->SUPER::load(); #remember that this sets loaded() to true
      return 1;         
   #}
   
   
   # if neither.. we caught that attop, actually.

   
   # we MUST have an id to load, 
   # because the file table entry IS relevant
   # to the data of this object
}
#load returns true if there is an entry in the files table
# it doesnt check if there is something in the metadata table







# save MUST assure we have an entry in the files table
# thus, only save really needs to require that we HAVE an id
sub save {
   my $self = shift;



   # IF WE SHOULD NOT BE ABLE TO SAVE YET:   
   # if we have neither.. complain
   if( !$self->abs_path and !$self->id){
      confess('missing abs_path AND id, cant save()');   
   }
   






   # IF WE HAVE NOT SAVED YET:
   if ( $self->abs_path and !$self->id){
      
      # then this is either a new entry, or an entry whose id we have not loaded

      my $id = $self->_file_id_request($self->abs_path)
         or confess('cant make files table entry for '.$self->abs_path);

      $self->id_set($id);

      # call save, deletes and saves again all metadata table entries for this id
      $self->SUPER::save();
      return 1;
   }
   









   # IF WE GOT AN ID FROM A SEARCH   
   # if we just have id, that is, they maybe searched got a result id and appended
   # meta to it and save.. then we need to make sure there really is an entry in the files table
   if( $self->id and !$self->abs_path ){
      
      # there MUST be an abs path entry in files table

      my($abs_path,$host_id) = $self->_filesystem_args_get($self->id)
         or warn($self->id. ' id has no entry in files table, will not save.')
         and return;

      $self->abs_path_set($abs_path);
      $self->host_id_set($host_id) if defined $host_id;

      # now we can save
      $self->SUPER::save();
      return 1;  
   }


   



   


   # IF WE ARE SAVING A SECOND TIME FOR SOME REASON   
   #what if we have BOTH id AND abs_path ???
   #if ( $self->abs_path and $self->id ){
   
      # check that there really is such an entry in the db???
      
      $self->_file_entry_exists($self->id, $self->abs_path, $self->host_id )
         or croak( sprintf "there is no such entry in the db: %s %s ", $self->id, $self->abs_path);
         
   #}
   
   $self->SUPER::save();
   return 1;
}


sub abs_path_exists {
   my $self = shift;
   return $self->_file_id_get($self->abs_path, $self->host_id);   
}



1;

__END__

=pod

=head1 NAME

Metadata::DB::File - metadata object about a file

=head1 SYNOPSIS

   use Metadata::DB::File;
   
   my $f = Metadata::DB::File->new({ 
      DBH => $dbh, 
      abs_path => '/home/myself/file',
   });

   $f->set('client' => 'James Mahoney');      
   $f->save;   
   my $id1 = $f->id;

   

   my $f2 = Metadata::DB::File->new({ DBH => $dbh, id => $id1 });   
   
   $f2->get('client'); #  eq 'James Mahoney'

   
   my $f = Metadata::DB::File::Base->new({ 
      DBH => $dbh, 
      abs_path => '/home/myself/this',
      host_id => 3,      
   });





=head1 DESCRIPTION

This is the 'file' counterpart to Metadata::DB::Base

This lets you store metadata in a database, about a file on disk
The system is extremely adaptive.
The manner in which we store metadata and the way in which we store information on what the
resources are, is separate.

You can store info on many files on many computers.


To load the file data.
The object must know which record you are referring to.
You can tell it either the id, or the absolute path and host to record.



=head1 METHODS

In addition to all the methods in Metadata::DB::Base ..

=head2 new()

you can specify arguments 'id' or 'abs_path', and optionally 'host_id'
otherwise you should use file_set()


   id
      file id, same as in metadata table, only reason you should have this
      for the constructor is out of a search query
   
   abs_path
      absolute path to file

   host_id
      optional, not currently implemented, but you could use it
   
     
   abs_path_resolve
      boolean, if we should normalize the paths with Cwd::abs_path
      if a host id is set, will ignore
      default is 0

=head2 id_exists()

is record in metadata table by id? (See Metadata::DB)

=head2 abs_path_exists()

is the record in files table by path? (and host_id if set)

=head2 file_set()

argument is file id or abs_path and optionally host_id

   $f->file_set('/home/hi/there');
   $f->file_set('/home/hi/there',4); # with host id
   $f->file_set(43); # via id only
   
if first arg is a number, we interpret as an id

=head2 abs_path()

returns abs path, must be set via constructor 

=head2 host_id()

returns host id if any is set

=head2 host_id_set()

=head2 abs_path_set()




=head1 SETTING UP THE DATABASE


   use Metadata::DB::File::Base;

   my $s = Metadata::DB::File::Base->new({ DBH => $dbh });

   $s->table_metadata_check;
   $s->table_files_check;

   exit;


=head1 SEE ALSO

Metadata::DB
Metadata::DB::File::Base


=cut



=for NOTES

I would like to be able to instance these ways:

Example 1

   my $f = Metadata::DB::File::Base->new({
      DBH => $dbh,
   });

   $f->abs_path_set('/home/myself/hey',$hostid);

   $f->set( age => 4 ); # does not need to call load or save

   $f->get('author'); # calls load, does NOT generate id unless there already

   $f->set( author => 'leo' ); # does not call load, does not generate id

   $f->id; # will call load, will generate id if not there

   

Example 2

   my $f = Metadata::DB::File::Base->new({
      DBH => $dbh,
   });

   $f->id_set(2); # calls load, does NOT generate id, croaks if not in db

   $f->get('author'); # calls load


   













   how the identity should be determined
   

   )) via constructor id
      
      if an id is in the constructor
      should we write to db immediately?? No

      
      


   

   )) via constructor abs_path

      if abs path is in const arg
      and we ask for id, we should return undefined unless we saved or loaded



   )) via id_set
   
      id set should ONLY accept the value IF it is already in database
      id set should warn and return undef if not in db (files table)

      


   )) via abs_path_set
      
      this should not save to db auto.. ?
      if you set abs path, 
         and then request id 
         and the id is not in the db
         then none is returned, and you are warned to save first
         before you get an id


   
      
   
   

   # if you set abs path and then request id, that should make sure an entry is in the db???



=cut




