package File::KDBX::Iterator;
# ABSTRACT: KDBX database iterator

use warnings;
use strict;

use File::KDBX::Error;
use File::KDBX::Util qw(:class :load :search);
use Iterator::Simple;
use Module::Loaded;
use Ref::Util qw(is_arrayref is_coderef is_ref is_scalarref);
use namespace::clean;

BEGIN { mark_as_loaded('Iterator::Simple::Iterator') }
extends 'Iterator::Simple::Iterator';

our $VERSION = '0.901'; # VERSION


sub new {
    my $class = shift;
    my $code  = is_coderef($_[0]) ? shift : sub { undef };

    my $items = @_ == 1 && is_arrayref($_[0]) ? $_[0] : \@_;
    return $class->SUPER::new(sub {
        if (@_) {   # put back
            if (@_ == 1 && is_arrayref($_[0])) {
                $items = $_[0];
            }
            else {
                unshift @$items, @_;
            }
            return;
        }
        else {
            my $next = shift @$items;
            return $next if defined $next;
            return $code->();
        }
    });
}


sub next {
    my $self = shift;
    my $code = shift or return $self->();

    $code = query_any($code, @_);

    while (defined (local $_ = $self->())) {
        return $_ if $code->($_);
    }
    return;
}


sub peek {
    my $self = shift;

    my $next = $self->();
    $self->($next) if defined $next;
    return $next;
}


sub unget {
    my $self = shift;   # Must shift in a statement before calling.
    $self->(@_);
}


sub each {
    my $self = shift;
    my $cb = shift or return @{$self->to_array};

    if (is_coderef($cb)) {
        my $count = 0;
        $cb->($_, $count++, @_) while defined (local $_ = $self->());
    }
    elsif (!is_ref($cb)) {
        $_->$cb(@_) while defined (local $_ = $self->());
    }
    return $self;
}


sub where { shift->grep(@_) }

sub grep {
    my $self = shift;
    my $code = query_any(@_);

    ref($self)->new(sub {
        while (defined (local $_ = $self->())) {
            return $_ if $code->($_);
        }
        return;
    });
}


sub map {
    my $self = shift;
    my $code = shift;

    ref($self)->new(sub {
        local $_ = $self->();
        return if !defined $_;
        return $code->();
    });
}


