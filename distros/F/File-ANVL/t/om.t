use 5.006;
use Test::More qw( no_plan );

# xxx To do: make test sets more comprehensive and systemmatic

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

use File::OM;

{	# OM object tests

remake_td();

my $om = File::OM->new("Xyz");
is $om, undef, 'failed to make a nonsense object';

$om = File::OM->new("Plain");
is ref($om), 'File::OM::Plain', 'made a File::OM::Plain object';

is $om->elem('foo', 'bar'), 'bar
', 'simple Plain element';

is $om->elem('foo', 0), '0
', 'Plain element of value 0';

is $om->elem('foo', ""), '
', 'Plain element of value ""';

$om = File::OM->new("XML", { verbose => 1 });
is ref($om), 'File::OM::XML', 'made a File::OM::XML object';

like $om->elem('foo', 'bar'),
	qr{<recs>.*<rec>.*from record 1, line 1.*<foo>bar</foo>}s,
	'simple XML element';

like $om->orec(), qr/<rec>.*record 2, line 1/,
	'XML verbose record start with defaults for recnum and lineno';

like $om->elem('foo', 0), qr,<foo>0</foo>,, 'XML element of value 0';

like $om->elem('foo', ""), qr,<foo></foo>,, 'XML element of value ""';

$om = File::OM->new('JSON');
is ref($om), 'File::OM::JSON', 'made a File::OM::JSON object';

is $om->elem('foo', 'bar'), '[
  {
    "foo": "bar"', 'simple JSON element';

like $om->elem('foo', 0), qr,"foo": "0",, 'JSON element of value 0';

like $om->elem('foo', ""), qr,"foo": "",, 'JSON element of value ""';

$om = File::OM->new('Turtle');
is ref($om), 'File::OM::Turtle', 'made a File::OM::Turtle object';

is $om->orec('a:b'), '@prefix erc: <http://purl.org/kernel/elements/1.1/> .
<default>', 'orec for Turtle with default';

is $om->elem('foo', 'bar'), '
    erc:foo """bar"""', 'simple Turtle element';

like $om->elem('foo', 0), qr,erc:foo """0""",, 'Turtle element of value 0';

like $om->elem('foo', ""), qr,erc:foo """""",, 'Turtle element of value ""';

$om = new File::OM::ANVL;
is ref($om), 'File::OM::ANVL', 'made a "new File::OM::ANVL" object';

$om = File::OM::ANVL->new();
is ref($om), 'File::OM::ANVL',
	'made a File::OM::ANVL object using subclass constructor';

like $om->elem('foo', 0), qr,foo: 0\n,, 'ANVL element of value 0';

like $om->elem('foo', ""), qr,foo:\n,, 'ANVL element of value ""';

# xxxxxxxxx this doesn't work but should! (arg1 assumed to be format)
#$om = File::OM::ANVL->new({wrap=>18});

$om = File::OM->new("anvl", {wrap=>14});
is $om->elem('erc', ''), 'erc:
',	'label and empty value';

is $om->elem('ab', 'cd ef gh ij kl mn op'), 'ab: cd ef gh
	ij kl
	mn op
', 'ANVL elem wrap with short lines';

is $om->elem('abracadabra', 'cd ef gh ij kl mn op'),
	'abracadabra:
	cd ef
	gh ij
	kl mn
	op
', 'ANVL wrap with long unbroken label and short lines';

is $om->elem('abracadabra', 'cd ef gh ij kl mn op', '#'),
	'#cd ef gh ij
# kl mn op
',	'ANVL comment wrap';

$om = File::OM->new("anvl", {wrap=>0});
is $om->elem('erc', ''), 'erc:
',	'nowrap with label and empty value';

like $om->elem('ab', 'cd ef gh' x 300), qr/^ab: .{2400}\n$/,
	'ANVL elem nowrap with one 2400-char line';

$om = File::OM->new("plain", {wrap=>14});

is $om->elem('abracadabra', 'cd ef gh ij kl mn op', '#'),
	'#cd ef gh ij
# kl mn op
',	'Plain comment wrap';

$om = File::OM->new("xml", {wrap=>14});

is $om->elem('abracadabra', 'cd ef gh ij kl mn op', '#'), '<recs>
  <rec>
    <!--cd ef
    gh ij kl
    mn op-->
',	'XML comment wrap';

is $om->elem('abracadabra', 'cd ef gh ij kl mn op', ':'),
'    <abracadabra>cd
    ef gh ij
    kl mn op</abracadabra>
',	'XML element wrap';

$om = File::OM->new("anvl");
is $om->elems('a', 'b', 'c', 'd'), "a: b\nc: d\n", 'elems for ANVL';

is $om->elems('a', 'b now is the time for all good men to come to the aid of the party and it is still time', 'c', 'd now is the time for all good men to come to the aid of the party and it is still time'),
  'a: b now is the time for all good men to come to the aid of the party
	and it is still time
c: d now is the time for all good men to come to the aid of the party
	and it is still time
',
	'bigger elems for ANVL';

$om = File::OM->new("xml", { wrap => 58 });
is $om->elems('a', 'b now is the time for all good men to come to the aid of the party and it is still time', 'c', 'd now is the time for all good men to come to the aid of the party and it is still time'),
'<recs>
  <rec>
    <a>b now is the time for all good men to come to the
    aid of the party and it is still time</a>
    <c>d now is the time for all good men to come to the
    aid of the party and it is still time</c>
', 'bigger elems form XML, wrap 58';

$om = File::OM->new("xml");
is $om->elems('a', 'b now is the time for all good men to come to the aid of the party and it is still time', 'c', 'd now is the time for all good men to come to the aid of the party and it is still time'),
  '<recs>
  <rec>
    <a>b now is the time for all good men to come to the aid of the
    party and it is still time</a>
    <c>d now is the time for all good men to come to the aid of the
    party and it is still time</c>
',
	'bigger elems for XML';

$om = File::OM->new("ANVL");
is $om->elem('ab', 'cd'), 'ab: cd
',	'ANVL elem auto-invokes open stream and open rec';

my $x = $om->DESTROY();
is $x, '
',	'ANVL DESTROY auto-invokes close rec and close stream';

$om = File::OM->new("json");
is $om->elem('ab', 'cd'), '[
  {
    "ab": "cd"', 'JSON elem auto-invokes open stream and open rec';

$x = $om->DESTROY();
is $x, '
  }
]
',	'JSON DESTROY auto-invokes close rec and close stream';

$om = File::OM->new("Plain");
is $om->elem('ab', 'cd'), 'cd
',	'Plain elem auto-invokes open stream and open rec';

$x = $om->DESTROY();
is $x, '
',	'Plain DESTROY auto-invokes close rec and close stream';

$om = File::OM->new("Turtle");
is $om->elem('ab', 'cd'),
	'@prefix erc: <http://purl.org/kernel/elements/1.1/> .
<default>
    erc:ab """cd"""',
	'Turtle elem auto-invokes open stream and open rec';

$x = $om->DESTROY();
is $x, ' .

',	'Turtle DESTROY auto-invokes close rec and close stream';

$om = File::OM->new("xml");
like $om->elem('ab', 'cd'), qr{<recs>.*<rec>.*<ab>cd</ab>}s,
	'XML elem auto-invokes open stream and open rec';

$x = $om->DESTROY();
like $x, qr{</rec>.*</recs>}s,
	'XML DESTROY auto-invokes close rec and close stream';

# Put perl script to test in a file instead of testing from command line
# to the avoid nightmare of incompatible -e and shell quotes between
# Windows and Unix.  This covers a number of tests below.

$x = flvl(">$td/file", 'use File::OM; my $x = File::OM->new("ANVL", { outhandle => *STDOUT }); $x->elem("a", "b");');
$x = `perl -Mblib $td/file`;
is $x, 'a: b

',	'ANVL implied DESTROY and STDOUT';

$x = flvl(">$td/file", 'use File::OM; my $x = File::OM->new("json", { outhandle => *STDOUT }); $x->elem("a", "b");');
$x = `perl -Mblib $td/file`;
is $x, '[
  {
    "a": "b"
  }
]
',	'JSON implied DESTROY and STDOUT';

