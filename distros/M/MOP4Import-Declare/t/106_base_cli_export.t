use strict;
use warnings;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
use Test::More;

my $cli;

{
    package CLI_Opts::TestA;
    use MOP4Import::Base::CLI_Opts -as_base;
}

{
    package CLI_Opts::TestB;
    use MOP4Import::Base::CLI_Opts -as_base;
}

eval q{
    CLI_Opts::TestA->import();
    CLI_Opts::TestB->import();
};

ok(!$@, $@);


done_testing;

