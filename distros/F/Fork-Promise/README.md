[![Build Status](https://travis-ci.org/tynovsky/Fork-Promise.svg?branch=master)](https://travis-ci.org/tynovsky/Fork-Promise)
# NAME

Fork::Promise - run a code in a subprocess and get a promise that it ended

# SYNOPSIS

    use Fork::Promise;
    use AnyEvent;

    my $pp = Fork::Promise->new();
    my $condvar = AnyEvent->condvar;

    my $promise = $pp->run(sub { sleep 1 });

# DESCRIPTION

Fork::Promise implements only one method - run. It runs given code in a
subprocess and registers AnyEvent child watcher which resolves promise returned
by run method.

# LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Miroslav Tynovsky <tynovsky@avast.com>
