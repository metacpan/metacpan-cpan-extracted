package Finance::Instrument;

use strict;
use 5.008_001;
our $VERSION = '0.02';

use Moose;
use methods;
use Finance::Instrument::Domain;
use Finance::Instrument::Exchange;
use MooseX::ClassAttribute;
use DateTime;

class_has global => (is => "rw", isa => "Financial::Instrument::Domain",
                     default => sub { Finance::Instrument::Domain->global },
                     handles => [qw(load_default_exchanges
                                    load_instrument_from_yml
                                    load_default_instrument
                                    get_exchange
                                    add_exchange
                                    get
                                    load_instrument
                               )]);

has domain => (is => "ro", isa => "Finance::Instrument::Domain", weak_ref => 1,
               default => sub { Finance::Instrument::Domain->global });

has code => (is => "ro", isa => "Str");
has name => (is => "ro", isa => "Str");

has attributes => (is => "rw", isa => "HashRef",
                   traits  => ['Hash'],
                   default => sub { {} },
                   handles   => {
                       attr     => 'accessor'
                   });

has time_zone => (is => "rw", isa => "Str");
has tick_size => (is => "rw", isa => "Num");
has exchange  => (is => "rw", isa => "Finance::Instrument::Exchange");
has session   => (is => "rw", isa => "ArrayRef[ArrayRef[Int]]");

has override_since => (is => "rw", isa => "HashRef", default => sub { {} });

has override_dow   => (is => "rw", isa => "HashRef", default => sub { {} });

method BUILD {
    $self->domain->add($self);
}

around attr => sub {
    my ($next, $self, @args) = @_;
    my ($key, $val) = @args;
    my $ret = $self->$next(@args);
    unless (defined $ret || defined $val) {
        $ret = $self->exchange->attr($key)
    }
    return $ret;
};

sub get_spec_for_date {
    my ($self, $date) = @_;
    my $spec = { map { $_ => $self->$_ } qw(time_zone session tick_size override_dow) };
    for (sort keys %{$self->override_since}) {
        last if $_ gt $date;
        $spec = { %$spec, %{$self->override_since->{$_}} };
    }
    if ($self->{override_dow}) {
        my ($y, $m, $d) = split('-', $date);
        my $dt = DateTime->new( year => $y, month => $m, day => $d,
                                time_zone => $spec->{time_zone} || $self->time_zone );
        $spec = { %$spec, %{$spec->{override_dow}{$dt->day_of_week} || {}} };
    }
    return $spec;
}

method derive_session($_dt) {
    my $dt = $_dt->clone->truncate(to => 'day');
    my $session = $self->session_for_day($dt);

    if ($session->[-1][1] > 1440 && $_dt <= $dt->clone->add(minutes => $session->[-1][1] - 1440)) {
        my $prev_session = $self->session_for_day($dt->add(days => -1));
        if ($_dt <=  $dt->clone->add(minutes => $session->[-1][1] - 1440)) {
            return ($prev_session, $dt, $#{$prev_session});
        }
    }

    my $idx = 0;
    for (@{ $session }) {
        my ($start, $end) = map { $dt->clone->add(minutes => $_) } @$_;
        if ($_dt <= $end) {
            last;
        }
        ++$idx;
    }

    if ($idx >= @{ $session }) {
        $idx = 0;
        $dt->add(days => 1);
        return $self->derive_session($dt);
    }

    return ($session, $dt, $idx);
}

method session_for_day($dt) {
    $self->get_spec_for_date($dt->ymd)->{session} || $self->session;
}

method trading_time_for_day($dt) {
    my ($session) = $self->session_for_day($dt);
    my $base = $dt->clone->truncate(to => 'day')->epoch;
    return [map { [ $base + $_->[0] * 60, $base + $_->[1] * 60 ] } @$session]
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

Finance::Instrument - Object representation of financial instruments

=head1 SYNOPSIS

  use Finance::Instrument;
  # load all iso10383 market identification exchanges
  Finance::Instrument->load_default_exchanges;
  Finance::Instrument->get_exchange('XHKF');

  my $spec = { type => 'Futures',
               exchange => 'XHKF',
               code => 'HSI',
               time_zone => 'Asia/Hong_Kong',
               currency => 'HKD',
               session => [[555, 720], [810, 975]] };

  my $hsi = Finance::Instrument->load_instrument($spec);
  my $contract = $hsi->contract(2012, 2);
  $contract->trading_time_for_day(DateTime->now);

=head1 DESCRIPTION

Finance::Instrument models financial instruments and provide utility
functions, such as calculating current or next trading hours for a
given L<DateTime>, or retrieve near-term futures contract from futures
contract series.

=head1 AUTHOR

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
