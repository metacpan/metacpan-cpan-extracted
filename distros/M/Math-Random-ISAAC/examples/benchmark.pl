#!/usr/bin/perl -T

# examples/benchmark.pl
#  Compare the ISAAC RNG implementations between each other, and between
#  other algorithms.
#
# $Id$

use strict;
use warnings;

eval {
  require Benchmark::ProgressBar;
  Benchmark::ProgressBar->import('cmpthese');
};
if ($@) {
  require Benchmark;
  Benchmark->import('cmpthese');
}

=head1 NAME

benchmark.pl - Test performance of various random number generators

=head1 VERSION

Version 1.0 ($Id$)

=cut

use version; our $VERSION = qv('1.0');

my $LOOPS    = 10_000; # Number of sequences to generate
my $NUMTESTS = 2_500; # Numbers to generate each test
my %TESTING; # modules we're testing

=head1 SYNOPSIS

Usage: benchmark.pl

This script will automatically detect available PRNG algorithms and compare
them using the Benchmark module. It will keep Pure Perl and C/XS modules
separate, so as to compare apples to apples.

=head1 DESCRIPTION

This script currently knows about the following modules, and will compare
them if they are installed.

This module will first compile all of the modules; loading time is also
benchmarked and compared, but separately from the rest of the operation.
For object oriented random number algorithms, the constructor is called
during the benchmark loop, so overhead due to initialization is fairly
counted too.

It will get 5 million integers from each, so as to provide a good sample
size. You can tune this, but you'll have to edit the file.

=head2 ALGORITHMS

=over

=item * Math::Random::ISAAC::PP (Perl)

=item * Math::Random::ISAAC::XS (XS/C)

=item * Math::Random::MT (XS/C)

=item * Math::Random::MT::Perl (Perl)

=item * Math::Random::TT800 (XS/C)

=item * Math::Random::random_uniform_integer (XS/C)

=item * Perl core rand() function

=back

=cut

print "Loading modules, please wait...\n";
load('Math::Random');
load('Math::Random::ISAAC::XS');
load('Math::Random::ISAAC::PP');
load('Math::Random::TT800');
load('Math::Random::MT');
load('Math::Random::MT::Perl');

print 'Setting up C/XS number generators... ';
my $seed = time;
my $code = {};

# Set up all of the modules we've just loaded
$code->{'Core'} = sub {
  my $var;
  srand($seed);
  for (1..$NUMTESTS) {
    $var = rand();
  }
};

if ($TESTING{'Math::Random'}) {
  $code->{'Math::Random'} = sub {
    my $var;
    Math::Random::random_set_seed($seed, $seed);
    for (1..$NUMTESTS) {
      $var = Math::Random::random_uniform();
    }
  };
}

if ($TESTING{'Math::Random::ISAAC::XS'}) {
  $code->{'ISAAC::XS'} = sub {
    my $rng = Math::Random::ISAAC::XS->new($seed);
    my $var;
    for (1..$NUMTESTS) {
      $var = $rng->irand();
    }
  };
}

if ($TESTING{'Math::Random::ISAAC::PP'}) {
  $code->{'ISAAC::PP'} = sub {
    my $rng = Math::Random::ISAAC::PP->new($seed);
    my $var;
    for (1..$NUMTESTS) {
      $var = $rng->irand();
    }
  };
}

if ($TESTING{'Math::Random::TT800'}) {
  $code->{'TT800'} = sub {
    my $rng = Math::Random::TT800->new($seed);
    my $var;
    for (1..$NUMTESTS) {
      $var = $rng->next_int();
    }
  };
}

if ($TESTING{'Math::Random::MT'}) {
  $code->{'MT'} = sub {
    my $rng = Math::Random::MT->new($seed);
    my $var;
    for (1..$NUMTESTS) {
      $var = $rng->rand();
    }
  };
}

if ($TESTING{'Math::Random::MT::Perl'}) {
  $code->{'MT::Perl'} = sub {
    my $rng = Math::Random::MT::Perl->new($seed);
    my $var;
    for (1..$NUMTESTS) {
      $var = $rng->rand();
    }
  };
}

print "done.\n";

print "Running comparisons (this might take a while)...\n\n";

cmpthese($LOOPS, $code);

sub load {
  my ($module) = @_;

  print '  ' . $module . '... ';
  eval 'use ' . $module;
  if ($@) {
    print 'not installed.';
    $TESTING{$module} = 0;
  }
  else {
    print 'done.';
    $TESTING{$module} = 1;
  }
  print "\n";
  return;
}

=head1 AUTHOR

Jonathan Yu E<lt>jawnsy@cpan.orgE<gt>

=head1 SUPPORT

For support details, please look at C<perldoc Math::Random::ISAAC> and
use the corresponding support methods.

=head1 LICENSE

This has the same copyright and licensing terms as L<Math::Random::ISAAC>.

=head1 SEE ALSO

L<Math::Random::ISAAC::PP>,
L<Math::Random::ISAAC::XS>,
L<Math::Random::MT>,
L<Math::Random::MT::Perl>,
L<Math::Random::TT800>,
L<Math::Random::random_uniform_integer>,

=cut
