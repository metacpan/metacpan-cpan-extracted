# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.
#
# This file hadles URLs for FreeWRL -
# the idea is to make it possible to do without libwww-perl
# (I don't know if the emulation really works...)
# 

package VRML::URL;
use strict;
use vars qw/$has_lwp/;

# See if we have libwww-perl

unless($VRML::ENV{FREEWRL_NO_LWP})  {

	eval 'require LWP::Simple; require URI::URL;';
	if($@) {
		warn "You don't seem to have libwww-perl installed.
	Cannot get files from the net";
	} else {
		$has_lwp = 1;
	}

}

##############################################################
#
# We make it possible to save stuff 

my %saved;

{
my $ind = 0;


sub save_file {
	my $s;
	if($s = $VRML::ENV{FREEWRL_SAVE}) {
		system("cp $_[1] $s/s$ind");
		system(qq{echo "$_[0] -> $s/s$ind" >>$s/dir});
		$ind ++;
	}
	$saved{"$_[0]:$_[2]"} = $_[1];
	return $_[1];
}

sub save_text {
	my $s;
	if($s = $VRML::ENV{FREEWRL_SAVE}) {
		open FOO, ">$s/s$ind";
		print FOO $_[1];
		close FOO;
		system(qq{echo "$_[0] -> $s/s$ind" >>$s/dir});
		$ind ++;
	}
	$saved{"$_[0]:$_[2]"} = $_[1];
	return $_[1];
}

}

##############################################################
#
# Much of the VRML content is gzipped -- we have to recognize
# it in the run.

sub is_gzip {
	if($_[0] =~ /^\037\213/) {
		warn "GZIPPED content -- trying to ungzip\n";
		return 1;
	}
	return 0;
}

sub ungzip_file {
	my($file) = @_;
	if($file !~ /^[-\w~\.,\/]+$/) {
	 warn("Suspicious file name '$file' -- not gunzipping");
	 return $file;
	}
	open URLFOO,"<$file";
	my $a;
	read URLFOO, $a, 10;
	if(is_gzip($a)) {
		print "Seems to be gzipped - ungzipping\n" if $VRML::verbose::url;
		my $f = temp_file();
		system("gunzip <$file >$f") == 0
		 or die("Gunzip failed: $?");
		return $f;
	} else {
		return $file;
	}
	close URLFOO;
}

sub ungzip_text {
	if(is_gzip($_[0])) {
		my $f = temp_file();
		open URLBAR, "|gunzip >$f";
		local $SIG{PIPE} = sub { die("Gunzip pipe broke"); };
		print URLBAR $_[0];
		close URLBAR || die("bad Gunzip: $! $?");;
		open URLFOO, "<$f";
		my $t = join '',<URLFOO>;
		close URLFOO;
		return $t;
	}
	return $_[0];
}

sub get_really {
	my ($url) = @_;
	$url = URI::URL::url($url,"file:".getcwd()."/")->abs->as_string;
	print "VRML::URI really '$url'\n" if $VRML::verbose::url;
	return $url;
}

sub get_absolute {
	my($url,$as_file) = @_;
	if($saved{"$url:$as_file"}) {
		return $saved{"$url:$as_file"}
	}
	print "VRML::URI::get_absolute('$url', $as_file)\n" if $VRML::verbose::url;
	if($has_lwp) {
		use POSIX qw/getcwd/;
		$url = get_really($url);
		if(!$as_file) {
			my $r = LWP::Simple::get($url);
			if(!defined $r) {die("URL not obtained: '$url'... something is wrong\n")}
			print "VRML::URI: GOT ".length($r)." bytes\n" if $VRML::verbose::url;
			return save_text($url,ungzip_text($r), $as_file);
		} else {
			if($url =~ /^file:(.*)$/) {
				return save_file($url,ungzip_file($1), $as_file);
			} else {
				my($name) = temp_file();
				LWP::Simple::getstore($url,$name);
				return save_file($url,ungzip_file($name), $as_file);
			}
		}
	} else {
		if(-e $url) {
			$url = ungzip_file($url);
			if($as_file) {return save_file($url,$url, $as_file)}
			open FOOFILE, "<$url";
			my $str = join '',<FOOFILE>;
			close FOOFILE;
			return save_text($url,$str, $as_file);
		} else {
			die("Cannot find file '$url' -- if it is a web
address, you need to install libwww-perl \n");
		}
	}
}

sub get_relative {
	my($base,$extra,$as_file) = @_;
	$base = get_really($base);
	print "VRML::URI::get_relative('$base', '$extra', $as_file)\n" if $VRML::verbose::url;
	my $url;
	if($has_lwp) {
		$url = URI::URL::url($extra,$base)->abs->as_string;
	} else {
		$url = $base;
		$url =~ s/[^\/]+$/$extra/ or die("Can't do relativization");
	}
	my $txt = get_absolute($url,$as_file);
	return (wantarray ? ($txt, $url) : $txt);
}

# Taken from perlfaq5
{
my %temps;
BEGIN {
	use IO::File;
	use Fcntl;
	my $temp_dir = -d '/tmp' ? '/tmp' : $ENV{TMP} || $ENV{TEMP};
	my $base_name = sprintf("%s/freewrl-%d-%d-00000", $temp_dir, $$, time());
	sub temp_file {
	   my $fh = undef;
	   my $count = 0;
	   until (defined($fh) || $count > 100) {
	       $base_name =~ s/-(\d+)$/"-" . (1 + $1)/e;
	       $temps{$base_name} = 1;
	       $fh = IO::File->new($base_name, O_WRONLY|O_EXCL|O_CREAT,0644)
	   }
	   if (defined($fh)) {
	       undef $fh;
	       unlink $base_name;
	       return $base_name;
	   } else {
	       die("Couldn't make temp file");
	   }
	}
}
sub unlinktmp {
	if(!$temps{$_[0]}) {
		die("Trying to unlink nonexistent tmp");
	}
	unlink $_[0];
	delete $temps{$_[0]};
}
END {
	for(keys %temps) {
		print "unlinking '$_' (NOT)\n" if $VRML::verbose::url;
		# unlink $_;
	}
}
}

1;
