package Iterator::Flex::Gather::Constants;

# ABSTRACT: Constants for Gather

use strict;
use warnings;

our $VERSION = '0.27';

use Exporter 'import';

use constant {
    GATHER_ELEMENT_MASK    => 0b000011,
    GATHER_ELEMENT_EXCLUDE => 0b000001,
    GATHER_ELEMENT_INCLUDE => 0b000010,
    GATHER_CYCLE_MASK      => 0b111100,
    GATHER_CYCLE_CONTINUE  => 0b000100,
    GATHER_CYCLE_RESTART   => 0b001000,
    GATHER_CYCLE_STOP      => 0b010000,
    GATHER_CYCLE_ABORT     => 0b100000,

    GATHER_GATHERING     => 1,
    GATHER_SRC_EXHAUSTED => 2,
};

our %EXPORT_TAGS = (
    all => [ qw(
          GATHER_ELEMENT_MASK
          GATHER_ELEMENT_EXCLUDE
          GATHER_ELEMENT_INCLUDE
          GATHER_CYCLE_MASK
          GATHER_CYCLE_CONTINUE
          GATHER_CYCLE_RESTART
          GATHER_CYCLE_STOP
          GATHER_CYCLE_ABORT
          GATHER_GATHERING
          GATHER_SRC_EXHAUSTED
        )
    ],
);

our @EXPORT_OK = ( map { @{$_} } values %EXPORT_TAGS );

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Iterator::Flex::Gather::Constants - Constants for Gather

=head1 VERSION

version 0.27

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
