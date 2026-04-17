use Test2::V1 -ipP;
use Test2::IPC;
use Test2::Require::Module 'IPC::SysV' => '2.09';

# Skip if Makefile.PL disabled SharedMem because the host's SysV IPC
# was broken at install time.  In that case _viable() throws and
# viable() returns false.
require IPC::Manager::Client::SharedMem;
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    unless (IPC::Manager::Client::SharedMem->viable) {
        my $reason = join('', @warnings) || 'viable() returned false';
        plan(skip_all => "IPC::Manager::Client::SharedMem not viable: $reason");
    }
}

use lib 't/lib';
use IPC::Manager::Test;
IPC::Manager::Test->run_all(protocol => 'SharedMem');

done_testing;
