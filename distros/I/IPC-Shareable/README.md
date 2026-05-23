# NAME

IPC::Shareable - Use shared memory backed variables across processes

<div>

    <a href="https://github.com/stevieb9/ipc-shareable/actions"><img src="https://github.com/stevieb9/ipc-shareable/workflows/CI/badge.svg"/></a>
    <a href='https://coveralls.io/github/stevieb9/ipc-shareable?branch=master'><img src='https://coveralls.io/repos/stevieb9/ipc-shareable/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>
</div>

# SYNOPSIS

    use IPC::Shareable qw(:lock);

    tie my %hash,   'IPC::Shareable', OPTIONS;
    tie my @array,  'IPC::Shareable', OPTIONS;
    tie my $scalar, 'IPC::Shareable', OPTIONS;

    # Lock, make changes, unlock

    tied(VARIABLE)->lock;
        # Do something with the variable
    tied(VARIABLE)->unlock;

    # Blocking lock attempt (a writer must have a LOCK_EX lock)

    tied(VARIABLE)->lock(LOCK_SH);
    my $val = VARIABLE->[5]; # Will wait to get value until writer releases LOCK_EX

    # Non-blocking lock attempt

    tied(VARIABLE)->lock(LOCK_SH|LOCK_NB)
        or print "Resource unavailable\n";

    # Lock with a code reference, which will auto-unlock when the block finishes

    tied(VARIABLE)->lock(sub { print "hello!\n"; });

    # Ensure only one instance of a script can be run at any time

    IPC::Shareable->singleton('UNIQUE SCRIPT LOCK STRING');

# SYNOPSIS - DEVELOPER/TROUBLESHOOTING

    # Get SYSV shared memory specifications of the system (if available)

    my $href = IPC::Shareable::sysv_info();

    # Get the shared memory segment and semaphore objects directly

    my $segment   = tied(VARIABLE)->seg;
    my $semaphore = tied(VARIABLE)->sem;

    # Get the shared memory segment and semaphores for a lower level

    my $seg = tied(%{ $hv{a}->{b} })->seg;
    my $sem = tied(%{ $hv{a}->{b} })->sem;

    # Fetch a printable string representation of the segment and semaphore
    # mapping for your data

    tied(VARIABLE)->seg_map;

    # Remove the shared memory segment and semaphore directly

    tied(VARIABLE)->remove;

    # Manual cleanup procedures (mainly used for unit testing etc)

    IPC::Shareable::clean_up;
    IPC::Shareable::clean_up_all;
    IPC::Shareable::clean_up_protected;

    # Get the actual IPC::Shareable tied object you can make method calls on
    # instead of using the tied object like the examples above

    my $knot = tied(VARIABLE); # Dereference first if using a tied reference

    # ...or get the knot at inception

    my $knot = tie my VARIABLE, 'IPC::Shareable', OPTIONS;
    my $sysv_info_href = $knot->sysv_info;

# DESCRIPTION

IPC::Shareable allows you to tie a variable to shared memory, making it
easy to share the contents of that variable with other Perl processes and
scripts.

Scalars, arrays, hashes and even objects can be tied. The variable being
tied may contain arbitrarily complex data structures - including references to
arrays, hashes of hashes, etc.

