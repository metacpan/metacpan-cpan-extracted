package Legba;

use strict;
use warnings;
our $VERSION = '0.07';
require XSLoader;
XSLoader::load('Legba', $VERSION);
1;

__END__

=encoding UTF-8

=head1 NAME

Legba - global reactive state slots with optional watchers

=head1 SYNOPSIS

    # Define and use slots
    package Config;
    use Legba qw(app_name debug);

    app_name("MyApp");
    debug(1);

    # Access from another package (same underlying storage)
    package Service;
    use Legba qw(app_name);

    print app_name();   # "MyApp"
    app_name("Changed");

    # Watchers (reactive)
    Legba::watch('app_name', sub {
        my ($name, $value) = @_;
        print "app_name changed to: $value\n";
    });

    Legba::unwatch('app_name');   # Remove all watchers

=head1 DESCRIPTION

C<Legba> (named after Papa Legba, the Vodou gatekeeper of crossroads) provides
fast, globally shared named storage slots. Slots are shared across all packages
— importing the same slot name in different packages gives access to the same
underlying value.

Key features:

=over 4

=item * B<Fast> - Custom ops with compile-time optimization

=item * B<Global> - Slots are shared across packages by name

=item * B<Reactive> - Optional watchers fire on value changes

=item * B<Lazy watchers> - No overhead unless you use C<watch()>

=item * B<Access control> - Optional per-slot lock and freeze

=back

=head1 COMPILE-TIME OPTIMIZATION

When you call any C<Legba::*> function with a B<constant string> name for a
slot that B<exists at compile time> (created via C<use Legba qw(...)>), the
call is optimized at compile time to a custom op or constant.

    use Legba qw(counter);            # Creates slot at compile time

    Legba::get('counter');            # Optimized to custom op (185% faster)
    Legba::set('counter', 42);        # Optimized to custom op (283% faster)
    my $idx = Legba::index('counter');# Constant-folded (no runtime code!)
    Legba::watch('counter', \&cb);    # Optimized to custom op
    Legba::unwatch('counter');        # Optimized to custom op
    Legba::clear('counter');          # Optimized to custom op

Variable names are NOT optimized and use the XS fallback:

    my $name = 'counter';
    Legba::get($name);                # XS function call (slower)

=head2 Optimization Requirements

=over 4

=item 1. The slot name must be a B<literal string constant>

=item 2. The slot must B<exist at compile time> (use C<use Legba qw(...)>)

=item 3. Slots created at runtime with C<Legba::add()> cannot be optimized

=back

=head1 FUNCTIONS

=head2 import

    use Legba qw(foo bar baz);

Imports slot accessors into the calling package. Each accessor is both a
getter and setter:

    foo();       # get
    foo(42);     # set and returns value

=head2 Legba::add

    Legba::add('name');
    Legba::add('name1', 'name2', 'name3');

Create slots without importing accessors into the current package.
Faster than C<use Legba qw(...)> when you only need get/set access via the
functional API. Idempotent — adding an existing slot is a no-op.

=head2 Legba::index

    my $idx = Legba::index('name');

Get the numeric index of a slot. Use with C<get_by_idx>/C<set_by_idx>
for maximum performance when you need repeated access.

B<Compile-time optimization:> When called with a constant string, the index
is computed at compile time and the call is replaced with a constant — no
runtime code at all.

=head2 Legba::get

    my $val = Legba::get('name');

Get a slot value by name (without importing an accessor).

B<Compile-time optimization:> When called with a constant string for a slot
that exists at compile time, this is optimized to a custom op and runs as fast
as an accessor. Also available as C<Legba::_get>.

=head2 Legba::set

    Legba::set('name', $value);

Set a slot value by name. Creates the slot if it does not yet exist.
Returns the stored value.

B<Compile-time optimization:> Like C<Legba::get>, optimized at compile time
when called with a constant string. Also available as C<Legba::_set>.

=head2 Legba::get_by_idx

    my $idx = Legba::index('name');
    my $val = Legba::get_by_idx($idx);

Get a slot value by numeric index. Faster than name-based lookup — a single
array dereference with no hash lookup.

B<Best use case:> When the slot name is a runtime variable and you need
repeated access, cache the index once and use C<get_by_idx>.

=head2 Legba::set_by_idx

    Legba::set_by_idx($idx, $value);

Set a slot value by numeric index. Faster than name-based lookup.
Respects lock/freeze and fires watchers. Returns the stored value.

=head2 Legba::watch

    Legba::watch('name', sub { my ($name, $value) = @_; ... });

Register a callback that fires whenever the slot value is set (including
setting to the same value). The callback receives the slot name and new value.

B<Compile-time optimization:> When called with a constant string, optimized
to a custom op.

