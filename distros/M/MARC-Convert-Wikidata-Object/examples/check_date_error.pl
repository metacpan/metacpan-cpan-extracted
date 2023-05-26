#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use MARC::Convert::Wikidata::Object::Utils qw(check_date);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'foo',
};
check_date($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [..Utils.pm:?] Parameter 'key' is in bad format.