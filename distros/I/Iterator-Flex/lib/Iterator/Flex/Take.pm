package Iterator::Flex::Take;

# ABSTRACT: Take Iterator Class

use strict;
use warnings;

our $VERSION = '0.30';

use Iterator::Flex::Utils ':IterAttrs', ':IterStates', ':SignalParameters', ':ExhaustionActions';
use Ref::Util;
use namespace::clean;
use experimental 'signatures';

use parent 'Iterator::Flex::Base';















































sub new ( $class, $iterable, $n, $pars = {} ) {

    my %pars = $pars->%*;

    defined $n && Scalar::Util::looks_like_number( $n ) && int( $n ) == $n && $n >= 0
      || $class->_throw( parameter => 'parameter "n" is not a positive integer' );

    my $lazy = delete $pars{lazy} // !!1;

    $class->SUPER::new( {
            n    => $n,
            lazy => $lazy,
            src  => $iterable,
        },
        \%pars
    );
}

sub construct ( $class, $state ) {

    $class->_throw( parameter => q{'state' parameter must be a HASH reference} )
      unless Ref::Util::is_hashref( $state );

    my ( $src, $prev, $current, $next, $array, $n, $lazy )
      = @{$state}{qw[ src prev current next array n lazy ]};

    $src
      = Iterator::Flex::Factory->to_iterator( $src, { ( +EXHAUSTION ) => THROW } );

    my $len;
    $len = $array->@* if defined $array;
    $current //= undef;
    $prev    //= undef;
    $next    //= 0;
    my $took = 0;

    my $self;
    my $iterator_state;

    my %params = (

        ( +_NAME ) => 'itake',

        ( +_SELF ) => \$self,

        ( +STATE ) => \$iterator_state,

        # this iterator only depends on $src if it hasn't drained it.
        # currently _DEPENDS must be a list of iterators, not a
        # coderef, so a dynamic dependency is no tpossible
        ( +_DEPENDS ) => $src,
        ( +FREEZE )   => sub {
            return [
                $class,
                {
                    src     => $src,
                    prev    => $prev,
                    current => $current,
                    next    => $next,
                    array   => $array,
                    n       => $n,
                    lazy    => $lazy,
                },
            ];
        },
    );

    if ( $lazy ) {

        $params{ +RESET } = sub {
            $prev = $current = undef;
            $next = 0;
            $took = 0;
        };

        $params{ +REWIND } = sub {
            $next = 0;
            $took = 0;
        };


        $params{ +PREV } = sub {
            return $prev;
        };

        $params{ +CURRENT } = sub {
            return $current;
        };

        $params{ +NEXT } = sub {
            my $ret;
            return $self->signal_exhaustion
              if $iterator_state == IterState_EXHAUSTED
              || $took == $n;

            eval {
                $ret = $src->();
                $took++;
                1;
            } or do {
                die $@
                  unless Ref::Util::is_blessed_ref( $@ )
                  && $@->isa( 'Iterator::Flex::Failure::Exhausted' );
                return $self->signal_exhaustion;
            };

            $prev    = $current;
            $current = $ret;
            return $current;
        };
    }

    else {

        $params{ +RESET } = sub {
            $array = $prev = $current = undef;
            $len   = undef;
            $next  = 0;
        };

        $params{ +REWIND } = sub {
            $prev  = $array->[$current] if defined $current;
            $array = $current = undef;
            $len   = undef;
            $next  = 0;
        };

        $params{ +PREV } = sub {
            return $prev;
        };

        $params{ +CURRENT } = sub {
            return defined $current ? $array->[$current] : undef;
        };

        $params{ +NEXT } = sub {

            return $self->signal_exhaustion
              if $iterator_state == IterState_EXHAUSTED;

            if ( !defined $array ) {
                eval {
                    $array = [];

                    # preload $array
                    push( $array->@*, $src->next );

                    # postfix until/while check conditional first,
                    # which would be a problem if $array->@* and
                    # n == 0, in which case it would never
                    # call $src->next
                    push( $array->@*, $src->next ) until $array->@* == $n;
                    1;
                } or do {
                    die $@
                      unless Ref::Util::is_blessed_ref( $@ )
                      && $@->isa( 'Iterator::Flex::Failure::Exhausted' );

                    if ( !$array->@* ) {
                        $current = undef;
                        return $self->signal_exhaustion;
                    }
                };

                $current = 0;
                $next    = 1;
                $len     = $array->@*;
                return $array->[$current];
            }

            if ( $next == $len ) {
                $prev = $array->[$current];
                return $self->signal_exhaustion;
            }

            $prev    = $array->[$current];
            $current = $next++;
            return $array->[$current];
        };

    }

    return \%params;

}


__PACKAGE__->_add_roles( qw[
      State::Closure
      Next::ClosedSelf
      Rewind::Closure
      Reset::Closure
      Prev::Closure
      Current::Closure
      Freeze
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

Iterator::Flex::Take - Take Iterator Class

=head1 VERSION

version 0.30

=head1 METHODS

=head2 new

  $iterator = Ierator::Flex::Take->new( $iterable, $n, ?\%pars );

Returns an iterator which returns at most C<$n> elements from
C<$iterable>.

C<$iterable> is converted into an iterator via
L<Iterator::Flex::Factory/to_iterator> if required.

The C<%pars> hash may contain standard L<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters> in
addition to the following:

=over

=item lazy => I<boolean>

If true, C<< $iterable->next >> is called for each call to
C<< $iterator->next >>.

If false, the first call to C<next> extracts C<$n> elements from
C<$iterable> and then returns them one by one.

=back

The returned iterator supports the following capabilities:

=over

=item current

=item next

=item prev

=item rewind

=item reset

=item freeze

=back

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
