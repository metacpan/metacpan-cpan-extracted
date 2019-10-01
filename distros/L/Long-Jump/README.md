# NAME

Long::Jump - Mechanism for returning to a specific point from a deeply nested
stack.

# DESCRIPTION

This module essentially provides a multi-level return. You can mark a spot with
`setjump()` and then unwind the stack back to that point from any nested stack
frame by name using `longjump()`. You can also provide a list of return
values.

This is not quite a match for C's long jump, but it is "close enough". It is
safer than C's jump in that it only lets you escape frames by going up the
stack, you cannot jump in other ways.

# SYNOPSIS

    use Long::Jump qw/setjump longjump/;

    my $out = setjump foo => sub {
        bar();
        ...; # Will never get here
    };
    is($out, [qw/x y z/], "Got results of the long jump");

    $out = setjump foo => sub {
        print "Not calling longjump";
    };
    is($out, undef, "longjump was not called so we got an undef response");

    sub bar {
        baz();
        return 'bar'; # Will never get here
    }

    sub baz {
        bat();
        return 'baz'; # Will never get here
    }

    sub bat {
        my @out = qw/x y z/;
        longjump foo => @out;

        return 'bat'; # Will never get here
    }

# EXPORTS

- $out = setjump($NAME, sub { ... })
- $out = setjump $NAME, sub { ... }
- $out = setjump($NAME => sub { ... })
- $out = setjump $NAME => sub { ... }

    Set a named point to which you will return when calling `longjump()`. `$out`
    will be `undef` if `longjump()` was not called. `$out` will be an arrayref
    if `longjump()` was called. The `$out` arrayref will be empty, but present if
    `longjump()` is called without any return values.

    The return value will always be false if `longjump` was not called, and will
    always be true if it was called.

    You cannot nest multiple jump points with the same name, but you can nest
    multiple jump points if they have unqiue names. `longjump()` will always jump
    to the correct name.

- longjump($NAME)
- longjump $NAME
- longjump($NAME, @RETURN\_LIST)
- longjump($NAME => @RETURN\_LIST)
- longjump $NAME => @RETURN\_LIST

    Jump to the named point, optionally with values to return. This will throw
    exceptions if you use an invalid `$NAME`, which includes the case of calling
    it without a set jump point.

# SOURCE

The source code repository for Long-Jump can be found at
`https://github.com/exodist/Long-Jump/`.

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright 2018 Chad Granum <exodist7@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `http://dev.perl.org/licenses/`
