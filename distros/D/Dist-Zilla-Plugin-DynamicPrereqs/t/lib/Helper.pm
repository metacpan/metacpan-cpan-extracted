use strict;
use warnings;

use Test::More ();
use Test::Fatal ();
use Path::Tiny ();
use File::pushd ();
use Capture::Tiny ();
use Config;

# Microsoft nmake outputs a copyright message that
# messes up the output checks, but we can work around
# this by setting the -nologo option using MAKEFLAGS
$ENV{MAKEFLAGS} = join(' ', 'nologo', ($ENV{MAKEFLAGS} // ())) if $Config{make} eq 'nmake';

sub run_makemaker {
    my $tzil = shift;

    my $exception;
    my ($stdout, $stderr, @rest) = Capture::Tiny::capture { $exception =
        Test::Fatal::exception {
            my $wd = File::pushd::pushd(Path::Tiny::path($tzil->tempdir)->child('build'));
            $tzil->plugin_named('MakeMaker')->build;
        }
    };
    Test::More::note($stdout) if defined $stdout;
    Test::More::is($exception, undef, 'generated Makefile.PL has no compiler errors')
        or diag $stderr;
    Test::More::is($stderr, '', 'running Makefile.PL did not produce warnings');
    return !$exception;
}

1;
