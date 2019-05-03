use warnings;
use strict;

use Data::Dumper;

open my $fh, '<', 'script/wmm.com' or die $!;

my @current_list;
my @wmm;

while (my $line = <$fh>){
    if ($. == 1) {
        push @wmm, [];
        next;
    }

    last if $line =~ /^99999999/;

    $line =~ s/^\s+//;
    my $test = $line;

    (my $one, my $two, my @vars) = $line =~ /^(\d+)\s+(\d+)/;

#    print "$one, $two, $line\n";

    if ($one != $two){
        push @current_list, [$test];
    }
    else {
        push @wmm, [@current_list];
        @current_list = ();
    }
}

print Dumper \@wmm;