# Inotify design

`Linux::Event::Kernel::Inotify` is the Linux-native filesystem notification
resource. It exposes inotify semantics directly rather than emulating a
portable polling watcher.

## Ownership model

One Inotify object owns one nonblocking, close-on-exec inotify fd and one
internal Loop registration. It may contain any number of logical
`Linux::Event::Kernel::Inotify::Watch` subscriptions.

Inotify follows the ordinary Linux::Event attachment contract:

```perl
my $inotify = Linux::Event::Kernel::Inotify->new;
my $watch = $inotify->watch(
    "log.txt",
    on_modify => sub ($event) {
        say $event->path . " changed";
    },
);

$loop->add($inotify);
```

The equivalent immediate-attachment form is:

```perl
my $inotify = Linux::Event::Kernel::Inotify->new(loop => $loop);
```

A watch created while the parent is detached is only a Perl watch
specification. No inotify instance or kernel watch exists until Loop
attachment succeeds. A watch created after attachment is installed
synchronously before `watch()` returns.

An attached Inotify object with no child watches remains a live Loop resource.
This permits applications to attach the notification source first and add
subscriptions later.

Attachment is transactional. If any pending watch cannot be installed, all
temporary native state is released, already-installed pending watches return to
their pending state, and the parent remains unattached.

Like other attachable Linux::Event resources, successful attachment happens
only once. `close()` is terminal; a closed Inotify object cannot be attached
again.

## Logical watches and shared kernel watches

Inotify is inode-based. Multiple pathnames, including hard links, can therefore
refer to one kernel watch descriptor.

Linux::Event preserves independent Perl subscriptions even when Linux shares
the native watch:

```perl
my $a = $inotify->watch(
    "log.txt",
    on_modify => sub ($event) { ... },
);

my $b = $inotify->watch(
    "log-link.txt",
    on_close_write => sub ($event) { ... },
);
```

Each call returns a distinct Watch object with its own path and callbacks. The
parent unions their requested event masks onto the shared native watch and fans
each kernel record out only to logical subscriptions interested in that record.

New watches use `IN_MASK_CREATE` first so a new subscription cannot
accidentally replace the mask of an inode already watched by the same inotify
instance. Duplicate inode subscriptions then enter the explicit sharing path.

Cancelling one logical Watch removes it from the shared group and recomputes the
remaining union. When a surviving pathname still resolves to the watched inode,
the native mask is replaced with that smaller union. If all surviving aliases
have stopped naming the original inode, Linux offers no descriptor-only mask
replacement operation; Linux::Event safely keeps the native superset while
logical dispatch continues filtering against the surviving subscriptions.

`excl_unlink` changes native delivery semantics for the shared inode and must
therefore agree across logical subscriptions sharing one native descriptor.
`only_dir` and `dont_follow` are path-resolution controls applied when a
watch is installed.

## Watch callbacks

Specific callbacks define the ordinary event mask:

```text
on_access
on_modify
on_attrib
on_close_write
on_close_nowrite
on_open
on_moved_from
on_moved_to
on_create
on_delete
on_delete_self
on_move_self
```

`on_event` is an optional catch-all. When one or more ordinary specific
callbacks are supplied, those callbacks define the native event mask and
`on_event` sees the same delivered records. When `on_event` is the only
ordinary callback, Linux::Event requests `IN_ALL_EVENTS`.

`on_unmount` and `on_ignored` are lifecycle callbacks. They do not establish
an ordinary watch mask by themselves.

For one kernel record, matching specific callbacks execute in this fixed order:

```text
on_create
on_open
on_access
on_modify
on_attrib
on_close_write
on_close_nowrite
on_moved_from
on_moved_to
on_move_self
on_delete
on_delete_self
on_unmount
on_ignored
on_event
```

The same Event object is passed to every callback for one logical Watch and
one kernel record. The first exception stops later callbacks for that logical
record and propagates through the active Loop driver.

