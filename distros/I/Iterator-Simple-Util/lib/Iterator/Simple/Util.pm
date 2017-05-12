package Iterator::Simple::Util;
{
  $Iterator::Simple::Util::VERSION = '0.002';
}

# ABSTRACT: Port of List::Util and List::MoreUtils to Iterator::Simple

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ qw( igroup ireduce isum
                     imax imin imaxstr iminstr imax_by imin_by imaxstr_by iminstr_by
                     iany inone inotall
                     ifirstval ilastval
                     ibefore ibefore_incl iafter iafter_incl
                     inatatime
               )
             ]
};

use Const::Fast;
use Iterator::Simple qw( iter iterator ichain );

const my $TRUE  => !0;
const my $FALSE => !1;

sub _ensure_coderef {
    unless( ref( shift ) eq 'CODE' ) {
        require Carp;
        Carp::croak("Not a subroutine reference");
    }
}

sub _wrap_code {
    my $code = shift;

    return sub {
        $_ = shift;
        $code->();
    };
}


sub igroup (&$) {
    my ( $is_same_group, $base_iter ) = @_;    

    _ensure_coderef( $is_same_group );

    $base_iter = iter $base_iter;

    my $next_record = $base_iter->next;

    # Localize caller's $a and $b
    my ( $caller_a, $caller_b ) = do {
        require B;
        my $caller = B::svref_2object( $is_same_group )->STASH->NAME;        
        no strict 'refs';
        map  \*{$caller.'::'.$_}, qw( a b );
    };
    local ( *$caller_a, *$caller_b );
    
    return iterator {
        defined( my $base_record = $next_record )
            or return;

        return iterator {
            return unless defined $next_record;
            ( *$caller_a, *$caller_b ) = \( $base_record, $next_record );
            return unless $is_same_group->();
            my $res = $next_record;
            $next_record = $base_iter->next;
            return $res;
        };
    };
}


sub ireduce (&$;$) {

    my ( $code, $init_val, $iter );
    
    if ( @_ == 2 ) {
        ( $code, $iter ) = @_;
    }
    else {
        ( $code, $init_val, $iter ) = @_;
    }

    _ensure_coderef( $code );
    $iter = iter $iter;
    
    # Localize caller's $a and $b
    my ( $caller_a, $caller_b ) = do {
        require B;
        my $caller = B::svref_2object( $code )->STASH->NAME;        
        no strict 'refs';
        map  \*{$caller.'::'.$_}, qw( a b );
    };
    local ( *$caller_a, *$caller_b ) = \my ( $x, $y );    

    $x = @_ == 3 ? $init_val : $iter->next;
    
    defined( $x )
        or return;

    defined( $y = $iter->next )
        or return $x;
    
    while( defined $x and defined $y ) {
        $x = $code->();
        $y = $iter->next;
    }
    
    return $x;
}


sub isum ($;$) {
    my ( $init_val, $iter );

    if ( @_ == 1 ) {
        $init_val = 0;
        $iter = $_[0];
    }
    else {
        ( $init_val, $iter ) = @_;
    }

    ireduce { $a + $b } $init_val, $iter;
}


sub imax ($) {
    ireduce { $a > $b ? $a : $b } shift;
}


sub imin ($) {
    ireduce { $a < $b ? $a : $b } shift;
}


sub imax_by (&$) {
    my ( $code, $iter ) = @_;

    _ensure_coderef( $code );
    $code = _wrap_code( $code );
        
    ireduce { $code->($a) > $code->($b) ? $a : $b } $iter;
}


sub imin_by (&$) {
    my ( $code, $iter ) = @_;
    
    _ensure_coderef( $code );
    $code = _wrap_code( $code );
    
    ireduce { $code->($a) < $code->($b) ? $a : $b } $iter;
}


sub imaxstr ($) {
    ireduce { $a gt $b ? $a : $b } shift;
}


sub iminstr ($) {
    ireduce { $a lt $b ? $a : $b } shift;
}


sub imaxstr_by (&$) {
    my ( $code, $iter ) = @_;

    _ensure_coderef( $code );
    $code = _wrap_code( $code );
    
    ireduce { $code->($a) gt $code->($b) ? $a : $b } $iter;
}


sub iminstr_by (&$) {
    my ( $code, $iter ) = @_;

    _ensure_coderef( $code );
    $code = _wrap_code( $code );
    
    ireduce { $code->($a) lt $code->($b) ? $a : $b } $iter;
}


sub iany (&$) {
    my ( $code, $iter ) = @_;

    _ensure_coderef( $code );
    $iter = iter $iter;
    
    while( defined( $_ = $iter->next ) ) {
        $code->() and return $TRUE;
    }

    return $FALSE;
}


