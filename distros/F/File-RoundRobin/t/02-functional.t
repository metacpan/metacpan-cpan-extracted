#!perl -T

use strict;
use warnings;

use Test::More tests => 19;

use_ok("File::RoundRobin");

{ # create a new file , write something and read it back using write()
    
    my $rrfile = File::RoundRobin->new(path => 'test.txt',size => '1k');
    
    isa_ok($rrfile,'File::RoundRobin');
    
    ok($rrfile->write("foo bar"),'Write successful') ;

	ok($rrfile->seek(-7),'seek works');
	
	my $buffer = $rrfile->read(7);
	
	is($buffer,"foo bar",'Read returned text as expected after write()');
	
	unlink('test.txt');
}

{ # create a new file , write something and read it back using print()
    
    my $rrfile = File::RoundRobin->new(path => 'test.txt',size => '1k');
    
    isa_ok($rrfile,'File::RoundRobin');
    
    ok($rrfile->print("foo bar"),'Print successful') ;

	ok($rrfile->seek(-7),'seek works');
	
	my $buffer = $rrfile->read(7);
	
	is($buffer,"foo bar",'Read returned text as expected after print()');
	
	unlink('test.txt');
}

{ # reate a new file, write to it and read back the content
    
    my $rrfile = File::RoundRobin->new(path => 'test.txt',size => '100');

    isa_ok($rrfile,'File::RoundRobin');
    
    ok($rrfile->write("A" x 60),'Write A successful') ;
	
	ok($rrfile->write("B" x 60),'Write B successful') ;
	
	$rrfile->close();
	
	$rrfile = File::RoundRobin->new(path => 'test.txt',mode => 'read');
	
	my $buffer = $rrfile->read(100);
	
	like($buffer,qr/A{30}B{60}/,'read returned text as expected');
	
	$rrfile->close();
	
	$rrfile = File::RoundRobin->new(path => 'test.txt',mode => 'append');
	
	ok($rrfile->write("C" x 60),'Write C successful') ;
		
	$rrfile->close();
	
	$rrfile = File::RoundRobin->new(path => 'test.txt',mode => 'read');
	
	$buffer = $rrfile->read(100);
	
	like($buffer,qr/B{40}C{60}/,"read returned text as expected");
	
	unlink('test.txt');
}


{ # create a new file , write something and read it back
    
    my $rrfile = File::RoundRobin->new(path => 'test.txt',size => '1k', autoflush => 1);
    
    isa_ok($rrfile,'File::RoundRobin');
    
    ok($rrfile->write("foo bar"),'Write successful') ;

	ok($rrfile->seek(-7),'seek works');
	
	$rrfile->close();
	
	$rrfile = File::RoundRobin->new(path => 'test.txt', mode => 'read');
	
	my $buffer = $rrfile->read(1);
	
	is($buffer,"f",'read returned text as expected');
	
	unlink('test.txt');
}
