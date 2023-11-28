#!perl
use strict;
use warnings;
use File::Basename qw/dirname/;
use lib dirname(__FILE__);
use MaybeMaketextTestdata;

# Checks to see that we verify if we have a module loaded before trying to load.
my $outer = test_data_iterator();
while ( my $loadable = $outer->() ) {
    unload_mocks();
    Locale::MaybeMaketext::maybe_maketext_reset();

    ok(
        lives {
            local @INC = $loadable->get_inc();
            require $loadable->get_path();
            Locale::MaybeMaketext::Tests::Simple->get_handle('en_gb');
        },
        sprintf( '%s: Should load correctly', $loadable->get_name() )
    );

    # check the reasoning
    my @reasoning = Locale::MaybeMaketext::maybe_maketext_get_reasoning();
    ok(
        $#reasoning == ( $loadable->get_index() ),
        sprintf( '%s: Should be exactly %d messages', $loadable->get_name(), ( $loadable->get_index() + 1 ) ),
        'Number of messages:', ( $#reasoning + 1 ),
        'Full reasoning:', @reasoning
    );
    my $expect = sprintf(
        '%s: Already loaded by filesystem from "%s/%s"', $loadable->get_name(), $loadable->get_mock(),
        $loadable->get_path()
    );
    my $qmexpect = quotemeta($expect);
    ok(
        $reasoning[-1] =~ /$qmexpect/,
        sprintf( '%s: Last message should be attempt to load', $loadable->get_name() ),
        (
            'Last',     $reasoning[-1],
            'Expected', $expect
        )
    );
    my $next = test_data_iterator();
    while ( my $package = $next->() ) {
        if ( $package->get_index() >= $loadable->get_index() ) {
            last;
        }
        $expect   = sprintf( '%s: No record of load attempt found', $package->get_name() );
        $qmexpect = quotemeta($expect);
        ok(
            $reasoning[ $package->get_index() ] =~ /$qmexpect/,
            sprintf(
                '%s: Message %s should relate to checking %s', $loadable->get_name(), $package->get_index(),
                $package->get_name()
            ),
            (
                'Index:',          $package->get_index(),
                'Expected: ',      $expect,
                'Got: ',           $reasoning[ $package->get_index() ],
                'Full reasoning:', @reasoning
            )
        );
    }
}
done_testing();
