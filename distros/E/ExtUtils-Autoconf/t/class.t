#!perl

use strict;
use warnings;
use Symbol qw(gensym);
use File::Which qw(which);
use Test::More tests => 21;
use Test::Exception;
use ExtUtils::Autoconf;

{
    local @ARGV = ('t/autoconf', (which('autoconf'))[0], (which('autoheader'))[0]);

    lives_ok(sub {
            ExtUtils::Autoconf->run_autogen;
    }, 'run_autogen');

    ok( -f 't/autoconf/config.h.in', 'config.h.in exists' );
    ok( -f 't/autoconf/configure', 'configure exists' );

    lives_ok(sub {
            ExtUtils::Autoconf->run_configure;
    }, 'configure');

    ok( -f 't/autoconf/config.h', 'config.h exists' );

    {
        my $conf = gensym();
        ok( open($conf, '<t/autoconf/config.h'), 'opened config.h' );
        like( do { local $/ = undef; <$conf>; }, qr/#define PERL_OSNAME "$^O"/, 'config.h has PERL_OSNAME set correctly' );
        close $conf;
    }

    SKIP: {
        skip 'Skipped cleanup tests when debugging', 13 if $ENV{TEST_DEBUG};

        lives_ok(sub {
                ExtUtils::Autoconf->run_clean;
        }, 'clean');

        ok(  -f 't/autoconf/configure.ac', 'configure.ac still exists' );
        ok(  -f 't/autoconf/configure', 'configure still exists' );
        ok(  -f 't/autoconf/config.h.in', 'config.h.in still exists' );
        ok(  -d 't/autoconf/autom4te.cache', 'autom4te.cache still exists' );
        ok( !-f 't/autoconf/config.h', 'config.h deleted' );
        ok( !-f 't/autoconf/config.log', 'config.log deleted' );
        ok( !-f 't/autoconf/config.status', 'config.status deleted' );

        lives_ok(sub {
                ExtUtils::Autoconf->run_realclean;
        }, 'realclean');

        ok(  -f 't/autoconf/configure.ac', 'configure.ac still exists' );
        ok( !-f 't/autoconf/configure', 'configure deleted' );
        ok( !-f 't/autoconf/config.h.in', 'config.h.in deleted' );
        ok( !-d 't/autoconf/autom4te.cache', 'autom4te.cache deleted' );
    }
}

{
    local @ARGV = ();

    dies_ok(sub {
            ExtUtils::Autoconf->run_configure;
    }, 'configure fails with invalid wd');
}
