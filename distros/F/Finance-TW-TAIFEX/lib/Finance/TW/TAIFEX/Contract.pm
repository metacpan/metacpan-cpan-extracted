package Finance::TW::TAIFEX::Contract;
use strict;
use Any::Moose;

=head1 NAME

Finance::TW::TAIFEX::Contract - Contract traded on TAIFEX

=head1 METHODS

=cut

has year  => (is => "ro", isa => "Int", required => 1);
has month => (is => "ro", isa => "Int", required => 1);
has product => (is => "ro", isa => "Finance::TW::TAIFEX::Product",
                handles => [qw(name exchange find_settlement_day)],
            );

=head2 is_settlement_day DATE

Check if DATE is a settlement day

=cut

sub is_settlement_day {
    my ($self, $date) = @_;
    return $date->ymd eq $self->settlement_day->ymd
}

=head2 settlement_day

Returns the settlement day of the contract.

=cut

sub settlement_day {
    my $self = shift;

    $self->find_settlement_day(
        DateTime->new( year => $self->year, month => $self->month, day => 1)
    );
}


my $local_month_code = ['A'..'L'];
sub encode_local {
    my $self = shift;
    return $local_month_code->[$self->month-1].substr($self->year, -1, 1);
}

my $month_code = [qw(F G H J K M N Q U V X Z)];
sub encode {
    my $self = shift;
    return $month_code->[$self->month-1].substr($self->year, -1, 1);
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;

