use strict;
use warnings;
use Test::More tests => 1;
use Pod::Checker;
my $errors = podchecker('lib/HTML/Anchor/Audit.pm');
is($errors, 0, 'POD documentation validates');
