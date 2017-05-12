# NAME

Log::StringFormatter - string formatter for logs

# SYNOPSIS

    use Log::StringFormatter;
    use Scalar::Util qw/dualvar/;

    stringf('foo') -> 'foo'
    stringf('%s bar','foo') -> 'foo bar'
    stringf([qw/foo bar/]) -> ['foo','bar']
    stringf('uri %s',URI->new("http://example.com/")) -> 'uri http://example.com/'
    my $dualvar = dualvar 10, "Hello";
    stringf('%s , %d', $dualvar, $dualvar) -> 'Hello , 10'

# DESCRIPTION

Log::StringFormatter provides a string formatter function that suitable for log messages.
Log::StringFormatter's formatter also can serialize non-scalar variables.

# FUNCTION

- stringf($format:Str,@variables) / stringf($variable)

    format and serialize given values

# SEE ALSO

[Log::Minimal](http://search.cpan.org/perldoc?Log::Minimal), [String::Flogger](http://search.cpan.org/perldoc?String::Flogger)

# LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>
