#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::EMX 'message';
use Email::MIME;
use Email::MIME::XPath;

use Test::More 'no_plan';

my $msg = message('mixed-alternative');
isa_ok $msg, 'Email::MIME';
isa_ok $msg->__xpath_engine, 'Tree::XPathEngine';

my (@parts) = $msg->xpath_findnodes('/*');
is @parts, 1, "root has a single child";
isa_ok $parts[0], 'Email::MIME';
is $parts[0], $msg, "it's the original message";

(@parts) = sort { $a->content_type cmp $b->content_type }
  $msg->xpath_findnodes('//*[@content_type =~ /^text\//]');

is @parts, 2, "two text/ parts";
is $parts[0]->xpath_get_name, 'html',  'one is html';
is $parts[1]->xpath_get_name, 'plain', 'one is plain';

my $node = $msg->xpath_findnode('//*[@subject="your face"]');
isa_ok $node, 'Email::MIME';
is $node, $msg, "found original message using subject";

$node = $msg->xpath_findnode('//png[@filename="yourface.png"]');
isa_ok $node, 'Email::MIME';
is $msg->xpath_findnode('//*[@address=' . $node->xpath_address . ']'),
  $node, "found node by address";

$msg = message('plain');
is $msg->xpath_findnode('//plain'), $msg, "single plain part";
