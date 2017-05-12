#!perl
use strict;
use warnings;

use Test::More tests => 78;

# Be lazy and have everything exported
use File::Basename::Extra @File::Basename::Extra::EXPORT_OK;

# We do not need to retest the original File::Basename functions so we
# can concentrate just on the new bits

# Run tests using Unix file system logic
ok length fileparse_set_fstype('Unix'), 'Set fstype to Unix';

# Suffix handling using default patterns
is basename('.foo'),              '.foo',     'Default patterns: basename(".foo")';
is basename_suffix('.foo'),       '',         'Default patterns: basename_suffix(".foo")';
is basename_nosuffix('.foo'),     '.foo',     'Default patterns: basename_nosuffix(".foo")';
is basename_suffix('.foo.bar'),   '.bar',     'Default patterns: basename_suffix(".foo.bar")';
is basename_nosuffix('.foo.bar'), '.foo',     'Default patterns: basename_nosuffix(".foo.bar")';
is basename_suffix('.foo_bar'),   '',         'Default patterns: basename_suffix(".foo_bar")';
is basename_nosuffix('.foo_bar'), '.foo_bar', 'Default patterns: basename_nosuffix(".foo_bar")';
is filename('.foo'),              '.foo',     'No      patterns: filename(".foo")';
is filename_suffix('.foo'),       '.foo',     'Default patterns: filename_suffix(".foo")';
is filename_nosuffix('.foo'),     '',         'Default patterns: filename_nosuffix(".foo")';
is filename_suffix('.foo.bar'),   '.bar',     'Default patterns: filename_suffix(".foo.bar")';
is filename_nosuffix('.foo.bar'), '.foo',     'Default patterns: filename_nosuffix(".foo.bar")';
is filename_suffix('.foo_bar'),   '.foo_bar', 'Default patterns: basename_suffix(".foo_bar")';
is filename_nosuffix('.foo_bar'), '',         'Default patterns: basename_nosuffix(".foo_bar")';
is fullname('.foo'),              '.foo',     'No      patterns: fullname(".foo")';
is fullname_suffix('.foo'),       '.foo',     'Default patterns: fullname_suffix(".foo")';
is fullname_nosuffix('.foo'),     '',         'Default patterns: fullname_nosuffix(".foo")';
is fullname_suffix('.foo.bar'),   '.bar',     'Default patterns: fullname_suffix(".foo.bar")';
is fullname_nosuffix('.foo.bar'), '.foo',     'Default patterns: fullname_nosuffix(".foo.bar")';
is fullname_suffix('.foo_bar'),   '.foo_bar', 'Default patterns: fullname_suffix(".foo_bar")';
is fullname_nosuffix('.foo_bar'), '',         'Default patterns: fullname_nosuffix(".foo_bar")';

# Suffix handling using non-default patterns
is basename('.foo', '.foo'),              '.foo',     'Pattern .foo: basename(".foo")';
is basename_suffix('.foo', '.foo'),       '',         'Pattern .foo: basename_suffix(".foo")';
is basename_nosuffix('.foo', '.foo'),     '.foo',     'Pattern .foo: basename_nosuffix(".foo")';
is basename_suffix('.foo.bar', '.foo'),   '',         'Pattern .foo: basename_suffix(".foo.bar")';
is basename_nosuffix('.foo.bar', '.foo'), '.foo.bar', 'Pattern .foo: basename_nosuffix(".foo.bar")';
is basename_suffix('.foo.bar', '.bar'),   '.bar',     'Pattern .bar: basename_suffix(".foo.bar")';
is basename_nosuffix('.foo.bar', '.bar'), '.foo',     'Pattern .bar: basename_nosuffix(".foo.bar")';
is basename_suffix('.foo_bar', '.bar'),   '',         'Pattern .bar: basename_suffix(".foo_bar")';
is basename_nosuffix('.foo_bar', '.bar'), '.foo_bar', 'Pattern .bar: basename_nosuffix(".foo_bar")';
is filename('.foo', '.foo'),              '',         'Pattern .foo: filename(".foo")';
is filename_suffix('.foo', '.foo'),       '.foo',     'Pattern .foo: filename_suffix(".foo")';
is filename_nosuffix('.foo', '.foo'),     '',         'Pattern .foo: filename_nosuffix(".foo")';
is filename_suffix('.foo.bar', '.foo'),   '',         'Pattern .foo: filename_suffix(".foo.bar")';
is filename_nosuffix('.foo.bar', '.foo'), '.foo.bar', 'Pattern .foo: filename_nosuffix(".foo.bar")';
is filename_suffix('.foo.bar', '.bar'),   '.bar',     'Pattern .bar: filename_suffix(".foo.bar")';
is filename_nosuffix('.foo.bar', '.bar'), '.foo',     'Pattern .bar: filename_nosuffix(".foo.bar")';
is filename_suffix('.foo_bar', '.bar'),   '_bar',     'Pattern .bar: filename_suffix(".foo_bar")';
is filename_nosuffix('.foo_bar', '.bar'), '.foo',     'Pattern .bar: filename_nosuffix(".foo_bar")';
is fullname('.foo', '.foo'),              '',         'Pattern .foo: fullname(".foo")';
is fullname_suffix('.foo', '.foo'),       '.foo',     'Pattern .foo: fullname_suffix(".foo")';
is fullname_nosuffix('.foo', '.foo'),     '',         'Pattern .foo: fullname_nosuffix(".foo")';
is fullname_suffix('.foo.bar', '.foo'),   '',         'Pattern .foo: fullname_suffix(".foo.bar")';
is fullname_nosuffix('.foo.bar', '.foo'), '.foo.bar', 'Pattern .foo: fullname_nosuffix(".foo.bar")';
is fullname_suffix('.foo.bar', '.bar'),   '.bar',     'Pattern .bar: fullname_suffix(".foo.bar")';
is fullname_nosuffix('.foo.bar', '.bar'), '.foo',     'Pattern .bar: fullname_nosuffix(".foo.bar")';
is fullname_suffix('.foo_bar', '.bar'),   '_bar',     'Pattern .bar: fullname_suffix(".foo_bar")';
is fullname_nosuffix('.foo_bar', '.bar'), '.foo',     'Pattern .bar: fullname_nosuffix(".foo_bar")';

