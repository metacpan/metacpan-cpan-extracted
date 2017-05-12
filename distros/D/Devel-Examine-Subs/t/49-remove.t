#!perl 
use warnings;
use strict;

use Data::Dumper;
use File::Copy;
use Test::More tests => 4;

use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";

my $file = 't/sample.data';
my $copy = 't/remove.data';

eval{ copy $file, $copy or die $!; };
is ($@, '', "sample file copied ok");

$file = $copy;

my $des = Devel::Examine::Subs->new (
    file => $file,
);

{
    $des->remove(delete => ["# sample data file"]);

    open my $fh, '<', $copy or die $!;

    my $line = <$fh>;

    like ($line, qr/package/, "remove deletes properly");
}

eval { unlink $file or die $!; };
is ($@, '', "test data file removed ok");

