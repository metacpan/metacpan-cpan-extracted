package Frozen;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Frozen', $VERSION);

1;

__END__

=encoding utf8

=head1 NAME

Frozen - an immutable container that survives a fork

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Frozen;

    # once, at deploy time
    Frozen->freeze_to('catalogue.frz', $nested_data, flat => '.');

    # in the parent, before the fork
    my $fz = Frozen->open('catalogue.frz');

    # in every worker, without unsharing a page
    my ($greeting) = $fz->get('messages.welcome');

=head1 DESCRIPTION

Perl's preload-then-fork idiom does not do what it appears to. Data loaded
before a fork is shared with every worker by copy-on-write, but the first
B<read> of an SV writes to its reference count, the page is copied, and the
sharing is gone.

Measured on Linux, four workers reading 20,000 random keys out of a preloaded
nested hash: B<47 MiB> of previously shared pages became private. An C<exists>
check that never fetches a value still dirtied 18 MiB, because the cost is
walking the structure rather than copying the string at the end of it.

CPython hit the same wall and answered it in 3.7 with C<gc.freeze()>. Perl has
no answer. Frozen is one: an immutable, position-independent block of bytes
holding nested data, addressed by offset, read without touching a reference
count.

=head2 What it saves

  perl hash  ~ 13877790 bytes  (payload 2677790 + 200000 SV heads at 56, bucket array ignored)
  Frozen        6420016 bytes  (2.16x smaller)
  
=head2 Speed

Frozen's lookup is B<flat> where a Perl hash B<degrades>. Per hit, net of the
measuring loop, on one machine:

    keys        perl hash      Frozen
        500       22.0 ns     23.9 ns
     10,000       30.0 ns     26.3 ns
     50,000       37.5 ns     26.4 ns
    200,000       40.3 ns     29.2 ns

For a three-level catalogue, which is the shape that motivates the dist:

    perl nested traversal     95.1 ns    10,516,435/s
    $fz->get('a.b.c')         63.6 ns    15,721,519/s


=head1 THE TWO DOORS

=head2 The fast door

    my $root = $fz->root;
    my ($v)  = $fz->fetch($root, 'key');   # () when absent, one value when not
    my $h    = $fz->child($root, 'branch');
    my ($v)  = $fz->get('a.b.c');          # a whole path, in one call

C<fetch>, C<get> and C<at> return an B<empty list> for an absent key and one
value for a present one. Not C<undef>: C<undef> is a legitimate stored value,
and a door that used it to mean absent could not tell the two apart. Use
C<exists> to ask the other question.

C<get> is the door to put on a request path. Reaching the same leaf by
descending - C<child>, C<child>, C<fetch> - costs 170.8 ns against C<get>'s
63.6 ns, because each segment is another call.

=head2 The tied door

    my $h = $fz->tied;                     # a plain hashref
    print $h->{items}{one};

Ergonomic, and B<11.6 times slower> than the fast door at three segments:

    $fz->get('a.b.c')      63.6 ns
    $h->{a}{b}{c}         757.5 ns

A single tied C<FETCH> is 263.5 ns, four times an XSUB call, because C<tie>
magic is a full method dispatch rather than a call. Use the tied view for
templates. Use C<get> on a request path.

=head1 STRINGS ARE COPIED

Every string comes back as a copy. This is not an efficiency compromise: a
borrowed SV cannot be delivered to Perl at all, because C<< my $s =
$fz->get(...) >> B<assigns>, and assignment copies - the caller would receive
a copy of the borrowed SV rather than the borrowed SV.

The copy costs a C<memcpy> and buys the guarantee that no pointer can outlive
the mapping it points into. The arena is still never written, so pages stay
clean and shared either way.

A C consumer through C<fz_abi.h> pays no such copy: it gets a pointer into the
block, because C has no assignment that copies a string behind your back.

=head1 DEPLOYING A BLOCK

B<Write and rename. Never rewrite in place.> A file truncated or rewritten
under a live mapping faults with C<SIGBUS> on the next access, and there is no
way to catch that from inside the process. C<freeze_to> writes to a temporary
and renames, which is atomic; a reader holds either the whole old file or the
whole new one.

For a file you cannot promise is immutable, C<< Frozen->open($path, copy => 1)
>> reads it instead of mapping it. It reports C<< $fz->is_mapped == 0 >>, and
the sharing claim does not apply to it.

=head1 WHAT IS REFUSED

