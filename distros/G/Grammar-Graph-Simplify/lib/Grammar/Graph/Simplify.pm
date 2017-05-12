#####################################################################
# Grammar::Graph
#####################################################################
package Grammar::Graph::Simplify;
use 5.012000;
use strict;
use warnings;
use Grammar::Graph;
use Grammar::Formal;
use Algorithm::ConstructDFA::XS 0.13;
use List::UtilsBy qw/partition_by/;
use List::MoreUtils qw/uniq/;
use List::Util qw/shuffle sum max/;
use Storable qw/freeze thaw/;
use Graph::SomeUtils qw/:all/;

local $Storable::canonical = 1;

our $VERSION = '0.02';

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

sub Grammar::Graph::fa_merge_equivalent_vertices {
  my ($g, $start_vertex, $final_vertex) = @_;
  
  die if $g->get_graph_attribute('ran_fa_merge_equivalent_vertices');
  $g->set_graph_attribute('ran_fa_merge_equivalent_vertices', 'yes');

  my $signature = sub {
    my ($g, $label) = @_;
    
    my $symbols = $g->get_graph_attribute('symbol_table');
    
    if (not defined $label) {
      return;
    } elsif ($label->isa('Grammar::Graph::StartOf')) {
      return "start " . $symbols->{ $label->of }{shortname};
    } elsif ($label->isa('Grammar::Graph::FinalOf')) {
      return "final " . $symbols->{ $label->of }{shortname};
    } elsif ($label->isa('Grammar::Graph::Prefix')) {
      return "prefix " . $label->link;
    } elsif ($label->isa('Grammar::Graph::Suffix')) {
      return "suffix " . $label->link;
    } elsif ($label->isa('Grammar::Formal::CharClass')) {
      die "Bad label" if $label->spans->empty;
      return '' . $label->spans;
    } elsif ($label->isa('Grammar::Formal::Reference')) {
      ...
    } elsif ($label->isa('Grammar::Formal::Empty')) {
      return;
    } else {
      ...
    }
  };
  
  my $get_classes = sub {
    my ($start_vertex, $final_vertex, $sub) = @_;

    my $dfa = Algorithm::ConstructDFA::XS::construct_dfa_xs(
      start        => [ $start_vertex ],
      is_accepting => sub { grep { $_ eq $final_vertex } @_ },
      is_nullable  => sub {
        my $label = $g->get_vertex_attribute($_[0], 'label');
        return 1 unless defined $label;
        return 1 if ref $label eq 'Grammar::Formal::Empty';
        return 0;
      },
      successors   => $sub,
      get_label    => sub {
        my $label = $g->get_vertex_attribute($_[0], 'label');
        return unless defined $label;
        return if ref $label eq 'Grammar::Formal::Empty';
        return $signature->($g, $label);
        return;
      },
    );
    
    my %delta;
    for my $s (keys %$dfa) {
      $delta{$_}->{$s}++ for @{ $dfa->{$s}{Combines} };
    }

    my %h = partition_by {
      join ' ', sort keys %{ $delta{$_} }
    } keys %delta;
    
    return values %h;
  };
  
  while (1) {
    my $changed = 0;
    my @fwd = $get_classes->($start_vertex, $final_vertex, sub { $g->successors($_[0]); });
    my @bck = $get_classes->($final_vertex, $start_vertex, sub { $g->predecessors($_[0]); });
    my @eq;
    
    for my $x (@fwd, @bck) {
      push @eq, grep { @$_ > 1 } values %{{ partition_by {
        my $label = $g->get_vertex_attribute($_, 'label');
        return 'prefix' if $label->isa('Grammar::Graph::Prefix');
        return 'suffix' if $label->isa('Grammar::Graph::Suffix');
        return $signature->($g, $label) // '';
      } @$x }};
    }

    my %cappa;
    
    for my $group (@eq) {
      my $label0 = $g->get_vertex_attribute($group->[0], 'label');
      next unless $label0->isa('Grammar::Graph::Prefix')
               or $label0->isa('Grammar::Graph::Suffix');
               
      for my $v1 (@$group) {
        for my $v2 (@$group) {
          $cappa{$v1}->{$v2}++;
        }
      }
    }
    
    my %ren;
    for my $v1 (sort keys %cappa) {
      for my $v2 (sort keys %{$cappa{$v1}}) {
        my $label1 = $g->get_vertex_attribute($v1, 'label');
        my $label2 = $g->get_vertex_attribute($v2, 'label');
        my ($p1, $s1) = split/ # /, $label1->link, 2;
        my ($p2, $s2) = split/ # /, $label2->link, 2;
        next if $p1 eq $p2;
        next if $s1 eq $s2;
        next unless $cappa{$p1}->{$p2} and
                    $cappa{$s1}->{$s2};
        
        $ren{"$p1 $s1"} = $ren{"$p2 $s2"} // [$p2, $s2];
      }
    }
    
    my $replace = sub {
      my ($g, $goes, $stays) = @_;
      
      return if $goes eq $stays;

      unless ($g->has_vertex($goes)) {
#        warn $goes . " not in graph";
        return;
      }

      unless ($g->has_vertex($stays)) {
#        warn "Cannot replace $goes by $stays because $stays does not exist";
        return;
      }

#      warn "replacing $goes by $stays\n";
      
      for my $p ($g->predecessors($goes)) {
        $g->add_edge($p, $stays);
      }
      for my $s ($g->successors($goes)) {
        $g->add_edge($stays, $s);
      }

      graph_delete_vertex_fast($g, $goes);
      
      ###############################################################
      # Note that this makes no effort to adjust the ->link attribute
      # of the vertex, so while above we rely on the contents of it
      # to be accurate, it cannot be relied upon after running this
      # step. Ideally that should be fixed to maintain invariants.
      ###############################################################
    };

    for my $k (sort keys %ren) {
      my ($p1, $s1) = split/ /, $k, 2;
      my ($p2, $s2) = @{ $ren{$k} };
      $replace->($g, $p1, $p2);
      $replace->($g, $s1, $s2);
      next unless $p1 ne $p2 or $s1 ne $s2;
      $changed += 1;
    }
    
    next if $changed;
    
    for my $group (@eq) {
      my $label = $g->get_vertex_attribute($group->[0], 'label');
      next unless $label;
      next if $label->isa('Grammar::Graph::Prefix');
      next if $label->isa('Grammar::Graph::Suffix');

      for (my $ix = 1; $ix < @$group; ++$ix) {
        $replace->($g, $group->[$ix], $group->[0]);
        $changed += 1;
      }
    }

    last unless $changed;
  }
}


