#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempfile);
use POSIX ();
use Scalar::Util qw(reftype);
use Test::More;

use lib 'lib';

use Developer::Dashboard::GoRoutine;

# -------------------------------------------------------------------------
# Shared scalars are plain values
# -------------------------------------------------------------------------
#
# Under the single-threaded event loop, share is a no-op: the variable IS
# the one process-wide value, visible to the main program and every
# routine, with no proxy, no marshalling, and no tied shape. These tests
# assert the observable values and the plain-value shape.

share my $counter = 4;
ok( !defined tied($counter), 'share leaves a plain scalar untied' );
is( 0 + $counter, 4, 'shared scalar reads its value' );
$counter += 3;
is( 0 + $counter, 7, 'shared scalar compound addition is applied' );
$counter = 20 - $counter;
is( 0 + $counter, 13, 'shared scalar applies reverse arithmetic when assigned' );
$counter = 9;
is( 0 + $counter, 9, 'shared scalar accepts a plain scalar assignment' );
my $counter_copy = $counter;
is( 0 + $counter_copy, 9, 'copied shared scalar converts to a number' );
is( "$counter_copy", '9', 'copied shared scalar converts to a string' );
ok( !!$counter_copy, 'non-zero shared scalar copy is true' );

my $operation = $counter_copy + 2;
is( 0 + $operation, 11, 'shared scalar copy can be evaluated in arithmetic' );
is( 0 + ( 20 - $counter_copy ), 11, 'reverse arithmetic evaluates with the right operand first' );
is( 0 + ( $counter_copy * 3 ), 27, 'shared scalar copy supports multiplication' );
is( 0 + ( $counter_copy / 3 ), 3, 'shared scalar copy supports division' );
is( 0 + ( 20 / $counter_copy ), 20 / 9, 'shared scalar copy supports reverse division' );
is( 0 + ( $counter_copy % 4 ), 1, 'shared scalar copy supports modulo' );
is( 0 + ( 20 + $counter_copy ), 29, 'shared scalar copy supports reverse addition' );
is( 0 + ( 20 - $counter_copy ), 11, 'shared scalar copy supports reverse subtraction' );
is( 0 + ( 3 * $counter_copy ), 27, 'shared scalar copy supports reverse multiplication' );
is( 0 + ( 27 / $counter_copy ), 3, 'shared scalar copy supports reverse division' );
is( 0 + ( 18 % $counter_copy ), 0, 'shared scalar copy supports reverse modulo' );
is( "prefix-" . $counter_copy, 'prefix-9', 'shared scalar copy supports reverse concatenation' );
is( int($counter_copy), 9, 'shared scalar copy converts directly to an integer' );
my $concatenated = $counter_copy . '!';
is( "$concatenated", '9!', 'shared scalar copy can be evaluated as a concatenation' );
ok( !!($counter_copy + 1), 'non-zero shared scalar arithmetic is true in boolean context' );
ok( !($counter_copy - 9), 'zero-valued shared scalar arithmetic is false in boolean context' );
my $already_applied = ++$counter;
is( 0 + $counter, 10, 'pre-increment applies to the shared scalar' );
my $map;
share $map = {};
$map->{incremented} = $already_applied;
is( 0 + $map->{incremented}, 10, 'storing an incremented value does not apply it twice' );
$counter = ++$counter;
is( 0 + $counter, 11,
    'assigning a pre-incremented value back to its source keeps the value' );
$counter = 10;
--$counter;
is( 0 + $counter, 9, 'pre-decrement applies to the shared scalar' );

# -------------------------------------------------------------------------
# Share declaration forms
# -------------------------------------------------------------------------

share my ($group_left, $group_right) = (5, 6);
is( 0 + $group_left, 5, 'grouped share declaration initializes its first scalar' );
is( 0 + $group_right, 6, 'grouped share declaration initializes its second scalar' );
share my @declared_array = qw(red green);
is_deeply( [@declared_array], [qw(red green)],
    'aggregate share declaration preserves its array initializer' );
