use strict;
use DB_File;

my %myhash;

tie %myhash, "DB_File", glob("cmusyldict.db"), O_CREAT|O_RDWR, 0666, $DB_HASH || die "Can't tie:  ",$!;
open(IF,"cmudict.0.6d.syl") || die "cmudict.0.6d.syl : ",$!;
while (<IF>) {
	chop;
	next if (/^\#/);
	my ($wd,$syls) = split(/\s+/,$_,2);
	$myhash{$wd} = $syls;
}
close(IF);
untie %myhash;
