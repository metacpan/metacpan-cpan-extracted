# File::Util::SecureDir

A process-wide, set-once directory security filter.

Modules that build search paths from directories they did not choose
(`@INC`, `PERL5LIB`, `LD_LIBRARY_PATH`) pass the candidates through
`filter_dirs` and use only what comes back. The #! code defines the
security level once; nothing loaded afterwards can relax it.

## Usage

In any module with directories to check, no arguments:

```perl
use File::Util::SecureDir;

state $secure = File::Util::SecureDir->new;     # the singleton.
my    @clean  = $secure->filter_dirs( @candidates );

say 'filtering with ' . $secure->filter;        # name only, read-only.
```

In the #! code, only to pick something other than the default. It must
come before any module that filters directories:

```perl
#!/usr/bin/env perl
use v5.36;

use File::Util::SecureDir qw( filter=same_owner );
use FindBin::libs;
```

If the #! code chooses nothing, the first call to `filter_dirs` installs
the default. A `filter=NAME` that arrives after that croaks instead of
being ignored.

`verbose[=0|1]` and `debug[=0|1]` can be given by any module at any time
and can be reset. They report on STDERR.

## Filters

From least to most restrictive:

| Name             | Rejects                                                          |
|------------------|------------------------------------------------------------------|
| `all`            | nothing (testing only)                                           |
| `other_no_write` | world-writable directories (the default)                        |
| `group_no_write` | group- or world-writable directories                             |
| `same_owner`     | the above, plus owners other than the effective user or root     |

On Win32 the same levels are evaluated from the directory's security
descriptor; the effective user is the user SID of the process token, with
an automatic, warned fallback to the login-name lookup if the token cannot
be read. On Unix the owner is compared with the effective uid (`$>`), so
sudo and setuid programs check the user they are actually running as.

## Contract

- The filter is assigned once per process and cannot be changed or replaced.
- Only the #! code can choose it; any other caller supplying `filter`
  croaks.
- Errors reading a directory reject it (fail closed).

## Limits

- Only the directory itself is checked, not its parents or its contents.
- The check is not atomic with the use of the directory.
- Code in the same interpreter can always redefine subroutines; the
  guarantee is that the API cannot weaken the filter.
- Unix permission bits only; ACLs on Unix are ignored.

See the POD for details.

## Installation

```
perl Makefile.PL
make
make test
make install
```

Sources and tests live under `version/`; `Makefile.PL` copies the
directory matching the running perl into `lib/` and `t/`. Perl v5.36 or
later is required. On Win32, `Win32` and `Win32::API` are also needed.

## Testing

Each test file checks one feature and depends only on features tested
before it. The filter is set once per process, so each file ends in one
filter. Win32-only tests skip elsewhere; two tests in
`t/14-same_owner-euid.t` need root and are skipped otherwise (run them
with `sudo prove t/14-same_owner-euid.t`).

## Author and license

Steven Lembark <lembark@wrkhors.com>

Same terms as Perl v5.36 or any later version of Perl.
