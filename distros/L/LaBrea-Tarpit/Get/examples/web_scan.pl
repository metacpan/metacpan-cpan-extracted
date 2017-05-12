#!/usr/bin/perl
#
# web_scan.pl
#
# version 1.11, 11-6-04, michael@bizsystems.com
# GPL'd, see Copyright notice in the package README file
#

use strict;
#use diagnostics;
my $AUTO_UPDATE;
use LaBrea::Tarpit::Get qw(
	short_response
	make_line
	not_day
	not_hour
	auto_update
);
use LaBrea::NetIO qw(
	reap_kids
);
use LaBrea::Tarpit::Util qw(
	ex_open
	close_file
);

####################################################
#### set this or comment it out for ################
#### AUTO_UPDATE of your 'other_sites.txt' file ####
####################################################

#$AUTO_UPDATE = 'http://scans.bizsystems.net/other_sites.txt';

unless (@ARGV >= 2) {
  print STDERR <<'EOF';

Usage: web_scan.pl in_file out_file [timeout] [kids]

  in_file	=> dir/filename of URL's to scan
  out_file	=> dir/filename of stat cache
		   (must be writable by this task)
  timeout	=> optional time to wait for 
		   web server response, default 60s
  kids		=> maximum number of forked children
		   doing this job, default 5

Input file format starts at the left margin and
ends with the server side executable file name.

All other lines are considered comments
trailing comments may follow the URL

http://www.foo.com/file.cgi
http://www.foo.com:8080/file.pl

EOF
  exit;
}

my $in	= $ARGV[0];
my $out	= $ARGV[1];
my $to	= $ARGV[2] || 60;
my $max_kids= $ARGV[3] || 5;

unless ( -e $in && -r $in && -f $in ) {
  print STDERR <<EOF;

  input '$in' not readable,
  does not exist or not a plain file

EOF
  exit;
}

my $dir = ( $out =~ m|(.*/)| )
	? $1 : './';

unless ( -e $dir && -d $dir && -w $dir ) {
  print STDERR <<EOF;

  '$dir' not a directory,
  not writable or does not exist

EOF
  exit;
}

if ( -e $out && ! -f $out && -w $out ) {
  print STDERR <<EOF;

  output '$out
  not writable or not a plain file

EOF
  exit;
}

######### Error Checks Complete #############

if ( -e $out ) {				# if output file exists
  exit unless not_hour($in);			# only run once per hour
}						# else run now

my $cur_ver = ($AUTO_UPDATE && not_day($in))	# flag for 'other_sites.txt' update
	? 1 : 0;

my $real_out = $out;
$out .= '.tmp';

local *IN;

unless (open(IN,$in)) {
  print STDERR <<EOF;

  could not open $in

EOF
  exit;
}

if ( $cur_ver ) {		# if current version is old
  while (<IN>) {			# get version number
    next unless $_ =~ /VERSION\s*=\s*(\d+)/;
    $cur_ver = $1;
    last;
  }
}

local (*LOCK,*OUT);	# truncate, blocking, perms 0664
ex_open(*LOCK,*OUT,$out,-1,0,0113);	# truncate any old files lying around
close_file(*LOCK,*OUT);

my %kids;
foreach (<IN>) {
  next unless $_ =~ m|^(http://[^\s]+)|i;
  my $url = $1;

  my $pid = fork;
  unless ($pid) {
# child
    close IN;		# child does not need file
    my (%response,%content);
    my $rv = short_response($url,\%response,\%content);
    local $SIG{ALRM} = sub {
      die "child timeout $out";
    };
    eval {
      alarm 15;		# that's a long time to wait for file open
# open for append, blocking, perms 0664
      ex_open(*LOCK,*OUT,$out,1,0,0113) || die "child failed to open $out";
      alarm 0;
    };
    print OUT make_line($url,$rv,\%content), "\n";
    close_file(*LOCK,*OUT);
    exit 0;
  }

  else {	# PARENT
# don't start too many kids
    $kids{$pid} = 1;
    until (reap_kids(\%kids) < $max_kids) { sleep 1 }
  }
}

while (1) {
  last unless reap_kids(\%kids);	# terminate when all kids are done
  sleep 1;
}

rename $out, $real_out;

if ($cur_ver ) {	# conditionally update 'other_sites.txt' daily
  my $rv = auto_update($AUTO_UPDATE,$in,$cur_ver);
  print STDERR $rv if $rv;
}
