package Iterator::Flex::Common;

# ABSTRACT: Iterator Generators and Adapters

use 5.10.0;
use strict;
use warnings;

use experimental ( 'postderef', 'signatures' );

our $VERSION = '0.19';

use Exporter 'import';

our @EXPORT_OK = qw[
  iterator iter iarray icycle icache
  icat igrep imap iproduct iseq istack ifreeze thaw
];

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Ref::Util             qw[ is_arrayref is_hashref is_ref is_globref ];
use Module::Runtime       qw[ require_module ];
use Iterator::Flex::Utils qw[ throw_failure ];
use Iterator::Flex::Factory;




























sub iterator : prototype(&@) ( $code, $pars = {} ) {
    Iterator::Flex::Factory->construct_from_iterable( $code, $pars );
}

















sub iter ( $iterable, $pars = {} ) {
    Iterator::Flex::Factory->to_iterator( $iterable, $pars );
}




























sub iarray ( $array, $pars = {} ) {
    require Iterator::Flex::Array;
    return Iterator::Flex::Array->new( $array, $pars );
}





























sub icache ( $iterable, $pars = {} ) {
    require Iterator::Flex::Cache;
    Iterator::Flex::Cache->new( $iterable, $pars );
}



































sub icat ( @args ) {
    require Iterator::Flex::Cat;
    Iterator::Flex::Cat->new( @args );
}


























sub icycle ( $array, $pars = {} ) {
    require Iterator::Flex::Cycle;
    return Iterator::Flex::Cycle->new( $array, $pars );
}























sub igrep : prototype(&$) ( $code, $pars = {} ) {
    require Iterator::Flex::Grep;
    Iterator::Flex::Grep->new( $code, $pars );
}
























sub imap : prototype(&$) ( $code, $pars = {} ) {
    require Iterator::Flex::Map;
    Iterator::Flex::Map->new( $code, $pars );
}





































sub iproduct {
    require Iterator::Flex::Product;
    return Iterator::Flex::Product->new( @_ );
}
































sub iseq {
    require Iterator::Flex::Sequence;
    Iterator::Flex::Sequence->new( @_ );
}

























sub istack ( @args ) {
    require Iterator::Flex::Stack;
    Iterator::Flex::Stack->new( @args );
}


































sub ifreeze : prototype(&$) ( $code, $pars = {} ) {
    require Iterator::Flex::Freeze;
    Iterator::Flex::Freeze->new( $code, $pars );
}













sub thaw ( $frozen, $pars = {} ) {

    my @steps = $frozen->@*;

    # parent data and iterator state is last
    my $exhausted = pop @steps;
    my $parent    = pop @steps;

    my @depends = map { thaw( $_ ) } @steps;

    my ( $package, $state ) = @$parent;

    throw_failure( parameter => "state argument for $package constructor must be a HASH  reference" )
      unless is_hashref( $state );

    require_module( $package );
    my $new_from_state = $package->can( 'new_from_state' )
      or
      throw_failure( parameter => "unable to thaw: $package doesn't provide 'new_from_state' method" );

    $state->{depends} = \@depends
      if @depends;

    $state->{thaw} = 1;

    my $iter = $package->$new_from_state( $state, $pars );
    $exhausted ? $iter->set_exhausted : $iter->_clear_state;
    return $iter;
}

1;

#
# This file is part of Iterator-Flex
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory icat istack

=head1 NAME

Iterator::Flex::Common - Iterator Generators and Adapters

=head1 VERSION

version 0.19

=head1 SYNOPSIS

 use Iterator::Flex::Common ':all'

 # generate an iterator which returns undef upon exhaustion
 my $iter = iseq( 0, 10, 2 );
 my $value;
 say $value while defined $value = $iter->next;
 # 0 2 4 6 8 10

 # generate an iterator which returns -1 upon exhaustion
 my $iter = iseq( 1, 10, 2, { exhaustion => [ 'return', -1 ] } );
 my $value;
 say $value while ($value = $iter->next) >= 0 ;
 # 1 3 4 7 9

