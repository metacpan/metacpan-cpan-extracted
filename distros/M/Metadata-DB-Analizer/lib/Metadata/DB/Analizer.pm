package Metadata::DB::Analizer;
use strict;
use Carp;
use warnings;
use LEOCHARRE::DEBUG;
use vars qw($VERSION);
use base 'Metadata::DB::Base';
use LEOCHARRE::Class::Accessors 
   multi => ['search_attributes_selected','_attributes'], 
   single => ['attribute_option_list_limit'];

no warnings 'redefine';
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /(\d+)/g;



# LIST ALL ATTS AVAILABLE
*get_attributes = \&_attributes;
sub _attributes {
   my $self = shift;
   unless( $self->_attributes_count ){
      debug('_attributes_count returned none.. ');
      my $atts = $self->_distinct_attributes_arrayref;
	ref $atts eq 'ARRAY' or die('not array ref');
      debug("got atts scalar: [".scalar @$atts."]");
      for(@$atts){
         $self->_attributes_add($_);
      }
         
   }
   return $self->_attributes_arrayref;
}

sub _distinct_attributes_arrayref {
   my $self = shift;
   
   my $keys = $self->dbh->selectcol(
      sprintf
      "SELECT DISTINCT %s FROM %s",
      $self->table_metadata_column_name_key,
      $self->table_metadata_name,
      );
      debug("keys @$keys\n");
   return $keys;
}






# get ratio of attributes, how many 'age', 'name', and 'color' etc atts are there

sub get_attributes_ratios {
   my $self = shift;

   my $at = $self->get_attributes_counts;
   
   $at->{all} or croak('no atts in table ?');

   my $attr ={};

   for my $att ( keys %$at){      

      # total entries
      $attr->{$att} = 
         int (($at->{$att} * 100) / $at->{all} );      
      
   }

   delete $attr->{all};
   return $attr;
}

sub get_attributes_by_ratio {
   my $self = shift;   

   my $_att = $self->get_attributes_ratios;

   my @atts = sort { $_att->{$b} <=> $_att->{$a} } keys %$_att;
   return \@atts;
}


sub get_attributes_counts {
   my $self = shift;

   my $attr ={};
   my $_atts = $self->get_attributes;

   my $total=0;
   
   for my $att (@$_atts){      

      # total entries
      $attr->{$att} = $self->attribute_all_unique_values_count($att);      
      $total+= $attr->{$att};
   }

   # actaully we can just add all the vals, can get diff numb.. but.. whatever- not urgent.
   $attr->{ all } = $total; #$self->dbh->rows_count($self->table_metadata_name);

   return $attr;   
}


sub get_records_count {
   my $self = shift;

   my $idname = $self->table_metadata_column_name_id;
   my $tablename = $self->table_metadata_name;
   my $q = $self->dbh->prepare("SELECT count(DISTINCT $idname) FROM $tablename");
   $q->execute;

   my $count;
   $q->bind_columns(\$count);
   $q->fetch;
   $count ||=0;
   return $count;
}

# end analysis












sub search_attributes_selected {
   my $self = shift;
   
   unless( $self->search_attributes_selected_count ){
      debug("no search attributes list has been selected, we will chose all");
      my @params = sort @{ $self->get_attributes };
      debug("params are [@params]\n");
      for (@params){
         $self->search_attributes_selected_add($_);
      }
   }

   # weed out ones that have one option only? maybe not since the alternative is none..
   # because one option for an att, the alternative is still valid.
   

   return $self->search_attributes_selected_arrayref;
}




# start single att methods
# INTERFACE

# for each of the attributes, how many variations are there?
# if there are less then x, then make it a drop down box

# this is not meant to be used online, only offline, as a regeneration of query interface


# if they are more then x choices, then return false
# what we used this for is making a drop down 
sub attribute_option_list {
   my( $self, $attribute, $_limit ) = @_;   
   defined $attribute or croak('missing dbh or attribute name');
   
   # this is safe because it returns what we wet, if we set, otherwise returns anyway
   my $limit = $self->attribute_option_list_limit( $attribute, $_limit ); 
   
   
   # order it 
   my $list = $self->attribute_all_unique_values($attribute,$limit) 
      or return;

   my $sorted = _sort($list);
   
   # unshift into list a value for 'none' ?
   
   
   return $sorted;
}

sub attribute_option_list_limit {
   my($self, $att, $limit ) = @_;

   $self->{_attlimit} ||={};
   $self->{_attlimit_default} ||= 100;
   
   if( defined $att and defined $limit){
      debug("att $att, limit $limit");
      $self->{_attlimit}->{$att} = $limit;   
      return $limit;
   }

   elsif ( defined $att and ( ! defined $limit ) ){ 
   
      if( $att=~/^\d+$/ ){ # then this is to set default limit globally
         debug("setting default limit to $att");
         $self->{_attlimit_default} = $att;
         return $self->{_attlimit_default};
      }
      
      else { # we are requesting the limit value for this att
         
         
         my $specific_limit =  $self->{_attlimit}->{$att};
         unless( $specific_limit ){
            debug("att $att did not have explicit limit, returning default");
            return $self->{_attlimit_default}; 
         }
         
         debug("att $att had specific limit set to $specific_limit");
         return $specific_limit;
      }

   }

   # no args, just return the default
   debug("returning default limit of ".$self->{_attlimit_default});
   
   return $self->{_attlimit_default};   
}


