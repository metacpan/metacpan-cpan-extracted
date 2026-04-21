# Public Path Inventory API

Use the public path inventory methods when Perl code needs the same resolved
path hashes printed by the CLI.

Full `dashboard paths` payload:

```perl
use Developer::Dashboard::PathRegistry;

my $paths = Developer::Dashboard::PathRegistry->new(
    home => $ENV{HOME},
);

my $all = $paths->all_paths;
```

Compatibility wrapper:

```perl
use Developer::Dashboard::Folder;

my $all = Developer::Dashboard::Folder->all;
```

Convenience constructor when code wants a fresh registry object instead of the
raw hash:

```perl
use Developer::Dashboard::PathRegistry;

my $paths = Developer::Dashboard::PathRegistry->new_from_all_folders;
```

Collector convenience constructor using the same path source:

```perl
use Developer::Dashboard::Collector;

my $collectors = Developer::Dashboard::Collector->new_from_all_folders;
```

The hashed temp-backed `state_root`, `collectors_root`, `indicators_root`, and
`sessions_root` paths are recreated automatically if a reboot or temp cleanup
removes them. The path registry also rewrites the matching `runtime.json`
metadata when it recreates one of those hashed state roots, so later runtime
lookups do not keep using stale missing directories.

Env provenance audit for dashboard-managed `.env` and `.env.pl` files:

```perl
use Developer::Dashboard::EnvAudit;

my $one = Developer::Dashboard::EnvAudit->key('FOO');
my $all = Developer::Dashboard::EnvAudit->keys;
```

Shorter alias-style inventory matching `dashboard path list`:

```perl
my $aliases = $paths->all_path_aliases;
```

These methods are the public library entrypoints. Avoid reaching into
`Developer::Dashboard::CLI::Paths` private helper functions or rebuilding the
hash shape manually. Use `Developer::Dashboard::EnvAudit` when you need env
provenance rather than path inventory.
