#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'Test::CPAN::Changes' => '0.4' };

Test::CPAN::Changes->import();

# Every release needs a valid ISO-8601 date and version; a pending release
# may say "Not Released" until it is uploaded
changes_file_ok('Changes');

done_testing();
