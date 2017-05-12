#=============================================================================
#	File:	subs.pm
#	Author:	Dave Oberholtzer, (daveo@obernet.com)
#			Copyright (c)2005, David Oberholtzer
#	Date:	2001/03/23
#	Use:	Testing file for FameHLI::API functions
#	Mod:	
#=============================================================================
use		FileHandle;
use		FameHLI::API::EXT;

my		$NA		=	"NA";
my		$NC		=	"NC";
my		$ND		=	"ND";

#=============================================================================
#		N U M   D A T A
#=============================================================================
#		Standardized data for numeric (and boolean) testing.
#=============================================================================
sub		NumData {
		return(-2.2, -1.1, \$ND, 0, \$NC, 1.1, 2.2, 3.3, 4.4, 5.5, \$NA);
}


;#=============================================================================
;#		D A T E   D A T A
;#=============================================================================
;#		Standardized data for date (and string) testing.
;#=============================================================================
sub		DateData {
		return(38000, 38001, 38002, 38003,
				\$NA, 38100, \$NC, 38200, \$ND, 38300);
}


;#=============================================================================
;#		N A   D A T A
;#=============================================================================
;#		Standardized data for date (and string) testing.
;#=============================================================================
sub		NAData {
		return(\$NA, \$NA, \$NA, \$NA);
}


;#=============================================================================
;#		N C   D A T A
;#=============================================================================
;#		Standardized data for date (and string) testing.
;#=============================================================================
sub		NCData {
		return(\$NC, \$NC, \$NC, \$NC);
}


;#=============================================================================
;#		N D   D A T A
;#=============================================================================
;#		Standardized data for date (and string) testing.
;#=============================================================================
sub		NDData {
		return(\$ND, \$ND, \$ND, \$ND);
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
my		$other = select($fh);
		$| = 1;
		select($other);
		return($fh);
}

;#=============================================================================
;#		GetVars
;#=============================================================================
sub		GetVars {
my		$vars;

		$vars->{hostname}	=	"none";
		$vars->{service}	=	"none";
		$vars->{username}	=	"";
		$vars->{password}	=	"";
		$vars->{siteserver}	=	"none";
		$vars->{famedb}		=	"none";
		$vars->{fameseries}	=	"none";
		$vars->{fameissuer}	=	"none";
		$vars->{spindex}	=	"none";
		$vars->{spindate}	=	"none";

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
				printf($log "\t=== %s\n", FameHLI::API::EXT::ErrDesc($rc));
			} else {
				printf($log "ignored: %s\n", FameHLI::API::EXT::ErrDesc($rc));
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


;#=============================================================================
;#		InteractiveFame
;#=============================================================================
sub		InteractiveFame {
my		$fametest = "./fametest.out";
		open(IN, $fametest) or die("'$fametest' isn't there.\n");
my		$val = <IN>;
		chomp($val);
		return($val eq "WORKED");
}

;#=============================================================================
;#		SkipResults
;#=============================================================================
sub		SkipResults {
my		$log		=	shift;
my		$level		=	shift;
my		$expect		=	shift;
my		$name		=	shift;
my		$rc			=	shift;
my		@printargs	=	@_;
my		$i;

		$name .= " .......................";
		$name = substr($name, 0, 20) . " ";
		++$test::num;
		printf($log "%3d) %s", $test::num, $name);

		print($log "ok # Skip ");
		print("ok $test::num # Skip ");

		if (@printargs) {
			for ($i=0; $i<=$#printargs; $i++) {
				if (!defined($printargs[$i])) {
					$printargs[$i] = "<UNDEF>";
				} elsif ($printargs[$i] eq "0") {
;#					nada...
				} elsif ($printargs[$i]) {
;#					nada...
				} else {
					$printargs[$i] = "<NULL>";
				}
			}
			print($log " (");
			printf($log @printargs);
			print($log ")");

			printf(@printargs);
		}
		print($log "\n");
		print("\n");

		print($log "Skipped $test::num\n");
}

1;
