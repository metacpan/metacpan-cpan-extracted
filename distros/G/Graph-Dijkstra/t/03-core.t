use strict;
use warnings;

use Test::More tests=>6;


BEGIN {#1
    use_ok( 'Graph::Dijkstra' ) || print "Bail out!\n";
}

{#tests 2-6

	my $graph = Graph::Dijkstra->new();
	ok(defined($graph), 'Dijkstra->new()');
	
	$graph->node( { id=>'A', label=>'one' } );
	$graph->node( { id=>'B', label=>'two' } );
	$graph->node( { id=>'C', label=>'three' } );
	$graph->node( { id=>'D', label=>'four' } );
	$graph->node( { id=>'E', label=>'five' } );
	$graph->node( { id=>'F', label=>'six' } );
	$graph->node( { id=>'G', label=>'seven' } );
	$graph->node( { id=>'H', label=>'eight' } );
	$graph->node( { id=>'I', label=>'nine' } );
	$graph->node( { id=>'J', label=>'ten' } );
	$graph->node( { id=>'K', label=>'eleven' } );
	$graph->node( { id=>'L', label=>'twelve' } );
	$graph->node( { id=>'M', label=>'thirteen' } );
	$graph->node( { id=>'N',  label=>'fourteen' } );
	
	
	$graph->node( { id=>'O',  label=>'fifteen' } );
	$graph->node( { id=>'P',  label=>'sixteen' } );
	$graph->node( { id=>'Q',  label=>'seventeen' } );
	
	$graph->node( { id=>'R',  label=>'eighteen' } );
	$graph->node( { id=>'S',  label=>'ninteen' } );
	$graph->node( { id=>'T',  label=>'twenty' } );
	$graph->node( { id=>'U',  label=>'twenty-one' } );
	$graph->node( { id=>'V',  label=>'twenty-two' } );
	$graph->node( { id=>'W',  label=>'twenty-three' } );
	$graph->node( { id=>'X',  label=>'twenty-four' } );
	$graph->node( { id=>'Y',  label=>'twenty-five' } );
	$graph->node( { id=>'Z',  label=>'twenty-six' } );
	
	$graph->edge( { sourceID=>'A', targetID=>'B', weight=>4 } );
	$graph->edge( { sourceID=>'A', targetID=>'D', weight=>3 } );
	$graph->edge( { sourceID=>'A', targetID=>'E', weight=>7 } );
	$graph->edge( { sourceID=>'A', targetID=>'F', weight=>5 } );
	$graph->edge( { sourceID=>'B', targetID=>'C', weight=>7 } );
	$graph->edge( { sourceID=>'B', targetID=>'F', weight=>2 } );
	$graph->edge( { sourceID=>'C', targetID=>'F', weight=>3 } );
	$graph->edge( { sourceID=>'C', targetID=>'G', weight=>5 } );
	$graph->edge( { sourceID=>'D', targetID=>'E', weight=>5 } );
	$graph->edge( { sourceID=>'D', targetID=>'H', weight=>5 } );
	$graph->edge( { sourceID=>'E', targetID=>'F', weight=>3 } );
	$graph->edge( { sourceID=>'E', targetID=>'H', weight=>2 } );
	$graph->edge( { sourceID=>'F', targetID=>'G', weight=>4 } );
	$graph->edge( { sourceID=>'F', targetID=>'K', weight=>5 } );
	$graph->edge( { sourceID=>'G', targetID=>'K', weight=>2 } );
	$graph->edge( { sourceID=>'H', targetID=>'L', weight=>6 } );
	$graph->edge( { sourceID=>'I', targetID=>'J', weight=>2 } );
	$graph->edge( { sourceID=>'I', targetID=>'L', weight=>4 } );
	$graph->edge( { sourceID=>'I', targetID=>'M', weight=>7 } );
	$graph->edge( { sourceID=>'J', targetID=>'K', weight=>9 } );
	$graph->edge( { sourceID=>'K', targetID=>'N', weight=>6 } );
	$graph->edge( { sourceID=>'M', targetID=>'N', weight=>3 } );
	
	$graph->edge( { sourceID=>'N', targetID=>'O', weight=>3 } );
	$graph->edge( { sourceID=>'O', targetID=>'P', weight=>3 } );
	$graph->edge( { sourceID=>'P', targetID=>'Q', weight=>4 } );
	$graph->edge( { sourceID=>'Q', targetID=>'O', weight=>5 } );
	
	$graph->edge( { sourceID=>'Q', targetID=>'R', weight=>2 } );
	$graph->edge( { sourceID=>'N', targetID=>'R', weight=>2 } );
	$graph->edge( { sourceID=>'R', targetID=>'S', weight=>3 } );
	$graph->edge( { sourceID=>'S', targetID=>'T', weight=>4 } );
	$graph->edge( { sourceID=>'T', targetID=>'U', weight=>5 } );
	$graph->edge( { sourceID=>'U', targetID=>'V', weight=>4 } );
	$graph->edge( { sourceID=>'V', targetID=>'W', weight=>3 } );
	$graph->edge( { sourceID=>'W', targetID=>'X', weight=>2 } );
	$graph->edge( { sourceID=>'X', targetID=>'Y', weight=>1 } );
	$graph->edge( { sourceID=>'Y', targetID=>'Z', weight=>2 } );
	$graph->edge( { sourceID=>'A', targetID=>'Z', weight=>7 } );
	
	
	
	my %solutionMatrix = ();
	
	my $graphMinMax = $graph->vertexCenter(\%solutionMatrix);
	ok($graphMinMax == 23, '$graph->vertexCenter(\%solutionMatrix) == 23');
	
	my @nodeList = (sort keys %{$solutionMatrix{row}});
	ok(scalar(@nodeList) == 26, '@nodeList = (sort keys %{$solutionMatrix{row}}) contains 26 nodes');
	
	my $filename = 't/data/APSP.csv';
	
	$graph->outputAPSPmatrixtoCSV(\%solutionMatrix, $filename);
	ok(-e $filename, "'$filename' created");
	
	unlink($filename);
	
	%solutionMatrix = ();
	
	$graphMinMax = $graph->vertexCenterFloydWarshall(\%solutionMatrix);
	ok($graphMinMax == 23, '$graph->vertexCenterFloydWarshall(\%solutionMatrix) == 23');

}
exit(0);