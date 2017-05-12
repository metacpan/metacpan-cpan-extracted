#!/usr/local/bin/perl

use strict;
use Mail::vpopmail;

my $HAVE_DBI;
eval { require DBI; $HAVE_DBI=1; };

my $vchkpw;
my $vpopdir = (getpwnam('vpopmail'))[7];
die "vpopmail home directory ($vpopdir) not found.\n" unless(-d $vpopdir);

if(open(MYSQL, "${vpopdir}/etc/vpopmail.mysql") && $HAVE_DBI){
	chop(my $input=<MYSQL>);
	my ($hostname,$dbport,$dbun,$dbpw,$dbname) = split(/\|/, $input);
	close MYSQL;
	
	warn "setting up for mysql as per $vpopdir/etc/vpopmail.mysql\n";

	my $dsn = "DBI:mysql:hostname=${hostname};database=${dbname}";
	$dsn .= ";port=$dbport" if($dbport);
	$vchkpw = Mail::vpopmail->new(cache => 0, debug => 0,
	                              auth_module => 'sql',
	                              dsn => $dsn, dbun => $dbun, dbpw => $dbpw);

}else{
	# check a few domains in assign for a vpasswd.
	if(open(ASSIGN, "/var/qmail/users/assign")){
		my $i = 0;
		my $found = 0;
		while(<ASSIGN>){
			last if($i == 20);
			if(/^[^:]+:[^:]+:\d+:\d+:([^:]+):-:/){
				my $dir = $1;
				if(-f "${dir}/vpasswd"){
					$found = 1;
					last;
				}
				$i++;
			}
		}
		close ASSIGN;

		if($found){
			# we are using CDB auth
			warn "setting up for CDB auth\n";
			$vchkpw = Mail::vpopmail->new(cache => 0, debug => 0);
		}else{
			# must be SQL auth
			if($HAVE_DBI){
				warn "no vpasswd files found: assuming for SQL setup.\n";
				# must get connect syntax
				print "enter SQL driver (mysql|Sybase|...) [ldap]: ";
				chop(my $driver=<STDIN>);
				$driver = 'ldap' unless($driver);
				print "enter SQL hostname [localhost]: ";
				chop(my $hostname=<STDIN>);
				$hostname='localhost' unless($hostname);
				print "enter SQL database name [vpopmail]: ";
				chop(my $dbname=<STDIN>);
				$dbname='vpopmail' unless($dbname);
				print "enter SQL username [vpopmailuser]: ";
				chop(my $dbun=<STDIN>);
				$dbun='vpopmailuser' unless($dbun);
				print "enter SQL password [vpoppasswd]: ";
				chop(my $dbpw=<STDIN>);
				$dbpw='vpoppasswd' unless($dbpw);
			
				$vchkpw = Mail::vpopmail->new(cache => 0, debug => 0,
				                              auth_module => 'sql',
				                              dsn => "DBI:${driver}:hostname=${hostname};database=${dbname}",
				                              dbun => $dbun, dbpw => $dbpw);

			}else{
				die "appears SQL auth_module in use, but can't find DBI.\n";
			}
		}
	}else{
		die "cannot open /var/qmail/users/assign: $!\n";
	}
}

my $dir = $vchkpw->userinfo(email => 'username@example.com', field => 'dir');

print "..code seems to be ok\n";
