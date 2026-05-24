use v5.36;
use utf8;
use lib qw(blib/lib lib);

use Test::More 1.0;

use Cwd qw(getcwd);
use File::Basename;
use File::Spec::Functions qw(catfile);

my $class = 'File::FindRoot';
my $method = 'dir_contains';

=encoding utf8

=head1 NAME

t/findroot.t - the meat of the tests

=head1 SYNOPSIS

Run all the tests:

	prove t

Run just this test:

	perl t/findroot.t

=head1 DESCRIPTION

Most of the tests for the functional parts of L<File::FindRoot>.

=cut

local $ENV{'FILE_FINDROOT_DEBUG'};

subtest sanity => sub {
	use_ok $class;
	can_ok $class, $method;
	};

subtest 'bad calls' => sub {
	subtest 'bad options argument' => sub {
		open my $cfh, '>', \my $warnings;
		local *STDERR = $cfh;
		is length($warnings) + 0, 0, "warnings starts empty";

		my $items = () = $class->$method( 'file', [] );
		is $items, 0, "returns empty list for bad options";
		cmp_ok length $warnings, '>', 0, 'there is a warning';
		like $warnings, qr/must be a hash reference/;
		};

	subtest 'bad callback argument' => sub {
		open my $cfh, '>', \my $warnings;
		local *STDERR = $cfh;
		is length($warnings) + 0, 0, "warnings starts empty";

		my $items = () = $class->$method( 'file', { callback => 'gggg' } );
		is $items, 0, "returns empty list for bad options";
		cmp_ok length $warnings, '>', 0, 'there is a warning';
		like $warnings, qr/not a subroutine reference/;
		};

	subtest 'start_at does not exist' => sub {
		open my $cfh, '>', \my $warnings;
		local *STDERR = $cfh;
		is length($warnings) + 0, 0, "warnings starts empty";

		my $start_at = File::Spec->catfile( $$, qw(a b c d e f) );
		ok ! -e $start_at, 'start_at does not exist (good)' or return;

		my $items = () = $class->$method( 'file', { start_at => $start_at } );
		is $items, 0, "returns empty list for bad options";
		cmp_ok length $warnings, '>', 0, 'there is a warning';
		like $warnings, qr/does not exist/;
		};

	subtest 'limit is less than zero' => sub {
		open my $cfh, '>', \my $warnings;
		local *STDERR = $cfh;
		is length($warnings) + 0, 0, "warnings starts empty";

		my $items = () = $class->$method( '.git', { limit => -1 } );
		is $items, 0, "returns empty list for limit";
		cmp_ok length $warnings, '>', 0, 'there is a warning';
		like $warnings, qr/less than zero/;
		};
	};

subtest 'good runs' => sub {
	my $expected = getcwd;
	if( basename($expected) eq 't' ) {
		diag "It looks like your are running this inside the t directory";
		$expected = dirname($expected);
		}
	ok -e $expected, 'expected directory exists';

	subtest 'default top of repo' => sub {
		foreach my $file ( qw(Makefile.PL t lib) ) {
			is $class->$method($file), $expected, "Found $file in $expected";
			}
		};

	subtest 'start from test name' => sub {
		foreach my $file ( qw(Makefile.PL t lib) ) {
			is $class->$method($file, { start_at => __FILE__ }), $expected, "Found $file in $expected";
			}
		};

	subtest 'start from test name, with .., .' => sub {
		foreach my $file ( qw(Makefile.PL t lib) ) {
			is $class->$method($file, {
				start_at   => catfile($expected, 't', '..', 't', '.', '..', 't'),
				}), $expected, "Found $file in $expected";
			}
		};
	};

subtest 'unsuccessful runs' => sub {
	open my $cfh, '>:utf8', \my $carped;

	subtest 'starting dir does not exist' => sub {
		$carped = '';
		local *STDERR = $cfh;

		my $start_at = catfile( qw(foo bar baz a x t 0 1), $$, time );
		ok ! -e $start_at, 'starting directory does not exist (good)';
		my $rc = $class->$method('.git', { start_at => $start_at } );
		ok ! defined $rc, 'returns empty list for missing starting directory';
		like $carped, qr/does not exist/, 'got expected carp message';
		};

	subtest 'target does not exist' => sub {
		my $items = () = $class->$method('.gitabcdefe');
		is $items, 0, 'returns empty list for missing target';
		};
	};

