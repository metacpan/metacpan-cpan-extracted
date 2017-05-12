#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Repair 'repair_json';
print repair_json (<<'EOF');
{
  # specify rate in requests/second
  rate: 1000
}
EOF
