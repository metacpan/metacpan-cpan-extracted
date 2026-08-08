#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Hyperman;

# A loop belongs to the process that created it, and so does every descriptor
# in it. A loop inherited across a fork must be freed WITHOUT closing any of
# them.
#
# On kqueue this is not a tidiness point but a correctness one: kqueue
# descriptors do not survive fork(2) - the kernel invalidates the child's copy,
# which frees the number, and the child's own kqueue() is then handed it
# straight back. Freeing the inherited loop used to close that number, shutting
# the queue the child was actually using, and nothing it watched fired again.
#
# The shape below is exactly what a preforking server does: the child builds
# its own loop and lets the inherited one go.

sub fires_in_child {
    my ($backend) = @_;
    my $parent = $backend ? Hyperman::Loop->new($backend) : Hyperman::Loop->new;

    my $pid = open my $rd, '-|';
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        my $child = $backend ? Hyperman::Loop->new($backend)
                             : Hyperman::Loop->new;
        undef $parent;                 # the inherited loop goes here

        pipe(my $r, my $w) or die "pipe: $!";
        syswrite $w, 'x';
        my $f = $child->readable_f($r);
        $child->run_until($f);
        print(($f->is_ready ? "fired" : "silent"), "\n");
        exit 0;
    }
    chomp(my $out = <$rd> // '');
    close $rd;
    return $out;
}

is(fires_in_child('poll'), 'fired',
   "poll: a child's own loop still fires after the inherited one is freed");

# and the platform default, which is the one a real server uses
is(fires_in_child(undef), 'fired',
   'default backend: likewise, and this is the kqueue case on the BSDs');

done_testing();
