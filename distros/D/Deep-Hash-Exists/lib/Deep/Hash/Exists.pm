package Deep::Hash::Exists;

use strict;
use warnings;
use utf8;
use Scalar::Util;

use base qw( Exporter );

our @EXPORT = qw();
our @EXPORT_OK = qw( 
        key_exists 
        every_keys 
        some_keys 
);
our %EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );
our $VERSION = '0.22';

sub key_exists($$) {
    my $hash_ref = shift;
    my $array_ref = shift;
    
    return 0 if Scalar::Util::reftype $hash_ref ne 'HASH';
    
    my $key = shift @$array_ref;
    
    if ( exists $hash_ref->{$key} ) {
        if ( scalar @$array_ref > 0 ) {
            return &key_exists( $hash_ref->{$key}, $array_ref );
        } else {
            return 1;
        }#fi
    } else {
        return 0;
    }#fi
}

sub every_keys($$) {
    my $hash_ref = shift;
    my $list_array_ref = shift;
    
    foreach my $array_ref ( @$list_array_ref ) {
        return 0 unless key_exists( $hash_ref, $array_ref );
    }#hcaerof
    
    return 1;
}

sub some_keys($$) {
    my $hash_ref = shift;
    my $list_array_ref = shift;
    
    foreach my $array_ref ( @$list_array_ref ) {
        return 1 if key_exists( $hash_ref, $array_ref );
    }#hcaerof
    
    return 0;
}

1;


__END__


=head1 NAME

Deep::Hash::Exists - Verify existence of keys hash.

=head1 SYNOPSIS

 use Deep::Hash::Exists ':all';
 
 my $hash_ref = {
         A => 'one',
         B => [ 'one', 'two' ],
         C => { 
             'one' => 1, 
             'two' => 2, 
         },
 };
 
 key_exists( $hash_ref, [ 'C', 'one' ] ); # return 1
 key_exists( $hash_ref, [ 'D' ] );        # return 0
 
 every_keys( $hash_ref, [ ['A'], ['B', 0], ['C', 'one'] ] ); # return 0
 every_keys( $hash_ref, [ ['A'], ['B'], ['C', 'one'] ] );    # return 1
 
 some_keys( $hash_ref, [ ['A'], ['B', 0], ['C', 'one'] ] ); # return 1
 some_keys( $hash_ref, [ ['D'], ['B', 0], ['C', 'six'] ] ); # return 0
 
=head1 DESCRIPTION

Exists hash:

 my $hash_ref = {
         A => 'one',
         B => [ 'one', 'two' ],
         C => { 
             'one' => 1, 
             'two' => 2, 
         },
 };

If verify existence of keys standard way, will be created non existent keys:

 exists $hash_ref->{C}{three}{PI}{0};
 print Dumper $hash_ref;

Output:

 # $VAR1 = {
 #          'A' => 'one',
 #          'B' => [
 #                   'one',
 #                   'two'
 #                 ]
 #          'C' => {
 #                   'one' => 1,
 #                   'two' => 2,
 #                   'three' => {
 #                                'PI' => {}
 #                              }
 #                },
 #        };

Subroutine C<key_exists> does not create new keys:

 key_exists( $hash_ref, [ 'C', 'three', 'PI', 0 ] );
 print Dumper $hash_ref;
 
Output:

 # $VAR1 = {
 #          'A' => 'one',
 #          'B' => [
 #                   'one',
 #                   'two'
 #                 ],
 #          'C' => {
 #                   'one' => 1,
 #                   'two' => 2
 #                 }
 #        };


=head1 METHODS

The first argument in methods I<key_exists>, I<every_keys> and I<some_keys> can be a hash reference and a blessed hash.


=head2 key_exists($$)

B<key_exists>( I<$hash_ref, $array_ref_keys> ) - Verify existence of keys hash.

B<Return>:

If exist keys of hash then return 1, otherwise - 0.

B<Example>:
 
 my $hash_ref = {
         A => 'one',
         B => [ 'one', 'two' ],
         C => { 
             'one' => 1, 
             'two' => 2, 
         },
 };
 
 printf "Output: %s", key_exists( $hash_ref, [ 'A' ] );
 # Output: 1
 printf "Output: %s", key_exists( $hash_ref, [ 'B' ] );
 # Output: 1
 printf "Output: %s", key_exists( $hash_ref, [ 'B', 0 ] );
 # Output: 0
 printf "Output: %s", key_exists( $hash_ref, [ 'C', 'one' ] );
 # Output: 1
 printf "Output: %s", key_exists( $hash_ref, [ 'C', 'three' ] );
 # Output: 0
 printf "Output: %s", key_exists( $hash_ref, [ 'C', 'three', 'PI', 0 ] );
 # Output: 0
 # Subroutine does not create new keys.

=cut


=head2 every_keys($$)

B<every_keys>( I<$hash_ref, $list_array_ref> ) - Verify list of hash keys for existence.

B<Return>:

If exist all keys of hash of the submitted list then return 1, otherwise - 0.

B<Example>:

 my $hash_ref = {
         A => 'one',
         B => [ 'one', 'two' ],
         C => { 
             'one' => 1, 
             'two' => 2, 
         },
 };
 
 printf "Output: %s", every_keys( $hash_ref, [ ['A'], ['B', 0], ['C', 'one'] ] );
 # Output: 0
 printf "Output: %s", every_keys( $hash_ref, [ ['A'], ['C', 'one'], ['C', 'two'] ] );
 # Output: 1

=cut


=head2 some_keys($$)

B<some_keys>( I<$hash_ref, $list_array_ref> ) - Verify list of hash keys for existence.

B<Return>:

If exist at least one key of hash of the submitted list then return 1, otherwise - 0.

B<Example>:

 my $hash_ref = {
         A => 'one',
         B => [ 'one', 'two' ],
         C => { 
             'one' => 1, 
             'two' => 2, 
         },
 };
 
 printf "Output: %s", some_keys( $hash_ref, [ ['A'], ['B', 0], ['C', 'one'] ] );
 # Output: 1
 printf "Output: %s", some_keys( $hash_ref, [ ['A', 'one'], ['B', 0], ['C', 'three'] ] );
 # Output: 0

=cut


=head1 SEE ALSO

L<Hash::Util>, L<Deep::Hash::Utils>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Vitaly Simul <vitalysimul@gmail.com>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.



=head1 AUTHOR

Vitaly Simul <vitalysimul@gmail.com>

=cut
