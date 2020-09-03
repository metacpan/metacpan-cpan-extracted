use strict;
use warnings;

use HTML::Parser ();
use Test::More;

my $no_tests = shift || 3;
plan tests => $no_tests;

my $file = "junk$$.html";
die if -e $file;

for (1 .. $no_tests) {
    open(my $junk, '>', $file) || die;
    for (1 .. rand(5000)) {
        for (1 .. rand(200)) {
            print {$junk} pack("N", rand(2**32));
        }
        print {$junk} ("<", "&", ">")[rand(3)];   # make these a bit more likely
    }
    close($junk);

    #diag "Parse @{[-s $file]} bytes of junk";

    HTML::Parser->new->parse_file($file);
    pass();

    #print_mem();
}

unlink($file);


sub print_mem {

    # this probably only works on Linux
    open(my $stat, "/proc/self/status") || return;
    while (defined(my $line = <$stat>)) {
        diag $line if $line =~ /^VmSize/;
    }
}
