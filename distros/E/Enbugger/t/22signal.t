#!perl

# COPYRIGHT AND LICENCE
#
# Copyright (C) 2007,2008 WhitePages.com, Inc. with primary
# development by Joshua ben Jore.
#
# This program is distributed WITHOUT ANY WARRANTY, including but not
# limited to the implied warranties of merchantability or fitness for
# a particular purpose.
#
# The program is free software.  You may distribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation (either version 2 or any later version)
# and the Perl Artistic License as published by O’Reilly Media, Inc.
# Please open the files named gpl-2.0.txt and Artistic for a copy of
# these licenses.

use strict;
use warnings;
use Test::More tests => 1;
use Config '%Config';
use lib 't';

my @SignalNames = split ' ', $Config{sig_name};
my %SignalNames =
   map {
       $SignalNames[$_] => $_;
   }
   0 .. $#SignalNames;

=head1 DESCRIPTION

This is a basic test that OnError traps a USR1 signal

=cut





BEGIN {
    no warnings 'once';
    @DB::typeahead = (q(main::is( "$@", 'USR1')),'q');

    require 'reset_perms.pl';
}
use Enbugger::OnError 'USR1';

kill $SignalNames{USR1}, $$;





=begin emacs

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:

=end emacs
