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
use Test::More tests => 2;
use lib 't';

=head1 DESCRIPTION

This is a basic test that OnError ignores an eval wrapped die().

=cut




use vars qw( $Caught );
BEGIN {
    no warnings 'once';
    @DB::typeahead = ('$main::Caught = 1','c');

    require 'reset_perms.pl';
}
use Enbugger::OnError;

my $ok = eval {
     die "An exception.\n";
     return 1;
};
isnt( $ok, 'Eval died' );
isnt( $main::Caught, q(Didn't trigger the debugger for the exception) );



=begin emacs

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:

=end emacs
