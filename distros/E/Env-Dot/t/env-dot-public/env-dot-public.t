#!perl
use strict;
use warnings;
use Test2::V0;

use File::Spec     ();
use File::Basename qw( dirname );
use Cwd;

# First thing change dir!
BEGIN {
    my $this = dirname( File::Spec->rel2abs(__FILE__) );
    ($this) = $this =~ /(.+)/msx;    # Make it non-tainted
    chdir $this;
}
subtest 'Public Interface' => sub {

    {
        # Do not use __FILE__ because its value is not absolute and not updated
        # when chdir is done.
        my $this = getcwd;
        ($this) = $this =~ /(.+)/msx;    # Make it non-tainted
        my %new_env = (
            'ENVDOT_FILEPATHS' => $this . '/dotenv',
            'FIRST_VAR'        => 'not to be overwritten',
        );

        # We need to replace the current %ENV, not change individual values.
        ## no critic [Variables::RequireLocalizedPunctuationVars]
        %ENV = %new_env;
        my $r = eval <<"END_OF_TEXT";    ## no critic [BuiltinFunctions::ProhibitStringyEval]
use Env::Dot;
END_OF_TEXT
        is( $ENV{'FOURTH_VAR'}, 'My fourth var', 'Interface works' );
        is( $ENV{'THIRD_VAR'},  'My third var',  'Interface works' );
        {
            ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
            is( $ENV{'SECOND_VAR'}, 'My second var!@#$ %', 'Interface works' );
        }
        isnt( $ENV{'FIRST_VAR'}, 'My first var', 'Interface works; variable value not from dotenv' );
        is( $ENV{'FIRST_VAR'}, 'not to be overwritten', 'Interface works; variable not overwritten' );
        is( $ENV{'FIFTH_VAR'}, undef,                   'Interface works, not existing var' );
    }

    done_testing;
};

done_testing;
