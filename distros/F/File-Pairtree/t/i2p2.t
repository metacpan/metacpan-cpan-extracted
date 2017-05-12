use 5.006;
use Test::More qw( no_plan );
use strict;
use warnings;

my $script = 'pt';		# script we're (not actually) testing

# as of 2010.05.02  (perlpath minus _exe, plus filval(), no -x for MSWin)
#### start boilerplate for script name and temporary directory support

use Config;
$ENV{SHELL} = "/bin/sh";
my $td = "td_$script";		# temporary test directory named for script
# Depending on circs, use blib, but prepare to use lib as fallback.
my $blib = (-e "blib" || -e "../blib" ?	"-Mblib" : "-Ilib");
my $bin = ($blib eq "-Mblib" ?		# path to testable script
	"blib/script/" : "") . $script;
my $perl = $Config{perlpath};		# perl used in testing
my $cmd = "2>&1 $perl $blib " .		# command to run, capturing stderr
	(-e $bin ? $bin : "../$bin") . " ";	# exit status in $? >> 8

my ($rawstatus, $status);		# "shell status" version of "is"
sub shellst_is { my( $expected, $output, $label )=@_;
	$status = ($rawstatus = $?) >> 8;
	$status != $expected and	# if not what we thought, then we're
		print $output, "\n";	# likely interested in seeing output
	return is($status, $expected, $label);
}

use File::Path;
sub remake_td {		# make $td with possible cleanup
	-e $td			and remove_td();
	mkdir($td)		or die "$td: couldn't mkdir: $!";
}
sub remove_td {		# remove $td but make sure $td isn't set to "."
	! $td || $td eq "."	and die "bad dirname \$td=$td";
	eval { rmtree($td); };
	$@			and die "$td: couldn't remove: $@";
}

# Abbreviated version of "raw" File::Value::file_value()
sub filval { my( $file, $value )=@_;	# $file must begin with >, <, or >>
	if ($file =~ /^\s*>>?/) {
		open(OUT, $file)	or return "$file: $!";
		my $r = print OUT $value;
		close(OUT);		return ($r ? '' : "write failed: $!");
	} # If we get here, we're doing file-to-value case.
	open(IN, $file)		or return "$file: $!";
	local $/;		$_[1] = <IN>;	# slurp mode (entire file)
	close(IN);		return '';
}

#### end boilerplate

use File::Pairtree ':all';

my $pre = $File::Pairtree::root;

# For round-trip testing.  Gets you more for your testing dollar.
#
sub i2p2i{ my( $id, $target, $label, $pathcomp_sep )=@_;
	my $ppath = id2ppath($id, $pathcomp_sep);
	is $ppath, $pre . $target, 'i2 ' . $label;
	is ppath2id($ppath, $pathcomp_sep), $id, 'ireverse ' . $label;
}

sub p2i2p{ my( $ppath, $normpp, $target, $label, $pathcomp_sep )=@_;
	my $id = ppath2id($ppath, $pathcomp_sep);
	is $id, $target, 'p2 ' . $label;
	is id2ppath($id, $pathcomp_sep),
		$pre . $normpp,		# compare with normalized ppath
		'preverse ' . $label;
}

