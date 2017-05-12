#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use JSON::Repair 'repair_json';
my $bad_json = <<EOF;
{'very bad':0123,
 "
naughty":'json',
value: 00000.00001,
}
// garbage
EOF
print repair_json ($bad_json);
