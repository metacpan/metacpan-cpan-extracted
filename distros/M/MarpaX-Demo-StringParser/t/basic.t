use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Capture::Tiny 'capture';

use MarpaX::Demo::StringParser;

use Test::More;

use utf8;

# -------------

my(%expected) =
(
	'edge.01' => << 'EOS',
root. Attributes: {uid => "0"}
    |--- prolog. Attributes: {uid => "1"}
    |--- graph. Attributes: {uid => "2"}
         |--- edge_id. Attributes: {uid => "3", value => "->"}
              |--- literal. Attributes: {uid => "4", value => "{"}
              |--- color. Attributes: {uid => "5", value => "cornflowerblue"}
              |--- label. Attributes: {uid => "6", value => "This edge's color is blueish"}
              |--- literal. Attributes: {uid => "7", value => "}"}
Parse result: 0 (0 is success)
EOS
	'graph.01' => << 'EOS',
root. Attributes: {uid => "0"}
    |--- prolog. Attributes: {uid => "1"}
    |--- graph. Attributes: {uid => "2"}
         |--- node_id. Attributes: {uid => "3", value => "node.1"}
         |    |--- literal. Attributes: {uid => "4", value => "{"}
         |    |--- color. Attributes: {uid => "5", value => "red"}
         |    |--- label. Attributes: {uid => "6", value => "Node A"}
         |    |--- literal. Attributes: {uid => "7", value => "}"}
         |--- edge_id. Attributes: {uid => "8", value => "->"}
         |    |--- literal. Attributes: {uid => "9", value => "{"}
         |    |--- color. Attributes: {uid => "10", value => "green"}
         |    |--- label. Attributes: {uid => "11", value => "Edge B"}
         |    |--- literal. Attributes: {uid => "12", value => "}"}
         |--- edge_id. Attributes: {uid => "13", value => "->"}
         |    |--- literal. Attributes: {uid => "14", value => "{"}
         |    |--- color. Attributes: {uid => "15", value => "red"}
         |    |--- label. Attributes: {uid => "16", value => "Edge C C"}
         |    |--- literal. Attributes: {uid => "17", value => "}"}
         |--- node_id. Attributes: {uid => "18", value => "node.2"}
         |--- edge_id. Attributes: {uid => "19", value => "->"}
Parse result: 0 (0 is success)
EOS
	'node.01' => << 'EOS',
root. Attributes: {uid => "0"}
    |--- prolog. Attributes: {uid => "1"}
    |--- graph. Attributes: {uid => "2"}
         |--- node_id. Attributes: {uid => "3", value => ""}
Parse result: 0 (0 is success)
EOS
	'quote.01' => << 'EOS',
root. Attributes: {uid => "0"}
    |--- prolog. Attributes: {uid => "1"}
    |--- graph. Attributes: {uid => "2"}
         |--- node_id. Attributes: {uid => "3", value => "node"}
              |--- literal. Attributes: {uid => "4", value => "{"}
              |--- color. Attributes: {uid => "5", value => "red"}
              |--- label. Attributes: {uid => "6", value => "\;"}
              |--- shape. Attributes: {uid => "7", value => "square"}
              |--- literal. Attributes: {uid => "8", value => "}"}
Parse result: 0 (0 is success)
EOS
	'table.01' => << 'EOS',
root. Attributes: {uid => "0"}
    |--- prolog. Attributes: {uid => "1"}
    |--- graph. Attributes: {uid => "2"}
         |--- node_id. Attributes: {uid => "3", value => "node.1"}
              |--- literal. Attributes: {uid => "4", value => "{"}
              |--- color. Attributes: {uid => "5", value => "pink"}
              |--- label. Attributes: {uid => "6", value => "<<table border='1'><tr><td>HTML-style label and '</td></tr></table>>"}
              |--- shape. Attributes: {uid => "7", value => "rectangle"}
              |--- literal. Attributes: {uid => "8", value => "}"}
Parse result: 0 (0 is success)
EOS
	'utf8.01' => << 'EOS',
root. Attributes: {uid => "0"}
    |--- prolog. Attributes: {uid => "1"}
    |--- graph. Attributes: {uid => "2"}
         |--- node_id. Attributes: {uid => "3", value => "From"}
         |    |--- literal. Attributes: {uid => "4", value => "{"}
         |    |--- color. Attributes: {uid => "5", value => "green"}
         |    |--- label. Attributes: {uid => "6", value => "Reichwaldstraße"}
         |    |--- literal. Attributes: {uid => "7", value => "}"}
         |--- edge_id. Attributes: {uid => "8", value => "->"}
         |    |--- literal. Attributes: {uid => "9", value => "{"}
         |    |--- color. Attributes: {uid => "10", value => "red"}
         |    |--- label. Attributes: {uid => "11", value => "Πηληϊάδεω Ἀχιλῆος"}
         |    |--- literal. Attributes: {uid => "12", value => "}"}
         |--- node_id. Attributes: {uid => "13", value => "To"}
              |--- literal. Attributes: {uid => "14", value => "{"}
              |--- color. Attributes: {uid => "15", value => "blue"}
              |--- label. Attributes: {uid => "16", value => "Δ Lady"}
              |--- literal. Attributes: {uid => "17", value => "}"}
Parse result: 0 (0 is success)
EOS
);
my($count) = 0;

my($file_name);
my($parser);
my($stdout, $stderr);

for my $key (sort keys %expected)
{
	$count++;

	$file_name         = "data/$key.dash";
	$parser            = MarpaX::Demo::StringParser -> new(input_file => $file_name, maxlevel => 'info');
	($stdout, $stderr) = capture{$parser -> run};

	ok($stdout eq $expected{$key}, "Output matches for $file_name");
}

print "# Internal test count: $count\n";

done_testing($count);
