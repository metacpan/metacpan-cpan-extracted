#!/usr/bin/perl -w

#
# pipeline_basic.pl
# Copyright (C) 2007 by John Heidemann
# $Id$
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

use Fsdb::IO::Reader;
use Fsdb::IO::Writer;

my $out;
my $in = new Fsdb::IO::Reader(-file => '-', -comment_handler => \$out)
    or die "cannot open stdin as fsdb\n";
$out = new Fsdb::IO::Writer(-file => '-', -clone => $in)
    or die "cannot open stdin as fsdb\n";

my %hrow;
while ($in->read_row_to_href(\%hrow)) {
    $hrow{product} = $hrow{x} * $hrow{y};
    $out->write_row_from_href(\%hrow);    
};

exit 0;
