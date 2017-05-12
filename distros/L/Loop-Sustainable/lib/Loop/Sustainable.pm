package Loop::Sustainable;

use strict;
use warnings;

use Carp;
use Exporter qw(import);
use Class::Load qw(load_class);
use Time::HiRes qw(tv_interval gettimeofday);

our $VERSION = '0.02';
our @EXPORT  = qw(loop_sustainable);

sub loop_sustainable (&&;$) {
    my ( $cb, $terminator, $args ) = @_;

    $args ||= +{};
    %$args = (
        wait_interval => 0.1,
        check_strategy_interval => 10,
        strategy => +{
            class => 'ByLoad',
            args  => +{ load => 0.5 },
        },
        %$args,
    );

    my $strategy_cb;

    if ( ref $args->{strategy} eq 'HASH' ) {
        my ( $strategy_class ) = index($args->{strategy}{class}, '+') == 1 ?
            substr($args->{strategy}{class}, 1) : 'Loop::Sustainable::Strategy::' . $args->{strategy}{class};

        load_class( $strategy_class );

        my $strategy = $strategy_class->new( 
            check_strategy_interval => $args->{check_strategy_interval}, 
            %{$args->{strategy}{args}} 
        );

        $strategy_cb = sub {
            my ( $execute_count, $time_sum, $rv ) = @_;
            $strategy->wait_correction( $execute_count, $time_sum, $rv );
        };
    }
    elsif ( ref $args->{strategy} eq 'CODE' ) {
        $strategy_cb = $args->{strategy};
    }
    else {
        croak 'Not supported strategy type. The strategy field must be hash reference or code reference.';
    }

    my $i               = 1;
    my $time_sum        = 0;
    my $time_total      = 0;
    my $wait_interval   = $args->{wait_interval};
    my $additional_wait = 0;

    for (;;) {
        my $t0      = [ Time::HiRes::gettimeofday ];
        my @ret = $cb->( $i, $wait_interval );
        my $elapsed = Time::HiRes::tv_interval( $t0, [ Time::HiRes::gettimeofday ] );

        $time_sum   += $elapsed;
        $time_total += $elapsed;

        if ( $terminator->( $i, $time_sum, \@ret ) ) {
            last;
        }

        Time::HiRes::sleep($wait_interval);

        if ( $i % $args->{check_strategy_interval} == 0 ) {
            $additional_wait = $strategy_cb->( $i, $time_sum, \@ret );
            $wait_interval   = $args->{wait_interval} + $additional_wait;
            $time_sum        = 0;
        }

        $i++;
    }

    my %result = ( 
        executed => $i, 
        total_time => $time_total 
    );

    return wantarray ? %result : \%result;
}

1;
__END__

=head1 NAME

Loop::Sustainable - Provides sustainable loop.

=head1 SYNOPSIS

  use DBI;
  use Loop::Sustainable;

  my $dbh = DBI->connect( ... );
  my $result = loop_sustainable(
      sub {
          my ( $execute_count, $time_sum ) = @_;
          my $rv = $dbh->do( 'DELETE FROM large_table ORDER BY id ASC LIMIT 100' );
          $dbh->commit or die( $dbh->errstr );
          return $rv;
      },
      sub {
          my ( $execute_count, $time_sum, $rv ) = @_;
          $rv->[0] < 100 ? 1 : 0;
      },
      +{
          wait_interval => 0.1,
          check_strategy_interval => 10,
          strategy => +{
            class => 'ByLoad',
            args  => +{ load => 0.5 },
          },
      }
  );

  printf("executed: %d; total time: %.02f sec\n", $result->{executed}, $result->{total_time});

=head1 DESCRIPTION

Loop::Sustainable provides sustainable loop with callback. 
The way of providing sustainable loop consists of inserting effectual wait time caliculated by strategy module into each loop execution.

Loop::Sustainable only exports loop_sustainable() function.

=head1 METHODS

=head2 loop_sustainable( \&cb, \&terminator, \%args )

This function runs callback function several times until terminator is returned true value.
And this function sleeps in order to specified strategy. So the loop supplied callback can run sustainably and continually.

=over

=item \&cb( $execute_count, $time_sum )

$execute_count is loop count. $time_sum is total times until calling strategy's wait_correction() method.

