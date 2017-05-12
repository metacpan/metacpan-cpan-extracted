#!/usr/bin/perl

use Memcached::Client::Selector;
use Test::More tests => 5;

ok (my $selector = Memcached::Client::Selector->new, 'Create a new instance of the abstract base class');
is (eval {$selector->set_servers}, undef, 'Watch ->set_servers fail');
ok ($@, 'Make sure it did fail');
is (eval {$selector->get_server}, undef, 'Watch ->get_server fail');
ok ($@, 'Make sure it did fail');
