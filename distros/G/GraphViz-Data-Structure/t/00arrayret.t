#!/usr/bin/perl -w
use strict;

BEGIN {
  unshift @INC,'../lib';
}

use Test::More tests=>52;

use GraphViz::Data::Structure;
my $gvds = GraphViz::Data::Structure->new(1);
my($object, $top, @port);

# scalar
($object, $top, @port) = $gvds->new(2);
ok(defined $object, "new() clones object");
ok(defined $top,    "returns object name");
like($top, qr/^gvds_atom/, "name type is right");
is_deeply(\@port, [], "port list is empty as expected");

# regex
($object, $top, @port) = $gvds->new(qr/foo/);
ok(defined $object, "new() clones object");
ok(defined $top,    "returns object name");
like($top, qr/^gvds_atom/, "name type is right");
is_deeply(\@port, [], "port list is empty as expected");

# scalar ref
my $x=3;
($object, $top, @port) = $gvds->new(\$x);
ok(defined $object, "new() clones object");
ok(defined $top,    "returns object name");
like($top, qr/^gvds_scalar/, "name type is right");
is_deeply(\@port, [], "port list is empty as expected");

# blessed scalar ref
$x=3;
my $y = \$x;
bless $y, "Foo";
($object, $top, @port) = $gvds->new($y);
ok(defined $object, "new() clones object");
ok(defined $top,    "returns object name");
like($top, qr/^gvds_scalar/, "name type is right");
is_deeply(\@port, ['to_port'=>0], "port list as expected");

# blessed scalar ref to ref
$x=\3;
$y = \$x;
bless $y, "Foo";
($object, $top, @port) = $gvds->new($y);
ok(defined $object, "new() clones object");
ok(defined $top,    "returns object name");
like($top, qr/^gvds_scalar/, "name type is right");
is_deeply(\@port, ['to_port'=>0], "port list as expected");

# array
($object, $top, @port) = $gvds->new([1,2,3]);
ok(defined $object, "new() clones object");
ok(defined $top,    "returns object name");
like($top, qr/^gvds_array/, "name type is right");
is_deeply(\@port, [], "port list as expected");

# blessed array
($object, $top, @port) = $gvds->new(bless([1,2,3],"foo"));
ok(defined $object, "new() clones object");
ok(defined $top,    "returns object name");
like($top, qr/^gvds_array/, "name type is right");
is_deeply(\@port, ['to_port'=>0], "port list as expected");

# hash
$x = {1=>2,3=>4};
($object, $top, @port) = $gvds->new($x);
ok(defined $object, "new() clones object");
ok(defined $top,    "returns object name");
like($top, qr/^gvds_hash/, "name type is right");
is_deeply(\@port, [], "port list as expected");

# blessed hash
$y = bless $x,"foo";
($object, $top, @port) = $gvds->new($y);
ok(defined $object, "new() clones object");
ok(defined $top,    "returns object name");
like($top, qr/^gvds_hash/, "name type is right");
is_deeply(\@port, ['to_port'=>0], "port list as expected");

# glob
($object, $top, @port) = $gvds->new(*FOO);
ok(defined $object, "new() clones object");
ok(defined $top,    "returns object name");
like($top, qr/^gvds_atom/, "name type is right");
is_deeply(\@port, [], "port list as expected");

# glob ref
($object, $top, @port) = $gvds->new(\*FOO);
ok(defined $object, "new() clones object");
ok(defined $top,    "returns object name");
like($top, qr/^gvds_glob/, "name type is right");
is_deeply(\@port, ['to_port'=>0], "port list as expected");

# code ref
($object, $top, @port) = $gvds->new(sub{ print "Hi there!\n" });
ok(defined $object, "new() clones object");
ok(defined $top,    "returns object name");
like($top, qr/^gvds_sub/, "name type is right");
is_deeply(\@port, [], "port list as expected");

# blessed code ref
($object, $top, @port) = $gvds->new(bless(sub{ print "Hi there!\n" },"foo"));
ok(defined $object, "new() clones object");
ok(defined $top,    "returns object name");
like($top, qr/^gvds_sub/, "name type is right");
is_deeply(\@port, [], "port list as expected");

