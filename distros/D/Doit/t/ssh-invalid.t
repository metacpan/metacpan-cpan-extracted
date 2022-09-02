#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use Doit;
use Test::More;

return 1 if caller;

plan skip_all => "Net::OpenSSH does not work on Windows" if $^O eq 'MSWin32'; # but it can still be installed
plan 'no_plan';

my @std_master_opts = qw(-oPasswordAuthentication=no -oBatchMode=yes);

my $doit = Doit->init;

my $cant_locate_net_openssh_rx = qr{Can't locate Net/OpenSSH\.pm};

{
    my $ssh = eval { $doit->do_ssh_connect('host.invalid.but.unused.here', put_to_remote => 'unhandled_put') };
    like $@, qr{($cant_locate_net_openssh_rx|\QValid values for put_to_remote:\E)}, 'expected error message';
    ok(!$ssh, 'Options error');
}

{
    my $ssh = eval { $doit->do_ssh_connect('host.invalid.but.unused.here', umask => 'invalid') };
    like $@, qr{($cant_locate_net_openssh_rx|\QThe umask 'invalid' does not look correct, it should be a (possibly octal) number\E)}, 'expected error message';
    ok(!$ssh, 'Options error');
}

{
    my $ssh = eval { $doit->do_ssh_connect('host.invalid', master_opts => [@std_master_opts]) };
    ok(!$ssh, 'Failed to connect to invalid host as expected');
}

{
    my $ssh = eval { $doit->do_ssh_connect('invalid.user.just.for.testing.Doit.pm@localhost', master_opts => [@std_master_opts]) };
    ok(!$ssh, 'Failed to connect to localhost with invalid user');
}

__END__
