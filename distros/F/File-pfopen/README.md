[![Perl CI](https://github.com/nigelhorne/File-pfopen/actions/workflows/perl-ci.yml/badge.svg)](https://github.com/nigelhorne/File-pfopen/actions/workflows/perl-ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/File-pfopen/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/File-pfopen?branch=master)
[![CPAN](https://img.shields.io/cpan/v/File-pfopen.svg)](https://metacpan.org/release/File-pfopen)

## Name

File::pfopen - Try hard to find a file

## Version

Version 0.04

## Synopsis

Find a configuration file in the first of several places, and read it:

```perl
use File::pfopen 'pfopen';

my $fh = pfopen('/etc/myapp:/usr/local/etc/myapp', 'config', 'yml:json', '<');
if($fh) {
    my @lines = <$fh>;
    close($fh);
}
```

Find out which file was found, by asking for two return values:

```perl
use File::pfopen 'pfopen';

my ($fh, $filename) = pfopen('/etc/myapp:/usr/local/etc/myapp', 'config', 'yml:json', '<');
print "Using $filename\n" if($fh);
```

Build the list of directories as an array, which works the same on every
operating system:

```perl
use File::Spec;
use File::pfopen 'pfopen';

my @dirs = (File::Spec->catdir($ENV{'HOME'}, '.myapp'), File::Spec->tmpdir());
my $fh = pfopen(\@dirs, 'state', 'dat', '<');
```

Use a full filename, with no list of suffixes:

```perl
use File::pfopen 'pfopen';

my $fh = pfopen('/var/tmp:/tmp', 'report.csv', undef, '<');
```

Use drive letters on Windows, where the directories are separated by ';':

```perl
use File::pfopen 'pfopen';

my $fh = pfopen('C:\myapp;D:\shared\myapp', 'config', 'ini', '<');
```

Open a found file to add to it, and read text in UTF-8:

```perl
use File::pfopen 'pfopen';

my $log = pfopen(['/var/log/myapp', '/tmp'], 'activity', 'log', '>>');
my $text = pfopen(['/usr/share/myapp'], 'messages', 'txt', '<:encoding(UTF-8)');
```

## Description

This module has one function, `pfopen`.
You give it a list of directories, a filename, and optionally a list of endings
(called suffixes) for the filename.
It looks for the file in each directory, in order,
and opens the first one that it finds.

For example, with the directories `/etc` and `/tmp`,
the filename `foo` and the suffixes `txt:bin`,
it tries these files, in this order, and stops at the first one that it can open:

```
/etc/foo.txt
/etc/foo.bin
/tmp/foo.txt
/tmp/foo.bin
```

It is similar to the way that a shell uses the `PATH` environment variable to find a program.

The function remembers each file that it finds.
If you ask for the same thing again, it opens the same file again without looking.
See ["COMMON PITFALLS"](#common-pitfalls).

## Subroutines/Methods

### Pfopen($Path, $Prefix, $Suffixes, $Mode)

```perl
my $fh = pfopen($path, $prefix);
my $fh = pfopen($path, $prefix, $suffixes);
my $fh = pfopen($path, $prefix, $suffixes, $mode);
my ($fh, $filename) = pfopen($path, $prefix, $suffixes, $mode);
```

#### Purpose

Look in a list of directories for a file, optionally trying a list of suffixes,
and open the first file that it finds.

It only finds files. It never returns a directory.
It looks in the directories in order.
In each directory, it tries the suffixes in order.
So a file in an earlier directory is used before a file with an earlier suffix.

It remembers each successful search until the program ends.
When it is called again with the same `$path`, `$prefix` and `$suffixes`,
it opens the same file again and does not search.
If that file can no longer be opened, it forgets the file and searches again.
A string and an array reference that give the same directories count as the same `$path`,
so `['/a', '/b']` and `'/a:/b'` share one remembered file.

#### Arguments

- `$path` (required)

    The directories to look in.
    This is one of:

    - A string. The directories are separated by the operating system's path separator.
    This is ':' on UNIX and ';' on Windows, the same as in the `PATH` environment variable.
    Perl stores this character in `$Config{path_sep}`.
    Because Windows uses ';', you can use drive letters, for example `'C:\tmp;D:\data'`.
    - A reference to an array of directories, for example `['/etc', '/tmp']`.
    Use this when a directory name contains the separator character.

    These directories are skipped without an error:
    directories that do not exist, names that are not directories,
    empty strings, `undef` values, and names that contain a NUL character.
    A relative directory, such as `'.'`, is relative to the current directory when `pfopen` is called.

- `$prefix` (required)

    The name of the file to find, without its suffix. For example, `'config'`.
    It must not be empty.
    The name is used exactly as given.
    Characters such as `|`, `<` and `>` have no special meaning.

- `$suffixes` (optional)

    A list of suffixes to try, separated by ':' on all operating systems.
    For example, `'yml:json'` tries `config.yml` and then `config.json`.
    Do not include the dot: `pfopen` adds it.

    If this is not given, or is `undef`, `$prefix` is used as the whole filename.
    If this is an empty string, nothing can be found.

- `$mode` (optional)

    How to open the file. This is the same as the second argument to Perl's `open` function.
    If it is not given, or is false (`undef`, `''` or `0`),
    the file is opened to read and write (`'+<'`).

    Only these modes are allowed:

    ```
    <     read
    >     write (the file is emptied first)
    >>    add to the end of the file
    +<    read and write
    +>    read and write (the file is emptied first)
    +>>   read and add to the end of the file
    ```

    After the mode you can add I/O layers, for example `'<:raw'` or `'<:encoding(UTF-8)'`.
    Other modes, such as the pipe mode `'-|'`, are not allowed,
    so the file that is found can never be run as a program.

#### Returns

- When the file is found and opened, and `pfopen` is called in scalar context
(one return value), it returns the open file handle.
- When the file is found and opened, and `pfopen` is called in list context
(two return values), it returns the open file handle and the full filename that was opened.
The filename is built from the directory, so it is relative if the directory was relative.
- When no file is found, or no file can be opened in `$mode`,
it returns `undef` in scalar context and an empty list in list context.
This also happens when `$prefix` or `$suffixes` contains a NUL character,
because a filename can never contain one.

#### Side Effects

It remembers the filename of each successful search, as described in ["Purpose"](#purpose).
It also forgets a remembered filename when that file can no longer be opened.
In taint mode, a call with any tainted argument always searches,
and doesn't remember what it finds,
so a remembered filename can't hide or add taint.

It does not change `$!`, `$@`, `$_`, or any of its arguments.

#### Errors

It croaks (dies with an error message that gives your file and line number) with:

- `Usage: pfopen($path, $prefix, [$suffixes, [$mode]])`

    when `$path` or `$prefix` is missing or `undef`, or `$prefix` is an empty string.

- `pfopen: path must be a string or an array reference`

    when `$path` is a reference to anything except an array.
    This includes an object that is a blessed array.

- `pfopen: invalid mode '$mode'`

    when `$mode` is not one of the modes listed in ["Arguments"](#arguments), for example `'-|'`.

It does not croak or warn when a file can't be found or can't be opened.

When Perl runs in taint mode (`-T`) and `$path` or `$prefix` is tainted,
a mode that writes, including the default `'+<'`,
dies with Perl's own error `Insecure dependency in open while running with -T switch`.
Use the mode `'<'`, or untaint the arguments first.

#### Usage Example

```perl
use File::pfopen 'pfopen';

my ($fh, $filename) = pfopen('/tmp:/var/tmp:/home/njh/tmp', 'foo', 'txt:bin');
my $fh2 = pfopen('/tmp:/var/tmp:/home/njh/tmp', 'foo', undef, '<');
my $fh3 = pfopen(['/tmp', '/var/tmp'], 'foo', 'txt');
```

#### Api Specification

The arguments are positional.
The schemas are in the format of [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) and [Return::Set](https://metacpan.org/pod/Return%3A%3ASet).
The output schema describes the list that is returned in list context.
In scalar context the return value is the first element of that list, or `undef`.

##### Input

```perl
[
    { name => 'path', type => ['string', 'arrayref'], position => 0 },
    { name => 'prefix', type => 'string', min => 1, position => 1 },
    { name => 'suffixes', type => 'string', optional => 1, position => 2 },
    { name => 'mode', type => 'string', optional => 1, default => '+<', position => 3, matches => qr/\A\+?(?:<|>>?)(?::.*)?\z/s },
]
```

##### Output

```perl
{
    type => 'arrayref',
    min => 0,
    max => 2,
    callback => sub { (scalar(@{$_[0]}) == 0) || ((scalar(@{$_[0]}) == 2) && defined(Scalar::Util::openhandle($_[0]->[0])) && !ref($_[0]->[1])) },
}
```

## Common Pitfalls

- **The default mode is read and write.**
If you only want to read, give the mode `'<'`.
Without it, a file that you can read but not write is skipped,
and `pfopen` returns nothing even though the file exists.
- **The mode is the fourth argument, not the third.**
To give a mode without suffixes, pass `undef` as the suffixes:
`pfopen($path, 'foo.txt', undef, '<')`.
`pfopen($path, 'foo.txt', '<')` looks for a file called `foo.txt.<`.
- **The modes `'>'` and `'+>'` empty the file.**
`pfopen` only finds files that already exist,
so these modes always delete the contents of an existing file.
Use `'>>'` to add to the end of a file instead.
- **Found files are remembered.**
After a file is found, a later call with the same arguments opens the same file without searching.
If you then create the file in an earlier directory, or change to a different current directory,
the remembered file is still used, as long as it can still be opened.
- **Use ';' between directories on Windows.**
On Windows the separator is ';', not ':', so `'C:\a:C:\b'` is one directory, not two.
To write code that works on all operating systems, pass an array reference.
- **Suffixes are always separated by ':'.**
This is true on Windows too. Do not include the dot: `'.txt'` looks for `foo..txt`.
- **`undef` and an empty string mean different things.**
`undef` suffixes mean "use `$prefix` as the whole filename".
An empty string of suffixes means "try no suffixes", so nothing is found.
`undef` and empty directories in `$path` are skipped.
A missing `$path` or `$prefix` is an error.
- **Check the return value before you use it.**
Nothing is found when the file is missing, unreadable, a directory, or can't be opened in `$mode`.
There is no warning, and `$!` is not set, so you can't tell these cases apart.

    ```perl
    my ($fh, $filename) = pfopen($path, 'foo', 'txt', '<');
    die "Can't find foo.txt in $path" unless($fh);
    ```

- **`$prefix` can contain directories.**
`pfopen('/etc', '../tmp/foo')` looks in `/etc/../tmp`.
If `$prefix` comes from a user, check it before you call `pfopen`.

## Encoding

- **Directory names, `$prefix` and `$suffixes`**

    These are filenames, and on UNIX a filename is a string of bytes.
    Names in any language, including emojis, work when you pass them as UTF-8 encoded bytes,
    which is how most UNIX systems store filenames:

    ```perl
    use Encode qw(encode);
    my $fh = pfopen($dir, encode('UTF-8', $name), 'txt', '<');
    ```

    If you pass a Perl character string instead,
    the result depends on how Perl stores the string internally.
    For example, `"caf\x{e9}"` may or may not find `café.txt`.
    Encode the name to make the result predictable.

    On Windows, Perl's `open` function uses the system's "ANSI" code page for filenames,
    so characters that are not in that code page, such as emojis, can't be used in names there.

    A NUL character can't be in any name. See ["Returns"](#returns).

- **`$mode`**

    The mode itself must be ASCII.
    The layer in the mode can be any layer that Perl supports.

- **The contents of the file**

    `pfopen` does not read the file, so the contents can be in any encoding.
    To read or write text as characters, add a layer to the mode,
    for example `'<:encoding(UTF-8)'`.
    Then all of Unicode, including emojis, is read and written correctly.
    Without a layer, the file handle reads and writes bytes.

## Bugs

In taint mode, writing to a file with a tainted name dies. See ["Errors"](#errors).

Would be better if the mode and suffixes options were the other way around, but it's too late to change that now.

Please report any bugs or feature requests to `bug-file-pfopen at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-pfopen](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-pfopen).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

## Support

You can find documentation for this module with the perldoc command.

```
perldoc File::pfopen
```

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/File-pfopen](https://metacpan.org/release/File-pfopen)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=File-pfopen](https://rt.cpan.org/NoAuth/Bugs.html?Dist=File-pfopen)

- CPANTS

    [http://cpants.cpanauthors.org/dist/File-pfopen](http://cpants.cpanauthors.org/dist/File-pfopen)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=File-pfopen](http://matrix.cpantesters.org/?dist=File-pfopen)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=File::pfopen](http://deps.cpantesters.org/?module=File::pfopen)

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Formal Specification

This section describes `pfopen` in the Z notation.
You do not need to read it to use the module.

### Pfopen

```
[PATH, NAME, HANDLE]

FILEMODE == { "<", ">", ">>", "+<", "+>", "+>>" }
MODE == { m : seq CHAR | (∃ f : FILEMODE; l : seq CHAR • m = f ⁀ l ∧ (l = ⟨⟩ ∨ head l = ':')) }
KEY == NAME × seq NAME × seq PATH

isFile, readable : ℙ PATH
opens : PATH ↔ MODE

┌─ PfopenState ───────────────────────────────────────────────────
│ cache : KEY ⇸ PATH
└─────────────────────────────────────────────────────────────────

┌─ InitPfopenState ───────────────────────────────────────────────
│ PfopenState'
├─────────────────────────────────────────────────────────────────
│ cache' = ∅
└─────────────────────────────────────────────────────────────────

┌─ PfopenArgs ────────────────────────────────────────────────────
│ dirs? : seq PATH
│ prefix? : NAME
│ suffixes? : seq NAME ∪ {⊥}
│ mode? : MODE
│ key : KEY
│ candidates : seq PATH
│ usable : ℙ PATH
├─────────────────────────────────────────────────────────────────
│ prefix? ≠ ⟨⟩
│ '\0' ∉ ran prefix?
│ key = (prefix?, suffixes?, dirs?)
│ suffixes? = ⊥ ⇒ candidates = ⟨ d / prefix? | d ← dirs? ⟩
│ suffixes? ≠ ⊥ ⇒ candidates = ⟨ d / (prefix? ⁀ "." ⁀ s) | d ← dirs?, s ← suffixes? ⟩
│ usable = { c : PATH | c ∈ isFile ∧ c ∈ readable ∧ (c, mode?) ∈ opens }
└─────────────────────────────────────────────────────────────────

┌─ PfopenRemembered ──────────────────────────────────────────────
│ ΞPfopenState
│ PfopenArgs
│ result! : HANDLE × PATH
├─────────────────────────────────────────────────────────────────
│ key ∈ dom cache ∧ cache(key) ∈ usable
│ second(result!) = cache(key)
└─────────────────────────────────────────────────────────────────

┌─ PfopenFound ───────────────────────────────────────────────────
│ ΔPfopenState
│ PfopenArgs
│ result! : HANDLE × PATH
├─────────────────────────────────────────────────────────────────
│ ¬(key ∈ dom cache ∧ cache(key) ∈ usable)
│ ran candidates ∩ usable ≠ ∅
│ second(result!) = head(candidates ↾ usable)
│ cache' = cache ⊕ { key ↦ second(result!) }
└─────────────────────────────────────────────────────────────────

┌─ PfopenNotFound ────────────────────────────────────────────────
│ ΔPfopenState
│ PfopenArgs
│ result! : {∅}
├─────────────────────────────────────────────────────────────────
│ ¬(key ∈ dom cache ∧ cache(key) ∈ usable)
│ ran candidates ∩ usable = ∅
│ cache' = {key} ⩤ cache
└─────────────────────────────────────────────────────────────────

┌─ PfopenError ───────────────────────────────────────────────────
│ ΞPfopenState
│ path?, prefix?, mode? : seq CHAR ∪ {⊥}
│ error! : seq CHAR
├─────────────────────────────────────────────────────────────────
│ (path? = ⊥ ∨ prefix? = ⊥ ∨ prefix? = ⟨⟩)
│     ⇒ error! = "Usage: pfopen($path, $prefix, [$suffixes, [$mode]])"
│ path? is a reference that is not an unblessed array
│     ⇒ error! = "pfopen: path must be a string or an array reference"
│ mode? ∉ MODE ∪ {⊥, "", "0"}
│     ⇒ error! = "pfopen: invalid mode '" ⁀ mode? ⁀ "'"
└─────────────────────────────────────────────────────────────────

pfopen ≙ PfopenError ∨ PfopenRemembered ∨ PfopenFound ∨ PfopenNotFound
```

The errors are checked in the order shown, and the first one that applies is raised.
A `$prefix` or `$suffixes` containing NUL gives `PfopenNotFound` without changing `cache`.
In taint mode, a call with a tainted argument behaves as if `key` were not in `dom cache`, and `cache' = cache`.

## State Diagram

`pfopen` keeps one piece of state for each different set of arguments (`$path`, `$prefix`, `$suffixes`):
either it remembers a filename for them, or it doesn't.
All lookups start in the FORGOTTEN state when the program starts.
The labels T1 to T7 are explained in the table below.

```
                program starts
                      |
                      v
               +-------------+
        +----->|  FORGOTTEN  |<-----+
        |      +-------------+      |
        |        |    |    |        |
        +--------+    |    |        |
        T1, T2        |    |        |
                      |    | T3     |
                      |    v        |
               +-------------+      |
        +----->| REMEMBERED  |------+
        |      +-------------+   T7
        |        |    |
        +--------+    |
        T4, T5, T6    |

Label  From        Trigger (a call to pfopen)       Action                       To
-----  ----------  -------------------------------  ---------------------------  ----------
T1     FORGOTTEN   bad argument                     croak with an error          FORGOTTEN
T2     FORGOTTEN   search finds no usable file      return nothing               FORGOTTEN
T3     FORGOTTEN   search finds a usable file       open it, remember the        REMEMBERED
                                                    filename, return the handle
T4     REMEMBERED  bad argument                     croak with an error          REMEMBERED
T5     REMEMBERED  remembered file opens            open it, return the handle;  REMEMBERED
                                                    don't search
T6     REMEMBERED  remembered file fails, and a     open it, remember the new    REMEMBERED
                   search finds another usable file filename, return the handle
T7     REMEMBERED  remembered file fails, and a     forget the filename,         FORGOTTEN
                   search finds no usable file      return nothing
```

"Return nothing" means `undef` in scalar context and an empty list in list context.

Notes:

- "Bad argument" means one of the croaks in ["Errors"](#errors).
It is checked before anything else, so it never changes the state.
- A `$prefix` or `$suffixes` containing a NUL character returns nothing in either state, and doesn't change the state.
- In taint mode, a call with a tainted argument always searches, as if in the FORGOTTEN state, and never changes the state.
- "Fails" means the remembered file is gone, is now a directory, or can't be opened in the `$mode` of this call.
- There is no way to forget all the remembered files, except by ending the program.

## Licence and Copyright

Copyright 2017-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