share my %declared_hash = (enabled => 1);
is( 0 + $declared_hash{enabled}, 1,
    'aggregate share declaration preserves its hash initializer' );

my $existing_scalar = 7;
my @existing_array = qw(one two);
my %existing_hash = (ready => 1);
share $existing_scalar, @existing_array, %existing_hash;
is( 0 + $existing_scalar, 7, 'existing-variable share preserves scalar data' );
is_deeply( [@existing_array], [qw(one two)],
    'existing-variable share preserves array data' );
is( 0 + $existing_hash{ready}, 1,
    'existing-variable share preserves hash data' );

# Assigning one shared scalar to another is a plain copy: the source keeps
# its value and the destination takes a copy of it.
my $other;
share $other = 2;
$counter = $other;
is( 0 + $counter, 2, 'assigning one shared scalar to another copies its value' );
is( 0 + $other, 2, 'copying a shared scalar leaves the source unchanged' );
$counter = 9;

# -------------------------------------------------------------------------
# Shared hashes: plain values, normal Perl operations
# -------------------------------------------------------------------------

my $state;
share $state = {
    hash  => { first => 'one', second => 'two' },
    array => [ 'zero', 'one' ],
};
ok( !defined tied(%$state), 'share leaves a plain hash untied' );
my $hash = $state->{hash};
is( $hash->{first}, 'one', 'shared hash fetch returns its scalar child' );
$hash->{third} = 'three';
is( $hash->{third}, 'three', 'shared hash store writes a scalar child' );
ok( exists $hash->{second}, 'shared hash exists checks a present key' );
ok( !exists $hash->{absent}, 'shared hash exists checks an absent key' );
$counter = 9;
$counter_copy = $counter;
$hash->{computed} = $counter_copy * 2;
is( 0 + $hash->{computed}, 18, 'shared hash store keeps a computed scalar value' );
is( 0 + $counter_copy, 9, 'storing a computed value leaves the source unchanged' );
$hash->{reverse_computed} = 20 - $counter_copy;
is( 0 + $hash->{reverse_computed}, 11, 'shared hash store keeps a reverse computed value' );
is( 0 + $counter_copy, 9, 'storing a reverse computed value leaves the source unchanged' );
$hash->{pending_value} = $counter;
is( 0 + $hash->{pending_value}, 9, 'shared hash store keeps a plain scalar copy' );
$hash->{incremented_value} = ++$counter_copy;
is( 0 + $counter_copy, 10, 'pre-incremented copy stored in a hash keeps its value' );
is( 0 + $hash->{incremented_value}, 10, 'shared hash store keeps a pre-incremented value' );
is( 0 + $counter, 9, 'incrementing a copy leaves the shared scalar unchanged' );
$counter = 9;
my $concat_source = $counter;
$hash->{concatenated} = $concat_source . '-tail';
is( $hash->{concatenated}, '9-tail', 'shared hash store keeps a concatenated value' );
is( 0 + $counter, 9, 'concatenation leaves the shared scalar unchanged' );
$hash->{unicode} = "caf\x{e9}";
is( $hash->{unicode}, "caf\x{e9}", 'shared hash store preserves a UTF-8 scalar' );
$counter = "caf\x{e9}";
is( $counter, "caf\x{e9}", 'shared scalar assignment preserves a UTF-8 scalar' );
$counter = 9;
my $upgraded_unicode = join q{}, 'caf', chr(0xE9);
utf8::upgrade($upgraded_unicode);
ok( utf8::is_utf8($upgraded_unicode), 'UTF-8 fixture is explicitly upgraded' );
$counter = $upgraded_unicode;
is( $counter, $upgraded_unicode,
    'shared scalar assignment preserves an explicitly upgraded UTF-8 value' );
my $counter_after_unicode = $counter;
$counter = $counter_after_unicode;
is( $counter, $counter_after_unicode,
    'shared scalar accepts a copied upgraded UTF-8 scalar' );
