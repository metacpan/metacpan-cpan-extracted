#!perl
# Refcount lifecycle: an Entry holds a back-ref to its Reader; if the
# user stashes an Entry past Reader scope, the C handle should stay
# alive for accessor calls (which only look at the cached meta AV)
# but slurp on a Reader that the user explicitly closed should fail
# cleanly rather than crash.
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/stash.tar";

my $w = File::Raw::Archive->create($tar);
$w->add(name => 'one.txt', content => 'first content');
$w->add(name => 'two.txt', content => 'second content');
$w->close;

# Case 1: stash an entry past Reader scope. The Reader stays alive
# because the entry holds a ref to it. Accessors keep working;
# slurp also works because the C handle is still allocated.
{
    my $stashed;
    {
        my $r = File::Raw::Archive->open($tar);
        $stashed = $r->next;       # entry holds ref to $r
        $stashed->slurp;            # cache the bytes inside the entry
        # $r goes out of scope here. Refcount drops by 1, but
        # $stashed's back-link keeps the C handle alive.
    }
    is($stashed->name, 'one.txt',
        'stashed entry: name accessor still works after Reader out of scope');
    is($stashed->size, length('first content'),
        'stashed entry: size accessor still works');
    is($stashed->slurp, 'first content',
        'stashed slurp returns memoised bytes');
    # Let $stashed go out of scope: chain unwinds, C handle freed.
}
ok(1, 'stashed-past-scope teardown completed without panic');

# Case 2: explicit close() on the Reader. The handle's C struct is
# freed immediately. A stashed entry's accessors still work (they
# read cached meta) but slurp() should croak gracefully if the bytes
# weren't memoised.
{
    my $r = File::Raw::Archive->open($tar);
    my $e = $r->next;
    is($e->name, 'one.txt', 'pre-close: accessor works');
    $r->close;
    is($e->name, 'one.txt', 'post-close: cached metadata still accessible');

    # slurp without prior memoisation should croak rather than segfault.
    my $err;
    eval { $e->slurp; 1 } or $err = $@;
    ok(defined $err, 'post-close slurp croaks (or returns empty)')
        or diag "got: " . ($e->slurp // 'undef');
}

# Case 3: Reader DESTROY runs cleanly when implicitly torn down with
# stashed entries kept around in an outer scope.
{
    my @stashed;
    my $r = File::Raw::Archive->open($tar);
    while (my $e = $r->next) {
        $e->slurp;       # memoise so post-close accessors work
        push @stashed, $e;
    }
    undef $r;            # drop direct reference
    # Entries still hold the back-link, so the handle is alive.
    is($stashed[0]->name, 'one.txt', 'first entry name post-undef');
    is($stashed[1]->slurp, 'second content', 'second entry slurp memoised');
    # Let @stashed go out of scope: full chain teardown.
}
ok(1, 'implicit Reader teardown via stashed-entries chain');

done_testing;
