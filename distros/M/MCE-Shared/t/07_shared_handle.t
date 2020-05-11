#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use MCE::Signal qw( $tmp_dir );

BEGIN {
   use_ok 'MCE::Shared';
   use_ok 'MCE::Shared::Handle';
}

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

# https://perldoc.perl.org/PerlIO.html

my ($buf, $fno, $ret1, $ret2, $ret3, $ret4, $ret5) = ('');
my $tmp_file = "$tmp_dir/test.txt";

my $fh = MCE::Shared->handle(">:raw", $tmp_file);

$fno = fileno $fh;

for (1 .. 9) {
   print  $fh "$_\n";
   printf $fh "%2s\n", $_;
}

close $fh;

{
   mce_open my $fh, ">>:raw", $tmp_file;
   syswrite $fh, "foo";
   close $fh;
}

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

# MCE::Shared->open($fh, "<:raw", $tmp_file);

mce_open $fh, "<:raw", $tmp_file or die "open error: $!";

$ret1 = eof $fh;

while ( <$fh> ) {
   chomp, $buf .= $_;
}

$ret2 = eof $fh;
$ret3 = tell $fh;

seek $fh, 12, 0;
read $fh, $ret4, 2;

$ret5 = getc $fh;

close $fh;

like( $fno, qr/\A\d+\z/, 'shared file, OPEN, FILENO, CLOSE' );

is( $buf, '1 12 23 34 45 56 67 78 89 9foo',
    'shared file, PRINT, PRINTF, READLINE, WRITE'
);

is( $ret1, '',   'shared file, EOF (test 1)' );
is( $ret2, '1',  'shared file, EOF (test 2)' );
is( $ret3, '48', 'shared file, TELL' );
is( $ret4, ' 3', 'shared file, SEEK, READ' );
is( $ret5, "\n", 'shared file, GETC' );

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

mce_open $fh, ">:raw", $tmp_file or die "open error: $!";

for (1..200) {
   print $fh "some number $_ fe fi fo\n";
}

close $fh;

mce_open $fh, "<:raw", $tmp_file or die "open error: $!";

is( read($fh, $buf, "2k"), 2055, 'shared file, chunk 1 read' );
is( substr($buf, -1, 1), "\n",   'shared file, chunk 1 last char' );

is( read($fh, $buf, "2k"), 2062, 'shared file, chunk 2 read' );
is( substr($buf, -1, 1), "\n",   'shared file, chunk 2 last char' );

is( read($fh, $buf, "2k"),  775, 'shared file, chunk 3 read' );
is( substr($buf, -1, 1), "\n",   'shared file, chunk 3 last char' );

is( read($fh, $buf, "2k"),    0, 'shared file, EOF' );
is( length($buf),             0, 'shared file, EOF length' );

close $fh;

unlink $tmp_file if -f $tmp_file;

done_testing;

