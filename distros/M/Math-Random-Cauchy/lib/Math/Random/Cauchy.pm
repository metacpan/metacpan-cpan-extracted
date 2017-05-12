package Math::Random::Cauchy;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

use Carp qw/croak/;

=head1 NAME

Math::Random::Cauchy - Random numbers following a Cauchy PDF

=head1 SYNOPSIS

  use Math::Random::Cauchy;
  my $cauchy = Math::Random::Cauchy->new(
    fwhm  => 1,  # the width (full width, half maximum), default==1
    middle => 5, # the expectation value, default==0
    random => 'rand', # use Perl's builtin (default)
  );
  
  foreach (1..100) {
      my $rnd = $cauchy->rand();
      # ...
  }
  
  # Use Math::Random::MT instead of bultin rand()
  use Math::Random::MT;
  my $mt = Math::Random::Mt->new($seed);
  $cauchy = Math::Random::Cauchy->new(
    random => sub { $mt->rand() };
  );

=head1 DESCRIPTION

This module transforms uniformly spaced random numbers into random
numbers that follow the Cauchy Probability Density Function (I<PDF>).

A more general transformation method is implemented in
L<Math::Random::AcceptReject>.

The algorithm is from Blobel et al as quoted in the I<SEE ALSO> section
below.

=head1 METHODS

=cut

=head2 new

Creates a new random number generator. Takes named arguments.

Optional parameters:

  random: The random number generator. Defaults to using Perl's
          rand() function. May be set to either 'rand' for the
          default or a subroutine reference for custom random
          number generators. Expected to return one or more(!)
          random numbers per call.
  fwhm:   Full width, half maximum. Defaults to 1.
  middle: Expectation value for x. Defaults to 0.

=cut

sub _dor {
    foreach (@_) {
        return $_ if defined $_;
    }
    return();
}

sub new {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my %args = @_;

    # Argument checking
    $args{fwhm} = _dor($args{fwhm}, 1);
    $args{middle} = _dor($args{middle}, 1);
    if ($args{fwhm} <= 0) {
        croak("'fwhm' must be positive!");
    }
    $args{random} = _dor($args{random}, 'rand');
    if (not ref($args{random}) eq 'CODE') {
        croak("'random' parameter must be a CODE reference or 'rand'")
          if not $args{random} eq 'rand';
    }

    my $self = {
        fwhm => $args{fwhm},
        middle => $args{middle},
        random => $args{random},
        cache => [],
    };

    bless $self => $class;

    return $self;
}

=head2 rand

Returns the next random number of Cauchy PDF.

=cut

sub rand {
    my $self = shift;
    my $rnd = $self->{random};
    my $cache = $self->{cache};

    my $x;
    while (not defined $x) {
        while (@$cache < 2) {
            if (not ref $rnd) {
                push @$cache, rand();
            }
            else {
                push @$cache, $rnd->();
            }
        }
        
        my ($u1, $u2) = (shift(@$cache), shift(@$cache));
        my ($v1, $v2) = (2*$u1-1, 2*$u2-1);
        my $r = $v1**2 + $v2**2;
        next if $r > 1;
        $x = 0.5*$v1/$v2;
    }
    $x = $self->{middle} + $x*$self->{fwhm};
    return $x;
}

1;
__END__

=head1 SEE ALSO

L<Math::Random::MT>, L<Math::Random>, L<Math::Random::OO>,
L<Math::TrulyRandom>, L<Math::Random::AcceptReject>

The examples in the F<examples/> subdirectory of this distribution.

The algorithm was taken from: (German)

Blobel, V., and Lohrmann, E. I<Statistische und numerische Methoden
der Datenanalyse>. Stuttgart, Leipzig: Teubner, 1998

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
