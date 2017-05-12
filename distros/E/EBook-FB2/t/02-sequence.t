#!perl -T

use Test::More tests => 2;
use XML::DOM;
use XML::DOM::XPath;
use EBook::FB2::Description::Sequence;

my $sequence_data = '<sequence name="seqname" number="1"/>';

my $parser = XML::DOM::Parser->new();
my $xp = $parser->parse($sequence_data);
my $sequence = EBook::FB2::Description::Sequence->new;
my @nodes = $xp->findnodes("/sequence");
$sequence->load($nodes[0]);
is($sequence->name, 'seqname');
is($sequence->number, '1');
