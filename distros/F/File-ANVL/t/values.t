use 5.006;
use Test::More qw( no_plan );

use strict;
use warnings;

my $script = "anvl";		# script we're testing

# as of 2011.06.29  flvl() from File::Value
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

use File::Value ':all';

#### end boilerplate

use File::ANVL qw(:all);

{	# values tests

my $m = anvl_valsplit("foo", "dummy");
like $m, qr/array/, 'valsplit message about 2nd arg referencing an array';

my (@elems, @svals);
#print "before svals=", \@svals, "\n";
$m = anvl_valsplit("ab;cd;ef|foo;bar||;;zaf", \@svals);
#print "after svals=", \@svals, "\n";

is scalar(@svals), 4, 'anvl_valsplit into 4 subvalues';

is scalar(@{$svals[0]}), 3, '1st subvalue cardinality correct';

is scalar(@{$svals[1]}), 2, '2nd subvalue cardinality correct';

is scalar(@{$svals[2]}), 0, '3rd subvalue cardinality correct';

is scalar(@{$svals[3]}), 3, '4th subvalue cardinality correct';

my $r = "erc: Gibbon, Edward | "
	. "The Decline and Fall of the Roman Empire | 1781 | "
	. "http://www.ccel.org/g/gibbon/decline/";
$m = anvl_recarray($r, \@elems);
is scalar(@elems), 6, 'correct elem count for shortest record form';

#erc_anvl_expand_array
# anvl_recarray(        # split $record into array of linenum-name-value
#         $record,      # triples, first triple being <anvl, beta, "">
#         $r_elems,     # reference to returned array
#         $linenum,     # starting line number (default 1)
#         $opts );      # options/default, eg, comments/0, autoindent/1

$m = erc_anvl_expand_array(\@elems);
is $m, '', 'simple erc_anvl_expand_array returns no message';

is $elems[7], 'who', 'did expand first element';
#like $m, qr/who:/, 'simple anvl_erc_longer';

my $m2 = erc_anvl_expand_array(\@elems);
is $m2, $m, 'erc_anvl_expand_array idempotence test (re-run against result)';

$r .= "\nnote: that should be preserved\n";
$m = anvl_recarray($r, \@elems);
$m = erc_anvl_expand_array(\@elems);
is $elems[19], 'note', 'other metadata preserved in anvl_erc_longer';

my $relems = [1,1,1, '1:', 'erc', undef];
$m = erc_anvl_expand_array($relems);
is scalar(@$relems), 6, 'no change from erc_anvl_expand_array for empty erc';

$r = "name1;name2;name3|title;subtitle|date|where|vellum|because|a|b|c";
$m2 = anvl_valsplit($r, \@svals);

is scalar(@svals), 9, 'short form with 9 elements/subvalues';

is scalar(@{$svals[0]}), 3, '1st subvalue cardinality correct';

is scalar(@{$svals[1]}), 2, '2nd subvalue cardinality correct';

is scalar(@{$svals[2]}), 1, '3rd subvalue cardinality correct';

is scalar(@{$svals[3]}), 1, '4th subvalue cardinality correct';

$r = 'Smith, Jo
H: 555-1234
W: 555-9876
W: 555-5678
E: jsmith@example.com
';
$m = anvl_recarray($r, \@elems);
is scalar(@elems), 15, 'correct elem count for record with non-standard start';

is $elems[2], "Smith, Jo", 'unlabeled start captured (not really ANVL)';

is $elems[0], "1", 'unlabeled start line number captured (not really ANVL)';

my %rhash;
$m = anvl_arrayhash(@elems, \%rhash);
like $m,  qr/array/, 'bad first arg';

$m = anvl_arrayhash(\@elems, %rhash);
like $m,  qr/hash/, 'bad second arg';

my $n;
$m = anvl_arrayhash(\@elems, \%rhash);
$n = $rhash{H}->[0];		# index of first such element triple
is $elems[$n + 2], '555-1234', 'hash home phone';

is $elems[ $rhash{W}->[0] + 2 ], '555-9876',
	'hash work phone, first value';

is $elems[ $rhash{W}->[1] + 2 ], '555-5678',
	'hash work phone, second value';

# no elem name becomes '_'
is $elems[ $rhash{'_'}->[0] + 2 ], 'Smith, Jo',
	'hash "" key for non-standard start';

undef %rhash;		# clears out old values so we don't add to them

# DEPRECATED
$m = anvl_rechash("foo", "dummy");
like $m, qr/hash/, 'rechash message about 2nd arg referencing a hash';

$m = anvl_rechash("foo: bar", \%rhash);
is $rhash{foo}, 'bar', 'simple one-element record hash';

#$m = erc_anvl2erc_turtle("foo: bar");
#like $m, qr/ERC.ANVL/, 'turtle conversion abort, not an erc';
#
#my $turtle_rec;
#$m = erc_anvl2erc_turtle("erc: bar");
#like $m, qr/string/, 'turtle conversion abort, no return string';
#
#$m = erc_anvl2erc_turtle("erc: $r", $turtle_rec);
#print "erc: $r\n";
#print "$turtle_rec\n";
#like $turtle_rec, qr/erc:who.*erc:what.*erc:when.*erc:where/s,
#	'turtle conversion with 9 reduced to 6 elems';
## xxx is 9 to 6 ok?

}
