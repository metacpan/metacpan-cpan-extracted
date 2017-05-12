package Geomag::Kyoto::Dst;

use 5.008;
use strict;
use warnings;
use LWP::Simple;
use Time::Local;

@Geomag::Kyoto::Dst::FILES = qw(Dstqthism.html Dstqlastm.html);
$Geomag::Kyoto::Dst::BASE  = 'http://swdcdb.kugi.kyoto-u.ac.jp/dstdir/dst1/q/';

our $VERSION = '0.01';

#
# Values stored in a hash: $time => $dst_val
#

sub new {
    my $class = shift || 'Geomag::Kyoto::Dst';
    my $dst = bless { values => {}}, $class;
    my %args = (@_);
    # default if no args is to fetch thism and lastm
    if (!@_) {
	return $dst->_parse_base(base=>$Geomag::Kyoto::Dst::BASE, files=> [@Geomag::Kyoto::Dst::FILES]);
    }
    # if we have a single file => arg, then parse that file only
    if (@_ == 2) {
	if ($args{file}) {
	    return $dst->_parse_file($args{file});
	}
	if ($args{url}) {
	    return $dst->_parse_url($args{url});
	}
	if ($args{files}) {
	    foreach (@{$args{files}}) {
		$dst->_parse_file($_);
	    }
	    return $dst;
	}
    }

    if (@_ == 4) {
	$dst->_except("bad args to new()") unless $args{base} && $args{files};
	return $dst->_parse_base(base=>$args{base}, files => $args{files});
    }
    $dst->_except("bad args to new()");
}

sub get_array {
    my $dst = shift;
    my @vals;
    while (my ($time,$val) = each %{$dst->{values}}) {
	push @vals, [$time, $val];
    }
    if (@_) {
	my %args = @_;
	if (my $start = $args{start}) {
	    @vals = grep {$_->[0] >= $start} @vals;
	}
	if (my $end = $args{end}) {
	    @vals = grep {$_->[0] <= $end} @vals;
	}
    }
    @vals = sort {$a->[0] <=> $b->[0]} @vals;
    return \@vals;
}

sub get_hash {
    my $dst = shift;
    # no limits...
    if (!@_) {
	return $dst->{values};
    }
    my %args = @_;
    my %ret;
    my ($start, $end) = @args{qw(start end)};
    while(my($time, $val) = each %{$dst->{values}}) {
	if (!$start || $time >= $start) {
	    if (!$end || $time <= $end) {
		$ret{$time} = $val;
	    }
	}
    }
    return \%ret;
}

sub _parse_file {
    my $dst = shift;
    my $file = shift;

    open(my $fh, "<$file") or $dst->_except("Cannot open $file $!");
    my $contents = do {local $/; <$fh>};
    close($fh);

    return $dst->_parse_scalar($contents);
}

sub _parse_url {
    my $dst =shift;
    my $url = shift;

    my $contents = get($url);
    $dst->_except("Failed to get $url") unless defined $contents;
    
    return $dst->_parse_scalar($contents);
}

sub _parse_base {
    my $dst = shift;
    my %args = @_; # base, files

    my $base = $args{base};
    my @files = @{$args{files}};
    foreach my $file (@files) {
	$dst->_parse_url("$base/$file");
    }
    return $dst;
}

sub _parse_scalar {
    my $dst = shift;
    my $data = shift;
    my @lines = split(/\n|\r\n|\r/, $data);

    my ($mon, $year, $day);
    my @months = qw(january february march
		    april may june
		    july august september
		    october november december);
    my $mnths = join("|", @months);
    my $i = 0;
    my %m_num = map {$_ => $i++} @months;

    foreach (@lines) {
	/^\s+($mnths)\s+(\d{4})/i && do {
	    $mon = $m_num{lc($1)};
	    $year = +$2;
	    next;
	};
	if (/^DAY/ && !defined($mon) && !defined($year)) {
	    $dst->_except("Did not find month or year in data");
	}
	# optional space, day num, space 8 4 char groups, space, 8 4 char groups, space, 8 4 char groups
	/^ ?(\d{1,2}) ([ 0-9-]{32}) ([ 0-9-]{32}) ([ 0-9-]{32})/ && do {
	    $day = $1;
	    $dst->_parse_vals($year, $mon, $day, "$2$3$4");
	};
    }
    return $dst;
}

sub _parse_vals {
    my $dst = shift;
    my ($year, $mon, $day, $sval) = @_;
    $dst->_except("No year, mon or day") unless defined($year) && defined($mon) && defined($day);

    # four character groups
    for (my $hour = 0; $hour < 24; $hour++) {
	my $val = substr($sval, $hour*4, 4);
	# only add valid values
	next if ($val eq "9999");
	next if ($val eq "    ");
	$dst->_add_val($year, $mon, $day, $hour, $val);
    }
    return $dst;
}

# expects values to be valid
sub _add_val {
    my($dst, $year, $mon, $day, $hour, $val) = @_;
    # only here do we alter into computer time values
    my $epoch = timegm(0,0,$hour, $day, $mon, $year-1900);
    $dst->{values}->{$epoch} = $val;
}

# placeholder for proper exceptions
sub _except {
    my $self = shift;
    die "DST: Exception: $_[0]";
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Geomag::Kyoto::Dst - Obtain and parse Kyoto WDC near real time DST values

=head1 SYNOPSIS

  use Geomag::Kyoto::Dst;
  blah blah blah

=head1 DESCRIPTION

A module to parse the near real time Dst measurements made available
by the Kyoto World Data Center for Geomagnetism.

=head1 METHODS

=head3 new()

 $dst = Geomag::Kyoto::Dst->new();

Obtain this month's and last month's Dst values from the default url.

 $dst = Geomag::Kyoto::Dst->new(file => $filename);

Parse the values directly from $filename.

 $dst = Geomag::Kyoto::Dst->new(file => [@filenames]);

Parse the values from a collection of files.

 $dst = Geomag::Kyoto::Dst->new(url => $url);

Obtain the values from the page at $url.

 $dst = Geomag::Kyoto::Dst->new(base => $base, files => [@files]);

Obtain the values from a collection of files over the web at $base.

Returns a new Geomag::Kyoto::Dst object, or dies if errors occur
(eg. file not found).

=head3 get_array()

Returns all predictions as a 2d array:

 my $aref = $dst->get_array();
 
 $time    = $aref->[0][0]
 $dst_val = $aref->[0][1]

Values will be sorted by time, with the earliest entry first.  Time
will be in epoch seconds.  Optionally specify a start and/or end time
to limit the range of values returned:

 $aref = $dst->get_array(start => $start_time, end => $end_time);

with the times in epoch seconds.

=head3 get_hash()

 my $href = $dst->get_hash();

 while (my($time, $val) = each %$href) {
    ...
 }

Returns all values as a hash.

Optionally specify either a start or end time with:

 $href = $dst->get_hash(start => $start_time, end => $end_time);

May return a reference to an internal copy of the data, so make
a copy before directly modifying any of the values.

=head2 DEFAULT URL

The default base url for obtaining near real time Dst values is:

 http://swdcdb.kugi.kyoto-u.ac.jp/dstdir/dst1/q/

The default files fetched are:

 Dstqthism.html
 Dstqlastm.html

=head1 AUTHOR

Alex Gough, alex@earth.li.

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
