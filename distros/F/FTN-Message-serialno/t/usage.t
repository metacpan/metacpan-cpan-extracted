#!perl -T
use strict;
use warnings FATAL => 'all';

use Test::More tests => 14;

BEGIN {
    use_ok( 'FTN::Message::serialno::File' ) || print "Bail out!\n";
    use_ok( 'File::Temp' ) or print "no File::Temp\n";
}

my $dir = File::Temp -> newdir;
my $serialno = FTN::Message::serialno::File -> new( directory => $dir );

for my $expected ( qw/ 00000001
                       00000002
                       00000003
                       00000004
                     /
                 ) {
  is( $serialno -> get_serialno, $expected );
}

$dir = File::Temp -> newdir;
$serialno = FTN::Message::serialno::File -> new( directory => $dir,
                                                 file_extension => 'seq',
                                               );

for my $expected ( qw/ 00000001
                       00000002
                       00000003
                       00000004
                     /
                 ) {
  is( $serialno -> get_serialno, $expected );
}

$dir = File::Temp -> newdir;
$serialno = FTN::Message::serialno::File -> new( directory => $dir,
                                                 file_extension => 'seq',
                                                 very_first_init => sub { 42; },
                                                 serialno_format => '%08X',
                                               );

for my $expected ( qw/ 0000002A
                       0000002B
                       0000002C
                       0000002D
                     /
                 ) {
  is( $serialno -> get_serialno, $expected );
}
