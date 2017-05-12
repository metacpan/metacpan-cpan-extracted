=head1 GOBO::DBIC::GODBModel::Query

The idea is to build a simple query engine on top of the Schema. It
will center around a gp type and a term type.

TODO: association_deep and association_very_deep should be resolved
into one query type as soon as I can figure out the nuances of deep
joining in DBIx::Class.

TODO: integration of 'filter_set'.

NOTE: QUERY_PREFETCH can be used to keep the objects of the initial
query around when you are traversing the objects. For example, if you
don't use it and traverse a many relationship, it looks like ->all.

=cut

use utf8;
use strict;

package GOBO::DBIC::GODBModel::Query;

use base 'GOBO::DBIC::GODBModel';
use utf8;
use strict;
use GOBO::DBIC::GODBModel::Schema;
#use Data::Page;



=item new

Sets the stype of search to be done.

Arg: {type=>X}, where X := 'term', 'gp', 'gene_product', 'homolset', etc.
Arg: {filter_set=>[]}, where ...

=cut
sub new {

  ##
  my $class = shift;
  my $args = shift || {};
  my $self = $class->SUPER::new($args);

  ## Argument processing.
  #my $args = shift || {};
  my $type = $self->{QUERY_TYPE} = $args->{type} || die "need type: $!";
  my $filter_set = $args->{filter_set} || []; # TODO:

  $self->{QUERY_ITERATOR} = undef;
  $self->{QUERY_PAGER} = undef;
  $self->{QUERY_RESULTS} = undef;

  ## Essentially acts as the object that we are creating in a single join.
  if( $type eq 'homolset' ){

    $self->{QUERY_RESULT_SET} = 'Homolset';
    $self->{QUERY_JOIN} = [];
#     $self->{QUERY_JOIN} = [{'gene_product' =>
# 			    ['species',
# 			     'dbxref',
# 			     {'association' =>
# 			      ['term',
# 			       'evidence']}]},
# 			   'dbxref'];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'gene_product_homolset' ){

    $self->{QUERY_RESULT_SET} = 'GeneProductHomolset';
    $self->{QUERY_JOIN} = ['homolset',
			   {'gene_product' =>
			    ['species',
			     'dbxref',
			     {'association' =>
			      ['term',
			       'evidence']}]}];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'association' ){

    $self->{QUERY_RESULT_SET} = 'Association';
    $self->{QUERY_JOIN} = [{'gene_product' =>
			    ['species',
			     'dbxref']},
			   'term',
			   {'evidence' =>
			    'dbxref'}];
			   #'evidence'];
			   #{'evidence' =>
			   # 'evidence_dbxref'}];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'association_very_deep' ){

    ## This should give us the ability to explore the "with" column
    ## and beyond with pretty good performace.
    $self->{QUERY_RESULT_SET} = 'Association';
    $self->{QUERY_JOIN} = ['term',
			   {'gene_product' =>
			    ['species',
			     'dbxref',
			     {'gene_product_homolset' =>
			      'homolset'}]},
 			   {'evidence' =>
			    ['dbxref',
			     {'evidence_dbxref' =>
			      {'dbxref' =>
			       {'gene_product' =>
				{'association' =>
				 ['term',
				  'evidence']}}}}]}];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'association_very_deep_DEBUG' ){

    ## This should give us the ability to explore the "with" column
    ## and beyond with pretty good performace.
    $self->{QUERY_RESULT_SET} = 'Association';
    $self->{QUERY_JOIN} = ['term',
			   {'gene_product' =>
			    ['species',
			     'dbxref',
			     {'gene_product_homolset' =>
			      'homolset'}]},
 			   'evidence'];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'association_deep' ){

    ## This should give us the ability to explore the "with" column
    ## and beyond with pretty good performace.
    $self->{QUERY_RESULT_SET} = 'Association';
    $self->{QUERY_JOIN} = ['term',
			   {'gene_product' =>
			    ['species',
			     'dbxref',
			     {'gene_product_homolset' =>
			      'homolset'},
			    ]},
			   #{'evidence' =>
			   # ['dbxref',
			   #  'evidence_dbxref']}];
			   {'evidence' =>
			    ['dbxref',
			     'evidence_dbxref']}];
#     $self->{QUERY_JOIN} = ['term',
# 			   {'gene_product' =>
# 			    ['species',
# 			     'dbxref',
# 			     {'gene_product_homolset' =>
# 			      'homolset'},
# 			    ]},
# 			   {'evidence' =>
# 			    {'dbxref',
# 			     {'evidence_dbxref' =>
# 			      {'dbxref' =>
# 			       {'gene_product' =>
# 				{'association' =>
# 				 ['term',
# 				  'evidence']}}}}}}];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'association_deep2' ){

    ## This should give us the ability to explore the "with" column
    ## and beyond with pretty good performace.
    $self->{QUERY_RESULT_SET} = 'Association';
    $self->{QUERY_JOIN} = ['term',
			   'evidence',
			   {'gene_product' =>
			    ['species',
			     'dbxref',
			     {'gene_product_homolset' =>
			      'homolset'},
			    ]}];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'association_coannotation' ){

    ## Specialized for coannoatation searches
    $self->{QUERY_RESULT_SET} = 'Association';
#     $self->{QUERY_JOIN} =[
# 			  {'graph_path_relations' =>
# 			   'object'},
# 			  {'graph_path_relations' =>
# 			   'object'}
# 			 ];
    ## TODO: still not working as expected...
    $self->{QUERY_JOIN} =[
			  {'graph_path_relations' =>
			   {'object' =>
			    {'association' =>
			     {'graph_path_relations' =>
			      'object'}}}}
			 ];
    #$self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'term_lazy' ){

    $self->{QUERY_RESULT_SET} = 'Term';
    $self->{QUERY_JOIN} = [];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'term' ){

    $self->{QUERY_RESULT_SET} = 'Term';
     $self->{QUERY_JOIN} = ['term_synonym',
 			   'gene_product_count',
			    {'association' =>
			     'evidence'},
			    # ['evidence',
			    # 'gene_product']},
 			   {'term_dbxref' =>
 			    'dbxref'}];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'term_synonym' ){

    $self->{QUERY_RESULT_SET} = 'TermSynonym';
    $self->{QUERY_JOIN} = ['term'];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'term2term' ){

    $self->{QUERY_RESULT_SET} = 'Term2Term';
    $self->{QUERY_JOIN} = ['subject',
			   'object',
			   'relationship'];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'graph_path' ){

    $self->{QUERY_RESULT_SET} = 'GraphPath';
    $self->{QUERY_JOIN} = ['subject',
			   'object'];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'term2term_over_graph_path' ){

    $self->{QUERY_RESULT_SET} = 'Term2Term';
    $self->{QUERY_JOIN} = ['subject',
			   'object',
			   'relationship',
			   {'graph_path' =>
			    ['graph_subject',
			     'graph_object']}];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'gene_product_lazy' || $type eq 'gp_lazy' ){

    $self->{QUERY_RESULT_SET} = 'GeneProduct';
    $self->{QUERY_JOIN} = [];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'gene_product' || $type eq 'gp' ){

    $self->{QUERY_RESULT_SET} = 'GeneProduct';
    $self->{QUERY_JOIN} = ['species',
			   'dbxref',
			   'gene_product_synonym',
			   {'association' =>
			    ['term',
			     'evidence']}];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'gene_product_two_terms' ){

    $self->{QUERY_RESULT_SET} = 'GeneProduct';
    $self->{QUERY_JOIN} = [[{'association' =>
			    {'graph_path_relations' =>
			     'object'}},
			    {'association_aux' =>
			     {'graph_path_relations' =>
			      'object'}}]];

    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'gene_product_synonym' ){

    $self->{QUERY_RESULT_SET} = 'GeneProductSynonym';
    $self->{QUERY_JOIN} = ['gene_product'];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'species' ){

    $self->{QUERY_RESULT_SET} = 'Species';
    $self->{QUERY_JOIN} = ['gene_product'];
    #$self->{QUERY_JOIN} = [{'gene_product' => 'association'}];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'dbxref' ){

    $self->{QUERY_RESULT_SET} = 'DBXRef';
    $self->{QUERY_JOIN} = ['gene_product',
			   'term'];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'db' ){

    ## Trivial, is it not?
    $self->{QUERY_RESULT_SET} = 'DB';
    $self->{QUERY_JOIN} = [];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }elsif( $type eq 'instance_data' ){

    ## Trivial, is it not?
    $self->{QUERY_RESULT_SET} = 'InstanceData';
    $self->{QUERY_JOIN} = [];
    $self->{QUERY_PREFETCH} = $self->{QUERY_JOIN};

  }else{
    die "that type is not yet implemented";
  }

  ## Defined in super now...
  # $self->{SCHEMA} =
  #   GOBO::DBIC::GODBModel::Schema->connect($self->connect_info);

  ## We'll borrow SUCCESS and ERROR_MESSAGE from GOBO::DBIC::GODBModel.
  ## TODO

  bless $self, $class;
  return $self;
}


