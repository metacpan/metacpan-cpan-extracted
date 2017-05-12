#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Dist::Zilla::PluginBundle::IDOPEREL' ) || print "Bail out PluginBundle!\n";
	use_ok( 'Dist::Zilla::MintingProfile::IDOPEREL' ) || print "Bail out MintingProfile!\n";
}

diag( "Testing Dist::Zilla::PluginBundle::IDOPEREL $Dist::Zilla::PluginBundle::IDOPEREL::VERSION, Perl $], $^X" );
diag( "Testing Dist::Zilla::MintingProfile::IDOPEREL $Dist::Zilla::MintingProfile::IDOPEREL::VERSION, Perl $], $^X" );
