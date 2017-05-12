#===============================================================================
#
#  DESCRIPTION:  Test split mod
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$

use strict;
use warnings;

use Test::More tests => 2;                      # last test to print
#use Test::More('no_plan');
use Flow;
use Flow::Split;
use Flow::Test;
use Data::Dumper;
#use_ok('Flow::Split');

my $str;
my $f1 = create_flow( sub { [1] } );
my $f2 = create_flow( sub { [2] } );
my $f =
  Flow::create_flow( Join => { Data1 => $f1, Data2 => $f2 }, ToXML => \$str );
$f->run(1);
my $in = $str;
my $out;
my $rec = sub { my $s = shift; push @{ $s->{rec} }, @_; \@_ };
my $fi1 = new Flow::Code:: flow => $rec, ctl_flow => $rec;
my $fi2 = new Flow::Code:: flow => $rec, ctl_flow => $rec;
my $fi = create_flow(
    FromXML => \$in,
    Split => { Data1 => $fi1, Data2 => $fi2 },
    Splice=>10,
    ToXML => \$out
);
$fi->run();

is_deeply [$fi1->{rec}, $fi2->{rec}], [[1],[2]], 'Split';
is_deeply_xml $out,
q#<?xml version="1.0" encoding="UTF-8"?>
<FLOW makedby="Flow::To::XML"></FLOW>#, 'Out of split';

