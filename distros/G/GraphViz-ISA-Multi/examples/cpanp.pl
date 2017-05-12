#!/usr/bin/perl -w
# Example for GraphViz::ISA::Multi
# 2003 (c) by Marcus Thiesen
# marcus@cpan.org

use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/../lib";

use GraphViz::ISA::Multi;
use CPANPLUS; # make sure it is there


my $gnew= GraphViz::ISA::Multi->new(ignore => [ 'Exporter' ]);

$gnew->add("CPANPLUS::Backend" );
$gnew->add("CPANPLUS::Configure" );
$gnew->add("CPANPLUS::Error" );
$gnew->add("CPANPLUS::Internals::Author" );
$gnew->add("CPANPLUS::Sell::Default" );

print "Writing to cpanp.png\n";
open TEST, ">cpanp.png";
print TEST $gnew->as_png();
close TEST;