sub inone (&$) {
    my ( $code, $iter ) = @_;

    _ensure_coderef( $code );
    $iter = iter $iter;

    while( defined( $_ = $iter->next ) ) {
        $code->() and return $FALSE;
    }

    return $TRUE;
}


sub inotall (&$) {
    my ( $code, $iter ) = @_;

    _ensure_coderef( $code );
    $iter = iter $iter;

    while( defined( $_ = $iter->next ) ) {
        return $TRUE if ! $code->();
    }

    return $FALSE;
}


sub ifirstval (&$) {
    my ( $code, $iter ) = @_;
    _ensure_coderef( $code );
    $iter = iter $iter;
    
    while( defined( $_ = $iter->next ) ) {
        $code->() and return $_;
    }

    return;
}


sub ilastval (&$) {
    my ( $code, $iter ) = @_;

    _ensure_coderef( $code );
    $iter = iter $iter;
    
    my $val;
    while( defined( $_ = $iter->next ) ) {
        $val = $_ if $code->();
    }

    return $val;
}


sub ibefore (&$) {
    my ( $code, $iter ) = @_;

    _ensure_coderef( $code );
    $iter = iter $iter;

    return iterator {
        defined( $_ = $iter->next )
            or return;
        $code->()
            and return;
        return $_;
    };
}


sub ibefore_incl (&$) {
    my ( $code, $iter ) = @_;

    _ensure_coderef( $code );
    $iter = iter $iter;

    my $done = $FALSE;
    
    return iterator {
        not( $done ) and defined( $_ = $iter->next )
            or return;
        $code->() and $done = $TRUE;
        return $_;
    };
}


sub iafter (&$) {
    my ( $code, $iter ) = @_;

    _ensure_coderef( $code );
    $iter = iter $iter;

    while( defined( $_ = $iter->next ) ) {
        last if $code->();
    }

    return $iter;
}


sub iafter_incl (&$) {
    my ( $code, $iter ) = @_;

    _ensure_coderef( $code );
    $iter = iter $iter;

    while( defined( $_ = $iter->next ) ) {
        last if $code->();
    }

    return ichain iter( [$_] ), $iter;
}


sub inatatime ($$) {
    my ($kicks, $iter) = @_;

    $iter = iter $iter;

    return iterator {
        my @vals;

        for (1 .. $kicks) {
            my $val = $iter->next;
            last unless defined $val;
            push @vals, $val;
        }
        return @vals ? \@vals : undef;
    };
}


1;



=pod

=head1 NAME

Iterator::Simple::Util - Port of List::Util and List::MoreUtils to Iterator::Simple

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Iterator::Simple::Util qw(  igroup ireduce isum
                                    imax imin imaxstr iminstr imax_by imin_by imaxstr_by iminstr_by
                                    iany inone inotall
                                    ifirstval ilastval
                                    ibefore ibefore_incl iafter iafter_incl
                                    inatatime );

=head1 DESCRIPTION

B<Iterator::Simple::Util> implements many of the functions from
L<List::Util> and L<List::MoreUtils> for iterators generated by
L<Iterator::Simple>.

=head1 EXPORTS

All of these functions call C<Iterator::Simple::iter()> on the
I<I<ITERABLE>> argument; this detects what I<I<ITERABLE>> is and turns it
into an iterator. See L<iterator::Simple> for details.

Functions taking a I<BLOCK> expect a code block that operates on
C<$_> or, in the case of B<igroup> and B<ireduce>, on C<$a> and C<$b>.

=over 4

=item igroup I<BLOCK> I<ITERABLE>

=item ireduce I<BLOCK> [I<INIT_VAL>] I<ITERABLE>

Reduces I<ITERABLE> by calling I<BLOCK>, in a scalar context, multiple times,
setting C<$a> and C<$b> each time. The first call will be with C<$a>
and C<$b> set to the first two elements of the list, subsequent
calls will be done by setting C<$a> to the result of the previous
call and C<$b> to the next element in the list.

Returns the result of the last call to I<BLOCK>. If the iterator is
empty then C<undef> is returned. If the iterator only contains one
element then that element is returned and I<BLOCK> is not executed.

    $foo = ireduce { $a < $b ? $a : $b } $iterator  # min
    $foo = ireduce { $a lt $b ? $a : $b } $iterator # minstr
    $foo = ireduce { $a + $b } $iterator            # sum
    $foo = ireduce { $a . $b } $iterator            # concat

If your algorithm requires that C<reduce> produce an identity value, then
make sure that you always pass that identity value as the first argument to prevent
C<undef> being returned. For example:

    $foo = ireduce { $a + $b } 0, $iterator

