## no critic (RequireVersion RequireExplicitPackage)
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
# Get use of modules.
use Test::More tests => 2;
use Test::NoWarnings;

############################################################################
# Tests for module inclusion.
BEGIN { use_ok('HTML::Meta::Robots'); }

############################################################################
1;
