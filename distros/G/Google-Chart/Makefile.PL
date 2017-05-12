use strict;
use inc::Module::Install;

my $have_previous = eval {
    require Google::Chart;
    $Google::Chart::VERSION < 0.05000;
};

if ($have_previous) {
    my $y_n = prompt(<<EOM, "n");

You seem to have an old version of Google::Chart installed.
As this version of Google::Chart breaks a lot of backwards compatibility,
installing this *WILL* break your code if you have something that depends on it.

Are you sure you want to continue? [y/N]
EOM
    if ($y_n !~ /^y(?:es)?$/i) {
        exit 0;
    }
}

name 'Google-Chart';

all_from('lib/Google/Chart.pm');

requires 'LWP::UserAgent';
requires 'Moose', '0.54';
requires 'Class::MOP', '0.63';
requires 'URI';
requires 'URI::Escape';
requires 'Scalar::Util';

test_requires 'Test::More' => '0.82';
test_requires 'Test::UseAllModules';

auto_include_deps;
WriteAll;
