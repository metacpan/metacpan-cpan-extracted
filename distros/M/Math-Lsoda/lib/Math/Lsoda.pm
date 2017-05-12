package Math::Lsoda;
use 5.008_001;
use POSIX;
use Any::Moose;

our $VERSION = '0.04';
our @ISA;

has equation => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

has initial => (
    is       => 'rw',
    isa      => 'ArrayRef',
    required => 1,
);

has start => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

has end => (
    is      => 'rw',
    isa     => 'Num',
    default => 1,
);

has dt => (
    is      => 'rw',
    isa     => 'Num',
    default => 0.1,
);

has relative_tolerance => (
    is         => 'rw',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

has absolute_tolerance => (
    is         => 'rw',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

has filename => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

eval {
    require XSLoader;
    XSLoader::load(__PACKAGE__, $VERSION);
    1;
} or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    __PACKAGE__->bootstrap($VERSION);
};

sub run {
    my $self = shift;
    my $fh;
    if($self->filename eq ''){
      $fh = *STDOUT;
    } else {
      my $file = $self->filename;
      open $fh, ">" . $file or die "$file: $!";
    }
    my $status = solve($self->equation, $self->initial, $self->start, $self->end, $self->dt, $self->relative_tolerance, $self->absolute_tolerance, $fh);
    close $fh;
    $status;
}

sub _build_relative_tolerance {
  my $self = shift;
  my $dim = @{$self->initial};
  my @tol;
  for ( 1 .. $dim ) {
    push @tol, sqrt(DBL_EPSILON);
  }
  \@tol;
}

sub _build_absolute_tolerance {
  my $self = shift;
  my $dim = @{$self->initial};
  my @tol;
  for ( 1 .. $dim ) {
    push @tol, sqrt(DBL_EPSILON);
  }
  \@tol;
}

1;
__END__

=head1 NAME

Math::Lsoda - Solve ordinary differential equation systems using lsoda.

=head1 SYNOPSIS

  use Math::Lsoda;

Equation:

  sub eqns {
     my ($t, $x, $y) = @_;
     @$y[0] = 1.0e+4 * @$x[1] * @$x[2] - 0.04 * @$x[0];
     @$y[2] = 3.0e+7 * @$x[1] * @$x[1];
     @$y[1] = -(@$y[0] + @$y[2]);
  }

Solver:

  my $solver = Math::Lsoda->new(equation => \&eqns,
                              initial => [1.0, 0.0, 0.0],
                              start => 0.0,
                              end => 100.0,
                              dt => 0.1,
                              relative_tolerance => [1.0e-4, 1.0e-8, 1.0e-4],
                              absolute_tolerance => [1.0e-6, 1.0e-10,1.0e-6],
                              filename => 'file.dat');

=head1 DESCRIPTION

Math::Lsoda is a numerical module used for solving ordinary differential equations.
The module is suitable for both stiff and non-stiff systems using the FORTRAN library odepack.


=head1 AUTHOR

Naoya Sato E<lt>synclover@gmail.comE<gt>

=head1 SEE ALSO

A. C. Hindmarsh, "ODEPACK, A Systematized Collection of ODE Solvers," in Scientific Computing, R. S. Stepleman et al., North-Holland, Amsterdam, 1983 pp. 55-64.

K. Radhakrishnan and A. C. Hindmarsh, "Description and Use of LSODE, the Livermore Solver for Ordinary Differential Equations," LLNL report UCRL-ID-113855, December 1993.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 Naoya Sato.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
