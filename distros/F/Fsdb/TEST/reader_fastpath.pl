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

# preamble
my $out;
my $in = new Fsdb::IO::Reader(-file => '-', -comment_handler => \$out)
    or die "cannot open stdin as fsdb\n";
$out = new Fsdb::IO::Writer(-file => '-', -clone => $in)
    or die "cannot open stdin as fsdb\n";

my $x_i = $in->col_to_i('x') // die "no x column.\n";
my $y_i = $in->col_to_i('y') // die "no y column.\n";
my $product_i = $in->col_to_i('product') // die "no product column.\n";

my $in_fastpath_sub = $in->fastpath_sub();
my $out_fastpath_sub = $out->fastpath_sub();


# core
my $rowobj;
while ($rowobj = &$in_fastpath_sub) {
    $rowobj->[$product_i] = $rowobj->[$x_i] * $rowobj->[$y_i];
    &$out_fastpath_sub($rowobj);
};

exit 0;
