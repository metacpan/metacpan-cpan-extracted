#use Test;
use Test::More;
use Test::Deep;

plan tests => 12;
use strict;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::OBOParser;
use GOBO::Writers::OBOWriter;
use FileHandle;


my $parser = new GOBO::Parsers::OBOParser(file=>"t/data/obo_file.obo");

$parser->parse;

my $g = $parser->graph;

print STDERR "graph: " . Dumper($g);

#print "Mystery node: " . Dumper($g->noderef(" "));

## create a new graph and check that we can add terms 'n' links 'n' stuff to it
my $new_g = new GOBO::Graph;

foreach (@{$g->terms})
{	$new_g->add_term( $g->noderef($_) );
}

foreach (@{$g->relations})
{	$new_g->add_relation( $g->noderef($_) );
}


$new_g->add_links( $g->links );
#foreach (@{$g->links})
#{	$new_g->add_link( $_ );
#}

foreach my $attrib qw( version source provenance date xrefs alt_ids is_anonymous comment declared_subsets property_value_map )
{	$new_g->$attrib( $g->$attrib ) if $g->$attrib;
}

## HACKS!
# add mystery term
#$new_g->{node_index}{ixN}{" "} = $g->noderef(" ");
# delete ixLabel
$new_g->{node_index}{ixLabel} = {};
# sort the term relationships in link_ix
foreach my $t ($g, $new_g)
{	foreach my $k (keys %{$t->{link_ix}{ixT}})
	{	$t->{link_ix}{ixT}{$k} = [ sort { $a->{node}{id} cmp $b->{node}{id} } @{$t->{link_ix}{ixT}{$k}} ];
	}
}


ok( $new_g->isa('GOBO::Graph'), "Checking new_g is a graph" );

foreach (keys %$g)
{	if (! cmp_deeply($g->{$_}, $new_g->{$_}, "Checking $_ graph structures..."))
	{	print "non-matching structures: graph: " . Dumper($g->{$_}) . "\nnew_g: " . Dumper($new_g->{$_});
	}
}

exit(0);