$counter = 9;
$hash->{nested_array} = $state->{array};
is( $hash->{nested_array}[0], 'zero',
    'shared hash store preserves an array reference' );
is( scalar keys %{$hash}, 10, 'shared hash key count reflects its stored keys' );
my @keys = sort keys %{$hash};
is_deeply( \@keys,
    [qw(computed concatenated first incremented_value nested_array pending_value reverse_computed second third unicode)],
    'shared hash iterates a stable key snapshot' );
is( delete $hash->{second}, 'two', 'shared hash delete returns the removed scalar' );
ok( !exists $hash->{second}, 'deleted shared hash key is absent' );
%{$hash} = ();
is( scalar keys %{$hash}, 0, 'shared hash clear removes its keys' );

# -------------------------------------------------------------------------
# Shared arrays: plain values, normal Perl operations
# -------------------------------------------------------------------------

my $array = $state->{array};
ok( !defined tied(@$array), 'share leaves a plain array untied' );
is( scalar @{$array}, 2, 'shared array length reports its size' );
is( $array->[0], 'zero', 'shared array fetch reads a non-negative index' );
is( $array->[-1], 'one', 'shared array fetch resolves a negative index' );
$array->[1] = 'updated';
is( $array->[1], 'updated', 'shared array store writes an indexed value' );
ok( exists $array->[0], 'shared array exists checks a present index' );
ok( !exists $array->[8], 'shared array exists checks an absent index' );
ok( exists $array->[-1], 'shared array exists resolves a negative index' );
$array->[-1] = 'negative-store';
is( $array->[-1], 'negative-store', 'shared array store resolves a negative index' );
$array->[-1] = 'negative-direct-store';
is( $array->[-1], 'negative-direct-store',
    'negative-index assignment updates the last element' );
ok( exists $array->[-1], 'negative-index exists checks the last element' );
is( delete $array->[-1], 'negative-direct-store',
    'negative-index delete returns the last element' );
is( scalar @{$array}, 1, 'delete of the last element shrinks the array' );
$counter = 9;
my $array_source = $counter;
$array->[0] = $array_source + 1;
is( 0 + $array->[0], 10, 'shared array store keeps a computed value' );
is( 0 + $counter, 9, 'storing a computed value leaves the shared scalar unchanged' );
$array->[0] = 30 - $array_source;
is( 0 + $array->[0], 21, 'shared array store keeps a reverse computed value' );
is( 0 + $counter, 9, 'storing a reverse computed value leaves the shared scalar unchanged' );
$array->[0] = $counter;
is( 0 + $array->[0], 9, 'shared array store keeps a plain scalar copy' );
$counter = 10;
my $array_size_before_increment = scalar @{$array};
my $increment_source = $counter;
$array->[20] = ++$increment_source;
is( 0 + $increment_source, 11, 'pre-incremented copy stored in an array keeps its value' );
is( 0 + $array->[20], 11, 'storing a pre-incremented copy stores the incremented value' );
is( scalar @{$array}, $array_size_before_increment + 20,
    'storing at a sparse index grows the shared array' );
is( 0 + $counter, 10, 'incrementing a copy leaves the shared scalar unchanged' );
@{$array} = qw(zero updated one two three four);
$hash->{computed} = 18;
$array->[1] = $hash;
is( $array->[1]{computed}, 18,
    'shared array store preserves a hash reference' );
is( scalar @{$array}, 6, 'array keeps its length after storing a reference' );
$array->[3] = 'sparse';
is( scalar @{$array}, 6, 'indexed store within bounds keeps the length' );
is( delete $array->[3], 'sparse', 'shared array delete returns its removed value' );
push @{$array}, 'tail';
is( pop @{$array}, 'tail', 'shared array pop returns the last value' );
unshift @{$array}, 'head';
is( shift @{$array}, 'head', 'shared array shift returns the first value' );
$hash->{available} = 'now';
unshift @{$array}, $hash;
is( $array->[0]{available}, 'now',
    'shared array unshift preserves a hash reference' );
