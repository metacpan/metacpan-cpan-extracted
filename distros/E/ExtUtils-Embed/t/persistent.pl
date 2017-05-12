
use ExtUtils::testlib;
use lib qw(./lib ../lib);
use strict;
use Embed::Persistent ();

my $embed = Embed::Persistent->new(DEBUG => 1); 

my $dfile = -e "sub.pl" ? "sub.pl" : "t/sub.pl"; 
my $file;

while (1) {
    print "Enter filename: ";
    chomp($file = <STDIN>);
    $file ||= $dfile;
    $embed->eval_file($file);
}
