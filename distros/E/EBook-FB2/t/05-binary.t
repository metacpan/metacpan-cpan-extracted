#!perl -T

use Test::More tests => 3;
use XML::DOM;
use XML::DOM::XPath;
use EBook::FB2::Binary;

my $binary_data = <<__EOBIN__;
<binary id="id.png" content-type="content/type">
dGVzdHRlc3Q=
</binary>
__EOBIN__

my $parser = XML::DOM::Parser->new();
my $xp = $parser->parse($binary_data);
my $binary = EBook::FB2::Binary->new;
my @nodes = $xp->findnodes("/binary");
$binary->load($nodes[0]);
is($binary->id, 'id.png');
is($binary->content_type, 'content/type');
is($binary->data, 'testtest');