=head2 Legba::unwatch

    Legba::unwatch('name');             # Remove all watchers
    Legba::unwatch('name', $coderef);   # Remove specific watcher

B<Compile-time optimization:> When called with a constant string, optimized
to a custom op.

=head2 Legba::clear

    Legba::clear('name');
    Legba::clear('name1', 'name2');

Reset slot value(s) to undef and remove all associated watchers. The slot
still exists (can be set again), but its value and watchers are cleared.
Silently skips locked or frozen slots.

B<Compile-time optimization:> When called with a single constant string,
optimized to a custom op.

=head2 Legba::clear_by_idx

    Legba::clear_by_idx($idx);
    Legba::clear_by_idx($idx1, $idx2);

Reset slot value(s) to undef and remove watchers by numeric index.

=head2 Legba::slots

    my @names = Legba::slots();

Returns a list of all defined slot names. Also available as C<Legba::_keys>.

=head2 Legba::exists

    if (Legba::exists('config')) { ... }

Check if a slot with the given name has been defined. Returns true if the
slot exists, false otherwise. Also available as C<Legba::_exists>.

=head1 ACCESS CONTROL

=head2 Legba::_lock

    Legba::_lock('name');

Reversibly prevents the slot from being set. Reads still work.
Croaks if the slot does not exist or is frozen.

=head2 Legba::_unlock

    Legba::_unlock('name');

Removes a lock placed by C<_lock>. Croaks if the slot is frozen.

=head2 Legba::_freeze

    Legba::_freeze('name');

Permanently prevents the slot from being set. Cannot be reversed.
Frozen slots cannot be locked or unlocked.

=head2 Legba::_is_locked

    if (Legba::_is_locked('name')) { ... }

Returns true if the slot is currently locked.

=head2 Legba::_is_frozen

    if (Legba::_is_frozen('name')) { ... }

Returns true if the slot is frozen.

=head1 ADVANCED API

=head2 Legba::_delete

    Legba::_delete('name');

Clears the slot value to undef without removing the slot from the index.
Respects lock and freeze — croaks if the slot is locked or frozen.

=head2 Legba::_clear

    Legba::_clear();

Clears all slot values to undef (skips locked and frozen slots). Preserves
the slot index and any active watchers.

=head2 Legba::_install_accessor

    Legba::_install_accessor($pkg, $slot_name);

Manually install an accessor function for C<$slot_name> into package C<$pkg>.
Creates the slot if it does not already exist.

=head2 Legba::_slot_ptr

    my $ptr = Legba::_slot_ptr('name');

Returns the raw C<SV*> pointer (as a UV) for the slot's dedicated SV. The
pointer is stable across value changes and registry resizes — useful for
embedding in custom C ops.

=head2 Legba::_registry

    my $hashref = Legba::_registry();

Returns a reference to the internal C<slot_name => index> hash. Intended for
introspection and debugging.

=head2 Legba::_make_get_op

    my $op_ptr = Legba::_make_get_op('name');

Allocates a getter C<OP*> for the named slot and returns its address as a UV.
Useful for injecting into an optree from another XS module.

=head2 Legba::_make_set_op

    my $op_ptr = Legba::_make_set_op('name');

Allocates a setter C<OP*> for the named slot and returns its address as a UV.

=head1 THREAD SAFETY

For thread-safe data sharing, store C<threads::shared> variables in slots:

    use threads;
    use threads::shared;
    use Legba qw(config);

    my %shared :shared;
    $shared{counter} = 0;
    config(\%shared);

    my @threads = map {
        threads->create(sub {
            my $cfg = config();
            lock(%$cfg);
            $cfg->{counter}++;
        });
    } 1..10;

    $_->join for @threads;
    print config()->{counter};   # 10

The slot provides the global accessor; C<threads::shared> provides the
thread-safe storage.

=head1 FORK BEHAVIOR

After C<fork()>, child processes get a copy of slot values (copy-on-write).
Changes in child processes do not affect the parent, and vice versa.

=head1 BENCHMARKS

    use Benchmark qw(timethese cmpthese);
    use Legba qw(bench_slot);

    my $r = timethese(1_000_000, {
        accessor_get => sub { bench_slot()         },
        accessor_set => sub { bench_slot(42)       },
        get_const    => sub { Legba::get('bench_slot') },
        set_const    => sub { Legba::set('bench_slot', 42) },
    });
    cmpthese($r);

Typical results (threaded perl, Apple Silicon):

    Accessor getter:  ~55M ops/sec
    Accessor setter: ~142M ops/sec
    get constant:    ~55M ops/sec  (custom op — same as accessor)
    set constant:   ~142M ops/sec  (custom op — same as accessor)

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
