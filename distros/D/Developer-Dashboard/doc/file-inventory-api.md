# File Inventory API

Developer Dashboard now exposes a first-class file alias surface alongside the
existing path alias surface.

## CLI commands

Use these commands for named files:

```bash
d2 files
d2 file list
d2 file add notes ~/notes.txt
d2 file resolve notes
d2 file del notes
```

Behavior:

- `d2 files` prints the full built-in plus configured file inventory
- `d2 file list` prints only configured named file aliases
- `d2 file add` writes to the deepest participating config layer
- `d2 file add` stores home-local targets as `$HOME/...` for portability
- `d2 file del` is idempotent for missing aliases

## Perl API

Use these public modules:

- `Developer::Dashboard::File`
- `Developer::Dashboard::FileRegistry`

Examples:

```perl
use Developer::Dashboard::File;

my $all = Developer::Dashboard::File->all;
my $config_path = Developer::Dashboard::File->global_config;
my $notes_path = Developer::Dashboard::File->notes;
```

`Developer::Dashboard::File` mirrors the public convenience role that
`Developer::Dashboard::Folder` already plays for paths. It resolves built-in
file names, config-backed file aliases, and direct reads or writes through one
public wrapper while leaving the deeper inventory rules in
`Developer::Dashboard::FileRegistry`.