will return 0 (rather than C<undef>) when C<$iterator> is empty.

=item isum [I<INIT_VAL>] I<ITERABLE>

Returns the sum of the elements of I<ITERABLE>, which should return
numeric values. Returns 0 if the iterator is empty.

=item imax I<ITERABLE>

Returns the maximum value of I<ITERABLE>, which should produce numeric
values. Retruns C<undef> if the iterator is empty.        

=item imin I<ITERABLE>

Returns the minimum value of I<ITERABLE>, which should produce numeric
values. Returns C<undef> if the iterator is empty.

=item imax_by I<BLOCK> I<ITERABLE>

Return the value of I<ITERABLE> for which I<BLOCK> produces the maximum value.
For example:

   imax_by { $_ * $_ } iter( [ -5 -2 -1 0 1 2 ] )

will return C<-5>.

=item imin_by I<BLOCK> I<ITERABLE>

Similar to B<imax_by>, but returns the value of I<ITERABLE> for which
I<BLOCK> produces the minimum value.

=item imaxstr I<ITERABLE>

Similar to B<imax>, but expects I<ITERABLE> to return string values.

=item iminstr I<ITERABLE>

Similar to B<imin>, but expects I<ITERABLE> to return string values.

=item imaxstr_by I<BLOCK> I<ITERABLE>

Similar to B<imax_by>, but expects I<ITERABLE> to return string values.

=item iminstr_by I<BLOCK> I<ITERABLE>

Similar to B<imin_by>, but expects I<ITERABLE> to return string values.

=item iany I<BLOCK> I<ITERABLE>

Returns a true value if any item produced by I<ITERABLE> meets the
criterion given through I<BLOCK>. Sets C<$_> for each item in turn:

    print "At least one value greater than 10"
        if iany { $_ > 10 } $iterator;

Returns false otherwise, or if the iterator is empty.

=item inone I<BLOCK> I<ITERABLE>

Returns a true value if no item produced by I<ITERABLE> meets the
criterion given through I<BLOCK>, or if the iterator is empty. Sets
C<$_> for each item in turn:

    print "No values greater than 10"
        if inone { $_ > 10 } $iterator;

Returns false otherwise.

=item inotall I<BLOCK> I<ITERABLE>

Logically the negation of I<all>. Returns true if I<BLOCK> returns
false for some value of I<ITERABLE>:

   print "Not all even"
     if inotall { $_ % 2 == 0 } $iterator;

Returns false if the iterator is empty, or all values of I<BLOCK>
produces a true value for every item produced by I<ITERABLE>.

=item ifirstval I<BLOCK> I<ITERABLE>

Returns the first element produced by I<ITERABLE> for which I<BLOCK>
evaluates to true. Each element produced by I<ITERABLE> is set to
C<$_> in turn. Returns C<undef> if no such element has been found.

=item ilastval I<BLOCK> I<ITERABLE>

Returns the last element produced by I<ITERABLE> for which I<BLOCK>
evaluates to true. Each element of I<ITERABLE> is set to C<$_> in
turn. Returns C<undef> if no such element has been found.

=item ibefore I<BLOCK> I<ITERABLE>

Returns an iterator that will produce all values of I<ITERABLE> upto
(and not including) the point where I<BLOCK> returns a true
value. Sets C<$_> for each element in turn.

=item ibefore_incl I<BLOCK> I<ITERABLE>

Returns an iterator that will produce all values of I<ITERABLE> upto
(and including) the point where I<BLOCK> returns a true value. Sets
C<$_> for each element in turn.

=item iafter I<BLOCK> I<ITERABLE>

Returns an iterator that will produce all values of I<ITERABLE> after
(and not including) the point where I<BLOCK> returns a true
value. Sets C<$_> for each element in turn.

    $it = iafter { $_ % 5 == 0 } [1..9];    # $it returns 6, 7, 8, 9

=item iafter_incl I<BLOCK> I<ITERABLE>

Returns an iterator that will produce all values of I<ITERABLE> after
(and including) the point where I<BLOCK> returns a true value. Sets
C<$_> for each element in turn.

    $it = iafter_incl { $_ % 5 == 0 } [1..9];    # $it returns 5, 6, 7, 8, 9

=item inatatime I<KICKS> I<ITERABLE>

Creates an array iterator that returns array refs of elements from
I<ITERABLE>, I<KICKS> items at a time. For example:

    my $it = inatatime 3, iter( [ 'a' .. 'g' ] );
    while( my $vals = $it->next ) {
        print join( ' ', @{$vals} ) . "\n";
    }

This prints:

    a b c
    d e f
    g

=back

=head1 AUTHOR

Ray Miller <raym@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ray Miller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

    
