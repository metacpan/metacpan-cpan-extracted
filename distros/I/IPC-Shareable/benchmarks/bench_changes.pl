#!/usr/bin/env perl
use warnings; use strict;

use Benchmark qw(:all);
use Data::Dumper;
use IPC::Shareable;

if (@ARGV < 1){
    print "\n Need test count argument...\n\n";
    exit;
}

my $timethis = 1; 
my $timethese = 0; 
my $cmpthese = 0;

if ($timethis) {
    timethis($ARGV[0], \&shareable);
    #timethis($ARGV[0], \&sharedhash);
}

if ($timethese) {
    timethese($ARGV[0],
        {
            'shareable' => \&shareable,
#            'shared_hash' => \&sharedhash,
        },
    );
}

if ($cmpthese) {
    cmpthese($ARGV[0],
        {
            'shareable' => \&shareable,
#            'sharedhash ' => \&sharedhash,
        },
    );
}

sub default {
     return {
        a => 1,
        b => 2,
        c => [qw(1 2 3)],
        d => {z => 26, y => 25},
    };
}

sub shareable {
    work('IPC::Shareable');
}
sub sharedhash {
#    work('IPC::SharedHash');
}

sub work {
    my ($pkg) = @_;
    my $base_data = default();

    tie my %hash, $pkg, {
        key => 'hash',
        create => 1,
        destroy => 1,
    };

    %hash = %$base_data;

    for (1..100) {
        $hash{struct} = { a => [ qw(b c d) ] };
        $hash{array} = [ qw(1 2 3) ];
        $hash{b} = 3;

        delete $hash{b};

        $hash{b} = 4;
    }
    tied(%hash)->clean_up_all;

}

__END__

            Rate   shareable sharedhash 
shareable    223/s          --        -95%
sharedhash  4808/s       2058%          --

