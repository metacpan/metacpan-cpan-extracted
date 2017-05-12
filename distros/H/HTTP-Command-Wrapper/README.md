[![Build Status](https://travis-ci.org/pine/p5-HTTP-Command-Wrapper.svg?branch=master)](https://travis-ci.org/pine/p5-HTTP-Command-Wrapper) [![Build Status](https://img.shields.io/appveyor/ci/pine/p5-HTTP-Command-Wrapper/master.svg)](https://ci.appveyor.com/project/pine/p5-HTTP-Command-Wrapper/branch/master) [![Coverage Status](http://codecov.io/github/pine/p5-HTTP-Command-Wrapper/coverage.svg?branch=master)](https://codecov.io/github/pine/p5-HTTP-Command-Wrapper?branch=master)
# NAME

HTTP::Command::Wrapper - The command based HTTP client (wget/curl wrapper). Too minimum dependencies!

# SYNOPSIS

    use HTTP::Command::Wrapper;

    my $client  = HTTP::Command::Wrapper->create; # auto detecting (curl or wget)
    my $content = $client->fetch('https://github.com/');

    print "$content\n";

# DESCRIPTION

HTTP::Command::Wrapper is a very simple HTTP client module.
It can wrap `wget` or `curl` command, and can use same interface.

# REQUIREMENTS

`wget` or `curl`

# METHODS

## CLASS METHODS

### `create($options = {})`

Create new wrapper instance using automatic commands detecting.

### `create($type, $options = {})`

Create new wrapper instance. `'wget'` or `'curl'` can be specified as `$type` value.

#### `$options`

- `verbose => 1`

    Turn on verbose output, with all the available data.

- `quiet => 1`

    Turn off output.

## METHODS

### `fetch($url, $headers = [])`

Fetch http/https contents from `$url`. Return a content body as string.

### `fetch_able($url, $headers = [])`

Return true if `$url` contents can fetch (status code is `200`).

### `download($url, $path, $headers = [])`

Fetch http/https contents from `$url`. Save in file. Return process exit code as boolean.

# LICENSE

The MIT License (MIT)

Copyright (c) 2015-2016 Pine Mizune

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
