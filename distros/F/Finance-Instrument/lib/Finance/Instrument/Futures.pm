package Finance::Instrument::Futures;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use Moose;
use methods;
use Finance::Instrument::FuturesContract;
use List::MoreUtils qw(firstidx);
extends 'Finance::Instrument';

has multiplier => (is => "rw", isa => "Num");
has currency => (is => "rw", isa => "Str");
has underlying => (is => "rw", isa => "Maybe[Finance::Instrument]");
has last_trading_day_close => (is => "rw", isa => "Int");
has month_cycle => (is => "rw", isa => "Str");
has active_months => (is => "rw", isa => "Int");

has contract_calendar => (is => "rw", isa => "HashRef", default => sub { {} });

my $month_code = [qw(F G H J K M N Q U V X Z)];

sub encode {
    my $self = shift;
    my $year_digit = shift || 2;
    return $month_code->[$self->month-1].substr($self->year, -1 * $year_digit, $year_digit);
}

method near_term_contract($datetime) {
    my $date = ref($datetime) ? $datetime->ymd : $datetime;
    my @contracts = reverse sort keys %{$self->contract_calendar};
    for my $c_i (0..$#contracts-1) {
        my ($curr, $prev) = map { $self->contract_calendar->{$contracts[$_]} } ($c_i, $c_i + 1);
        if ($date le $curr->{last_trading_day} && $date gt $prev->{last_trading_day}) {
            return $self->contract($contracts[$c_i]);
        }
    }
}

method contract($year, $month) {
    unless ($month) {
        ($year, $month) = $year =~ m/(\d\d\d\d)(\d\d)/
            or Carp::croak "invalid expiry format";
    }
    my $expiry = sprintf("%04d%02d", $year, $month);
    my $curr = $self->contract_calendar->{$expiry} || {};
    my $fc = $self->domain->get($self->code.'_'.$expiry)
        || Finance::Instrument::FuturesContract->new( futures => $self,
                                                      expiry_year => int($year),
                                                      expiry_month => int($month),
                                                      domain => $self->domain,
                                                      %$curr,
                                                  );
}

method previous_contract($year, $month) {
    my $month_idx = index($self->month_cycle, $month_code->[$month-1]);
    die "unknown month $month in month_cycle" if $month_idx < 0;
    if ($month_idx == 0) {
        --$year;
    }
    my $code = substr($self->month_cycle, $month_idx - 1, 1);

    $self->contract($year, 1 + firstidx { $_ eq $code } @$month_code);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Finance::Instrument::Futures -

=head1 SYNOPSIS

  use Finance::Instrument;

=head1 DESCRIPTION

Finance::Instrument is

=head1 AUTHOR

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
