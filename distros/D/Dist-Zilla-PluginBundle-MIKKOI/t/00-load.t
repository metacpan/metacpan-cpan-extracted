#!perl
## no critic (ControlStructures::ProhibitPostfixControls)
use strict;
use warnings;

use utf8;
use Test2::V0;
set_encoding('utf8');

use Carp;
use English '-no_match_vars';
use Module::Load qw( load );
use File::Find ();
use File::Spec ();

# Add t/lib to @INC
use FindBin 1.51 qw( $RealBin );
use File::Spec;
my $lib_path;
BEGIN {
    $lib_path = File::Spec->catdir(($RealBin =~ /(.+)/msx)[0], q{.}, 'lib');
}
use lib "$lib_path";

my @dirs_to_search = (
    'lib',
    File::Spec->catdir('t', 'lib'),
);
my @packages;

foreach my $dir (@dirs_to_search) {
    File::Find::find(
        {
            wanted => sub {
                if( -f && m/ [.]{1} pm $/msx) {
                    my ($package) = m/ ^(?: $dir \/ ) ( [[:alnum:]\/]{1,} ) [.]{1} pm $/msx;
                    $package =~ s/\//::/gmsx;
                    push @packages, $package;
                }
                return;
            },
            no_chdir => 1,
        },
        $dir,
    ) if( -d $dir );
}

for my $package (@packages) {
    subtest 'Load ' . $package => sub {
        # Does it exist and can we load it?
        local $EVAL_ERROR = $EVAL_ERROR;
        my $r = eval { load $package; 1; };
        if( ! $r || $EVAL_ERROR ) {
            my $e = 'Failed to package \'%s\', error: %s';
            diag( sprintf $e, $package, $EVAL_ERROR );
            fail("Unable to load package $package");
        } else {
            pass("Can load package $package");
        }

        done_testing;
    };
}

done_testing;