=item \&terminator( $execute_count, $time_sum, $rv )

$execute_count and $time_sum are same means in \&cb.
$rv is array reference as \&cb return values.

=item \%args

Available key-value pairs are following.

=over

=item strategy

This value must be CODE reference or HASH reference with strategy module name and passing arguments to it.
If you want to use built-in strategy module, 
you would specify suffix of complete module name excluded 'Loop::Sustainable::Strategy::'.
Or if you want to use non built-in strategy module, 
you must specify full module name with prefix '+' char likes '+My::Strategy::Excellent'.

The case of specify strategy module is following:

  #!/usr/bin/env perl
  
  use strict;
  use warnings;
  use FindBin;
  use lib "$FindBin::Bin/../lib";
  
  use Iterator::Simple qw(iter);
  use Loop::Sustainable;
  use POSIX qw(strftime);
  use Time::HiRes ();
  
  my $iter = iter( [ 1 .. 10 ] );
  
  loop_sustainable {
      my ( $i, $wait_interval ) = @_;
      Time::HiRes::sleep( rand(1) );
      warn sprintf(
          "[%s] times: %d. wait_interval: %02.2f",
          strftime( "%Y-%m-%d %H:%M:%S", localtime ),
          $i, $wait_interval
      );
      $iter->next;
  } (
      sub {
          my ( $i, $time_sum, $rv ) = @_;
          return not defined $rv->[0] ? 1 : 0;
      },
      {
          check_strategy_interval => 2,
          wait_interval           => 0.5,
          strategy                => {
              class => 'ByLoad',
              args  => { load => 0.5 }
          }
      }
  );

The case of specify code refernce is following:

  #!/usr/bin/env perl
  
  use strict;
  use warnings;
  use FindBin;
  use lib "$FindBin::Bin/../lib";
  
  use Loop::Sustainable;
  use POSIX qw(strftime);
  
  loop_sustainable {
      my ( $i, $wait_interval ) = @_;
      warn sprintf(
          "[%s] times: %d. interval: %s sec",
          strftime( "%Y-%m-%d %H:%M:%S", localtime ),
          $i, $wait_interval
      );
  } (
      sub {
          my ( $i, $time_sum, $rv ) = @_;
          ( $i > 11 ) ? 1 : 0;
      },
      {
          wait_interval           => 0,
          check_strategy_interval => 2,
          strategy                => sub {
              my ( $i, $time_sum, $rv ) = @_;
              return $i;
            }
      }
  );

This sample helps your understanding.
Run this code, you would see like following output:

  [2011-12-11 23:53:02] times: 1. interval: 0 sec at -e line 1.
  [2011-12-11 23:53:02] times: 2. interval: 0 sec at -e line 1.
  [2011-12-11 23:53:02] times: 3. interval: 2 sec at -e line 1.
  [2011-12-11 23:53:04] times: 4. interval: 2 sec at -e line 1.
  [2011-12-11 23:53:06] times: 5. interval: 4 sec at -e line 1.
  [2011-12-11 23:53:10] times: 6. interval: 4 sec at -e line 1.
  [2011-12-11 23:53:14] times: 7. interval: 6 sec at -e line 1.
  [2011-12-11 23:53:20] times: 8. interval: 6 sec at -e line 1.
  [2011-12-11 23:53:26] times: 9. interval: 8 sec at -e line 1.
  [2011-12-11 23:53:34] times: 10. interval: 8 sec at -e line 1.
  [2011-12-11 23:53:42] times: 11. interval: 10 sec at -e line 1.
  [2011-12-11 23:53:52] times: 12. interval: 10 sec at -e line 1.
  
The interval value point to wait time on the loop. On times equals 3, interval value is increased.
Because after execution at 2 times, call strategy code and set it's result value as next wait interval.

=item wait_interval

The base waiting time after running each loop. So each loop must be forced to wait for this value. 

=item check_strategy_interval

The count of next check time by strategy.

=back

=back

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

=head1 SEE ALSO

Built-in strategy modules are following:

=over

=item L<Loop::Sustainable::Strategy::ByLoad>

Calculates wait interval by execution time and load ratio.

=item L<Loop::Sustainable::Strategy::MySQL::BalancedReplication>

Calculates wait interval by Seconds_Behind_Master of SHOW SLAVE STATUS command return value.

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
