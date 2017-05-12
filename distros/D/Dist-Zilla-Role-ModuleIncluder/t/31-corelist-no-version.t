use strict;
use warnings;
# vim: ts=4 sts=0 sw=0 noet

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny 0.062;
use Test::Fatal;

use lib path('t/lib')->absolute->stringify;

my $tzil = Builder->from_config(
	{ dist_root => 'does-not-exist' },
	{
		add_files => {
			path(qw(source dist.ini)) => simple_ini(
				[ GatherDir => ],
				[ ModuleIncluder => {
						module => [ 'UsesConfig' ],
						background_perl => '5.006001',
					},
				],
			),
			path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
		},
	},
);

$tzil->chrome->logger->set_debug(1);
is(
	exception { $tzil->build },
	undef,
	'build proceeds normally',
) or diag 'got log messages: ', explain $tzil->log_messages;

my $build_dir = path($tzil->tempdir)->child('build');

my $inc_dir = $build_dir->child('inc');
my @inc_files;
$inc_dir->visit(
	sub { push @inc_files, $_->relative($build_dir)->stringify if -f },
	{ recurse => 1 },
);

is(@inc_files, 1, 'module has a prereq that is in core - nothing extra added to inc')
	or diag 'files added to inc: ', explain \@inc_files;

diag 'saw log messages: ', explain($tzil->log_messages)
	if not Test::Builder->new->is_passing;

done_testing;
