# NAME

Hash::Unique - It's hash manipulation module

# DESCRIPTION

### get\_unique\_hash

This subroutine makes hash-array unique by specified key.

#### way to use

    use Hash::Unique;

    my @hash_array = (
      {id => 1, name => 'tanaka'},
      {id => 2, name => 'sato'},
      {id => 3, name => 'suzuki'},
      {id => 4, name => 'tanaka'}
    );

    my @unique_hash_array = Hash::Unique->get_unique_hash(\@hash_array, "name");

#### result

Contents of "@unique\_hash\_array"

    (
     {id => 1, name => 'tanaka'},
     {id => 2, name => 'sato'},
     {id => 3, name => 'suzuki'}
    )

# LICENSE

Copyright (C) matsumura-taichi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

matsumura-taichi <hiroto.in.the.cromagnons@gmail.com>