1;

__END__

=head1 NAME

Grammar::Graph::Simplify - Simplify Grammar::Graph objects

=head1 SYNOPSIS

  use Grammar::Graph;
  use Grammar::Graph::Simplify;
  my $g = Grammar::Graph->from_grammar_formal($formal);
  ...
  $g->fa_merge_equivalent_vertices($start_vertex, $final_vertex);

=head1 DESCRIPTION

Extension methods for L<Grammar::Graph> objects that simplify
Grammars when possible.

=head1 METHODS

=over

=item C<fa_merge_equivalent_vertices($start_vertex, $final_vertex)>

This method is added to L<Grammar::Graph> objects and when called it
attempts to merge equivalent vertices in the object between the given
C<$start_vertex> and C<$final_vertex>. Ideally, the start vertex does
not have incoming edges, and the final vertex does not have outgoing
edges. The code is untested for when they do. It relies on being able
to determine whether two labeled vertices have an equivalent label and
there is currently no extension functionality to consider any but the
standard labels. It dies when there are unrecognised labels. For the
sentinel labels C<Grammar::Graph::Prefix> and C<Grammar::Graph::Suffix>
vertices are merged only when matching pairs are equivalent.

The code relies on the C<link> attributes of sentinel labels to determine
which pairs are matching pairs, but then does not make any attempt to
correct the C<link> attributes, so it can be run only once on a given
L<Grammar::Graph> object. The code dies if an attempt is made to run the
method a second time (it uses a graph attribute to maintain this state).

=back

=head1 EXPORTS

None.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2014 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
