package Math::Random::AcceptReject;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

use Carp qw/croak/;
use Math::Symbolic qw/parse_from_string/;

=head1 NAME

Math::Random::AcceptReject - Acceptance-Rejection PDF transformations

=head1 SYNOPSIS

  use Math::Random::AcceptReject;
  my $pdf = Math::Random::AcceptReject->new(
    xmin   => 0, # defaults to 0
    xmax   => 2, # defaults to 1
    ymax   => 2, # no default!
    pdf    => 'x',    # a triangle from x=0 to x=2 with slope 1
    random => 'rand', # use Perl's builtin (default)
  );
  
  foreach (1..100) {
      my $rnd = $pdf->rand();
      # ...
  }
  
  # Use Math::Random::MT instead of bultin rand()
  # Same target PDF but as Perl code instead of a Math::Symbolic
  # function!
  use Math::Random::MT;
  my $mt = Math::Random::Mt->new($seed);
  $pdf = Math::Random::AcceptReject->new(
    xmax   => 2,
    ymax   => 2,
    pdf    => sub { $_[0] },
    random => sub { $mt->rand() };
  );

=head1 DESCRIPTION

This module implements acceptance-rejection transformations of uniformly
distributed random numbers to mostly arbitrary probability density functions
(I<PDF>s).

Note that whereas J. von Neumann's algorithm can transform from arbitrary
source PDFs to arbitrary destination PDFs, this module is currently limited to
uniform C<[0,1]> source PDFs!

=head1 METHODS

=cut

=head2 new

Creates a new random number generator. Takes named arguments.

Mandatory parameters:

  pdf:  The probability density function. This can either be a
        subroutine reference which takes an argument ('x') and
        returns f(x), a Math::Symbolic tree representing f(x) and
        using the variable 'x', or a string which can be parsed
        as such a Math::Symbolic tree.
  ymax: Maximum value of the target PDF f(x) in the x range. This
        max theoretically be safely set to a very large value which
        is much higher than the real maximum of f(x) within
        the range [xmin,xmax]. The efficiency of the algorithm goes
        down with 

Optional parameters:

  random: The random number generator. Defaults to using Perl's
          rand() function. May be set to either 'rand' for the
          default or a subroutine reference for custom random
          number generators. Expected to return one or more(!)
          random numbers per call.
  xmin:   Minimum value for x. Defaults to 0.
  xmax:   Maximum value for x. Defaults to 1.

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
    if (not defined $args{ymax}) {
        croak("Need 'ymax' parameter.");
    }
    if (not ref $args{random} eq 'CODE') {
        $args{random} = 'rand';
    }
    if (not defined $args{pdf}) {
        croak("Need 'pdf' parameter.");
    }
    if (not ref($args{pdf})) {
        eval {
            $args{pdf} = parse_from_string($args{pdf});
        };
        if ($@ or not defined $args{pdf}) {
            croak(
                "Error parsing string into Math::Symbolic tree."
                . ($@ ? " Error: $@" : "")
            );
        }
    }
    if (ref($args{pdf}) =~ /^Math::Symbolic/) {
        my ($sub, $leftover) = $args{pdf}->to_sub(x => 0);
        die("Compiling Math::Symbolic tree to sub failed!")
          if not ref($sub) eq 'CODE';
        $args{pdf} = $sub;
    }
    if (not ref($args{pdf}) eq 'CODE') {
        croak("'pdf' parameter needs to be a CODE ref, string, or Math::Symbolic tree.");
    }

    my $self = {
        xmin => _dor($args{xmin}, 0),
        xmax => _dor($args{xmax}, 1),
        ymax => $args{ymax},
        random => $args{random},
        pdf => $args{pdf},
        cache => [],
    };

    if ($self->{xmin} >= $self->{xmax}) {
        croak("'xmin' must be smaller than 'xmax'");
    }

    $self->{xdiff} = $self->{xmax} - $self->{xmin};

    bless $self => $class;

    return $self;
}

=head2 rand

Returns the next random number of PDF C<f(x)> as specified by the C<pdf>
parameter to C<new()>.

=cut

sub rand {
    my $self = shift;
    my $rnd = $self->{random};
    my $pdf = $self->{pdf};
    my $cache = $self->{cache};

    my $accept = 0;
    my $u = 0;
    my $f = -1;
    my $x;
    if (ref($rnd) eq 'CODE') {
        while ($u > $f) {
            push @$cache, $rnd->() if not @$cache;
            $x = $self->{xmin} + shift(@$cache) * $self->{xdiff};
            
            $f = $pdf->($x);
        
            push @$cache, $rnd->() if not @$cache;
            $u = shift(@$cache) * $self->{ymax};
        }
    }
    else { # rand
        while ($u > $f) {
            $x = $self->{xmin} + rand() * $self->{xdiff};
            $f = $pdf->($x);
            $u = rand() * $self->{ymax};
        }
    }

    return $x;
}

1;
__END__

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Rejection_sampling>

L<Math::Random::MT>, L<Math::Random>, L<Math::Random::OO>,
L<Math::TrulyRandom>

L<Math::Symbolic>

The examples in the F<examples/> subdirectory of this distribution.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
