use Test::More tests => 2;

BEGIN {
   use_ok('Dist::Zilla::Plugin::CustomLicense');
   use_ok('Software::License::Custom');
}

diag("Testing Dist::Zilla::Plugin::CustomLicense $Dist::Zilla::Plugin::CustomLicense::VERSION");
