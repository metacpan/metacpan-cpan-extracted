#!/usr/bin/perl -w

use strict;
use lib qw( ./lib ../lib);
use Kite::XML::Node;

#------------------------------------------------------------------------
package MyNode;
use base qw( Kite::XML::Node );
use vars qw( $ATTRIBUTES $ELEMENTS $ERROR );

$ATTRIBUTES = {
    id    => undef,
    lang  => 'en',
    title => '',
};

$ELEMENTS = {
    foo =>   'MyNode::Foo',
    bar =>   'MyNode::Bar+',
    baz => [ 'MyNode::Baz',  'MyNode::Baz::Nofile' ],
    qux => [ 'MyNode::Qux+', 'MyNode::Qux::Nofile' ],
};

#------------------------------------------------------------------------
package MyNode::Foo;
use base qw( Kite::XML::Node );
use vars qw( $ATTRIBUTES $ELEMENTS $ERROR );

$ATTRIBUTES = {
    id    => undef,
};

$ELEMENTS = {
    CDATA => 1,
};

#------------------------------------------------------------------------
package MyNode::Bar;
use base qw( Kite::XML::Node );
use vars qw( $ATTRIBUTES $ELEMENTS $ERROR );

$ATTRIBUTES = {
    id    => undef,
    name  => '',
};

$ELEMENTS = {
    foo =>   'MyNode::Foo+',
};

#------------------------------------------------------------------------
package main;

print "1..23\n";
my $n = 0;

sub ok {

    shift or print "not ";
    print "ok ", ++$n, "\n";
}

my $node;

$node = MyNode->new(id => 123);
die "1: ", $MyNode::ERROR, "\n" unless $node;
ok( $node );
ok( $node->id() == 123 );

$node = MyNode->new(id => 456, title => 'test');
die "2: ", $MyNode::ERROR, "\n" unless $node;
ok( $node );
ok( $node->id() == 456 );
ok( $node->lang() eq 'en' );
ok( $node->title eq 'test' );

ok( ! defined $node->foo );
my $bar = $node->bar();
ok( $bar );
ok( ref $bar eq 'ARRAY' );

my $qux = $node->qux;
ok( $qux );
ok( ref $qux eq 'ARRAY' );

ok( $node->attr('id') == 456 );
ok( $node->attribute('id') == 456 );
ok( ref $node->elem('bar') eq 'ARRAY' );
ok( ref $node->element('bar') eq 'ARRAY' );

my $foo = $node->child('foo');
ok( ! $foo );
ok( $node->error() eq 'id not defined' );
$foo = $node->child('foo', id => 25);
die "no foo: ", $node->error(), "\n" unless $foo;

ok( $foo );
ok( $foo->id(25) );

$bar = $node->child('bar', id => 35)
    || die $node->error(), "\n";

ok( $bar );
ok( $bar->id == 35 );

$bar = $node->bar(id => 45)
    || die $node->error(), "\n";

ok( $bar );
ok( $bar->id == 45 );


#print $node->_dump();


