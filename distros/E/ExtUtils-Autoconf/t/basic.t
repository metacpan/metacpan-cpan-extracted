#!perl

use strict;
use warnings;
use Symbol qw(gensym);
use Test::More tests => 50;
use Test::Exception;
use ExtUtils::Autoconf;

{
    my $ac = ExtUtils::Autoconf->new({
            wd => 't/autoconf',
    });
    isa_ok( $ac, 'ExtUtils::Autoconf' );

    lives_ok(sub {
            $ac->autogen;
    }, 'autogen');

    ok( -f 't/autoconf/config.h.in', 'config.h.in exists' );
    ok( -f 't/autoconf/configure', 'configure exists' );

    lives_ok(sub {
            $ac->configure;
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
                $ac->clean;
        }, 'clean');

        ok(  -f 't/autoconf/configure.ac', 'configure.ac still exists' );
        ok(  -f 't/autoconf/configure', 'configure still exists' );
        ok(  -f 't/autoconf/config.h.in', 'config.h.in still exists' );
        ok(  -d 't/autoconf/autom4te.cache', 'autom4te.cache still exists' );
        ok( !-f 't/autoconf/config.h', 'config.h deleted' );
        ok( !-f 't/autoconf/config.log', 'config.log deleted' );
        ok( !-f 't/autoconf/config.status', 'config.status deleted' );

        lives_ok(sub {
                $ac->realclean;
        }, 'realclean');

        ok(  -f 't/autoconf/configure.ac', 'configure.ac still exists' );
        ok( !-f 't/autoconf/configure', 'configure deleted' );
        ok( !-f 't/autoconf/config.h.in', 'config.h.in deleted' );
        ok( !-d 't/autoconf/autom4te.cache', 'autom4te.cache deleted' );
    }
}

{
    my $ac;
    lives_ok(sub {
        $ac = ExtUtils::Autoconf->new([]);
    }, 'new doesn\'t croak on a non-HASH reference');

    isa_ok( $ac, 'ExtUtils::Autoconf' );
}

{
    my $ac = ExtUtils::Autoconf->new({
            env => {
                foo => 'bar',
            },
            wd => 'some/dir',
    });
    isa_ok( $ac, 'ExtUtils::Autoconf' );

    is( $ac->env('foo'), 'bar', 'setting hash attribute via new() works' );
    is( $ac->wd, 'some/dir', 'setting scalar attribute via new() works' );
}

{
    my $ac;
    lives_ok(sub {
            $ac = ExtUtils::Autoconf->new({
                    does_not_exist => {
                        foo => 'bar',
                    },
            });
    }, 'new does not croak on unknown attributes');

    isa_ok( $ac, 'ExtUtils::Autoconf' );
}

{
    my $ac;
    lives_ok(sub {
            $ac = ExtUtils::Autoconf->new({
                env => [],
            });
    }, 'new does not croak on invalid value for existing attribute');

    isa_ok( $ac, 'ExtUtils::Autoconf' );
}

{
    local %ENV = %ENV;
    $ENV{PATH} = '';

    my $ac = ExtUtils::Autoconf->new;
    isa_ok( $ac, 'ExtUtils::Autoconf' );

    is( $ac->autoheader, 'autoheader', 'autoheader attribute defaults to \'autoheader\' if nothing was found in PATH' );
    is( $ac->autoconf,   'autoconf',   'autoconf attribute defaults to \'autoconf\' if nothing was found in PATH' );
}

{
    my $ac = ExtUtils::Autoconf->new({
            wd => 't/autoconf',
    });
    isa_ok( $ac, 'ExtUtils::Autoconf' );

    lives_ok(sub {
            $ac->configure;
    }, 'configure succeeds even if autogen() didn\'t run before');

    ok( -f 't/autoconf/config.h.in', 'config.h.in exists' );
    ok( -f 't/autoconf/configure', 'configure exists' );
    ok( -f 't/autoconf/config.h', 'config.h exists' );

    lives_ok(sub {
            $ac->realclean;
    }, 'realclean');
}

{
    my $ac = ExtUtils::Autoconf->new({
            wd => 't/autoconf_bad_configure',
    });
    isa_ok( $ac, 'ExtUtils::Autoconf' );

    dies_ok(sub {
            $ac->configure;
    }, 'dies with invalid configure.ac');

    lives_ok(sub {
            $ac->realclean;
    }, 'realclean');
}

{
    my $ac = ExtUtils::Autoconf->new({
            wd => 't/autoconf_bad_autoheader',
    });
    isa_ok( $ac, 'ExtUtils::Autoconf' );

    dies_ok(sub {
            $ac->configure;
    }, 'dies with invalid configure.ac');

    lives_ok(sub {
            $ac->realclean;
    }, 'realclean');
}

{
    my $ac = ExtUtils::Autoconf->new({
            wd => 't/autoconf',
            autoconf => 'exit foo',
    });
    isa_ok( $ac, 'ExtUtils::Autoconf' );

    dies_ok(sub {
            $ac->autogen;
    }, 'dies with invalid configure.ac');

    lives_ok(sub {
            $ac->realclean;
    }, 'realclean');
}

{
    my $ac = ExtUtils::Autoconf->new({
            wd => 'does/not/exist',
    });
    isa_ok( $ac, 'ExtUtils::Autoconf' );

    dies_ok(sub {
            $ac->configure;
    }, 'dies with non-existent path');
}
