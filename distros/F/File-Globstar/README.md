# File-Globstar

This library implements globbing with support for "**" in Perl.

Two consecutive asterisks stand for all files and directories in the
current directory and all of its descendants.

See [File::Globstar](https://github.com/gflohr/File-Globstar/blob/master/lib/File/Globstar.pod) for more information.

The library also contains [File::Globstar::ListMatch](https://github.com/gflohr/File-Globstar/blob/master/lib/File/Globstar/ListMatch.pod), a module that implements matching against lists of patterns in the style of [gitignore](https://git-scm.com/docs/gitignore).

## Installation

Via CPAN:

```
$ perl -MCPAN -e install 'File::Globstar'
```

From source:

```
$ perl Build.PL
Created MYMETA.yml and MYMETA.json
Creating new 'Build' script for 'File-Globstar' version '0.1'
$ ./Build
$ ./Build install
```

From source with "make":

```
$ git clone https://github.com/gflohr/File-Globstar.git
$ cd File-Globstar
$ perl Makefile.PL
$ make
$ make install
```

## Usage

```perl
use File::Globstar qw(globstar fnmatchstar);

@files = globstar '**/*.css';
@files = globstar 'css/**/*.css';
@files = globstar 'scss/**';

print "Match!\n" if fnmatchstar '*.pl', 'hello.pl';
print "Case-insensitive match!\n" 
    if fnmatchstar '*.pl', 'Makefile.PL', ignoreCase => 1;

$re = File::Globstar::translatestar('**/*.css');

    use File::Globstar::ListMatch;

# Parse from file.
$matcher = File::Globstar::ListMatch('.gitignore', 
                                     ignoreCase => 1);

# Parse from file handle.
$matcher = File::Globstar::ListMatch(STDIN, ignoreCase => 0);

# Parse list of patterns.  Comments and blank lines are not
# stripped!
$matcher = File::Globstar::ListMatch([
    'src/**/*.o',
    '.*',
    '!.gitignore'
], filename => 'exclude.txt');

# Parse string.
$patterns = <<EOF;
# Ignore all compiled object files.
src/**/*.o
# Ignore all hidden files.
'.*'
# But not this one.
'.gitignore'
EOF
$matcher = File::Globstar::ListMatch(\$pattern);

$filename = 'path/to/hello.o';
if ($matcher->match($filename)) {
    print "Ignore '$filename'.\n";
}
```

See [File::Globstar](https://github.com/gflohr/File-Globstar/blob/master/lib/File/Globstar.pod) and [File::Globstar::ListMatch](https://github.com/gflohr/File-Globstar/blob/master/lib/File/Globstar/ListMatch.pod) for more information!

## Bugs

Please report bugs at
[https://github.com/gflohr/File-Globstar/issues](https://github.com/gflohr/File-Globstar/issues)

## Copyright

Copyright (C) 2016-2017, Guido Flohr, <guido.flohr@cantanea.com>,
all rights reserved.

