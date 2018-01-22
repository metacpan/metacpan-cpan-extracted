[![Build Status](https://travis-ci.org/codecov/codecov-perl.svg?branch=master)](https://travis-ci.org/codecov/codecov-perl)
# NAME

Devel::Cover::Report::Codecov - Backend for Codecov reporting of coverage statistics

# SYNOPSIS

    $ cover -report codecov

# DESCRIPTION

Devel::Cover::Report::Codecov is coverage reporter for [Codecov](https://codecov.io).

## CI Companies Supported

Many CI services supported.
You must set CODECOV\_TOKEN environment variables if you don't use Travis CI, Circle CI and AppVeyor.

- [Travis CI](https://travis-ci.org/)
- [Circle CI](https://circleci.com/)
- [AppVeyor](http://www.appveyor.com/)
- [Codeship](https://codeship.com/)
- [Drone.io](https://drone.io/)
- [Semaphore](https://semaphoreci.com/)
- [Wercker](http://wercker.com/)
- [GitLab](https://about.gitlab.com/gitlab-ci/)

There are example Codecov CI settings in [example-perl](https://github.com/codecov/example-perl).

# SEE ALSO

- [Devel::Cover](https://metacpan.org/pod/Devel::Cover)

# LICENSE

The MIT License (MIT)

Copyright (c) 2015-2018 Pine Mizune

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
