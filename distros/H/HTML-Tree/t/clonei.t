#!/usr/bin/perl -T

use warnings;
use strict;
use Test::More tests => 3;
use HTML::TreeBuilder;

my $t = HTML::TreeBuilder->new;
$t->parse('stuff <em name="foo">lalal</em>');
$t->eof;
my $c = $t->clone();

#these are correct tests. Of what, I'm not sure.
ok( $c->same_as($t), "\$c is the same as \$t, according to HTML::Element" );
ok( $t->same_as($c), "\$t is the same as \$c, according to HTML::Element" );

$c->delete();
ok( $t->find_by_attribute( 'name', 'foo' ), "My name is foo after delete" );

$t->delete();
