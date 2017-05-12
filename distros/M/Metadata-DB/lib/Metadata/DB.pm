package Metadata::DB;
use strict;
use LEOCHARRE::DEBUG;
use LEOCHARRE::Class2;
use base 'Metadata::Base';
use base 'Metadata::DB::Base';
use Carp;
use vars qw($VERSION);
$VERSION = sprintf "%d.%02d", q$Revision: 1.15 $ =~ /(\d+)/g;

__PACKAGE__->make_constructor();
__PACKAGE__->make_accessor_setget({
   loaded => undef,
   id => undef,   
});
no warnings 'redefine';

# overriding  Metadata::Base::Write
*write = \&save;
sub save {
   my $self = shift;
   #my $id = $self->id or confess('no id is set');
   my $id;
   unless( $id = $self->id ){
      # gen new
      
      $id = $self->table_metadata_last_record_id + 1; #thus would set to 1 in none yet
      $self->id($id);
   }


   $self->_record_entries_delete( $id );
   $self->_table_metadata_insert_multiple( $id, $self->get_all );
   
   return $id;
}


#does obj id exist in db
# if id_exists just returns entries_count, might as well be an alias
#sub id_exists { $_[0]->entries_count }
*id_exists = \&entries_count;

sub entries_count {
   my $self = shift;
   my $id = $self->id or warn("no id is set");
   return $self->_record_entries_count($id);
}


*elements_count = \&Metadata::Base::size;
#sub elements_count {
#   my $self = shift;
#   my @e = $self->elements;
#   my $c = scalar @e;
#   debug("$c\n");
#   return $c;
#}


# take object and return meta hash ref of what it holds
sub _get_meta_from_object {
   my $self = shift;
   
   my $meta = {};
   
   my @elements = $self->elements or return {};
   
   
   my $c = $self->elements_count;
   debug("[count was $c], have: [@elements]\n");

   for my $key (@elements){
      my @values = $self->get($key);
      $meta->{$key} = \@values;
   }
   return $meta;
}
*get_all = \&_get_meta_from_object;


# overriding Metadata::Base::Read
*read = \&load;
sub load {
   my $self = shift;

   my $id = $self->id or confess('cannot load, no id is set, no id was passed as arg');
   #debug('calling clear..');
   #$self->clear;
   $self->loaded(1);

   if ( my $meta= $self->_record_entries_hashref($id) ){
      debug("found meta for: $id");
      $self->add(%$meta); # what happens if we load twice???
   }
   return 1;
}


sub add {
   my $self = shift;

   while( scalar @_){
      my($key,$val) = (shift,shift);
      defined $key and defined $val or confess('undefined values');
      #debug("adding $key:$val\n");
      # TODO , what if $val is an array ref?? then... is set just recording ONE ????
      # Metadata::Base says if the value is array ref, then all vals are recorded
      $self->set($key, $val);
   }
   return 1;
}



# lookup
sub lookup {
   my $self = shift;

   # are there any atts set??
   $self->elements or $self->errstr("No elements present, no atts.") and return;
   
   my $metaref = $self->get_all;
   my $found_id = $self->_find_record_id_via_record_entries_hashref($metaref) or return;
   # load it? i guess yes

   $self->id($found_id);
   $self->load;
   $found_id;
}






1;

__END__

=pod

=head1 NAME

Metadata::DB

=head1 SYNOPSIS

   use Metadata::DB;

   my $dbh;
   my $o = new Metadata::DB($dbh);
   $o->load;
   $o->set( name => 'jack' );
   $o->set( age  =>  14 );
   $o->id(4);
   $o->save;


   my $o2 = new Metadata::DB($dbh);
   $o2->id(4);
   $o2->load;
   $o2->get( 'name' );
   $o2->set( 'age' => 44 );


=head2 Loading metadata from db

=over 4

=item via constructor

If you pass the id to the constructor, it will attempt to load from db.

   my $o = new Metadata::DB({ DBH => $dbh, id => 'james' });

=item via methods

You can directly tell it what the id will be , and then request to load.

   my $o = new Metadata::DB({ DBH => $dbh });
   $o->id('james');
   $o->load;

