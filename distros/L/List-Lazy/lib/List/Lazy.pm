package List::Lazy;
our $AUTHORITY = 'cpan:YANICK'; 
# ABSTRACT: Generate lists lazily
$List::Lazy::VERSION = '0.3.2';



use Moo;
use MooX::HandlesVia;

use Clone qw/ clone /;

use 5.22.0;

use experimental 'signatures', 'postderef';

use List::MoreUtils;
use Carp;

*list_before = *List::MoreUtils::before;

extends 'Exporter::Tiny';

sub _exporter_validate_opts {
    my $into = $_[1]->{into};
    eval qq{
        *${into}::a = *::a;
        *${into}::b = *::b;
        1;
    } or die $@;
}


our @EXPORT_OK = qw/ lazy_list lazy_range lazy_fixed_list /;

sub _lazy_list ($generator,$state=undef) {
    return List::Lazy->new(
        generator => $generator,
        state     => $state,
    );
}

sub lazy_list :prototype(&@) { goto &_lazy_list }

sub _lazy_range ($min,$max,$step=1) {
    my $it = ref $step ? $step : sub { $_ + $step };

    return scalar lazy_list { 
        return if defined $max and  $_ > $max;
        my $current = $_;
        $_ = $it->();
        return $current;
    } $min;
}


sub lazy_range :prototype($$@) { goto &_lazy_range }

sub lazy_fixed_list {
    my @list = @_;
    return List::Lazy->new(
        _next => [ @list ],
        is_done => 0,
        generator => sub { return () },
    );
}

has generator => (
    is => 'ro',
    required => 1, 
);

has state => (
    is => 'rw'
);

has _next => (
    is => 'rw',
    handles_via => 'Array',
    handles => {
        has_next   => 'count', 
        shift_next => 'shift',
        push_next => 'push',
        _all_next => 'elements',
    },
    default => sub { [] },
);

has is_done => (
    is => 'rw',
    default => sub { 0 },
);

sub generate_next($self) {
    local $_ = $self->state;

    my @values = $self->generator->();
    $self->state($_);

    $self->is_done(1) unless @values;

    return @values;
}

sub next($self,$num=1) {
    my @returns;

    croak "next called in scalar context with \$num = $num"
        if defined wantarray and not wantarray and $num != 1;

    while( @returns < $num and not $self->is_done ) {
        $self->push_next( $self->generate_next )
            unless $self->has_next;

        next unless $self->has_next;

        if( ref $self->_next->[0] eq 'List::Lazy' ) {
            my $list = $self->_next->[0];
            push @returns, $list->next;
            $self->shift_next if $list->is_done;
        }
        else {
            push @returns, $self->shift_next;
        }
    }

    return wantarray ? @returns : $returns[0];
}

sub all ($self) {
    return $self->next(1E99);
}

sub reduce($self,$reducer,$reduced=undef) {
    $reduced = $self->next if @_ < 3;

    while( my $next = $self->next ) {
        local ( $::a, $::b ) = ( $reduced, $next );
        $reduced = $reducer->();
    }

    return $reduced;
}

sub map($self,$map) {
    return List::Lazy->new(
        state => $self->_clone,
        generator => sub {
            while( my @next = $_->next ) {
                @next = map { $map->() } @next;
                return @next if @next;
            }
            return;
        },
    );
}

sub batch($self,$n) {
    return List::Lazy->new(
        state => [ $self->_clone, [] ],
        generator => sub {
            my $stash  = $_->[1];

            while( my @next = $_->[0]->next ) {
                push @$stash, @next;
                if( @$stash >= $n ) {
                    return [ splice @$stash, 0, $n ];
                }
            }

            return @$stash ? [ splice @$stash ] : ();
        },
    );
};

sub grep($self,$filter) {
    $self->map(sub{ $filter->() ? $_ : () })
}

sub spy($self,$sub=undef) {
    $sub ||= sub { carp $_ };
    $self->map(sub{ $sub->(); $_ } ); 
}

sub _clone($self,%args) {
    return List::Lazy->new(
        state     => clone( $self->state ),
        generator => $self->generator,
        _next => [ $self->_next->@* ],
        %args
    );
}

sub until($self,$condition) {
    my $done;
    return List::Lazy->new(
        state => $self->_clone,
        generator => sub {
            return () if $done;
            my @next = $_->next;
            my @filtered = list_before( sub { $condition->() }, @next );
            $done = @filtered < @next;
            return @filtered;
        },
    );
}

sub append($self,@list) {

    return List::Lazy->new(
        state => [ map { $_->_clone } $self, @list ],
        generator => sub {
            while(@$_) {
                shift @$_ while @$_ and $_->[0]->is_done;
                last unless @$_;
                my @next = $_->[0]->next;
                return @next if @next;
            }
            return ();
        },
    );

}

