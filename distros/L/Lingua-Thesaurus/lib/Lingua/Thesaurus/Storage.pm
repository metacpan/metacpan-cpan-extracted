package Lingua::Thesaurus::Storage;
use Moose::Role;
use Moose::Meta::Class;
use namespace::clean -except => 'meta';

#======================================================================
# ATTRIBUTES
#======================================================================

has 'params'           => (is => 'ro', isa => 'HashRef',
                           lazy => 1, builder => '_params',
                           predicate => 'has_params',
         documentation => "params saved in storage");

has 'term_class'       => (is => 'ro', isa => 'ClassName',
                           lazy => 1, builder => '_build_term_class',
                           init_arg => undef,
         documentation => "dynamic class for terms");

has 'relType_class'    => (is => 'ro', isa => 'ClassName',
                           lazy => 1, builder => '_relType_class',
                           init_arg => undef,
         documentation => "class for relTypes");

#======================================================================
# REQUIRED METHODS
#======================================================================

requires 'search_terms';
requires 'fetch_term';
requires 'related';
requires 'rel_types';
requires 'fetch_rel_type';

requires 'do_transaction';
requires 'initialize';
requires 'store_rel_type';
requires 'store_relation';
requires 'store_term';
requires 'finalize';

requires '_params';

#======================================================================
# IMPLEMENTED METHODS
#======================================================================

sub _build_term_class {
  my ($self) = @_;

  # compute subclass name from the list of possible relations
  my @rel_ids       = $self->rel_types;
  my $subclass_name = join "_", "auto", sort @rel_ids;
  my $parent_class  = $self->_parent_term_class;
  my $pkg_name      = "${parent_class}::${subclass_name}";

  # build subclass (only if it does not already exist)
  no strict 'refs';
  unless (%{$pkg_name."::"}) {
    # build a closure for each relation type (NT, BT, etc.)
    my %methods;
    foreach my $rel_id (@rel_ids) {
      $methods{$rel_id} = sub {my $self = shift;
                               my @rel  = map {$_->[1]} $self->related($rel_id);
                               return wantarray ? @rel : $rel[0];};
    }

    # dynamically create a new subclass
    my $meta_subclass = Moose::Meta::Class->create(
      $pkg_name,
      superclasses => [$parent_class],
      methods      => \%methods,
     );
    $meta_subclass->make_immutable;
  }

  return $pkg_name;
}



sub _parent_term_class {
  my $self = shift;
  my $parent_term_class =  $self->params->{term_class}
                       || 'Lingua::Thesaurus::Term';
  Module::Load::load $parent_term_class;
  return $parent_term_class;
}


sub _relType_class {
  my $self = shift;
  my $relType_class =  $self->params->{relType_class} 
                    || 'Lingua::Thesaurus::RelType';
  Module::Load::load $relType_class;
  return $relType_class;
}

1;

__END__

=head1 NAME

Lingua::Thesaurus::Storage - Role for thesaurus storage

=head1 DESCRIPTION

This role specifies the interface for thesaurus storage classes.


=head1 METHODS

=head2 Retrieval methods

=head3 search_terms

Implementation for L<Lingua::Thesaurus/"search_terms">.

=head3 fetch_term

Implementation for L<Lingua::Thesaurus/"fetch_term">.

=head3 related

Implementation for L<Lingua::Thesaurus::Term/"related">.

=head3 rel_types

Implementation for L<Lingua::Thesaurus/"rel_types">.

=head3 fetch_rel_type

Implementation for L<Lingua::Thesaurus/"fetch_rel_type">.


=head2 Populating the database

=head3 initialize

Called by an IO class to initialize storage before a load operation.

=head3 do_transaction

  $storage->do_transaction($coderef);

Will execute C<$coderef> within a transaction. This is used
by L<Lingua::Thesaurus::IO/"load"> to store all terms and relations
in a single step.

=head3 store_term

  my $term_id = $storage->store_term($term_string);

Stores a new term, and returns the unique storage id for this
term. Depending on the implementation, an exception could be raised if
several attempts are made to store the same C<$term_string>.


=head3 store_rel_type

  $storage->store_rel_type($rel_id, $description, $is_external);

Stores a new relation type.

=over

=item *

C<$rel_id> is a unique identifier string for this relation type 
(such as C<'NT'> or C<'UF'>).

=item *

C<$description> is an optional free text description

=item *

C<$is_external> is a boolean which tells whether related items
will be other terms or external data.

=back



=head3 store_relation

  $storage->store_relation($term_id, $rel_id, $related,
                           $is_external, $inverse_id);

Stores a relation, where

=over

=item *

C<$term_id> is the unique identifier for the first term in the relation

=item *

C<$rel_id> is the unique identifier for relation type

=item *

C<$related> is an arrayref of items to relate to the term;
if C<$is_external> is true, these items can be any scalar;
if C<$is_external> is false, items should be identifiers of other terms.

The storage should preserve the order of items in C<$related>, i.e.
the L</"related"> method should return items in the same order.

=item *

C<$is_external> is a boolean which tells what kind of items
are related, as explained above

=item *

C<$inverse_id> is the optional identifier of the inverse
relation type; if non-null, relations will be stored in both
directions.

=back


=head3 finalize

Will be called by IO classes after loading files.
Storage implementations may use this to perform cleanup operations if needed.
