package Finance::Instrument::FuturesContract;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use Moose;
use methods;
use DateTime::Format::Strptime;

extends 'Finance::Instrument';

has futures => (is => "rw", isa => "Finance::Instrument::Futures",
                handles => [qw(name exchange tick_size multiplier time_zone currency session
                               override_since attr)]);

has expiry_year  => (is => "rw", isa => "Int");
has expiry_month => (is => "rw", isa => "Int");

has last_trading_day => (is => "rw", isa => 'DateTime');

has first_trading_day => (is => "rw", isa => "DateTime");


method BUILDARGS {
    my %args = @_;
    my $strp = DateTime::Format::Strptime->new(
        pattern     => '%F',
        time_zone   => $args{futures}->time_zone);
    for (qw(last_trading_day first_trading_day)) {
        if ($args{$_}) {
            $args{$_} = $strp->parse_datetime($args{$_})
                unless ref $args{$_};
        }
    }
    return \%args;
}

method expiry { sprintf("%04d%02d", $self->expiry_year, $self->expiry_month) }

method code { $self->futures->code.'_'.$self->expiry }

method previous_contract {
    $self->futures->previous_contract($self->expiry_year, $self->expiry_month);
}



1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Finance::Instrument -

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
