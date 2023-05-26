#!/usr/bin/env perl

use strict;
use warnings;

use MARC::Convert::Wikidata::Object::Utils qw(check_date);

my $self = {
        'key' => '2022-01-15',
};
check_date($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok