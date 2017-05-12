#!/usr/bin/perl

# This is a port of the Java code in the SecondHop.java example. You can find
# the original Java source at:
#
#   http://jackrabbit.apache.org/doc/firststeps.html#Hop_2:_Working_with_content
#
# -- Sterling, 2006-06-11

use strict;
use warnings;

use Java::JCR;
use Java::JCR::Jackrabbit;

my $repository = Java::JCR::Jackrabbit->new;
my $session = $repository->login(
    Java::JCR::SimpleCredentials->new('username', 'password'));

my $root = $session->get_root_node;

my $hello = $root->add_node('hello');
my $world = $hello->add_node('world');
$world->set_property('message', 'Hello, World!');
$session->save;

my $node = $root->get_node('hello/world');
print $node->get_path(), "\n";
print $node->get_property('message')->get_string, "\n";

$root->get_node('hello')->remove;
$session->save;

$session->logout;
