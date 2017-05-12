package Loop::Sustainable::Strategy::ByLoad;

use strict;
use warnings;
use parent qw(Loop::Sustainable::Strategy);

use Class::Accessor::Lite (
    new => 0,
    rw  => [qw/load/],
);
use List::Util qw(max);

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    $self->{load} = 0.5 unless (defined $self->{load});
    $self;
}

sub wait_correction {
    my ( $self, $i, $elapsed, $rv ) = @_;
    return ( max( $elapsed, 0 ) * ( 1 - $self->{load} ) / $self->{load} ) / $self->check_strategy_interval;
}

1;

__END__

=head1 NAME

Loop::Sustainable::Strategy::ByLoad - Calculates wait interval by load.

=head1 SYNOPSIS

  use Loop::Sustainable;

  loop_sustainable {
      my ( $i, $time_sum ) = @_;
      #### maybe heavy process
  } (
      sub {
           my ($i, $time_sum, $rv ) = @_;
           not defined $rv->[0] ? 1 : 0;
      },
      {
          strategy => {
              class => 'ByLoad',
              args  => { load => 0.5 },
          }
      }
  );


=head1 DESCRIPTION

Loop::Sustainable::Strategy::ByLoad provides wait interval time calculated by total execution time and 
loop execution count, specified load ratio.

=head1 METHODS

=head2 new( %args )

=over

=item load

The ratio of executed time.

=back

=head2 wait_correction( $query, $time_sum, $executed_count )

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@dena.jp<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item L<Loop::Sustainable>

=back

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
