package Log::Stamper;
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '0.031';

our $GMTIME = 0;

our @MONTH_NAMES = qw/
    January February March April May June July
    August September October November December
/;

our @WEEK_DAYS = qw/
    Sunday Monday Tuesday Wednesday Thursday Friday Saturday
/;

sub new {
    my ($class, $format, $callback) = @_;

    my $self = +{
        stack    => [],
        fmt      => undef,
        callback => ref($callback) eq 'CODE' ? $callback : undef,
    };

    bless $self, $class;

    $self->_prepare($format) if $format;

    return $self;
}

sub _prepare {
    my($self, $format) = @_;

    # the actual DateTime spec allows for literal text delimited by
    # single quotes; a single quote can be embedded in the literal
    # text by using two single quotes.
    #
    # my strategy here is to split the format into active and literal
    # "chunks"; active chunks are prepared using $self->rep() as
    # before, while literal chunks get transformed to accomodate
    # single quotes and to protect percent signs.
    #
    # motivation: the "recommended" ISO-8601 date spec for a time in
    # UTC is actually:
    #
    #     YYYY-mm-dd'T'hh:mm:ss.SSS'Z'

    my $fmt = '';

    for my $chunk ( split /('(?:''|[^'])*')/, $format ) {
        if ( $chunk =~ /\A'(.*)'\z/ ) {
            # literal text
            my $literal = $1;
            $literal =~ s/''/'/g;
            $literal =~ s/\%/\%\%/g;
            $fmt .= $literal;
        } elsif ( $chunk =~ /'/ ) {
            # single quotes should always be in a literal
            croak "bad date format \"$format\": " .
                  "unmatched single quote in chunk \"$chunk\"";
        } else {
            # handle active chunks just like before
            $chunk =~ s/(([GyMdhHmsSEeDFwWakKzZ])\2*)/$self->_rep($1)/ge;
            $fmt .= $chunk;
        }
    }

    $self->{fmt} = $fmt;
}

sub _rep {
    my ($self, $string) = @_;

    my $first = substr $string, 0, 1;
    my $len   = length $string;

    my $time=time();
    my @g = gmtime($time);
    my @t = localtime($time);
    my $z = $t[1]-$g[1]+($t[2]-$g[2])*60+($t[7]-$g[7])*1440+
            ($t[5]-$g[5])*(525600+(abs($t[7]-$g[7])>364)*1440);
    my $offset = sprintf("%+.2d%.2d", $z/60, "00");

    #my ($s,$mi,$h,$d,$mo,$y,$wd,$yd,$dst) = localtime($time);

    # Here's how this works:
    # Detect what kind of parameter we're dealing with and determine
    # what type of sprintf-placeholder to return (%d, %02d, %s or whatever).
    # Then, we're setting up an array, specific to the current format,
    # that can be used later on to compute the components of the placeholders
    # one by one when we get the components of the current time later on
    # via localtime.

    # So, we're parsing the "yyyy/MM" format once, replace it by, say
    # "%04d:%02d" and store an array that says "for the first placeholder,
    # get the localtime-parameter on index #5 (which is years since the
    # epoch), add 1900 to it and pass it on to sprintf(). For the 2nd
    # placeholder, get the localtime component at index #2 (which is hours)
    # and pass it on unmodified to sprintf.

    # So, the array to compute the time format at logtime contains
    # as many elements as the original SimpleDateFormat contained. Each
    # entry is a arrary ref, holding an array with 2 elements: The index
    # into the localtime to obtain the value and a reference to a subroutine
    # to do computations eventually. The subroutine expects the orginal
    # localtime() time component (like year since the epoch) and returns
    # the desired value for sprintf (like y+1900).

    # This way, we're parsing the original format only once (during system
    # startup) and during runtime all we do is call localtime *once* and
    # run a number of blazingly fast computations, according to the number
    # of placeholders in the format.

    if($first eq 'G') { # G - epoch
        # Always constant
        return 'AD';
    }
    elsif($first eq 'e') { # e - epoch seconds
          # index (0) irrelevant, but we return time() which
          # comes in as 2nd parameter
        push @{$self->{stack}}, [0, sub { return $_[1] }];
        return "%d";
    }
    elsif($first eq 'y') { # y - year
        if($len >= 4) {
            # 4-digit year
            push @{$self->{stack}}, [5, sub { return $_[0] + 1900 }];
            return "%04d";
        }
        else {
            # 2-digit year
            push @{$self->{stack}}, [5, sub { $_[0] % 100 }];
            return "%02d";
        }
    }
    elsif($first eq 'M') { # M - month
        if($len >= 3) {
            # Use month name
            push @{$self->{stack}}, [4, sub { return $MONTH_NAMES[$_[0]] }];
           if($len >= 4) {
                return "%s";
            }
            else {
               return "%.3s";
            }
        }
        elsif($len == 2) {
            # Use zero-padded month number
            push @{$self->{stack}}, [4, sub { $_[0]+1 }];
            return "%02d";
        }
        else {
            # Use zero-padded month number
            push @{$self->{stack}}, [4, sub { $_[0]+1 }];
            return "%d";
        }
    }
    elsif($first eq 'd') { # d - day of month
        push @{$self->{stack}}, [3, sub { return $_[0] }];
        return "%0" . $len . 'd';
    }
    elsif($first eq 'h') { #h - am/pm hour
        push @{$self->{stack}}, [2, sub { ($_[0] % 12) || 12 }];
        return "%0" . $len . 'd';
    }
    elsif($first eq 'H') { # H - 24 hour
        push @{$self->{stack}}, [2, sub { return $_[0] }];
        return "%0" . $len . 'd';
    }
    elsif($first eq 'm') { # m - minute
        push @{$self->{stack}}, [1, sub { return $_[0] }];
        return "%0" . $len . 'd';
    }
    elsif($first eq 's') { # s - second
        push @{$self->{stack}}, [0, sub { return $_[0] }];
        return "%0" . $len . 'd';
    }
    elsif($first eq 'E') { # E - day of week
        push @{$self->{stack}}, [6, sub { $WEEK_DAYS[$_[0]] }];
        if($len >= 4) {
            return "%${len}s";
        }
        else {
           return "%.3s";
        }
    }
    elsif($first eq 'D') { # D - day of the year
        push @{$self->{stack}}, [7, sub { $_[0] + 1}];
        return "%0" . $len . 'd';
    }
    elsif($first eq 'a') { # a - am/pm marker
        push @{$self->{stack}}, [2, sub { $_[0] < 12 ? 'AM' : 'PM' }];
        return "%${len}s";
    }
    elsif($first eq 'S') { # S - milliseconds
        push @{$self->{stack}},
             [9, sub { substr sprintf("%06d", $_[0]), 0, $len }];
        return "%s";
    }
    elsif($first eq 'Z') { # Z - RFC 822 time zone  -0800
        push @{$self->{stack}}, [10, sub { $offset }];
        return "$offset";
    }
    # Something that's not defined
    # (F=day of week in month
    #  w=week in year W=week in month
    #  k=hour in day K=hour in am/pm
    #  z=timezone
    else {
        return "-- '$first' not (yet) implemented --";
    }

    return $string;
}

