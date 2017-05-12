#!perl

use strict;
use warnings;

use Test::More tests => 14;

use_ok("File::RoundRobin");

{ # print & getc & read tests
    
    local *FH;
 	tie *FH, 'File::RoundRobin', path => 'test.txt',size => '1k';

    my $fh = *FH;

    print $fh "foo bar";

	close($fh);
	
	tie *FH, 'File::RoundRobin', path => 'test.txt',mode => 'read';
	
	$fh = *FH;
	
	my $char = getc($fh);
	is($char,'f','getc works');
	
	my $buffer;	
	my $bytes = read($fh,$buffer,10);
	
	is($buffer,"oo bar",'read returned text as expected');
	is($bytes,6,'length returned ok');
	
	unlink('test.txt');
}


{ # print & readline

	local $/ = undef;

    local *FH;
 	tie *FH, 'File::RoundRobin', path => 'test.txt',size => '1000';

    my $fh = *FH;

    print $fh <DATA>;

	close($fh);
	
	tie *FH, 'File::RoundRobin', path => 'test.txt',mode => 'read';
	
	$fh = *FH;
	
	my $line = readline($fh);
	is($line,"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n",'readline 1 ok');
	$line = readline($fh);
	is($line,"Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n",'readline 2 ok');
	$line = readline($fh);
	is($line,"Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\n",'readline 3 ok');
	$line = readline($fh);
	is($line,"Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n",'readline 4 ok');
	
	$line = readline($fh);
	is($line,undef,'reached end of file');
	
	unlink('test.txt');
}


{ # print & readline again

	local $/ = undef;
	seek(DATA,0,0);

    local *FH;
 	tie *FH, 'File::RoundRobin', path => 'test.txt',size => '111';

    my $fh = *FH;

    print $fh <DATA>;

	close($fh);
	
	tie *FH, 'File::RoundRobin', path => 'test.txt',mode => 'read';
	
	$fh = *FH;
	
	my $line = readline($fh);
	is($line,"Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n",'Another readline test');
	
	$line = readline($fh);
	is($line,undef,'reached end of file');
	
	my $buffer;
	read($fh,$buffer,10);
	
	isnt(defined $buffer,'Cannot read beyond the end of line');
	
	unlink('test.txt');
}

{ # read beyond the end of line

	local $/ = undef;
	seek(DATA,0,0);

    local *FH;
 	tie *FH, 'File::RoundRobin', path => 'test.txt',size => '111';

    my $fh = *FH;

    print $fh <DATA>;

	close($fh);
	
	tie *FH, 'File::RoundRobin', path => 'test.txt',mode => 'read';
	
	$fh = *FH;
	
	my $buffer;
	read(FH,$buffer,300);
	is($buffer,"Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n",'Another readline test');
	
	read($fh,$buffer,10);
	isnt(defined $buffer,'Cannot read beyond the end of line');
	
	unlink('test.txt');
}


__DATA__
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
