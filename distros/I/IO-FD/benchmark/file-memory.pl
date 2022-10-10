use v5.36;

use BSD::Resource;

use IO::FD;
#Fork 2 children. First does file handles, second does file descriptors

my $n=2000;
say "Creating $n file handles/descriptors";
say "Start maxrss (kB): ". getrusage->maxrss/1024;

{

        say "\nPerl file handles";
        my $total=0;
        my @fh;
        #Duplicate a large number of times
        for(1..$n){
                my $fh;
                my $start=getrusage->maxrss;
		open $fh, ">&STDOUT";
		#open $fh, ">temp";
                my $end=getrusage->maxrss;
                #say "Delta Memory usage: ".
                $total+=($end-$start);
                push @fh,$fh;
        }
        say "Bytes: $total, per handle: ". ($total/$n);
	#say "max Rss (kB): ". getrusage->maxrss/1024;
}

{
	say "\nIO::FD";
	my $total=0;
	my @fh;
	#Duplicate a large number of times
	for(1..$n){
		my $start=getrusage->maxrss;
		my $fh=IO::FD::dup(fileno STDOUT);
		my $end=getrusage->maxrss;
		#say "Delta Memory usage: ". (
		$total+=($end-$start);
		push @fh,$fh;
	}
	say "Bytes: $total, per fd: ". ($total/$n);


}
say "\nEnd maxrss (kB): ". getrusage->maxrss/1024;