=item checking for record

   my $o = new Metadata::DB({ DBH => $dbh });
   $o->id('james');
   $o->load; # you must call load
   $o->id_exists;

=head1 DESCRIPTION

Inherits Metadata::Base and all its methods.

=head2 new()

Argument is hash ref with at least a DBH argument, which is a database handle.

   my $o = Metadata::DB->new({ DBH = $dbh });

Optional argument is 'id'.

=head2 id()

Perl setget method.
Arg is number.

=head2 id_exists()

Returns boolean.
If the id is in the database, that is- if the record by this id has any entries in the 
metadata table, this returns true.

=head2 entries_count()

Returns number of entries for this record.

=head2 set()

Works like Metadata::Base::set()

   $o->set( name => 'Jack' );

=head2 elements()

See Metadata::Base.

=head2 add()

Works like set(), only you can provide many entries.

   $o->add(
      name => 'this',
      age => 4,
   );

=head2 write(), save()

Save to db. You call this to create a new record as well.
Returns id.

=head2 load(), read()

Will attempt to load from db.
YOU MUST CALL load() to check what is in the database.
If load is not called or triggered, the data in the object is just the data in the object.
Instead of a representation of what is or may be stored.

=head2 loaded()

Returns boolean
If load() was triggered or called or not.

=head2 lookup()

Takes no argument.
Returns record id.
On fail returns undef, reason for failure is in errstr().

This is another kind of load() method.
(Internally it's also a kind of very specific search.)
It requires that first you have some attribute set() in the instance.
It will look up the records by those attributes, if one and one only matches those 
attributes exactly, then the record's id() is automatically set and load() is called.

For example, if you have a "person" record. That you know contains an attribute called 
"last_name" with value "Jefferson"- If there is only one record matching that, you can 
load the metadata record via the last name.

   my $m = Metadata::DB->new({ DBH => $dbh });
   $m->set( last_name => 'Jefferson' ); # has not yet been loaded
   $m->lookup or print ("was not found because :".$m->errstr ) and exit;

   # now you can access all the record's metadata which has been loaded..
   my $record_id = $m->id;
   my $last_name = $m->get('last_name');
   my $first_name = $m->get('first_name');
   # etc..

Note that if you had had two records with last name 'Jefferson', lookup() would fail,
and errstr() would contain a message saying that too many records matched.

=head2 get_all()

Returns hashref with all meta.
This only returns what is stored in the object.
Thus..

   my $m = Metadata::DB->new({ DBH => $dbh });
   $m->id( 3 );
   $m->set( name => 'billy');

   $m->get_all; # returns { name => 'billy' }

If you want to get everything that may be in the database, call load() or lookup().

=head2 get()

See Metadata::Base.

   $o->get('name');

=head1 CAVEATS

WARNING
Calling save() before load() will delete all record metadata previously saved.

Delete ALL metadata with id 5 and save only 'name marc'.

   my $m = Metadata::DB->new({ DBH => $dbh, id => 5 });
   $m->set( name=> 'marc' );
   $m->save;

After, this will NOT load the metadata 'name marc':

   my $m = Metadata::DB->new({ DBH => $dbh, id => 5 });
   $m->get( 'name' );

This example WILL load the metadata:

   my $m3= Metadata::DB->new({ DBH => $dbh, id => 5 });
   $m->load;
   $m->get( 'name' );

This example will NOT delete metadata and will add instead:

   my $m = Metadata::DB->new({ DBH => $dbh, id => 5 });
   $m->load;
   $m->set( age => 25 );
   $m->save;

Why? Why not just override get and get all to take care of this?
Wny not just call load() automatically??
Because that's up to you. You MAY want to NOT do this cpu intensive operation.
Maybe you want to insert a million entries really quickly, thus you dont want to load
every time, maybe you already know there is nothing in there.

=head1 SEE ALSO

Metadata::Base
Metadata::DB::Base
Metadata::DB::Indexer
Metadata::DB::Analizer
Metadata::DB::WUI

=head1 BUGS

Please contact the AUTHOR for any issues, suggestions, bugs etc.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

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
