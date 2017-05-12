## no critic (RequireVersion RequireExplicitPackage RequireCheckingReturnValueOfEval ProhibitStringyEval)
############################################################################
# A simple HTML meta tag "robots" generator.
# @copyright © 2013, BURNERSK. Some rights reserved.
# @license http://www.perlfoundation.org/artistic_license_2_0 Artistic License 2.0
# @author BURNERSK <burnersk@cpan.org>
############################################################################
# Perl pragmas.
use strict;
use warnings FATAL => 'all';
use utf8;

############################################################################
use Test::More;
plan skip_all => "Release tests are not enabled" if !$ENV{RELEASE_TESTING};

############################################################################
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD" if $@;
all_pod_coverage_ok();
done_testing();
