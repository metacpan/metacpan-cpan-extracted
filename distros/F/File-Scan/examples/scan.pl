#!/usr/bin/perl -w
#############################################################################
#
# Virus Scanner
# Last Change: Tue Apr 27 16:08:18 WEST 2004
#
# Copyright (c) 2005 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#############################################################################

use strict;
use File::Scan;
use MIME::Base64 qw(decode_base64);
use Getopt::Long();
use Benchmark;

my $VERSION = "0.17";

my $infected = 0;
my $objects = 0;
my $skipped = 0;
my $suspicious = 0;

my $EXTENSION = "";
my $CP_DIR = "";
my $MV_DIR = "";
my $MK_DIR = 0;
my $DELETE = 0;
my $FOLLOW = 0;
my $QUIET = 0;
my $MAXTXTSIZE = 0;
my $MAXBINSIZE = 0;
my $UNZIP_PROG = "/usr/bin/unzip";
my $TMP_DIR = "/tmp";

my $pattern = '^[\t ]+(inflating|extracting): (.+)[\n\r]';

my %skipcodes = (
	1 => "file not vulnerable",
	2 => "file has zero size",
	3 => "the size of file is small",
	4 => "file size exceed the maximum text size",
	5 => "file size exceed the maximum binary size",
);

my $opt = {};
Getopt::Long::GetOptions($opt,
	"help"         => \&usage,
	"version"      => \&print_version,
	"ext=s"        => \$EXTENSION,
	"cp=s"         => \$CP_DIR,
	"mv=s"         => \$MV_DIR,
	"mkdir=s"      => \$MK_DIR,
	"unzip=s"      => \$UNZIP_PROG,
	"tmp=s"        => \$TMP_DIR,
	"del"          => sub { $DELETE = 1; },
	"follow"       => sub { $FOLLOW = 1; },
	"quiet"        => sub { $QUIET = 1; },
	"maxtxtsize=i" => \$MAXTXTSIZE,
	"maxbinsize=i" => \$MAXBINSIZE,
) or die(short_usage());

&main();

#---main---------------------------------------------------------------------

sub main {

	scalar(@ARGV) or die(short_usage());
	my $start = new Benchmark;
	&check_path(\@ARGV);
	my $finish = new Benchmark;
	my $diff = timediff($finish, $start);
	my $strtime = timestr($diff);

	print <<ENDREPORT;

Results of virus scanning:
--------------------------
 Module Version: $File::Scan::VERSION
Objects scanned: $objects 
        Skipped: $skipped
     Suspicious: $suspicious
       Infected: $infected
      Scan Time: $strtime

ENDREPORT

        exit(0);
}

#---display_msg-------------------------------------------------------------

sub display_msg {
	my $file = shift;
	my $virus = shift;

	$objects++;
	my $string = "No viruses were found";
	if($virus) {
		$infected++;
		$string = "Infection: $virus";
	}
	print "$file $string\n" if(!$QUIET || $virus);
	return();
}

#---check_path--------------------------------------------------------------

sub check_path {
	my $argv = shift;

	my @args = ();
	push(@args, "max_txt_size", $MAXTXTSIZE) if($MAXTXTSIZE);
	push(@args, "max_bin_size", $MAXBINSIZE) if($MAXBINSIZE);

	my $fs = File::Scan->new(
		extension => $EXTENSION,
		copy      => $CP_DIR,
		mkdir     => oct($MK_DIR),
		move      => $MV_DIR,
		delete    => $DELETE,
		@args);
	$fs->set_callback(
		sub {
			my $file = shift;
			local $_ = shift;
			if($UNZIP_PROG) {
				if(/^\x50\x4b\x03\x04/o) {
					# Extract compressed files in a ZIP archive
					my $files = &unzip_file($UNZIP_PROG, $TMP_DIR, $file);
					for my $f (@{$files}) {
						&check($fs, $f);
						unlink($f);
					}
					return("ZIP archive");
				}
			}
			if(/^MIME-Version: 1\.0\x0a/o) {
				# MHTML exploit
				if(my $insidefile = &mhtml_exploit($file)) {
					&check($fs, $insidefile);
					unlink($insidefile);
				}
				return("MHTML exploit");
			}
			if(/^[A-Za-z0-9\+\=\/]{76}\x0d?\x0a[A-Za-z0-9\+\=\/]{76}\x0d?\x0a/o) {
				# Base64 encoded file
				if(my $decodedfile = &decode_b64_file($TMP_DIR, $file)) {
					&check($fs, $decodedfile);
					unlink($decodedfile);
				}
				return("Base64 encoded file");
			}
			return("");
		}
	);
	for my $p (@{$argv}) {
		if(-d $p) {
			($p eq "/") or $p =~ s{\/+$}{}g;
			&dir_handle($fs, $p);
		} elsif(-e $p) {
			&check($fs, $p);
		} else {
			print "No such file or directory: $p\n";
			exit(0);
		}
	}
	return();
}

#---extract_file------------------------------------------------------------

