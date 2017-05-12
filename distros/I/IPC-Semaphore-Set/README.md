# IPC::Semaphore::Set

[![Build Status](https://travis-ci.org/shaneutt/ipc-semaphore-set.svg?branch=master)](https://travis-ci.org/shaneutt/ipc-semaphore-set.svg?branch=master)

[POSIX semaphores](https://linux.die.net/man/7/sem_overview) allow processes and threads to synchronize their actions.

This module abstracts away POSIX semaphores into an `IPC::Semaphore::Set` object, which is a set of resources that provides mutexes for a key.

Installation
---

You can install this module from CPAN directly:

```bash
sudo cpan -i IPC::Semaphore::Set
```

Or manually build and install the module via the repository with [Dist::Zilla](http://dzil.org/):

```bash
cpan -i Dist::Zilla Dist::Zilla::Plugin::VersionFromModule Dist::Zilla::Plugin::AutoPrereqs Dist::Zilla::PluginBundle::Basic
dzil test
dzil install
```

# Synopsis

## Basics

In the simplest case you may want to provide a single mutex for a key:

```perl
my $semset = IPC::Semaphore::Set->new(key_name => 'my_lock_name');
```

In the above example, `my_lock_name` refers to some arbitrary resource that my system processes need access to, but should only allow one process to use it at a time.

The `$semset` object above will provide a single resource that can be locked once (this is the default configuration).

We can wait for a lock and then do our work with the following line:

```perl
$semset->resource->lockWait;
# ... do our work
```

Resource locks are released when the `$semset` object goes out of scope, or you can explicitly unlock in your code (TODO):

```perl
# ... our work is done
$semset->resource->unlock;
```

## Multiple Resources and Availability

For a more complex use case, let's imagine I have five arbitrary devices connected to my current computer

and each of those devices has ten channels for whatever work it is they do.

I could use `IPC::Semaphore::Set` to manage locking for those devices from local programs on my machine.

For instance I might create the following object:

```perl
my $semset = IPC::Semaphore::Set->new(
    key_name     => 'my_device',
    resources    => 5,
    availability => 10,
);
```

This would create a `$semset` object that would represent my five devices and allow those devices each ten simultaneous locks.

I could then lock several resources as many times as I need and do my work with the resource elsewhere:

```perl
$semset->resource(0)->lockWait;
$semset->resource(1)->lockWait;
$semset->resource(1)->lockWait;
# ... do our work
```

Keep in mind that the `key_name` provided is only for your benefit and that the locks here are arbitrary.

This module just provides mutexes so that your applications/processes/threads can keep track of and coordinate resource limitations with each other.

