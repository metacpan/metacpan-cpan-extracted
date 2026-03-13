##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/MM/Table.pm
## Version v0.5.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/03
## Modified 2026/03/04
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package MM::Table;
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $VERSION );
    use Scalar::Util qw( blessed );
    use Mail::Make::Exception;
    use overload (
        '%{}'    => '_as_hashref',
        fallback => 1
    );
    our $VERSION = 'v0.5.0';
};

use strict;
use warnings;

sub make
{
    my( $class ) = @_;

    my $state =
    {
        _entries   => [],   # array of { key => original, lkey => lc, val => string }
        _error     => undef,
        _tied_href => undef,
    };

    my $self = bless( \$state, $class );
    return( $self );
}

sub add
{
    my( $self, $key, $val ) = @_;

    $self->_validate_key( $key ) || return( $self->pass_error );
    $val = $self->_stringify_value( $val );
    my $lkey = lc( $key );

    my $st = $self->_state();
    push( @{$st->{_entries}}, { key => $key, lkey => $lkey, val => $val } );

    $self->_invalidate_tie_cache();
    return( $self );
}

sub clear
{
    my( $self ) = @_;
    my $st = $self->_state();
    $st->{_entries} = [];
    $self->_invalidate_tie_cache();
    return( $self );
}

sub compress
{
    my( $self, $flags ) = @_;

    $self->_validate_overlap_flags( $flags, 'compress' ) || return( $self->pass_error );
    $flags //= 0;

    my $st  = $self->_state();
    my $src = $st->{_entries} || [];
    my @out;

    my %seen_idx;

    for( my $i = 0; $i < scalar( @$src ); $i++ )
    {
        my $e    = $src->[ $i ];
        my $lkey = $e->{lkey};

        if( !exists( $seen_idx{ $lkey } ) )
        {
            push( @out,
            {
                key  => $e->{key},
                lkey => $lkey,
                val  => $e->{val},
            });
            $seen_idx{ $lkey } = scalar( @out ) - 1;
            next;
        }

        my $idx = $seen_idx{ $lkey };

        if( $flags )
        {
            $out[ $idx ]->{val} = $out[$idx]->{val} . ', ' . $e->{val};
        }
        else
        {
            $out[ $idx ]->{key} = $e->{key};
            $out[ $idx ]->{val} = $e->{val};
        }
    }

    $st->{_entries} = \@out;
    $self->_invalidate_tie_cache();
    return( $self );
}

sub copy
{
    my( $self ) = @_;

    my $class = ref( $self ) || $self;

    my $state =
    {
        _entries   => [],
        _error     => undef,
        _tied_href => undef,
    };

    my $new = bless( \$state, $class );

    my $src = $self->_state()->{_entries} || [];
    my $dst = $new->_state()->{_entries};

    for( my $i = 0; $i < scalar( @$src ); $i++ )
    {
        my $e = $src->[ $i ];
        push( @$dst,
        {
            key  => $e->{key},
            lkey => $e->{lkey},
            val  => $e->{val},
        });
    }

    return( $new );
}

sub do
{
    my( $self, $sub, @filter ) = @_;

    return( $self->error( "MM::Table->do: missing callback." ) ) if( !defined( $sub ) );

    my $cb;
    if( ref( $sub ) eq 'CODE' )
    {
        $cb = $sub;
    }
    elsif( !ref( $sub ) )
    {
        my $name = $sub;
        if( $name !~ /::/ )
        {
            my $pkg = (caller())[0];
            $name = $pkg . '::' . $name;
        }

        no strict 'refs';
        my $code = *{$name}{CODE};
        return( $self->error( "MM::Table->do: could not resolve callback '$sub'." ) ) if( !$code );
        $cb = $code;
    }
    else
    {
        return( $self->error( "MM::Table->do: callback must be a CODE reference or a sub name." ) );
    }

    my %filter;
    if( scalar( @filter ) )
    {
        for( my $i = 0; $i < scalar( @filter ); $i++ )
        {
            my $k = $filter[ $i ];
            next if( !defined( $k ) );
            $filter{ lc( "$k" ) } = 1;
        }
    }

    my $src = $self->_state()->{_entries} || [];

    for( my $i = 0; $i < scalar( @$src ); $i++ )
    {
        my $e = $src->[ $i ];

        if( scalar( %filter ) )
        {
            next if( !$filter{ $e->{lkey} } );
        }

        my $ok = $cb->( $e->{key}, $e->{val} );
        last if( !$ok );
    }

    return( $self );
}

