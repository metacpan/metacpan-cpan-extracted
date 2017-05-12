#! /usr/bin/perl

use strict;
use warnings;

use Ganglia::Gmetric::PP ':all';
use Getopt::Long;

sub usage {
    (my $me = $0) =~ s,.*/,,;
    my $error = shift;
    print "Error: $error\n\n" if $error;
    print <<EOD;
$me $Ganglia::Gmetric::PP::VERSION

Usage: $me [OPTIONS]...

  -h, --help          Print help and exit
  -n, --name=STRING   Name of the metric
  -v, --value=STRING  Value of the metric
  -t, --type=STRING   Either
                        string|int8|uint8|int16|uint16|int32|uint32|float|double
  -u, --units=STRING  Unit of measure for the value e.g. Kilobytes, Celcius
                        (default=`')
  -s, --slope=STRING  Either zero|positive|negative|both  (default=`both')
  -x, --tmax=INT      The maximum time in seconds between gmetric calls
                        (default=`60')
  -d, --dmax=INT      The lifetime in seconds of this metric  (default=`0')
  -H, --host=STRING   Host where gmond is listening  (default=`localhost')
  -p, --port=INT      UDP port where gmond is listening  (default=`8649')
EOD

    exit 1;
}

GetOptions(
    'n|name=s'  => \(my $name),
    'v|value=s' => \(my $value),
    't|type=s'  => \(my $type),
    'u|units=s' => \(my $units = ''),
    's|slope=s' => \(my $slope = 'both'),
    'x|tmax=i'  => \(my $tmax  = 60),
    'd|dmax=i'  => \(my $dmax  = 0),
    'H|host=s'  => \(my $host  = 'localhost'),
    'p|port=i'  => \(my $port  = 8649),
    'h|help!'   => \(my $help),
);

my %types = map { $_ => 1 }
    GANGLIA_VALUE_STRING,
    GANGLIA_VALUE_CHAR,  GANGLIA_VALUE_UNSIGNED_CHAR,
    GANGLIA_VALUE_SHORT, GANGLIA_VALUE_UNSIGNED_SHORT,
    GANGLIA_VALUE_INT,   GANGLIA_VALUE_UNSIGNED_INT,
    GANGLIA_VALUE_FLOAT, GANGLIA_VALUE_DOUBLE;

my %slopes = (
    zero        => GANGLIA_SLOPE_ZERO,
    positive    => GANGLIA_SLOPE_POSITIVE,
    negative    => GANGLIA_SLOPE_NEGATIVE,
    both        => GANGLIA_SLOPE_BOTH,
);

usage if $help;
usage('--name required')  unless defined $name;
usage('--value required') unless defined $value;
usage('--type required')  unless defined $type;
usage("invalid type '$type'")     unless exists $types{$type};
usage('invalid slope')    unless exists $slopes{$slope};

$slope = $slopes{$slope};

my $gmetric = Ganglia::Gmetric::PP->new(host => $host, port => $port);
$gmetric->send($type, $name, $value, $units, $slope, $tmax, $dmax);
