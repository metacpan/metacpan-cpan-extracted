#!/usr/bin/perl -w
###########################################################################
#
# ScanVirus for use with Procmail
#
# Copyright (c) 2003 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
# Last Change: Sat Nov 15 18:36:03 WET 2003
#
###########################################################################

use strict;
use locale;
use MIME::Explode qw(rfc822_base64);
use Digest::MD5 qw(md5_hex);
use File::Scan;
use Net::SMTP;
use Fcntl qw(:flock);
use vars qw($VERSION);

$VERSION = '0.06';
if($ENV{HOME} =~ /^(.+)$/) { $ENV{HOME} = $1; }
if($ENV{LOGNAME} =~ /^(.+)$/) { $ENV{LOGNAME} = $1; }

#---begin_config----------------------------------------------------------

my $path          = $ENV{'HOME'};
my $scandir       = "$path/.scanvirus";
my $logsdir       = "$scandir/logs";
my $quarantine    = "$scandir/quarantine";
my $smtp_hosts    = ["smtp1.myorgnization.com", "smtp2.myorgnization.com"];
my $hostname      = "myhostname.myorgnization.com";
my $subject       = ["Returned mail: Virus alert!", "Returned mail: Suspicious file alert!"];
my $unzip         = "/usr/bin/unzip";
my $notify_sender = "yes",
my $suspicious    = "no";
my $timeout       = 180;
my $copyrg        = "(c) 2003 Henrique Dias - ScanVirus for Mail";

#---end_config------------------------------------------------------------

use constant SEEK_END => 2;
my $preserve = 0;

my $pattern = '^[\t ]+(inflating|extracting): (.+)[\n\r]';

unless(@ARGV) {
	print STDERR "Empty args\n";
	exit(0);
}

$SIG{ALRM} = sub { &logs("error.log", "Timeout"); };

&main();

#---main------------------------------------------------------------------

sub main {
	unless(-d $scandir) { mkdir($scandir, 0700) or exit_script("$!"); }
	my $id = (my $tmp_dir = "");
	do {
		$id = &generate_id();
		$tmp_dir = join("/", $scandir, $id);
	} until(!(-e $tmp_dir));
	mkdir($tmp_dir, 0700) or exit_script("$!");

	my $explode = MIME::Explode->new(
		output_dir         => $tmp_dir,
		check_content_type => 1,
		decode_subject     => 1,
		exclude_types      => ["image/gif", "image/jpeg"],
	);
	my $headers = {};
	my $line_from = <STDIN>;
	my ($from) = ($line_from =~ /^From +([^ ]+) +/o);
	eval {
		alarm($timeout);
		open(OUTPUT, ">$tmp_dir/$id.tmp") or exit_script("Can't open '$tmp_dir/$id.tmp': $!");
		$headers = $explode->parse(\*STDIN, \*OUTPUT);
		close(OUTPUT);
		alarm(0);
	};
	my %attachs = ();
	for my $msg (keys(%{$headers})) {
		if(exists($headers->{$msg}->{'content-disposition'}) &&
				exists($headers->{$msg}->{'content-disposition'}->{'filepath'})) {
			my $file = $headers->{$msg}->{'content-disposition'}->{'filepath'};
			$attachs{$file} = 0;
		}
	}
	my $result = scalar(keys(%attachs)) ? &init_scan($tmp_dir, \%attachs, $from, $ENV{LOGNAME}) : 0;
	if($result && $quarantine) {
		unless(-d $quarantine) { mkdir($quarantine, 0755) or exit_script("$!"); }
		&deliver_msg("$tmp_dir/$id.tmp", $line_from, $ENV{LOGNAME}, $quarantine);
	}
	unless($preserve) {
		if(my $res = &clean_dir($tmp_dir)) { &logs("error.log", "$res"); }
	}
	exit($result);
}

#---extract_file----------------------------------------------------------

sub extract_file {
	my $fh = shift;   
	my $size = shift; 
	my $buff = shift; 
	my $file = shift; 

	open(NEWFILE, ">$file") or return("Can't open $file: $!");
	flock(NEWFILE, LOCK_EX);
	binmode(NEWFILE);
	print NEWFILE $buff;
	while(read($fh, $buff, $size)) { print NEWFILE $buff; }
	flock(NEWFILE, LOCK_UN);
	close(NEWFILE);
	return("");
}

#---decode_b64_file---------------------------------------------------------

sub decode_b64_file {
	my $files = shift;
	my $tmp_dir = shift;
	my $file = shift;

	my ($filename) = ($file =~ /\/?([^\/]+)$/);
	my $decoded = join("/", $tmp_dir, "$filename\.eml");
	open(ENCFILE, "<$file") or return("Can't open $file: $!\n");
	open(DECFILE, join("", ">$decoded")) or return("Can't open $decoded: $!\n");
	binmode(DECFILE);
	while(<ENCFILE>) { print DECFILE rfc822_base64($_); }
	close(DECFILE);
	close(ENCFILE);

	$files->{$decoded} = "";

	return("");
}

