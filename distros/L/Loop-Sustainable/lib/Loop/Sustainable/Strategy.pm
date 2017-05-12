package Loop::Sustainable::Strategy;

use strict;
use warnings;
use Class::Accessor::Lite (
    new => 0,
    rw  => [ qw/check_strategy_interval/ ]
);

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $args = ref $_[0] ? $_[0] : +{ @_ };
    bless $args => $class;
}

sub wait_correction { 1; }

1;

__END__

=head1 NAME

Loop::Sustainable::Strategy - Strategy base class

=head1 SYNOPSIS

  use Loop::Sustainable::Strategy;

=head1 DESCRIPTION

=head1 METHODS

=head2 new( %args )

=head2 wait_correction( $query, $time_sum, $executed_count )

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@dena.jp<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 SEE ALSO

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