shift @{$array};
@{$array} = qw(zero updated one two three four);
is_deeply( [ splice @{$array}, 1, 2, 'replacement' ], [ 'updated', 'one' ], 'shared array splice returns removed values' );
is_deeply( [ @{$array} ], [ 'zero', 'replacement', 'two', 'three', 'four' ], 'shared array splice replaces the selected range' );
is( scalar splice( @{$array}, -1 ), 'four', 'scalar splice returns the final removed value' );
is( scalar @{$array}, 4, 'splice without a length removes through the end' );
@{$array} = qw(alpha beta gamma delta);
is_deeply( [ splice @{$array}, -4, 99 ], [qw(alpha beta gamma delta)],
    'splice with a negative offset at the array start removes the whole array' );
@{$array} = qw(alpha beta gamma delta);
my $far_negative_splice = eval { splice @{$array}, -99, 99; 1 };
ok( !$far_negative_splice,
    'a shared array is a plain array, so splice rejects a far-negative offset beyond its start' );
is_deeply( [@{$array}], [qw(alpha beta gamma delta)],
    'failed splice leaves the shared array unchanged' );
@{$array} = qw(alpha beta gamma delta);
my $beyond_end;
{
    # Plain Perl warns on a past-end splice offset but still returns an
    # empty list; the warning is expected behaviour, not a failure.
    no warnings 'misc';
    $beyond_end = [ splice @{$array}, 99, 1 ];
}
is_deeply( $beyond_end, [],
    'splice clamps an offset beyond the array end' );
@{$array} = qw(alpha beta gamma delta);
is_deeply( [ splice @{$array}, 1, -99 ], [],
    'splice clamps a negative length beyond the remaining range to zero' );
@{$array} = qw(alpha beta gamma delta);
is_deeply( [ splice @{$array}, 1, 99 ], [qw(beta gamma delta)],
    'splice clamps an oversized positive length to the remaining range' );
@{$array} = qw(alpha beta gamma delta);
is_deeply( [ splice @{$array} ], [qw(alpha beta gamma delta)],
    'splice without arguments defaults to the full array' );
$#{$array} = 5;
is( scalar @{$array}, 6, 'shared array size assignment grows the array' );
@{$array} = ();
is( scalar @{$array}, 0, 'shared array clear removes all entries' );

# -------------------------------------------------------------------------
# Scalar references and blessed values: plain references, same identity
# -------------------------------------------------------------------------

my $scalar_value = 12;
$state->{scalar_ref} = \$scalar_value;
my $shared_scalar_ref = $state->{scalar_ref};
is( ref($shared_scalar_ref), 'SCALAR', 'shared scalar-reference child remains a scalar reference' );
is( 0 + ${$shared_scalar_ref}, 12, 'shared scalar-reference child reads its value' );
${$shared_scalar_ref} = 13;
is( $scalar_value, 13, 'shared scalar-reference assignment updates the referenced scalar' );
is( 0 + ${$shared_scalar_ref}, 13, 'shared scalar-reference reads its updated value' );
my $blessed_scalar_value = 14;
$state->{blessed_scalar_ref} = bless( \$blessed_scalar_value, 'Local::SharedScalarRef' );
my $blessed_scalar_ref = $state->{blessed_scalar_ref};
is( ref($blessed_scalar_ref), 'Local::SharedScalarRef',
    'shared scalar-reference preserves its blessing' );
is( 0 + ${$blessed_scalar_ref}, 14,
    'blessed shared scalar-reference remains dereferenceable' );
my $other_scalar_value = 14;
my $plain_scalar_ref = \$other_scalar_value;
is( ref($plain_scalar_ref), 'SCALAR',
    'an unblessed scalar reference stays a plain scalar reference' );

