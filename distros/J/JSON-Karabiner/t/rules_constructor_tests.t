#/usr/bin/env perl
use Test::Most;
use JSON::Karabiner;













my $tests = 5; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;

# test that it dies if file not passed
my $obj;
lives_ok { $obj = JSON::Karabiner->new('some_title', 'file.json'); } 'creates object';
lives_ok { $obj->add_rule('some rule'); } 'can create rule';
dies_ok { $obj->add_rule() } 'rules require names';
throws_ok { $obj->add_rule() } qr/No description passed/, 'throws correct error when no name passed';
is_deeply $obj->{_karabiner}, {title => 'some_title', rules => [ { description => 'some rule', manipulators => [] } ]}, 'rule get added to karabiner object';
