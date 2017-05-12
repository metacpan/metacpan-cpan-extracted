# NAME

HTTP::Headers::Fast - faster implementation of HTTP::Headers

# SYNOPSIS

    use HTTP::Headers::Fast;
    # and, same as HTTP::Headers.

# DESCRIPTION

HTTP::Headers::Fast is a perl class for parsing/writing HTTP headers.

The interface is same as HTTP::Headers.

# WHY YET ANOTHER ONE?

HTTP::Headers is a very good. But I needed a faster implementation, fast  =)

# ADDITIONAL METHODS

- as\_string\_without\_sort

    as\_string method sorts the header names.But, sorting is bit slow.

    In this method, stringify the instance of HTTP::Headers::Fast without sorting.

- psgi\_flatten

    returns PSGI compatible arrayref of header.

        my $headers:ArrayRef = $header->flatten

- psgi\_flatten\_without\_sort

    same as flatten but returns arrayref without sorting.

# @ISA HACK

If you want HTTP::Headers::Fast to pretend like it's really HTTP::Headers, you can try the following hack:

    unshift @HTTP::Headers::Fast::ISA, 'HTTP::Headers';

# BENCHMARK

    HTTP::Headers 5.818, HTTP::Headers::Fast 0.01

    -- push_header
            Rate orig fast
    orig 144928/s   -- -20%
    fast 181818/s  25%   --

    -- push_header_many
            Rate orig fast
    orig 74627/s   -- -16%
    fast 89286/s  20%   --

    -- get_date
            Rate orig fast
    orig 34884/s   -- -14%
    fast 40541/s  16%   --

    -- set_date
            Rate orig fast
    orig 21505/s   -- -19%
    fast 26525/s  23%   --

    -- scan
            Rate orig fast
    orig 57471/s   --  -1%
    fast 57803/s   1%   --

    -- get_header
            Rate orig fast
    orig 120337/s   -- -24%
    fast 157729/s  31%   --

    -- set_header
            Rate orig fast
    orig  79745/s   -- -30%
    fast 113766/s  43%   --

    -- get_content_length
            Rate orig fast
    orig 182482/s   -- -77%
    fast 793651/s 335%   --

    -- as_string
            Rate orig fast
    orig 23753/s   -- -41%
    fast 40161/s  69%   --

# AUTHOR

    Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>
    Daisuke Maki

And HTTP::Headers' originally written by Gisle Aas.

# THANKS TO

Markstos

Tatsuhiko Miyagawa

# SEE ALSO

[HTTP::Headers](https://metacpan.org/pod/HTTP::Headers)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