$x = flvl(">$td/file", 'use File::OM; my $x = File::OM->new("Plain", { outhandle => *STDOUT }); $x->elem("a", "b");');
$x = `perl -Mblib $td/file`;
is $x, 'b

',	'Plain implied DESTROY and STDOUT';

$x = flvl(">$td/file", 'use File::OM; my $x = File::OM->new("Turtle", { outhandle => *STDOUT }); $x->elem("a", "b");');
$x = `perl -Mblib $td/file`;
is $x, '@prefix erc: <http://purl.org/kernel/elements/1.1/> .
<default>
    erc:a """b""" .

',	'Turtle implied DESTROY and STDOUT';

$x = flvl(">$td/file", 'use File::OM; my $x = File::OM->new("xml", { outhandle => *STDOUT }); $x->elem("a", "b");');
$x = `perl -Mblib $td/file`;
is $x, '<recs>
  <rec>
    <a>b</a>
  </rec>
</recs>
',	'XML implied DESTROY and STDOUT';

$om = File::OM::JSON->new();
$x = $om->elem('a1', 'x');
$x = $om->elem('a2', 'y');
$x = $om->elem('a3', 'z');   # 707-765-3960   # 05215176
is $om->{elemnum}, '3', 'elem tracks element number';

$x = $om->elems('a1', 'b', 'a2', 'c', 'a3', 'd');	# 3 more elems
is $om->{elemnum}, '6', 'elems tracks element number';

$x = $om->elem('a18', 'e', ':', 18);
is $om->{elemnum}, '18', 'elem allows reset of element number';

is $om->{recnum}, '1', 'elem(s) tracks recnum 1';

$x = $om->crec();
$x = $om->orec();
is $om->{recnum}, '2', 'crec/orec tracks recnum 2';

remove_td();

}
