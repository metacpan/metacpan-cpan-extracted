package Math::Histo::KDE;

use strict;
use warnings;
use Math::Histo ();
use Math::Histo::Constants ();

our $VERSION = '0.2.0';

my %KERNEL_MAP = (
    gaussian     => Math::Histo::Constants::HISTO_KDE_KERNEL_GAUSSIAN,
    epanechnikov => Math::Histo::Constants::HISTO_KDE_KERNEL_EPANECHNIKOV,
    uniform      => Math::Histo::Constants::HISTO_KDE_KERNEL_UNIFORM,
    boxcar       => Math::Histo::Constants::HISTO_KDE_KERNEL_UNIFORM,
    triangular   => Math::Histo::Constants::HISTO_KDE_KERNEL_TRIANGULAR,
    biweight     => Math::Histo::Constants::HISTO_KDE_KERNEL_BIWEIGHT,
    quartic      => Math::Histo::Constants::HISTO_KDE_KERNEL_BIWEIGHT,
    cosine       => Math::Histo::Constants::HISTO_KDE_KERNEL_COSINE,
);

my %BW_MAP = (
    silverman => Math::Histo::Constants::HISTO_KDE_BW_SILVERMAN,
    scott     => Math::Histo::Constants::HISTO_KDE_BW_SCOTT,
    manual    => Math::Histo::Constants::HISTO_KDE_BW_MANUAL,
);

sub new {
    my ($class, %args) = @_;
    my $samples   = $args{samples}   // $args{data} // croak("Math::Histo::KDE->new: 'samples' arrayref required");
    my $weights   = $args{weights};
    my $kernel    = $args{kernel}    // 'gaussian';
    my $bw_method = $args{bw_method} // 'silverman';
    my $bandwidth = $args{bandwidth} // 0.0;
    my $bw_adjust = $args{bw_adjust} // 1.0;

    my $k_code  = exists $KERNEL_MAP{lc($kernel)} ? $KERNEL_MAP{lc($kernel)} : int($kernel);
    my $bw_code = exists $BW_MAP{lc($bw_method)} ? $BW_MAP{lc($bw_method)} : int($bw_method);

    return $class->_create($samples, $weights, $k_code, $bw_code, $bandwidth, $bw_adjust);
}

sub from_histogram {
    my ($class, $h, %args) = @_;
    my $kernel    = $args{kernel}    // 'gaussian';
    my $bw_method = $args{bw_method} // 'silverman';
    my $bandwidth = $args{bandwidth} // 0.0;
    my $bw_adjust = $args{bw_adjust} // 1.0;

    my $k_code  = exists $KERNEL_MAP{lc($kernel)} ? $KERNEL_MAP{lc($kernel)} : int($kernel);
    my $bw_code = exists $BW_MAP{lc($bw_method)} ? $BW_MAP{lc($bw_method)} : int($bw_method);

    return $class->_create_from_histo($h, $k_code, $bw_code, $bandwidth, $bw_adjust);
}

sub pdf {
    my ($self, $x) = @_;
    return $self->eval($x);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Math::Histo::KDE - 1-Dimensional Kernel Density Estimation (KDE) Engine

=head1 SYNOPSIS

  use Math::Histo::KDE;

  # Construct KDE from sample points
  my $kde = Math::Histo::KDE->new(
      samples   => [1.2, 2.3, 2.5, 3.1, 4.8, 5.0],
      kernel    => 'gaussian',     # or epanechnikov, uniform, triangular, biweight, cosine
      bw_method => 'silverman',    # or scott, manual
  );

  # Evaluate estimated probability density (PDF)
  my $pdf = $kde->eval(2.5);

  # Evaluate cumulative distribution (CDF)
  my $cdf = $kde->cdf(2.5);

  # Invert CDF for quantile
  my $median = $kde->quantile(0.50);

  # Generate random synthetic samples
  my @samples = $kde->sample(100, 42);

  # Construct directly from a Math::Histo histogram
  my $h_kde = Math::Histo::KDE->from_histogram($histo);

=head1 DESCRIPTION

C<Math::Histo::KDE> provides fast, non-parametric continuous density estimation
for 1-dimensional datasets using standard kernel functions and automated bandwidth
selection rules.

=cut