# error( [$message] )
# With an argument  : creates a Mail::Make::Exception, stores it in the
#                     instance, and returns undef (or empty list).
# Without argument  : returns the stored exception object, or undef.
sub error
{
    my $self = shift( @_ );
    my $st   = $self->_state();
    if( @_ )
    {
        my $msg = join( '', @_ );
        my $o   = Mail::Make::Exception->new( $msg );
        $st->{_error} = $o;
        warn( $o->as_string ) if( warnings::enabled( scalar( caller ) ) );
        return;
    }
    return( $st->{_error} );
}

sub get
{
    my( $self, $key ) = @_;

    $self->_validate_key( $key ) || return( $self->pass_error );
    my $lkey = lc( $key );

    my $src = $self->_state()->{_entries} || [];

    if( wantarray )
    {
        my @vals;
        for( my $i = 0; $i < scalar( @$src ); $i++ )
        {
            my $e = $src->[ $i ];
            next if( $e->{lkey} ne $lkey );
            push( @vals, $e->{val} );
        }
        return( @vals );
    }

    for( my $i = 0; $i < scalar( @$src ); $i++ )
    {
        my $e = $src->[ $i ];
        next if( $e->{lkey} ne $lkey );
        return( $e->{val} );
    }

    return;
}

sub merge
{
    my( $self, $key, $val ) = @_;

    $self->_validate_key( $key ) || return( $self->pass_error );
    $val = $self->_stringify_value( $val );
    my $lkey = lc( $key );

    my $st  = $self->_state();
    my $src = $st->{_entries} || [];

    for( my $i = 0; $i < scalar( @$src ); $i++ )
    {
        my $e = $src->[ $i ];
        next if( $e->{lkey} ne $lkey );

        $e->{val} = $e->{val} . ', ' . $val;
        $self->_invalidate_tie_cache();
        return( $self );
    }

    push( @$src, { key => $key, lkey => $lkey, val => $val } );
    $self->_invalidate_tie_cache();
    return( $self );
}

sub overlap
{
    my( $self, $other, $flags ) = @_;

    $self->_validate_table( $other )         || return( $self->pass_error );
    $self->_validate_overlap_flags( $flags ) || return( $self->pass_error );
    $flags //= 0;

    my $o = $other->_state()->{_entries} || [];
    for( my $i = 0; $i < scalar( @$o ); $i++ )
    {
        my $e = $o->[ $i ];
        if( $flags )
        {
            $self->merge( $e->{key}, $e->{val} ) || return( $self->pass_error );
        }
        else
        {
            $self->set( $e->{key}, $e->{val} ) || return( $self->pass_error );
        }
    }
    return( $self );
}

sub overlay
{
    my( $self, $other ) = @_;

    $self->_validate_table( $other ) || return( $self->pass_error );

    my $class = ref( $self ) || $self;

    my $state =
    {
        _entries   => [],
        _error     => undef,
        _tied_href => undef,
    };

    my $new = bless( \$state, $class );

    my $dst = $new->_state()->{_entries};

    my $o = $other->_state()->{_entries} || [];
    for( my $i = 0; $i < scalar( @$o ); $i++ )
    {
        my $e = $o->[ $i ];
        push( @$dst, { key => $e->{key}, lkey => $e->{lkey}, val => $e->{val} } );
    }

    my $s = $self->_state()->{_entries} || [];
    for( my $i = 0; $i < scalar( @$s ); $i++ )
    {
        my $e = $s->[$i];
        push( @$dst, { key => $e->{key}, lkey => $e->{lkey}, val => $e->{val} } );
    }

    return( $new );
}

