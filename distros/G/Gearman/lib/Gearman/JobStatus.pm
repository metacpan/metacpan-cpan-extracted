package Gearman::JobStatus;
use version ();
$Gearman::JobStatus::VERSION = version->declare("2.004.015");


use strict;
use warnings;

=head1 NAME

Gearman::JobStatus - represents a job status in gearman distributed job system

=head1 DESCRIPTION

L<Gearman::Client> get_status($handle) returns I<Gearman::JobStatus> for a given handle

=head1 METHODS

=cut

sub new {
    my ($class, $known, $running, $nu, $de) = @_;
    $nu = '' unless defined($nu) && length($nu);
    $de = '' unless defined($de) && length($de);

    return bless [$known, $running, $nu, $de], $class;
} ## end sub new

=head2 known()

=cut

sub known { shift->[0]; }

=head2 running()

=cut

sub running { shift->[1]; }

=head2 progress()

=cut

sub progress {
    my $self = shift;
    return $self->[2] ne '' ? [$self->[2], $self->[3]] : undef;
}

=head2 percent()

=cut

sub percent {
    my $self = shift;
    return ($self->[2] ne '' && $self->[3])
        ? ($self->[2] / $self->[3])
        : undef;
} ## end sub percent

1;
