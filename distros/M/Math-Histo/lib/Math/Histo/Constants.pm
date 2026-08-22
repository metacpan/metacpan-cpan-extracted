package Math::Histo::Constants;

use strict;
use warnings;
use Exporter qw(import);

our $VERSION = '0.2.0';


our %EXPORT_TAGS = (
    flags => [qw(
        HISTO_FLAG_NONE
        HISTO_FLAG_TRACK_SUMW2
        HISTO_FLAG_EXACT_MOMENTS
        HISTO_FLAG_AUTO_EXTEND
    )],
    status => [qw(
        HISTO_STATUS_SUCCESS
        HISTO_STATUS_ERR_INVALID_ARG
        HISTO_STATUS_ERR_NO_MEMORY
        HISTO_STATUS_ERR_OUT_OF_BOUNDS
        HISTO_STATUS_ERR_INCOMPATIBLE
        HISTO_STATUS_ERR_NOT_INITIALIZED
        HISTO_STATUS_ERR_SERIALIZATION
        HISTO_STATUS_ERR_DESERIALIZATION
        HISTO_STATUS_ERR_IO
        HISTO_STATUS_ERR_CORRUPT_DATA
    )],
    fit => [qw(
        HISTO_FIT_GAUSSIAN
        HISTO_FIT_EXPONENTIAL
        HISTO_FIT_POLYNOMIAL
        HISTO_FIT_BREIT_WIGNER
        HISTO_FIT_POWER_LAW
        HISTO_FIT_LOG_NORMAL
        HISTO_FIT_GAUSSIAN_PLUS_LINEAR
        HISTO_FIT_WEIBULL
        HISTO_FIT_GAMMA
        HISTO_FIT_POISSON
        HISTO_FIT_LAPLACE
        HISTO_FIT_CUSTOM
        HISTO_FIT_LOSS_CHI2
        HISTO_FIT_LOSS_POISSON_MLE
    )],
    bin_rules => [qw(
        HISTO_BIN_RULE_AUTO
        HISTO_BIN_RULE_FD
        HISTO_BIN_RULE_SCOTT
        HISTO_BIN_RULE_STURGES
        HISTO_BIN_RULE_DOANE
        HISTO_BIN_RULE_KNUTH
    )],
    kde => [qw(
        HISTO_KDE_KERNEL_GAUSSIAN
        HISTO_KDE_KERNEL_EPANECHNIKOV
        HISTO_KDE_KERNEL_UNIFORM
        HISTO_KDE_KERNEL_TRIANGULAR
        HISTO_KDE_KERNEL_BIWEIGHT
        HISTO_KDE_KERNEL_COSINE
        HISTO_KDE_BW_SILVERMAN
        HISTO_KDE_BW_SCOTT
        HISTO_KDE_BW_MANUAL
    )],
    palettes => [qw(
        @PALETTES
    )],
);

our @PALETTES = qw(viridis plasma inferno magma turbo cividis grayscale rainbow);

$EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ];
our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} }, '@PALETTES' );