# pass_error()
# Propagates the error stored in this instance: sets it as the current
# error and returns undef (or empty list), exactly as error() does, but
# without creating a new exception object.
sub pass_error
{
    my $self = shift( @_ );
    # If called with arguments, delegate to error() to create a new exception.
    return( $self->error( @_ ) ) if( @_ );
    # No arguments: the error is already stored in the instance by the method
    # that failed. We simply return, letting Perl resolve the context: undef
    # in scalar context, empty list in list context.
    return;
}

sub set
{
    my( $self, $key, $val ) = @_;

    $self->_validate_key( $key ) || return( $self->pass_error );
    $val = $self->_stringify_value( $val );
    my $lkey = lc( $key );

    my $st  = $self->_state();
    my $src = $st->{_entries} || [];
    my @kept;

    for( my $i = 0; $i < scalar( @$src ); $i++ )
    {
        my $e = $src->[ $i ];
        next if( $e->{lkey} eq $lkey );
        push( @kept, $e );
    }

    push( @kept, { key => $key, lkey => $lkey, val => $val } );

    $st->{_entries} = \@kept;
    $self->_invalidate_tie_cache();
    return( $self );
}

sub unset
{
    my( $self, $key ) = @_;

    $self->_validate_key( $key ) || return( $self->pass_error );
    my $lkey = lc( $key );

    my $st  = $self->_state();
    my $src = $st->{_entries} || [];
    my @kept;

    for( my $i = 0; $i < scalar( @$src ); $i++ )
    {
        my $e = $src->[ $i ];
        next if( $e->{lkey} eq $lkey );
        push( @kept, $e );
    }

    $st->{_entries} = \@kept;
    $self->_invalidate_tie_cache();
    return( $self );
}

# NOTE: tied-hash like APR::Table
sub _as_hashref
{
    my( $self ) = @_;

    my $st = $self->_state();

    if( defined( $st->{_tied_href} ) )
    {
        return( $st->{_tied_href} );
    }

    my %h;
    tie( %h, 'MM::Table::Tie', $self );

    $st->{_tied_href} = \%h;
    return( $st->{_tied_href} );
}

sub _invalidate_tie_cache
{
    my( $self ) = @_;

    my $st = $self->_state();
    # Drop our own reference to the tied hash. If the caller holds a copy of
    # the \%{} deref, Perl will keep the tie alive until that reference is
    # released - untie() would warn in that case, so we leave it to Perl's
    # normal reference counting and simply clear our cached pointer so that
    # the next %{} deref creates a fresh, correctly-initialised tie.
    $st->{_tied_href} = undef;

    return;
}

sub _state
{
    my( $self ) = @_;
    return( ${$self} );
}

sub _stringify_value
{
    my( $self, $val ) = @_;
    return( defined( $val ) ? "$val" : '' );
}

sub _validate_key
{
    my( $self, $key ) = @_;
    if( !defined( $key ) || ref( $key ) )
    {
        return( $self->error( "MM::Table: key must be a defined non-reference scalar." ) );
    }
    return(1);
}

sub _validate_overlap_flags
{
    my( $self, $flags, $method ) = @_;
    $method ||= 'method';
    return(1) if( !defined( $flags ) );

    if( $flags !~ /^\d+\z/ )
    {
        return( $self->error( "MM::Table->$method: invalid flags '$flags' (expected 0 or 1)." ) );
    }

    $flags = int( $flags );
    if( $flags != 0 && $flags != 1 )
    {
        return( $self->error( "MM::Table->$method: invalid flags '$flags' (expected 0 or 1)." ) );
    }

    return(1);
}

sub _validate_table
{
    my( $self, $other ) = @_;
    if( !blessed( $other ) || !$other->isa( 'MM::Table' ) )
    {
        return( $self->error( "MM::Table: expected an MM::Table object, got '" . ( ref( $other ) || 'undef' ) . "'." ) );
    }
    return(1);
}

1;
# NOTE: package MM::Table::Tie
package MM::Table::Tie;

use strict;
use warnings;

sub TIEHASH
{
    my( $class, $table ) = @_;
    # This is a programming error, not a runtime one - die is appropriate here.
    unless( defined( $table ) && ref( $table ) eq 'MM::Table' )
    {
        die( "MM::Table::Tie: expected an MM::Table instance, got '" . ( ref( $table ) || 'undef' ) . "'.\n" );
    }

    return( bless(
    {
        _table => $table,
        _iter  => 0,
        _curr  => undef,
    }, $class ) );
}

