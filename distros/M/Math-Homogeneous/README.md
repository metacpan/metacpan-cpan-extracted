# NAME

Math::Homogeneous - Perform homogeneous product

# SYNOPSIS

## Function
  

    use Math::Homogeneous;

    my @n = qw/ a b c /;
    my $homo = homogeneous(2, @n);
    for (@$homo) {
      print join(',', @$_) . "\n";
    }

### Output
    

    a,a
    a,b
    a,c
    b,a
    b,b
    b,c
    c,a
    c,b
    c,c

## Iterator

    use Math::Homogeneous;

    my @n = qw/ a b c /;
    my $itr = Math::Homogeneous->new(2, @n);
    
    while (<$itr>) {
      print join(',', @$_) . "\n";
    }

### Output

    a,a
    a,b
    a,c
    b,a
    b,b
    b,c
    c,a
    c,b
    c,c

# DESCRIPTION

Perform homogeneous product.

# LICENSE

Copyright (C) hoto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

hoto <hoto17296@gmail.com>
