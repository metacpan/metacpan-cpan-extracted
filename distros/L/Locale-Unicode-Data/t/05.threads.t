#!perl
# Thread safety tests for the $DBH and $STHS package-level caches.
# Skipped entirely when Perl is not compiled with useithreads.
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use utf8;
    use vars qw( $DEBUG );
    use Config;
    use Test::More;
    use version;
    use DBD::SQLite;
    if( version->parse( $DBD::SQLite::sqlite_version ) < version->parse( '3.6.19' ) )
    {
        plan skip_all => 'SQLite driver version 3.6.19 or higher is required. You have version ' . $DBD::SQLite::sqlite_version;
    }
    elsif( !$Config{useithreads} )
    {
        plan( skip_all => "Perl $^V is not compiled with useithreads, skipping thread safety tests" );
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Locale::Unicode::Data' ) || BAIL_OUT( 'Unable to load Locale::Unicode::Data' );
};

use strict;
use warnings;
use utf8;

require threads;

my $NUM_THREADS = 10;

# NOTE: Thread safety: concurrent instantiation
subtest 'Concurrent instantiation' => sub
{
    # Each thread creates its own Locale::Unicode::Data object.
    # Without the tid-keyed $DBH cache, DBD::SQLite raises:
    # "handle %s is owned by thread %s not current thread"
    my @threads = map
    {
        threads->create(sub
        {
            my $cldr = Locale::Unicode::Data->new;
            return(0) unless( defined( $cldr ) );
            return( $cldr->isa( 'Locale::Unicode::Data' ) ? 1 : 0 );
        });
    } 1 .. $NUM_THREADS;

    my $success = 1;
    foreach my $thr ( @threads )
    {
        $success &&= $thr->join();
    }
    ok( $success, "All $NUM_THREADS threads instantiated Locale::Unicode::Data without error" );
};

# NOTE: Thread safety: concurrent locale() lookups
subtest 'Concurrent locale() lookups' => sub
{
    my @locales = qw(
        en-US fr-FR ja-JP de-DE zh-Hans-CN
        es-ES pt-BR ko-KR ar-SA ru-RU
    );

    my @threads = map
    {
        my $locale = $locales[ $_ % scalar( @locales ) ];
        threads->create(sub
        {
            my $cldr = Locale::Unicode::Data->new;
            return(0) unless( defined( $cldr ) );
            my $ref = $cldr->locale( locale => $locale );
            return(0) unless( defined( $ref ) );
            return(0) unless( ref( $ref ) eq 'HASH' );
            return(1);
        });
    } 0 .. ( $NUM_THREADS - 1 );

    my $success = 1;
    foreach my $thr ( @threads )
    {
        $success &&= $thr->join();
    }
    ok( $success, "All $NUM_THREADS threads performed locale() lookups without error" );
};

# NOTE: Thread safety: concurrent territory() lookups
subtest 'Concurrent territory() lookups' => sub
{
    my @territories = qw( US FR JP DE CN ES BR KR SA RU );

    my @threads = map
    {
        my $territory = $territories[ $_ % scalar( @territories ) ];
        threads->create(sub
        {
            my $cldr = Locale::Unicode::Data->new;
            return(0) unless( defined( $cldr ) );
            my $ref = $cldr->territory( territory => $territory );
            return(0) unless( defined( $ref ) );
            return(0) unless( ref( $ref ) eq 'HASH' );
            return(1);
        });
    } 0 .. ( $NUM_THREADS - 1 );

    my $success = 1;
    foreach my $thr ( @threads )
    {
        $success &&= $thr->join();
    }
    ok( $success, "All $NUM_THREADS threads performed territory() lookups without error" );
};

# NOTE: Thread safety: concurrent language() lookups
subtest 'Concurrent language() lookups' => sub
{
    my @languages = qw( en fr ja de zh es pt ko ar ru );

    my @threads = map
    {
        my $lang = $languages[ $_ % scalar( @languages ) ];
        threads->create(sub
        {
            my $cldr = Locale::Unicode::Data->new;
            return(0) unless( defined( $cldr ) );
            my $ref = $cldr->language( language => $lang );
            return(0) unless( defined( $ref ) );
            return(0) unless( ref( $ref ) eq 'HASH' );
            return(1);
        });
    } 0 .. ( $NUM_THREADS - 1 );

    my $success = 1;
    foreach my $thr ( @threads )
    {
        $success &&= $thr->join();
    }
    ok( $success, "All $NUM_THREADS threads performed language() lookups without error" );
};

# NOTE: Thread safety: concurrent plural_rule() lookups
subtest 'Concurrent plural_rule() lookups' => sub
{
    my @locales = qw( en fr ja ru ar pl cs sk sl he );

    my @threads = map
    {
        my $locale = $locales[ $_ % scalar( @locales ) ];
        threads->create(sub
        {
            my $cldr = Locale::Unicode::Data->new;
            return(0) unless( defined( $cldr ) );
            my $ref = $cldr->plural_rule( locale => $locale );
            # plural_rule may legitimately return undef for some locales
            return(1) if( !defined( $ref ) && !$cldr->error );
            return(0) if( !defined( $ref ) && $cldr->error );
            return(0) unless( ref( $ref ) eq 'HASH' );
            return(1);
        });
    } 0 .. ( $NUM_THREADS - 1 );

    my $success = 1;
    foreach my $thr ( @threads )
    {
        $success &&= $thr->join();
    }
    ok( $success, "All $NUM_THREADS threads performed plural_rule() lookups without error" );
};

# NOTE: Thread safety: shared object, concurrent lookups
subtest 'Shared object concurrent lookups' => sub
{
    # Construct one object in the main thread, then use it from multiple
    # threads concurrently. Each thread gets its own $DBH via the tid key
    # so they do not interfere with each other.
    my $cldr = Locale::Unicode::Data->new;
    ok( defined( $cldr ), 'Shared Locale::Unicode::Data object constructed' );

    my @locales = qw( en-US fr-FR ja-JP de-DE zh-Hans-CN es-ES pt-BR ko-KR ar-SA ru-RU );

    my @threads = map
    {
        my $locale = $locales[ $_ % scalar( @locales ) ];
        threads->create(sub
        {
            my $ref = $cldr->locale( locale => $locale );
            return(0) unless( defined( $ref ) );
            return(0) unless( ref( $ref ) eq 'HASH' );
            return(1);
        });
    } 0 .. ( $NUM_THREADS - 1 );

    my $success = 1;
    foreach my $thr ( @threads )
    {
        $success &&= $thr->join();
    }
    ok( $success, "All $NUM_THREADS threads used shared object for locale() lookups without error" );
};

done_testing();

__END__
