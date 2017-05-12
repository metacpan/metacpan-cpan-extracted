# NAME

Devel::StackTrace::Extract - Extract a stack trace from an exception object

# VERSION

version 1.000000

# DESCRIPTION

It's popular to store stack traces in objects that are thrown as exceptions,
but, this being Perl, there's more than one way to do it.  This module
provides a simple interface to attempt to extract the stack trace from various
well known exception classes that are on the CPAN.

# FUNCTION

Exported on demand or can be used fully qualified

## extract\_stack\_trace($exception\_object)

Returns a Devel::StackTrace stack trace object extracted from the exception
object or returns undef if no stack trace can be extracted with the current
heuristics.

The current rules that this uses to determine how to get a stack trace are, in
order, as follows (these are subject to change without notice):

- If it has a method called `stack_trace` use that

    This works with anything that uses the [StackTrace::Auto](https://metacpan.org/pod/StackTrace::Auto) Moose/Moo role, or
    subclasses the [Throwable::Exception](https://metacpan.org/pod/Throwable::Exception) class.

- If it is a Mojo::Exception, and has a method called `frames` use that

    If we have a modern [Mojo::Exception](https://metacpan.org/pod/Mojo::Exception) object with a `frames` method, and it has
    its frames populated (i.e. someone used the `trace` method, or called `throw`)
    then we'll synthesize a [Devel::StackTrace](https://metacpan.org/pod/Devel::StackTrace) instance from that.

- If it has a `trace` method call that

    This works for [Exception::Class](https://metacpan.org/pod/Exception::Class) built exception objects, as well as any
    [Moose::Exception](https://metacpan.org/pod/Moose::Exception) instances.

# BUGS

The heuristics in this make no attempt to check whatever is returned by the
exception classes are valid [Devel::StackTrace](https://metacpan.org/pod/Devel::StackTrace) objects

[Mojo::Exception](https://metacpan.org/pod/Mojo::Exception) objects don't keep track of the arguments that are passed to a
stack frame, so the [Devel::StackTrace](https://metacpan.org/pod/Devel::StackTrace) that this synthesizes acts as if every
subroutine was called without arguments.

# SEE ALSO

[Devel::StackTrace](https://metacpan.org/pod/Devel::StackTrace)

[Throwable::Error](https://metacpan.org/pod/Throwable::Error) and [StackTrace::Auto](https://metacpan.org/pod/StackTrace::Auto)

[Exception::Class](https://metacpan.org/pod/Exception::Class)

[Moose::Exception](https://metacpan.org/pod/Moose::Exception)

[Mojo::Exception](https://metacpan.org/pod/Mojo::Exception)

# AUTHOR

Mark Fowler <mfowler@maxmind.com>

# CONTRIBUTORS

- Dave Rolsky <drolsky@maxmind.com>
- Mark Fowler <mark@twoshortplanks.com>
- Olaf Alders <oalders@maxmind.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
