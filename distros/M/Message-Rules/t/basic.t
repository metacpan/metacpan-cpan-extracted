#!env perl

use strict;use warnings;

use lib '../lib';
use Test::More;

use_ok('Message::Rules');

ok my $r = Message::Rules->new();

ok $r->load_rules_from_directory('t/conf');
ok my $m = $r->merge_rules({main => 'thing'});
ok $m->{this} eq 'that';

ok 1;

done_testing();
