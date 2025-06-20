package Iterator::Flex::Sequence;

# ABSTRACT: Numeric Sequence Iterator Class

use strict;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.19';

use Scalar::Util;
use List::Util;

use parent 'Iterator::Flex::Base';
use Iterator::Flex::Utils qw( STATE :IterAttrs );

use namespace::clean;


































sub new ( $class, @args ) {

    my $pars = Ref::Util::is_hashref( $args[-1] ) ? pop @args : {};

    $class->_throw( parameter => "incorrect number of arguments for sequence" )
      if @args < 1 || @args > 3;

    my %state;
    $state{step}  = pop @args if @args == 3;
    $state{end}   = pop @args;
    $state{begin} = pop @args;


    $class->SUPER::new( \%state, $pars );
}

sub construct ( $class, $state ) {

    $class->_throw( parameter => "$class: arguments must be numbers\n" )
      unless List::Util::all { Scalar::Util::looks_like_number( $_ ) };

    my ( $begin, $end, $step, $iter, $next, $current, $prev )
      = @{$state}{qw[ begin end step iter next current prev ]};

    my $self;
    my $iterator_state;

    my %params;

    if ( !defined $step ) {

        $begin = 0      unless defined $begin;
        $next  = $begin unless defined $next;

        %params = (
            ( +NEXT ) => sub {
                if ( $next > $end ) {
                    $prev = $current
                      unless $self->is_exhausted;
                    return $current = $self->signal_exhaustion;
                }
                $prev    = $current;
                $current = $next++;
                return $current;
            },
            ( +FREEZE ) => sub {
                [
                    $class,
                    {
                        begin   => $begin,
                        end     => $end,
                        prev    => $prev,
                        current => $current,
                        next    => $next,
                    },
                ]
            },
        );
    }

    else {

        $class->_throw(
            parameter => "sequence will be inifinite as \$step is zero or has the incorrect sign" )
          if ( $begin < $end && $step <= 0 ) || ( $begin > $end && $step >= 0 );

        $next = $begin unless defined $next;
        $iter = 0      unless defined $iter;

        %params = (
            ( +FREEZE ) => sub {
                [
                    $class,
                    {
                        begin   => $begin,
                        end     => $end,
                        step    => $step,
                        iter    => $iter,
                        prev    => $prev,
                        current => $current,
                        next    => $next,
                    } ]
            },

            ( +NEXT ) => $begin < $end
            ? sub {
                if ( $next > $end ) {
                    $prev = $current
                      unless $self->is_exhausted;
                    return $current = $self->signal_exhaustion;
                }
                $prev    = $current;
                $current = $next;
                $next    = $begin + ++$iter * $step;
                return $current;
            }
            : sub {
                if ( $next < $end ) {
                    $prev = $current
                      unless $self->is_exhausted;
                    return $current = $self->signal_exhaustion;
                }
                $prev    = $current;
                $current = $next;
                $next    = $begin + ++$iter * $step;
                return $current;
            },
        );
    }

    return {
        %params,
        ( +CURRENT ) => sub { $current },
        ( +PREV )    => sub { $prev },
        ( +REWIND )  => sub {
            $next = $begin;
            $iter = 0;
        },
        ( +RESET ) => sub {
            $prev = $current = undef;
            $next = $begin;
            $iter = 0;
        },

        ( +_SELF ) => \$self,

        ( +STATE ) => \$iterator_state,
    };

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

Iterator::Flex::Sequence - Numeric Sequence Iterator Class

=head1 VERSION

version 0.19

=head1 METHODS

=head2 new

  # sequence starting at 0, incrementing by 1, ending at $end
  $iterator = Iterator::Flex::Sequence->new( $end, ?\%pars );

  # sequence starting at $begin, incrementing by 1, ending at $end
  $iterator = Iterator::Flex::Sequence->new( $begin, $end, ?\%pars );

  # sequence starting at $begin, incrementing by $step, ending <= $end
  $iterator = Iterator::Flex::Sequence->new( $begin, $end, $step, ?\%pars );

The optional C<%pars> hash may contain standard L<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters>.

The iterator supports the following capabilities:

=over

=item current

=item next

=item prev

=item rewind

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
