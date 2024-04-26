#! perl

use strict;
use warnings;

use Test::More 0.89;
use lib 't/lib';
use Test::LivesOK 'lives_ok';

use ExtUtils::Builder::Node;
use ExtUtils::Builder::Action::Code;

our @triggered;
my @actions = map { ExtUtils::Builder::Action::Code->new(code => "push \@::triggered, $_") } 1, 2;
my $node;
lives_ok { $node = ExtUtils::Builder::Node->new(target => 'foo', dependencies => [ qw/bar baz/ ], actions => \@actions) } 'Can create new object';

lives_ok { $node->execute } 'Can execute quiet command';
is_deeply(\@triggered, [ 1, 2 ], 'Both actions ran');
is_deeply([ $node->flatten ], \@actions, '$node->actions contains all expected actions');
lives_ok { $node->to_command } '$node->to_command doesn\'t give any error';
is($node->preference, 'flatten', 'Preferred action is "flatten"');

done_testing;
