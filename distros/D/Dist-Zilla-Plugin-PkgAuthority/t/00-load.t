use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Dist::Zilla::Plugin::PkgAuthority') || print "Bail out!\n"; }
diag( "Testing Dist::Zilla::Plugin::PkgAuthority $Dist::Zilla::Plugin::PkgAuthority::VERSION, Perl $], $^X" );
