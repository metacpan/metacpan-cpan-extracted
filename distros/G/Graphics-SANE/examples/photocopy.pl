#use ExtUtils::testlib;
use Graphics::SANE;
use Data::Dumper;
use File::Temp qw(tempfile);
use strict;
use warnings;

# initialize sane
my $i = Graphics::SANE::init;			 # returns version hash

# get a list of devices
my @l = Graphics::SANE::get_devices;

if (!@l) {
    print "No devices!\n";
    exit;
}

my $dev;
if (@l > 1) {
    my $i = 0;
    print("$i) $l[$i]{model} ($l[$i]{name})\n"),$i++ for @l;
    print "Device index: ";
    my $idx = <>;
    chomp $idx;
    $dev = $l[$idx];
} else {
    $dev = $l[0];
}

# open a device
my $h = Graphics::SANE::open($dev->{name});
if (!$h) {
    print "Open error: $Graphics::SANE::errstr" . $/;
    die "Can't open device $dev->{name}";
}

# determine how many options
my $n = $h->get_option_value(0);
my %values = ( 'resolution' => 150,
	       'mode' => 'Lineart',
	       'tl-x' => 0,
	       'tl-y' => 0,
	       'br-x' => 216,
	       'br-y' => 297,
	       @ARGV );

# retrieve options
for my $o (1..$n-1) {
    my $opt = $h->get_option_descriptor($o);
    next if $opt->{inactive};
    next unless $opt->{title};
    next if $opt->{type} eq "group";
    # display option value and constraints
    if ( exists $values{$opt->{name}} ) {
	my $val = $values{$opt->{name}};
	my $v = $h->get_option_value($opt->{index});
	if ($val ne $v) {
	    my $s = $h->set_option_value($opt->{index},$val);
	    if (!$s) {
		print "status: $Graphics::SANE::errstr" . $/;
		die "Unable to set option $opt->{name} to $val";
	    }
	}
    }
}

# start scanning
if (!$h->start) {
    print "status = $Graphics::SANE::errstr",$/;
    die "Error starting scan";
}

# retrieve scan parameters
my $p = $h->get_parameters;

# write data to a pnm file
my ($f,$t);
if ($p->{depth} == 1) {
    $f = 4;
    $t = '.pbm';
} elsif ($p->{format} eq 'gray') {
    $f = 5;
    $t = '.pgm';
} elsif ($p->{format} eq 'rgb') {
    $f = 6;
    $t = '.ppm';
} else {
    print "Multi-frame format not yet supported\n";
    exit(2);
}
my ($fh, $fnm) = tempfile('pcopyXXXX', SUFFIX=>$t, UNLINK=>0);
print $fh "P$f\n";
print $fh $p->{pixels_per_line}," ",$p->{lines},$/;
print $fh "255\n" if $f > 4;
my $sts;
while ($b = $h->read($p->{bytes_per_line})) {
    print $fh $b;
}
print "status = $Graphics::SANE::errstr\n"
    unless $Graphics::SANE::err == Graphics::SANE::SANE_STATUS_EOF;
close $fh;

# spool to printer
system("pnmtopclxl -dpi $values{resolution} -center -format letter " .
       "-rendergray $fnm | " .
       "lp -d Brother -t 'photocopy'");
unlink $fnm;

# finish scanning
$h->cancel;

# close the scanner
$h->close;

# finish with the library
Graphics::SANE::exit;
