# emacs, this is really -*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 50walking.t'

#########################

use strict;
use Test::More tests => 12;

# Test 1
BEGIN { use_ok('Lingua::Treebank::Const') };

#########################

# my $node;

my $empty_root = <<EOTREE;
(
 (INTJ
  (UH Okay)
  (. .)
  (-DFL- E_S)))
EOTREE

my $path = <<EOTREE;
(NP
 (NP
  (VP
   (N dog))))
EOTREE

my $children = <<EOTREE;
(no
 (yes_1 term_1)
 (no
  (no term_2)
  (yes_2 term_3)))
EOTREE


my $sibling = <<EOTREE;
(S
 (NP
  (D the)
  (N boy))
 (VP
  ran))
EOTREE

my $npcount = <<EOTREE;
 (S
  (CONJP
    (NP (D the) (N boy))
    (C and)
    (NP (D a) (A tall) (N boy)))
  (NP
    (D a)
    (N girl)
    (PP
      (EDITED
        (P in )
        (NP (PN Naples) (PN On) (PN East) (PN Thames))
        (UH uh))
      (P in)
      (NP (PN Paris)))))
EOTREE


# Test 2
{
    my $empty_root_node = Lingua::Treebank::Const->new();
    $empty_root_node = $empty_root_node->from_penn_string($empty_root);
    ok($empty_root_node->is_empty_root(), "Detect empty root");
}
# Tests 3-4
{
    my $path_node = Lingua::Treebank::Const->new();
    $path_node->from_penn_string($path);
    my @terms = $path_node->get_all_terminals();
    my $child = shift @terms;
    my @ancestors = $child->select_ancestors(sub{$_[0]->tag() eq "NP"});
    ok($ancestors[1] eq $path_node, "Select ancestors 1");
    ok($ancestors[0] eq @{$path_node->children()}[0], "Select ancestors 2");
}


# Test 5
{
    my $children_node = Lingua::Treebank::Const->new();
    $children_node->from_penn_string($children);
    my @children = $children_node->select_children(sub{$_[0]->tag() =~ /yes/});
    @children = map($_->word(), @children);
    ok(eq_array(\@children, ['term_3', 'term_1']), "Select children");
}


# Tests 6-8
{
    my $sibling_node = Lingua::Treebank::Const->new();
    $sibling_node->from_penn_string($sibling);
    my @child = @{$sibling_node->children()};
    my $np = $child[0];
    my $vp = $child[1];
    my $det = @{$np->children()}[0];
    ok($np->is_sibling($vp), "NP-VP sibling");
    ok(not ($det->is_sibling($vp)), "DET-VP not sibling");
    ok(not ($np->is_sibling($det)), "NP-DET not sibling");
}

# test 9-12
{
    my $npcount_node = Lingua::Treebank::Const->new();
    $npcount_node->from_penn_string($npcount);

    # find out how many children each NP has, but don't count anything
    # inside an EDITED node
    my $action = sub {
	my ($self, $state) = @_;
	return unless $self->tag() eq 'NP';

	# just print it

#	print scalar @{$self->children}, "\n";

	# or store it in the state variable
	push @{$state}, scalar @{$self->children()};
    };

    my $stop_crit = sub {$_[0]->tag() eq 'EDITED'};

    {
	my @counts;
	$npcount_node->walk( $action, $stop_crit, \@counts );
	# the-boy, a-tall-boy, a-girl-PP, Paris
	ok(eq_array(\@counts, [2,3,3,1]), "count");
    }

    {
	my @counts;
	$npcount_node->walk( $action, $stop_crit, \@counts, 'breadthfirst' );
	# a-girl-PP, the-boy, a-tall-boy, Paris
	ok(eq_array(\@counts, [3,2,3,1]), "count");
    }

    {
	my @counts;
	$npcount_node->walk( $action, undef, \@counts );
	# the-boy, a-tall-boy, a-girl-PP, Naples-on-east-thames, Paris
	ok(eq_array(\@counts, [2,3,3,4,1]), "count");
    }

    {
	my @counts;
	$npcount_node->walk( $action, undef, \@counts, 'breadthfirst' );
	# a-girl-PP, the-boy, a-tall-boy, Paris, Naples-on-east-thames
	ok(eq_array(\@counts, [3,2,3,1,4]), "count");
    }

#      use List::Util 'sum';
#      print "there were ", sum (@counts),
#        " total children of NP nodes\n";

}
