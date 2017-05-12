=head1 GOBO::DBIC::GODBModel::Resolver

Converts strings, identifiers, etc. into usable objects. This should
be a heavy lifter for session handling and such in the new framework.

This should be the only stop for turning things into GOBO::DBIC::GODBModel internal
canonical form.

TODO: heavy speed checking.

NOTE: It occurs to me that if this was backed by a lucene instead of
the DB it would be *smoking* fast.

=cut

use utf8;
use strict;

package GOBO::DBIC::GODBModel::Resolver;

use base 'GOBO::DBIC::GODBModel';
use utf8;
use strict;
use GOBO::DBIC::GODBModel::Schema;
use GOBO::DBIC::GODBModel::Query;


=item new

=cut
sub new {

  ##
  my $class = shift;
  my $self  = $class->SUPER::new();

  ## We'll use lazys where we can can't we don't plan on going very deep.
  $self->{GP_Q} = GOBO::DBIC::GODBModel::Query->new({type=>'gene_product_lazy'});
  $self->{GP_SYN_Q} = GOBO::DBIC::GODBModel::Query->new({type=>'gene_product_synonym'});
  $self->{DBXREF_Q} = GOBO::DBIC::GODBModel::Query->new({type=>'dbxref'});
  $self->{TERM_Q} = GOBO::DBIC::GODBModel::Query->new({type=>'term_lazy'});
  $self->{TERM_SYN_Q} = GOBO::DBIC::GODBModel::Query->new({type=>'term_synonym'});

  bless $self, $class;
  return $self;
}


=item get_gene_products

Take: an array ref of "identifiers"
Return:

[ [gene products that fit a criteria],
  [errata]]

=cut
sub get_gene_products {

  my $self = shift;
  my $strings = shift || [];
  my $unresolvable = [];

  ###
  ### Process the input by sorting into ID and symbol groups.
  ###

  ## Split the strings into symbols and IDs.
  my $symbol_hash = {};
  my $id_hash = {};
  foreach my $string (@$strings){

    ## Standardize on lc
    $string = lc($string);

    if( $string =~ /\:/ ){ # is this too naive?
      if( ! defined $id_hash->{$string} ){
	$id_hash->{$string} = 1;
      }else{
	$id_hash->{$string}++;
      }
    }else{
      if( ! defined $symbol_hash->{$string} ){
	$symbol_hash->{$string} = 1;
      }else{
	$symbol_hash->{$string}++;
      }
    }
  }

  ## TODO: at this point, scanning the hash would give trivial dupes.
  ## Building these are necessary to make the query.
  my $ids = [];
  foreach my $id (keys %$id_hash){
    push @$ids, $id;
  }
  my $symbols = [];
  foreach my $symbol (keys %$symbol_hash){
    push @$symbols, $symbol;
  }

  ###
  ### Work on the symbols.
  ###

  ## If we actually have symbols...
  if( scalar(@$symbols) > 0 ){

    ## Get all of the possible results.
    my $all_gps =
      $self->{GP_Q}->get_all_results(-or=>[
					   {'me.symbol' => $symbols},
					   {'gene_product_synonym.product_synonym' => $symbols}
					  ]});

  ## Cycle through them to find the missings.
  my $missing = [];
  foreach my $gp (@$all_gp){

    my $spotted_p = 0;
    if( defined $symbol_hash->{lc($gp->symbol)} ){
    ## See if it is a symbol...OK.
      $spotted_p = 1;
    }else{

#       ## Otherwise, cycle through the synonyms.
#       foreach my $gp (@$all_gp){


#       }
    }

    #     if ! spotted_p;
  }

  ###
  ### TODO: work on the ids...harder...
  ###
    
  ## TODO:
  return [], [];
}


=item get_terms

Returns an array ref of terms that fit and an array ref of strings
that didn't match.

TODO: maybe this could be sped up by sorting into GO id and name
groups, like with the gps above...

=cut
sub get_terms {

  my $self = shift;
  my $strings = shift || [];

  ## Hashify the incoming strings. Items will be removed from this
  ## hash as we go until it is empty or we reach the end, it which
  ## case they become the unresolvable.
  my $symbol_hash = {};
  foreach my $string (@$strings){

    ## Standardize on lc
    $string = lc($string);

    if( ! defined $symbol_hash->{$string} ){
      $symbol_hash->{$string} = 1;
    }else{
      $symbol_hash->{$string}++;
    }
  }

  ## TODO: at this point, scanning the hash would give trivial
  ## dupes. Do we care? I hope not...

  ###
  ### Work our way through the different DB tables and fields.
  ###
  ### For each one, we'll cycle through the results. We can't find the
  ### missings directly, so we'll delete things that are found,
  ### leaving the rest as missing.
  ###

  my @remaining_symbols = ();
  my @good_terms = ();

  ## First, try the acc.
  @remaining_symbols = keys %$symbol_hash;
  if( scalar(@remaining_symbols) > 0 ){

    ## Get all of the possible results.
    my $remaining_terms =
      $self->{TERM_Q}->get_all_results({'me.acc' => $symbols});

    foreach my $term (@remaining_terms){

      ## Remove any seen acc and add it.
      if( defined $symbol_hash->{lc($term->acc)} ){
	delete $symbol_hash->{lc($term->acc)};
	push @good_terms, $term;
      }
    }
  }

  ## Next, try the term_synonym acc_synonym.
  @remaining_symbols = keys %$symbol_hash;
  if( scalar(@remaining_symbols) > 0 ){

    ## Get all of the possible results.
    my $remaining_term_synonyms =
      $self->{TERM_SYN_Q}->get_all_results({'me.acc_synonym' =>	$symbols});

    foreach my $term_syn (@remaining_term_synonyms){

      ## Remove any seen acc and add it.
      if( defined $symbol_hash->{lc($term_syn->acc_synonym)} ){
	delete $symbol_hash->{lc($term_syn->acc_synonym)};
	push @good_terms, $term_stn->term;
      }
    }
  }

  my @missings = keys %$symbol_hash;
  return \@good_terms, \@missings;
}



1;