sub CLEAR
{
    my( $self ) = @_;
    $self->{_table}->clear();
    return;
}

sub DELETE
{
    my( $self, $key ) = @_;
    $self->{_table}->unset( $key );
    return;
}

sub DESTROY
{
    my( $self ) = @_;
    return;
}

sub EXISTS
{
    my( $self, $key ) = @_;

    return(0) unless( defined( $key ) && !ref( $key ) );
    my $lkey = lc( $key );

    my $src = $self->{_table}->_state()->{_entries} || [];
    for( my $i = 0; $i < scalar( @$src ); $i++ )
    {
        my $e = $src->[$i];
        return(1) if( $e->{lkey} eq $lkey );
    }

    return(0);
}

sub FETCH
{
    my( $self, $key ) = @_;

    return( undef ) unless( defined( $key ) && !ref( $key ) );
    my $lkey = lc( $key );

    my $t   = $self->{_table};
    my $src = $t->_state()->{_entries} || [];

    # Fast path: if the iterator is currently positioned on this key, we can
    # return its value without a full scan. This is safe because _curr is only
    # set by NEXTKEY, which always runs against the live _entries array, and
    # FIRSTKEY resets it to undef before any iteration begins.
    if( defined( $self->{_curr} ) )
    {
        my $idx = $self->{_curr};
        if( $idx >= 0 && $idx < scalar( @$src ) )
        {
            my $e = $src->[$idx];
            return( $e->{val} ) if( $e->{lkey} eq $lkey );
        }
    }

    for( my $i = 0; $i < scalar( @$src ); $i++ )
    {
        my $e = $src->[$i];
        next if( $e->{lkey} ne $lkey );
        return( $e->{val} );
    }

    return( undef );
}

sub FIRSTKEY
{
    my( $self ) = @_;
    $self->{_iter} = 0;
    $self->{_curr} = undef;
    return( $self->NEXTKEY( undef ) );
}

sub NEXTKEY
{
    my( $self, $lastkey ) = @_;

    my $src = $self->{_table}->_state()->{_entries} || [];

    if( $self->{_iter} >= scalar( @$src ) )
    {
        $self->{_curr} = undef;
        return( undef );
    }

    my $idx = $self->{_iter};
    $self->{_iter}++;
    $self->{_curr} = $idx;

    return( $src->[$idx]->{key} );
}

