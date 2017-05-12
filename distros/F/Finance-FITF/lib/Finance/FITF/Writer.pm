package Finance::FITF::Writer;
use strict;
use warnings;
BEGIN {
    eval "use Class::XSAccessor::Compat 'antlers'; 1" or
    eval "use Class::Accessor::Fast 'antlers'; 1" or die $@;
}
use DateTime;
use Carp qw(croak);

extends 'Finance::FITF';

has current_prices => ( is => 'rw' );

has bars_written => (is => "rw", isa => "Int");

has ticks_written => (is => "rw", isa => "Int");
has last_index => (is => "rw", isa => "Int");

has bar_index => (is => "rw", isa => "Int");

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->ticks_written(0);
    $self->bars_written(0);
    $self->last_index(0);

    $self->bar_index(0);

    return $self;
}

sub add_session {
    my ($self, $start_offset, $end_offset) = @_;
    my $date_start = $self->{date_start};

    $self->{bar_ts} ||= [];
    if (scalar @{$self->header->{start}} >= 3) {
        croak "FITF supports up to 3 sessions only.";
    }
    push @{$self->header->{start}}, $date_start + $start_offset;
    push @{$self->header->{end}}, $date_start + $end_offset;
    push @{$self->{bar_ts}},
        map { $date_start + $start_offset + $_ * $self->{header}{bar_seconds} }
            (1..($end_offset - $start_offset) / $self->{header}{bar_seconds});
    $self->nbars( scalar @{$self->{bar_ts}} );
}

sub push_bar {
    my $self = shift;
    my $ts   = shift;
    my $frame = shift;
    my $pos = sysseek($self->{fh}, 0, 1);
    seek $self->{fh}, $self->header_sz + ($self->{bars_written}++) * $self->bar_sz, 0;
    syswrite $self->{fh}, $self->bar_fmt->format({ %$frame, index => $self->{last_index}});

    seek $self->{fh}, $pos, 0;
    $self->last_index( $self->ticks_written );
}

sub push_price {
    my ($self, $ts, $price, $volume) = @_;
    $price *= $self->{header}{divisor};
    unless ($self->ticks_written) {
        seek $self->{fh}, $self->header_sz + $self->nbars * $self->bar_sz, 0;
    }

    die unless @{$self->{bar_ts}};
    my $cp = $self->current_prices;
    my $last = $cp && $cp->{close} || 0;
    while ($ts >= $self->{bar_ts}[$self->{bar_index}]) {
        $self->push_bar($self->{bar_ts}[$self->{bar_index}++],
                      $cp || { open => $last, high => $last, low => $last, close => $last });
        $cp = undef;
    }

    if ($cp) {
        ++$cp->{ticks}; $cp->{volume} += $volume;
        $cp->{close} = $price;
        $cp->{high}  = $price if $price > $cp->{high};
        $cp->{low}   = $price if $price < $cp->{low};
    }
    else {
        $self->current_prices({ open => $price, close => $price,
                                volume => $volume, ticks => 1,
                                high => $price, low => $price });
    }
    my $offset = $ts - $self->{date_start};
    my $offset_min = int($offset/60);
    my $offset_msec = int(($offset - $offset_min*60 ) * 1000);
    syswrite $self->{fh}, $self->tick_fmt->format({ offset_min => $offset_min,
                                                    offset_msec => $offset_msec,
                                                    price => $price,
                                                    volume => $volume,
                                                });
    ++$self->{ticks_written};

}

sub end {
    my $self = shift;

    my $cp = $self->current_prices;
    my $last = $cp && $cp->{close} || 0;
    while ($self->{bar_index} < $self->{nbars}) {
        $self->push_bar($self->{bar_ts}[$self->{bar_index}++],
                      $cp || { open => $last, high => $last, low => $last, close => $last });
        $cp = undef;
    }

    $self->header->{start}[1] ||= 0;
    $self->header->{start}[2] ||= 0;
    $self->header->{end}[1] ||= 0;
    $self->header->{end}[2] ||= 0;

    $self->header->{records} = $self->{ticks_written};
    seek $self->{fh}, 0 ,0;
    syswrite $self->{fh}, $self->header_fmt->format($self->header);
}

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

Finance::FITF::Writer - Fast Intraday Transaction Format Writer

=head1 SYNOPSIS

  use Finance::FITF;
  my $fh;
  my $writer = Finance::FITF::Writer->new(
    fh => $fh,
    header => {
        name => 'XTAF.TX',
        date => '20101119',
        time_zone => 'Asia/Taipei',
        bar_seconds => 10,
    },
  );

  # add session: from 08:45 to 13:45
  $writer->add_session( 525 * 60, 825 * 60 );

  # $writer->push_price( $timestamp, $price, $volume);
  # ...
  $writer->end;

=head1 DESCRIPTION

Finance::FITF::Writer is a helper class to create FITF-formatted files.

=head2 METHODS

=over

=item Finance::FITF::Writer->new( fh => $fh, header => { .... } )

=item $self->add_session($start, $end)

Add a session to the file.  C<$start> and C<$end> are seconds relative
to midnight of the trading day defined by the header.

=item $self->push_price( $timestamp, $price, $volume );

Add a trade transaction record.

=item $self->push_bar( $timestamp, $price, $volume );

You should not call this unless you are writing a bar-only file.

=item $self->end

Call C<end> when you are done.

=back

=head1 AUTHOR

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