#---mhtml_exploit---------------------------------------------------------

sub mhtml_exploit {
	my $files = shift; 
	my $tmp_dir = shift;
	my $file = shift;   

	my ($error, $buff, $filename, $size) = ("", "", "", 1024);
	open(FILE, "<$file") or return("Can't open $file: $!");
	binmode(FILE);
	while(read(FILE, $buff, $size)) {
		$buff =~ s{^MIME-Version: 1.0\x0aContent-Location: *File://([^\x0a]+)\x0aContent-Transfer-Encoding: binary\x0a\x0a}{}o or last;
		if($filename = join("/", $tmp_dir, $1)) {
			unless($error = &extract_file(\*FILE, $size, $buff, $filename)) {
				$files->{$filename} = "";
			}
			last;
		}
	}
	close(FILE);
	return($error);
}

#---unzip_file------------------------------------------------------------

sub unzip_file {
	my $files = shift;
	my $program = shift;
	my $tmp_dir = shift;
	my $file = shift;

	my $pid = open(UNZIP, "-|");
	defined($pid) or return("Cannot fork: $!");
	if($pid) {
		while(<UNZIP>) {
			if(my ($f) = (/$pattern/)[1]) {
				$f =~ s/ +$//g;
				$files->{$f} = "";
			}
		}
		close(UNZIP) or return("Unzip error: kid exited $?");
	} else {
		my @args = ("-P", "''", "-d", $tmp_dir, "-j", "-n");
		exec($program, @args, $file) or return("Can't exec program: $!");
	}
	return("");
}

#---init_scan-------------------------------------------------------------
        
sub init_scan {
	my $tmp_dir = shift;
	my $files = shift;
	my $from = shift || "unknown";
	my $user = shift || "unknown";

	my $to = join("\@", $user, $hostname);
	my %param = (max_txt_size => 2048);
	my $fs = File::Scan->new(%param);
	my %hash = ();
	$fs->set_callback(
		sub {
			my $file = shift;
			local $_ = shift;
			if(-e $unzip) {
				if(/^\x50\x4b\x03\x04/o) {
					my $error = &unzip_file(\%hash, $unzip, $tmp_dir, $file);
					&logs("error.log", $error) if($error);
					return("Zip Archive");
				}
			}
			if(/^\x4d\x49\x4d\x45\x2d\x56\x65\x72\x73\x69\x6f\x6e\x3a\x20\x31\x2e\x30\x0a/o) {
				my $error = &mhtml_exploit(\%hash, $tmp_dir, $file);
				&logs("error.log", $error) if($error);
				return("MHTML exploit");
			}
			if(/^[A-Za-z0-9\+\=\/]{76}\x0d?\x0a[A-Za-z0-9\+\=\/]{76}\x0d?\x0a/o) {
				my $error = &decode_b64_file(\%hash, $tmp_dir, $file);
				&logs("error.log", $error) if($error);
				return("Base64 encoded file");
			}
			return("");
		}
	);
	my $status = 0;
	FILE: for my $file (keys(%{$files})) {
		my $virus = $fs->scan($file);
		if(scalar(keys(%hash))) {
			$status = &init_scan($tmp_dir, \%hash, $from, $user);
			$files = {%{$files}, %hash};
			%hash = ();
			$status and return($status);
		}
		if(my $e = $fs->error) {
			$preserve = 1;
			&logs("error.log", "$e\n");
			next FILE;
		}
		unless($status) {
			my ($shortfn) = ($file =~ /([^\/]+)$/o);
			if($virus) {
				$status = 1;
				delete($files->{$file});
				my $string = join("", "\"$shortfn\" (", $virus, ")");
				&logs("virus.log", "[$string] From: $from\n");
				&virus_mail($string, $from, $to, $user);
			} else {
				&suspicious_mail($shortfn, $from, $to) if($suspicious eq "yes");
			}
		}
	}
	return($status);
}

#---deliver_msg-----------------------------------------------------------

sub deliver_msg {
	my $msg = shift;
	my $line_from = shift;
	my $user = shift;
	my $maildir = shift;

	my $mailbox = "$maildir/$user";
	open(MSG, "<$msg") or &close_app("$!");
	open(MAILBOX, ">>$mailbox") or &close_app("$!");
	flock(MAILBOX, LOCK_EX);
	seek(MAILBOX, 0, SEEK_END);
	print MAILBOX $line_from;
	while(<MSG>) { print MAILBOX $_; }
	print MAILBOX "\n"; 
	flock(MAILBOX, LOCK_UN);
	close(MAILBOX);
	close(MSG);

	chmod(0600, $mailbox);
	my ($uid, $gid) = (getpwnam($user))[2,3];
	chown($uid, $gid, $mailbox) if($uid && $gid);

	return();
}

#---clean_dir-------------------------------------------------------------

sub clean_dir {
	my $dir = shift;

	my @files = ();
	opendir(DIRECTORY, $dir) or return("Can't opendir $dir: $!");
	while(defined(my $file = readdir(DIRECTORY))) {
		next if($file =~ /^\.\.?$/);
		push(@files, "$dir/$file");
	}
	closedir(DIRECTORY);
	for my $file (@files) {
		if($file =~ /^(.+)$/s) { unlink($1) or return("Could not delete $1: $!"); }
	}
	rmdir($dir) or return("Couldn't remove dir $dir: $!");
	return();
}

#---set_addr--------------------------------------------------------------

sub set_addr {
	my $user = shift || "unknown";
	my $email = shift || "unknown";

	my $name = &getusername($user);
	return("$name <$email>");
}

#---getusername-----------------------------------------------------------

sub getusername {
	my $user = shift || return("unknown");

	my ($name) = split(/,/, (getpwnam($user))[6]);
	return($name || "unknown");
}

#---suspicious_mail-------------------------------------------------------

sub suspicious_mail {
	my $file = shift;
	my $from = shift;
	my $to = shift;
 
	my $data = <<DATATXT;
Suspicious file alert: $file

The e-mail from $from has a suspicious file attachement.

Please take a look at the suspicious file.

Thank You.

$copyrg

DATATXT
	&send_mail(
		from    => $to,
		to      => $to,
		subject => $subject->[1],
		data    => $data );
	return();
}

#---virus_mail------------------------------------------------------------

sub virus_mail {
	my $string = shift;
	my $from = shift;
	my $to = shift;
	my $user = shift;

	my $full_email = &set_addr($user, $to);

	my $data = <<DATATXT;
Virus alert: $string

You have send a e-mail to $full_email with a infected file.
Your email was not sent to its destiny.

This infected file cannot be cleaned. You should delete the file and
replace it with a clean copy.

Please try to clean the infected file. If clean fails, delete the file and
replace it with an uninfected copy and try to send the email again.

Thank You.

$copyrg

DATATXT
	my %param = (
		from    => $to,
		subject => $subject->[0],
		data    => $data );

	if($notify_sender eq "yes") {
		$param{'to'} = $from;
		$param{'bcc'} = $to;
	} else {
		$param{'to'} = $to;
	}
	&send_mail(%param);
	return();
}

#---send_mail-------------------------------------------------------------

sub send_mail {
	my $param = {  
		from    => "",
		to      => "",
		bcc     => "",
		subject => "",
		data    => "",
		@_
	};
	HOST: for my $host (@{$smtp_hosts}) {
		my $smtp = Net::SMTP->new($host);
		unless(defined($smtp)) {
			&logs("error.log", "Send mail failed for \"$host\"\n");
			next HOST;
		}
		$smtp->mail($param->{from});
		$smtp->to($param->{to});
		$smtp->bcc(split(/ *\, */, $param->{bcc})) if($param->{bcc});
		$smtp->data();
		$smtp->datasend(join("", "From: ", $param->{from}, "\n")) if($param->{from});
		$smtp->datasend(join("", "To: ", $param->{to}, "\n"));
		$smtp->datasend(join("", "Bcc: ", $param->{bcc}, "\n")) if($param->{bcc});
		$smtp->datasend(join("", "Subject: ", $param->{subject}, "\n")) if($param->{subject});
		$smtp->datasend("\n");
		$smtp->datasend($param->{data}) if($param->{data});
		$smtp->dataend();
		$smtp->quit;
		return();
	}
	return();
}

#---exit_script-----------------------------------------------------------

sub exit_script {
	my $string = shift;

	&logs("error.log", $string);
	exit(0);
}

#---generate_id-----------------------------------------------------------

sub generate_id {
	return(substr(md5_hex(time(). {}. rand(). $$. 'blah'), 0, 16));
}

#---string_date-----------------------------------------------------------

sub string_date {
	my ($sec,$min,$hour,$mday,$mon,$year) = localtime();

	return sprintf("%04d/%02d/%02d %02d:%02d:%02d",
		$year + 1900, $mon + 1, $mday, $hour, $min, $sec);
}

#---logs------------------------------------------------------------------

sub logs {
	my $logfile = shift;
	my $string = shift; 

	unless(-d $logsdir) { mkdir($logsdir, 0755) or exit(0); }
	my $today = &string_date();
	$string .= "\n" unless($string =~ /\n+$/);
	open(LOG, ">>$logsdir/$logfile") or exit(0);
	print LOG "$today $string";
	close(LOG);

	return();
}

#---end-------------------------------------------------------------------