**Note**: When using nested data structures, each nested structure utilizes an
additional shared memory segment. The entire structure is not squashed into a
single segment. See ["DATA AND SEGMENT MAPPING"](#data-and-segment-mapping) for details.

The association between variables in distinct processes is provided by
GLUE (aka. a "key"). This is any arbitrary string or integer that serves as a
common identifier for data across process space.  Hence the statement:

    tie my %hash, 'IPC::Shareable', { key => 'GLUE STRING', create => 1 };

...in program one and the statement

    tie my %thing, 'IPC::Shareable', { key => 'GLUE STRING' };

...in program two will create and bind `%hash` the shared memory in program
one and bind it to `%thing` in program two.

There is no pre-set limit to the number of processes that can bind to
data; nor is there a pre-set limit to the complexity of the underlying
data of the tied variables.  The amount of data that can be shared
within a single bound variable is limited by the system's maximum size
for a shared memory segment, and the total number of segments allowed by the
system (the exact values are system-dependent).

The bound data structures are all linearized (using [JSON](https://metacpan.org/pod/JSON) by default or
optionally [Storable](https://metacpan.org/pod/Storable)) before being slurped into shared memory. Upon retrieval,
the original format of the data structure is recovered. Semaphore flags can be
used for locking data between competing processes.

**Recommendation**: Utilizing the locking mechanisms is highly advised to ensure
data consistency and integrity. See ["LOCKING"](#locking).

**Recommendation**: If you're using JSON to serialize your data (the default), I
would highly advise you to install the XS version ([JSON::XS](https://metacpan.org/pod/JSON%3A%3AXS)). We will
automatically use it if available, and it is much faster than the pure Perl
version ([JSON::PP](https://metacpan.org/pod/JSON%3A%3APP)).

# OPTIONS

Options are specified by passing a reference to a hash as the third argument to
the `tie()` function that binds a variable. We also call these
**attributes**.

The following fields are recognized in the options hash:

## key

**key** is the GLUE that is a direct reference to the shared memory segment
that's to be tied to the variable.

If this option is missing, we'll default to using `IPC_PRIVATE`. Note however,
that going this route will not allow you to share your data across processes.

The key can be specified as:

- A text string (internally, a 32-bit CRC of the string is used as the key)
- A hex string (eg. `'0xDEADBEEF'`), which we convert to integer form
- A hex value (eg. `0xDEADBEEF`), used as-is as the integer key
- An integer (eg. `1234`), used as-is as the integer key

Default: **IPC\_PRIVATE**

## create

**create** is used to control whether the process creates a new shared
memory segment or not.  If **create** is set to a true value,
[IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable) will create a new binding associated with GLUE as
needed.  If **create** is false, [IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable) will not attempt to
create a new shared memory segment associated with GLUE.  In this
case, a shared memory segment associated with GLUE must already exist
or we'll `croak()`.

Default: **false**

## exclusive

If **exclusive** field is set to a true value, we will `croak()` if the data
binding associated with GLUE already exists.  If set to a false value, calls to
`tie()` will succeed even if a shared memory segment associated with GLUE
already exists.

See ["graceful"](#graceful) for a silent, non-exception exit if a second process attempts
to obtain an in-use `exclusive` segment.

Default: **false**

## graceful

If **exclusive** is set to a true value, we normally `croak()` if a second
process attempts to obtain the same shared memory segment. Set **graceful**
to true and we'll `exit` silently and gracefully. This option does nothing
if `exclusive` isn't set.

See ["warn"](#warn) to emit a warning before gracefully exiting when a collision occurs.

Default: **false**

## warn

When set to a true value, **graceful** will output a warning if there are
process collisions.

Default: **false**

## mode

The **mode** argument is an octal number specifying the access
permissions when a new data binding is being created.  These access
permission are the same as file access permissions in that `0666` is
world readable and writable, `0600` is writable only by the effective UID of
the process creating the shared variable, etc.

Default: **0666** (world readable and writeable)

## size

This field is used to specify the size of each shared memory segment allocated.

**Note**: Each nested data structure requires a new shared memory segment. The
`size` attribute is applied to the first, and all subsequent segments created,
and does not reflect the overall size of memory to be used.

The maximum size we allow for each segment by default is ~1GB. See the ["limit"](#limit)
option to override this default.

Default: `IPC::Shareable::SHM_BUFSIZ()` (ie. **65536**)

## protected

The segments with this option set will persist even through all of our automatic
and manual clean up procedures, less
[clean\_up\_protected](#clean_up_protected-protect_key).

Set this to a non-zero integer. The integer is persisted in the segment's
associated semaphore set, so any process that later attaches to the same
segment via `create => 0` will automatically have this attribute restored;
it does not need to pass `protected` explicitly.

The integer acts as a group key: all segments (including nested children)
created under the same protected parent share the same value, so a single call
to `clean_up_protected($key)` removes the entire group.

To clean up protected objects, call
`(tied %object)->clean_up_protected(integer)`, where 'integer' is the
value you set the `protected` option to. You can call this cleanup routine in
the script you created the segment, or anywhere else, at any time.

**Note**: The protect key is limited to values accepted by the system's semaphore
implementation (typically 0-32767; 0 means unprotected).

Default: **0**

## limit

This field will allow you to set a segment size larger than the default maximum
which is 1,073,741,824 bytes (approximately 1 GB). If set, we will
`croak()` if a size specified is larger than the maximum. If it's set to a
false value, we'll `croak()` if you send in a size larger than the total
system RAM.

Default: **true**

## destroy

If set to a true value, the shared memory segment underlying the data
binding will be removed when the process that initialized the shared memory
segment exits cleanly.

Only those memory segments that were created by the current process will be
removed.

Use this option with care. In particular you should not use this option in a
program that will fork after binding the data.  On the other hand, shared memory
is a finite resource and should be released if it is not needed.

**Note**: If the segment was created with its ["protected"](#protected) attribute set,
it will not be removed upon program completion, even if `destroy` is set.

Default: **false**

## serializer

By default, we use [JSON](https://metacpan.org/pod/JSON) as the data serializer when writing to or
reading from the shared memory segments we create. For cross-platform and
cross-language interoperability this is the recommended choice. Alternatively,
you can use [Storable](https://metacpan.org/pod/Storable) for richer data type support (eg. blessed objects).

Send in either `json` or `storable` as the value to use the respective
serializer.

Default: **json**

## enforced\_write\_locking

When enabled, writes from any knot are blocked while another knot holds
`LOCK_EX` on the segment, or while there are active `LOCK_SH` readers. Pair
with `violated_write_lock_warn` to also emit a warning when a write is
blocked.

**Note**: This protection system will never be reached if all callers use
proper locking at all times.

Default: **true**

## violated\_write\_lock\_warn

When `enforced_write_locking` is enabled, and this attribute is set to true,
we will emit a warning when a write violation occurs (a write attempted
against a segment that another knot has locked with `LOCK_EX`, or a write
attempted against a segment with active `LOCK_SH` readers). The warning
includes the UUID of the object that caused the violation and the segment ID
it occurred against.

Default: **true**

## enforced\_read\_locking

When enabled, an unlocked read against a segment that another knot has locked
with `LOCK_EX` is detected. Reads are never **blocked**; this option only
controls whether the check fires. Pair with `violated_read_lock_warn` to emit
a warning when this happens.

**Note**: Reads (fetches) are never blocked, even when a `LOCK_EX` is active.
If a reader does not hold a `LOCK_SH` and reads while a writer holds
`LOCK_EX`, the returned data may be stale or partially-written. To guarantee
a coherent snapshot, acquire `LOCK_SH` before reading.

**Note**: This protection system will never be reached if all callers use
proper locking at all times.

Default: **true**

## violated\_read\_lock\_warn

When `enforced_read_locking` is enabled, and this attribute is set to true,
we will emit a warning when an unlocked read is attempted against a segment
that another knot has locked with `LOCK_EX`. The returned data may be stale
or partially-written; the warning recommends acquiring `LOCK_SH` before
reading to guarantee a coherent snapshot. The warning includes the UUID of
the object that caused the violation and the segment ID it occurred against.

Default: **true**

## Default Option Values

Default values for options are:

    key                         => IPC_PRIVATE, # 0
    create                      => 0,
    exclusive                   => 0,
    mode                        => 0666,
    size                        => IPC::Shareable::SHM_BUFSIZ(), # 65536
    protected                   => 0,
    limit                       => 1,
    destroy                     => 0,
    graceful                    => 0,
    warn                        => 0,
    serializer                  => 'json',
    enforced_write_locking      => 1,
    enforced_read_locking       => 1,
    violated_write_lock_warn    => 1,
    violated_read_lock_warn     => 1,

# METHODS - STANDARD USER

These are typically the only methods a normal user will need in the course of
their use of this distribution.

## new

This `new()` call is not necessary and is a simple wrapper around `tie()`. It
is capable only of returning a tied reference object (by default, a hash ref).

Instantiates and returns a reference to a hash backed by shared memory.

    my $href = IPC::Shareable->new(key => "testing", create => 1);

    $href=>{a} = 1;

    # Call tied() on the dereferenced variable to access object methods
    # and information

    tied(%$href)->seg_count;

Parameters:

Optional: See the ["OPTIONS"](#options) section for a list of all available options.
Most often, you'll want to at minimum, send in the **key** and **create** options.

It is possible to get a reference to an array or scalar as well. Simply send in
either `var => 'ARRAY'` or `var => 'SCALAR'` to do so.

Return: A reference to a hash (or array or scalar) which is backed by shared
memory.

## lock($flags, $code)

Obtains a lock on the shared memory. `$flags` specifies the type of lock to
acquire.  If `$flags` is not specified, an exclusive read/write lock is
obtained. Acceptable flags are:

    LOCK_EX         - Exclusive; use when writing
    LOCK_SH         - Shared; use when reading

    LOCK_EX|LOCK_NB - Exclusive, non-blocking
    LOCK_SH|LOCK_NB - Shared, non-blocking

Parameters:

    $flags

Optional, Integer: If this parameter is omitted, we default to `LOCK_EX`, an
exclusive write lock.

    $code

Optional, Code reference: If this parameter is sent in, and an exclusive lock
is asked for, we will set the lock, execute the subroutine, and then call
`unlock()` on the segment. The sub is called within an `eval`, so we will
`unlock`, then `die` with whatever error your function threw.

**Note**: Although the `$flags` and `$code` parameters appear positional, you
can send in `$code` without sending in any `$flags`. When this occurs,
`$flags` will automatically be set to `LOCK_EX`.

Return: `true` on success, and `undef` on error. For non-blocking calls, the
method returns `0` if it would have blocked.

Obtain an exclusive lock like this:

        tied(%var)->lock(LOCK_EX); # Same as default

Only one process can hold an exclusive lock on the shared memory at a given
time.

Obtain a shared (read) lock:

        tied(%var)->lock(LOCK_SH);

Multiple processes can hold a shared (read) lock at a given time.  If a process
attempts to obtain an exclusive lock while one or more processes hold
shared locks, it will be blocked until they have all finished.

Either of the locks may be specified as non-blocking:

        tied(%var)->lock( LOCK_EX|LOCK_NB );
        tied(%var)->lock( LOCK_SH|LOCK_NB );

A non-blocking lock request will return `0` immediately if it would have had to
wait to obtain the lock.

**Note**: These locks are advisory (just like flock), meaning that
all cooperating processes must coordinate their accesses to shared memory
using these calls in order for locking to work.  See the `flock()` call for
details.

**Note**: You can enforce a `LOCK_EX` lock at a software level by ensuring that
the `enforced_write_locking` option is set to a true value (the default).
This will prevent processes that decide not to implement the advisory locking
from writing to the segment. The companion `enforced_read_locking` option
(also true by default) enables detection of unlocked reads against an
exclusively-locked segment; reads are never blocked, but a warning will be
emitted if `violated_read_lock_warn` is also set.

**Important**: Locks are inherited through forks, which can cause unintended and
problematic side effects (particularly duplicated `LOCK_EX` locks). Don't
`fork()` until all active locks have been released.

The constants `LOCK_EX`, `LOCK_SH`, `LOCK_NB`, and `LOCK_UN` are available
for import using any of the following export tags:

        use IPC::Shareable qw(:lock);
        use IPC::Shareable qw(:flock);
        use IPC::Shareable qw(:all);

Or, just use the flock constants available in the Fcntl module.

See ["LOCKING"](#locking) for further details.

## unlock

Removes a lock. Takes no parameters, returns `true` on success.

This is equivalent to calling `shlock(LOCK_UN)`.

See ["LOCKING"](#locking) for further details.

## singleton($glue, $warn)

Class method that ensures that only a single instance of a script can be run
at any given time.

Parameters:

    $glue

Mandatory, String: The key/glue that identifies the shared memory segment.

    $warn

Optional, Bool: Send in a true value to have subsequent processes throw a
warning that there's been a shared memory violation and that it will exit.

Default: **false**

Return: `$$`. The process ID.

**Note**: See [Script::Singleton](https://metacpan.org/pod/Script::Singleton).
That library implements `singleton` for a script with a simple `use` line.

# METHODS - OBJECT AND PROCESS

These methods provide facilities for identifying information about the current
object and the overall state information of the current processes.

## attributes

Retrieves the list of attributes that drive the [IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable) object.

Parameters:

    $attribute

Optional, String: The name of the attribute. If sent in, we'll return the value
of this specific attribute. Returns `undef` if the attribute isn't found.

Attributes are the `OPTIONS` that were used to create the object.

Returns: A hash reference of all attributes if `$attributes` isn't sent in, the
value of the specific attribute if it is.

## global\_register

Returns a hash reference of hashes of all in-use shared memory segments across
all processes/forks within the current process space. The key is the memory
segment ID, and the value is the segment and semaphore objects.

## process\_register

Returns a hash reference of hashes of all in-use shared memory segments created
by the calling process only (ie. not including forks). The key is the memory
segment ID, and the value is the segment and semaphore objects.

## uuid

Returns the UUID of the object.

# METHODS - MANUAL CLEANUP

These methods are mainly for forced cleanup. `remove()` is used internally.
These methods are generally never needed by a normal user, and are primarily
for use in unit testing and other development work.

## clean\_up

    IPC::Shareable->clean_up;

    # or

    tied($var)->clean_up;

    # or

    $knot->clean_up;

This is a class method that provokes [IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable) to remove all
shared memory segments created by the process. Segments not created
by the calling process are not removed.

This method will not clean up segments created with the `protected` option.

## clean\_up\_all

    IPC::Shareable->clean_up_all;

    # or

    tied($var)->clean_up_all;

    # or

    $knot->clean_up_all

This is a class method that provokes [IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable) to remove all
shared memory segments encountered by the process. Segments are
removed even if they were not created by the calling process.

This method will not clean up segments created with the `protected` option.

## clean\_up\_protected($protect\_key)

If a segment is created with the `protected` option, it, nor its children will
be removed during calls of `clean_up()` or `clean_up_all()`.

When setting ["protected"](#protected), you specified a lock key integer. When calling this
method, you must send that integer in as a parameter so we know which segments
to clean up.

Because the protect key is stored in the segment's semaphore set, any process
that attached to the segment (even without passing `protected` on tie)
will have had its in-process attribute populated automatically. You can
therefore call `clean_up_protected()` from any process that has attached to
the segment, not only from the one that created it.

    my $protect_key = 93432;

    IPC::Shareable->clean_up_protected($protect_key);

    # or

    tied($var)->clean_up_protected($protect_key);

    # or

    $knot->clean_up_protected($protect_key)

Parameters:

    $protect_key

Mandatory, Integer: The integer protect key you assigned with the `protected`
option

## remove($key)

Parameters:

    $key

Optional, see ["key"](#key) for valid values. Preferably, an integer or a hex string
prefixed with `0x`.

**Note**: If the `$key` parameter is sent in, we will delete that segment only
and return immediately thereafter.

    tied($var)->remove;

    # or

    $knot->remove;

    # Remove a specific segment by key (can remove non C<IPC::Shareable>
    # segments). If key is sent in, the caller can be the module or the object.

    IPC::Shareable->remove('0xdeadbeef');   # hex string
    IPC::Shareable->remove(0xdeadbeef);     # hex integer
    IPC::Shareable->remove(1234);           # integer
    tied($var)->remove('Test');             # string

**Note**: Calling `remove()` on the object underlying a `tie()`d variable
removes the associated shared memory segment.  The segment is removed
irrespective of whether it has the **destroy** option set or not and
irrespective of whether the calling process created the segment.

# METHODS - SYSTEM AND SHARED MEMORY

These methods are for very low level diagnostic, troubleshooting, investigation,
informational and fact finding situations.

**Note**: Both ["seg"](#seg) and ["sem"](#sem) are external objects and have their own
methods and data that can be used for analysis. This is particularly true with
["seg"](#seg). Each of their respective documentation sections link to their
corresponding documentation.

## seg

Called on either a tied variable or on the tie object, returns the shared
memory segment object currently in use.

    tie my %h, ...;
    $h{a}->{b}{c} = 10;

    my $top_level_seg = tied(%h)->seg;
    my $bot_level_seg = tied(%{ $h{a}->{b} })->seg;

See [IPC::Shareable::SharedMem](https://metacpan.org/pod/IPC%3A%3AShareable%3A%3ASharedMem) documentation for details and available
methods.

## sem

Called on either a tied variable or on the tie object, returns the semaphore
object related to the memory segment currently in use.

    tie my %h, ...;
    $h{a}->{b}{c} = 10;

    my $top_level_sem = tied(%h)->sem;
    my $bot_level_sem = tied(%{ $h{a}->{b} })->sem;

See [IPC::Semaphore](https://metacpan.org/pod/IPC%3A%3ASemaphore) documentation.

## seg\_count

Returns the number of shared memory segments that currently exist
on the system, by counting data lines in your system's `ipcs -m` output.
It is guaranteed to produce consistent results.

Return: Integer

## sem\_count

Returns the number of semaphore sets that currently exist on the system, by
parsing `ipcs -s`. Since each [IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable) segment is associated with
exactly one semaphore set (same SysV key), this count moves in lockstep with
["seg\_count"](#seg_count) when [IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable) segments are the only semaphore
users on the system and are created and destroyed cleanly.

Return: Integer

## shm\_segments($key)

    my $ipc_shareable_segments = IPC::Shareable->shm_segments;

    # Filtered to one variable's segments only
    my $segs = IPC::Shareable->shm_segments('my_key');
    my $segs = IPC::Shareable->shm_segments('0xDEADBEEF');

Class/object method. Scans all existing shared memory segments on the system
and returns a hash reference mapping the hex key string (eg. `'0xdeadbeef'`)
to the raw literal contents of that segment. Only loads segments that were
created by [IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable).

Segments created with `IPC_PRIVATE` (key `0x00000000`) are skipped because
they cannot be looked up by key.

Parameters:

    $key

Optional, String or Int: If sent in, we will restrict the result to only the
segments related to the variable the `$key` reflects. Without this parameter,
all [IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable) segments on the system are returned.

Return: Hash reference where each key is the SHM key in hex format.

Field descriptions:

**known**: `1` if this segment is currently tied in the calling process,
`0` if not. A value of `0` includes segments legitimately persisted by
another process (`destroy => 0`), not just crashed leftovers. See
["unknown\_segments"](#unknown_segments) for important caveats.

**local\_process**: `1` if created by the same process this method is being run,
and `0` if not.

**content**: The actual raw content of the shared memory segment.

**child\_keys**: Nested data structures each require their own segment. Keys
within this array reference map to child segments.

Here's an example data structure, and what the return value of `shm_segments`
would look like for it using the JSON serializer. Note that the top-level
structure is a hash, and it contains two nested hashes (keys 'c; and 'd'), which
are each stored in their own segments. It also has two scalar values (keys 'a'
and 'b'), which are stored in the top-level segment.

    # Actual data

    {
        a => 1,
        b => 'hello',
        c => {
            x => 10,
            y => 20,
        },
        d => {
            p => 'foo',
            q => 'bar',
        },
    }

    # Call return (JSON content strings will be on one line; separated for
    # clarity)

    {
        '0x2abc0001' => {
            known           => 1,
            local_process   => 1,
            content         => 'IPC::Shareable{
                "a": 1,
                "b": "hello",
                "c": {
                    "__ics__": {
                        "child_key_hex": "0x000e1b1d",
                        "child_key":     "924445",
                        "type":          "HASH"
                    }
                },
                "d": {
                    "__ics__": {
                        "child_key_hex": "0x000097af",
                        "child_key":     "38831",
                        "type":          "HASH"
                    }
                }
            }',
            child_keys      => [
                '0x000e1b1d',
                '0x000097af'
            ],
        },
        '0x000e1b1d' => {
            known           => 1,
            local_process   => 1,
            content         => 'IPC::Shareable{"y":20,"x":10}',
            child_keys      => [],
        },
        '0x000097af' => {
            known           => 1,
            local_process   => 1,
            content         => 'IPC::Shareable{"p":"foo","q":"bar"}',
            child_keys      => [],
        }
    }

## unknown\_segments

    my @unknown_segments = IPC::Shareable->unknown_segments;

    for my $key (@unknown_segments) {
        print "Unknown segment: $key\n";
        IPC::Shareable->remove($key);
    }

Class/object method. Returns a list of hex key strings (eg. `'0xdeadbeef'`)
for all shared memory segments that were created by [IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable) but are
not currently tied in the calling process.

**Important**: this method has no way to distinguish between a segment that was
left behind by a crashed process and one that is legitimately persisted by
another running process (`destroy => 0`). Both will appear in the returned
list. Only call `remove` on entries you are certain belong to your own
application and are no longer in use.

Return: List of hex key strings.

## seg\_map

    # Show all IPC::Shareable segments visible on the system
    print IPC::Shareable->seg_map;

    # Show only the segment tree rooted at this object
    print $knot->seg_map;
    print tied(%hash)->seg_map;

When called as a **class method**, returns a human-readable string showing all
[IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable) shared memory segments visible on the current system,
organised as a tree (root segments at the top, nested children indented below
their parent).

When called as an **object method**, the output is filtered to just the segment
tree rooted at that object (the segment itself plus any nested children).

For each segment the output includes:

- The hex key and OS segment ID
- Status tags: `known` (tied in this process) or `unknown`, and
`owner` if this process created the segment
- Semaphore information: OS semaphore ID (`sem_id`), `SEM_MARKER`,
read-lock counter, write-lock counter, and `PROTECTED` (the integer stored
in `SEM_PROTECTED`)
- The list of child segment hex keys, or `(none)`
- The segment's current content. Reference values that are child segments
are shown as `<child: 0xHEX>` rather than being recursed into.
Segments not tied in this process show `(not accessible)`.

Example:

    tie my %h, 'IPC::Shareable', {
        key     => 0x1a2b,
        create  => 1,
        destroy => 1
    };

    $h->{nested} = { x => 1, y => 2 };

    my $mapping = tied(%h)->seg_map;

    print $mapping;

Output:

IPC::Shareable Segment Map
&#x3d;=========================

    [known, owner]  key: 0x00001a2b  seg_id: 1890844693
        Semaphores: sem_id: 1272774674
            1: SEM_MARKER=1
            2: READERS=0
            3: WRITERS=0
            4: PROTECTED=0
        Children:   0x00018373
        Content:    { nested => <child: 0x00018373> }

    [known, owner]  key: 0x00018373  seg_id: 1888682002
        Semaphores: sem_id: 1300234259
            1: SEM_MARKER=1
            2: READERS=0
            3: WRITERS=0
            4: PROTECTED=0
        Children:   (none)
        Content:    { x => "1", y => "2" }

## sysv\_info

    my $sysv_info = IPC::Shareable->sysv_info;

    print "Max segment size: $sysv_info->{shmmax}\n";
    print "Max segments (system): $sysv_info->{shmmni}\n";

Class method. Returns a hash reference containing the kernel's SysV shared
memory configuration parameters for the current platform.

Returns `undef` if the platform is not supported or no data could be read.

On MacOS, reads from `sysctl kern.sysv`. Example return value:

    {
        shmmax => 4194304,   # Maximum size of a single segment (bytes)
        shmmin => 1,         # Minimum size of a single segment (bytes)
        shmmni => 32,        # Maximum number of segments system-wide
        shmseg => 8,         # Maximum number of segments per process
        shmall => 1024,      # Maximum total shared memory (pages)
    }

On Linux, reads from `/proc/sys/kernel/`. Example return value:

    {
        shmmax => 18446744073692774399,  # Maximum size of a single segment (bytes)
        shmmin => 1,                     # Minimum size of a single segment (bytes)
        shmmni => 4096,                  # Maximum number of segments system-wide
        shmall => 18446744073692774399,  # Maximum total shared memory (pages)
    }

Note: Linux has no per-process segment limit (`shmseg`); only the system-wide
`shmmni` applies.

On FreeBSD, reads from `sysctl kern.ipc`. Example return value:

    {
        shmmax => 536870912,  # Maximum size of a single segment (bytes)
        shmmin => 1,          # Minimum size of a single segment (bytes)
        shmmni => 192,        # Maximum number of segments system-wide
        shmseg => 128,        # Maximum number of segments per process
        shmall => 131072,     # Maximum total shared memory (pages)
    }

On Solaris (including OmniOS/illumos), the kernel's SysV shared memory
configuration is not yet read programmatically. This method returns
`undef` on Solaris; use system tools such as `prctl` or
`mdb -k` to inspect the kernel IPC limits instead.

Return: Hash reference, or `undef` if the platform is not supported or no data
could be read.

# LOCKING

IPC::Shareable provides methods to implement application-level advisory and
enforced locking of the shared data structures.  These methods are `lock()` and
`unlock()`. To use them you must first get the object underlying the tied
variable, either by saving the return value of the original call to `tie()` or
by using the built-in `tied()` function.

See [lock()](#lock-flags-code) for flag combinations allowed.

## Lock and unlock

To lock and subsequently unlock a variable, do this:

    tie my %hash, 'IPC::Shareable', { %options };

    tied(%hash)->lock;
    $hash{a}->{b} = 1;
    tied(%hash)->unlock;

This will place an exclusive lock on the data of `%hash`, including all nested
data below the parent. You can also get shared locks or attempt to get a lock
without blocking.

[IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable) makes the constants `LOCK_EX`, `LOCK_SH`, `LOCK_NB`, and
`LOCK_UN` exportable to your address space with the export tags `:lock`,
`:flock`, or `:all`. The values should be the same as the standard `flock`
option arguments.

When attempting to get a blocking lock (eg. `LOCK_EX` or `LOCK_SH`) while
another process has an exclusive write lock (`LOCK_EX`), your call will block
and wait until the other process releases its exclusive lock. The same thing
happens if you attempt to get a `LOCK_EX` if there are any other processes that
hold a `LOCK_SH`.

Here is an example of how to manage a non-blocking lock:

    if (tied(%hash)->lock(LOCK_SH|LOCK_NB)){
        print "The value is $hash{a}\n";
        tied(%hash)->unlock;
    } else {
        print "Another process has an exclusive lock.\n";
    }

If no argument is provided to `lock`, it defaults to `LOCK_EX`.

## Enforced write and read locking

Additional safeguards are in place to protect your locked data from processes
that don't bother to implement locking explicitly.

### Violating an enforced write lock

By default, the `enforced_write_locking` option is set to true, which means
that if a tied variable sets a `LOCK_EX`, all writes from all other processes
will fail, and their data will not be updated.

If the offending process has `violated_write_lock_warn` set to true (also
default), it will receive a warning regarding the issue.

### Violating an enforced read lock

Also enabled by default, the `enforced_read_locking` will catch instances where
a process attempts a read of data that is currently locked with `LOCK_EX` by
another process. Unlike write protection, read protection does not prevent the
read; it simply sets the stage for you to be able to warn the user that they
are receiving stale data.

To have the user warned that they are in fault, the `violated_read_lock_warn`
option must be set to true, which it is by default. The warning advises the user
that the data they have received is stale, and that they should refactor their
code to implement proper locking.

### Important notes

Note that in the background, we perform lock optimization when reading and
writing to the shared storage even if the advisory locks aren't being used.

Using the advisory locks can speed up processes that are doing several writes/
reads at the same time (ie. transactions).

When using `lock()` to lock a variable, be careful to guard against
signals.  Under normal circumstances, `IPC::Shareable`'s `END` method
unlocks any locked variables when the process exits.  However, if an
untrapped signal is received while a process holds a lock, `END` will
not be called.

This is _not_ a deadlock risk: all semaphore lock operations in
`IPC::Shareable` use the `SEM_UNDO` flag, which causes the kernel to
automatically reverse any semaphore operations when the process exits,
regardless of the cause of death (including `SIGKILL` and hardware
faults). Other processes waiting for the lock will be unblocked.

# LOCKING BEHAVIOR MATRIX

The following matrix describes what happens to a second object (B) when a
first object (A) holds `LOCK_EX` on a segment, across all combinations of
the four lock-control attributes:

- EW = `enforced_write_locking`
- ER = `enforced_read_locking`
- WW = `violated_write_lock_warn`
- WR = `violated_read_lock_warn`

## Lock acquisition (attribute-independent)

`semop` runs at the kernel level; none of the four flags affect whether a
lock is granted.

    +--------------------------+----------------------------------------------+
    | B's attempt              | Lock result while A holds LOCK_EX            |
    +--------------------------+----------------------------------------------+
    | LOCK_EX                  | Blocks, then acquires once A unlocks         |
    | LOCK_EX | LOCK_NB        | Returns 0 immediately                        |
    | LOCK_SH                  | Blocks, then acquires once A unlocks         |
    | LOCK_SH | LOCK_NB        | Returns 0 immediately                        |
    | (no lock)                | N/A                                          |
    +--------------------------+----------------------------------------------+

## Behavior after lock state is established

### Case 1: B successfully holds LOCK\_EX (blocking attempts complete after A unlocks)

All flags are irrelevant; `FETCH` uses the cache (skipping the read check),
and the write check bypasses on `LOCK_EX` ownership.

    +----------+--------------+-----------+--------------+
    | Read     | Read warn?   | Write     | Write warn?  |
    +----------+--------------+-----------+--------------+
    | cache    | never        | succeeds  | never        |
    +----------+--------------+-----------+--------------+

### Case 2: B successfully holds LOCK\_SH (after A unlocks)

`FETCH` uses cache (no read warn possible). Writes go through the write
check, which sees `SEM_READERS > 0` from B's own `LOCK_SH`.

    +----+----+------------------------------------+--------------+
    | EW | WW | Write outcome                      | Write warn?  |
    +----+----+------------------------------------+--------------+
    |  0 |  * | succeeds (enforcement off)         | no           |
    |  1 |  0 | blocked ("active readers")         | no           |
    |  1 |  1 | blocked ("active readers")         | YES          |
    +----+----+------------------------------------+--------------+

### Case 3: B is unlocked (NB attempt returned 0, or B never attempted a lock); A still holds LOCK\_EX, so SEM\_WRITERS = 1

    +----+----+----+----+-------------------+--------------+-------------------+---------------+
    | EW | ER | WW | WR | Read              | Read warn?   | Write             | Write warn?   |
    +----+----+----+----+-------------------+--------------+-------------------+---------------+
    |  0 |  0 |  0 |  0 | raw shmem (stale) | no           | succeeds (race)   | no            |
    |  0 |  0 |  0 |  1 | raw shmem         | no           | succeeds          | no            |
    |  0 |  0 |  1 |  0 | raw shmem         | no           | succeeds          | no            |
    |  0 |  0 |  1 |  1 | raw shmem         | no           | succeeds          | no            |
    |  0 |  1 |  0 |  0 | raw shmem         | no           | succeeds          | no            |
    |  0 |  1 |  0 |  1 | raw shmem         | YES          | succeeds          | no            |
    |  0 |  1 |  1 |  0 | raw shmem         | no           | succeeds          | no            |
    |  0 |  1 |  1 |  1 | raw shmem         | YES          | succeeds          | no            |
    |  1 |  0 |  0 |  0 | raw shmem         | no           | blocked           | no            |
    |  1 |  0 |  0 |  1 | raw shmem         | no           | blocked           | no            |
    |  1 |  0 |  1 |  0 | raw shmem         | no           | blocked           | YES           |
    |  1 |  0 |  1 |  1 | raw shmem         | no           | blocked           | YES           |
    |  1 |  1 |  0 |  0 | raw shmem         | no           | blocked           | no            |
    |  1 |  1 |  0 |  1 | raw shmem         | YES          | blocked           | no            |
    |  1 |  1 |  1 |  0 | raw shmem         | no           | blocked           | YES           |
    |  1 |  1 |  1 |  1 | raw shmem         | YES          | blocked           | YES           |
    +----+----+----+----+-------------------+--------------+-------------------+---------------+

## When A holds LOCK\_SH instead of LOCK\_EX

When A holds a shared lock, `SEM_READERS > 0` and `SEM_WRITERS = 0`.
This collapses the matrix in three significant ways:

- **Lock acquisition diverges.** B's `LOCK_SH` and `LOCK_SH | LOCK_NB` both
succeed immediately; multiple readers can hold `LOCK_SH` concurrently.
Only the `LOCK_EX` attempts still block (or return 0 for the NB variant).

        +--------------------------+----------------------------------------------+
        | B's attempt              | Lock result while A holds LOCK_SH            |
        +--------------------------+----------------------------------------------+
        | LOCK_EX                  | Blocks, then acquires once A unlocks         |
        | LOCK_EX | LOCK_NB        | Returns 0 immediately                        |
        | LOCK_SH                  | Acquires immediately (concurrent readers OK) |
        | LOCK_SH | LOCK_NB        | Acquires immediately                         |
        | (no lock)                | N/A                                          |
        +--------------------------+----------------------------------------------+

- **Read warnings never fire.** The read check tests `SEM_WRITERS > 0`,
which is false. ER and WR become irrelevant; unlocked reads return raw
shmem but never warn. The data is also genuinely fresher: A is reading, not
writing, so there is no stale-write risk.
- **Write warnings carry a different message.** Unlocked writes are still
blocked when `EW = 1`, but via the `SEM_READERS > 0` branch of the
write check. The warning text becomes:

        "...has active readers (enforced write locking enabled)"

    rather than the "exclusively locked" variant. Write outcome and warn
    behavior across (EW, WW) are otherwise identical to Case 3 above.

## Rules distilled from the matrix

- **Lock acquisition** is governed only by SysV semaphores; the four flags do
not participate.
- **Read result** is always raw shmem when unlocked, always cached when locked;
the four flags only affect whether a warning is emitted, never the value
returned.
- **Read warns** iff `ER = 1` AND `WR = 1` AND another process holds
`LOCK_EX`.
- **Write blocks** iff `EW = 1` AND (another process holds `LOCK_EX` OR has
active `LOCK_SH` readers OR the caller itself holds only `LOCK_SH`).
- **Write warns** iff the write was blocked AND `WW = 1`.
- `LOCK_EX` ownership bypasses every check in the write path and never reaches
the read check, so the four flags never fire for the lock holder.

# DATA AND SEGMENT MAPPING

For simple data (none of the values are references), a single segment is used
throughout. However, with nested data, each value that is a reference is stored
in its own, separate shared memory segment (the key is auto-generated).

Consider a three-level hash:

    $h{a}{b}{c} = 1;

This creates three segments:

    Root segment  (SysV key 0xABCD)
      stored data: { a => <pointer to child key=11111> }
                              |
                              v
              Child segment  (SysV key 11111)
                stored data: { b => <pointer to grandchild key=22222> }
                                          |
                                          v
                        Grandchild segment  (SysV key 22222)
                          stored data: { c => 1 }

Each segment only knows about its direct children. The chain is followed
lazily, one level at a time, as you `FETCH` down into the structure. (See the
[shm\_segments()](#shm_segments-key) documentation to gather this structure within code).

When you replace a child with a new reference where the previous value was
also a reference, a new segment is created and the new data is stored there.
The old segment is automatically removed.

When a value that is a reference is deleted from the data, the memory segment
that held that data is automatically cleaned up and freed.

## Storable

The child knot object (which holds \_key, \_type, etc.) is frozen in-place
inside the parent's serialized byte blob. On thaw, the child knot is
reconstructed from those bytes and re-attached to the existing child segment.

## JSON

JSON can't serialize blessed objects, so each child pointer is written as an
explicit marker:

    { "__ics__" => { type => "HASH", child_key => 11111, child_key_hex => "0x00002b67" } }

The raw JSON in the root segment looks like:

    {"a":{"__ics__":{"type":"HASH","child_key":11111,"child_key_hex":"0x00002b67"}}}

The raw JSON in the child segment (key 11111) looks like:

    {"b":{"__ics__":{"type":"HASH","child_key":22222,"child_key_hex":"0x000056ce"}}}

Finally, the value in the child is not a reference, so it's stored as literal
data:

    {"c": 1}

On decode, any `__ics__` marker is spotted and a tie with `create => 0` is
used to re-attach to the existing child segment by that key; no new segment is
created, it simply reconnects.

# SEMAPHORES

Each memory segment that we utilize comes with it a semaphore set of four
individual semaphores. These semaphores keep state information about the segment
itself, and manages the locking aspects.

## SEM\_MARKER

Semaphore slot ID 0. Signals whether the associated shared memory segment has
been initialized and is ready for use. `1` if it is, `0` if it isn't.

## SEM\_READERS

Semaphore slot ID 1. Specifies the current number of readers holding a
`LOCK_SH`. A write lock (`LOCK_EX` can't be obtained until this value is
reduced to `0`.

## SEM\_WRITERS

Semaphore slot ID 2. Value is `1` if a process has a `LOCK_EX` write lock,
and `0` if not.

## SEM\_PROTECTED

Semaphore slot ID 3. Used to keep track of the `protected` option value for
protected segments. See ["protected"](#protected).

# DESTRUCTION

perl will destroy the object underlying a tied variable when then tied variable
goes out of scope.  Unfortunately for [IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable), this may not be
desirable: other processes may still need a handle on the relevant shared memory
segment.

[IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable) therefore provides several options to control the timing of
removal of shared memory segments.

## destroy Option

As described in ["OPTIONS"](#options), specifying the **destroy** option when
`tie()`ing a variable coerces [IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable) to remove the underlying
shared memory segment when the process calling `tie()` exits gracefully.

## Notes

**Note**: The destruction is handled in an `END` block. Only those memory
segments that are tied to the current process will be removed.

**Note**: If the segment was created with its ["protected"](#protected) attribute set,
it will not be removed in the `END` block, even if `destroy` is set.

**Note**: The `END` block only runs on a _clean_ exit (normal program
end, `die`, or `exit`). It does **not** run for untrapped signals
(`SIGTERM`, `SIGINT`, etc.) or for `SIGKILL`. If your process may be
terminated by a signal and you want `destroy` cleanup to run, install
signal handlers that call `exit`:

    $SIG{INT} = $SIG{TERM} = $SIG{HUP} = sub { exit };

This causes the `END` block to fire on those signals. `SIGKILL` cannot
be caught; any segments left behind by it can be recovered with
`IPC::Shareable->clean_up_all`.

**Note**: Advisory locks (`lock()`/`unlock()`) are _always_ released
automatically when a process dies, even on `SIGKILL`, because the
underlying semaphore operations use `SEM_UNDO`. Lock release is
therefore not a concern; only shared memory _segment_ data requires
the signal handler precaution above.

## See also

See ["METHODS - MANUAL CLEANUP"](#methods-manual-cleanup) for further information.

# EXPORTS

We do not export anything by default. You must request an item individually, or
by tag.

## Tags

### :lock

Aliases: `:flock`

Includes: `LOCK_EX`, `LOCK_SH`, `LOCK_NB` and `LOCK_UN`.

### :flock

Simple legacy alias for `:lock`.

### :semaphores

Includes: `SEM_MARKER`, `SEM_READERS`, `SEM_WRITERS` and `SEM_PROTECTED`.

### :all

Includes [":lock"](#lock) and [":semaphores"](#semaphores).

# AUTHORS

    Benjamin Sugars <bsugars@canoe.ca>
    Steve Bertrand <steveb@cpan.org> (since 2016)

# NOTES

## Important Notes

- o

    In v1.14, we changed our default serializer from `Storable` to `JSON`. For
    backward compatibility, there is a process whereby if you have existing segments
    saved in `Storable` format and the JSON serializer can't process it, we'll
    automatically fall back to `Storable` for you. You should however recreate the
    segments with the `JSON` serializer.

## General Notes

- o

    This distribution has minor parts of it developed in C/XS, but these components
    are only built if we can determine that you've got the proper build tools
    installed. If not, we simply skip the XS build and fall back to our pure Perl
    code.

- o

    Iterating over a hash causes a special optimization if you have not
    obtained a lock (it is better to obtain a read (or write) lock before
    iterating over a hash tied to [IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable), but we attempt this
    optimization if you do not).

- o

    For tied hashes, the `fetch`/`thaw` operation is performed
    when the first key is accessed.  Subsequent key and and value
    accesses are done without accessing shared memory.  Doing an
    assignment to the hash or fetching another value between key
    accesses causes the hash to be replaced from shared memory. The
    state of the iterator in this case is not defined by the Perl
    documentation. Caveat Emptor.

# CREDITS

Thanks to all those with comments or bug fixes, especially

    Maurice Aubrey      <maurice@hevanet.com>
    Stephane Bortzmeyer <bortzmeyer@pasteur.fr>
    Doug MacEachern     <dougm@telebusiness.co.nz>
    Robert Emmery       <roberte@netscape.com>
    Mohammed J. Kabir   <kabir@intevo.com>
    Terry Ewing         <terry@intevo.com>
    Tim Fries           <timf@dicecorp.com>
    Joe Thomas          <jthomas@women.com>
    Paul Makepeace      <Paul.Makepeace@realprogrammers.com>
    Raphael Manfredi    <Raphael_Manfredi@pobox.com>
    Lee Lindley         <Lee.Lindley@bigfoot.com>
    Dave Rolsky         <autarch@urth.org>
    Steve Bertrand      <steveb@cpan.org>

# SEE ALSO

[perltie](https://metacpan.org/pod/perltie), [Storable](https://metacpan.org/pod/Storable), `shmget`, `ipcs`, `ipcrm` and other SysV IPC manual
pages.
