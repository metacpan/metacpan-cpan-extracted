use Forks::Super ':test_CA';
use Test::More tests => 2;
use strict;
use warnings;

#
# a proof-of-concept: pass strings to a child 
# and receive back the checksums
#

sub compute_checksums_in_child {
    for (1..10) {
	while (<STDIN>) {
	    s/\s+$//;
	    exit if $_ eq "__END__";
	    print "$_\\", unpack("%32C*",$_)%65535,"\n";
	}
	# <STDIN> might not be ready right away.
	sleep 1;
    }
}

my @pids = ();
my @data = (@INC,%INC,%!,0..19)[0..19];
my (@pdata, @cdata);
for (my $i=0; $i<4; $i++) {
    push @pids, 
    fork { 
	sub => \&compute_checksums_in_child, 
	child_fh => "in,out" 
    };
}
for (my $i=0; $i<@data; $i++) {
    Forks::Super::write_stdin $pids[$i%4], "$data[$i]\n";
    push @pdata, sprintf("%s\\%d\n", 
			 $data[$i], unpack("%32C*",$data[$i])%65535);
}
Forks::Super::write_stdin($_,"__END__\n") for @pids;
waitall;

foreach (@pids) {
    push @cdata, Forks::Super::read_stdout($_);
}
ok(@pdata == @cdata,                                              ### 1 ###
   "Master/slave produced ".scalar @pdata."/".scalar @cdata." lines")
 or do {
     no warnings 'uninitialized';
     print STDERR "\@pdata: @pdata[0..19]\n";
     print STDERR "--------------\n\@cdata: ",
         join ' ', map { $_ || '"undef"' . "\n" } @cdata[0..19], "\n";
};

@pdata = sort grep defined,@pdata;
@cdata = sort grep defined,@cdata;
my $pc_equal = 1;
for (my $i=0; $i<@pdata; $i++) {
    if (!defined($pdata[$i]) || !defined($cdata[$i])
	    || $pdata[$i] ne $cdata[$i]) {
	$pc_equal=0 
    }
}
ok($pc_equal, "master/slave produced same data"); ### 22 ###

##########################################################
