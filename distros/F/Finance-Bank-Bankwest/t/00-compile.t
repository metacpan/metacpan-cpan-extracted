use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.039

use Test::More  tests => 23 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'Finance/Bank/Bankwest.pm',
    'Finance/Bank/Bankwest/Account.pm',
    'Finance/Bank/Bankwest/Error.pm',
    'Finance/Bank/Bankwest/Error/BadResponse.pm',
    'Finance/Bank/Bankwest/Error/ExportFailed.pm',
    'Finance/Bank/Bankwest/Error/ExportFailed/UnknownReason.pm',
    'Finance/Bank/Bankwest/Error/NotLoggedIn.pm',
    'Finance/Bank/Bankwest/Error/NotLoggedIn/BadCredentials.pm',
    'Finance/Bank/Bankwest/Error/NotLoggedIn/SubsequentLogin.pm',
    'Finance/Bank/Bankwest/Error/NotLoggedIn/Timeout.pm',
    'Finance/Bank/Bankwest/Error/NotLoggedIn/UnknownReason.pm',
    'Finance/Bank/Bankwest/Error/ServiceMessage.pm',
    'Finance/Bank/Bankwest/Error/WithResponse.pm',
    'Finance/Bank/Bankwest/Parser/Accounts.pm',
    'Finance/Bank/Bankwest/Parser/Login.pm',
    'Finance/Bank/Bankwest/Parser/Logout.pm',
    'Finance/Bank/Bankwest/Parser/ServiceMessage.pm',
    'Finance/Bank/Bankwest/Parser/TransactionExport.pm',
    'Finance/Bank/Bankwest/Parser/TransactionSearch.pm',
    'Finance/Bank/Bankwest/Parsers.pm',
    'Finance/Bank/Bankwest/Session.pm',
    'Finance/Bank/Bankwest/SessionFromLogin.pm',
    'Finance/Bank/Bankwest/Transaction.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};


