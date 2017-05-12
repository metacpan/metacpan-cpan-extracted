#!/usr/bin/perl

use strict;
use warnings;

our $test_class = 'TypeTest::Objects';

my $uid = uid();
our @mapping = (
    'object'  => { type => 'object', enabled => 0 },
    'objectx' => { type => 'object', enabled => 0 },

    'doc' => {
        type       => "object",
        dynamic    => "strict",
        properties => {
            email     => { type => "string" },
            name      => { type => "string" },
            timestamp => { type => "date" },
            lazy      => { type => "string" },
            uid       => $uid,
        },
    },

    'doc_none' => {
        type       => "object",
        dynamic    => "strict",
        properties => { uid => $uid, },
    },

    'doc_name' => {
        type       => "object",
        dynamic    => "strict",
        properties => {
            name => { type => "string" },
            uid  => $uid,
        },

    },

    'doc_exname' => {
        type       => "object",
        dynamic    => "strict",
        properties => {
            email     => { type => "string" },
            timestamp => { type => "date" },
            lazy      => { type => "string" },
            uid       => $uid,
        },

    },

    'moose' => {
        type       => "object",
        dynamic    => "strict",
        properties => {
            name => { type => "string" },
            two  => {
                dynamic    => "strict",
                properties => { foo => { type => "string" } },
                type       => "object",
            },
        },
    },

    'moose_none' => { enabled => 0, type => "object" },

    'moose_name' => {
        type       => "object",
        dynamic    => "strict",
        properties => { name => { type => "string" } }
    },

    'moose_exname' => {
        type       => "object",
        dynamic    => "strict",
        properties => {
            two => {
                dynamic    => "strict",
                properties => { foo => { type => "string" } },
                type       => "object",
            },
        },
    },

    'non_moose'   => qr/No mapper found/,
    'not_defined' => qr/No mapper found/,
    'bad_mapping' => qr/even number of elements/,

    'custom'       => { type    => 'string' },
    'custom_class' => { type    => 'integer' },
    'no_tc'        => { enabled => 0, type => "object" },
);

do 't/10_typemaps/test_mapping.pl' or die $!;

#===================================
sub uid {
#===================================
    +{  type       => "object",
        dynamic    => "strict",
        path       => 'full',
        properties => {
            id      => { index => "not_analyzed", type => "string" },
            index   => { index => "not_analyzed", type => "string" },
            routing => { index => "no",           type => "string" },
            type    => {
                index => "not_analyzed",
                type  => "string",
            },
        },
    };
}
1;
