package Finance::FITF;

use strict;
use 5.008_001;
our $VERSION = '0.31';
use Finance::FITF::Writer;
use POSIX qw(ceil);
BEGIN {
    eval "use Class::XSAccessor::Compat 'antlers'; 1" or
    eval "use Class::Accessor::Fast 'antlers'; 1" or die $@;
}

use Sub::Exporter -setup => {
    groups  => {
        default    => [ qw(FITF_TICK_FMT FITF_TICK_NONE  FITF_TICK_USHORT FITF_TICK_ULONG
                           FITF_BAR_FMT  FITF_BAR_USHORT FITF_BAR_ULONG)],
    },
    exports => [qw(FITF_TICK_FMT FITF_TICK_NONE FITF_TICK_USHORT FITF_TICK_ULONG
                   FITF_BAR_FMT FITF_BAR_USHORT FITF_BAR_ULONG)],
};

use constant FITF_TICK_FMT    => 0x000f;
use constant FITF_TICK_NONE   => 0x0000;
use constant FITF_TICK_USHORT => 0x0001;
use constant FITF_TICK_ULONG  => 0x0002;

use constant FITF_BAR_FMT     => 0x00f0;
use constant FITF_BAR_USHORT  => 0x0010;
use constant FITF_BAR_ULONG   => 0x0020;

use constant FITF_VERSION => 0x02;
use constant FITF_MAGIC => "\x1f\xf1";
use Parse::Binary::FixedFormat;

my $header_fmt = Parse::Binary::FixedFormat->new(
    [qw(magic:a2 version:n
        date:a8
        time_zone:Z31
        start:N:3
        end:N:3
        records:N
        bar_seconds:n
        format:N
        divisor:N
        name:Z47
   )]);

my $bar_s =
    Parse::Binary::FixedFormat->new([qw(
                                       open:n
                                       high:n
                                       low:n
                                       close:n
                                       volume:n
                                       ticks:n
                                       index:N
                                   )]);

my $bar_l =
    Parse::Binary::FixedFormat->new([qw(
                                       open:N
                                       high:N
                                       low:N
                                       close:N
                                       volume:N
                                       ticks:N
                                       index:N
                                   )]);


my $tick_s =
    Parse::Binary::FixedFormat->new([qw(
                                       offset_min:s
                                       offset_msec:n
                                       price:n
                                       volume:n
                                   )]);

my $tick_l =
    Parse::Binary::FixedFormat->new([qw(
                                       offset_min:s
                                       offset_msec:n
                                       price:N
                                       volume:N
                                   )]);

has fh => ( is => 'ro' );

has header => ( is => "ro", isa => "HashRef" );

has header_fmt => ( is => "ro", isa => "Parse::Binary::FixedFormat" );
has header_sz  => ( is => "rw", isa => "Int");
has bar_fmt    => ( is => "ro", isa => "Parse::Binary::FixedFormat" );
has bar_sz     => ( is => "rw", isa => "Int");
has tick_fmt   => ( is => "ro", isa => "Parse::Binary::FixedFormat" );
has tick_sz    => ( is => "rw", isa => "Int");

has day        => (is => "rw", isa => "DateTime");
has date_start => (is => "rw", isa => "Int");

has nbars => (is => "rw", isa => "Int");

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->header_sz( length( $self->header_fmt->format({}) ) );
    $self->bar_sz(    length( $self->bar_fmt->format({}) ) );
    $self->tick_sz(   length( $self->tick_fmt->format({}) ) );
    my ($y, $m, $d) = $self->header->{date} =~ m/(\d\d\d\d)(\d\d)(\d\d)/;
    $self->day(DateTime->new(time_zone => $self->header->{time_zone},
                             year => $y, month => $m, day => $d));
    $self->date_start( $self->day->epoch );

    $self->{bar_ts} ||= [];

    for (0..2) {
        my ($start, $end) = ($self->header->{start}[$_], $self->header->{end}[$_]);
        last unless $start && $end;

        push @{$self->{bar_ts}},
            map { $start + $_ * $self->{header}{bar_seconds} }
                (1..($end - $start) / $self->{header}{bar_seconds});
    }
    $self->nbars( scalar @{$self->{bar_ts}} );

    return $self;
}


sub new_from_file {
    my $class = shift;
    my $file = shift;
    open my $fh, '<:raw', $file or die "$file: $!";

    sysread $fh, my $buf, length( $header_fmt->format({}) );

    my $header = $header_fmt->unformat($buf);

    # check magic
    die "file not recognized" unless $header->{magic} eq FITF_MAGIC;
    # XXX: sanity check for format

    my $self = $class->new({
        header_fmt => $header_fmt,
        bar_fmt    => ($header->{format} & FITF_BAR_FMT) == FITF_BAR_USHORT  ? $bar_s  : $bar_l,
        tick_fmt   => ($header->{format} & FITF_TICK_FMT) == FITF_TICK_USHORT ? $tick_s : $tick_l,
        fh => $fh,
        header => $header });

    return $self;
}

sub bar_idx {
    my ($self, $timestamp) = @_;
    my $session_idx = 0;
    my $h = $self->header;
    my $offset = 0;
    while ($session_idx < 3 && $timestamp > $h->{end}[$session_idx]) {
        $offset += ($h->{end}[$session_idx] - $h->{start}[$session_idx]) / $h->{bar_seconds};
        ++$session_idx;
    }
    return if $session_idx == 3;
    my $nth = ($timestamp - $h->{start}[$session_idx]) / $h->{bar_seconds} + $offset - 1;
}

sub bar_at {
    my ($self, $timestamp) = @_;
    my $nth = $self->bar_idx($timestamp);
    return unless defined $nth;

    seek $self->{fh}, $nth * $self->bar_sz + $self->header_sz, 0;

    my $buf;
    sysread $self->{fh}, $buf, $self->bar_sz;
    my $bar = $self->bar_fmt->unformat($buf);
    $bar->{$_} /= $self->{header}{divisor} for qw(open high low close);
    return $bar;
}

sub run_ticks {
    my ($self, $start, $end, $cb) = @_;
    my $cnt = $end - $start + 1;
    seek $self->{fh}, $start * $self->tick_sz + $self->nbars * $self->bar_sz + $self->header_sz, 0;

    $self->_fast_unformat($self->tick_fmt, $self->tick_sz, $cnt,
                          sub {
                              my $tick = shift;
                              my $time = $self->{date_start} + $tick->{offset_min}*60 + $tick->{offset_msec}/1000;
                              $cb->($time, $tick->{price} / $self->{header}{divisor}, $tick->{volume});
                          });
}

sub run_bars {
    my ($self, $start, $end, $cb) = @_;
    my $cnt = $end - $start + 1;
    seek $self->{fh}, $start * $self->bar_sz + $self->header_sz, 0;

    $self->_fast_unformat($self->bar_fmt, $self->bar_sz, $cnt, $cb);
}

sub _fast_unformat {
    my ($self, $fmt, $sz, $n, $cb) = @_;

    my $buf;
    read $self->{fh}, $buf, $sz * $n;

    my @records = unpack('('.$fmt->_format.')*', $buf);
    while (my @r = splice(@records, 0, scalar @{$fmt->{Names}})) {
        my $record = {};
        @{$record}{@{$fmt->{Names}}} = @r;
        $cb->($record);
    }
}

sub run_bars_as {
    my ($self, $bar_seconds, $offset, $cb) = @_;
    Carp::confess unless $bar_seconds;
    my @ts;
    my $h = $self->header;
    for (0..2) {
        my ($start, $end) = ($self->header->{start}[$_], $self->header->{end}[$_]);
        last unless $start && $end;

        $start -= $offset;
        push @ts,
            map { my $t = $start + $_ * $bar_seconds;
                  $t < $end ? $t : $end;
              } (1..ceil(($end - $start) / $bar_seconds));
    }

    my $i = 0;
    my $current_bar;
    my $last_price;
    $self->run_bars(0, $self->nbars-1,
                    sub {
                        my $bar = shift;
                        my $ts = $self->{bar_ts}[$i++];
                        if ($bar->{volume}) {
                            if ($current_bar) {
                                $current_bar->{high} = $bar->{high}
                                    if $bar->{high} > $current_bar->{high};
                                $current_bar->{low} = $bar->{low}
                                    if $bar->{low} < $current_bar->{low};

                                $current_bar->{close} = $bar->{close};
                                $current_bar->{volume} += $bar->{volume};
                                $current_bar->{ticks} += $bar->{ticks};
                            }
                            else {
                                $current_bar = $bar;
                            }
                        }
                        if ($ts == $ts[0]) {
                            $current_bar ||= { open => $last_price,
                                               high => $last_price,
                                               low  => $last_price,
                                               close => $last_price,
                                               volume => 0,
                                               ticks => 0,
                                           };
                            $cb->(shift @ts, $current_bar);
                            $last_price = $current_bar->{close};
                            undef $current_bar;
                        }
                    });
    if (@ts) {
        $cb->(shift @ts, $current_bar);
    }
}

sub format_timestamp {
    my ($self, $ts) = @_;
    my $hms = $ts - $self->{date_start};
    my $d = $self->day;

    if ($hms < 0) {
        $d = $d->clone->subtract(days => 1);
        $hms += 86400;
    }
    elsif ($hms >= 86400) {
        $d = $d->clone->add(days => 1);
        $hms -= 86400;
    }
    $hms = sprintf('%02d:%02d:%02d',
                   int($hms / 60 / 60),
                   int(($hms % 3600)/60),
                   ($hms % 60));
    return $d->ymd. ' '.$hms;
}

sub new_writer {
    my ($class, %args) = @_;
    my $hdr = delete $args{header};
    my $header = {
        magic => FITF_MAGIC,
        version => FITF_VERSION,
        start => [],
        end   => [],
        records => 0,
        bar_seconds => 10,
        divisor => 1,
        format => FITF_TICK_ULONG | FITF_BAR_ULONG,
        %$hdr,
    };

    Finance::FITF::Writer->new({
        header_fmt => $header_fmt,
        bar_fmt    => ($header->{format} & FITF_BAR_FMT) == FITF_BAR_USHORT  ? $bar_s  : $bar_l,
        tick_fmt   => ($header->{format} & FITF_TICK_FMT) == FITF_TICK_USHORT ? $tick_s : $tick_l,
        %args,
        header => $header});
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Finance::FITF - Fast Intraday Transaction Format

=head1 SYNOPSIS

  use Finance::FITF;

  my $day = Finance::FITF->new_from_file('XTAF.TX-2010-11-19.fitf');
  warn $day->header->{start}[0]; # start of the first session
  warn $day->header->{end}[0];   # end of the first session

  warn $day->header->{bar_seconds}; # number of seconds per bar

  # last bar in the file. you can get open/high/low/close/volume from $bar
  my $bar = $day->bar_at($day->header->{end}[0]);

  # run the ticks in the last bar with the given callback
  $day->run_ticks($bar->{index}, $bar->{index}+$bar->{ticks}-1,
                  sub { my ($time, $price, $volume) = @_; });

=head1 DESCRIPTION

Finance::FITF provides access to the FITF format, an efficient storage
format for intraday trading records.

=head1 FORMAT

The FITF format consists 3 parts:

=over

=item header

The header defines the name, date, and sessions of the transactions
that the file is describing.

The fields and packing format of FITF header are:

=over

=item magic a2

magic for FITF files should be C<"\x1f\xf1">.

=item version n

FITF format version

=item date a8

YYYYMMDD string of the trading day

=item time_zone Z31

Long time zone name.  For example: America/Chicago, Asia/Taipei.

=item start N:3

start timestamp of each session

=item end N:3

end timestamp of each session

=item records N

number of tick records

=item bar_seconds n

number of seconds per bar

=item format N

flags for bar and tick sizing and format

=item divisor N

the number that the all prices in this file should be divided by

=item name Z47

free form name

=back

=item bars

The number of bars in the file is determined by the total seconds in
the sessions defined in the header, divided by C<bar_seconds> defined
in the header.  The first bar denotes trading transaction between the
start of the session, until and excluding C<bar_seconds> past the start
of the session.

Each bar contains the C<open>, C<high>, C<low>, and C<close> prices
information of the given period, as well as C<volume> and C<ticks>.

The C<index> field points to the start of the tick records of the
period of the current bar.

=item ticks

The number of ticks in the file is determined by the C<records> field
in the header.  Each record contains C<price> and C<volume> for the
transaction.  The time of the transaction is determined by
C<offset_min> and C<offset_msec>, which are time offset in minutes and
milliseconds from the start of the I<first session>, respectively.

=back

=head2 METHODS

=over

=item Finance::FITF->new_from_file($fname)

Returns L<Finance::FITF> object for the given FITF-formatted file at C<$fname>.

=item $self->bar_at($ts)

Returns the bar hash located at C<$ts>.  The bar represents trades
within the C<bar_seconds> before and excluding the epoch timestamp
C<$ts>.

=item $self->bar_idx($ts)

Returns the index of the bar located C<$ts>.

=item $self->run_ticks($start, $end, $cb)

Iterate the ticks indexed by C<$start> and C<$end> for the callback
C<$cb>.  the callback takes timestamp, price, and volume as argument.

=item $self->run_bars($start, $end, $cb)

Iterate the bars indexed by C<$start> and C<$end> for the callback
C<$cb>.  the callback takes the bar hash.

=item $self->run_bars_as($bar_seconds, $offset, $cb)

Aggregate bars into C<$bar_seconds>-bars for the callback C<$cb>.  The
callback takes timestamp of the bar and the bar hash.

=item $self->format_timestamp($ts)

A faster helper to format timestamp as C<"%F %T"> in the
C<$self->header->{time_zone}>.

=back

=head2 ATTRIBUTES

=over

=item header

=item fh

=item nbars

=back

=cut

=head1 AUTHOR

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