{
i2p2i('abc', '/ab/c/', 'basic 3-char case');

i2p2i('abcd', '/ab/cd/', 'basic 4-char case');

i2p2i('abcdefg', '/ab/cd/ef/g/', 'basic 7-char case');

i2p2i('abcde', '\\ab\\cd\\e\\', '5-char with \\ separator', '\\');

i2p2i('xy', '/xy/', '2-char edge case');

i2p2i('z', '/z/', '1-char edge case');

i2p2i('', '//', '0-char edge case');

i2p2i('abcdefg', '/ab/cd/ef/g/', '7-char, empty separator case', '');

i2p2i('', '//', '0-char, empty separator edge case', '');

i2p2i('z', '/z/', '1-char, empty separator edge case', '');

i2p2i('12-986xy4', '/12/-9/86/xy/4/', 'hyphen');

i2p2i('13030_45xqv_793842495',
	'/13/03/0_/45/xq/v_/79/38/42/49/5/',
	'long id with undescores');

i2p2i('ark:/13030/xt12t3',
	'/ar/k+/=1/30/30/=x/t1/2t/3/',
	'colons and slashes');

i2p2i('/', '/=/', '1-separator-char edge case');

i2p2i('http://n2t.info/urn:nbn:se:kb:repos-1',
	'/ht/tp/+=/=n/2t/,i/nf/o=/ur/n+/nb/n+/se/+k/b+/re/po/s-/1/',
	'a URL with colons, slashes, and periods');

i2p2i('what-the-*@?#!^!?',
	'/wh/at/-t/he/-^/2a/@^/3f/#!/^5/e!/^3/f/',
	'weird chars from spec example');

i2p2i('\"*+,<=>?^|',
	'/^5/c^/22/^2/a^/2b/^2/c^/3c/^3/d^/3e/^3/f^/5e/^7/c/',
	'all weird visible chars');

i2p2i('Années de Pèlerinage',
	'/An/n^/c3/^a/9e/s^/20/de/^2/0P/^c/3^/a8/le/ri/na/ge/',
	'UTF-8 chars');
i2p2i(qq{Années de Pèlerinage (Years of Pilgrimage) (S.160, S.161,
 S.163) is a set of three suites by Franz Liszt for solo piano. Liszt's
 complete musical style is evident in this masterwork, which ranges from
 virtuosic fireworks to sincerely moving emotional statements. His musical
 maturity can be seen evolving through his experience and travel. The
 third volume is especially notable as an example of his later style: it
 was composed well after the first two volumes and often displays less
 showy virtuosity and more harmonic experimentation.},
	qq{/An/n^/c3/^a/9e/s^/20/de/^2/0P/^c/3^/a8/le/ri/na/ge/^2/0(/Ye/ar/s^/20/of/^2/0P/il/gr/im/ag/e)/^2/0(/S,/16/0^/2c/^2/0S/,1/61/^2/c^/0a/^2/0S/,1/63/)^/20/is/^2/0a/^2/0s/et/^2/0o/f^/20/th/re/e^/20/su/it/es/^2/0b/y^/20/Fr/an/z^/20/Li/sz/t^/20/fo/r^/20/so/lo/^2/0p/ia/no/,^/20/Li/sz/t'/s^/0a/^2/0c/om/pl/et/e^/20/mu/si/ca/l^/20/st/yl/e^/20/is/^2/0e/vi/de/nt/^2/0i/n^/20/th/is/^2/0m/as/te/rw/or/k^/2c/^2/0w/hi/ch/^2/0r/an/ge/s^/20/fr/om/^0/a^/20/vi/rt/uo/si/c^/20/fi/re/wo/rk/s^/20/to/^2/0s/in/ce/re/ly/^2/0m/ov/in/g^/20/em/ot/io/na/l^/20/st/at/em/en/ts/,^/20/Hi/s^/20/mu/si/ca/l^/0a/^2/0m/at/ur/it/y^/20/ca/n^/20/be/^2/0s/ee/n^/20/ev/ol/vi/ng/^2/0t/hr/ou/gh/^2/0h/is/^2/0e/xp/er/ie/nc/e^/20/an/d^/20/tr/av/el/,^/20/Th/e^/0a/^2/0t/hi/rd/^2/0v/ol/um/e^/20/is/^2/0e/sp/ec/ia/ll/y^/20/no/ta/bl/e^/20/as/^2/0a/n^/20/ex/am/pl/e^/20/of/^2/0h/is/^2/0l/at/er/^2/0s/ty/le/+^/20/it/^0/a^/20/wa/s^/20/co/mp/os/ed/^2/0w/el/l^/20/af/te/r^/20/th/e^/20/fi/rs/t^/20/tw/o^/20/vo/lu/me/s^/20/an/d^/20/of/te/n^/20/di/sp/la/ys/^2/0l/es/s^/0a/^2/0s/ho/wy/^2/0v/ir/tu/os/it/y^/20/an/d^/20/mo/re/^2/0h/ar/mo/ni/c^/20/ex/pe/ri/me/nt/at/io/n,/},
	'very long id with apostrophes and UTF-8 chars');

p2i2p('/ab/cd/', '/ab/cd/', 'abcd', 'basic 4-char path');

p2i2p('/ab/cd/e/', '/ab/cd/e/', 'abcde', 'basic 5-char path');

p2i2p('ab/cd/e', '/ab/cd/e/', 'abcde', 'missing terminal separators');

p2i2p('/ab/cd/e/f/gh/', '/ab/cd/e/', 'abcde', '1-char shorty ends ppath');

p2i2p('///ab///cd///e///////', '/ab/cd/e/', 'abcde',
	'lots of bunched separators');

p2i2p('  //ab///cd///e///  ', '/ab/cd/e/', 'abcde',
	'whitespace in front and in back');

p2i2p('pairtree_root/ab/cd/e/obj',
	'/ab/cd/e/', 'abcde', 'junk before and after path');

p2i2p('pairtree_root/ab/c/d/ef', '/ab/c/', 'abc',
	'junk after one-char component terminates ppath');

p2i2p('pairtree_root/a=/c+/e,/obj',
	'/a=/c+/e,/', 'a/c:e.', 'junk with weird chars');

p2i2p('/home/jak/pairtree_root/ab/cd/e/data/obj',
	'/ab/cd/e/', 'abcde', 'bigger junk before and after path');

p2i2p('/home/jak/pairtree_root/ab/cd/e/data/obj/pairtree_root/gh/ij',
	'/gh/ij/', 'ghij', 'ppath followed by a ppath picks last one');

like ppath2id('/ab/ d/ e'), '/^error: non-visible/',
	'internal whitespace check';

like ppath2id('/ab/^'), '/^error: impossible/', 'hex encoding check 1';

like ppath2id('/ab/^a'), '/^error: impossible/', 'hex encoding check 2';

like ppath2id('/ab/^a/g'), '/^error: impossible/', 'hex encoding check 3';

like ppath2id('/ab/^r/f'), '/^error: impossible/', 'hex encoding check 4';

is s2ppchars('http://n2t.info/urn:nbn:se:kb:repos-1'),
	'http+==n2t,info=urn+nbn+se+kb+repos-1',
	'ptsafe on a URL with colons, slashes, and periods';

}
# XXX initial whitespace, utf8