sub extract_file {
	my $fh = shift;
	my $size = shift;
	my $buff = shift;
	my $file = shift;

	my $total = length($buff);
	open(NEWFILE, ">$file") or die("Can't open $file: $!\n");
	binmode(NEWFILE);
	print NEWFILE $buff;
	while(read($fh, $buff, $size)) {
		print NEWFILE $buff;
		if($MAXBINSIZE) {
			$total += $size;
			last if($total > $MAXBINSIZE*1024);
		}
	}
	close(NEWFILE);
	return();
}

#---decode_b64_file---------------------------------------------------------

sub decode_b64_file {
	my $tmp = shift;
	my $file = shift;

	my ($filename) = ($file =~ /\/?([^\/]+)$/);
	my $decoded = join("/", $tmp, "$filename\.eml");
	open(ENCFILE, "<$file") or die("Can't open $file to read: $!\n");
	open(DECFILE, join("", ">$decoded")) or die("Can't open $decoded to write: $!\n");
	binmode(DECFILE);
	while(<ENCFILE>) { print DECFILE decode_base64($_); }
	close(DECFILE);
	close(ENCFILE);  

	return($decoded);
}

#---mhtml_exploit-----------------------------------------------------------

sub mhtml_exploit {
	my $file = shift;

	my ($buff, $filename) = ("", "");
	my $size = 1024;
	open(FILE, "<$file") or die("Can't open $file: $!\n");
	binmode(FILE);
	while(read(FILE, $buff, $size)) {
		$buff =~ s{^MIME-Version: 1.0\x0aContent-Location: *File://([^\x0a]+)\x0aContent-Transfer-Encoding: binary\x0a\x0a}{}o or last;
		if($filename = join("/", $TMP_DIR, $1)) {
			&extract_file(\*FILE, $size, $buff, $filename);
			last;
		}
	}
	close(FILE);
	return($filename);
}

#---unzip_file--------------------------------------------------------------

sub unzip_file {
	my $program = shift;
	my $tmp_dir = shift;
	my $file = shift;   

	my $pid = open(UNZIP, "-|");
	defined($pid) or die("Cannot fork: $!");
	my @files = ();
	if($pid) {
		while(<UNZIP>) {
			if(my ($f) = (/$pattern/)[1]) {
				$f =~ s/ +$//g;
				push(@files, $f);
			}
		}
		close(UNZIP) or warn("unzip error: kid exited $?");
	} else {
		my @args = ("-P", "''", "-d", $tmp_dir, "-j", "-n");
		exec($program, @args, $file) or die("Can't exec program: $!");
	}
	return(\@files);
}

#---dir_handle--------------------------------------------------------------

sub dir_handle {
	my $fs = shift;
	my $dir_path = shift;

	unless(-r $dir_path) {
		print "Permission denied at $dir_path\n";
		return();
	}
	opendir(DIRHANDLE, $dir_path) or die("can't opendir $dir_path: $!");
	for my $item (readdir(DIRHANDLE)) {
		($item =~ /^\.+$/o) and next;
		$dir_path eq "/" and $dir_path = "";
		my $f = "$dir_path/$item";
		next if(!$FOLLOW && (-l $f));
		(-d $f) ? &dir_handle($fs, $f) : &check($fs, $f);
	}
	closedir(DIRHANDLE);
	return();
}

#---check-------------------------------------------------------------------

sub check {
	my $fs = shift;
	my $file = shift;

	my $res = $fs->scan($file);
	if(my $e = $fs->error) { print"$e\n"; }
	elsif(my $c = $fs->skipped) {
		$skipped++;
		$QUIET or print "$file File Skipped (", $skipcodes{$c}, ")\n";
	} elsif($fs->suspicious) {
		$suspicious++;
		print "$file Suspicious file\n";
	} elsif(my $r = $fs->callback) {
		print "$file $r\n";
	} else { &display_msg($file, $res); }
	return($res);
}

#---short_usage-------------------------------------------------------------

sub short_usage {

	return(<<"EOUSAGE");
usage: $0 [options] file|directory

  --ext=string_extension
  --cp=/path/to/dir
  --mv=/path/to/dir
  --mkdir=octal_number
  --del
  --follow
  --quiet
  --maxtxtsize=size
  --maxbinsize=size
  --unzip=/path/to/program
  --tmp=/path/to/dir
  --version
  --help
        
EOUSAGE

}

#---print_version-----------------------------------------------------------

sub print_version {
	print STDERR <<"VERSION";

version $VERSION

Copyright 2003, Henrique Dias

VERSION
	exit 1;
}

#---usage-------------------------------------------------------------------

sub usage {
	print STDERR <<"USAGE";
Usage: $0 [options] file|directory

Possible options are:

  --ext=<string>        add the specified extension to the infected file

  --mv=<dir>            move the infected file to the specified directory

  --cp=<dir>            copy the infected file to the specified directory

  --mkdir=octal_number  make the specified directories (ex: 0755)

  --del                 delete the infected file

  --follow              follow symbolic links

  --quiet               don't report files that are clean or skipped

  --maxtxtsize=<size>   scan only the text file if the file size is less
                        then maxtxtsize (size in kbytes)
 
  --maxbinsize=<size>   scan only the binary file if the file size is less
                        then maxbinsize (size in kbytes)

  --unzip=<string>      path to unzip program

  --tmp=<string>        path to temporary directory

  --version             print version number

  --help                print this message and exit

USAGE
	exit 1;
}

#---end---------------------------------------------------------------------
