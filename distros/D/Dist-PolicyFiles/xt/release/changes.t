use 5.010;
use strict;
use warnings;
use Test::More;

use Test::Changes::Strict::Simple -empty_line_after_version => 1;

use Dist::PolicyFiles;

plan skip_all => 'Release and "additional" tests only'
  unless $ENV{RELEASE_TESTING} && $ENV{RELEASE_TEST_ADDN};
plan tests => 1;

changes_strict_ok(module_version => $Dist::PolicyFiles::VERSION,
                  $ENV{RELEASE_TEST_ADDN} ? (release_today  => 1) : ()
                 );
