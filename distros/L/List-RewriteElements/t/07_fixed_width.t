# -*- perl -*-
#$Id: 07_fixed_width.t 1110 2006-12-14 03:56:31Z jimk $
# t/07_fixed_width.tt - test what happens with fixed width records
use strict;
use warnings;

use Test::More qw(no_plan); # tests => 35;
use_ok( 'List::RewriteElements' );
use lib ( "t/testlib" );
use_ok( 'IO::Capture::Stdout' );

my $lre;
my $cap;
my @lines;

my @dataset = (
    q{00374Bloggs & Co       19991105100103+00015000},
    q{00375Smith Brothers    19991106001234-00004999},
    q{00376Camel Inc         19991107289736+00002999},
    q{00377Generic Code      19991108056789-00003999},
);

my %revisions = (
    376 => [ 'Camel Inc', 20061107, 388293, '+', 4999 ],
    377 => [ 'Generic Code', 20061108, 99821, '-',  6999 ],
);

my @expected = (
  q{00374Bloggs & Co       19991105100103+00015000},
  q{00375Smith Brothers    19991106001234-00004999},
  q{00376Camel Inc         20061107388293+00004999},
  q{00377Generic Code      20061108099821-00006999},
);


$lre  = List::RewriteElements->new ( {
    list        => \@dataset,,
    body_rule   => \&update_record,
} );
isa_ok ($lre, 'List::RewriteElements');

$cap = IO::Capture::Stdout->new();
$cap->start();
$lre->generate_output();
$cap->stop();
chomp( @lines = $cap->read() );

is_deeply( [ @lines ], [ @expected ],
    "Got expected output after updating fixed-width records");

$lre  = List::RewriteElements->new ( {
    file        => "t/testlib/fixed.txt",
    body_rule   => \&update_record,
} );
isa_ok ($lre, 'List::RewriteElements');

$cap = IO::Capture::Stdout->new();
$cap->start();
$lre->generate_output();
$cap->stop();
chomp( @lines = $cap->read() );

is_deeply( [ @lines ], [ @expected ],
    "Got expected output after updating fixed-width records");


sub update_record {
    my $record = shift;
    my $template = 'A5A18A8A6AA8';
    my @rec  = unpack($template, $record);
    $rec[0] =~ s/^0+//;
    my ($acctno, %values, $result);
    $acctno = $rec[0];
    $values{$acctno} = [ @rec[1..$#rec] ];
    if ($revisions{$acctno}) {
        $values{$acctno} = $revisions{$acctno};
    }
    $result = sprintf  "%05d%-18s%8d%06d%1s%08d",
        ($acctno, @{$values{$acctno}});
    return $result;
};
