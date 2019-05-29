#!/usr/bin/perl -I ./lib

use strict;
use GRNOC::WebService::Client;
use Data::Dumper;
use Term::ReadKey;

print "Password: ";
ReadMode('noecho');
my $password = <STDIN>;
ReadMode('normal');
chop($password);
print "\n";


my $svc = GRNOC::WebService::Client->new(
						url	=> "https://db-dev.grnoc.iu.edu/CDS/NameService.cgi",
						uid	=> "ebalas",
						passwd	=> $password
					);
print "get list of available methods:\n";
my $res= $svc->help();
if(!defined $res){
	print Dumper($svc->get_error());
}else{
	print Dumper($res);
}


print "get help for specific method:\n";
my $res= $svc->help(method_name => 'list_services');
if(!defined $res){
        print Dumper($svc->get_error());
}else{
        print Dumper($res);
}


print "call one of the methods:\n";
my $res= $svc->list_services();

if(!defined $res){
	print "res is null\n";
        print Dumper($svc->get_error());
}else{
        print Dumper($res);
}

print "This should blow up\n";
my $res= $svc->blamo(data => 'This is a test');

if(!defined $res){
	print "error:\n";
        print Dumper($svc->get_error());
}else{
        print Dumper($res);
}

