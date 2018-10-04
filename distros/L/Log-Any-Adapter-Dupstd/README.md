[![Build Status](https://travis-ci.org/ivanych/Log-Any-Adapter-Dupstd.svg?branch=master)](https://travis-ci.org/ivanych/Log-Any-Adapter-Dupstd) [![MetaCPAN Release](https://badge.fury.io/pl/Log-Any-Adapter-Dupstd.svg)](https://metacpan.org/release/Log-Any-Adapter-Dupstd)
# NAME

Log::Any::Adapter::Dupstd - Cunning adapter for logging to a duplicate of
STDOUT or STDERR

# SYNOPSIS

    # Log to a duplicate of stdout or stderr

    use Log::Any::Adapter ('Dupout');
    use Log::Any::Adapter ('Duperr');

    # or

    use Log::Any::Adapter;
    ...
    Log::Any::Adapter->set('Dupout');
    Log::Any::Adapter->set('Duperr');

    # with minimum level 'warn'

    use Log::Any::Adapter ('Dupout', log_level => 'warn' );
    use Log::Any::Adapter ('Duperr', log_level => 'warn' );

    # and later

    open(STDOUT, ">/dev/null");
    open(STDERR, ">/dev/null");

# DESCRIPTION

Adapters Dupstd are intended to log messages into duplicates of standard
descriptors STDOUT and STDERR.

Logging into a duplicate of standard descriptor might be needed in special
occasions when you need to redefine or even close standard descriptor but you
want to continue displaying messages wherever they are displayed by a standard
descriptor.

For instance, your script types something in STDERR, and you want to redirect
that message into a file. If you redirect STDERR into a file, warnings `warn`
and even exceptions `die` will be redirected there as well. But that is not
always convenient. In many cases it is more convenient to display warnings and
exceptions on the screen.

    # Redirect STDERR into a file
    open(STDERR, '>', 'stderr.txt');

    # This message will go to the file, not on the screen (you want this)
    print STDERR 'Some message';

    # This warning will go to the file too (and that is what you don't want)
    warn('Warning!');

You can try to display warning or exception on the screen by yourself using
adapter Stderr from the distributive Log::Any. But adapter Stderr types message
on STDERR so the message will anyway be in the file and not on the screen.

    # Adapter Stderr
    use Log::Any::Adapter ('Stderr');

    # Redirect STDERR into a file
    open(STDERR, '>', 'stderr.txt')

    # This message will go to the file, not on the screen (you want this)
    print STDERR 'Some message';

    # Oops, warning will go to the file (again it's not what you expected)
    $log->warning('Warning!')

You can display message on the screen using adapter Stdout, which is also in the
distributive Log::Any. Warning will be displayed on the screen as expected, but
that will be "not real" warning because it will be displayed through STDOUT.
That warning will be impossible to filter in the shell.

    # That won't be working!
    $ script.pl 2> error.log

That is the situation when you need adapter Dupstd. Warnings and exceptions sent
using these adapters will be "real". They can be filtered in the shell just as
if they would have been sent to usual STDERR.

    # Adapter Duperr (definitely PRIOR TO redirecting STDERR)
    use Log::Any::Adapter ('Duperr');

    # Redirect STDERR into a file
    open(STDERR, '>', 'stderr.txt')

    # This message will go to the file, not on the screen (you want this)
    print STDERR 'Some message';

    # Warning will be displayed on the screen (that is what you want)
    $log->warning('Warning!')

# ATTENTION

Adapters Dupstd must be initialized prior to standard descriptors being redefined or closed.

Standard descriptor can't be reopened, that's why the duplicate must be made in advance.

# ADAPTERS

In this distributive there are two cunning adapters - Dupout and Duperr.

These adapters work similarly to ordinary adapters from distributive Log::Any -
[Stdout](https://metacpan.org/pod/Log::Any::Adapter::Stdout) and [Stderr](https://metacpan.org/pod/Log::Any::Adapter::Stderr) (save that inside are used descriptors duplicates).

# SEE ALSO

[Log::Any](https://metacpan.org/pod/Log::Any), [Log::Any::Adapter](https://metacpan.org/pod/Log::Any::Adapter), [Log::Any::For::Std](https://metacpan.org/pod/Log::Any::For::Std)

# LICENSE

Copyright (C) Mikhail Ivanov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHORS

- Mikhail Ivanov <m.ivanych@gmail.com>
- Anastasia Zherebtsova <zherebtsova@gmail.com> - translation of documentation
into English
