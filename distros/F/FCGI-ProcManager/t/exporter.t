# -*- perl -*-
# Copyright (c) 2000, FundsXpress Financial Network, Inc.
# This library is free software released "AS IS WITH ALL FAULTS"
# and WITHOUT ANY WARRANTIES under the terms of the GNU Lesser
# General Public License, Version 2.1, a copy of which can be
# found in the "COPYING" file of this distribution.

# $Id: exporter.t,v 1.6 2001/04/23 16:13:45 muaddie Exp $

use strict;
use Test;

BEGIN { plan tests => 4; }

use FCGI::ProcManager qw(:all);

ok pm_parameter('n_processes',100) == 100;
ok pm_parameter('n_processes',2) == 2;
ok pm_parameter('n_processes',0) == 0;

ok !pm_manage();

#ok pm_parameter('n_processes',-3);
#eval { pm_manage(); };
#ok $@ =~ /dying from number of processes exception: -3/;
#undef $@;

if ($ENV{PM_N_PROCESSES}) {
  pm_parameter('n_processes',$ENV{PM_N_PROCESSES});
  pm_manage();
  sample_request_loop();
}

exit 0;

sub sample_request_loop {

  while (1) {
    # Simulate blocking for a request.
    my $t1 = int(rand(2)+1);
    print "TEST: simulating blocking for request: $t1 seconds.\n";
    sleep $t1;
    # (Here is where accept-fail-on-intr would exit request loop.)

    pm_pre_dispatch();

    # Simulate a request dispatch.
    my $t = int(rand(3)+2);
    print "TEST: simulating request: sleeping $t seconds.\n";
    while (my $nslept = sleep $t) {
      $t -= $nslept;
      last unless $t;
    }

    pm_post_dispatch();
  }
}
