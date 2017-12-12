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

{
    my $ssh = eval { $doit->do_ssh_connect('host.invalid', master_opts => [@std_master_opts]) };
    ok(!$ssh, 'Failed to connect to invalid host as expected');
}

{
    my $ssh = eval { $doit->do_ssh_connect('invalid.user.just.for.testing.Doit.pm@localhost', master_opts => [@std_master_opts]) };
    ok(!$ssh, 'Failed to connect to localhost with invalid user');
}

__END__