sub _sort { # mostly to sort values
   my $list = shift;
   
   for(@$list){
      $_=~/^[\.\d]+$/ and next;
      
      # then we are string!      
      return [ sort { lc $a cmp lc $b } @$list ];      
   }
   
   # we are number
   return [ sort { $a <=> $b } @$list ];   
}


#just for heuristics!!! not accurate!
sub _att_uniq_vals {
   my ($self,$att) = @_;
   defined $att or croak('missing att');

   my $limit = 1000;

   # unique vals

   # this is for heuristics
	my $_sql = sprintf "SELECT DISTINCT %s FROM %s WHERE %s=? LIMIT ?",       
      $self->table_metadata_column_name_value,
      $self->table_metadata_name,
      $self->table_metadata_column_name_key;

   my $s = $self->dbh->prepare_cached( $_sql )
      or die( "statement [$_sql], ".$self->dbh->errstr );
   
   $s->execute($att,$limit) or die( $self->dbh->errstr );
   
   my $value;
   $s->bind_columns(\$value);

   my @vals;
   while($s->fetch){
      push @vals,$value;
   }
   return \@vals;
}




sub attribute_all_unique_values {
   my ($self,$attribute,$limit) = @_;
   defined $attribute or croak('missing dbh or attribute name');
   
   my $_limit;
   if(defined $limit){
      $_limit = ' LIMIT '.($limit+1);
   }
   else {
      $_limit = '';
   }

   debug("limit = $limit\n") if $limit;
   
   

   # unique vals
   my $q = sprintf "SELECT DISTINCT %s FROM %s WHERE %s='%s' $_limit",
      $self->table_metadata_column_name_value,
      $self->table_metadata_name,
      $self->table_metadata_column_name_key,
      $attribute,
   ;
   #   debug(" query: $q \n");
   
   my $r = $self->dbh->selectall_arrayref($q);
   
   my @vals = ();
   for(@$r){
      push @vals, $_->[0];
   }         

   if(scalar @vals and $limit and (scalar @vals > $limit)){
      debug("limit [$limit] exceeded, try higher limit?\n");
      return;
   }
   return \@vals;
}


# pass it one attribute name, tells how many there are (possibilities) distinct values
sub attribute_all_unique_values_count { # THIS WILL BE SLOW
   my ($self,$attribute) =@_;
   defined $attribute or confess('missing attribute arg');

   my $vals = $self->attribute_all_unique_values($attribute);
   my $count = scalar @$vals;
   return $count;
}

sub attribute_type_is_number {
   my ($self,$att) = @_;
   defined $att or croak('missing attribute name');

   my $vals = $self->_att_uniq_vals($att) or return;
   scalar @$vals or return;
   for (@$vals){
      /^\d+$/ or return 0;      
   }
   return 1;
}


# end single att methods






1;

__END__

=pod

=head1 NAME

Metadata::DB::Analizer - methods to analize database metadata table entries 


=head1 SYNOPSIS

   use DBI;
   use Metadata::DB::Analizer;

   my $absdb = '/home/myself/metadata.db';

   my $dbh = DBI->connect("dbi:SQLite:dbname=$abs","","");

   my $a = Metadata::DB::Analizer->new({ DBH => $dbh });

   # we are storing metadata entries for how many things?
   $a->get_records_count;

   # what are all the attribute labels we are storing for all things?
   my $atts = $a->get_attributes;

   for my $att (@$atts) {
      
      # how many different kinds of values does this att have for all things?
      my $count = $a->attribute_all_unique_values_count($att);
      my $att_is_number = $a->attribute_type_is_number($att);

      print "Attribute $att has $count possible value options. The values are all numbers? $att_is_number\n";
   }  



=head1 DESCRIPTION

These methods help analize a table in a database about metadata.
They are meant to help create an interface to search the results.

Imagine you are storing metadata about people, you have things like first_name, last_name, etc.

This module will help create the interface, by analizing the table data.

For example, if you add 'age' attribute to the table, and there are a finite number of unique values, 
this code suggests whether to add a drop down select box (in a web interface, for example) or a search text field.

The output generated by this code can be used to generate gui interfaces with html, perltk, etc.






=head1 METHODS

=head2 new()

   my $dbh = your_database_connection_handle();

   my $a = Metadata::DB::Analizer->new({ DBH => $dbh });


=cut





=head2 GENERAL INSPECTION METHODS

=head3 get_records_count()

returns count of metadata records (each id is one record, athough the metadata table may contain multiple
row entries).

=cut






=head2 FUNCTIONS FOR ALL ATTRIBUTES

To inspect the metadata table's contents.

=head3 get_attributes()

returns 'all' of the attributes in the metadata table as array ref.

If you store 'age', 'phone', 'name' in your table, this returns those labels.
This is the basis of the idea here, that if you add another attribute, the search interface will
automatically offer this as a search option.

