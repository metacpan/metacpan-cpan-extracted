#! /usr/bin/perl
#---------------------------------------------------------------------
# 10-getopt.t
# Copyright 2002 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test the Getopt::Mixed module
#---------------------------------------------------------------------
######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use Getopt::Mixed 'getOptions';
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use vars qw($opt_apples $opt_apricots $opt_c $opt_d $opt_file);

@ARGV = qw(-a4 -dNow --file foo bar);

getOptions("apples=f a>apples apricots=f b:i c d:s file=s f>file pears=f",
           "help ?>help version V>version");

print 'not ' unless $opt_apples == 4;
print "ok 2\n";

print 'not ' unless $opt_d eq 'Now';
print "ok 3\n";

print 'not ' unless $opt_file eq 'foo';
print "ok 4\n";

print 'not ' if defined $opt_apricots;
print "ok 5\n";

print 'not ' unless $ARGV[0] eq 'bar';
print "ok 6\n";

print 'not ' if defined $opt_c;
print "ok 7\n";