sub prepend( $self, @list ) {
    push @list, $self;
    $self = shift @list;
    $self->append(@list);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

List::Lazy - Generate lists lazily

=head1 VERSION

version 0.3.2

=head1 SYNOPSIS

    use List::Lazy qw/ lazy_range /;

    my $range = lazy_range( 1, undef )->grep(sub{ $_ % 2})->map( sub { '!' x $_ } );

    say $_ for $range->next(3); # prints ! !!! !!!!!

=head1 DESCRIPTION

C<List::Lazy> creates lists that lazily evaluate their next values on-demand.

=head1 EXPORTED FUNCTIONS

Lazy::List doesn't export any function by default, but will export the three following 
functions on request.

=head2 lazy_list

    my $list  = lazy_list $generator_sub, $state;

A convenience shortcut for the List::Lazy constructor. The C<$state> will be available
(and can be changed) by the generator subroutine. The generator subroutine is expected
to return a list of one or more next items of the list. Returning an empty list means
that the list has reached its end.

    my $even_numbers = lazy_list { $_ += 2 } 0; # will return 2, 4, 6, ...

In additional of regular values, the generator can also return lazy lists,
which will be seamlessly expanded.

    my $list = lazy_range( 1, undef )->map(sub { lazy_range( 1, $_ ) });
    # will return 1, 1, 2, 1, 2, 3, 1, 2, 3, 4, ...

=head2 lazy_range

    my $range = lazy_range $min, $max, $iterator;

Creates a list iterating over a range of values. C<$min> and C<$max> are required, but C<$max>  can be 
C<undef> (meaning no upper limit). The C<$iterator> is optional and defaults to the value C<1>. 
The C<$iterator> can be a number, which will be the step at which the numbers are increased, or a coderef that will 
be passed the previous value as C<$_>, and is expected to return the next value.

    my $palinumbers = lazy_range 99, undef, sub { do { $_++ } until $_ eq reverse $_; $_ };

    say join ' ', $palinumbers->next(3); # 99 101 111

=head2 lazy_fixed_list

    my $list = lazy_fixed_list @some_array;

Creates a lazy list that will returns the values of the given array. 

=head1 CLASS

=head2 new

    my $list = List::Lazy->new(
        state => 1,
        generator => sub {
            $_++;
        },
    );

Creates a lazy list.

=head3 arguments

=over 4

=item state

The state will be passed to the generator as C<$_>. If it is modified by the generator,
its new value will be saved for the next invocation.

=item generator

A coderef that generates one or more next items for the list. If it returns an empty list,
the stream will be considered to be exhausted.

=back

=head2 is_done

Returns C<true> is the list is exhausted.

=head2 next($num)

Returns the next C<$num> items of the list (or less if the list doesn't have
that many items left). C<$num> defaults to C<1>.

    my $range = lazy_range 1, 100;

    while( my $next = $range->next ) {
        ...
    }

=head2 reduce

    my $value = $list->reduce( $reducing_sub, $initial_value );

Iterates through the list and reduces its values via the C<$reducing_sub>, which
will be passed the cumulative value and the next item via C<$a> and C<$b>. 
If C<$initial_value> is not given, it defaults to the first element of the list.

    my $sum = lazy_range( 1, 100 )->reduce( sub { $a + $b } );

=head2 batch

    my $new_list = $list->batch($n);

Creates a new list where the items of the original list are batched in groups
of C<$n> (or less for the last batch).

    my $list = lazy_fixed_list( 1..100 )->batch(3);
    
    my $x = $list->next;           # $x == [ 1, 2, 3]

=head2 map

    my $new_list = $list->map( $mapper_sub );

Creates a new list by applying the transformation given by C<$mapper_sub> to the
original list. The sub ill be passed the original next item via C<$_>
and is expected to return its transformation, which 
can modify the item, explode it into many items, or suppress it,

Note that the new list do a deep clone of the original list's state, so reading
from the new list won't affect the original list.

    my $recount = ( lazy_range 1, 100 )->map( sub { 1..$_ } );
    # will return 1 1 2 1 2 3 1 2 3 4 ...

=head2 grep

    my $new_list = $list->grep( $filter_sub );

Creates a new list by applying the filtering given by C<$filter_sub> to the
original list. The sub will be passed the original next item via C<$_>
and is expected to return a boolean indicating if the item should be kept or not.

Note that the new list do a deep clone of the original list's state, so reading
from the new list won't affect the original list.

    my $odd = ( lazy_range 1, 100 )->grep( sub { $_ % 2 } );

=head2 spy

    my $new_list = $list->spy( $sub );

Creates a new list that will execute the spy C<$sub> for
every value it sees (with the value assigned to C<$_>). 

If C<$sub> is not given, it'll C<carp> the values.

=head2 until

    my $new_list = $list->until( $condition );

Creates a new list that truncates the original list as soon
as the condition is met.

    my $to_ten = $list->until(sub{ $_ > 10 });

=head2 append

    my $new_list = $list->append( @other_lists );

Creates a new list that will return first the elements of C<$list>,
and those of the C<@other_lists>. 

Note that the new list do a deep clone of the original lists's state, so reading
from the new list won't affect the original lists.

    my $range = lazy_range 1..100;
    my $twice = $range->append( $range );

=head2 prepend

    my $new_list = $list->prepend( @other_lists );

Like C<append>, but prepend the other lists to the current one.

Note that the new list do a deep clone of the original lists's state, so reading
from the new list won't affect the original lists.

=head2 all

    my @rest = $list->all;

Returns all the remaining values of the list. Be careful: if the list is unbounded, 
calling C<all()> on it will result into an infinite loop.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
