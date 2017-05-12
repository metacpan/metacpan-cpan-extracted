#
# reader.t - test reading in simple graph
#

use Graph;
use File::Compare;

use Graph::Reader::XML;
use Graph::Reader::HTK;
use Graph::Writer::HTK;
use Graph::Reader::Dot;

my ($graph, $reader, $writer);
my ($testfile);
my $FILE;

print "1..3\n";

$graph = Graph->new();
$graph->add_edge('a' => 'b');
$graph->add_edge('b' => 'c');
$graph->add_edge('c' => 'd');
$graph->add_edge('b' => 'd');
$graph->add_edge('a' => 'c');
$graph->add_edge('c' => 'e');
$graph->add_edge('e' => 'e');

my $ingraph;


#-----------------------------------------------------------------------
# XML
#-----------------------------------------------------------------------
$testfile = 't/data/simple.xml';
$reader = Graph::Reader::XML->new();
if (defined($reader)
    && ($ingraph = $reader->read_graph($testfile))
    && $graph->eq($ingraph))
{
    print "ok 1\n";
} else {
    print "not ok 1\n";
}

#-----------------------------------------------------------------------
# HTK
#	given the nature of the format, the nodes end up with idenfifiers
#	of numbers, even though we start off with letters.
#	So we do a read, write, and then compare the two files.
#-----------------------------------------------------------------------
$testfile = 't/data/simple.htk';
$genfile  = 'foobar.htk';
$reader = Graph::Reader::HTK->new();
$writer = Graph::Writer::HTK->new();
if (defined($reader) && defined($writer)
    && ($ingraph = $reader->read_graph($testfile))
    && $writer->write_graph($ingraph, $genfile)
    && compare($genfile, $testfile, -1) == 0)
{
    print "ok 2\n";
} else {
    print "not ok 2\n";
}
unlink($genfile);

#-----------------------------------------------------------------------
# Dot
#-----------------------------------------------------------------------
$testfile = 't/data/simple.dot';
$reader = Graph::Reader::Dot->new();
if (defined($reader)
    && ($ingraph = $reader->read_graph($testfile))
    && $graph->eq($ingraph))
{
    print "ok 3\n";
} else {
    print "not ok 3\n";
}

