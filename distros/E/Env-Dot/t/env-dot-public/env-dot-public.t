#!perl
use strict;
use warnings;
use Test2::V0;

use File::Spec     ();
use File::Basename qw( dirname );

use Data::Dumper;

subtest 'Public Interface' => sub {

    {
        my $this = dirname( File::Spec->rel2abs(__FILE__) );
        ($this) = $this =~ /(.+)/msx;    # Make it non-tainted

        chdir $this;
        local $ENV{'ENVDOT_FILEPATHS'} = $this . '/dotenv';
        ## no critic [BuiltinFunctions::ProhibitStringyEval]
        my $r = eval <<"END_OF_TEXT";
use Env::Dot;
END_OF_TEXT
        is( $ENV{'FOURTH_VAR'}, 'My fourth var', 'Interface works' );
    }

    done_testing;
};

done_testing;
