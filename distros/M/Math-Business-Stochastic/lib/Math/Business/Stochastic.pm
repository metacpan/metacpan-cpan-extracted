package Math::Business::Stochastic;

use strict;
use warnings;
use diagnostics;

our $VERSION = '0.03';

use Carp;
use List::Util qw(max min sum);

1;

sub new { 
    bless {
        val  => [],
        days => 0,
    };
}

sub set_days {
    my $this = shift;
    my ($k,$d,$sd) = @_;

    croak "k must be a positive non-zero integers"  if int($k) <= 0;
    croak "d must be a positive non-zero integers"  if int($d) <= 0;
    croak "sd must be a positive non-zero integers" if int($sd) <= 0;

    $this->{k} = int($k);
    $this->{d} = int($d);
    $this->{sd} = int($sd);
    $this->{days} = int($k) + int($d) + int($sd) - 2;
}

sub query_k  { my $this = shift; return $this->{cur_k}; }
sub query_d  { my $this = shift; return $this->{cur_d}; }
sub query_sd { my $this = shift; return $this->{cur_sd}; }

sub insert {
    my $this = shift;
    my ($high,$low,$close) = @_;

    croak "You must set the number of days before you try to insert" if not $this->{days};
    croak "You must specify the high,low,close values" unless defined $close;
    croak "High value must be higher than low value" unless $high >= $low;
    croak "Low value must be lower than close value" unless $low <= $close;
    croak "High value must be higher than close value" unless $high >= $close;

    push @{ $this->{val_high} }, $high;
    push @{ $this->{val_low} }, $low;
    push @{ $this->{val} }, $close;

    $this->recalc;
}

sub start_with {
    my $this        = shift;
       $this->{val_high} = shift;
       $this->{val_low}  = shift;
       $this->{val}      = shift;

    croak "bad arg to start_with" unless ref($this->{val_high}) eq "ARRAY";
    croak "bad arg to start_with" unless ref($this->{val_low}) eq "ARRAY";
    croak "bad arg to start_with" unless ref($this->{val}) eq "ARRAY";
    croak "bad arg to start_with" unless @{$this->{val_high}} == @{$this->{val}};
    croak "bad arg to start_with" unless @{$this->{val_low}} == @{$this->{val}};

    $this->recalc;
}

sub recalc {
    my $this = shift;

    shift @{ $this->{val_high} } while @{ $this->{val_high} } > $this->{days};
    shift @{ $this->{val_low} } while @{ $this->{val_low} } > $this->{days};
    shift @{ $this->{val} } while @{ $this->{val} } > $this->{days};

    if( $this->{k} <= @{ $this->{val} }  ) {
        push @{ $this->{val_max} }, max( picklast($this->{k},@{$this->{val_high}}) );
        push @{ $this->{val_min} }, min( picklast($this->{k},@{$this->{val_low}}) );
        push @{ $this->{val_close_minus_min} }, $this->{val}->[-1] - $this->{val_min}->[-1];
        push @{ $this->{val_max_minus_min} }, $this->{val_max}->[-1] - $this->{val_min}->[-1];
        shift @{ $this->{val_max} } while @{ $this->{val_max} } > $this->{k};
        shift @{ $this->{val_min} } while @{ $this->{val_min} } > $this->{k};
        shift @{ $this->{val_close_minus_min} } while @{ $this->{val_close_minus_min} } > $this->{k};
        shift @{ $this->{val_max_minus_min} } while @{ $this->{val_max_minus_min} } > $this->{k};
    }
    if( $this->{k}+$this->{d}-1 <= @{ $this->{val} } ) {
        push @{ $this->{val_d} }, sum(picklast($this->{d},@{$this->{val_close_minus_min}})) / sum(picklast($this->{d},@{$this->{val_max_minus_min}})) * 100;
        shift @{ $this->{val_d} } while @{ $this->{val_d} } > $this->{sd};
    }

    if( not defined $this->{val_max_minus_min}->[-1] or $this->{val_max_minus_min}->[-1] > 0 ) {
        if( @{ $this->{val} } == $this->{days} ) {
            $this->{cur_k}  = ($this->{val}->[-1] - $this->{val_min}->[-1]) / ($this->{val_max_minus_min}->[-1]) * 100;
            $this->{cur_d}  = $this->{val_d}->[-1];
            $this->{cur_sd} = sum(picklast($this->{sd},@{$this->{val_d}})) / $this->{sd};
        }
        elsif( @{ $this->{val} } >= $this->{days} - $this->{sd} + 1 ) {
            $this->{cur_k}  = ($this->{val}->[-1] - $this->{val_min}->[-1]) / ($this->{val_max_minus_min}->[-1]) * 100;
            $this->{cur_d}  = $this->{val_d}->[-1];
            $this->{cur_sd} = undef;
        }
        elsif( @{ $this->{val} } >= $this->{days} - $this->{sd} - $this->{d} + 2 ) {
            $this->{cur_k}  = ($this->{val}->[-1] - $this->{val_min}->[-1]) / ($this->{val_max_minus_min}->[-1]) * 100;
            $this->{cur_d}  = undef;
            $this->{cur_sd} = undef;
        }
        else {
            $this->{cur_k}  = undef;
            $this->{cur_d}  = undef;
            $this->{cur_sd} = undef;
        }
    }
    else {
        $this->{cur_k}  = undef;
        $this->{cur_d}  = undef;
        $this->{cur_sd} = undef;
    }
}

sub picklast {
    my $n = int(shift);
    return splice @_,-$n;
}

__END__

=head1 NAME

Math::Business::Stochastic - Perl extension for calculate stochastic oscillator

=head1 SYNOPSIS

  use Math::Business::Stochastic;

  my $stoc = new Math::Business::Stochastic;

  my ($k, $d, $sd) = (5, 3, 3);

  set_days $stoc $k, $d, $sd;

  my @high_values = qw(
      3 5 5 6 6 5 7 5 8 5 7
      8 6 8 6 8 7 8 8 9 8 9
  );
  my @low_values = qw(
      2 4 3 5 3 5 3 4 5 3 4
      4 5 6 6 6 6 6 7 7 6 7
  );
  my @close_values = qw(
      3 4 4 5 6 5 6 5 5 5 5
      6 6 6 6 7 7 7 8 8 8 8
  );

  for(my $i=0 ; $i<int(@close_values) ; $i++) {
      $stoc->insert( $high_values[$i], $low_values[$i], $close_values[$i] );

      if( defined $stoc->query_k ) {
          print "Stochastic k:  ", $stoc->query_k,  "\n";
      }
      else {
          print "Stochastic k:  n/a\n";
      }
      if( defined $stoc->query_d ) {
          print "Stochastic d:  ", $stoc->query_d,  "\n";
      }
      else {
          print "Stochastic d:  n/a\n";
      }
      if( defined $stoc->query_sd ) {
          print "Stochastic sd: ", $stoc->query_sd,  "\n";
      }
      else {
          print "Stochastic sd: n/a\n";
      }
  }

  # you may use this to kick start 
  $stoc->start_with( [@high_values], [@low_values], [@close_values] );

=head1 SEE ALSO

perl(1), Math::Business::MACD(3).

=head1 THANKS

Jettero Heller <jettero@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by NAGAYASU Yukinobu <nagayasu@yukinobu.jp>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
