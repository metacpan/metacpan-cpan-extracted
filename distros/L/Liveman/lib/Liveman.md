# NAME

Liveman - markdown compiller to test and pod

# VERSION

2.0

# SYNOPSIS

File lib/Example.md:
```markdown
Twice two:
\```perl
2*2  # -> 2+2
\```
```

Test:
```perl
use Liveman;

my $liveman = Liveman->new(prove => 1);

# compile lib/Example.md file to t/example.t and added pod to lib/Example.pm
$liveman->transform("lib/Example.md");

$liveman->{count}   # => 1
-f "t/example.t"    # => 1
-f "lib/Example.pm" # => 1

# compile all lib/**.md files with a modification time longer than their corresponding test files (t/**.t)
$liveman->transforms;
$liveman->{count}   # => 0

# compile without check modification time
Liveman->new(compile_force => 1)->transforms->{count} # => 1

# start tests with yath
my $yath_return_code = $liveman->tests->{exit_code};

$yath_return_code           # => 0
-f "cover_db/coverage.html" # => 1

# limit liveman to these files for operations transforms and tests (without cover)
my $liveman2 = Liveman->new(files => [], force_compile => 1);
```

# DESCRIPION

The problem with modern projects is that the documentation is disconnected from testing.
This means that the examples in the documentation may not work, and the documentation itself may lag behind the code.

Liveman compile `lib/**`.md files to `t/**.t` files
and it added pod-documentation to section `__END__` to `lib/**.pm` files.

Use `liveman` command for compile the documentation to the tests in catalog of your project and starts the tests:

    liveman

Run it with coverage.

Option `-o` open coverage in browser (coverage file: `cover_db/coverage.html`).

Liveman replace `our $VERSION = "...";` in `lib/**.pm` from `lib/**.md` if it exists in pm and in md.

If exists file **minil.toml**, then Liveman read `name` from it, and copy file with this name and extension `.md` to README.md.

## TYPES OF TESTS

Section codes `noname` or `perl` writes as code to `t/**.t`-file. And comment with arrow translates on test from module `Test::More`.

The test name set as the code-line.

### `is`

Compare two expressions for equivalence:

```perl
"hi!" # -> "hi" . "!"
"hi!" # → "hi" . "!"
```

### `is_deeply`

Compare two expressions for structures:

```perl
"hi!" # --> "hi" . "!"
"hi!" # ⟶ "hi" . "!"
```

### `is` with extrapolate-string

Compare expression with extrapolate-string:

```perl
my $exclamation = "!";
"hi!2" # => hi${exclamation}2
"hi!2" # ⇒ hi${exclamation}2
```

### `is` with nonextrapolate-string

Compare expression with nonextrapolate-string:

```perl
'hi${exclamation}3' # \> hi${exclamation}3
'hi${exclamation}3' # ↦ hi${exclamation}3
```

### `like`

It check a regular expression included in the expression:

```perl
'abbc' # ~> b+
'abc'  # ↬ b+
```

### `unlike`

It check a regular expression excluded in the expression:

```perl
'ac' # <~ b+
'ac' # ↫ b+
```

## EMBEDDING FILES

Each test is executed in a temporary directory, which is erased and created when the test is run.

This directory format is /tmp/.liveman/*project*/*path-to-test*/.

Code section in md-file prefixed line **File `path`:** write to file in rintime testing.

Code section in md-file prefixed line **File `path` is:** will be compared with the file by the method `Test::More::is`.

File experiment/test.txt:
```text
hi!
```

File experiment/test.txt is:
```text
hi!
```

**Attention!** An empty string between the prefix and the code is not allowed!

Prefixes maybe on russan: `Файл path:` and `Файл path является:`.

# METHODS

## new (%param)

Constructor. Has arguments:

1. `files` (array_ref) — list of md-files for methods `transforms` and `tests`.
1. `open` (boolean) — open coverage in browser. If is **opera** browser — open in it. Else — open via `xdg-open`.
1. `force_compile` (boolean) — do not check the md-files modification time.
1. `options` — add options in command line to yath or prove.
1. `prove` — use prove, but use'nt yath.

## test_path ($md_path)

Get the path to the `t/**.t`-file from the path to the `lib/**.md`-file:

```perl
Liveman->new->test_path("lib/PathFix/RestFix.md") # => t/path-fix/rest-fix.t
```

## transform ($md_path, [$test_path])

Compile `lib/**.md`-file to `t/**.t`-file.

And method `transform` replace the **pod**-documentation in section `__END__` in `lib/**.pm`-file. And create `lib/**.pm`-file if it not exists.

File lib/Example.pm is:
```perl
package Example;

1;

__END__

=encoding utf-8

Twice two:

	2*2  # -> 2+2

```

File `lib/Example.pm` was created from file `lib/Example.md` described in section `SINOPSIS` in this document.

## transforms ()

Compile `lib/**.md`-files to `t/**.t`-files.

All if `$self->{files}` is empty, or `$self->{files}`.

## tests ()

Tests `t/**.t`-files.

All if `$self->{files}` is empty, or `$self->{files}` only.

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Liveman module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