my $blessed_hash = bless { value => 5 }, 'Local::SharedHash';
$state->{blessed_hash} = $blessed_hash;
is( ref( $state->{blessed_hash} ), 'Local::SharedHash', 'shared hash preserves its blessing' );
is( 0 + $state->{blessed_hash}{value}, 5, 'blessed shared hash remains dereferenceable' );
my $plain_hash = { value => 5 };
is( ref($plain_hash), 'HASH', 'an unblessed hash stays a plain hash reference' );
my $blessed_array = bless [ 6, 7 ], 'Local::SharedArray';
$state->{blessed_array} = $blessed_array;
is( ref( $state->{blessed_array} ), 'Local::SharedArray', 'shared array preserves its blessing' );
is( 0 + $state->{blessed_array}[1], 7, 'blessed shared array remains dereferenceable' );
my $plain_array = [ 6, 7 ];
is( ref($plain_array), 'ARRAY', 'an unblessed array stays a plain array reference' );

# -------------------------------------------------------------------------
# Regexps and code references: plain Perl values
# -------------------------------------------------------------------------

my $regexp = qr/^native+$/i;
$state->{regexp} = $regexp;
is( ref( $state->{regexp} ), 'Regexp', 'shared regexp stays a Perl regexp' );
ok( 'NATIVEEE' =~ $state->{regexp}, 'shared regexp preserves matching behavior' );
my $blessed_regexp = bless qr/example/, 'Local::SharedRegexp';
$state->{blessed_regexp} = $blessed_regexp;
is( ref( $state->{blessed_regexp} ), 'Local::SharedRegexp',
    'shared regexp preserves a non-default blessing' );
ok( 'an example' =~ $state->{blessed_regexp}, 'blessed shared regexp still matches' );
my $plain_regexp = qr/example/;
is( ref($plain_regexp), 'Regexp', 'an unblessed regexp stays a plain regexp' );

my $shared_code = sub { return "code-$_[0]" };
$state->{code} = $shared_code;
is( $state->{code}->('argument'), 'code-argument',
    'shared code reference runs directly' );

# -------------------------------------------------------------------------
# Filehandles: the same open-file description in every routine
# -------------------------------------------------------------------------

my ($in_fh, $in_path) = tempfile();
print {$in_fh} "first\nsecond\n";
close $in_fh;
open share my $shared_in, '<', $in_path or die "cannot open $in_path: $!";
is( reftype($shared_in), 'GLOB', 'shared filehandle stays a glob' );
ok( defined fileno($shared_in), 'shared filehandle has a real descriptor' );
my $read_line;
share $read_line;
go sub { $read_line = <$shared_in> };
wait_all();
is( $read_line, "first\n", 'a routine reads from a shared filehandle' );
is( scalar <$shared_in>, "second\n", 'the main program continues reading the same handle' );
close $shared_in;

my ($out_fh, $out_path) = tempfile();
close $out_fh;
open share my $shared_out, '>', $out_path or die "cannot open $out_path: $!";
go sub { print {$shared_out} "written\n" };
wait_all();
close $shared_out;
open my $check_fh, '<', $out_path or die "cannot open $out_path: $!";
is( scalar <$check_fh>, "written\n", 'a routine writes to a shared filehandle' );
close $check_fh;

# -------------------------------------------------------------------------
# Formats: plain format references
# -------------------------------------------------------------------------

my $format_ref;
{
    our $coverage_format_value = 'abc';
    format GOROUTINE_COVERAGE_FORMAT =
@<<<<
$coverage_format_value
.
    $format_ref = *GOROUTINE_COVERAGE_FORMAT{FORMAT};
}
ok( defined $format_ref, 'a format reference is defined' );
is( ref($format_ref), 'FORMAT', 'a format reference keeps its type' );
$state->{format} = $format_ref;
is( $state->{format}, $format_ref, 'a shared format reference keeps its identity' );

# -------------------------------------------------------------------------
# Routines see the same shared values
# -------------------------------------------------------------------------

