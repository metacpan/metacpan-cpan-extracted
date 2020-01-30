# NAME

JS::JJ - Encode and Decode JJ

# SYNOPSIS

    use JS::JJ qw/
        jj_encode
        jj_decode
    /;
    
    my $jj = jj_encode($js);
    
    my $js = jj_decode($jj);
    
# DESCRIPTION

This module provides methods for encode and decode jj.

# METHODS

## jj_encode

    my $jj = jj_encode($js);
    
Returns the jj.

## jj_decode

    my $js = jj_decode($jj);
    
Returns the javascript.

# SEE ALSO

[Original encoder jjencode](http://utf-8.jp/public/jjencode.html)

# AUTHOR

Lucas Tiago de Moraes `lucastiagodemoraes@gmail.com`

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Lucas Tiago de Moraes.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
