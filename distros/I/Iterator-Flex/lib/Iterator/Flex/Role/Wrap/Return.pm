package Iterator::Flex::Role::Wrap::Return;

# ABSTRACT: wrap imported iterator which returns a sentinel on exhaustion

use strict;
use warnings;

our $VERSION = '0.19';

use Iterator::Flex::Utils qw( :default INPUT_EXHAUSTION );
use Scalar::Util;
use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

around _construct_next => sub ( $orig, $class, $ipar, $gpar ) {

    my $next = $class->$orig( $ipar, $gpar );

    # this will be weakened latter.
    my $wsub;

    my $sentinel = (
        $gpar->{ +INPUT_EXHAUSTION } // do {
            require Iterator::Flex::Failure;
            Iterator::Flex::Failure::parameter->throw(
                "internal error: input exhaustion policy was not registered" );
        }
    )->[1];

    # undef
    if ( !defined $sentinel ) {
        $wsub = sub {
            my $self = $_[0] // $wsub;
            my $val  = $next->( $self );
            return !defined $val ? $self->signal_exhaustion : $val;
        };
    }

    # reference
    elsif ( ref $sentinel ) {
        my $sentinel = refaddr $sentinel;

        $wsub = sub {
            my $self = $_[0] // $wsub;
            my $val  = $next->( $self );
            my $addr = refaddr $val;
            return defined $addr
              && $addr == $sentinel ? $self->signal_exhaustion : $val;
        };
    }

    # number
    elsif ( Scalar::Util::looks_like_number( $sentinel ) ) {
        $wsub = sub {
            my $self = $_[0] // $wsub;
            my $val  = $next->( $self );
            return defined $val
              && $val == $sentinel ? $self->signal_exhaustion : $val;
        };
    }

    # string
    else {
        $wsub = sub {
            my $self = $_[0] // $wsub;
            my $val  = $next->( $_[0] );
            return defined $val
              && $val eq $sentinel ? $self->signal_exhaustion : $val;
        };
    }

    # create a second reference to $wsub, before we weaken it,
    # otherwise it will lose its contents, as it would be the only
    # reference.

    my $sub = $wsub;
    Scalar::Util::weaken( $wsub );
    return $sub;
};

requires 'signal_exhaustion';

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

Iterator::Flex::Role::Wrap::Return - wrap imported iterator which returns a sentinel on exhaustion

=head1 VERSION

version 0.19

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
