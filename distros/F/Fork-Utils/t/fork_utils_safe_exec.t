package main;

use 5.012;
use utf8;
use strict;
use warnings;
use Test::More ('import' => [qw/ is done_testing /]);

use lib '../lib', 'lib';

use Fork::Utils qw/ safe_exec /;

my ($result, $error) = (0, '');
my $SUCCESS_VALUE = 101;

{
    local $SIG{'ALRM'} = "IGNORE"; # just not to be killed after "safe_exec"
    alarm(1);
    $result = safe_exec(
        code => sub {
            local $SIG{ALRM} = "DEFAULT";
            sleep(2);
            return $SUCCESS_VALUE;
        },
        sigset => [qw/ ALRM /]
    );
    $error = $@;
    alarm(0);
}

is($error, '', "Checking the error message");
is($result, $SUCCESS_VALUE, "Checking the blocked ALRM signal");

####

($result, $error) = (0, '');

alarm(1);

eval {
    local $SIG{'ALRM'} = "IGNORE";
    alarm(1);
    $result = safe_exec(
        code => sub {
            local $SIG{'ALRM'} = sub { die "alarmed\n" };
            sleep(2);
            return $SUCCESS_VALUE;
        },
        sigset => [qw/ INT /]
    );
    $error = $@;
    alarm(0);
};


is($error, "alarmed\n", "Checking the error message");
is($result, undef, "Checking the non-blocked ALRM signal");

done_testing();

1;
__END__