share my $seen = 0;
go sub { $seen = 7 };
wait_all();
is( $seen, 7, 'a routine writes the same shared scalar the main program reads' );
share my @shared_items = ();
go sub { push @shared_items, 'from-routine' };
wait_all();
is_deeply( [@shared_items], ['from-routine'],
    'a routine appends to the same shared array' );

# -------------------------------------------------------------------------
# Channels: same public API, values passed by reference
# -------------------------------------------------------------------------

my $channel = channel(2);
is( $channel->capacity, 2, 'buffered channel reports its capacity' );
is( $channel->size, 0, 'empty buffered channel reports zero size' );
ok( !$channel->is_closed, 'open buffered channel reports its open state' );
is( $channel->send('queued'), $channel,
    'channel send returns the channel for chaining' );
is( $channel->size, 1, 'buffered channel reports a queued value' );
my ( $channel_value, $channel_ok ) = $channel->receive;
is( $channel_value, 'queued', 'buffered channel receives its queued value' );
ok( $channel_ok, 'buffered channel receive reports a successful value' );
$channel->send('scalar-context');
is( scalar $channel->receive, 'scalar-context',
    'buffered channel receive returns the value in scalar context' );
is( $channel->close, $channel, 'channel close returns the channel for chaining' );
ok( $channel->is_closed, 'closed channel reports its closed state' );
my ( $closed_value, $closed_ok ) = $channel->receive;
ok( !defined $closed_value, 'closed channel returns no further value' );
ok( !$closed_ok, 'closed channel receive reports failure' );
my $closed_send = eval { $channel->send('rejected'); 1 };
ok( !$closed_send, 'channel propagates send-after-close errors' );
like( $@, qr/closed/, 'send-after-close failure has an explicit diagnostic' );

my $by_ref_channel = channel(1);
my $sent = { count => 1 };
$by_ref_channel->send($sent);
my $received = $by_ref_channel->receive;
is( $received, $sent, 'channel passes a reference through unchanged' );
$received->{count} = 2;
is( $sent->{count}, 2, 'channel values are passed by reference, not copied' );

my $invalid_channel = bless {}, 'Developer::Dashboard::GoRoutine::Channel';
my $invalid_channel_ok = eval { $invalid_channel->size; 1 };
ok( !$invalid_channel_ok, 'channel rejects a missing native handle' );
like( $@, qr/invalid channel handle/, 'invalid channel diagnostic names the handle' );

# -------------------------------------------------------------------------
# Routine handles: real routines, real states
# -------------------------------------------------------------------------

my $invalid_routine = bless {}, 'Developer::Dashboard::GoRoutine::Routine';
my $invalid_routine_ok = eval { $invalid_routine->is_running; 1 };
ok( !$invalid_routine_ok, 'routine rejects a missing native handle' );
like( $@, qr/invalid go routine handle/, 'invalid routine diagnostic names the handle' );

my $fresh = go(sub { 1 }, { after => 10 });
is( $fresh->status, 'pending', 'a fresh routine reports pending' );
ok( !$fresh->is_running, 'a pending routine is not running' );
ok( !$fresh->is_killed, 'a pending routine is not killed' );
ok( !$fresh->cancel_requested, 'a pending routine has no cancel requested' );
ok( $fresh->age >= 0, 'a fresh routine reports a non-negative age' );
ok( $fresh->kill, 'kill cancels a pending routine at once' );
is( $fresh->status, 'killed', 'killed pending routine reports killed' );
ok( $fresh->is_killed, 'killed routine is marked as killed' );
ok( !$fresh->kill, 'kill on a finished routine returns false' );

my $chained = go sub { 42 };
is( $chained->timeout(0.25), $chained, 'valid timeout returns the routine for chaining' );
wait_all();
is( $chained->status, 'done', 'finished routine reports done' );
ok( !$chained->is_killed, 'done routine is not marked as killed' );

