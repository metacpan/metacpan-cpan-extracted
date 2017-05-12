#!/usr/bin/perl

# This is a port of the Java code in the ThirdHop.java example. You can find
# the original Java source at:
#
#   http://jackrabbit.apache.org/doc/firststeps.html#Hop_3:_Importing_content
#
# -- Sterling, 2006-06-11

use strict;
use warnings;

use Java::JCR;
use Java::JCR::Nodetype;
use Java::JCR::Jackrabbit;

sub dump_node {
    my $node = shift;

    print $node->get_path, "\n";

    if ($node->get_name eq 'jcr:system') {
        return;
    }

    my $properties = $node->get_properties;
    while ($properties->has_next) {
        my $property = $properties->next_property;
        if ($property->get_definition->is_multiple) {
            my $values = $property->get_values;
            for my $value (@$values) {
                print $property->get_path, ' = ', $value->get_string, "\n";
            }
        }

        else {
            print $property->get_path, ' = ', $property->get_string, "\n";
        }
    }

    my $nodes = $node->get_nodes;
    while ($nodes->has_next) {
        dump_node($nodes->next_node);
    }
}

my $repository = Java::JCR::Jackrabbit->new;
my $session = $repository->login(
    Java::JCR::SimpleCredentials->new('username', 'password')
);

my $root = $session->get_root_node;

if ($root->has_node('importxml')) {
    my $importxml = $root->get_node('importxml');
    $importxml->remove;
    $session->save;
}

print "Importing xml... \n";

my $node = $root->add_node('importxml', 'nt:unstructured');
open XML, 'test.xml' or die "Failed to open test.xml: $!";

eval {
    $session->import_xml('/importxml', \*XML,
        $Java::JCR::ImportUUIDBehavior::IMPORT_UUID_CREATE_NEW);
};

if ($@) {
    die "$@\n";
}

close XML;

$session->save;

print "done.\n";

dump_node($root);

$session->logout;
