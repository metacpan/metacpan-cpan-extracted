use strict;
use Benchmark qw(cmpthese);
use File::MMagic;
use File::MMagic::XS;

my $fm   = File::MMagic->new();
my $fmxs = File::MMagic::XS->new();

my $file = shift @ARGV;
cmpthese(10_000, {
    xs   => sub { $fmxs->get_mime($file) },
    perl => sub { $fm->checktype_filename($file) }
});