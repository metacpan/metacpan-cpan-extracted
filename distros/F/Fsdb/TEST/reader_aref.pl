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

use 5.010;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;

my $out;
my $in = new Fsdb::IO::Reader(-file => '-', -comment_handler => \$out)
    or die "cannot open stdin as fsdb\n";
$out = new Fsdb::IO::Writer(-file => '-', -clone => $in)
    or die "cannot open stdin as fsdb\n";

my $x_i = $in->col_to_i('x') // die "no x column.\n";
my $y_i = $in->col_to_i('y') // die "no y column.\n";
my $product_i = $in->col_to_i('product') // die "no product column.\n";
my @arow;
while ($in->read_row_to_aref(\@arow)) {
    $arow[$product_i] = $arow[$x_i] * $arow[$y_i];
    $out->write_row_from_aref(\@arow);    
};

exit 0;
