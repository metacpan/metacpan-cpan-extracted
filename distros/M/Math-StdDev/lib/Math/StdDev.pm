package Math::StdDev;

use strict;
use warnings;

# perl -MPod::Markdown -e 'Pod::Markdown->new->filter(@ARGV)' lib/Math/StdDev.pm  > README.md

=head1 NAME

Math::StdDev - Pure-perl mean and variance computation supporting running/online calculation (Welford's algorithm)

=head1 SYNOPSIS


    #!/usr/bin/perl -w
      
    use Math::StdDev;

    my $d = new Math::StdDev();
    $d->Update(2);
    $d->Update(3);
    print $d->mean() . "\t" . $d->sampleVariance();	# or $d->variance()

or

    perl -MMath::StdDev -e '$d=new Math::StdDev; $d->Update(10**8+4, 10**8 + 7, 10**8 + 13, 10**8 + 16); print $d->mean() . "\n" . $d->sampleVariance() . "\n"'


=head1 DESCRIPTION

This module impliments Welford's online algorithm (see https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance )
Maybe one day in future the two-pass algo could be included, along with Kahan compensated summation... so much math, so little time...


=head2 EXPORT

None by default.


=head2 Notes

=head2 new

Usage is

    my $d = new Math::StdDev();
or
    my $d = new Math::StdDev(1,2,3,4);	# Add one or more samples, or a population, right from the start


=head2 Update

Usage is

    my $d->Update(123);
or
    my $d->Update(@list_of_scalars);

=head2 mean()

Usage is

    print $d->mean();

=head2 variance

Usage is

    print $d->variance();

=head2 sampleVariance

(same as variance, but uses n-1 divisor.)  Usage is:

    print $d->sampleVariance();

=cut

require Exporter;

our @ISA = qw(Exporter);
our($VERSION)='1.02';
our($UntarError) = '';

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );


sub new {
  my $class = shift;
  my $this={};
  $this->{count}=0;
  $this->{mean}=0;
  $this->{M2}=0;

  bless $this,$class;
  if(defined $_[0]) {
    $this->Update(@_);	# Include anything passed into the new()
    # Also compute the exact correct result using the 2-pass method, in case they're not going to provide more samples later
    my $s=0;$s+=$_ foreach(@_);
    my $m=$s/(1+$#_);
    my $v=0;$v+=($_-$m)**2 foreach(@_);
    $this->{exactMean}=$m;
    $this->{exactVariance}=($v/(1+$#_))**.5;
    $this->{exactSampleVariance}=($v/($#_))**.5 if($#_>0);
  }

  return $this;
} # new


#	# for a new value newValue, compute the new count, new mean, the new M2.
#	# mean accumulates the mean of the entire dataset
#	# M2 aggregates the squared distance from the mean
#	# count aggregates the number of samples seen so far
#	def update(existingAggregate, newValue):
#	    (count, mean, M2) = existingAggregate
#	    count += 1 
#	    delta = newValue - mean
#	    mean += delta / count
#	    delta2 = newValue - mean
#	    M2 += delta * delta2
#	
#	    return (count, mean, M2)
#	
#	# retrieve the mean, variance and sample variance from an aggregate
#	def finalize(existingAggregate):
#	    (count, mean, M2) = existingAggregate
#	    (mean, variance, sampleVariance) = (mean, M2/count, M2/(count - 1)) 
#	    if count < 2:
#	        return float('nan')
#	    else:
#	        return (mean, variance, sampleVariance)



sub Update {
  my $this = shift;
  while(defined($_[0])) {
    my $newValue=shift;
    $this->{count}++;
    my $delta = $newValue - $this->{mean};
    $this->{mean} += $delta / $this->{count};
    my $delta2 = $newValue - $this->{mean};
    $this->{M2} += $delta * $delta2;
  }
  undef($this->{exactMean}); # switch over to online method instead of two-pass method
} # Update

sub mean {
  my $this = shift;
  if($this->{count}<1) { return undef; }
  return $this->{exactMean} if(defined $this->{exactMean});
  return $this->{mean};
}

sub variance {
  my $this = shift;
  if($this->{count}<1) { return undef; }
  return $this->{exactVariance} if(defined $this->{exactMean});
  return ($this->{M2}/$this->{count})**0.5;
}

sub sampleVariance {
  my $this = shift;
  if($this->{count}<2) { return undef; }
  return $this->{exactSampleVariance} if(defined $this->{exactMean});
  return ($this->{M2}/($this->{count}-1))**0.5;
}


1;

__END__

=head1 AUTHOR

This module was written by Chris Drake F<cdrake@cpan.org>. 


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019 Chris Drake. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

