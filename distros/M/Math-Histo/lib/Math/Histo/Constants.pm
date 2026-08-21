package Math::Histo::Constants;

use strict;
use warnings;
use Exporter qw(import);

our $VERSION = '0.1.0';

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
        HISTO_FIT_CUSTOM
        HISTO_FIT_LOSS_CHI2
        HISTO_FIT_LOSS_POISSON_MLE
    )],
);

$EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{all} };

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
    HISTO_FIT_CUSTOM            => 5,

    HISTO_FIT_LOSS_CHI2         => 0,
    HISTO_FIT_LOSS_POISSON_MLE  => 1,
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
