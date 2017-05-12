package File::DataClass::ResultSet;

use namespace::autoclean;

use File::DataClass::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use File::DataClass::Functions qw( is_arrayref is_hashref is_member throw );
use File::DataClass::List;
use File::DataClass::Result;
use File::DataClass::Types     qw( ArrayRef ClassName
                                   HashRef Int Maybe Object Str );
use Scalar::Util               qw( blessed );
use Subclass::Of;
use Unexpected::Functions      qw( RecordNotFound Unspecified );
use Moo;

my $class_stash = {};

# Private functions
my $_build_operators = sub {
   return {
      'eq' => sub { return $_[ 0 ] eq $_[ 1 ] },
      '==' => sub { return $_[ 0 ] == $_[ 1 ] },
      'ne' => sub { return $_[ 0 ] ne $_[ 1 ] },
      '!=' => sub { return $_[ 0 ] != $_[ 1 ] },
      '>'  => sub { return $_[ 0 ] >  $_[ 1 ] },
      '>=' => sub { return $_[ 0 ] >= $_[ 1 ] },
      '<'  => sub { return $_[ 0 ] <  $_[ 1 ] },
      '<=' => sub { return $_[ 0 ] <= $_[ 1 ] },
      '=~' => sub { my $re = $_[ 1 ]; return $_[ 0 ] =~ qr{ $re }mx },
      '!~' => sub { my $re = $_[ 1 ]; return $_[ 0 ] !~ qr{ $re }mx },
   };
};

# Public attributes
has 'list_class'    => is => 'ro',   isa => ClassName,
   default          => 'File::DataClass::List';

has 'result_class'  => is => 'ro',   isa => ClassName,
   default          => 'File::DataClass::Result';

has 'result_source' => is => 'ro',   isa => Object,
   handles          => [ qw( attributes defaults label_attr path storage ) ],
   required         => TRUE, weak_ref => TRUE;

has '_iterator'     => is => 'rw',   isa => Int, default => 0,
   init_arg         => undef;

has '_operators'    => is => 'lazy', isa => HashRef,
   builder          => $_build_operators;

has '_results'      => is => 'rw',   isa => ArrayRef,
   builder          => sub { [] }, init_arg => undef;

# Private methods
my $_get_attr_meta = sub {
   my ($types, $source, $values, $attr) = @_;

   my $sdef = $source->defaults->{ $attr };
   my $type = $source->types->{ $attr }
           // $types->{ ref $sdef || ref $values->{ $attr } || 'SCALAR' };

   return [ is => 'rw', isa => $type ];
};

my $_new_result_class = sub {
   my ($class, $source, $values) = @_;

   my $name = "${class}::".(ucfirst $source->name);

   exists $class_stash->{ $name } and return $class_stash->{ $name };

   my $except = 'delete | id | insert | name | result_source | update';
   my %types  = ( 'ARRAY',  Maybe[ArrayRef],
                  'HASH',   Maybe[HashRef],
                  'SCALAR', Maybe[Str], );
   my @attrs  = map  { $_ => $_get_attr_meta->( \%types, $source, $values, $_ )}
                grep { not m{ \A (?: $except ) \z }mx }
                    @{ $source->attributes };

   return $class_stash->{ $name } = subclass_of
      ( $class, -package => $name, -has => [ @attrs ] );
};

my $_create_result = sub {
   my ($self, $args) = @_;

   my $attr = { %{ $self->defaults }, result_source => $self->result_source };

   for (grep { exists $args->{ $_ } and defined $args->{ $_ } }
            @{ $self->attributes }, 'id', 'name') {
      $attr->{ $_ } = $args->{ $_ };
   }

   my $class = $_new_result_class->
      ( $self->result_class, $self->result_source, $attr );

   return $class->new( $attr );
};

my $_eval_op = sub {
   my ($self, $lhs, $op, $rhs) = @_;

   my $subr = $self->_operators->{ $op } or return FALSE;

   $_ or return FALSE for (map { $subr->( $_, $rhs ) ? 1 : 0 }
                           (is_arrayref $lhs) ? @{ $lhs } : ( $lhs ));

   return TRUE;
};

my $_push = sub {
   my ($self, $id, $attr, $items) = @_;

   my $attrs = { %{ $self->select->{ $id } // {} }, id => $id };
   my $list  = [ @{ $attrs->{ $attr } // [] } ];
   my $in    = [];

   for my $item (grep { not is_member $_, $list } @{ $items }) {
      CORE::push @{ $list }, $item; CORE::push @{ $in }, $item;
   }

   $attrs->{ $attr } = $list;
   return ($attrs, $in);
};

my $_splice = sub {
   my ($self, $id, $attr, $items) = @_;

   my $attrs = { %{ $self->select->{ $id } // {} }, id => $id };
   my $list  = [ @{ $attrs->{ $attr } // [] } ];
   my $out   = [];

   for my $item (@{ $items }) {
      defined $list->[ 0 ] or last;

      for (0 .. $#{ $list }) {
         if ($list->[ $_ ] eq $item) {
            CORE::splice @{ $list }, $_, 1; CORE::push @{ $out }, $item;
            last;
         }
      }
   }

   $attrs->{ $attr } = $list;
   return ($attrs, $out);
};

my $_txn_do = sub {
   my ($self, $coderef) = @_;

   return $self->storage->txn_do( $self->path, $coderef );
};

my $_update_result = sub {
   my ($self, $result, $args) = @_;

   for my $attr (grep { exists $args->{ $_ } } @{ $self->attributes }) {
      $result->$attr( $args->{ $attr } );
   }

   return $result->update;
};

my $_validate_params = sub {
   my ($self, $args) = @_; $args //= {};

   my $id = (is_hashref $args) ? ($args->{id} // $args->{name}) : $args;

   $id or throw Unspecified, [ 'record id' ], level => 2;

   return $id;
};

my $_eval_clause = sub {
   my ($self, $clause, $lhs) = @_;

   if (is_hashref $clause) {
      for (keys %{ $clause }) {
         $self->$_eval_op( $lhs, $_, $clause->{ $_ } ) or return FALSE;
      }

      return TRUE;
   }
   elsif (is_arrayref $clause) { # TODO: Handle case of 2 arrays
      return (is_arrayref $lhs) ? FALSE : (is_member $lhs, $clause);
   }

   return (is_arrayref $lhs) ? ((is_member $clause, $lhs) ? TRUE : FALSE)
                             : ($clause eq $lhs           ? TRUE : FALSE);
};

my $_find = sub {
   my ($self, $id) = @_; my $results = $self->select;

   ($id and exists $results->{ $id }) or return;

   my $attrs = { %{ $results->{ $id } }, id => $id };

   return $self->$_create_result( $attrs );
};

my $_list = sub {
   my ($self, $id) = @_; my ($attr, $attrs, $labels); my $found = FALSE;

   my $results = $self->select; my $list = [ sort keys %{ $results } ];

   $attr = $self->label_attr
      and $labels = { map { $_ => $results->{ $_ }->{ $attr } } @{ $list } };

   if ($id and exists $results->{ $id }) {
      $attrs = { %{ $results->{ $id } }, id => $id }; $found = TRUE;
   }
   else { $attrs = { id => $id } }

   my $result = $self->$_create_result( $attrs );

   $attrs = { found => $found, list => $list, result => $result, };
   $labels and $attrs->{labels} = $labels;
   return $self->list_class->new( $attrs );
};

my $_eval_criteria = sub {
   my ($self, $criteria, $attrs) = @_; my $lhs;

   for my $k (keys %{ $criteria }) {
      defined ($lhs = $attrs->{ $k eq 'name' ? 'id' : $k }) or return FALSE;
      $self->$_eval_clause( $criteria->{ $k }, $lhs ) or return FALSE;
   }

   return TRUE;
};

my $_find_and_update = sub {
   my ($self, $args) = @_; my $id = $self->$_validate_params( $args );

   my $result = $self->$_find( $id )
      or throw RecordNotFound, [ $self->path, $id ];

   return $self->$_update_result( $result, $args );
};

my $_search = sub {
   my ($self, $where) = @_; my $results = $self->_results; my @tmp;

   if (not defined $results->[ 0 ]) {
      $results = $self->select;

      for (keys %{ $results }) {
         my $attrs = { %{ $results->{ $_ } }, id => $_ };

         if (not $where or $self->$_eval_criteria( $where, $attrs )) {
            CORE::push @{ $self->_results }, $self->$_create_result( $attrs );
         }
      }
   }
   elsif ($where and defined $results->[ 0 ]) {
      for (@{ $results }) {
         $self->$_eval_criteria( $where, $_ ) and CORE::push @tmp, $_;
      }

      $self->_results( \@tmp );
   }

   return wantarray ? $self->all : $self;
};

# Public methods
sub all {
   my $self = shift; return @{ $self->_results };
}

sub create {
   my ($self, $args) = @_; $self->$_validate_params( $args );

   return $self->$_txn_do( sub { $self->$_create_result( $args )->insert } );
}

sub create_or_update {
   my ($self, $args) = @_; my $id = $self->$_validate_params( $args );

   return $self->$_txn_do( sub {
      my $result = $self->$_find( $id )
         or return $self->$_create_result( $args )->insert;

      return $self->$_update_result( $result, $args );
   } );
}

sub delete {
   my ($self, $args) = @_; my $id = $self->$_validate_params( $args );

   my $path     = $self->path;
   my $optional = (is_hashref $args) ? $args->{optional} : FALSE;
   my $res      = $self->$_txn_do( sub {
      my $result; unless ($result = $self->$_find( $id )) {
         $optional or throw RecordNotFound, [ $path, $id ];
         return FALSE;
      }

      $result->delete
         or throw 'File [_1] source [_2] not deleted', [ $path, $id ];
      return TRUE;
   } );

   return $res ? $id : undef;
}

sub find {
   my ($self, $args) = @_; my $id = $self->$_validate_params( $args );

   return $self->$_txn_do( sub { $self->$_find( $id ) } );
}

sub find_and_update {
   my ($self, $args) = @_; $self->$_validate_params( $args );

   return $self->$_txn_do( sub { $self->$_find_and_update( $args ) } );
}

sub first {
   my $self = shift; return $self->_results->[ 0 ];
}

sub last {
   my $self = shift; return $self->_results->[ -1 ];
}

sub list {
   my ($self, $args) = @_;

   my $id = (is_hashref $args) ? $args->{id} // $args->{name} : $args;

   return $self->$_txn_do( sub { $self->$_list( $id ) } );
}

sub next {
   my $self  = shift;
   my $index = $self->_iterator; $self->_iterator( $index + 1 );

   return $self->_results->[ $index ];
}

sub push {
   my ($self, $args) = @_; my $id = $self->$_validate_params( $args );

   my $list  = $args->{list} or throw Unspecified, [ 'list' ];
   my $items = $args->{items} // []; my ($added, $attrs);

   $items->[ 0 ] or throw 'List contains no items';

   my $res = $self->$_txn_do( sub {
      ($attrs, $added) = $self->$_push( $id, $list, $items );

      return $self->$_find_and_update( $attrs );
   } );

   return $res ? $added : FALSE;
}

sub reset {
   my $self = shift; return $self->_iterator( 0 );
}

sub select {
   my $self = shift;

   return $self->storage->select( $self->path, $self->result_source->name );
}

sub search {
   my ($self, $args) = @_;

   return $self->$_txn_do( sub { $self->$_search( $args ) } );
}

sub splice {
   my ($self, $args) = @_; my $id = $self->$_validate_params( $args );

   my $list  = $args->{list} or throw Unspecified, [ 'list' ];
   my $items = $args->{items} // []; my ($attrs, $removed);

   $items->[ 0 ] or throw 'List contains no items';

   my $res = $self->$_txn_do( sub {
      ($attrs, $removed) = $self->$_splice( $id, $list, $items );

      return $self->$_find_and_update( $attrs );
   } );

   return $res ? $removed : FALSE;
}

sub update {
   my ($self, $args) = @_;

   if (my $id = $args->{id} // $args->{name}) { # Deprecated
      return $self->$_txn_do( sub { $self->$_find_and_update( $args ) } );
   }

   return $self->$_txn_do( sub {
      my $updated = FALSE;

      for my $result (@{ $self->_results }) {
         my $res = $self->$_update_result( $result, $args ); $updated ||= $res;
      }

      return $updated;
   } );
}

1;

__END__

=pod

=head1 Name

File::DataClass::ResultSet - Core result management methods

=head1 Synopsis

   use File:DataClass;

   my $attr = { result_source_attributes => { schema_attributes => { ... } } };

   my $result_source = File::DataClass->new( $attr )->result_source;

   my $rs = $result_source->resultset( { path => q(path_to_data_file) } );

   my $result = $rs->search( $hash_ref_of_where_clauses );

   for my $result_object ($result->next) {
      # Do something with the result object
   }

=head1 Description

Find, search and update methods for element objects

=head1 Configuration and Environment

Defines these attributes

=over 3

=item C<list_class>

List class name, defaults to L<File::DataClass::List>

=item C<result_class>

Result class name, defaults to L<File::DataClass::Result>

=item C<result_source>

An object reference to the L<File::DataClass::ResultSource> instance
that created this result set

=item C<_iterator>

Contains the integer count of the position within the C<_results> hash.
Incremented by each call to L</next>

=item C<_operators>

A hash ref of coderefs that implement the comparison operations performed
by the L</search> method

=item C<_results>

An array of result objects. Produced by calling L</search>

=back

=head1 Subroutines/Methods

=head2 all

   @results = $rs->search()->all;

Returns all the result object references that were found by the
L</search> call

=head2 create

   $result_object_ref = $rs->create( $args );

Creates and inserts an new record. The C<$args> hash requires the
C<id> of the record to create. Missing attributes are defaulted from
the C<defaults> attribute of the L<File::DataClass::Schema>
object. Returns the new record's object reference

This behaviour changed after 0.41. It used to return the new record id

=head2 create_or_update

   $result_object_ref = $rs->create_or_update( $args );

Creates a new record if it does not already exist, updates the existing
one if it does. Returns the record's object reference

This behaviour changed after 0.41. It used to return the record id

=head2 delete

   $record_id = $rs->delete( $id_of_record_to_delete );
   $record_id = $rs->delete( { id => $record_to_delete, optional => $bool } );

Deletes a record. Returns the id of the deleted record. By default the
C<optional> flag is false and if the record does not exist an exception will
be thrown. Setting the flag to true avoids the exception and C<undef> is
returned instead

=head2 find

   $result_object_ref = $rs->find( $id_of_record_to_find } );

Finds the named record and returns an
L<result|File::DataClass::Result> object reference for it

=head2 find_and_update

   $result_object_ref = $rs->find_and_update( $args );

Finds the named result object and updates it's attributes

This behaviour changed after 0.41. It used to return the result id

=head2 first

   $result_object_ref = $rs->search( $where_clauses )->first;

Returns the first result object that was found by the C</search> call

=head2 list

   $list_object_ref = $rs->list( { id => $id } );

Returns a L<list|File::DataClass::List> object reference

Retrieves the named record and a list of record ids

=head2 last

   $result_object_ref = $rs->search( $where_clauses )->last;

Returns the last result object that was found by the C</search> call

=head2 next

   $result_object_ref = $rs->search( $where_clauses )->next;

Iterate over the results returned by the C</search> call

=head2 path

   $path = $rs->path;

Attribute L<File::DataClass::Schema/path>

=head2 push

   $added = $rs->push( { name => $id, list => $list, items => $items } );

Adds items to the attribute list. The C<$args> hash requires these
keys; C<id> the element to edit, C<list> the attribute of the named
element containing the list of existing items, C<req> the request
object and C<items> the field on the request object containing the
list of new items

=head2 reset

   $rs->reset

Resets the resultset's cursor, so you can iterate through the search
results again

=head2 search

   $result = $rs->search( $hash_ref_of_where_clauses );

Search for records that match the given criterion. The criterion is a
hash reference whose keys are record attribute names. The criterion
values are either scalar values or hash references. The scalar values
are tested for equality with the corresponding record attribute
values. Hash reference keys are treated as comparison operators, the
hash reference values are compared with the record attribute values, e.g.

   { 'some_element_attribute_name' => { '>=' => 0 } }

=head2 select

   $hash = $rs->select;

Returns a hash ref of records

=head2 splice

   $removed = $rs->splice( { name => $id, list => $list, items => $items } );

Removes items from the attribute list

=head2 storage

   $storage = $rs->storage;

Attribute L<File::DataClass::Schema/storage>

=head2 update

   $rs->update( { id => $of_element, fields => $attr_hash } );

Updates the named element

=head2 _txn_do

Calls L<File::DataClass::Storage/txn_do>

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<File::DataClass::List>

=item L<File::DataClass::Result>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