sub format {
    my($self, $secs, $msecs) = @_;

    $secs ||= time();
    $msecs  = 0 unless defined $msecs;

    my @time;

    if($GMTIME) {
        @time = gmtime $secs;
    }
    else {
        @time = localtime $secs;
    }

    # add milliseconds
    push @time, $msecs;

    my @values = ();

    for my $stack ( @{$self->{stack}} ) {
        my($val, $code) = @{$stack};
        if($code) {
            push @values, $code->($time[$val], $secs);
        }
        else {
            push @values, $time[$val];
        }
    }

    my $ret = sprintf($self->{fmt}, @values);

    if ($self->callback) {
        return ($self->callback)->($ret);
    }
    else {
        return $ret;
    }
}

sub callback { $_[0]->{callback}; }

1;

__END__

=head1 NAME

Log::Stamper - generate the formatted stamp for logging


=head1 SYNOPSIS

    use Log::Stamper;

    my $stamp = Log::Stamper->new("yyyy-MM-dd");

    # Simple time, resolution in seconds
    my $time = time();
    print $stamp->format($time); # 2013-01-13

    # if you use milliseconds
    use Time::HiRes;
    my $stamp = Log::Stamper->new("HH:mm:ss,SSS");
    my ($secs, $msecs) = Time::HiRes::gettimeofday();
    print $stamp->format($secs, $msecs); # => "17:02:39,959"

Typically, you would initialize the stamper once and then reuse
it over and over again to display all kinds of time values.


=head1 DESCRIPTION

C<Log::Stamper> is a formatter which allows dates to be formatted
according to the log4j spec on

    http://download.oracle.com/javase/1.4.2/docs/api/java/text/SimpleDateFormat.html

which allows the following placeholders to be recognized and processed:

    Symbol Meaning              Presentation    Example
    ------ -------              ------------    -------
    G      era designator       (Text)          AD
    e      epoch seconds        (Number)        1315011604
    y      year                 (Number)        1996
    M      month in year        (Text & Number) July & 07
    d      day in month         (Number)        10
    h      hour in am/pm (1~12) (Number)        12
    H      hour in day (0~23)   (Number)        0
    m      minute in hour       (Number)        30
    s      second in minute     (Number)        55
    S      millisecond          (Number)        978
    E      day in week          (Text)          Tuesday
    D      day in year          (Number)        189
    F      day of week in month (Number)        2 (2nd Wed in July)
    w      week in year         (Number)        27
    W      week in month        (Number)        2
    a      am/pm marker         (Text)          PM
    k      hour in day (1~24)   (Number)        24
    K      hour in am/pm (0~11) (Number)        0
    z      time zone            (Text)          Pacific Standard Time
    Z      RFC 822 time zone    (Text)          -0800
    '      escape for text      (Delimiter)
    ''     single quote         (Literal)       '


=head1 METHODS

=head2 new

constractor

=head2 format

return the formatted string

=head2 callback

return the code reference for filtering.

    use Log::Stamper;
    my $stamper = Log::Stamper->new(
        "yyyy",
        sub {
            my $str = shift;
            $str =~ s/0/X/g;
            return $str;
        }
    );
    print $stamper->format(time()); # 2X13


=head1 REPOSITORY

Log::Stamper is hosted on github
<http://github.com/bayashi/Log-Stamper>


=head1 AUTHOR

This module was copied from C<Log::Log4perl::DateFormat> to go independent.

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Log::Log4perl::DateFormat>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
