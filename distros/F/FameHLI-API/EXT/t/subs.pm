;#=============================================================================
;#	File:	subs.pm
;#	Author:	Dave Oberholtzer, (daveo@obernet.com)
;#			Copyright (c)2005, David Oberholtzer
;#	Date:	2001/03/23
;#	Use:	Testing subroutines for:
;#				FameHLI::API functions and
;#				FameHLI::API::EXT functions
;#=============================================================================
use		FileHandle;

;#=============================================================================
;#		N U M   D A T A
;#=============================================================================
;#		Standardized data for numeric (and boolean) testing.
;#		(Note that boolean will be (T, T, F, T, T, T, T, T).)
;#=============================================================================
sub		NumData {
		return(-2.2, -1.1, 0, 1.1, 2.2, 3.3, 4.4, 5.5);
}

;#=============================================================================
;#		P R E C   D A T A
;#=============================================================================
;#
;#=============================================================================
sub		PrecData {
		return(NumData());
}

;#=============================================================================
;#		B O O L   D A T A
;#=============================================================================
;#
;#=============================================================================
sub		BoolData {
		return(NumData());
}


;#=============================================================================
;#		D A T E   D A T A
;#=============================================================================
;#		Standardized data for date (and string) testing.
;#		(Note that strings will simply be the string of digits.)
;#=============================================================================
sub		DateData {
		return(38000, 38001, 38002, 38003, 38100, 38200, 38300);
}


;#=============================================================================
;#		S T R I N G   D A T A
;#=============================================================================
;#
;#=============================================================================
sub		StringData {
		return(DateData());
}


;#=============================================================================
;#		StartTest
;#=============================================================================
sub		StartTest {
my		$name	=	shift;

my		$fh = new FileHandle(">${name}.log");
		$name .= " .......................";
		$name = substr($name, 0, 20) . " ";
;#		printf("%s", $name);
		printf($fh "File Test: %s\n", $name);
		return($fh);
}

;#=============================================================================
;#		GetVars
;#=============================================================================
sub		GetVars {
my		$vars;

		$vars->{hostname}	=	"localhost";
		$vars->{service}	=	"mcadbs";
		$vars->{username}	=	"";
		$vars->{password}	=	"";
		$vars->{siteserver}	=	"mcaserv\@localhost";

		@dirs = ('./.', './..', './../..', './../../..');
		foreach (@dirs) {
			if (-f "$_/PWD") {
				open (PWD, "$_/PWD") or die("$_/PWD is not readable: $!");
				while (<PWD>) {
					chomp;
					1 while s/^\s//;
					1 while s/\s$//;
					next if /^\#/;
					next if /^$/;
					next if /^;/;
my					($l,$r) = split(/=/);
					$l =~ tr/A-Z/a-z/;
					$vars->{$l} = $r;
				}
				printf("Service:%s\@%s, User:%s, Pwd:%s, SiteServer:%s\n",
						$vars->{service},
						$vars->{hostname},
						$vars->{username},
						$vars->{password},
						$vars->{siteserver});
				close(PWD);
				last;
			}
		}
		return($vars);
}

;#=============================================================================
;#		ShowResults
;#=============================================================================
sub		ShowResults {
my		$log		=	shift;
my		$level		=	shift;
my		$expect		=	shift;
my		$name		=	shift;
my		$rc			=	shift;
my		@printargs	=	@_;
my		$i;

		return if ($rc == 999);

		$name .= " .......................";
		$name = substr($name, 0, 20) . " ";
		++$test::num;
		printf($log "%3d) %s", $test::num, $name);

		if ($rc ne $expect) {
			if ($level eq 1) {
				$err++;
				print($log "failed\n");
				printf($log "\tResponse: '%s'\n", 
					FameHLI::API::EXT::ErrDesc($rc));
				printf($log "\tExpected: '%s'\n", 
					FameHLI::API::EXT::ErrDesc($expect));
			} elsif ($level eq 2) {
				$warn++;
				print($log "failed (Probably not important)\n");
				printf($log "\t=== %s\n", 
					FameHLI::API::EXT::ErrDesc($rc));
			} else {
				printf($log "ignored: %s\n", 
					FameHLI::API::EXT::ErrDesc($rc));
			}
			print($log "failed\n");
			print("not ");		# < < = = = = = = N O T E = = = = < <
			print($log "not ");		# < < = = = = = = N O T E = = = = < <
		} else {
			print($log "ok");
			if (@printargs) {
				for ($i=0; $i<=$#printargs; $i++) {
					if (!defined($printargs[$i])) {
						$printargs[$i] = "<UNDEF>";
					} elsif ($printargs[$i] eq "0") {
;#						nada...
					} elsif ($printargs[$i]) {
;#						nada...
					} else {
						$printargs[$i] = "<NULL>";
					}
				}
				print($log " (");
				printf($log @printargs);
				print($log ")");
			}
			print($log "\n");
		}
		print("ok $test::num\n");
		print($log "ok $test::num\n");
}

1;
