use Test::More qw[no_plan];
use strict;
$^W = 1;

use_ok 'File::Pid';
use File::Spec::Functions qw[tmpdir catfile];

is File::Pid->program_name, 'test.t', 'program_name correct';

my $pid = File::Pid->new;

is $pid->pid, $$, 'current process by default';
is $pid->file, catfile(tmpdir,'test.t.pid'), 'pid file correct';

is $pid->write, $$, 'writing file';
is $pid->running, $$, 'we are running';
ok $pid->remove, 'deleted file';

my $child;
my $file = catfile(tmpdir, 'test.t.child.pid');
unlink $file;

if ( $child = fork ) { #parent
    waitpid $child, 0;
    my $cpid = File::Pid->new({file => $file});
    is $cpid->pid, $child, "$$:$child: child pid correct";
    ok !$cpid->running, 'child is not running';
    ok $cpid->remove, 'removed child pid file';
} else { # child
    File::Pid->new({
        file => $file,
        pid  => $$,
    })->write; # hope for the best
}
