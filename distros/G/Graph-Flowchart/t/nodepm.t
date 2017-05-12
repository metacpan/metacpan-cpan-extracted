#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 18;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Flowchart::Node") or die($@);
   };

#############################################################################

can_ok ('Graph::Flowchart::Node',
  qw/
    new
    _set_type
  /);

my $node = Graph::Flowchart::Node->new ( '$a = 0;' );
is ($node->{_type}, 1, 'type got set');
is ($node->name(), "0", 'name got set');
is ($node->label(), '$a = 0;', 'text');

$node = Graph::Flowchart::Node->new ( '$a = 9;', 2);
is ($node->{_type}, 2, 'type got set');
is ($node->name(), "1", 'new name');
is ($node->label(), '$a = 9;', 'text');

$node = Graph::Flowchart::Node->new ( '$a = 9;', 1, 'MyLabel');
is ($node->{_type}, 1, 'type got set');
is ($node->{_label}, 'MyLabel', 'labelname got set');
is ($node->name(), "2", 'new name');
is ($node->label(), '$a = 9;', 'text');

$node = Graph::Flowchart::Node->new ( '"hello\nworld\n!"', 1);
is ($node->{_type}, 1, 'type got set');
is ($node->{_label}, undef, 'no label');
is ($node->label(), '"hello\\nworld\\n!"', 'multiple \n in label to \\n');

$node = Graph::Flowchart::Node->new ( '"hello\n\nworld!"', 1);
is ($node->{_type}, 1, 'type got set');
is ($node->{_label}, undef, 'no label');
is ($node->label(), '"hello\\n\\nworld!"', 'multiple \n in label to \\n');


