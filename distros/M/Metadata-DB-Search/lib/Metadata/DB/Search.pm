package Metadata::DB::Search;
use strict;
use vars qw($VERSION);
use LEOCHARRE::Class2;
use base 'Metadata::DB::Base';
use LEOCHARRE::DEBUG;
use Carp;
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /(\d+)/g;

__PACKAGE__->make_constructor();
__PACKAGE__->make_accessor_setget({
   search_params           => [],
   _searches_run_count     => 0,
   _results_hashref        => {},
   _default_search_type    => 'like',
});


*{search_reset} = \&_search_reset;
sub _search_reset {
   my $self = shift;
   $self->_searches_run_count(0);
   $self->search_params([]);
   $self->_results_hashref({});
   debug();
   return 1;
}


# =============================== search params
*{search_params_arrayref} = \&search_params;

sub search_params_add {
   my $self = shift;
   my $a = $self->search_params;
   while( scalar @_ ){
      my ($key, $val, $type ) = (shift, shift, shift);
      my $arref = $self->__array_to_search_params($key,$val,$type);
      #print STDERR "  - $key, $val, $type\n" if DEBUG;
      push @$a, $arref;  
   }
   return $a;   
}
sub search_params_count {
   my $self = shift;
   my $a = $self->search_params_arrayref or return 0;
   return ( scalar @$a );
}

# TODO deprecate this ?
sub constriction_keys {
   my $self = shift;
   my @ck;
   for( @{$self->search_params_arrayref} ){
      push @ck, $_->[0];
   }
   return \@ck;
}
# hack
sub __array_to_search_params {
   my $self = shift;
   my($att,$val,$type) = @_;
   if ( $att=~s/:(\w+)$// ) {
      $type ||= $1;
   }
   $type ||= $self->_default_search_type;
   return [$att,$val,$type];
}






*{search} = \&layered_search; 
#  a layered search is searching on multiple vectors(?), mutiple conditions (constraints)
sub layered_search { # multiple key lookup and ranked
   my $self = shift;

   my @strayargs=();

   ARG: while( scalar @_ ){
      my $arg = shift;
      defined $arg or next;

   
      if( ref $arg eq 'HASH' ){
         debug('hash');
         while( my($k,$v) = each %{$arg} ){
            #print STDERR "$k $v, " if DEBUG;
            $self->search_params_add($k,$v);            
         }
         next ARG;
      }

      elsif( ref $arg eq 'ARRAY' ){
        $self->search_params_add(@$arg);   
        debug('array');
        next ARG;
      }
      else {
         debug('stay arg');
         push @strayargs, $arg;
      }   
   }

   
   if( my $argcount = scalar @strayargs ){
      $argcount == 2 or $argcount == 3 or die('bad args to search()');
      $self->search_params_add(@strayargs);      
   }


   $self->search_params_count or die('missing search params');
   

   
   QUERY: for( @{$self->search_params_arrayref} ){    
      my $ids = $self->_execute_search_run( @$_ );
      scalar @$ids 
         or next QUERY; # TODO actually if none here we should go ahead and return no results

		next QUERY;
	}

   return $self->ids; # will only return those in all matches
}





sub _id_was_in_results_how_many_times {
   my($self, $id) = @_;
   defined $id or die;
   my $count = $self->_results_hashref->{$id};
   $count ||= 0;   
   return $count;
}

# also known as ids
*{ids} = \&_ids_present_in_all_search_results;
sub _ids_present_in_all_search_results {
   my $self = shift;

   # if no search was run, then forget it
   my $runcount = $self->_searches_run_count or die('no searches run yet');
   debug("runs: $runcount");
   
   # if we only ran one search, then we dont need to filter
   if ( $runcount == 1 ){
      return $self->_results_arrayref;
   }

   # if we ran many, we only want the ones that match ALL searches  
   my $results = $self->_results_hashref;
   my @inall = grep { $results->{$_} == $runcount } keys %$results;

   # print STDERR "\n" if DEBUG;

   return \@inall;
}

sub ids_count {
   my $self = shift;
   return ( scalar @{$self->ids} );
}

# wrappers...

sub search_morethan {
   my($self,$att,$val) = @_;
   defined $val or confess('missing val arg');
   return ($self->search( $att, $val, 'morethan'));
}

