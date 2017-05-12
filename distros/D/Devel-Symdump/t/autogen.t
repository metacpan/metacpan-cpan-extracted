#!/usr/bin/perl -w

BEGIN { unshift @INC, '.' ;}

require Devel::Symdump;

print "1..8\n";

@p = qw(
scalars arrays hashes functions
unknowns filehandles dirhandles packages);

$i=0;
if ($] < 5.010) {
    # with 5.8.9 just calling a sort() left something behind on the symbol table
    @x1 = sort (1,2);
}
for (@p){
    @x1 = sort Devel::Symdump->$_();
    @x2 = sort Devel::Symdump->new->$_();
    unless ("@x1" eq "@x2"){
        my %h1 = map {$_=>1} @x1;
        my %h2 = map {$_=>1} @x2;
        my %hm;
        for (@x1,@x2) {
            $hm{$_}++;
        }
        for my $k (sort keys %hm) {
            next if $hm{$k}==2;
            if (!exists $h1{$k}) {
                print "# only in x2 [$k]\n";
            } else {
                print "# only in x1 [$k]\n";
            }
        }
	print "not ";
    }
    print "ok ", ++$i, "\n";
}

