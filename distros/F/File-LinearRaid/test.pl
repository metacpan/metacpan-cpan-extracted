#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use File::Temp ':POSIX';

use_ok("File::LinearRaid");

my %data = (
    "empty-0"   => "",
    "num-15"    => "123456789012345",
    "lines1-15" => "123456789_12345",
    "lines2-15" => "6789_123456789_",
    "a-15"      => "a" x 15,
);

my %tmp_files;

END {
    unlink for values %tmp_files;
}

for (keys %data) {
    $tmp_files{$_} = scalar tmpnam();
    open my $fh, ">", $tmp_files{$_} or die $!;
    print $fh $data{$_};
}

##################

my $fh = File::LinearRaid->new( "<",
    $tmp_files{"empty-0"} => 15,
    $tmp_files{"num-15"} => 15,
    $tmp_files{"num-15"} => 5
);

is( $fh->size,
    35,
    "size accessor" );

isa_ok(
    $fh,
    "File::LinearRaid",
    "new return" );

#################

for (20, 10, 0, 10) {
    ok( seek($fh, $_, 0),
        "seek to $_" );
    is( tell($fh),
        $_,
        "tell == seek" );
}

#################

my $buf;
my $pos = 0;
seek($fh, 0, 0);

my @buffers = (("\x0" x 15) . "123456789012345") =~ m/(.{10})/gs;

for (0..2) {
    my $b = read $fh, $buf, 10;

    is( length $buf,
        10,
        "read right amount" );
    is( $buf,
        $buffers[$_],
        "read correct data" );
    is( $b,
        length $buf,
        "read returned appropriate amount" );
    is( tell($fh),
        $pos + 10,
        "read advances pointer" );
    $pos += 10;
}

seek $fh, 35, 0;
my $b = read $fh, $buf, 10;
is( $b,
    0,
    "don't read past end (physical eof)" );
is( $buf,
    "",
    "don't read past end (physical eof)" );


seek $fh, 30, 0;
$b = read $fh, $buf, 10;
is( $b,
    5,
    "don't read past end (logical eof)" );
is( length $buf,
    5,
    "don't read past end (logical eof)" );

###############

$fh = File::LinearRaid->new( "<",
    $tmp_files{"lines1-15"} => 15,
    $tmp_files{"lines2-15"} => 15
);

is( tell($fh),
    0,
    "init pointer = 0" );

my $lines = 0;
$pos = 0;

for (0..2) {
    local $/ = "_";
    $buf = <$fh>;

    is( length $buf,
        10,
        "readline until \$/" );
    is( $buf,
        "123456789_",
        "readline correct data" );
    is( tell($fh),
        ($pos += 10),
        "readline advances pointer" );
}

ok( (not defined scalar <$fh>),
    "readline = undef at eof" );
    
###
    
seek $fh, 0, 0;
{ local $/ = undef;
  $buf = <$fh>;
}
is( length($buf),
    30,
    "readline with \$/ = undef" );
is( tell($fh),
    30,
    "readline with \$/ = undef" );
ok( eof($fh),
    "readline to end of file" );



ok( $fh->append( $tmp_files{"a-15"} => 15 ),
    "append accessor" );

is( $fh->size,
    45,
    "size accessor after append" );

ok( seek($fh, 35, 0),
    "seek after append" );
is( tell($fh),
    35,
    "tell after append" );

$b = read $fh, $buf, 10;
is( $b,
    10,
    "read after append" );
is( $buf,
    "a" x 10,
    "read correct data after append" );

###################################

$fh = File::LinearRaid->new( "+<",
    $tmp_files{"empty-0"} => 15,
    $tmp_files{"a-15"} => 15
);

seek $fh, 5, 0;
$b = print $fh "x" x 5;
ok( $b,
    "write to file" );

is( tell($fh),
    10,
    "print advanced pointer" );
    
seek $fh, 13, 0;
print $fh "x" x 5;

{
  seek $fh, 0, 0;
  local $/;
  $buf = <$fh>;
}

is( $buf,
    ("\x0" x 5) . ("x" x 5) . ("\x0" x 3) . ("x" x 5) . ("a" x 12),
    "write filled with nulls" );

close $fh;
