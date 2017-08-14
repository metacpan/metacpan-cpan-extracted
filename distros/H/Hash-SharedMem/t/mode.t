use warnings;
use strict;

use Errno 1.00 qw(ENOENT EEXIST);
use File::Temp 0.22 qw(tempdir);
use Test::More tests => 2323;

BEGIN { use_ok "Hash::SharedMem", qw(
	is_shash
	shash_open
	shash_is_readable shash_is_writable shash_mode
	shash_exists shash_length shash_get
	shash_set shash_gset shash_cset
	shash_occupied shash_count shash_size
	shash_key_min shash_key_max
	shash_key_ge shash_key_gt shash_key_le shash_key_lt
	shash_keys_array shash_keys_hash
	shash_group_get_hash
	shash_snapshot shash_is_snapshot
	shash_idle shash_tidy
	shash_tally_get shash_tally_zero shash_tally_gzero
); }
require_ok "Hash::SharedMem::Handle";

my $enoent = do { local $! = ENOENT; "$!" };
my $eexist = do { local $! = EEXIST; "$!" };

my $tmpdir = tempdir(CLEANUP => 1);
my $i = 0;

for(my $v = ord(" "); $v <= ord("~"); $v++) {
	my $c = chr($v);
	next if $c =~ /\A[rwce]\z/;
	eval { shash_open("$tmpdir/t".$i++, $c) };
	like $@, qr/\Aunknown open mode flag `\Q$c\E' at /;
}
for(my $v = 0; $v <= 0x200; $v++) {
	my $c = chr($v);
	next if $c =~ /\A[ -~]\z/;
	eval { shash_open("$tmpdir/t".$i++, $c) };
	like $@, qr/\Aunknown open mode flag at /;
}
foreach my $c (qw(r w c e)) {
	eval { shash_open("$tmpdir/t".$i++, $c.$c) };
	like $@, qr/\Aduplicate open mode flag `$c' at /;
	eval { shash_open("$tmpdir/t".$i++, $c."r".$c) };
	like $@, qr/\Aduplicate open mode flag `$c' at /;
}

sub test_shash_ops($$$) {
	my($sh, $name, $iomode) = @_;
	ok !shash_is_snapshot($sh);
	is shash_is_readable($sh), scalar($iomode =~ /r/);
	is shash_is_writable($sh), scalar($iomode =~ /w/);
	is shash_mode($sh), $iomode;
	my $v = eval { shash_exists($sh, $i++) };
	if($iomode =~ /r/) {
		is $@, "";
		is $v, !!0;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_length($sh, $i++) };
	if($iomode =~ /r/) {
		is $@, "";
		is $v, undef;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_get($sh, $i++) };
	if($iomode =~ /r/) {
		is $@, "";
		is $v, undef;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	eval { shash_set($sh, $i++, $i++) };
	if($iomode =~ /w/) {
		is $@, "";
	} else {
		like $@, qr#\Acan't\ write\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unwritable\ mode\ #x;
	}
	$v = eval { shash_gset($sh, $i++, $i++) };
	if($iomode =~ /rw/) {
		is $@, "";
		is $v, undef;
	} elsif($iomode =~ /r/) {
		like $@, qr#\Acan't\ update\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unwritable\ mode\ #x;
	} else {
		like $@, qr#\Acan't\ update\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_cset($sh, $i++, $i++, $i++) };
	if($iomode =~ /rw/) {
		is $@, "";
		is $v, !!0;
	} elsif($iomode =~ /r/) {
		like $@, qr#\Acan't\ update\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unwritable\ mode\ #x;
	} else {
		like $@, qr#\Acan't\ update\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	my $occupied = $iomode =~ /w/;
	$v = eval { shash_occupied($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		is $v, !!$occupied;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_count($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		like $v, $occupied ? qr/\A[1-9][0-9]*\z/ : qr/\A0\z/;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_size($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		like $v, qr/\A[0-9]+\z/;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_key_min($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		if($occupied) {
			like $v, qr/\A[0-9]+\z/;
		} else {
			is $v, undef;
		}
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_key_max($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		if($occupied) {
			like $v, qr/\A[0-9]+\z/;
		} else {
			is $v, undef;
		}
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_key_ge($sh, "-") };
	if($iomode =~ /r/) {
		is $@, "";
		if($occupied) {
			like $v, qr/\A[0-9]+\z/;
		} else {
			is $v, undef;
		}
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_key_gt($sh, "-") };
	if($iomode =~ /r/) {
		is $@, "";
		if($occupied) {
			like $v, qr/\A[0-9]+\z/;
		} else {
			is $v, undef;
		}
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_key_le($sh, "~") };
	if($iomode =~ /r/) {
		is $@, "";
		if($occupied) {
			like $v, qr/\A[0-9]+\z/;
		} else {
			is $v, undef;
		}
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_key_lt($sh, "~") };
	if($iomode =~ /r/) {
		is $@, "";
		if($occupied) {
			like $v, qr/\A[0-9]+\z/;
		} else {
			is $v, undef;
		}
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_keys_array($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		is ref($v), "ARRAY";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_keys_hash($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		is ref($v), "HASH";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_group_get_hash($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		is ref($v), "HASH";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	eval { shash_idle($sh) };
	is $@, "";
	eval { shash_tidy($sh) };
	if($iomode =~ /w/) {
		is $@, "";
	} else {
		like $@, qr#\Acan't\ tidy\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unwritable\ mode\ #x;
	}
	$v = eval { shash_tally_get($sh) };
	is $@, "";
	is ref($v), "HASH";
	$v = eval { shash_tally_zero($sh) };
	is $@, "";
	is $v, undef;
	$v = eval { shash_tally_gzero($sh) };
	is $@, "";
	is ref($v), "HASH";
	my %sh;
	tie %sh, "Hash::SharedMem::Handle", $sh;
	ok is_shash(tied(%sh));
	ok tied(%sh) == $sh;
	$v = eval { exists($sh{$i++}) };
	if($iomode =~ /r/) {
		is $@, "";
		is $v, !!0;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { $sh{$i++} };
	if($iomode =~ /r/) {
		is $@, "";
		is $v, undef;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	eval { $sh{$i++} = $i++ };
	if($iomode =~ /w/) {
		is $@, "";
	} else {
		like $@, qr#\Acan't\ write\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unwritable\ mode\ #x;
	}
	$v = eval { delete($sh{$i++}) };
	if($iomode =~ /rw/) {
		is $@, "";
		is $v, undef;
	} elsif($iomode =~ /r/) {
		like $@, qr#\Acan't\ update\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unwritable\ mode\ #x;
	} else {
		like $@, qr#\Acan't\ update\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	SKIP: {
		skip "tied hash in scalar context not supported on this Perl", 2
			unless ("$]" >= 5.008003 && "$]" < 5.009000) ||
				"$]" >= 5.009001;
		$v = eval { scalar(%sh) };
		if($iomode =~ /r/) {
			is $@, "";
			if("$]" >= 5.025003) {
				like $v, $occupied ? qr/\A[1-9][0-9]*\z/ :
						qr/\A0\z/;
			} else {
				is $v, !!$occupied;
			}
		} else {
			like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
					\ shared\ hash\ was\ opened
					\ in\ unreadable\ mode\ #x;
			ok 1;
		}
	}
	$v = eval { scalar(keys(%sh)) };
	if($iomode =~ /r/) {
		is $@, "";
		like $v, $occupied ? qr/\A[1-9][0-9]*\z/ : qr/\A0\z/;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { scalar(values(%sh)) };
	if($iomode =~ /r/) {
		is $@, "";
		like $v, $occupied ? qr/\A[1-9][0-9]*\z/ : qr/\A0\z/;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { scalar(each(%sh)) };
	if($iomode =~ /r/) {
		is $@, "";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { [each(%sh)] };
	if($iomode =~ /r/) {
		is $@, "";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { [keys(%sh)] };
	if($iomode =~ /r/) {
		is $@, "";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { [values(%sh)] };
	if($iomode =~ /r/) {
		is $@, "";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { [%sh] };
	if($iomode =~ /r/) {
		is $@, "";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$sh = shash_snapshot($sh);
	$iomode =~ s/w//;
	ok shash_is_snapshot($sh);
	is shash_is_readable($sh), scalar($iomode =~ /r/);
	is shash_is_writable($sh), !!0;
	is shash_mode($sh), $iomode;
	$v = eval { shash_exists($sh, $i++) };
	if($iomode =~ /r/) {
		is $@, "";
		is $v, !!0;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_length($sh, $i++) };
	if($iomode =~ /r/) {
		is $@, "";
		is $v, undef;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_get($sh, $i++) };
	if($iomode =~ /r/) {
		is $@, "";
		is $v, undef;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	eval { shash_set($sh, $i++, $i++) };
	like $@, qr#\Acan't\ write\ shared\ hash\ \Q$name\E:
			\ shared\ hash\ handle\ is\ a\ snapshot\ #x;
	$v = eval { shash_gset($sh, $i++, $i++) };
	if($iomode =~ /r/) {
		like $@, qr#\Acan't\ update\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ handle\ is\ a\ snapshot\ #x;
	} else {
		like $@, qr#\Acan't\ update\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_cset($sh, $i++, $i++, $i++) };
	if($iomode =~ /r/) {
		like $@, qr#\Acan't\ update\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ handle\ is\ a\ snapshot\ #x;
	} else {
		like $@, qr#\Acan't\ update\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_occupied($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		is $v, !!$occupied;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_count($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		like $v, $occupied ? qr/\A[1-9][0-9]*\z/ : qr/\A0\z/;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_size($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		like $v, qr/\A[0-9]+\z/;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_key_min($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		if($occupied) {
			like $v, qr/\A[0-9]+\z/;
		} else {
			is $v, undef;
		}
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_key_max($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		if($occupied) {
			like $v, qr/\A[0-9]+\z/;
		} else {
			is $v, undef;
		}
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_key_ge($sh, "-") };
	if($iomode =~ /r/) {
		is $@, "";
		if($occupied) {
			like $v, qr/\A[0-9]+\z/;
		} else {
			is $v, undef;
		}
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_key_gt($sh, "-") };
	if($iomode =~ /r/) {
		is $@, "";
		if($occupied) {
			like $v, qr/\A[0-9]+\z/;
		} else {
			is $v, undef;
		}
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_key_le($sh, "~") };
	if($iomode =~ /r/) {
		is $@, "";
		if($occupied) {
			like $v, qr/\A[0-9]+\z/;
		} else {
			is $v, undef;
		}
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_key_lt($sh, "~") };
	if($iomode =~ /r/) {
		is $@, "";
		if($occupied) {
			like $v, qr/\A[0-9]+\z/;
		} else {
			is $v, undef;
		}
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_keys_array($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		is ref($v), "ARRAY";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_keys_hash($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		is ref($v), "HASH";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { shash_group_get_hash($sh) };
	if($iomode =~ /r/) {
		is $@, "";
		is ref($v), "HASH";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	eval { shash_idle($sh) };
	is $@, "";
	eval { shash_tidy($sh) };
	like $@, qr#\Acan't\ tidy\ shared\ hash\ \Q$name\E:
			\ shared\ hash\ handle\ is\ a\ snapshot\ #x;
	$v = eval { shash_tally_get($sh) };
	is $@, "";
	is ref($v), "HASH";
	$v = eval { shash_tally_zero($sh) };
	is $@, "";
	is $v, undef;
	$v = eval { shash_tally_gzero($sh) };
	is $@, "";
	is ref($v), "HASH";
	tie %sh, "Hash::SharedMem::Handle", $sh;
	ok is_shash(tied(%sh));
	ok tied(%sh) == $sh;
	$v = eval { exists($sh{$i++}) };
	if($iomode =~ /r/) {
		is $@, "";
		is $v, !!0;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { $sh{$i++} };
	if($iomode =~ /r/) {
		is $@, "";
		is $v, undef;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	eval { $sh{$i++} = $i++ };
	like $@, qr#\Acan't\ write\ shared\ hash\ \Q$name\E:
			\ shared\ hash\ handle\ is\ a\ snapshot\ #x;
	$v = eval { delete($sh{$i++}) };
	if($iomode =~ /r/) {
		like $@, qr#\Acan't\ update\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ handle\ is\ a\ snapshot\ #x;
	} else {
		like $@, qr#\Acan't\ update\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	SKIP: {
		skip "tied hash in scalar context not supported on this Perl", 2
			unless ("$]" >= 5.008003 && "$]" < 5.009000) ||
				"$]" >= 5.009001;
		$v = eval { scalar(%sh) };
		if($iomode =~ /r/) {
			is $@, "";
			if("$]" >= 5.025003) {
				like $v, $occupied ? qr/\A[1-9][0-9]*\z/ :
						qr/\A0\z/;
			} else {
				is $v, !!$occupied;
			}
		} else {
			like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
					\ shared\ hash\ was\ opened
					\ in\ unreadable\ mode\ #x;
			ok 1;
		}
	}
	$v = eval { scalar(keys(%sh)) };
	if($iomode =~ /r/) {
		is $@, "";
		like $v, $occupied ? qr/\A[1-9][0-9]*\z/ : qr/\A0\z/;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { scalar(values(%sh)) };
	if($iomode =~ /r/) {
		is $@, "";
		like $v, $occupied ? qr/\A[1-9][0-9]*\z/ : qr/\A0\z/;
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { scalar(each(%sh)) };
	if($iomode =~ /r/) {
		is $@, "";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { [each(%sh)] };
	if($iomode =~ /r/) {
		is $@, "";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { [keys(%sh)] };
	if($iomode =~ /r/) {
		is $@, "";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { [values(%sh)] };
	if($iomode =~ /r/) {
		is $@, "";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
	$v = eval { [%sh] };
	if($iomode =~ /r/) {
		is $@, "";
	} else {
		like $@, qr#\Acan't\ read\ shared\ hash\ \Q$name\E:
				\ shared\ hash\ was\ opened
				\ in\ unreadable\ mode\ #x;
	}
}

foreach my $iomode ("", qw(r w rw)) {
	my $name = "$tmpdir/t".$i++;
	my $sh = eval { shash_open($name, $iomode) };
	like $@, qr/\Acan't open shared hash \Q$name\E: \Q$enoent\E at /;
	$sh = eval { shash_open($name, $iomode."c") };
	ok $sh;
	ok is_shash($sh);
	test_shash_ops($sh, $name, $iomode);
	$sh = eval { shash_open($name, $iomode."c") };
	ok $sh;
	ok is_shash($sh);
	test_shash_ops($sh, $name, $iomode);
	$sh = eval { shash_open($name, $iomode) };
	ok $sh;
	ok is_shash($sh);
	test_shash_ops($sh, $name, $iomode);
	$sh = eval { shash_open($name, $iomode."e") };
	like $@, qr/\Acan't open shared hash \Q$name\E: \Q$eexist\E at /;
	$sh = eval { shash_open($name, $iomode."ce") };
	like $@, qr/\Acan't open shared hash \Q$name\E: \Q$eexist\E at /;
	$name = "$tmpdir/t".$i++;
	$sh = eval { shash_open($name, $iomode."e") };
	like $@, qr/\Acan't open shared hash \Q$name\E: \Q$enoent\E at /;
	$sh = eval { shash_open($name, $iomode."ce") };
	ok $sh;
	ok is_shash($sh);
	test_shash_ops($sh, $name, $iomode);
}

1;
