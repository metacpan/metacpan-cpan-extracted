#!perl -T

use Test::More;
use File::Spec;

BEGIN {
    use_ok('File::PlainPath', qw(path to_path));
}

is(path('foo'), File::Spec->catfile('foo'),
    'Make path from a single directory/file name');

is(path('foo/bar'), File::Spec->catfile('foo', 'bar'),
    'Make path with the default separator');
is(path('foo/bar\\baz'), File::Spec->catfile('foo', 'bar\\baz'),
    'Make path with backslash in file name');
is(path('dir', 'foo/bar'), File::Spec->catfile('dir', 'foo', 'bar'),
    'Make path with multiple components');
is(path('dir/subdir', 'foo/bar'), File::Spec->catfile('dir', 'subdir', 'foo',
    'bar'), 'Make path with multiple components');

# Set backslash as directory separator
use File::PlainPath -separator => '\\';

is(path('foo\\bar'), File::Spec->catfile('foo', 'bar'),
    'Make path with separator set to "\\"');
is(path('dir\\subdir', 'foo\\bar'), File::Spec->catfile('dir', 'subdir', 'foo',
    'bar'), 'Make path with multiple components, separator set to "\\"');

# Set pipe as directory separator
use File::PlainPath -separator => '|';

is(path('foo|bar'), File::Spec->catfile('foo', 'bar'),
    'Make path with separator set to "|"');
is(path('foo|bar\\baz'), File::Spec->catfile('foo', 'bar\\baz'),
    'Make path with backslash in file name, separator set to "|"');
is(path('dir|subdir', 'foo|bar'), File::Spec->catfile('dir', 'subdir', 'foo',
    'bar'), 'Make path with multiple components, separator set to "|"');

is(\&path, \&to_path, 'path and to_path are the same subroutine');

done_testing;
