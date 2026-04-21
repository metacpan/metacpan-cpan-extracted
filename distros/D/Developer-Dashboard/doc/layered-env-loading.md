# Layered Env Loading

Layered env loading follows the same DD-OOP-LAYERS contract as config,
bookmarks, collectors, and custom CLI hooks.

## Runtime env files

When `dashboard ...` starts, it loads env files from root to leaf before it
executes hooks, built-in helpers, custom commands, or skill dispatch.

The runtime order is:

1. `<root>/.env`
2. `<root>/.env.pl`
3. each deeper ancestor directory `.env`
4. each deeper ancestor directory `.env.pl`
5. each participating `.developer-dashboard/.env`
6. each participating `.developer-dashboard/.env.pl`

Later files win. A deeper layer can override a key from an earlier layer by
setting the same variable again.

Plain `.env` files must use `KEY=VALUE` lines, and dashboard always loads
`.env` before `.env.pl` at the same directory.

Plain `.env` parsing supports:

- blank lines
- whole-line `#` comments
- whole-line `//` comments
- `/* ... */` block comments, including multi-line blocks
- leading `~` expansion to `$HOME`
- `$NAME` expansion from the current effective environment
- `${NAME:-default}` fallback expansion
- `${Namespace::function():-default}` fallback expansion through a static Perl function

Expansion can read from system env, values loaded from earlier layers, and
values assigned by earlier lines in the same `.env` file. Malformed lines,
invalid env names, missing functions, and unterminated block comments fail the
command explicitly.

`.env.pl` files are required directly and can update `%ENV` programmatically.

## Skill env files

Skill env files only load when a skill command or a skill hook is running.
Non-skill commands do not load skill-local env files.

For a running skill, dashboard first loads the normal runtime env chain and
then loads each participating skill root from the base skill layer to the
deepest matching child skill layer:

1. `<skill-root>/.env`
2. `<skill-root>/.env.pl`

That lets a nested skill override a shared runtime key only inside the skill
execution path.

Example `.env`:

```dotenv
# root defaults
ROOT_CACHE=~/cache
TOKEN=${ACCESS_TOKEN:-anonymous}
MESSAGE=${Local::Env::Helper::message():-hello}

/*
later layers can still override any of these
*/
CHAINED=$ROOT_CACHE/$TOKEN
```

## Perl env audit API

Use `Developer::Dashboard::EnvAudit` when Perl code needs the effective source
file for a dashboard-loaded env key.

Single key:

```perl
use Developer::Dashboard::EnvAudit;

my $entry = Developer::Dashboard::EnvAudit->key('FOO');
```

Full inventory:

```perl
my $all = Developer::Dashboard::EnvAudit->keys;
```

Each recorded entry looks like:

```perl
{
    value   => 'bar',
    envfile => '/full/path/to/.env',
}
```

Only dashboard-managed env files are recorded. System env keys that were not
set by a loaded `.env` or `.env.pl` file return `undef`.
