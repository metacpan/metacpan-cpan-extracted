use strict;
use Test::More tests => 1;

use Lingua::JA::Regular;

    my $charset = ($0 =~ /\d+_(\w+)\.t$/)[0];
    my @str;

    my $file = "t/text/$charset.txt";
    open(TEXT, $file) or  fail("test file open: $file");
    
    while(<TEXT>){
        chomp;
        push(@str, $_);
    }
    close(TEXT);

    my $regular = Lingua::JA::Regular->new($str[0], $charset)->regular;
    ok $regular eq $str[1], 'regular';

