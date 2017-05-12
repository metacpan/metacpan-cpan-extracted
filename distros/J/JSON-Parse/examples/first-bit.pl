#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Parse 'assert_valid_json';
my $json = <<EOF;
   [
      {
         "precision": "zip",
         "Latitude":  37.7668,
         "Longitude": -122.3959,
         "Address":   "",
         "City":      "SAN FRANCISCO",
         "State":     "CA",
         "Zip":       "94107",
         "Country":   "US"
      },
      {
         "precision": "zip",
         "Latitude":  37.371991,
         "Longitude": -122.026020,
         "Address":   "",
         "City":      "SUNNYVALE",
         "State":     "CA",
         "Zip":       "94085",
         "Country":   "US"
      }
   ]
EOF
my $half = substr ($json, 0, length ($json)/2);
eval {
    assert_valid_json ($half);
};
if (! $@ || $@ =~ /unexpected end/i) {
    print "The first half of the JSON is valid.\n";
}
