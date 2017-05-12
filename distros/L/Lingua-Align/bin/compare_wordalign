#!/usr/bin/perl
#-*-perl-*-


use strict;
use FindBin;
use lib $FindBin::Bin.'/../lib';

use Lingua::Align::Corpus::Parallel;

use vars qw($opt_a $opt_b $opt_A $opt_B $opt_s $opt_S $opt_t $opt_T);
use Getopt::Std;
getopts('a:b:A:B:s:S:t:T:');


my $alg1file=shift(@ARGV);
my $alg2file=shift(@ARGV);


my $alg1type = $opt_a || 'sta';
my $alg2type = $opt_b || 'sta';

my $text1type = $opt_A || 'tiger';
my $text2type = $opt_B || 'tiger';


my $class1 = new Lingua::Align::Corpus::Parallel(
    -type => $alg1type,
    -alignfile => $alg1file,
    -src_type => $text1type,
    -trg_type => $text1type,
    -src_file => $opt_s,
    -trg_file => $opt_t);
my $class2 = new Lingua::Align::Corpus::Parallel(
    -type => $alg2type,
    -alignfile => $alg2file,
    -src_type => $text2type,
    -trg_type => $text2type,
    -src_file => $opt_S,
    -trg_file => $opt_T);




my (%src1,%trg1);
my (%src2,%trg2);

while ($class1->next_alignment(\%src1,\%trg1)){
    while ($class2->next_alignment(\%src2,\%trg2)){
	last if ($src2{ID} eq $src1{ID});
    }

    my %links1 = $class1->get_links(\%src1,\%trg1);
    my %links2 = $class2->get_links(\%src2,\%trg2);

#    $class1->print_link_matrix(\@srcwords,\@trgwords,\%links1);
#    $class1->print_link_matrix(\@srcwords,\@trgwords,\%links2);
    $class1->compare_link_matrix(\%src1,\%trg1,\%links1,\%links2);

    print STDERR "press enter to continue ";
    <>;
}


