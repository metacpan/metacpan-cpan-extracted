use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Memory process reporting.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Memory-Process';
readme_from 'Process.pm';
recursive_author_tests('xt');
requires 'Memory::Usage' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Memory-Process';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Memory-Process';
resources 'repository' => 'git://github.com/michal-josef-spacek/Memory-Process';
test_requires 'Capture::Tiny' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.06';

if ($^O eq 'freebsd' || $^O eq 'MSWin32' || $^O eq 'openbsd' || $^O eq 'solaris'
	|| $^O eq 'darwin') {

	die "System '$^O' doesn't supported.";
}

# Run.
WriteAll();