use constant {
    HISTO_FLAG_NONE             => 0,
    HISTO_FLAG_TRACK_SUMW2      => (1 << 0),
    HISTO_FLAG_EXACT_MOMENTS    => (1 << 1),
    HISTO_FLAG_AUTO_EXTEND      => (1 << 2),

    HISTO_STATUS_SUCCESS        => 0,
    HISTO_STATUS_ERR_INVALID_ARG => 1,
    HISTO_STATUS_ERR_NO_MEMORY  => 2,
    HISTO_STATUS_ERR_OUT_OF_BOUNDS => 3,
    HISTO_STATUS_ERR_INCOMPATIBLE => 4,
    HISTO_STATUS_ERR_NOT_INITIALIZED => 5,
    HISTO_STATUS_ERR_SERIALIZATION => 6,
    HISTO_STATUS_ERR_DESERIALIZATION => 7,
    HISTO_STATUS_ERR_IO         => 8,
    HISTO_STATUS_ERR_CORRUPT_DATA => 9,

    HISTO_FIT_GAUSSIAN          => 0,
    HISTO_FIT_EXPONENTIAL       => 1,
    HISTO_FIT_POLYNOMIAL        => 2,
    HISTO_FIT_BREIT_WIGNER      => 3,
    HISTO_FIT_POWER_LAW         => 4,
    HISTO_FIT_LOG_NORMAL        => 5,
    HISTO_FIT_GAUSSIAN_PLUS_LINEAR => 6,
    HISTO_FIT_WEIBULL           => 7,
    HISTO_FIT_GAMMA             => 8,
    HISTO_FIT_POISSON           => 9,
    HISTO_FIT_LAPLACE           => 10,
    HISTO_FIT_CUSTOM            => 11,

    HISTO_FIT_LOSS_CHI2         => 0,
    HISTO_FIT_LOSS_POISSON_MLE  => 1,

    HISTO_BIN_RULE_AUTO         => 0,
    HISTO_BIN_RULE_FD           => 1,
    HISTO_BIN_RULE_SCOTT        => 2,
    HISTO_BIN_RULE_STURGES      => 3,
    HISTO_BIN_RULE_DOANE        => 4,
    HISTO_BIN_RULE_KNUTH        => 5,

    HISTO_KDE_KERNEL_GAUSSIAN     => 0,
    HISTO_KDE_KERNEL_EPANECHNIKOV => 1,
    HISTO_KDE_KERNEL_UNIFORM      => 2,
    HISTO_KDE_KERNEL_TRIANGULAR   => 3,
    HISTO_KDE_KERNEL_BIWEIGHT     => 4,
    HISTO_KDE_KERNEL_COSINE       => 5,

    HISTO_KDE_BW_SILVERMAN        => 0,
    HISTO_KDE_BW_SCOTT            => 1,
    HISTO_KDE_BW_MANUAL           => 2,
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Math::Histo::Constants - Exportable constants and flags for Math::Histo

=head1 SYNOPSIS

  use Math::Histo::Constants qw(:flags :fit :status :all);

=head1 EXPORT TAGS

=over 4

=item B<:flags>

  HISTO_FLAG_NONE
  HISTO_FLAG_TRACK_SUMW2
  HISTO_FLAG_EXACT_MOMENTS
  HISTO_FLAG_AUTO_EXTEND

=item B<:fit>

  HISTO_FIT_GAUSSIAN
  HISTO_FIT_EXPONENTIAL
  HISTO_FIT_POLYNOMIAL
  HISTO_FIT_BREIT_WIGNER
  HISTO_FIT_POWER_LAW
  HISTO_FIT_CUSTOM
  HISTO_FIT_LOSS_CHI2
  HISTO_FIT_LOSS_POISSON_MLE

=item B<:status>

  HISTO_STATUS_SUCCESS
  HISTO_STATUS_ERR_INVALID_ARG
  HISTO_STATUS_ERR_NO_MEMORY
  HISTO_STATUS_ERR_OUT_OF_BOUNDS
  HISTO_STATUS_ERR_INCOMPATIBLE
  HISTO_STATUS_ERR_NOT_INITIALIZED
  HISTO_STATUS_ERR_SERIALIZATION
  HISTO_STATUS_ERR_DESERIALIZATION
  HISTO_STATUS_ERR_IO
  HISTO_STATUS_ERR_CORRUPT_DATA

=item B<:all>

Exports all constants listed above.

=back

=head1 SEE ALSO

=over 4

=item * L<Math::Histo>

=back

=head1 AUTHOR

Steffen Mueller E<lt>cpan@steffen-mueller.netE<gt>

=head1 LICENSE

MIT License. Copyright (c) 2026 Steffen Mueller and libhisto contributors.

=cut