=item get_next_result

Args: standard
Returns: result set iterator

=cut
sub get_next_result {

  my $self = shift;
  my $args = shift || {}; # get the rest?

  if( ! defined($self->{QUERY_ITERATOR}) ){
    $self->{QUERY_ITERATOR} =
      $self->{SCHEMA}->resultset($self->{QUERY_RESULT_SET})->search($args,
								    {
								     distinct => 'me',
								     join => $self->{QUERY_JOIN},
								     prefetch => $self->{QUERY_PREFETCH},
								    });
  }

  return $self->{QUERY_ITERATOR}->next || undef;
}


=item get_all_results

Args: a more hard-wired version of the below do_query.
Returns: result set, unpaged

=cut
sub get_all_results {

  my $self = shift;
  my $search_args = shift || {}; # get all?
  my $incoming_aux_args = shift || {};

  ## Merge the incoming aux args with the preset ones.
  my $aux_args =
    {
     distinct => 'me',
     join => $self->{QUERY_JOIN},
     prefetch => $self->{QUERY_PREFETCH},
    };
  foreach my $key (keys %$incoming_aux_args){
    $aux_args->{$key} = $incoming_aux_args->{$key};
  }

  my $results =
    $self->{SCHEMA}->resultset($self->{QUERY_RESULT_SET})->search($search_args,
								  $aux_args);

  ## TODO: can toss some error checking in here for return values.
  my @all = $results->all;
  return \@all;
}


