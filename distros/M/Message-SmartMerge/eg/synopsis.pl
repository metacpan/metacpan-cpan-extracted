#!env perl

use strict;use warnings;
use lib '../lib';

#code and results from the synopsis

package mine;
use base 'Message::SmartMerge';
use Data::Dumper;
sub emit {
    my $self = shift;
    my %args = @_;
    print Dumper $args{message};
}

package main;

my $merge = mine->new();
$merge->config({
    merge_instance => 'instance',
});

$merge->message({
    instance => 'i1',
    x => 'y',
    this => 'whatever',
});
#$VAR1 = {
#          'x' => 'y',
#          'instance' => 'i1',
#          'this' => 'whatever'
#        };

$merge->add_merge({
    merge_id => 'm1',
    match => {x => 'y'},
    transform => {this => 'that'},
});
#$VAR1 = {
#          'x' => 'y',
#          'instance' => 'i1',
#          'this' => 'that'
#        };

$merge->message({
    instance => 'i1',
    x => 'y',
    this => 'not that',
    something => 'else',
});
#$VAR1 = {
#          'x' => 'y',
#          'instance' => 'i1',
#          'this' => 'that',
#          'something' => 'else'
#        };

$merge->remove_merge('m1');
#$VAR1 = {
#          'x' => 'y',
#          'instance' => 'i1',
#          'this' => 'not that',
#          'something' => 'else'
#        };

$merge->add_merge({
    merge_id => 'm2',
    match => {
        x => 'y',
    },
    transform => {
        foo => 'bar',
    },
    toggle_fields => ['something'],
});
#$VAR1 = {
#          'foo' => 'bar',
#          'x' => 'y',
#          'instance' => 'i1',
#          'this' => 'not that',
#          'something' => 'else'
#        };


$merge->message({
    instance => 'i1',
    x => 'y',
    foo => 'not bar',
    something => 'else',
    another => 'thing',
});
#$VAR1 = {
#          'another' => 'thing',
#          'x' => 'y',
#          'foo' => 'bar',
#          'instance' => 'i1',
#          'something' => 'else'
#        };

$merge->message({
    instance => 'i1',
    x => 'y',
    foo => 'not bar',
    something => 'other',
    another => 'thing',
});
#$VAR1 = {
#          'another' => 'thing',
#          'x' => 'y',
#          'foo' => 'not bar',
#          'instance' => 'i1',
#          'something' => 'other'
#        };

print "remove_match merge:\n";

$merge->add_merge({
    merge_id => 'm3',
    match => {
        i => 'j',
    },
    transform => {
        a => 'b',
    },
    remove_match => {
        remove => 'match',
    },
});
#nothing

$merge->message({
    instance => 'i2',
    x => 'y',
    i => 'j',
    foo => 'not bar',
    a => 'not b',
    something => 'here',
});
#$VAR1 = {
#          'a' => 'b',
#          'x' => 'y',
#          'foo' => 'not bar',
#          'instance' => 'i2',
#          'i' => 'j',
#          'something' => 'here'
#        };

print "remove match\n";
$merge->message({
    instance => 'i2',
    x => 'y',
    i => 'j',
    a => 'not b',
    remove => 'match',
});
#$VAR1 = {
#          'remove' => 'match',
#          'a' => 'not b',
#          'x' => 'y',
#          'instance' => 'i2',
#          'i' => 'j'
#        };

