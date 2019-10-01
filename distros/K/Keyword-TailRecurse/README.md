# NAME

Keyword::TailRecurse - Enables true tail recursion

# SYNOPSIS

    use Keyword::TailRecurse;

    sub fibonacci {
        my ( $count, $previous, $current ) = @_;

        return ( $previous // 0 ) if $count <= 0;

        $current //= 1;

        tailRecurse fibonacci ( $count - 1, $current, $previous + $current );
    }

    print fibonacci( 7 );

# DESCRIPTION

Keyword::TailRecurse provides a `tailRecurse` keyword that does proper tail
recursion that doesn't grow the call stack.

# USAGE

After using the module you can precede a function call with the keyword
`tailRecurse` and rather adding a new entry on the call stack the function
call will replace the current entry on the call stack.

## Sub::Call::Tail compatability

If compatibility with `Sub::Call::Tail` is required then you can use the
`subCallTail` flag to enable the `tail` keyword.

    use Keyword::TailRecurse 'subCallTail';

    sub fibonacci {
        my ( $count, $previous, $current ) = @_;

        return ( $previous // 0 ) if $count <= 0;

        $current //= 1;

        tail fibonacci ( $count - 1, $current, $previous + $current );
    }

    print fibonacci( 7 );

Note: with `Sub::Call:Tail` compatibility enabled both the `tailRecurse` and
`tail` keywords are available.

# REQUIRED PERL VERSION

`Keyword::TailRecurse` requires features only available in Perl v5.14 and
above. In addition a `Keyword::TailRecurse` dependency doesn't work in Perl
v5.20 due to a bug in regular expression compilation.

# SEE ALSO

- [Sub::Call::Recur](https://metacpan.org/pod/Sub::Call::Recur)

    An `XS` module that provides a form of tail recursion - limited to recursing
    into the same function it's used from.

- [Sub::Call::Tail](https://metacpan.org/pod/Sub::Call::Tail)

    An `XS` module that provides a generic tail recursion.

# LICENSE

Copyright (C) Jason Cooper.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jason Cooper <JLCOOPER@cpan.org>
