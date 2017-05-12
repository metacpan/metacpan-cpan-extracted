use strict;
use warnings;
use inc::Module::Install;

name 'Math-Rational-Approx';
repository {
    url => 'https://bitbucket.org/djerius/math-rational-approx',
    web => 'https://bitbucket.org/djerius/math-rational-approx',
    type => 'hg',
};

license 'gpl3';
all_from 'lib/Math/Rational/Approx.pm';

author_tests( 'xt' );

auto_set_bugtracker;
auto_license( holder => 'Smithsonian Astrophysical Observatory' );

requires 'Math::BigFloat';

requires 'Moo';
requires 'MooX::Types::MooseLike::Numeric';
requires 'POSIX';
requires 'Params::Validate';

author_requires 'Test::Pod';
author_requires 'Test::Pod::Coverage';
author_requires 'Test::Perl::Critic';
author_requires 'Module::Install::AutoLicense';
author_requires 'Module::Install::AuthorTests';
author_requires 'Module::Install::AuthorRequires';
author_requires 'Module::Install::Bugtracker';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Math::Trig';

auto_install;

WriteAll;
