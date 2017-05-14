# 001_main.t

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Basename 'dirname';
use utf8;

use File::Sip;

my $dir = File::Spec->rel2abs( dirname(__FILE__) );
my $txt_file = File::Spec->catfile( $dir, 'data', 'somefile.txt' );

my @lines = (
    'This is a first line',
    'and', 'a ', 'fourth.', "some utf8 ★ ",
    '',    'A line after an empty one.',
);
my $file = File::Sip->new( path => $txt_file );

subtest "read lines one by one, with their position" => sub {
    my $count = 0;
    foreach my $line (@lines) {
        is $file->read_line( $count++ ), "$line\n", "got expected line $count";
    }
};

subtest "Read all the lines, with an iterator loop" => sub {
    my $count = 0;
    while ( my $line = $file->read_line ) {
        is $line, $lines[ $count++ ] . "\n", "got expected line $count";
    }
};

done_testing;