=head1 DESCRIPTION

C<Iterator::Flex::Common> provides generators for iterators
for common uses, such as iterating over arrays, generating numeric
sequences, wrapping subroutines or other L<iterable
objects|Iterator::Flex::Manual::Glossary/iterable object> or adapting
other iterator data streams.

All of the generated iterators and adaptors support the C<next>
capability; some support additional ones.  For adapters, some
capabilities are supported only if the iterable they operate on
supports them.  For example, L</icache> can't provide the C<reset> or
C<rewind> capabilities if the iterable reads from the terminal.  In
these cases, attempting to use this capability will result in an
error.

See L<Iterator::Flex::Manual::Overview/Capabilities> for a full list
of capabilities.

=head2 Generator Parameters

Most of the generators take an optional trailing hash, C<%pars>, to
accommodate optional parameters.

Iterator generators accept the C<exhaustion> (see
L<Iterator::Flex::Manual::Overview/exhaustion>) and C<error> (see
L<Iterator::Flex::Manual::Overview/error>) parameters, which indicate
how the generated iterator or adaptor will signal exhaustion and
error.

Adapter generators additionally accept the C<input_exhaustion> (see
L<Iterator::Flex::Manual::Overview/input_exhaustion>)
parameter, specifying how the input iterator will signal exhaustion.

Some generators have parameters specific to what they do, for example
the L<icache> adaptor generator has an optional C<capacity> option.

=head1 SUBROUTINES

=head2 iterator

  $iter = iterator { CODE } ?\%pars;

Construct an iterator from code. The code will have access to the
iterator object through C<$_[0]>. By default the code is expected to
return C<undef> upon exhaustion; this assumption can be changed by setting the
C<input_exhaustion> parameter (see
L<Iterator::Flex::Manual::Overview/input_exhaustion>).

For example, here's a simple integer sequence iterator that counts up to 100:

 #! /usr/bin/perl
 use strict;
 use warnings;
 use v5.10.0;
 
 use Iterator::Flex::Common ':all';
 
 my $seq = 0;
 my $iter = iterator { return $seq < 100 ? ++$seq : undef } ;
 while ( defined ( my $r = $iter->() ) ) {
     #...
 }
 1;

See L</Parameters> for a description of C<%pars>

The returned iterator supports the following methods:

=over

=item next

=back

=head2 iter

  $iter = iter( $iterable, ?\%pars );

Construct an iterator from an L<iterable
thing|Iterator::Flex::Manual::Glossary/iterable thing>.  By default
C<$iterable> is expected to
return C<undef> upon exhaustion; this assumption can be changed by setting the
C<input_exhaustion> parameter (see
L<Iterator::Flex::Manual::Overview/input_exhaustion>).

See L</Parameters> for a description of C<%pars>

=head2 iarray

  $iterator = iarray( $array_ref, ?\%pars );

Wrap an array in an iterator. See L<Iterator::Flex::Array> for more details.

The returned iterator supports the following methods:

=over

=item current

=item next

=item prev

=item rewind

=item reset

=item freeze

=back

=head2 icache

  $iterator = icache( $iterable, ?\%pars );

The iterator caches the current and previous values of the passed iterator,
See L<Iterator::Flex::Cache> for more details.

The returned iterator supports the following methods:

=over

=item reset

=item rewind

=item next

=item prev

=item current

=item freeze

=back

=head2 icat

  $iterator = icat( @iterables, ?\%pars );

Concatenate the iterables.  As each iterator is exhausted, the next
one is queried for its values.  See L<Iterator::Flex::Cat> for more
details.

The returned iterator supports the following methods:

=over

=item reset

If all of the iterables support it.

=item rewind

If all of the iterables support it.

=item next

=item prev

=item current

=item freeze

If all of the iterables support it.

=back

=head2 icycle

  $iterator = icycle( $array_ref, ?\%pars );

