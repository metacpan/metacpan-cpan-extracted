package Iterator::Flex::Chunk;

# ABSTRACT: Chunk Iterator Class

use v5.28;
use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.33';

use Iterator::Flex::Factory 'to_iterator';
use Iterator::Flex::Utils qw[ THROW STATE EXHAUSTION :IterAttrs :IterStates ];
use Ref::Util;
use parent 'Iterator::Flex::Base';

use namespace::clean;




































sub new ( $class, $iterable, $pars = {} ) {

    my %pars     = $pars->%*;
    my $capacity = delete $pars{capacity} // 1;
    $class->SUPER::new( {
            capacity => $capacity,
            src      => $iterable,
        },
        \%pars,
    );
}

sub construct ( $class, $state ) {

    throw_failure( parameter => q{'state' parameter must be a HASH reference} )
      unless Ref::Util::is_hashref( $state );

    my ( $src, $capacity ) = @{$state}{qw[ src capacity ]};

    $src
      = to_iterator( $src, { ( +EXHAUSTION ) => THROW } );

    my $self;
    my $iterator_state;

    # This iterator may have to delay signalling exhaustion for one
    # cycle if the input iterator is exhausted and the current chunk
    # is not empty
    my $next_is_exhausted = !!0;

    return {
        ( +_NAME ) => 'ichunk',

        ( +_SELF ) => \$self,

        ( +STATE ) => \$iterator_state,

        ( +NEXT ) => sub {
            return $self->signal_exhaustion
              if $iterator_state == IterState_EXHAUSTED || $next_is_exhausted;

            my @chunked;
            eval {
                push @chunked, $src->() while @chunked < $capacity;
                1;
            } or do {
                die $@
                  unless Ref::Util::is_blessed_ref( $@ )
                  && $@->isa( 'Iterator::Flex::Failure::Exhausted' );

                return $self->signal_exhaustion if !@chunked;
                $next_is_exhausted = !!1;
            };
            return \@chunked;
        },
        ( +RESET ) => sub {
            $next_is_exhausted = !!0;
        },
        ( +_DEPENDS ) => $src,
    };
}

__PACKAGE__->_add_roles( qw[
      State::Closure
      Next::ClosedSelf
      Reset::Closure
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

Iterator::Flex::Chunk - Chunk Iterator Class

=head1 VERSION

version 0.33

=head1 METHODS

=head2 new

  $iterator = Ierator::Flex::Chunk->new( $iterable, ?\%pars );

Returns an iterator which, for each iteration, reads up to a specified
number of elements from C<$iterable>, and returns an arrayref containing
those elements.

C<$iterable> is converted into an iterator via
L<Iterator::Flex::Factory/to_iterator> if required.

The optional C<%pars> hash may contain standard L<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters> as well
as the following model parameters:

=over

=item capacity => I<integer>

The number of elements per chunk.  It defaults to C<1>.

=back

The iterator supports the following capabilities:

=over

=item next

=item reset

=back

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
