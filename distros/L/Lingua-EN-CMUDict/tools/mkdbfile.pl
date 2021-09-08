use strict;
use DB_File;

my $file = shift;

my %myhash;

tie %myhash, "DB_File", glob("cmusyldict.db"), O_CREAT|O_RDWR, 0666, $DB_HASH || die "Can't tie:  ",$!;
open(IF,$file) || die $file," : ",$!;
while (<IF>) {
	chop;
	next if (/^\#/);
	my ($wd,$syls) = split(/\s+/,$_,2);
	$myhash{uc($wd)} = $syls;
}
close(IF);
untie %myhash;