Callbacks may cancel their own Watch, cancel another Watch, add a new Watch, or
close the parent. Dispatch rechecks state after every callback, so terminal
objects receive no later callbacks from the current record.

## Event values

`Linux::Event::Kernel::Inotify::Event` is an immutable value with:

```perl
$event->watch;
$event->name;
$event->path;
$event->mask;
$event->cookie;
$event->is_directory;
```

For a directory watch, `name` is the child name supplied by Linux and
`path` is that name composed with the logical Watch path. For an event about
the watched object itself, `name` is undefined and `path` is the captured
Watch path.

Relative Watch paths are made absolute when `watch()` is called. A later
`chdir` therefore cannot retarget a pending watch.

The raw mask is preserved for advanced consumers. `IN_ISDIR` is metadata and
is exposed through `is_directory`; it is not a separate callback.

Rename pairing remains application policy. `IN_MOVED_FROM` and
`IN_MOVED_TO` events preserve the kernel cookie so a higher layer can pair
them when useful. Core does not delay records while waiting for a possible
partner.

Linux may coalesce successive identical unread inotify events. Linux::Event
does not synthesize records to undo that kernel behavior; callbacks describe
the decoded records the kernel actually supplied.

A native watch follows the filesystem object selected when the watch is
installed, not an abstract pathname slot. Replacing a watched pathname with a
new inode does not silently retarget the Watch. Move/delete/invalidation events
describe the original watched object, and higher-level code may explicitly
install a new Watch when its application policy requires following a pathname.
The Event `path` remains the logical absolute path captured by the Watch; it
is not recomputed by probing the filesystem after each event.

## Cancellation and invalidation

A child Watch uses:

```perl
$watch->cancel;
```

Cancellation is idempotent and immediately terminal. Once it returns, no later
callback can target that Watch. In particular, the `IN_IGNORED` generated by
`inotify_rm_watch()` is internal confirmation of an application-requested
removal and is not delivered to the cancelled object.

If Linux invalidates an active watch because the object is deleted or its
filesystem is unmounted, the Watch remains active while the corresponding
lifecycle record is dispatched. `on_ignored`, followed by `on_event` when
configured, may therefore observe the final Event. The Watch then becomes
terminal with state `ignored`.

The parent uses:

```perl
$inotify->close;
```

Parent close cancels its Loop registration, closes the inotify fd, releases all
logical subscriptions, and makes every child terminal without delivering
callbacks.

## Overflow and source errors

`IN_Q_OVERFLOW` belongs to the inotify instance rather than a child watch
(`wd == -1`). It is delivered through:

```perl
on_overflow => sub ($inotify) { ... }
```

If no overflow callback exists, Linux::Event raises an exception rather than
silently accepting lost filesystem state. The inotify source itself remains
usable so the application can rebuild higher-level state and continue.

Fatal source failures use:

```perl
on_error => sub ($inotify, $error) { ... }
```

After `on_error` returns or throws, the parent is closed.

## Fairness

The XS reader decodes one bounded native buffer at a time. Perl dispatch then
examines at most 256 decoded records in one turn. Remaining decoded records are
retained and resumed through `Loop->defer()`.

This keeps large filesystem bursts from monopolizing one readiness callback
while preserving record order and exact-once logical dispatch.

## Scope boundaries

Core inotify support is deliberately primitive and composable:

- it does not recursively watch directory trees;
- it does not synthesize rename pairs;
- it does not rescan filesystem state after overflow;
- it does not poll with `stat()`;
- it does not turn one Watch into a separate Loop registration.

Recursive tree management, state reconciliation, and other filesystem policy
belong above this resource.

## Introspection

The parent is one managed public Loop resource with introspection type
`inotify`. `inspect()` exposes its source fd and current logical watch count.
Child Watch and Event objects are not separate Loop resources.

The internal inotify fd is an internal registration, so it contributes to native
resource counts but does not appear as a duplicate public registration or
liveness reason.