# basename, filename, pathname, fullname handling of directory vs file
is filename('/foo/bar/baz.txt'),           'baz.txt',           'Filename part of file spec "/foo/bar/baz.txt"';
is filename('/foo/bar/baz.txt/'),          '',                  'Filename part of dir  spec "/foo/bar/baz.txt/"';
is filename_suffix('/foo/bar/baz.txt'),    '.txt',              'Filename suffix part of file spec "/foo/bar/baz.txt"';
is filename_suffix('/foo/bar/baz.txt/'),   '',                  'Filename suffix part of dir  spec "/foo/bar/baz.txt/"';
is filename_nosuffix('/foo/bar/baz.txt'),  'baz',               'Filename without suffix part of file spec "/foo/bar/baz.txt"';
is filename_nosuffix('/foo/bar/baz.txt/'), '',                  'Filename without suffix part of dir  spec "/foo/bar/baz.txt/"';
is pathname('/foo/bar/baz.txt'),           '/foo/bar/',         'Pathname part of file spec "/foo/bar/baz.txt"';
is pathname('/foo/bar/baz.txt/'),          '/foo/bar/baz.txt/', 'Pathname part of dir  spec "/foo/bar/baz.txt/"';
is fullname('/foo/bar/baz.txt'),           '/foo/bar/baz.txt',  'Fullname part of file spec "/foo/bar/baz.txt"';
is fullname('/foo/bar/baz.txt/'),          '/foo/bar/baz.txt/', 'Fullname part of dir  spec "/foo/bar/baz.txt/"';
is fullname_suffix('/foo/bar/baz.txt'),    '.txt',              'Fullname suffix part of file spec "/foo/bar/baz.txt"';
is fullname_suffix('/foo/bar/baz.txt/'),   '',                  'Fullname suffix part of dir  spec "/foo/bar/baz.txt/"';
is fullname_nosuffix('/foo/bar/baz.txt'),  '/foo/bar/baz',      'Fullname without suffix part of file spec "/foo/bar/baz.txt"';
is fullname_nosuffix('/foo/bar/baz.txt/'), '/foo/bar/baz.txt/', 'Fullname without suffix part of dir  spec "/foo/bar/baz.txt/"';

# Changing the default suffix patterns
my @org = qr/\.[^.]*/;
my @new = ('.baz', '.bar');

is_deeply [ default_suffix_patterns() ],     [ @org ], 'Default suffix patterns';
is_deeply [ default_suffix_patterns(@new) ], [ @org ], 'Setting new patterns returns org patterns';
is_deeply [ default_suffix_patterns() ],     [ @new ], 'New patterns are active';

is basename('.foo'),              '.foo', 'New default patterns: basename(".foo")';
is basename_suffix('.foo'),       '',     'New default patterns: basename_suffix(".foo")';
is basename_nosuffix('.foo'),     '.foo', 'New default patterns: basename_nosuffix(".foo")';
is basename_suffix('.foo.bar'),   '.bar', 'New default patterns: basename_suffix(".foo.bar")';
is basename_nosuffix('.foo.bar'), '.foo', 'New default patterns: basename_nosuffix(".foo.bar")';
is basename_suffix('.foo_bar'),   '_bar', 'New default patterns: basename_suffix(".foo_bar")';
is basename_nosuffix('.foo_bar'), '.foo', 'New default patterns: basename_nosuffix(".foo_bar")';
is filename('.foo'),              '.foo', 'No          patterns: filename(".foo")';
is filename_suffix('.foo'),       '',     'New default patterns: filename_suffix(".foo")';
is filename_nosuffix('.foo'),     '.foo', 'New default patterns: filename_nosuffix(".foo")';
is filename_suffix('.foo.bar'),   '.bar', 'New default patterns: filename_suffix(".foo.bar")';
is filename_nosuffix('.foo.bar'), '.foo', 'New default patterns: filename_nosuffix(".foo.bar")';
