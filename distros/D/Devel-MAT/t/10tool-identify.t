#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;

use Devel::MAT::Dumper;
use Devel::MAT;
use Scalar::Util qw( refaddr );

my $DUMPFILE = "test.pmat";

our %HASH = (
   array => [ my $SCALAR = \"foobar" ],
);

Devel::MAT::Dumper::dump( $DUMPFILE );
END { unlink $DUMPFILE; }

my $pmat = Devel::MAT->load( $DUMPFILE );
ok ( scalar( grep { $_ eq "Identify" } $pmat->available_tools ), 'Identify tool is available' );

$pmat->load_tool( "Identify" );

my $graph = $pmat->inref_graph( $pmat->dumpfile->sv_at( refaddr $SCALAR ),
   strong => 1,
   direct => 1,
   elide  => 1,
);

my $got = "";

no warnings 'once';
local *Devel::MAT::Cmd::printf = sub {
   shift;
   my ( $fmt, @args ) = @_;
   $got .= sprintf $fmt, @args;
};
Devel::MAT::Tool::Identify::walk_graph( $graph );

# Due to ordering within walk_graph this string should be relatively stable
my $want = <<'EOR';
├─(via RV) a constant of CODE() at _ADDR_=main_cv, which is:
│ └─the main code
├─(via RV) element [0] of ARRAY(1) at _ADDR_, which is:
│ └─(via RV) value {array} of HASH(1) at _ADDR_, which is:
│   └─the symbol '%main::HASH'
└─(via RV) the lexical $SCALAR at depth 1 of CODE() at _ADDR_=main_cv, which is:
  └─the main code
EOR

chomp $want;
$want = quotemeta $want;
$want =~ s/_ADDR_/0x[0-9a-f]+/g;
$want =~ s/_NUM_/\\d+/g;

like( $got, qr/^$want$/, 'string from walk_graph' );

done_testing;