At freeze: blessed references, code references, globs, filehandles, references
to scalars, cycles, structures deeper than 256, strings flagged UTF-8 whose
bytes are not valid UTF-8, NVs that do not fit a double (pass C<< lossy_nv =>
1 >> to narrow them), and anything over 2 GiB. Each names the path to the
offending value.

At open: a block that is not Frozen's, one written on the other endianness -
refused, never byteswapped - one whose format version this build does not
read, one using the reserved 64-bit offsets, and one whose recorded size
disagrees with its length.

=head1 CORRUPT INPUT

A Frozen block is a build artifact you ship, not a stranger's upload. The bar
is still B<never segfault>, because the realistic failure is a deploy that
half-wrote a file.

Structural validation - bounds, alignment, tag, and counts against the bytes
that remain - is always on. C<< $fz->verify >> is the opt-in O(n) pass:
checksum plus a walk of every reachable node. It is not done at open unless
you ask, because a checksum over fifty megabytes at every boot is exactly the
pass Frozen exists to remove.

Tested by truncating a block at every one of its 3,080 lengths and by 18,000
single-bit flips across six seeds, each in a child process so a crash is an
exit status rather than a dead test run. Clean under ASAN on Linux.

=head1 BUILDING A BLOCK

Both builders take the same two options. C<< flat => '.' >> builds an index
over joined paths, which is what makes C<get> one probe instead of one per
segment. C<< lossy_nv => 1 >> accepts an NV that does not fit a double,
narrowing it instead of refusing it.

Neither is exported. L<Storable> exports C<freeze> and C<thaw>, and a program
importing both modules would get the wrong function.

=head2 freeze

    my $bytes = Frozen->freeze($data, %opts);

Builds a block in memory and returns it as a string of bytes. Croaks, naming
the path to the offending value, for anything the format cannot hold - see
L</WHAT IS REFUSED>.

    my $bytes = Frozen->freeze(
        { messages => { welcome => 'Hello', bye => 'Goodbye' } },
        flat => '.',
    );

    open my $fh, '>:raw', 'catalogue.frz' or die $!;
    print $fh $bytes;

=head2 freeze_to

    Frozen->freeze_to($path, $data, %opts);

The same build, written straight to a file. Writes to a temporary beside
C<$path> and renames, so a reader holds either the whole old file or the whole
new one - never a half-written block under a live mapping. This is the
supported way to deploy; see L</DEPLOYING A BLOCK>.

    Frozen->freeze_to('catalogue.frz', {
        messages => { welcome => 'Hello' },
        limits   => { rate => 100, burst => 20 },
    }, flat => '.');

=head1 OPENING A BLOCK

=head2 open

    my $fz = Frozen->open($path, %opts);

Maps the file and validates its header. Returns C<undef> with C<$!> set when
the file does not exist; croaks when the file exists but is not a block this
build can read.

C<< copy => 1 >> reads the file instead of mapping it, for a file you cannot
promise is immutable. It reports C<< $fz->is_mapped == 0 >>, and the page
sharing claim does not apply to it.

    my $fz = Frozen->open('catalogue.frz')
        or die "catalogue.frz: $!";

    my $vol = Frozen->open('/mnt/volatile/catalogue.frz', copy => 1);

=head2 attach

    my $fz = Frozen->attach($bytes);

Opens a block already in memory, as returned by L</freeze>. Croaks if the
bytes are not a readable block.

The bytes are B<copied>. Holding a reference to the caller's scalar is not
enough: C<undef $bytes> leaves the SV alive but frees its string buffer, and a
reference counts the SV rather than the PV inside it.

    my $fz = Frozen->attach(Frozen->freeze($data, flat => '.'));

    my ($v) = $fz->get('messages.welcome');

=head2 close

    $fz->close;

Unmaps the block and releases the file. Idempotent; any read after it croaks
rather than touching a dead mapping. Closing is not required, since C<DESTROY>
does it, but it is the way to release the mapping at a chosen moment.

    $fz->close;
    $fz->close;                      # fine, does nothing
    eval { $fz->root };              # croaks: this container is closed

=head2 size

    my $bytes = $fz->size;

The length of the block in bytes.

    printf "catalogue is %.1f KiB\n", $fz->size / 1024;

=head2 is_mapped

    my $bool = $fz->is_mapped;

True when the block is a real C<mmap>, false when it was read into memory -
C<< copy => 1 >>, or L</attach>. Only a mapped block makes the page sharing
claim.

    warn "not mapped, pages will not be shared\n" unless $fz->is_mapped;

=head2 is_open

    my $bool = $fz->is_open;