my $slow = go(sub { 1 }, { after => 10 });
$slow->timeout(0.05);
Developer::Dashboard::GoRoutine::pump(0.5);
is( $slow->status, 'timed_out', 'a routine past its timeout reports timed_out' );
ok( $slow->is_killed, 'timed-out routine is marked as killed' );

my $no_timeout = go(sub { 1 }, { after => 0.2 });
$no_timeout->timeout(0.01);
$no_timeout->timeout(0);
Developer::Dashboard::GoRoutine::pump(0.05);
is( $no_timeout->status, 'pending', 'timeout(0) disables a pending timeout' );
wait_all();
is( $no_timeout->status, 'done', 'routine with a disabled timeout still runs' );

my $exiter = go sub { exit };
wait_all();
is( $exiter->status, 'exited', 'exit inside a routine reports exited' );
ok( !$exiter->is_killed, 'exited routine is not marked as killed' );

my $running_seen;
my $self_observed;
$self_observed = go sub { $running_seen = $self_observed->is_running };
wait_all();
ok( $running_seen, 'routine reports running while its callback executes' );

my $co_op;
my $saw_cancel = 0;
$co_op = go sub {
    for (1 .. 500) {
        Developer::Dashboard::GoRoutine::pump(0.01);
        if ($co_op->cancel_requested) { $saw_cancel = 1; last; }
    }
};
my $killer = go(sub { $co_op->kill }, { after => 0.05 });
wait_all();
ok( $saw_cancel, 'running routine observes the cooperative cancel flag' );
is( $co_op->status, 'killed', 'cooperatively cancelled routine reports killed' );
ok( $co_op->is_killed, 'cooperatively cancelled routine is marked as killed' );
is( $killer->status, 'done', 'killer routine finishes normally' );

# -------------------------------------------------------------------------
# Timeout validation
# -------------------------------------------------------------------------

for my $bad_timeout ( undef, [], 'not-a-number', 'NaN', 'Inf', '1e999', -1 ) {
    my $routine = bless {}, 'Developer::Dashboard::GoRoutine::Routine';
    my $ok = eval { $routine->timeout($bad_timeout); 1 };
    ok( !$ok, 'invalid timeout is rejected' );
    like( $@, qr/timeout\(\) requires a non-negative number/, 'invalid timeout has a clear diagnostic' );
}

{
    package Local::NaNTimeout;
    use overload
        '""' => sub { return '1' },
        '0+' => sub { return POSIX::nan() },
        fallback => 1;
    package main;

    my $routine = bless {}, 'Developer::Dashboard::GoRoutine::Routine';
    my $nan_timeout = bless {}, 'Local::NaNTimeout';
    my $ok = eval { $routine->timeout($nan_timeout); 1 };
    ok( !$ok, 'timeout rejects a value that stringifies numerically but numifies to NaN' );
    like( $@, qr/timeout\(\) requires a non-negative number/,
        'NaN timeout rejection uses the public validation diagnostic' );
}

# -------------------------------------------------------------------------
# _share_many and share on pre-tied variables
# -------------------------------------------------------------------------

{
    my $scalar_value = 21;
    my @array_values = qw(alpha beta);
    my %hash_values = ( key => 'value' );
    Developer::Dashboard::GoRoutine::_share_many(
        \$scalar_value, \@array_values, \%hash_values
    );
    is( 0 + $scalar_value, 21, '_share_many accepts a scalar reference and preserves its initial value' );
    is_deeply( [@array_values], [qw(alpha beta)], '_share_many accepts an array and preserves its items' );
    is_deeply( { %hash_values }, { key => 'value' }, '_share_many accepts a hash and preserves its entries' );

    my $already_shared = eval { Developer::Dashboard::GoRoutine::_share_many(
            \$scalar_value, \@array_values, \%hash_values
        ); 1 };
    ok( $already_shared, '_share_many accepts its own already-shared scalar, array, and hash values' );

    my $code = sub { return 1 };
    my $unsupported = eval {
        Developer::Dashboard::GoRoutine::_share_many($code);
        1;
    };
    ok( !$unsupported, '_share_many rejects a code reference' );
    like( $@, qr/expects scalar, array, or hash/, 'unsupported shared-reference error names accepted types' );

    my $unsupported_scalar = eval {
        Developer::Dashboard::GoRoutine::_share_many('ordinary value');
        1;
    };
    ok( !$unsupported_scalar, '_share_many rejects a non-reference value' );
    like( $@, qr/expects scalar, array, or hash/,
        'non-reference rejection names the accepted shared types' );
}

