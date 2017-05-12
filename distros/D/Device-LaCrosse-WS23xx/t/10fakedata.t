# -*- perl -*-
#
#
use strict;
use Test::More;

my $loaded = 0;

our $mmap;
our @fakedata;
our @sample_data;
our @canonicalize_tests;

BEGIN {
    # Read the memory map file; get tests from there.  This will
    # make sure that we're interpreting data correctly.
    $mmap = 'memory_map_2300.txt';
    open my $map_fh, '<', $mmap or die "Cannot read $mmap: $!";

    while (my $line = <$map_fh>) {
	chomp $line;
	$line =~ s/\s+$//;			# Remove trailing whitespace

	# E.g. 0019 0   alarm set flags
	if ($line =~ s!^([0-9a-f]{4})\s+([0-9a-f])\s*!!i) {
	    $fakedata[hex($1)] = hex($2);

	    if ($line =~ m!^\|\s+([^ 0-9].*?)\s*:\s*(.*)!) {
		my ($desc, $formula) = ($1, $2);
		if ($formula =~ /\(=(.*)\)$/) {
		    push @sample_data, [ $desc, $1 ];
		}
	    }
	}
    }
    close $map_fh;

    # Create some hardcoded tests.  This requires knowledge of
    # the sample data values in the memory map file.  These
    # tests aren't completely duplicates of the above.  These
    # tests use nonstandard field names, so we're actually
    # testing the canonicalize() function.
    my $canonicalize = <<'END_CANONICALIZE_TESTS';
Outdoor_Temp                    7.4
LCD_Contrast                    5
Max_Dewpoint                    8.44
Min_Outdoor_Temp_datetime       2003-04-17.06:25:00
Min_Out_temp_datetime           2003-04-17.06:25:00
END_CANONICALIZE_TESTS

    for my $line (split "\n", $canonicalize) {
	$line =~ /^(\S.*\S)\s+(\S+)$/
	  or die "Internal error: cannot grok test '$line'";
	push @canonicalize_tests, { field => $1, expect => $2 };
    }

    plan tests => 2 + @sample_data + @canonicalize_tests;
}
END { $loaded or print "not ok 1\n"; }

use Device::LaCrosse::WS23xx;

$loaded = 1;

# Note that this uses the ::Fake subclass, which does not
# actually talk to a weather station device!
my $ws = Device::LaCrosse::WS23xx->new($mmap);

my @got_data = $ws->_read_data(0, scalar(@fakedata));
is_deeply \@got_data, \@fakedata, "array contents";

# Test the tied interface.  @WS is a magical object that maps
# the WS-23xx device memory into a perl list.
tie my @WS, 'Device::LaCrosse::WS23xx', $ws
    or die "Cannot tie";
is_deeply \@WS, \@fakedata, "tie";

for my $r (@sample_data) {
    my ($field, $expect) = @$r;

    my $got = $ws->get($field);
    if ($field =~ /date.*time/i) {
	my @lt = localtime($got);
	$got = sprintf("%04d-%02d-%02d %02d:%02d",
		       $lt[5]+1900, $lt[4]+1, @lt[3,2,1]);
    }

    # ARGH! Compensate for IEEE floating point arithmetic.  We put $got
    # into the same scale as $expect.
    # This is necessary because Air Pressure Correction is 10022/10.0-1000
    # which ends up as 2.20000000000005, which != 2.2
    if ($expect =~ /\.(\d+)$/) {
	$got = sprintf("%.*f", length($1), $got);
    }

    is $got, $expect, "$field = $expect";
}

for my $t (@canonicalize_tests) {
    my $field = $t->{field};
    my $expect = $t->{expect};

    my $got = $ws->get($field);

    # Is this a datetime field?  Since $ws->get() invokes timelocal(),
    # we need to convert back to localtime().
    if ($field =~ /datetime/) {
	my @t = CORE::localtime($got);
	$got = sprintf("%d-%02d-%02d.%02d:%02d:%02d",
		       $t[5]+1900, $t[4]+1, $t[3], @t[2,1,0]);
    }

    is $got, $expect, "[canonicalize] $field";
}
