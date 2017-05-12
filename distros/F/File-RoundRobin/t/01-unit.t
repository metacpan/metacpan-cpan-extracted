#!perl -T

use strict;
use warnings;

use Test::More tests => 13;

use_ok("File::RoundRobin");

{ #convert_size
    
    is(File::RoundRobin::convert_size('1000'),1000,'Simple number');
    is(File::RoundRobin::convert_size('10K'),10_000,'Kb test1');
    is(File::RoundRobin::convert_size('1.3Kb'),1_300,'Kb test2');
    is(File::RoundRobin::convert_size('10M'),10_000_000,'Mb test');
    is(File::RoundRobin::convert_size('12Gb'),12_000_000_000,'Gb test');
    
    eval {
        File::RoundRobin::convert_size('asdf');
    };
    like($@,qr/^Broke size format. See pod for accepted formats/,'Fails for broken size');
    
}


{ #open new file
    
    my ($fh,$size,$start_point) = File::RoundRobin::open_file(
                                                path => "test.txt",
                                                mode => 'new',
                                                size => '1000'
                                    );
    
    ok(defined $fh,"File handle created");
    is($size,1000,"Size ok");
    is($start_point,12,"Start point ok");
    
    close($fh);
    
    open($fh,"<",'test.txt');
    
    local $/ = "\x00";
    
    my $version = <$fh>;
	my $read_size = <$fh>;
	my $read_start_point = <$fh>;
    
    is($version,"1\x00",'File version 1');
	is($read_size,"1000\x00",'File size 1000');
	is($read_start_point,"0012\x00",'File start point correct');
    
    unlink("text.txt");
           
}