sub STORE
{
    my( $self, $key, $val ) = @_;
    return unless( defined( $key ) && !ref( $key ) );
    $self->{_table}->set( $key, $val );
    return;
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

MM::Table - Pure-Perl mimic of APR::Table (multi-valued, case-insensitive table)

=head1 SYNOPSIS

    use MM::Table ();
    use MM::Const qw( :table );

    my $t = MM::Table->make;

    $t->set( Foo => "one" ) || die( $t->error );
    $t->add( foo => "two" ) || die( $t->error );

    my $v  = $t->get( 'FOO' );     # "one" (scalar ctx: oldest)
    my @vs = $t->get( 'foo' );     # ("one","two")

    $t->merge( foo => "three" );   # first "foo" becomes "one, three"

    my $copy = $t->copy;

    my $o = $t->overlay( $copy );

    $t->compress( OVERLAP_TABLES_SET );    # flattens to last value per key
    $t->compress( OVERLAP_TABLES_MERGE );  # flattens to "a, b, c"

    $t->do( sub{ print "$_[0] => $_[1]\n"; 1 } ) || die( $t->error );

    # APR-like deref:
    $t->{foo} = "bar";      # calls set()
    print $t->{foo};        # calls get()
    print "yes\n" if( exists( $t->{foo} ) );

    while( my( $k, $v ) = each( %$t ) )
    {
        print "$k => $v\n";    # duplicates preserved in insertion order
    }

=head1 VERSION

    v0.5.0

=head1 DESCRIPTION

A pure-Perl, ordered, multi-valued, case-insensitive key-value table, modelled on L<APR::Table>. Used internally by L<Mail::Make::Headers> to store mail header fields in insertion order while allowing case-insensitive lookup and multiple values per field name.

=head1 ERROR HANDLING

C<MM::Table> does not inherit from L<Module::Generic>, but follows the same error convention used throughout the C<Mail::Make> ecosystem:

=over 4

=item * On error, a method stores a L<Mail::Make::Exception> object via L</error> and returns C<undef> in scalar context or an empty list in list context.

=item * The caller retrieves the exception with C<< $t->error >>.

=item * L</pass_error> is provided for propagating an error set earlier in the same object.

=back

Because C<MM::Table> is never instantiated by untrusted input and construction cannot fail, there is no class-level C<< MM::Table->error >> - errors are always per-instance.

=head1 CONSTRUCTOR

=head2 make

    my $t = MM::Table->make;

Creates and returns a new, empty C<MM::Table> instance.

=head1 METHODS

=head2 add( $key, $value )

Appends a new entry without removing any existing entries for C<$key>.
Returns C<$self>, or C<undef> on error.

=head2 clear

Removes all entries. Returns C<$self>.

=head2 compress( $flags )

Flattens duplicate keys. C<$flags> must be C<OVERLAP_TABLES_SET> (C<0>) to keep only the last value, or C<OVERLAP_TABLES_MERGE> (C<1>) to join all values with C<", ">. Returns C<$self>, or C<undef> on error.

=head2 copy

Returns a deep copy of the table as a new C<MM::Table> instance.

=head2 do( $callback [, @filter_keys] )

Iterates over all entries in insertion order, calling C<< $callback->( $key, $value ) >> for each. Iteration stops if the callback returns a false value.
If C<@filter_keys> is provided, only entries whose lowercased key matches one of the filter keys are visited. Returns C<$self>, or C<undef> on error.

=head2 error( [$message] )

Without argument: returns the stored L<Mail::Make::Exception> object, or C<undef> if no error has occurred.

With one or more arguments: joins them into a message, creates a L<Mail::Make::Exception>, stores it, and returns C<undef>.

=head2 get( $key )

In scalar context: returns the value of the first matching entry, or C<undef>. In list context: returns all values for C<$key>, in insertion order. Returns C<undef>/empty list on error.

=head2 merge( $key, $value )

If an entry for C<$key> already exists, appends C<", $value"> to its value.
Otherwise behaves like L</add>. Returns C<$self>, or C<undef> on error.

=head2 overlap( $other_table, $flags )

Copies all entries from C<$other_table> into C<$self>. With C<OVERLAP_TABLES_SET> each key is replaced; with C<OVERLAP_TABLES_MERGE> values are appended. Returns C<$self>, or C<undef> on error.

=head2 overlay( $other_table )

Returns a new C<MM::Table> containing all entries from C<$other_table> followed by all entries from C<$self> (C<$other_table> entries come first).
Returns the new table, or C<undef> on error.

=head2 pass_error

Propagates the error currently stored in this instance by returning C<undef>. If called with arguments, delegates to L</error> to create a new exception first.

=head2 set( $key, $value )

Removes all existing entries for C<$key> and adds a single new one.
Returns C<$self>, or C<undef> on error.

=head2 unset( $key )

Removes all entries for C<$key>. Returns C<$self>, or C<undef> on error.

=head1 TIED-HASH INTERFACE

C<MM::Table> overloads C<%{}> to expose a tied hash interface compatible with APR::Table's C<< $t->{key} >> syntax. Assignment calls L</set>, deletion calls L</unset>, and C<each>/C<keys>/C<values> iterate in insertion order. Multiple values for the same key are all visited during iteration.

=head1 NOTES / LIMITATIONS

=over 4

=item * Performance

All lookups are linear scans. C<MM::Table> is designed for the small, bounded sets of headers found in email messages, not for large tables.

=item * C<copy> and the C<$pool> argument

The C<copy> method accepts no arguments. The C<$pool> parameter present in the original C<APR::Table> API has no equivalent here.

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<APR::Table>, L<Mail::Make::Headers>, L<Mail::Make::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
