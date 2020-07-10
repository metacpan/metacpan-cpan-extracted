# NAME

Hash::Merge - Merges arbitrarily deep hashes into a single hash

# SYNOPSIS

    my %a = (
        'foo'    => 1,
        'bar'    => [qw( a b e )],
        'querty' => { 'bob' => 'alice' },
    );
    my %b = (
        'foo'    => 2,
        'bar'    => [qw(c d)],
        'querty' => { 'ted' => 'margeret' },
    );
    
    my %c = %{ merge( \%a, \%b ) };
    
    Hash::Merge::set_behavior('RIGHT_PRECEDENT');
    
    # This is the same as above
    
    Hash::Merge::specify_behavior(
        {   'SCALAR' => {
                'SCALAR' => sub { $_[1] },
                'ARRAY'  => sub { [ $_[0], @{ $_[1] } ] },
                'HASH'   => sub { $_[1] },
            },
            'ARRAY' => {
                'SCALAR' => sub { $_[1] },
                'ARRAY'  => sub { [ @{ $_[0] }, @{ $_[1] } ] },
                'HASH'   => sub { $_[1] },
            },
            'HASH' => {
                'SCALAR' => sub { $_[1] },
                'ARRAY'  => sub { [ values %{ $_[0] }, @{ $_[1] } ] },
                'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
            },
        },
        'My Behavior',
    );
    
    # Also there is OO interface.
    
    my $merge = Hash::Merge->new('LEFT_PRECEDENT');
    my %c = %{ $merge->merge( \%a, \%b ) };
    
    # All behavioral changes (e.g. $merge->set_behavior(...)), called on an object remain specific to that object
    # The legacy "Global Setting" behavior is respected only when new called as a non-OO function.

# DESCRIPTION

Hash::Merge merges two arbitrarily deep hashes into a single hash.  That
is, at any level, it will add non-conflicting key-value pairs from one
hash to the other, and follows a set of specific rules when there are key
value conflicts (as outlined below).  The hash is followed recursively,
so that deeply nested hashes that are at the same level will be merged 
when the parent hashes are merged.  **Please note that self-referencing
hashes, or recursive references, are not handled well by this method.**

Values in hashes are considered to be either ARRAY references, 
HASH references, or otherwise are treated as SCALARs.  By default, the 
data passed to the merge function will be cloned using the Clone module; 
however, if necessary, this behavior can be changed to use as many of 
the original values as possible.  (See `set_clone_behavior`). 

Because there are a number of possible ways that one may want to merge
values when keys are conflicting, Hash::Merge provides several preset
methods for your convenience, as well as a way to define you own.  
These are (currently):

- Left Precedence

    This is the default behavior.

    The values buried in the left hash will never
    be lost; any values that can be added from the right hash will be
    attempted.

        my $merge = Hash::Merge->new();
        my $merge = Hash::Merge->new('LEFT_PRECEDENT');
        $merge->set_set_behavior('LEFT_PRECEDENT');
        Hash::Merge::set_set_behavior('LEFT_PRECEDENT');

- Right Precedence

    Same as Left Precedence, but with the right
    hash values never being lost

        my $merge = Hash::Merge->new('RIGHT_PRECEDENT');
        $merge->set_set_behavior('RIGHT_PRECEDENT');
        Hash::Merge::set_set_behavior('RIGHT_PRECEDENT');

- Storage Precedence

    If conflicting keys have two different
    storage mediums, the 'bigger' medium will win; arrays are preferred over
    scalars, hashes over either.  The other medium will try to be fitted in
    the other, but if this isn't possible, the data is dropped.

        my $merge = Hash::Merge->new('STORAGE_PRECEDENT');
        $merge->set_set_behavior('STORAGE_PRECEDENT');
        Hash::Merge::set_set_behavior('STORAGE_PRECEDENT');

- Retainment Precedence

    No data will be lost; scalars will be joined
    with arrays, and scalars and arrays will be 'hashified' to fit them into
    a hash.

        my $merge = Hash::Merge->new('RETAINMENT_PRECEDENT');
        $merge->set_set_behavior('RETAINMENT_PRECEDENT');
        Hash::Merge::set_set_behavior('RETAINMENT_PRECEDENT');

Specific descriptions of how these work are detailed below.

- merge ( &lt;hashref>, &lt;hashref> )

    Merges two hashes given the rules specified.  Returns a reference to 
    the new hash.

