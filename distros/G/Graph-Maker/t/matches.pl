use strict;
use warnings;

sub directedok
{
	my ($g) = @_;
	return 0 unless $g->directed();
	foreach my $e($g->edges())
	{
		return 0 unless $g->has_edge($e->[1], $e->[0]);
	}
	return 1;
}

sub matches
{
	my ($g, $edges, $directed, $debug) = @_;

	print "$g\n" if $debug;
	my @edges = grep {m/\-/} split(/,/, $edges);
	my $t = "$g";
	my $r = 1;
	$r &&= $g->has_edge(split(/-/, $_)) foreach (@edges);
	if($directed && $r)
	{
		$r &&= $g->has_edge(reverse split(/-/, $_)) foreach (@edges);
	}
	if($debug)
	{
		foreach (@edges)
		{
			print "[", join(', ', split(/-/, $_)), "]\n" unless $g->has_edge(split(/-/, $_));
		}
		if($directed)
		{
			foreach (@edges)
			{
				print '[', join(', ', reverse split(/-/, $_)), "]\n" unless $g->has_edge(reverse split(/-/, $_));
			}
		}
	}
	my %verts = map {do {my ($f, $t) = split(/-/, $_); ($f=>1, (defined $t ? ($t=>1) : ()))} } split(/,/, $edges);
	print "$r\te: " . $g->edges() . "\tE: " . @edges . "\tv: " . $g->vertices() . "\tV: " . keys(%verts) . "\t" . $g->is_directed() . "\n" if $debug;
	return $r
		&& $g->edges() == ($directed ? 2 : 1)*@edges
		&& $g->vertices() == keys %verts
		&& $g->is_directed() == $directed;
}

1;