False once L</close> has run. Cheap enough to guard a long-lived handle with.

    $fz = Frozen->open($path) unless $fz && $fz->is_open;

=head2 verify

    $fz->verify;

The opt-in O(n) pass: the stored checksum against the bytes, then a walk of
every reachable node. Croaks describing the first disagreement it finds.

Structural validation - bounds, alignment, tag and counts - is always on and
costs nothing at open. C<verify> is not run at open unless you ask, because a
checksum over fifty megabytes at every boot is exactly the pass Frozen exists
to remove.

    my $fz = Frozen->open('catalogue.frz') or die $!;
    eval { $fz->verify; 1 } or die "catalogue.frz is damaged: $@";

=head1 READING A BLOCK

A B<handle> is an integer, stable for the life of the block and identical in
every process that maps it - so it can go in a shared cache or a PSGI env and
mean the same thing after a fork. Every entry validates one. What that cannot
catch: a valid handle from a B<different> container reads wrong data rather
than failing. Hold a handle with the container it came from.

=head2 root

    my $h = $fz->root;

The handle of the block's outermost node, and the starting point for every
descent.

    my $root = $fz->root;
    printf "root is a %s of %d\n", $fz->kind($root), $fz->count($root);

=head2 kind

    my $kind = $fz->kind($h);

What a handle points at: C<'hash'>, C<'array'>, C<'string'>, C<'int'>,
C<'num'>, C<'bool'>, C<'undef'>, or C<'unknown'>.

    my $h = $fz->child($fz->root, 'limits');

    if ($fz->kind($h) eq 'hash') {
        say for $fz->keys($h);
    }

=head2 count

    my $n = $fz->count($h);

The number of pairs in a hash node or elements in an array node. Zero for a
leaf.

    my $items = $fz->child($fz->root, 'items');

    for my $i (0 .. $fz->count($items) - 1) {
        my ($v) = $fz->at($items, $i);
        say $v;
    }

=head2 keys

    my @keys = $fz->keys($h);

The keys of a hash node, as strings, with their UTF-8-ness restored. An empty
list for anything that is not a hash.

The order is B<stable>, not sorted and not insertion order. A node with a
perfect hash comes back in hash order; a small one comes back sorted. Both are
identical in every process, which is what lets two workers agree.

    for my $k ($fz->keys($fz->root)) {
        my ($v) = $fz->fetch($fz->root, $k);
        say "$k = $v";
    }

=head2 fetch

    my ($v) = $fz->fetch($h, $key);

The B<value> under a key, as a Perl scalar. Returns an B<empty list> when the
key is absent and one value when it is present - not C<undef>, because
C<undef> is a legitimate stored value and a door that used it to mean absent
could not tell the two apart. Use L</exists> to ask the other question.

    my ($limit) = $fz->fetch($fz->child($fz->root, 'limits'), 'rate');

    $limit = 60 unless defined $limit;

=head2 child

    my $h = $fz->child($h, $key);

The B<handle> under a key, rather than its value, so a descent can continue
from it. Returns C<undef> when the key is absent.

    my $h = $fz->root;
    $h = $fz->child($h, $_) or last for qw(messages errors);

    my ($msg) = $fz->fetch($h, 'not_found');

=head2 exists

    my $bool = $fz->exists($h, $key);

Whether a key is present, without building an SV for its value. The question
to ask when the value may legitimately be C<undef>.

    my ($v) = $fz->fetch($h, 'timeout');

    if ($fz->exists($h, 'timeout') && !defined $v) {
        say "timeout is present and explicitly undef";
    }

=head2 probe

    my $what = $fz->probe($h, $key);

All three answers from a single lookup: C<'leaf'>, C<'branch'> or C<'absent'>.
Cheaper than an L</exists> followed by a L</kind>, which probes twice.

    my $what = $fz->probe($h, $key);

    if    ($what eq 'branch') { $h = $fz->child($h, $key) }
    elsif ($what eq 'leaf')   { ($v) = $fz->fetch($h, $key) }
    else                      { die "no such key: $key" }

=head2 at

    my ($v) = $fz->at($h, $i);

The value at an array index, as a Perl scalar. Like L</fetch>, an B<empty
list> when the index is out of range and one value when it is not.

    my $items = $fz->child($fz->root, 'items');

    my ($first) = $fz->at($items, 0);
    my ($last)  = $fz->at($items, $fz->count($items) - 1);

=head2 value

    my $v = $fz->value($h);

