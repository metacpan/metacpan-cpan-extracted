package Iterator::Flex::Zip;

# ABSTRACT: Zip Iterator Class

use strict;
use warnings;
use experimental 'signatures', 'declared_refs';

our $VERSION = '0.26';

use Iterator::Flex::Factory;
use Iterator::Flex::Utils qw[ THROW STATE EXHAUSTION :IterAttrs :IterStates ];
use Ref::Util 'is_ref', 'is_hashref', 'is_blessed_ref';
use List::Util 'first';

use parent 'Iterator::Flex::Base';

use constant { map { $_ => lc } qw( ON_EXHAUSTION TRUNCATE THROW INSERT ) };

use namespace::clean;








































































sub new ( $class, @args ) {
    my $pars = is_hashref( $args[-1] ) ? pop @args : {};

    $class->_throw( parameter => 'not enough parameters' )
      unless @args;

    my @iterators;
    my @keys;

    # distinguish between ( key => iterator, key =>iterator ) and ( iterator, iterator );
    if ( is_ref( $args[0] ) ) {
        @iterators = @args;
    }
    else {
        $class->_throw( parameter => 'expected an even number of arguments' )
          if @args % 2;

        while ( @args ) {
            push @keys,      shift @args;
            push @iterators, shift @args;
        }
    }

    ## no critic (AmbiguousNames)
    my ( @set, @insert );

    my %attr = (
        keys    => \@keys,
        depends => \@iterators,
        set     => \@set,
        insert  => \@insert,
        value   => [],
    );

    if ( defined( my $on_exhaustion = delete $pars->{ +ON_EXHAUSTION } ) ) {

        if ( is_hashref( $on_exhaustion ) ) {
            my @ekeys = keys $on_exhaustion->%*;

            my %idx;
            @idx{ 0 .. $#iterators } = 0 .. $#iterators;
            @idx{@keys} = 0 .. $#iterators
              if @keys;

            my @iset = @idx{@ekeys};

            $class->_throw( parameter => ON_EXHAUSTION . ' illegal iterator label or index' )
              if defined first { !defined } @iset;

            @set[@iset]    = ( !!1 ) x @iset;
            @insert[@iset] = $on_exhaustion->@{@ekeys};

            $attr{set}              = \@set;
            $attr{insert}           = \@insert;
            $attr{ +ON_EXHAUSTION } = INSERT;
        }
        elsif ( is_ref( $on_exhaustion ) or !first { $on_exhaustion eq $_ } TRUNCATE, THROW ) {
            $class->_throw( parameter => ON_EXHAUSTION . ": unexpected value: $on_exhaustion" );
        }
        else {
            $attr{ +ON_EXHAUSTION } = $on_exhaustion;
        }
    }
    else {
        $attr{ +ON_EXHAUSTION } = TRUNCATE;
    }

    $class->SUPER::new( \%attr, $pars );
}


## no critic (ExcessComplexity)
sub construct ( $class, $state ) {
    $class->_throw( parameter => q{state must be a HASH reference} )
      unless is_hashref( $state );

    $state->{value} //= [];

    ## no critic (AmbiguousNames)
    my ( \@depends, \@keys, \@value, \@insert, \@set, $on_exhaustion, $thaw )
      = @{$state}{qw[ depends keys value insert set on_exhaustion thaw ]};

    # transform into iterators if required.

    my @iterators
      = map { Iterator::Flex::Factory->to_iterator( $_, { ( +EXHAUSTION ) => THROW } ) } @depends;

    $class->_throw( parameter => q{number of keys not equal to number of iterators} )
      if @keys && @keys != @iterators;

    @value = map { $_->current } @iterators
      if $thaw;

    my $self;
    my $iterator_state;
    my %params = (

        ( +_NAME ) => 'izip',

        ( +_SELF ) => \$self,

        ( +STATE ) => \$iterator_state,


        ( +CURRENT ) => sub {
            return undef                    if !@value;
            return $self->signal_exhaustion if $iterator_state eq IterState_EXHAUSTED;
            if ( @keys ) {
                my %value;
                @value{@keys} = @value;
                return \%value;
            }
            else {
                return [@value];
            }
        },

        ( +RESET )    => sub { @value = () },
        ( +REWIND )   => sub { },
        ( +_DEPENDS ) => \@iterators,
    );

    if ( $on_exhaustion eq TRUNCATE ) {

        $params{ +NEXT } = sub {
            return $self->signal_exhaustion if $iterator_state == IterState_EXHAUSTED;

            my @nvalue;

            eval {
                @nvalue = map { $_->() } @iterators;
                1;
            } or do {
                die $@
                  unless is_blessed_ref( $@ )
                  && $@->isa( 'Iterator::Flex::Failure::Exhausted' );
                return $self->signal_exhaustion;
            };

            @value = @nvalue;

            if ( @keys ) {
                my %value;
                @value{@keys} = @value;
                return \%value;
            }
            else {
                return [@value];
            }
        };
    }

    elsif ( $on_exhaustion eq THROW ) {

        $params{ +NEXT } = sub {
            return $self->signal_exhaustion if $iterator_state == IterState_EXHAUSTED;

            my @nvalue;

            my $idx = -1;
            eval {
                ## no critic (ComplexMappings)
                @nvalue = map { $idx++; $_->() } @iterators;
                1;
            } or do {
                die $@
                  unless is_blessed_ref( $@ )
                  && $@->isa( 'Iterator::Flex::Failure::Exhausted' );

                # if all of the iterators have been exhausted,
                # then we're ok. Otherwise, find out which ones
                # are

                my @exhausted = ( $idx );
                while ( ++$idx < @iterators ) {
                    if ( !eval { $iterators[$idx]->(); 1 } ) {
                        die $@
                          unless is_blessed_ref( $@ )
                          && $@->isa( 'Iterator::Flex::Failure::Exhausted' );
                        push @exhausted, $idx;
                    }
                }
                return $self->signal_exhaustion
                  if @exhausted == @iterators;

                @exhausted = @keys[@exhausted]
                  if @keys;

                $class->_throw( Truncated => \@exhausted );
            };

            @value = @nvalue;

            if ( @keys ) {
                my %value;
                @value{@keys} = @value;
                return \%value;
            }
            else {
                return [@value];
            }
        };
    }

    elsif ( $on_exhaustion eq INSERT ) {

        my @exhausted  = ( !!0 ) x @iterators;
        my $nexhausted = 0;

        $params{ +NEXT } = sub {
            return $self->signal_exhaustion
              if $iterator_state == IterState_EXHAUSTED
              || $nexhausted == @iterators;

            my @nvalue;

            for my $idx ( 0 .. $#iterators ) {

                my $value;

                if ( $exhausted[$idx] ) {
                    $value = $insert[$idx];
                }
                else {
                    eval { $value = $iterators[$idx]->(); 1 } or do {
                        die $@
                          unless is_blessed_ref( $@ )
                          && $@->isa( 'Iterator::Flex::Failure::Exhausted' );

                        # if insert value not provided for this iterator,
                        # abort
                        return $self->signal_exhaustion if !$set[$idx];

                        $nexhausted++;
                        $exhausted[$idx] = !!1;
                        $value = $insert[$idx];
                    }
                }

                push @nvalue, $value;
            }

            @value = @nvalue;

            if ( @keys ) {
                my %value;
                @value{@keys} = @value;
                return \%value;
            }
            else {
                return [@value];
            }
        };
    }


    return \%params;
}

__PACKAGE__->_add_roles( qw[
      State::Closure
      Next::ClosedSelf
      Current::Closure
      Reset::Closure
      Rewind::Closure
] );

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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Iterator::Flex::Zip - Zip Iterator Class

=head1 VERSION

version 0.26

=head1 METHODS

=head2 new

  $iterator = Iterator::Flex::Zip->new( $iterable1, $iterable2, ..., ?\%pars );
  $iterator = Iterator::Flex::Zip->new( key1 => $iterable1,
                              key2 => iterable2, ..., ?\%pars );

Returns an iterator which returns, as a single element, the next
element from each of the passed iterables.  By default the iterator is
exhausted if any of the input iterables is exhausted; this behavior
may be changed via the L</on_exhaustion> parameter.

If the input is a list of iterables, the returned iterator will return
an array reference containing an element from each iterable.

If the input is a list of key, iterable pairs, it will return a hash
reference.

The iterables are converted into iterators via
L<Iterator::Flex::Factory/to_iterator> if required.

In addition to the standard L<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters>, the
optional C<%pars> hash may contain the following:

=over

=item on_exhaustion

This specifies what the iterator does when any of the input iterators
is exhausted early. It can take the following values:

=over

=item C<truncate>

The C<Zip> iterator will signal exhaustion when any of the input iterators
is exhausted.  This is the default behavior.

=item C<throw>

The C<Zip> iterator will throw an instance of the
B<iterator::Flex::Failure::Truncated> exception class.  The object's
C<msg> method will contain an array indicating which of the input
iterators were exhausted, either the zero-based positions of the
iterators in the order they were specified, or, if they were specified
with keys, their keys.

=item a hashref

The hashref provides values to be used for exhausted input iterators
until all of the iterators are exhausted.  The keys are either the
zero-based positions of the iterators in the order they were specified,
or, if they were specified with keys, their keys.

If an iterator without a replacement value is exhausted, the C<Zip>
iterator will signal exhaustion.

=back

=back

The iterator supports the following capabilities:

  next

And optionally (if the iterables support it)

 reset

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
