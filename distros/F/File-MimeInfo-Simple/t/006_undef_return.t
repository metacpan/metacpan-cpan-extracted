use strict;
use warnings;

use Test::More tests => 3;
use File::MimeInfo::Simple;

# Test that unknown extensions return undef instead of empty string
my $lookup = \&File::MimeInfo::Simple::_find_mimetype_by_table;

# Test 1: Unknown extension returns undef
my $result1 = $lookup->('file.unknownext12345');
is($result1, undef, 'unknown extension returns undef');

# Test 2: No extension returns undef
my $result2 = $lookup->('noextension');
is($result2, undef, 'no extension returns undef');

# Test 3: Can distinguish undef from empty string
ok(!defined($lookup->('file.zzzznotreal')), 'result is truly undef, not empty string');