sub search_like {
   my($self,$att,$val) = @_;
   defined $val or confess('missing val arg');
   return ($self->search( $att, $val, 'like'));
}

sub search_lessthan {
   my($self,$att,$val) = @_;
   defined $val or confess('missing val arg');
   return ($self->search( $att, $val, 'lessthan'));
}

sub search_exact {
   my($self,$att,$val) = @_;
   defined $val or confess('missing val arg');
   return ($self->search( $att, $val, 'exact'));
}

# ONE search type, 
# this only returns ids, that's all
# does not calculate overlaps
#
# my $ids = _search( 'name:like' => 'joe'         );
# my $ids = _search(  name       => 'joe'         );
# my $ids = _search( 'name',        'joe', 'like' );
# my $ids = _search( 'name:like' => 'joe', 'exact' );  exact overrides, usage warning is issued
sub _execute_search_run { # execute_search_run
   my $self = shift;
   my ($att, $val, $type) = @_;
   
   my $runcount = $self->_searches_run_count;

   my $_type;
   if ( $att=~s/:(\w+)$// ) {
      $type ||= $_type;
   }
   $type ||= $self->_default_search_type;

   defined $val or confess('missing val argument');

   if ( $type eq 'like' ){
      $val = "\%$val\%";
   }

	debug(" QUERY : $type, $att, $val ..");



   my $sth = $self->get_search_type_handle($type);
   $sth->execute($att, $val) or die($self->dbh->errstr);

   my $id; # for binding
   my @ids = ();
   $sth->bind_columns(\$id);


   my $results = $self->_results_hashref;

   while( $sth->fetch ){
      push @ids, $id;

      # if there are previous runs.. only record a hit if it exists alrady
      if( $runcount ){
         if( exists $results->{$id} ){
            $results->{$id}++; # record a hit
         }
      }
      else {
         $results->{$id}++; # record a hit
      }
   }

   # increment the searches run counter
   $self->_searches_run_count( ++$runcount );

   return \@ids;
}


sub _results_arrayref {
   my $self = shift;
   my @a = keys %{$self->_results_hashref};
   return \@a;
}


# ----------------------
# search types code etc

sub search_types_arrayref {
   my $self = shift;
   my @t = keys %{$self->search_types_hashref};
   return \@t;
}

sub search_types_hashref {
   my $self = shift;
   
   unless( $self->{_get_sth_statement} ){

      my ($table,$colk,$colv,$coli) = ( 
         $self->table_metadata_name, 
         $self->table_metadata_column_name_key, 
         $self->table_metadata_column_name_value, 
         $self->table_metadata_column_name_id );

      $self->{_get_sth_statement} = {
          'like'     => "SELECT $coli FROM $table WHERE $colk=? and $colv LIKE ?",
          'exact'    => "SELECT $coli FROM $table WHERE $colk=? and $colv = ?",
          'lessthan' => "SELECT $coli FROM $table WHERE $colk=? and $colv < CAST( ? AS SIGNED )",
          'morethan' => "SELECT $coli FROM $table WHERE $colk=? and $colv > CAST( ? AS SIGNED )",
      };	
   }
   return $self->{_get_sth_statement};
}

sub get_search_type_handle {
   my($self,$type) = @_;
   defined $type or confess('missing type');
   my $sql = $self->search_type_exists($type) or confess("search type $type does not exist");

   my $sth = $self->dbh->prepare_cached($sql) or die($self->dbh->errstr);   
   return $sth;
}

sub search_type_exists {
   my($self,$type) = @_;
   defined $type or confess('missing type');
   return ( $self->search_types_hashref->{$type} or 0 );
}


# end search types ------


1;

__END__

=pod

=head1 NAME

Metadata::DB::Search - search a metadata table

=head1 SYNOPSES

=head2 Example 1

This example returns all metadata record ids that match all of the requirements..

   use Metadata::DB::Search;
   
   my $s = Metadata::DB::Search->new({ DBH => $dbh });

   $s->search({
      'age:exact'       => 24,
      'first_name:like' => 'jo',   
      'speed:morethan'  => 40,
   });

   $s->ids_count or die('nothing found');

   for my $id (@$ids) {
      my $meta = $s->record_entries_hashref($id);
   }
   
Start a new search..
   
   $s->search_reset;

   $s->search( ... );



=head2 Example 2i

You want to search every record that has an attribute of name matching 'jo' in a value, and the attribute age which has a value over '24'.
Here are ways you can do that:

   my $ids = $s->search({
      'age:morethan' => 24,
      'name' => 'jo',
   });

Or

   my $ids = $s->search(
      [ age  => '24', 'morethan'],
      [ name => 'jo'],   
   );

Or

   my $ids_olderthan = $s->search( age => 24, 'morethan' );

   my $ids_namelike  = $s->search( name => 'jo' );

   my $ids_matching_both_constraints = $s->ids;




   
=cut


=head1 DESCRIPTION

This module is for searching a Metadata::DB metadata table in a database.
It returns matching metadata record identifiers.

=head1 METHODS

=head2 new()

Argument is hashref with database handle.

   my $s = Metadata::DB::Search->new({ DBH => $dbh });

=head2 search()

optional argument is a hash ref with search params
these are key value pairs
the value can be a string or an array ref

   $s->search({
      age => 25,
      'name:exact' => ['larry','joe']
   });

Returns array ref of ids matching.

=head3 Possible search types 

Default is 'like'.

=over 4

=item like

=item exact

=item lessthan

=item morethan

=back

=head2 search_morethan()

First argument is attribute name, second argument is value.

   $s->search_morethan( age => 20 );

Returns all ids of records that match this search.

=head2 search_lessthan()

First argument is attribute name, second argument is value.
Returns all ids of records that match this search.

=head2 search_like()

First argument is attribute name, second argument is value.
Returns all ids of records that match this search.

=head2 search_exact()

First argument is attribute name, second argument is value.
Returns all ids of records that match this search.

=head2 search_reset()

Resets the search. 
Returns all ids of records that match this search.

=head2 ids()

Returns array ref of matching ids, results, in metadata table that meet the criteria.
If you run multiple searches before calling search_reset(), the ids returns are only the ones
that were returned in every search result set.


=head2 ids_count()

Returns count of how many search results we have.

=head2 SEARCH TYPES

=head2 search_type_exists()

argument is search type label, such as 'like', 'exact', 'morethan', 'lessthan'

=head2 search_types_arrayref()

returns the names of the search types

=head2 search_types_hashref()

returns the search types names as keys and sql statements for each

=head2 

   search( att => val , type )

   search( 
      att => val,
      att => val,
      att => val,
   );



=head2 record_entries_hashref()

Argument is id. Returns all entries in metadata with said id, in a hash ref.
See also Metadata::DB.


=head2 SEARCH PARAMS

An alternative to providing arguments all at once to search() is to incrementally
add the parameters.
   
   $s->search_params_add( name => 'jimmy' );
   $s->search_params_add( age  => 45, 'morethan' );
   $s->search_params_add( 'age:lessthan'  => 65 );

   $s->ids;

=head3 search_params() search_params_arrayref()

returns array ref, each element is an array ref with three elements, the attribute name, the value, and the search type.

=head3 search_params_add()

First argument is attribute name. Second argument is value.
Optional third argument is search type, defaults to 'like'.

=head3 search_params_count()

returns how many search params we have

=head3 constriction_keys() DEPRECATED

returns array ref of what the search params were for the search, not the types


=head1 ADDING A SEARCH TYPE

This is in infancy.
   
   my ( $table_name, $col_id, $col_key, $col_val ) =
      $s->table_metadata_name,
      $s->table_metadata_column_name_id,
      $s->table_metadata_column_name_key,
      $s->table_metadata_column_name_value );

   $self->search_types_hashref->{custom1} =
      "SELECT $col_id FROM $table_name WHERE $col_key=? and $col_val LIKE ?";

All searches execute with two arguments, the attribute name, and the value specified.
So the above search would work as..

   $s->search( age => 34 , 'custom1' );

The $col_key ? would receive 'age' and the $col_val would receive '34'.

This does not leave a lot of wiggle room, indeed. Feed free to code your own search method 
and contribute back to the project.

Any search methods you add will work with the other search methods to find ids that match
all searches run.
All search methods return an array ref with ids matching that cosntraint.
All seeach methods should increment the searches run counter.

=head1 SEE ALSO

Metadata::DB
Metadata::DB::Indexer
Metadata::DB::WUI

=head1 CAVEATS

This is a work in progress.

=head1 BUGS

Please contact the AUTHOR of any bugs.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut
