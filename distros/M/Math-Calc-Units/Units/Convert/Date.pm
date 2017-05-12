package Math::Calc::Units::Convert::Date;
use base 'Math::Calc::Units::Convert::Base';
use Time::Local qw(timegm);
use strict;
use vars qw(%units %pref %ranges %total_unit_map);

my $min_nice_time = timegm(0, 0, 0, 1, 0, 1975-1900);
my $max_nice_time = timegm(0, 0, 0, 1, 0, 2030-1900);

%units = ();
%pref = ( default => 1 );
%ranges = ( timestamp => [ $min_nice_time, $max_nice_time ] );

sub major_pref {
    return 2;
}

# sub major_variants {}

# sub variants {}

sub canonical_unit { return 'timestamp'; }

sub unit_map {
    my ($self) = @_;
    if (keys %total_unit_map == 0) {
	%total_unit_map = (%{$self->SUPER::unit_map()}, %units);
    }
    return \%total_unit_map;
}

sub get_ranges {
    return \%ranges;
}

sub get_prefs {
    return \%pref;
}

use vars qw(@MonthNames);
BEGIN { @MonthNames = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec); }
sub construct {
    my ($self, $constructor, $args) = @_;

    # Allow timestamp(1000347142) or timestamp() for the current time
    if ($constructor eq 'timestamp') {
        $args = time if $args eq '';
        return [ $args, { 'timestamp' => 1 } ];
    }

    return unless $constructor eq 'date';

    # Accept a very limited range of formats.

    # Always assume GMT if not given. Currently, do not handle timezones.
    $args =~ s/\s+GMT\s+$//;

    my ($Mon, $d, $y, $h, $m, $s, $tz, $M);
    $tz = 'GMT';

    # Format 1: [Weekday] Mon DD HH:MM:SS [Timezone] YYYY
    # (as returned by gmtime and the 'date' command)
    # The weekday is ignored if given. The timezone is currently ignored.
    if ($args =~ /^((?:\w\w\w\s+)?)
                   (\w\w\w)\s*
                   (\d+)\s+
                   (\d+):(\d+)[:.](\d+)\s+
                   (\w+)?\s*
                   (\d\d\d\d)$/x)
    {
        (undef, $Mon, $d, $h, $m, $s, $tz, $y) = ($1, $2, $3, $4, $5, $6, $7, $8);

    # Format 2: Mon DD YYYY
    } elsif ($args =~ /^(\w\w\w)[\s-]*
                        (\d+)[,\s-]+
                        (\d\d\d\d)$/x)
    {
        ($Mon, $d, $y) = ($1, $2, $3);

    # Format 3: YYYY-MM-DD HH:MM:SS
    } elsif ($args =~ /^(\d\d\d\d)-(\d+)-(\d+)\s+
                        (\d+):(\d+)[:.](\d+)$/x)
    {
        ($y, $M, $d, $h, $m, $s) = ($1, $2, $3, $4, $5, $6);
        $M--;

    # Format 4: YYYY-MM-DD
    } elsif ($args =~ /^(\d\d\d\d)-(\d+)-(\d+)$/) {
        ($y, $M, $d) = ($1, $2, $3);
        $M--;
    } else {
        die "Unparseable date string '$args'";
    }

    $h ||= 0;
    $m ||= 0;
    $s ||= 0;

    if (defined $Mon) {
        $M = 0;
        foreach (@MonthNames) {
            last if lc($_) eq lc($Mon);
            $M++;
        }
        die "Unparseable month '$Mon'" if $M > 11;
    }

    if (defined($tz) && $tz ne 'GMT') {
        warn "Timezones not supported. Assuming GMT.\n";
    }

    my $timestamp = timegm($s, $m, $h, $d, $M, $y-1900);
    die "Date '$args' is out of range" if $timestamp == -1;
    return [ $timestamp, { 'timestamp' => 1 } ];
}

sub render {
    my ($self, $mag, $name, $power) = @_;
    return "\@$mag" if $power != 1;
    return "\@$mag" if $mag < $min_nice_time;
    return "\@$mag" if $mag > $max_nice_time;
    return gmtime($mag) . " (\@$mag)";
}

1;