This is called internally by search_attributes_selected() if you dont select your own out of the list.
this only means what attributes to OFFER the user to search by

=head3 get_attributes_by_ratio()

returns array ref of attributes, sorted by occurrences of that value.
In the above example, if there are 100 'name' entries and 8 'phone' entries, the name is closer to 
the front of the list.

=head3 get_attributes_ratios()

returns hash ref. keys are the attribute names (vals in mkey)- values are the percentage
of occurrence, as compared to all the entries.

=head3 get_attributes_counts()

returns hash ref. Each key is an attribute, the values are the number of occurrences.


=head3 WHAT SEARCH ATTRIBUTES TO OFFER IN THE SEARCH FORM

When we generate automatic interfaces for searching the metadata.

=head4 search_attributes_selected()

returns list of attributes that will be used in the html interface
if you do not pass a list, all attribtues are chosen
you do not need to specify what kind of selection this is, drop down or text,
the data within the databse will figure it out

this is used by generate_search_interface_loop(), in turn used by html_search_form_output().

So, if you wanted to change what shows up..

   my $i = Metadata::DB::Search::InterfaceHTML({ DBH => $dbh });

   $i->search_attributes_selected_clear;
   $i->search_attributes_selected_add('age','height','name','office');

This means if there are fewer then x 'age' possible values, a dropdown box is generated, etc.
This is also the order.


If you want to grep out all attributes that match 'path'

   my @attribute_names = sort grep { !/path/ } @{ $self->get_search_attributes }; 
   
now you need to set them as the atts the user can search by..

   $self->search_attributes_selected_clear;
   $self->search_attributes_selected_add( @attribute_names );

if you want to set default limits to all atts matching 'client' to be 1000 instead
of the default limit for all atts
   
   for my $att_name ( grep { /client/ } @attribute_names ){
   
      $self->attribute_option_list_limit( $att_name => 1000 );
   
   }



=head4 search_attributes_selected_clear()

take out all search attributes to 0

=head4 search_attributes_selected_count()

=head4 search_attributes_selected_add()

arg is attribute name

=head4 search_attributes_selected_delete()

arg is attribute name. will take out of list, when generating, will not show up.

=cut




=head2 METHODS FOR ONE ATTRIBUTE

Once you know your attribute label/name.

=head3 attribute_option_list()

argument is name of attribute, optional arg is a limit number
the default limit is 100.
returns a list suitable for a select box, or returns undef if the unique values
found for this attribute exceed the limit.

For example, if you have an attribute called hair_color, you can have blonde, brunette, redhead etc.
You would want to offer this as a select box. Thus, if you have blondes and brunnettes as values
for the attribute 'hair_color' in the metadata table..

   my $options = generate_attribute_option_list($dbh,'hair_color');

   # $options = [qw( blonde redhead brunette )];

Note that if your metadata table does not have any entries such as

   id mkey        mval
   1  hair_color  auburn

Then the hair color auburn will not appear in the array ref returned.
Furthermore if there are more then 15 variations of hair color, undef is returned.
If you want to allow for more variations...

For example, if you want to list every single 'first_name' attribute as an option, regardless of how many 
there are..
   
   my $options = generate_attribute_option_list($dbh,'first_name',1000000);

Remember that the return values depend on what the database table holds!

=head3 attribute_option_list_limit()

returns defatult limit set. by default this is 100
if an attribute to be selected from has more then this count, it is offered as a field,
if it has less, it is a drop down box.
this can be overridden on a per attribtue basis also, this is just the main default

you can also set limits on a per attribute basis, to do so..

   my $limit = 
      $self->attribute_option_list_limt( $attribute_name => $number );

   my $limit_retrieved = 
      $self->attribute_option_list_limit( $attribute_name );

   my $default_limit_for_all_not_specifically_set =
      $self->attribute_option_list_limit;
      
this is a perl set get method, always returns the value

=head3 attribute_all_unique_values()

argument is dbh and atrribtue name. optional arg is limit (default is 15)
returns array ref.

if you provide the limit, and it is reached (more then 'limit' unique value occurrences) then it returns undef.

=head3 attribute_type_is_number()

argument is the attribute name
analizes the possible values and determines if they are all numbers
returns boolean

this is useful if you want to offer 'less than' option in a select box, for example

=head3 attribute_type_is_boolean()

TODO: NOT IMPLEMENTED

=cut







=head1 CAVEATS

These are meant to be used offline, they can use up cpu like mad.
Consider caching the values with Cache::File



=head1 DATABASE LAYOUT

The default metadata table columns are 
   
   id | mkey | mval

The default table name is 'metadata'.

If for some reason you have a metadata table with somewhat of a different layout,
you can change the names of the columns and table via:

   $object_instance->table_metadata_name('metadata_cars');
   $object_instance->table_metadata_column_name_key('attribute');

For more information of the database layout, please see L<Metadata::DB>

=head1 SEE ALSO

Metadata::DB::Search
Metadata::DB::Indexer
Metadata::DB::Search::InterfaceHTML
Metadata::DB::WUI
Metadata::DB
Metadata::Base

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut
