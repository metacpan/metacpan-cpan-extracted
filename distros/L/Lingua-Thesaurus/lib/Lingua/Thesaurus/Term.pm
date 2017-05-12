package Lingua::Thesaurus::Term;
use 5.010;
use Moose;
use overload '""' => sub {$_[0]->string},
             'eq' => sub {$_[0]->string eq $_[1]};

#DO NOT "use namespace::clean -except => 'meta'" BECAUSE it sweeps 'overload'

has 'storage'        => (is => 'ro', does => 'Lingua::Thesaurus::Storage',
                           required => 1,
         documentation => "storage object from which this term was issued");

has 'id'               => (is => 'ro', isa => 'Str', required => 1,
         documentation => "unique storage id for the term");

has 'string'           => (is => 'ro', isa => 'Str', required => 1,
         documentation => "the term itself");

has 'origin'           => (is => 'ro', isa => 'Maybe[Str]',
         documentation => "where this term was found");

__PACKAGE__->meta->make_immutable;

sub related {
  my ($self, $rel_ids) = @_;

  return $self->storage->related($self->id, $rel_ids);
}

sub transitively_related {
  my ($self, $rel_ids, $max_depth) = @_;
  $max_depth //= 50;

  $rel_ids
    or die "missing relation type(s) for method 'transitively_related()'";
  my @results;
  my @terms   = ($self);
  my %seen    = ($self->id => 1);
  my $level = 1;
  while ($level < $max_depth && @terms) {
    my @next_related;
    foreach my $term (@terms) {
      my @step_related = $term->related($rel_ids);
      my @new_terms    = grep {!$seen{$_->[1]->id}} @step_related;
      push @next_related, map {[@$_, $term, $level]} @new_terms;
      $seen{$_->[1]->id} = 1 foreach @new_terms;
    }
    @terms = map {$_->[1]} @next_related;
    push @results, @next_related;
    $level += 1;
  }
  return @results;
}

1;

__END__

=head1 NAME

Lingua::Thesaurus::Term - parent class for thesaurus terms

=head1 SYNOPSIS

  my $term = $thesaurus->fetch_term($term_string);

  # methods for specific relations
  my $scope_note = $term->SN;
  my @synonyms   = $term->UF;

  # exploring several relations at once
  foreach my $pair ($term->related(qw/NT RT/)) {
    my ($rel_type, $item) = @$pair;
    printf "  %s(%s) = %s\n", $rel_type->description, $rel_type->rel_id, $item;
  }

  # transitive search
  foreach my $quadruple ($term->transitively_related(qw/NT/)) {
    my ($rel_type, $related_term, $through_term, $level) = @$quadruple;
    printf "  %s($level): %s (through %s)\n", 
       $rel_type->rel_id,
       $level,
       $related_term->string,
       $through_term->string;
  }

=head1 DESCRIPTION

Objects of this class encapsulate terms in a thesaurus.
They possess methods for navigating through relations, reaching
other terms or external data. 

=head1 CONSTRUCTOR

=head2 new

  my $term = Lingua::Thesaurus::Term->new(
    storage => $storage, # an object playing role Lingua::Thesaurus::Storage
    id      => $id,      # unique id for this term
    string  => $string,  # the actual term string
    origin  => $origin,  # an identifier for the file where this term was found
  );

Creates a new term object; not likely to be called from client code,
because such objects are created automatically
from the thesaurus through
L<Lingua::Thesaurus/"search_terms"> and 
L<Lingua::Thesaurus/"fetch_term"> methods.


=head1 ATTRIBUTES

=head2 storage

Reference to the storage object
from which this term was issued.

=head2 id

unique storage id for the term

=head2 string

the term itself

=head2 origin

tagname of the dumpfile where this term was found


=head1 METHODS

=head2 related

  my @pairs = $term->related(@relation_ids);

Returns a list of items related to the current term, through
one or several C<@relation_ids>.
Each returned item is a pair, where the first element is
an instance of L<Lingua::Thesaurus::RelType>,
and the second element is either a plain string (when the relation
type is "external"), or another term (when the relation type is "internal").

=head2 NT, BT, etc.

  my @narrower_terms = $term->NT;
  my $broader_term   = $term->BT;
  ...

Specific navigation methods, such as C<NT>, C<BT>, etc., depend on the
relation types declared in the thesaurus; once those relations are known,
a subclass of C<Lingua::Thesaurus::Term> is automatically created, with
the appropriate additional methods.

Internally these methods are implemented of course by calling the
L</"related"> method described above; but instead or returning
a list of pairs, they just return related items (since the relation type is
explicitly requested in the method call, it would be useless to return
it again as a result). The result is either a list or a single related item,
depending on the calling context.

=head2 transitively_related

  my @quadruples = $term->transitively_related(@relation_ids);

Returns a list of items directly or indirectly related to the current term,
through one or several C<@relation_ids>.
Each returned item is a quadruple, where the first two elements
are as in the L</"related> method, and the two remaining elements
are

=over

=item *

the last intermediate term through wich this relation was reached

=item *

the level of transitive steps

=back

