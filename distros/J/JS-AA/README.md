# NAME

JS::AA - Encode and Decode AA

# SYNOPSIS

    use JS::AA qw/
        aa_encode
        aa_decode
    /;
    
    my $aa = aa_encode($js);
    
    my $js = aa_decode($aa);
    
# DESCRIPTION

This module provides methods for encode and decode AA.

# METHODS

## aa_encode

    my $aa = aa_encode($js);
    
Returns the aa.

## aa_decode

    my $js = aa_decode($aa);
    
Returns the javascript.

# SEE ALSO

[Original encoder aaencode](http://utf-8.jp/public/aaencode.html)

[Original decoder aadecode](https://cat-in-136.github.io/2010/12/aadecode-decode-encoded-as-aaencode.html)

# AUTHOR

Lucas Tiago de Moraes `lucastiagodemoraes@gmail.com`

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Lucas Tiago de Moraes.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.