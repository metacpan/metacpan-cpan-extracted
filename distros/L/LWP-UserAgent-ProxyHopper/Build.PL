use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'LWP::UserAgent::ProxyHopper',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/LWP/UserAgent/ProxyHopper.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'LWP::UserAgent'                    => 2.036,
        'LWP::UserAgent::ProxyHopper::Base' => 0.002,
    },
    add_to_cleanup      => [ 'LWP-UserAgent-ProxyHopper-*' ],
    create_makefile_pl => 'traditional',
);

my $t = $builder->prompt(
"\n\n\nThis test includes a run-through test, it might take a long time "
. "(20 secs - 5 minutes). Running it will not fail the test-suite at all but"
. " prints some debug info which I would love to examine to make the module better"
. ". If you chose to run the run-through test then, please, can you email "
. "the output to cpan\@zoffix.com. Thank you.\n\n"
. "Would you like to run the run-through test? [Y/n]:", 'y'
);

if ( 'y' eq lc $t ) {
    open my $TOUCH, '>', 'lwp_ua_proxify_do_thorough_testing'
        or warn "Failed to create a test file `do_thorough_testing` ($!)";

    close $TOUCH;
}
else {
    unlink 'lwp_ua_proxify_do_thorough_testing';
}
$builder->create_build_script();
