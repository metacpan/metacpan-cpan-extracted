# This test should demonstrate that strictures are enabled
#   in all lexical scope in this project. 
#   But it only checks use-ed modules. 

#~ use strict;
use warnings;

my @modules     = (
    'Error::Base',                # Simple structured errors with full backtrace
    'Error::Base::Cookbook',      # Examples of Error::Base usage

);

BEGIN {
#~     no warnings 'redefine';
    require strict;
    no warnings;
    *strict::import = sub {
#~         print STDERR "Successfully here: ";
        my @caller      = caller(0);
#~         my $call_pkg    = caller(0)[0];
        my $call_pkg    = $caller[0];
#~         my $call_file   = caller[1];
#~         print STDERR $call_pkg;
#~         print STDERR $call_file;
#~         print STDERR caller;
#~         print STDERR "\n";
        push @::callers, $call_pkg;
    };
}

use Test::More;
my $tc      ;
my $base    = 'strictures-enabled: ';

for (@modules) {
    $tc++;
    my $mod     = $_;
    my $diag    = $base . $mod;
    eval "use $mod";
    my $got     = join q{^}, @::callers;
    my $want    = qr/$mod/;
    like( $got, $want, $diag );
};

done_testing($tc);
exit 0;


