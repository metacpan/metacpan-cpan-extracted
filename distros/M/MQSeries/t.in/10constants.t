#
# $Id: 10constants.t,v 33.9 2012/09/26 16:15:32 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

BEGIN {
    require "../util/parse_config";
    require "../util/parse_headers";
}

print("1..",
      scalar(keys %constant_null) +
      scalar(keys %constant_hex) +
      scalar(keys %constant_numeric) +
      scalar(keys %constant_string) +
      scalar(keys %constant_char) + 1,
      "\n");

END {print "not ok 1\n" unless $loaded;}
use __APITYPE__::MQSeries 1.34;
$loaded = 1;
print "ok 1\n";

$counter = 2;

foreach my $constant (
		      keys %constant_null,
		      keys %constant_hex,
		      keys %constant_numeric,
		      keys %constant_string,
		      keys %constant_char
		     ) {

    my $value = undef;
    $value = eval "&\$constant";

    #
    # Debugging output
    #
    print "Constant '$constant':\n\tis ";

    if ( exists $constant_null{$constant} ) {
	if ( defined($value) ) {
	    if ( $value =~ /^\0+$/ ) {
		print length($value) . " NULL chars";
	    } else {
		print "'$value'";
	    }
	} else {
	    print "undefined";
	}
    } else {
	print(defined($value) ? "'$value'" : "undefined")
    }

    print "\n\tshould be ";

    if ( exists $constant_null{$constant} ) {
	print "$constant_null{$constant} NULL chars\n";
	print "not " unless defined($value) && length($value) == $constant_null{$constant};
    } elsif ( exists $constant_hex{$constant} ) {
	print "'$constant_hex{$constant}'\n";
	print "not " unless defined($value) && $value == $constant_hex{$constant};
    } elsif ( exists $constant_numeric{$constant} ) {
	print "'$constant_numeric{$constant}'\n";
	print "not " unless defined($value) && $value == $constant_numeric{$constant};
    } elsif ( exists $constant_string{$constant} ) {
	print "'$constant_string{$constant}'\n";
	print "not " unless defined($value) && $value eq $constant_string{$constant};
    } else {
	print "'$constant_char{$constant}'\n";
	print "not " unless defined($value) && $value eq $constant_char{$constant};
    }

    print "ok $counter\n";

    $counter++;

}