sub order_by {
    my $self    = shift;
    my $field   = shift;
    my %args    = @_;

    my $ascending = delete $args{ascending} // !delete $args{descending} // 1;
    my $case = delete $args{case} // !delete $args{no_case} // 1;
    my $collate = (delete $args{collate} // !delete $args{no_collate} // 1)
        && try_load_optional('Unicode::Collate');

    if ($collate && !$case) {
        $case = 1;
        # use a proper Unicode::Collate level to ignore case
        $args{level} //= 2;
    }
    $args{upper_before_lower} //= 1;

    my $value = $field;
    $value = $case ? sub { $_[0]->$field // '' } : sub { uc($_[0]->$field) // '' } if !is_coderef($value);
    my @all = CORE::map { [$_, $value->($_)] } @{$self->to_array};

    if ($collate) {
        my $c = Unicode::Collate->new(%args);
        if ($ascending) {
            @all = CORE::map { $_->[0] } CORE::sort { $c->cmp($a->[1], $b->[1]) } @all;
        } else {
            @all = CORE::map { $_->[0] } CORE::sort { $c->cmp($b->[1], $a->[1]) } @all;
        }
    } else {
        if ($ascending) {
            @all = CORE::map { $_->[0] } CORE::sort { $a->[1] cmp $b->[1] } @all;
        } else {
            @all = CORE::map { $_->[0] } CORE::sort { $b->[1] cmp $a->[1] } @all;
        }
    }

    $self->(\@all);
    return $self;
}


sub sort_by { shift->order_by(@_)  }


sub norder_by {
    my $self    = shift;
    my $field   = shift;
    my %args    = @_;

    my $ascending = $args{ascending} // !$args{descending} // 1;

    my $value = $field;
    $value = sub { $_[0]->$field // 0 } if !is_coderef($value);
    my @all = CORE::map { [$_, $value->($_)] } @{$self->to_array};

    if ($ascending) {
        @all = CORE::map { $_->[0] } CORE::sort { $a->[1] <=> $b->[1] } @all;
    } else {
        @all = CORE::map { $_->[0] } CORE::sort { $b->[1] <=> $a->[1] } @all;
    }

    $self->(\@all);
    return $self;
}


sub nsort_by { shift->norder_by(@_) }


sub limit { shift->head(@_) }


sub to_array {
    my $self = shift;

    my @all;
    push @all, $_ while defined (local $_ = $self->());
    return \@all;
}


sub count {
    my $self = shift;

    my $items = $self->to_array;
    $self->($items);
    return scalar @$items;
}


sub size { shift->count }

##############################################################################

sub TO_JSON { $_[0]->to_array }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Iterator - KDBX database iterator

=head1 VERSION

version 0.901

=head1 SYNOPSIS

    my $kdbx = File::KDBX->load('database.kdbx', 'masterpw');

    $kdbx->entries
        ->where(sub { $_->title =~ /bank/i })
        ->order_by('title')
        ->limit(5)
        ->each(sub {
            say $_->title;
        });

=head1 DESCRIPTION

A buffered iterator compatible with and expanding upon L<Iterator::Simple>, this provides an easy way to
navigate a L<File::KDBX> database. The documentation for B<Iterator::Simple> documents functions and methods
supported but this iterator that are not documented here, so consider that additional reading.

=head2 Buffer

This iterator is buffered, meaning it can drain from an iterator subroutine under the hood, storing items
temporarily to be accessed later. This allows features like L</peek> and L</order_by> which might be useful in
the context of KDBX databases which are normally pretty small so draining an iterator completely isn't
cost-prohibitive in terms of memory usage.

The way this works is that if you call an iterator without arguments, it acts like a normal iterator. If you
call it with arguments, however, the arguments are added to the buffer. When called without arguments, the
buffer is drained before the iterator function is. Using L</unget> is equivalent to calling the iterator with
arguments, and L</next> is equivalent to calling the iterator without arguments.

=head1 METHODS

=head2 new

    \&iterator = File::KDBX::Iterator->new(\&iterator);

Bless an iterator to augment it with buffering plus some useful utility methods.

=head2 next

    $item = $iterator->next;
    # OR equivalently
    $item = $iterator->();

    $item = $iterator->next(\&query);

Get the next item or C<undef> if there are no more items. If a query is passed, get the next matching item,
discarding any unmatching items before the matching item. Example:

    my $item = $iterator->next(sub { $_->label =~ /Gym/ });

=head2 peek

    $item = $iterator->peek;

Peek at the next item. Returns C<undef> if the iterator is empty. This allows you to access the next item
without draining it from the iterator. The same item will be returned the next time L</next> is called.

=head2 unget

    # Replace buffer:
    $iterator->unget(\@items);
    # OR equivalently
    $iterator->(\@items);

    # Unshift onto buffer:
    $iterator->unget(@items);
    # OR equivalently
    $iterator->(@items);

Replace the buffer (first form) or unshift one or more items to the current buffer (second form).

See L</Buffer>.

=head2 each

    @items = $iterator->each;

    $iterator->each(sub($item, $num, @args) { ... }, @args);

    $iterator->each($method_name, ...);

Get or act on the rest of the items. This method has three forms:

=over 4

=item 1

Without arguments, C<each> returns a list of the rest of the items.

=item 2

Pass a coderef to be called once per item, in order. Arguments to the coderef are the item itself (also available as C<$_>), its index number and then any extra arguments that were passed to C<each> after the coderef.

=item 3

Pass a string that is the name of a method to be called on each object, in order. Any extra arguments passed to C<each> after the method name are passed through to each method call. This form requires each item be an object that C<can> the given method.

=back

B<NOTE:> This method drains the iterator completely, leaving it empty. See L</CAVEATS>.

=head2 grep

=head2 where

    \&iterator = $iterator->grep(\&query);

Get a new iterator draining from an existing iterator but providing only items that pass a test or are matched
by a query. In its basic form this method is very much like perl's built-in grep function, except for
iterators.

There are many examples of the various forms of this method at L<File::KDBX/QUERY>.

=head2 map

    \&iterator = $iterator->map(\&code);

Get a new iterator draining from an existing iterator but providing modified items. In its basic form this
method is very much like perl's built-in map function, except for iterators.

=head2 order_by

    \&iterator = $iterator->sort_by($field, %options);
    \&iterator = $iterator->sort_by(\&get_value, %options);

Get a new iterator draining from an existing iterator but providing items sorted by an object field. Sorting
is done using L<Unicode::Collate> (if available) or C<cmp> to sort alphanumerically. The C<\&get_value>
subroutine is called once for each item and should return a string value. Options:

=over 4

=item *

C<ascending> - Order ascending if true, descending otherwise (default: true)

=item *

C<case> - If true, take case into account, otherwise ignore case (default: true)

=item *

C<collate> - If true, use B<Unicode::Collate> (if available), otherwise use perl built-ins (default: true)

=item *

Any B<Unicode::Collate> option is also supported.

=back

B<NOTE:> This method drains the iterator completely and places the sorted items onto the buffer. See
L</CAVEATS>.

=head2 sort_by

Alias for L</order_by>.

=head2 norder_by

    \&iterator = $iterator->nsort_by($field, %options);
    \&iterator = $iterator->nsort_by(\&get_value, %options);

Get a new iterator draining from an existing iterator but providing items sorted by an object field. Sorting
is done numerically using C<< <=> >>. The C<\&get_value> subroutine or C<$field> accessor is called once for
each item and should return a numerical value. Options:

=over 4

=item *

C<ascending> - Order ascending if true, descending otherwise (default: true)

=back

B<NOTE:> This method drains the iterator completely and places the sorted items onto the buffer. See
L</CAVEATS>.

=head2 nsort_by

Alias for L</norder_by>.

=head2 limit

    \&iterator = $iterator->limit($count);

Get a new iterator draining from an existing iterator but providing only a limited number of items.

C<limit> as an alias for L<< Iterator::Simple/"$iterator->head($count)" >>.

=head2 to_array

    \@array = $iterator->to_array;

Get the rest of the items from an iterator as an arrayref.

B<NOTE:> This method drains the iterator completely, leaving it empty. See L</CAVEATS>.

=head2 count

    $size = $iterator->count;

Count the rest of the items from an iterator.

B<NOTE:> This method drains the iterator completely but restores it to its pre-drained state. See L</CAVEATS>.

=head2 size

Alias for L</count>.

=for Pod::Coverage TO_JSON

=head1 CAVEATS

Some methods attempt to drain the iterator completely before returning. For obvious reasons, this won't work
for infinite iterators because your computer doesn't have infinite memory. This isn't a practical issue with
B<File::KDBX> lists which are always finite -- unless you do something weird like force a child group to be
its own ancestor -- but I'm noting it here as a potential issue if you use this iterator class for other
things (which you probably shouldn't do).

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KDBX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
