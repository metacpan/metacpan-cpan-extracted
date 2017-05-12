#
#===============================================================================
#
#         FILE:  001-VersionFromScript.t
#
#     ABSTRACT:  test script
#
#       AUTHOR:  Reid Augustin (REID), <reid@lucidport.com>
#      COMPANY:  LucidPort Technology, Inc.
#      VERSION:  1.0
#      CREATED:  12/02/2010 09:34:28 AM PST
#===============================================================================

use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

BEGIN { use_ok('Dist::Zilla::Plugin::VersionFromScript') };

# apparently we need some other support structure for this to work.

#my $test = Dist::Zilla::Plugin::VersionFromScript->new(script => 'echo 321');
#isa_ok($test, 'Dist::Zilla::Plugin::VersionFromScript', 'created');

#is ($test->provide_version, '321', 'works');


