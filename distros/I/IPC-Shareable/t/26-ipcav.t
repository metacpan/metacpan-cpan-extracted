use warnings;
use strict;

use Carp;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(unique_glue assert_clean);

# A two-phase pipe handshake replaces the old SIGALRM/sleep handshake, which
# had a lost-wakeup race: a signal delivered in the window after the "unless
# $awake" check but before sleep() blocked the process forever (the CPAN
# smoker SIGKILLed a hung run of this test). Blocking pipe reads cannot miss
# the wakeup. Same idiom as t/19 and t/24.

my $glue = unique_glue('foco');

pipe(my $ready_r, my $ready_w) or die "Cannot create pipe: $!";  # parent -> child
pipe(my $done_r,  my $done_w)  or die "Cannot create pipe: $!";  # child  -> parent

my $pid = fork;
defined $pid or die "Cannot fork: $!";

if ($pid == 0) {
    # child (producer): attach only after the parent has created and emptied
    # the segment, then push 1..10 under the lock
    close $ready_w;
    close $done_r;

    <$ready_r>;
    close $ready_r;

    my @av;

    my $ipch = tie @av, 'IPC::Shareable', $glue, {
        create     => 1,
        exclusive  => 0,
        mode       => 0666,
        size       => 1024 * 512,
        destroy    => 0,
        serializer => 'storable',
    };

    for my $i (1 .. 10) {
        $ipch->shlock;
        push @av, $i;
        $ipch->shunlock;
    }

    print $done_w "done\n";
    close $done_w;

    exit;
}

# parent (consumer)
close $ready_r;
close $done_w;

my @av;

my $ipch = tie @av, 'IPC::Shareable', $glue, {
    create     => 1,
    exclusive  => 0,
    mode       => 0666,
    size       => 1024 * 512,
    destroy    => 'yes',
    serializer => 'storable',
};

@av = ();

print $ready_w "go\n";   # segment now exists and is empty; child may push
close $ready_w;

<$done_r>;               # block until the child has pushed all 10 elements
close $done_r;

my %seen;

$ipch->shlock;
while (@av) {
    my $line = shift @av;
    ++$seen{$line};
}
$ipch->shunlock;

waitpid($pid, 0);

my $count = 0;
for (1 .. 10) {
    is $seen{$_}, 1, "child set elem $count to $_ ok";
    $count++;
}

IPC::Shareable->clean_up_all;

IPC::Shareable::_end;

assert_clean(unique_glue('foco'));

done_testing();
