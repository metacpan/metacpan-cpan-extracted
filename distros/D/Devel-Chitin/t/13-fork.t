use strict;
use warnings;

use Devel::Chitin;
use Test2::IPC;
use Test2::Require::Fork;
use Test2::V0; no warnings 'void';

plan tests => 7;

TestDB->attach();

my $main_pid = $$;
my $parent_notified = 0;
my $child_notified = 0;

my $pid = fork(); # 17
if ($pid) {
    ok($parent_notified, "parent $$ notified before fork() returned");
} elsif (defined $pid) {
    ok($child_notified, "child $$ notified before fork() returned");
} else {
    fail("fork: $!");
}

package
    TestDB;
use base 'Devel::Chitin';
use Test2::V0;

sub notify_fork_parent {
    my($db, $loc, $pid) = @_;

    is($$, $main_pid, 'notify_fork_parent');
    isnt($pid, $main_pid, 'got child pid');
    is($loc->line, 17, 'parent notified on line 17');
    $parent_notified = 1;
}

sub notify_fork_child {
    my($db, $loc) = @_;

    isnt($$, $main_pid, 'notify_fork_child');
    is($loc->line, 17, 'child notified on line 17');
    $child_notified = 1;
}

