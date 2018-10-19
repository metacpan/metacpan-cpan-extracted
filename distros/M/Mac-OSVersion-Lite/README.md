[![Build Status](https://travis-ci.org/pine/p5-Mac-OSVersion-Lite.svg?branch=master)](https://travis-ci.org/pine/p5-Mac-OSVersion-Lite) [![Build Status](https://img.shields.io/appveyor/ci/pine/p5-Mac-OSVersion-Lite/master.svg?logo=appveyor)](https://ci.appveyor.com/project/pine/p5-Mac-OSVersion-Lite/branch/master) [![Coverage Status](http://codecov.io/github/pine/p5-Mac-OSVersion-Lite/coverage.svg?branch=master)](https://codecov.io/github/pine/p5-Mac-OSVersion-Lite?branch=master)
# NAME

Mac::OSVersion::Lite - It's the lightweight version object for Mac OS X

# SYNOPSIS

    use Mac::OSVersion::Lite;
    use feature qw/say/;

    my $version = Mac::OSVersion::Lite->new;
    say $version->major; # 10
    say $version->minor; # 11
    say $version->name;  # el_capitan

# DESCRIPTION

Mac::OSVersion::Lite is the lightweight version object for Mac OS X with auto detection.

# METHODS

## CLASS METHODS

### `new()`

Create new `Mac::OSVersion::Lite` instance with auto detection.

### `new($version_string)`

Create new `Mac::OSVersion::Lite` instance from a version string.
`Mac::OSVersion::Lite->new('10.11')` equals `Mac::OSVersion::Lite->new(10, 11)`.

### `new($major, $minor = 0)`

Create new `Mac::OSVersion::Lite` instance from version numbers.
`Mac::OSVersion::Lite->new(10, 11)` equals `Mac::OSVersion::Lite->new('10.11')`.

## METHODS

### `major`

Get the major version number.

### `minor`

Return the minor version number.

### `<=>`

Compare two `SemVer::V2::Strict` instances.

### `""`

Convert a `SemVer::V2::Strict` instance to string.

### `as_string()`

Convert a `SemVer::V2::Strict` instance to string.

# SEE ALSO

- [Mac::OSVersion](https://metacpan.org/pod/Mac::OSVersion)

# LICENSE

The MIT License (MIT)

Copyright (c) 2017 Pine Mizune

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

# AUTHOR

Pine Mizune <pinemz@gmail.com>
