#!perl -T

use Test::More tests => 2;
use XML::DOM;
use XML::DOM::XPath;
use EBook::FB2::Description::CustomInfo;

my $custom_data = '<custom-info info-type="weirdinfotype">long info</custom-info>';

my $parser = XML::DOM::Parser->new();
my $xp = $parser->parse($custom_data);
my $custom = EBook::FB2::Description::CustomInfo->new;
my @nodes = $xp->findnodes("/custom-info");
$custom->load($nodes[0]);
is($custom->info, 'long info');
is($custom->info_type, 'weirdinfotype');
