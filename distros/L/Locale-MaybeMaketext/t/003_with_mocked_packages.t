#!perl
use strict;
use warnings;
use File::Basename qw/dirname/;
use lib dirname(__FILE__);
use MaybeMaketextTestdata;

# Check everything works as expected using our dummy/mocked packages.
my $next = test_data_iterator();
while ( my $package = $next->() ) {

    my ($handle);
    unload_mocks();
    Locale::MaybeMaketext::maybe_maketext_reset();

    ok(
        lives {
            local @INC = $package->get_inc();
            $handle = Locale::MaybeMaketext::Tests::Simple->get_handle('en_gb');
        },
        sprintf( 'Calling get_handle for package %s', $package->get_name() ),
        sprintf(
            'Failed to get handle for %s: %s (%s) from %s',  $package->get_name(), $@,
            isa_diagnose( 'errored', $package->get_name() ), join( q{, }, $package->get_inc() )
        )
    );

    isa_check(
        $handle,
        [
            $package->get_name(),
            'Locale::MaybeMaketext',
            'Locale::MaybeMaketext::Tests::Simple',
            'Locale::MaybeMaketext::Tests::Simple::en_gb'
        ],
        sprintf( '%s: Should inherit correctly (English)', $package->get_name() )
    );
    is(
        sprintf( 'Generated through %s', $package->get_name() ),
        $handle->maketext('Dummy text'),
        sprintf( '%s: Checking mocked return', $package->get_name() )
    );
    $handle = Locale::MaybeMaketext::Tests::Simple->get_handle('fr');
    isa_check(
        $handle,
        [
            $package->get_name(),
            'Locale::MaybeMaketext',
            'Locale::MaybeMaketext::Tests::Simple',
            'Locale::MaybeMaketext::Tests::Simple::fr'
        ],
        sprintf( '%s: Should inherit correctly (French)', $package->get_name() )
    );
}
done_testing();
