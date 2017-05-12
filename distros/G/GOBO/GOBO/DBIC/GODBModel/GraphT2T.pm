=head1 GOBO::DBIC::GODBModel::GraphT2T

This graph should probably be sub-classed as an ontology, and the
connecting and abstract bits should be shifted around.

NOTE: This uses term2term as the primary engine and should be
considered deprecated.

=cut

use utf8;
use strict;

package GOBO::DBIC::GODBModel::GraphT2T;

use base 'GOBO::DBIC::GODBModel';
use utf8;
use strict;
use GOBO::DBIC::GODBModel::Schema;
use GOBO::DBIC::GODBModel::Query;
use Graph::Directed;
use Graph::TransitiveClosure;

=item new

=cut
sub new {

  ##
  my $class = shift;
  my $self  = $class->SUPER::new();

  $self->{SCHEMA} = GOBO::DBIC::GODBModel::Schema->connect($self->db_connector());
  $self->{REL_Q} = GOBO::DBIC::GODBModel::Query->new({type=>'term2term'});

  ## We'll borrow SUCCESS and ERROR_MESSAGE from GOBO::DBIC::GODBModel.

  ### Nodes are defined as terms (keyed by acc) and edges are defined
  ### as two terms, a relationship, and a completeness (keyed
  ### accordingly).
  #$self->{NODES} = {};
  #$self->{EDGES} = {};

  ## TODO/BUG: the below would be preferable if the GO wasn't borked.
  #my $rrs = $schema->resultset('Term')->search({is_root => 1});
  $self->{ROOTS} = {};
  my $rrs = $self->{SCHEMA}->resultset('Term2Term')->search({ term1_id => 1 });
  while( my $possible_root_rel = $rrs->next ){
    my $term = $possible_root_rel->subject;
    if( ! $term->is_obsolete && $term->name ne 'all' ){
      $self->{ROOTS}{$term->acc} = $term;
    }
  }

  bless $self, $class;
  return $self;
}


=item get_roots

Returns the root nodes.

=cut
sub get_roots {
  my $self = shift;

  ## We don't want to actually pass this thing...
  my $copy = {};
  foreach my $key (keys %{$self->{ROOTS}}){
    $copy->{$key} = $self->{ROOTS}{$key};
  }
  return $copy;
}


=item is_root_p

Boolean on acc.

=cut
sub is_root_p {
  my $self = shift;
  my $acc = shift || '';
  return 1 ? defined $self->{ROOTS}{$acc} : 0;
}


=item get_term

Gets a term from a string.

TODO: should be able to take string or object.

=cut
sub get_term {

  my $self = shift;
  my $acc = shift || '';

  my $term_rs =
    $self->{SCHEMA}->resultset('Term')->search({ acc => $acc });

  return $term_rs->first || undef;
}


=item get_children

In: acc.
Out: Children term list.

TODO: should be able to take string or object.

=cut
sub get_children {

  my $self = shift;
  #my $term = shift || undef;
  my $acc = shift || '';

  my $all = $self->{REL_Q}->get_all_results({'object.acc' => $acc});

  my $ret = [];
  foreach my $t2t (@$all){
    if( ! $t2t->subject->is_obsolete ){
      push @$ret, $t2t->subject;
      #print STDERR "_>_" . $t2t->subject->acc . "\n";
    }
  }
  return $ret;
}


=item get_relationship

In: acc, acc.
Out: int.

TODO: should be able to take string or object.

=cut
sub get_relationship {

  my $self = shift;
  #my $term = shift || undef;
  my $obj_acc = shift || '';
  my $sub_acc = shift || '';

  my $all = $self->{REL_Q}->get_all_results({'object.acc' => $obj_acc,
					     'subject.acc' => $sub_acc});

  ## Should be one.
  my $ret = undef;
  foreach my $t2t (@$all){
    #$ret = $t2t->relationship_type_id;
    $ret = $t2t->relationship->name;
    last;
  }
  return $ret;
}


=item get_child_relationships

Takes term.
Gets the term2term links from a term.

=cut
sub get_child_relationships {

  my $self = shift;
  my $term = shift || undef;
  return $self->{REL_Q}->get_all_results({ term1_id=>$term->id });
}


=item get_parent_relationships

Takes term.
Gets the term2term links from a term.

=cut
sub get_parent_relationships {

  my $self = shift;
  my $term = shift || undef;
  return $self->{REL_Q}->get_all_results({ term2_id=>$term->id });
}


