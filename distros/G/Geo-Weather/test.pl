# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Geo::Weather;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

$weather = new Geo::Weather;
$weather->{timeout} = 10;
$weather->{debug} = 2; # Adjust debug level

print "Enter city of location you are at: ";
my $city = <STDIN>;
chomp($city);

print "Enter state of location you are at: ";
my $state = <STDIN>;
chomp($state);

print "Proxy (just press enter if no proxy): ";
my $proxy = <STDIN>;
chomp($proxy);
$weather->{proxy} = $proxy;

if ($proxy) {
	unless ($ENV{HTTP_PROXY_USER}) {
		print "Proxy Username: ";
		my $proxy_user = <STDIN>;
		chomp($proxy_user);
		$weather->{proxy_user} = $proxy_user;
	}

	unless ($ENV{HTTP_PROXY_PASS}) {
		print "Proxy Password: ";
		my $proxy_pass = <STDIN>;
		chomp($proxy_pass);
		$weather->{proxy_pass} = $proxy_pass;
	}
}


print "Attempting to connect to weather.com...\n\n";

my $condition = $weather->get_weather($city, $state);

if (ref $condition) {
	print "Current Conditions for $condition->{city}, $condition->{state}:\n\n";
	print " Condition: $condition->{cond}\n";
	print " Condition Image: $condition->{pic}\n";
	print " Temp: $condition->{temp} F\n";
	print " Temp: $condition->{temp_c} C\n";
	print " Wind: $condition->{wind}\n";
	print " Heat Index: $condition->{heat} F\n";
	print " Visability: $condition->{visb}\n";
	print " Barometer: $condition->{baro}\n\n";
	print "If the above results are correct, your Geo::Weather installation is functioning normally\n";
	print "ok 2\n";
} else {
	print "Error: $condition\n";
	print "not ok 2\n";
}