=item get_paged_results

Args: table sets.
Returns: all results by page

=cut
sub get_paged_results {

  my $self = shift;
  my $args = shift || {}; # get the rest?
  my $page = shift || 1; # TODO: play with this a bit more...

  my $results =
    $self->{SCHEMA}->resultset($self->{QUERY_RESULT_SET})->search($args,
								  {
								   #distinct=>1,
								   #join => $self->{QUERY_JOIN},
								   distinct => 'me',
								   prefetch => $self->{QUERY_PREFETCH},
								   rows => 10,
								  });

  #$self->{QUERY_PAGER} = $results->pager();
  $self->{QUERY_COUNT} = $results->count();
  #$self->{QUERY_RESULTS} = $results->all();
  #$self->{QUERY_RESULTS} = $results;

  my $r2 = $results->page($page);

  ## TODO: can toss some error checking in here for return values.
  #my @all =  return \@all;
  #return \@all;
  #return $results->all();
  return $r2->all();
}


=item get_page_info

Args: nil
Returns: an array of paging info

=cut
sub get_page_info {

  #$self->{QUERY_PAGER} = $results->pager();

  my $self = shift;

  my $total = $self->{QUERY_PAGER}->total_entries || 0;
  my $first = $self->{QUERY_PAGER}->first_page || 0;
  my $curr = $self->{QUERY_PAGER}->current_page || 0;
  my $last = $self->{QUERY_PAGER}->last_page || 0;

  $self->kvetch("pager total: " . $total);
  $self->kvetch("pager fp: " . $first);
  $self->kvetch("pager cu: " . $curr);
  $self->kvetch("pager lp: " . $last);

  return ($total, $first, $curr, $last);
}



1;
