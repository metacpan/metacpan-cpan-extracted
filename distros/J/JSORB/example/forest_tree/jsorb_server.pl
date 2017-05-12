#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use Scalar::Util 'blessed';

use lib "$FindBin::Bin/../../lib";

use JSORB;
use JSORB::Dispatcher::Path;
use JSORB::Server::Simple;
use JSORB::Server::Traits::WithStaticFiles;
use JSORB::Client::Compiler::Javascript;

use Forest;
use Forest::Tree;
use Forest::Tree::Loader::SimpleUIDLoader;
use Forest::Tree::Indexer::SimpleUIDIndexer;

my $index;
{
    my $data = [
        { node => '1.0',   uid => 1,  parent_uid => 0 },
        { node => '1.1',   uid => 2,  parent_uid => 1 },
        { node => '1.2',   uid => 3,  parent_uid => 1 },
        { node => '1.2.1', uid => 4,  parent_uid => 3 },
        { node => '2.0',   uid => 5,  parent_uid => 0 },
        { node => '2.1',   uid => 6,  parent_uid => 5 },
        { node => '3.0',   uid => 7,  parent_uid => 0 },
        { node => '4.0',   uid => 8,  parent_uid => 0 },
        { node => '4.1',   uid => 9,  parent_uid => 8 },
        { node => '4.1.1', uid => 10, parent_uid => 9 },
        { node => '4.1.2', uid => 11, parent_uid => 9 },
    ];
    my $loader = Forest::Tree::Loader::SimpleUIDLoader->new;
    $loader->load($data);
    $index = Forest::Tree::Indexer::SimpleUIDIndexer->new(tree => $loader->tree);
    $index->build_index;
}

sub decompose_tree {
    my ($tree) = @_;
    (blessed $tree && $tree->isa('Forest::Tree'))
        || Carp::croak "You must pass in a tree, not $tree";
    return +{
        uid      => $tree->uid,
        parent   => ($tree->is_root ? undef : $tree->parent->uid),
        node     => $tree->node,
        children => [
            map {
                +{
                    uid  => $_->uid,
                    node => $_->node,
                }
            } @{ $tree->children }
        ]
    };
}

sub get_tree_at {
    my ($uid) = @_;
    decompose_tree($index->get_tree_at($uid));
}

my $ns = JSORB::Namespace->new(
    name     => 'Forest',
    elements => [
        JSORB::Interface->new(
            name       => 'Tree',
            procedures => [
                JSORB::Procedure->new(
                    name  => 'get_root_tree',
                    body  => sub { decompose_tree($index->get_root) },
                    spec  => [ 'Unit' => 'HashRef' ]
                ),
                JSORB::Procedure->new(
                    name  => 'get_tree_at',
                    body  => \&get_tree_at,
                    spec  => [ 'Int' => 'HashRef' ],
                ),
            ]
        )
    ]
);

JSORB::Client::Compiler::Javascript->new->compile(
    namespace => $ns,
    to        => [ $FindBin::Bin, 'ForestTree.js' ]
);

JSORB::Server::Simple->new_with_traits(
    traits     => [
        'JSORB::Server::Traits::WithDebug',
        'JSORB::Server::Traits::WithStaticFiles',
    ],
    doc_root   => [ $FindBin::Bin, '..', '..' ],
    dispatcher => JSORB::Dispatcher::Path->new(
        namespace => $ns,
    )
)->run;

1;