The value a leaf handle points at, as a Perl scalar. This is the second half
of the handle path: resolve a handle once, keep the integer, then read through
it as often as you like without paying for the lookup again.

    my $h = $fz->path($fz->root, 'messages.welcome');   # once

    for (1 .. 1000) {
        my $greeting = $fz->value($h);                  # no lookup
    }

=head2 get

    my ($v) = $fz->get($path);

A whole dotted path from the root, resolved to a B<value>, in one call. This
is the door to put on a request path: it is one probe against the flat index
where the block has one, rather than one probe per segment.

Returns an B<empty list> when the path does not resolve.

    my ($greeting) = $fz->get('messages.welcome');

    my ($rate) = $fz->get('limits.rate');
    $rate = 100 unless defined $rate;

=head2 path

    my ($h) = $fz->path($h, $path, $sep);

The same walk as L</get>, but starting from any handle, returning a B<handle>
rather than a value, and taking an optional separator - useful when the keys
themselves contain dots. Returns an empty list when the path does not resolve.

    my ($h) = $fz->path($fz->root, 'messages/errors/404', '/');

    my $v = $fz->value($h);

=head2 find

    my $h = $fz->find($key);

One key against the root hash, returning its handle, with no path splitting at
all. The narrowest door in the dist: no separator scan, no descent. Returns
C<undef> when the key is absent, and croaks if the root is not a hash.

    my $h = $fz->find('messages') or die "no messages node";

    say $fz->count($h), " messages";

=head2 string_at

    my $str = $fz->string_at($h);

The string at a handle already known to be a string, skipping the kind
dispatch L</value> does. Croaks if the handle is not a string. Worth reaching
for only in a loop hot enough to notice; L</value> is the general answer.

    my @keys = $fz->keys($h);

    my @vals = map { $fz->string_at($fz->child($h, $_)) } @keys;

=head2 inflate

    my $data = $fz->inflate($h);

The whole subtree under a handle, as ordinary Perl data structures. This
B<copies everything> and unshares nothing - it is the escape hatch for code
that wants a plain hashref, not a way to read a block. Defaults to the root.

    my $limits = $fz->inflate($fz->child($fz->root, 'limits'));

    say $limits->{rate};             # a plain hashref, fully copied

=head2 each_leaf

    my $n = $fz->each_leaf($cb, $sep);

Calls C<$cb> once per leaf in the block, with the joined path, the leaf's
handle, and the path as an arrayref of segments. Returns the number of leaves
visited. The separator defaults to C<'.'>.

The joined path is B<lossy> where a key contains the separator: C<< {"a.b" =>
$x} >> and C<< {a => {b => $x}} >> join to the same string. The segments are
authoritative, and the tree keeps the two distinct where a flattened
representation cannot.

    my $n = $fz->each_leaf(sub {
        my ($joined, $handle, $segs) = @_;
        printf "%-30s %s\n", $joined, $fz->value($handle);
    });

    say "$n leaves";

=head2 tied

    my $ref = $fz->tied($h);

A tied hashref or arrayref over the node, for code that wants to read the
block with ordinary Perl syntax. Defaults to the root. Nested nodes tie
themselves as you descend into them.

Writing through it croaks. It is also B<11.6 times slower> than L</get> at
three segments - see L</The tied door>. Use it for templates, not on a request
path.

    my $h = $fz->tied;

    say $h->{messages}{welcome};
    say for sort keys %{ $h->{limits} };

    eval { $h->{messages}{welcome} = 'Hi' };   # croaks: read-only

=head1 LIMITATIONS

=over 4

=item * The flat index is capped at 4,096 leaves, because its duplicate-path
check is quadratic. A larger catalogue gets no index and C<get> descends.

=item * The flat index is consulted only for a path from the root, and only
for leaves. A path naming a branch descends.

=item * Booleans return as 0 or 1, not as the reference they went in as: the
block stores a tag, and a tag does not know which spelling it arrived in.

=item * A block is refused across endianness rather than byteswapped.

=item * Blocks over 2 GiB are refused; the 64-bit offset flag is reserved.

=back

=head1 THE C API

C<fz_abi.h> is installed through L<ExtUtils::Depends> and resolved at runtime
through C<Frozen::_abi_ptr>, so a consumer's XS reads a block with no Perl
frame at all. See the header for the table, the ownership rules and the
resolution idiom; it is the normative description.

The byte format is specified in C<include/fz/fz_format.h>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-frozen at rt.cpan.org>, or
through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Frozen>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Frozen

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