- \_hashify( &lt;scalar>|&lt;arrayref> ) -- INTERNAL FUNCTION

    Returns a reference to a hash created from the scalar or array reference, 
    where, for the scalar value, or each item in the array, there is a key
    and it's value equal to that specific value.  Example, if you pass scalar
    '3', the hash will be { 3 => 3 }.

- \_merge\_hashes( &lt;hashref>, &lt;hashref> ) -- INTERNAL FUNCTION

    Actually does the key-by-key evaluation of two hashes and returns 
    the new merged hash.  Note that this recursively calls `merge`.

- set\_clone\_behavior( &lt;scalar> ) 

    Sets how the data cloning is handled by Hash::Merge.  If this is true,
    then data will be cloned; if false, then original data will be used
    whenever possible.  By default, cloning is on (set to true).

- get\_clone\_behavior( )

    Returns the current behavior for data cloning.

- set\_behavior( &lt;scalar> )

    Specify which built-in behavior for merging that is desired.  The scalar
    must be one of those given below.

- get\_behavior( )

    Returns the behavior that is currently in use by Hash::Merge.

- specify\_behavior( &lt;hashref>, \[&lt;name>\] )

    Specify a custom merge behavior for Hash::Merge.  This must be a hashref
    defined with (at least) 3 keys, SCALAR, ARRAY, and HASH; each of those
    keys must have another hashref with (at least) the same 3 keys defined.
    Furthermore, the values in those hashes must be coderefs.  These will be
    called with two arguments, the left and right values for the merge.  
    Your coderef should return either a scalar or an array or hash reference
    as per your planned behavior.  If necessary, use the functions
    \_hashify and \_merge\_hashes as helper functions for these.  For example,
    if you want to add the left SCALAR to the right ARRAY, you can have your
    behavior specification include:

        %spec = ( ...SCALAR => { ARRAY => sub { [ $_[0], @$_[1] ] }, ... } } );

    Note that you can import \_hashify and \_merge\_hashes into your program's
    namespace with the 'custom' tag.

# BUILT-IN BEHAVIORS

Here is the specifics on how the current internal behaviors are called, 
and what each does.  Assume that the left value is given as $a, and
the right as $b (these are either scalars or appropriate references)

    LEFT TYPE    RIGHT TYPE    LEFT_PRECEDENT       RIGHT_PRECEDENT
     SCALAR       SCALAR        $a                   $b
     SCALAR       ARRAY         $a                   ( $a, @$b )
     SCALAR       HASH          $a                   %$b
     ARRAY        SCALAR        ( @$a, $b )          $b
     ARRAY        ARRAY         ( @$a, @$b )         ( @$a, @$b )
     ARRAY        HASH          ( @$a, values %$b )  %$b 
     HASH         SCALAR        %$a                  $b
     HASH         ARRAY         %$a                  ( values %$a, @$b )
     HASH         HASH          merge( %$a, %$b )    merge( %$a, %$b )

    LEFT TYPE    RIGHT TYPE    STORAGE_PRECEDENT    RETAINMENT_PRECEDENT
     SCALAR       SCALAR        $a                   ( $a ,$b )
     SCALAR       ARRAY         ( $a, @$b )          ( $a, @$b )
     SCALAR       HASH          %$b                  merge( hashify( $a ), %$b )
     ARRAY        SCALAR        ( @$a, $b )          ( @$a, $b )
     ARRAY        ARRAY         ( @$a, @$b )         ( @$a, @$b )
     ARRAY        HASH          %$b                  merge( hashify( @$a ), %$b )
     HASH         SCALAR        %$a                  merge( %$a, hashify( $b ) )
     HASH         ARRAY         %$a                  merge( %$a, hashify( @$b ) )
     HASH         HASH          merge( %$a, %$b )    merge( %$a, %$b )

(\*) note that merge calls \_merge\_hashes, hashify calls \_hashify.

# AUTHOR

Michael K. Neylon <mneylon-pm@masemware.com>,
Daniel Muey <dmuey@cpan.org>,
Jens Rehsack <rehsack@cpan.org>,
Stefan Hermes <hermes@cpan.org>

# COPYRIGHT

Copyright (c) 2001,2002 Michael K. Neylon. All rights reserved.
Copyright (c) 2013-2020 Jens Rehsack. All rights reserved.
Copyright (c) 2017-2020 Stefan Hermes. All rights reserved.

This library is free software.  You can redistribute it and/or modify it 
under the same terms as Perl itself.
