#
# simple.t - simple tests for writing graphs
#

use Graph;

use Graph::Writer::XML;
use Graph::Writer::HTK;
use Graph::Writer::Dot;
use Graph::Writer::VCG;
use Graph::Writer::daVinci;

use File::Compare;

my ($graph, $writer);
my ($genfile, $expected);
my $FILE;

print "1..5\n";

$graph = Graph->new();
$graph->add_edge('a' => 'b');
$graph->add_edge('b' => 'c');
$graph->add_edge('c' => 'd');
$graph->add_edge('b' => 'd');
$graph->add_edge('a' => 'c');
$graph->add_edge('c' => 'e');
$graph->add_edge('e' => 'e');


#-----------------------------------------------------------------------
# XML
#-----------------------------------------------------------------------
$genfile  = 'test.xml';
$expected = 't/data/simple.xml';
$writer = Graph::Writer::XML->new();
if (defined($writer)
    && $writer->write_graph($graph, $genfile)
    && compare($genfile, $expected, -1) == 0)
{
    print "ok 1\n";
} else {
    print "not ok 1\n";
}
unlink $genfile;

#-----------------------------------------------------------------------
# HTK
#-----------------------------------------------------------------------
$genfile  = 'test.htk';
$expected = 't/data/simple.htk';
$writer = Graph::Writer::HTK->new();
if (defined($writer)
    && $writer->write_graph($graph, $genfile)
    && compare($genfile, $expected, -1) == 0)
{
    print "ok 2\n";
} else {
    print "not ok 2\n";
}
unlink $genfile;

#-----------------------------------------------------------------------
# Dot
#-----------------------------------------------------------------------
$genfile  = 'test.dot';
$expected = 't/data/simple.dot';
$writer = Graph::Writer::Dot->new();
if (defined($writer)
    && $writer->write_graph($graph, $genfile)
    && compare($genfile, $expected, -1) == 0)
{
    print "ok 3\n";
} else {
    print "not ok 3\n";
}
unlink $genfile;

#-----------------------------------------------------------------------
# VCG
#-----------------------------------------------------------------------
$genfile  = 'test.vcg';
$expected = 't/data/simple.vcg';
$writer = Graph::Writer::VCG->new();
if (defined($writer)
    && $writer->write_graph($graph, $genfile)
    && compare($genfile, $expected, -1) == 0)
{
    print "ok 4\n";
} else {
    print "not ok 4\n";
}
unlink $genfile;

#-----------------------------------------------------------------------
# daVinci
#-----------------------------------------------------------------------
$genfile  = 'test.davinci';
$expected = 't/data/simple.davinci';
$writer = Graph::Writer::daVinci->new();
if (defined($writer)
    && $writer->write_graph($graph, $genfile)
    && compare($genfile, $expected, -1) == 0)
{
    print "ok 5\n";
} else {
    print "not ok 5\n";
}
unlink $genfile;

