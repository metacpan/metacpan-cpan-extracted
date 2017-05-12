package t::tfiles;

use IPC::System::Simple;
use autodie qw(system);

sub import {
    system('rm -rf tfiles');
    system('mkdir tfiles');
}

1;