=item climb

With an array ref of terms, will climb to the top of the ontology
(with an added 'all' stopper for GO).

This returns an array of three things:
   *) a link list
   *) a term (node)
   *) a hashref of of nodes in terms of in-graph descendants

TODO: should also be able to take array ref of strings...

=cut
sub climb {

  my $self = shift;
  my $seed_terms = shift || [];

  ## For doing transitive closure on the graph to help with
  ## association transfer.
  my $booking_graph = Graph::Directed->new();

  $self->kvetch("Climb: IN");

  ## Pre-seed the nodes list.
  my %edges = ();
  my %nodes = ();
  foreach my $seed ( @$seed_terms ){
    $nodes{$seed->acc} = $seed;
    $self->kvetch("Climb: added seed: " . $seed->acc);
  }

  ##
  my %in_graph_by_acc = ();
  while( @$seed_terms ){

    my $current_term = pop @$seed_terms;

    ## BUG: Prevent super root (not really our bug though).
    my $current_acc = $current_term->acc;
    if( $current_acc ne 'all' ){

      ## Add node to hash if not already there.
      if( ! $nodes{$current_acc} ){
	$nodes{$current_acc} = $current_term;
	$self->kvetch("Climb: adding node: " . $current_acc);
	$booking_graph->add_vertex($current_acc);
      }

      ## Find parent releations each time.
      my $parent_rs = $current_term->parent_relations;
      my @all_parents = $parent_rs->all;
      foreach my $parent_rel (@all_parents){

	my $id = $parent_rel->id;

	my $obj = $parent_rel->object;
	my $obj_acc = $obj->acc;

	## BUG: Prevent links to super root (not really our bug though).
	if( $obj_acc ne 'all' ){

	  my $sub = $parent_rel->subject;
	  my $sub_acc = $sub->acc;
	  #my $rel_id = $parent_rel->relationship_type_id;
	  my $rel_id = $parent_rel->relationship->name;

	  ## Add edge to hash if not already there.
	  if( ! defined $edges{$id} ){
	    $edges{$id} = $parent_rel;
	    $self->kvetch("Climb adding edge: $sub_acc $rel_id $obj_acc");
	    $booking_graph->add_edge($sub_acc, $obj_acc);
	  }

	  ## Make sure that there is a space in the indirect hash
	  ## if it is not already there.
	  if( ! defined $in_graph_by_acc{$obj_acc} ){
	    $in_graph_by_acc{$obj_acc} = {};
	  }

	  ## TODO: double check the correctness of this...
	  ## If we haven't seen it, mark it and climb.
	  if( ! defined $in_graph_by_acc{$obj_acc}{$sub_acc} ){

	    $in_graph_by_acc{$obj_acc}{$sub_acc} = 1;
	    push @{$seed_terms}, $obj;
	  }
	}
      }
    }
  }

  ## Calculate the transitive closure to help with figuring out the
  ## association transitivity in other components.
  my $tc_graph = Graph::TransitiveClosure->new($booking_graph,
					       reflexive => 0,
					       path_length => 1);
  my %tc_desc = ();
  my %tc_anc = ();

  ## Iterate through the combinations making the anc and desc hashes.
  foreach my $obj (keys %nodes){

    $tc_desc{$obj} = {} if ! defined $tc_desc{$obj};
    $tc_anc{$obj} = {} if ! defined $tc_anc{$obj};

    foreach my $sub (keys %nodes){

      if( $tc_graph->is_reachable($obj, $sub) ){
	$tc_anc{$obj}{$sub} = 1;
      }
      if( $tc_graph->is_reachable($sub, $obj) ){
	$tc_desc{$obj}{$sub} = 1;
      }
    }
  }

  ## Down here, we're doing something separate--we're going to get
  ## the depth of the node.
  #TODO
  my %tc_depth = ();
  foreach my $sub (keys %nodes){
    foreach my $root (keys %{$self->{ROOTS}}){
      my $len = $tc_graph->path_length($sub, $root);
      if( defined $len ){
	$tc_depth{$sub} = $len;
	$self->kvetch('Depth of ' . $sub . ' is ' . $len);
      }
    }
  }

  #return (\%nodes, \%edges, \%in_graph_by_acc);
  #return (\%nodes, \%edges, \%tc_desc);
  return (\%nodes, \%edges, \%tc_desc, \%tc_anc, \%tc_depth);
}



1;