Wrap an array in an iterator.  The iterator will continuously cycle through the array's values.
See L<Iterator::Flex::Cycle> for more details.

=over

=item current

=item next

=item prev

=item rewind

=item reset

=item freeze

=back

=head2 igrep

  $iterator = igrep { CODE } $iterable, ?\%pars;

Returns an iterator equivalent to running C<grep> on C<$iterable> with the specified code.
C<CODE> is I<not> run if C<$iterable> is exhausted.  To indicate how C<$iterable> signals
exhaustion, use the C<input_exhaustion> general parameter; by default it is expected to return
C<undef>. See L<Iterator::Flex::Grep> for more details.

The iterator supports the following methods:

=over

=item next

=item reset

=back

=head2 imap

  $iterator = imap { CODE } $iterable, ?\%pars;

Returns an iterator equivalent to running C<map> on C<$iterable> with
the specified code.  C<CODE> is I<not> run if C<$iterable> is
exhausted.  To indicate how C<$iterable> signals exhaustion, use the
C<input_exhaustion> general parameter; by default it is expected to
return C<undef>. See L<Iterator::Flex::Map> for more details.

The iterator supports the following methods:

=over

=item next

=item reset

=back

=head2 iproduct

  $iterator = iproduct( $iterable1, $iterable2, ..., ?\%pars );
  $iterator = iproduct( key1 => $iterable1, key2 => iterable2, ..., ?\%pars );

Returns an iterator which produces a Cartesian product of the input iterables.
If the input to B<iproduct> is a list of iterables, C<$iterator> will return an
array reference containing an element from each iterable.

If the input is a list of key, iterable pairs, C<$iterator> will return a
hash reference.

All of the iterables must support the C<rewind> method.

The iterator supports the following methods:

=over

=item current

=item next

=item reset

=item rewind

=item freeze

This iterator may be frozen only if all of the iterables support the
C<prev> or C<__prev__> method.

=back

=head2 iseq

  # integer sequence starting at 0, incrementing by 1, ending at $end
  $iterator = iseq( $end );

  # integer sequence starting at $begin, incrementing by 1, ending at $end
  $iterator = iseq( $begin, $end );

  # real sequence starting at $begin, incrementing by $step, ending <= $end
  $iterator = iseq( $begin, $end, $step );

The iterator supports the following methods:

=over

=item current

=item next

=item prev

=item rewind

=item freeze

=back

=head2 istack

  $iterator = istack( \@iterables, ?\%pars );

A stack of iterables.  It returns the next value from the iterator at
the top of the stack.  Iterators are popped when they are exhausted.
It supports C<push>, C<pop>, C<shift>, and C<unshift> methods, which
have same API as the Perl builtin subroutines.  See
L<Iterator::Flex::Stack> for more details.

The returned iterator supports the following methods:

=over

=item next

=item prev

=item current

=back

=head2 ifreeze

  $iter = ifreeze { CODE } $iterator, ?\%pars;

Construct a pass-through iterator which freezes the input iterator
after every call to C<next>.  C<CODE> will be passed the frozen state
(generated by calling C<$iterator->freeze> via C<$_>, with which it
can do as it pleases.

<CODE> I<is> executed when C<$iterator> returns I<undef> (that is,
when C<$iterator> is exhausted).

The returned iterator supports the following methods:

=over

=item next

=item prev

If C<$iterator> provides a C<prev> method.

=item rewind

=item freeze

=back

See L<Iterator::Flex::Manual::Serialization> for more information.

=head2 thaw

   $frozen = $iterator->freeze;
   $iterator = thaw( $frozen, ?\%pars );

Restore an iterator that has been frozen.
See L<Iterator::Flex::Manual::Serialization> for more information.

=head1 INTERNALS

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-iterator-flex@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Iterator-Flex>

=head2 Source

Source is available at

  https://gitlab.com/djerius/iterator-flex

and may be cloned from

  https://gitlab.com/djerius/iterator-flex.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Iterator::Flex|Iterator::Flex>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
