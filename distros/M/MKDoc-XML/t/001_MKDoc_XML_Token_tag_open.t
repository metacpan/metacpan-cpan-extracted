#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Token;

my $data  = qq |<a petal:omit-tag="">|;
my $token = new MKDoc::XML::Token ($data);
my $node  = $token->tag_open();
ok (exists $node->{'petal:omit-tag'});
is ($node->{'petal:omit-tag'}, '');

$data  = qq |<a foo_bulb:zoo="baz">|;
$token = new MKDoc::XML::Token ($data);
$node  = $token->tag_open();
ok (exists $node->{'foo_bulb:zoo'});
is ($node->{'foo_bulb:zoo'}, 'baz');

$data = <<EOF;
<a petal_temp:attributes
   = "petal:attributes dididi dadada">
EOF

$token = new MKDoc::XML::Token ($data);
$node  = $token->tag_open();
is ($node->{'petal_temp:attributes'}, 'petal:attributes dididi dadada');

$token = new MKDoc::XML::Token (qq |<head foo='bar'>|);
$node  = $token->tag_open();
is ($node->{foo}, 'bar');


1;


__END__
