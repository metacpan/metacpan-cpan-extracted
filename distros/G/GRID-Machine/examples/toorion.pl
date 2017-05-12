#!/usr/local/bin/perl -w
use strict;
use Net::SSH::Perl;
my $host = 'localhost';
my $user = 'casiano';
my $pass = '........';
my $cmd = 'uname -a';
my $ssh = Net::SSH::Perl->new($host, protocol=>'1,2', interactive=>1);
$ssh->login($user);
my($stdout, $stderr, $exit) = $ssh->cmd($cmd);
print $stdout;
print $stderr;
