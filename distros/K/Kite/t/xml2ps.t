#!/usr/bin/perl -w

use strict;
use lib qw( ./lib ../lib);
use Kite::XML2PS;

print "1..6\n";
my $n = 0;

sub ok {
    shift or print "not ";
    print "ok ", ++$n, "\n";
}

my $file = 'xml/test.xml';
$file = -f $file ? $file : (-f "../$file" ? "../$file" : die "$file: $!\n");

# test failure and error message set
ok( ! defined  Kite::XML2PS->new( filename => 'no such file' ) );
ok( $Kite::XML2PS::ERROR );

my $ps = Kite::XML2PS->new( filename => $file )
    || die $Kite::XML2PS::ERROR, "\n";
ok( $ps );
ok( $ps->path );
ok( $ps->image );
ok( $ps->doc );

