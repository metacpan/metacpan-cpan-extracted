#!/usr/bin/env perl

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)
use Config;
use English '-no_match_vars';
use Test::Most tests => 3;
use Test::DZil;
use Env::Path 'PATH';
use Path::Class;

my $perl = file($EXECUTABLE_NAME);
if ( $OSNAME ne 'VMS' ) {
    $perl = file("$perl$Config{_exe}") unless $perl =~ m/$Config{_exe}$/i;
}
PATH->Prepend( $perl->dir->stringify() );

my $tzil = Builder->from_config(
    { dist_root => 1 },
    {   add_files => {
            'source/dist.ini' => simple_ini(
                ['@Basic'],
                [   RequiresExternal =>
                        { requires => [ "$perl", $perl->basename ] },
                ],
            ),
            'source/lib/DZT/Sample.pm' => <<'END_SAMPLE_PM' } } );
package DZT::Sample;
# ABSTRACT: Sample package
1;
END_SAMPLE_PM

lives_ok( sub { $tzil->build() }, 'build' );
ok( ( grep { $ARG->name eq 't/requires_external.t' } @{ $tzil->files } ),
    'test script added' );
lives_ok(
    sub { $tzil->run_tests_in( $tzil->built_in ) },
    "run DZ tests: $perl executable and added to PATH",
);