{
    package Local::UnsupportedSharedScalar;
    sub TIESCALAR { return bless {}, shift }
    package Local::UnsupportedSharedArray;
    sub TIEARRAY { return bless {}, shift }
    package Local::UnsupportedSharedHash;
    sub TIEHASH { return bless {}, shift }
    package main;

    tie my $foreign_scalar, 'Local::UnsupportedSharedScalar';
    tie my @foreign_array, 'Local::UnsupportedSharedArray';
    tie my %foreign_hash, 'Local::UnsupportedSharedHash';
    for my $case (
        [ \$foreign_scalar, qr/already tied scalar/ ],
        [ \@foreign_array, qr/already tied array/ ],
        [ \%foreign_hash, qr/already tied hash/ ],
    ) {
        my $accepted = eval { Developer::Dashboard::GoRoutine::_share_many( $case->[0] ); 1 };
        ok( !$accepted, '_share_many rejects an incompatible pre-tied aggregate' );
        like( $@, $case->[1], 'incompatible tied-aggregate diagnostic is explicit' );
    }

    my $share_tied_ok = eval { share $foreign_scalar; 1 };
    ok( !$share_tied_ok, 'share rejects an already tied scalar' );
    like( $@, qr/already tied scalar/, 'already tied scalar diagnostic is explicit' );
}

done_testing;

__END__

=head1 NAME

t/233-goroutine-shared-object-coverage.t - exercise GoRoutine shared values as plain Perl values

=head1 PURPOSE

This test exercises shared scalars, hashes, arrays, scalar references,
blessed values, regexps, code references, filehandles, and formats under the
single-threaded GoRoutine engine, where C<share> is a no-op and every shared
value is just a plain Perl value in the one interpreter. It also covers the
channel and routine-handle public API with real routines: pending/killed/
timed-out/exited/done statuses, cooperative cancellation, timeout validation
(including a NaN overload), and the C<_share_many> helper. Routines observe
the same shared values the main program sees, and channel values pass by
reference.

=head1 WHY IT EXISTS

The old version of this file covered the tied-proxy marshalling layer that
adapted native shared nodes to ordinary Perl references. That layer is gone
with the perl_clone engine, so the file now pins the new contract instead:
plain values, final observable values, and the public routine/channel API.
The separate integration tests exercise real routine scheduling outside
Devel::Cover instrumentation.

=head1 WHEN TO USE

Run this test whenever GoRoutine shared values, the source filter, timeout
validation, or routine and channel handle behaviour change:

    prove -Iblib/lib -Iblib/arch t/233-goroutine-shared-object-coverage.t

=head1 HOW TO USE

The test requires the checkout's built XS object and loads it through the
existing C<Developer::Dashboard::HtmlEscape> distribution module. It uses
ordinary Perl operations against shared values and real C<go> routines, so it
never creates a worker thread. Run it with the normal test library paths and
the coverage gate will include its Perl-module execution in the lib-only
report.

=head1 EXAMPLES

Run the focused shared-value contract:

    prove -lv t/233-goroutine-shared-object-coverage.t

Run it as part of all tests and coverage:

    d2 docker compose exec dev perl script/coverage-gate

=head1 WHAT USES IT

The repository test and coverage workflows use this file to measure the Perl
shared-value and handle code while the integration tests independently verify
routine scheduling. It is not installed as an end-user command.

=cut
