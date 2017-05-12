#!/usr/bin/env perl
#-*-perl-*-

use Test::More;
use utf8;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use Lingua::Identify::Blacklists ':all';

# evaluation files
my %files = ( bs => "$Bin/data/eval/dnevniavaz.ba.200.check",
	      hr => "$Bin/data/eval/vecernji.hr.200.check",
	      sr => "$Bin/data/eval/politika.rs.200.check" );

# correct prediction counts (for classification of every_line)
my %eval = ( 'bs' => { bs => 188, hr => 11, sr => 1 },
	     'hr' => { hr => 196, bs => 4 },
	     'sr' => { sr => 200 } );


foreach my $lang (keys %files){

    # classify the whole file
    is( identify_file($files{$lang}), $lang);

    # classify every line separately
    my @pred = identify_file($files{$lang}, every_line => 1);
    foreach my $l (keys %{$eval{$lang}}){
	is( my $count = grep ($_ eq $l,@pred), $eval{$lang}{$l} );
    }
}

done_testing;