subtest 'debug' => sub {
	open my $dfh, '>:utf8', \my $debug;

	subtest 'off' => sub {
		subtest 'implicit' => sub {
			$debug = '';
			local $ENV{'FILE_FINDROOT_DEBUG'};
			local *STDERR = $dfh;
			is length($debug), 0, 'string starts as empty';
			my $dir = $class->$method( 'Makefile.PL' );
			is length $debug, 0, 'there is nothing in debug fh';
			};

		subtest 'implicit' => sub {
			$debug = '';
			local $ENV{'FILE_FINDROOT_DEBUG'};
			local *STDERR = $dfh;
			is length($debug), 0, 'string starts as empty';
			my $dir = $class->$method( 'Makefile.PL', { debug_fh => undef } );
			is length $debug, 0, 'there is nothing in debug fh';
			};

		subtest 'implicit' => sub {
			$debug = '';
			local $ENV{'FILE_FINDROOT_DEBUG'};
			is length($debug), 0, 'string starts as empty';
			my $dir = $class->$method( 'Makefile.PL', { debug_fh => $dfh } );
			is length $debug, 0, 'there is nothing in debug fh';
			};

		subtest 'implicit, env not set' => sub {
			$debug = '';
			is length($debug), 0, 'string starts as empty';
			local $ENV{'FILE_FINDROOT_DEBUG'} = 0;
			my $dir = $class->$method( 'Makefile.PL', { debug_fh => $dfh } );
			is length $debug, 0, 'there is nothing in debug fh';
			};

		subtest 'implicit, env set' => sub {
			$debug = '';
			is length($debug), 0, 'string starts as empty';
			local $ENV{'FILE_FINDROOT_DEBUG'} = 1;
			my $dir = $class->$method( 'Makefile.PL', { debug_fh => $dfh } );
			cmp_ok length $debug, '>', 0, 'there is something in debug fh';
			};

		subtest 'explicitly off' => sub {
			$debug = '';
			is length($debug), 0, 'string starts as empty';
			local $ENV{'FILE_FINDROOT_DEBUG'};
			my $dir = $class->$method( 'Makefile.PL', { debug => 0, debug_fh => $dfh } );
			is length $debug, 0, 'there is nothing in debug fh';
			};

		subtest 'explicitly off, env off' => sub {
			$debug = '';
			is length($debug), 0, 'string starts as empty';
			local $ENV{'FILE_FINDROOT_DEBUG'} = 0;
			my $dir = $class->$method( 'Makefile.PL', { debug => 0, debug_fh => $dfh } );
			is length $debug, 0, 'there is nothing in debug fh';
			};

		subtest 'explicitly off, env on' => sub {
			$debug = '';
			is length($debug), 0, 'string starts as empty';
			local $ENV{'FILE_FINDROOT_DEBUG'} = 1;
			my $dir = $class->$method( 'Makefile.PL', { debug => 0, debug_fh => $dfh } );
			is length $debug, 0, 'there is nothing in debug fh';
			};
		};

	subtest 'on' => sub {
		subtest 'explicit' => sub {
			$debug = '';
			is length($debug), 0, 'string starts as empty';
			local $ENV{'FILE_FINDROOT_DEBUG'};
			my $dir = $class->$method( 'Makefile.PL', { debug => 1, debug_fh => $dfh } );
			like $debug, qr/\Q$method/, 'there is stuff in debug fh';
			};

		subtest 'explicit, env off' => sub {
			$debug = '';
			is length($debug), 0, 'string starts as empty';
			local $ENV{'FILE_FINDROOT_DEBUG'} = 0;
			my $dir = $class->$method( 'Makefile.PL', { debug => 1, debug_fh => $dfh } );
			like $debug, qr/\Q$method/, 'there is stuff in debug fh';
			};

		subtest 'explicit, env on' => sub {
			$debug = '';
			is length($debug), 0, 'string starts as empty';
			local $ENV{'FILE_FINDROOT_DEBUG'} = 1;
			my $dir = $class->$method( 'Makefile.PL', { debug => 1, debug_fh => $dfh } );
			like $debug, qr/\Q$method/, 'there is stuff in debug fh';
			};
		};
	};

TODO: {
local $TODO = 'HAve not checked Windows yet';

subtest windows => sub {
	pass();
	};
}

done_testing();

=back

=head1 TO DO

=head1 SEE ALSO

=over 4

=back

=cut
