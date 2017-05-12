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

use File::ANVL qw(:all);	# import everything in EXPORT_OK

{	# anvl_encode/anvl_decode

is anvl_encode("now:this|that"), 'now%cnthis%vbthat', 'simple encode';

is anvl_decode("now%cnthis%vbthat"), 'now:this|that', 'simple decode';

is anvl_decode("a%{ b c d %}e"), 'abcde', 'one expansion block';

is anvl_decode("%{nospaces%} u %{ a
b	c
d
%}%{b = c%}th%{%}at"), 'nospaces u abcdb=cthat', 'several expansion blocks';

#{
is anvl_decode("now%}this%{that"), 'nowthisthat',
	'mismatched expansion block delimiters removed';
#}

is anvl_decode('http://foo.bar.org/node%{
           ? db = foo
           & start = 1
           & end = 5
           & buf = 2
           & query = foo + bar + zaf
       %}'),
'http://foo.bar.org/node?db=foo&start=1&end=5&buf=2&query=foo+bar+zaf',
	'example expansion block URL from documentation';

use File::OM;

my $om = File::OM::XML->new();
is $om->name_encode('ab<cd>ef&"hi\'j'), 'ab&lt;cd&gt;ef&amp;\\"hi&apos;j',
	'xml name encode';

is $om->value_encode('ab<cd>ef&"hi\'j'), 'ab&lt;cd&gt;ef&amp;\\"hi&apos;j',
	'xml value encode';

is $om->comment_encode('ab-->ef"hi\'j'), 'ab--&gt;ef"hi\'j',
	'xml comment encode';

$om = File::OM->new("turtle");
# \" \\
is $om->value_encode('ab<cd>ef&"hi\\j'), 'ab<cd>ef&\\"hi\\\\j',
	'turtle value encode';

$om = File::OM->new("jSon");
is $om->name_encode('ab<cd>ef&"hi\\j'),
	'ab<cd>ef&\\"hi\\\\j', 'json name encode';

is $om->value_encode("a	b\nc"), 'a\u0009b\u000ac',
	'json value encode with control chars';

}

{	# get_anvl and trimlines

remake_td();
 
# create and open a file with 3 records and whitespace before and after
my $recstream = '	 
    

a:b
c:d



e:f
g:h


i:j

    


';

my $x = flvl(">$td/file", $recstream);
open "IN", "<$td/file"		or die "couldn't open $td/file";

my ($linenum, $rec, $wslines, $rrlines, @newlines);
my $get_anvl = make_get_anvl();

$linenum = 1;
$rec = &$get_anvl(*IN);
$rec = trimlines($rec, \$wslines, \$rrlines);
$linenum += $wslines;
like $linenum.$rec, qr/4a:b\nc:d\n\n/, 'first get_anvl record on line 4';

$linenum += $rrlines;
$rec = &$get_anvl(*IN);
$rec = trimlines($rec, \$wslines, \$rrlines);
$linenum += $wslines;
like $linenum.$rec, qr/9e:f\ng:h\n\n/, 'second get_anvl record on line 9';

#$linenum += scalar(@newlines = $rec =~ /\n/g);
$linenum += $rrlines;
$rec = &$get_anvl(*IN);
$rec = trimlines($rec, \$wslines, \$rrlines);
$linenum += $wslines;
#$rec =~ s/^(\s+)//s	and $linenum += scalar(@newlines = $1 =~ /\n/g);
like $linenum.$rec, qr/13i:j\n\n/, 'third get_anvl record on line 13';

#$linenum += scalar(@newlines = $rec =~ /\n/g);
$linenum += $rrlines;
$rec = &$get_anvl(*IN);
$rec = trimlines($rec, \$wslines, \$rrlines);
is $rec, undef, 'fourth get_anvl call hits almost eof (blank record)';
$linenum += $wslines;	# where next rec would start if there was one

is $linenum-1, 14, 'get_anvl chops blank lines at end of input';

is $rec, undef, 'fifth get_anvl call hits real eof';

close(*IN);

#is trimlines("a:b", \$wslines), "a:b\n\n",
#	'trimlines adds one newline, one optional arg';
#
#is trimlines("a:b\n"), "a:b\n\n",
#	'trimlines adds two newlines, no optional args';
#
#is trimlines("\n\n\na:b"), "a:b\n\n",
#	'trimlines adds 2 newlines, strips 3 newlines';

$wslines = $rrlines = undef;
is trimlines("\n\n  \n  ", \$wslines, \$rrlines), undef,
	'trimlines strips whitespace with premature EOF and returns undef';

is $wslines, 3, 'trimlines returns undef but still counted blank lines';
is $rrlines, 0, 'trimlines returns undef but still defined record linecount';

$x = `$cmd --verbose --comments < $td/file`;
like $x, qr/record 3, line 13/, 'stdin test for get_anvl (with anvl)';

$x = `$cmd --verbose --comments $td/file $td/file $td/file`;
like $x, qr{
line\ 4 .* line\ 21 .* line\ 26 .* line\ 30 .* line\ 38 .*
}sx, '3-file test for get_anvl (with anvl)';

remove_td();
}

{	# anvl_name_naturalize

remake_td();

is anvl_name_naturalize("Smith, John"), "Smith, John",
	'naturalize, no final comma';

is anvl_name_naturalize("Smith, III, John,"), "John Smith, III",
	'naturalize, with suffix';
#print anvl_name_naturalize("Smith, III, John,"), "\n";

is anvl_name_naturalize("Hu Jintao,"), "Hu Jintao",
	'naturalize, no internal comma';

is anvl_name_naturalize("McCartney, Paul, Sir,,"), "Sir Paul McCartney",
	'double-comma name';

is anvl_name_naturalize("Health and Human Services, United States Government Department of, The,,"),
	"The United States Government Department of Health and Human Services",
	'double-comma title';

is anvl_name_naturalize("a, b, c, d, e,,,"),
	"e d c a, b",
	'triple-comma value with 4th internal comma';

my $recstream = '	 
a: Hu Jintao,
b: McCartney, Paul, Sir,,
c: Health and Human Services, United States Government
	Department of, The,,
';
my $x = flvl(">$td/file", $recstream);

$x = `$cmd --invert $td/file`;
is $x, "a: Hu Jintao\nb: Sir Paul McCartney\nc: The United States Government Department of Health and Human Services\n\n",
	'invert 3 values';

remove_td();
}

{	# --find and --show

remake_td();

# create and open a file with 3 records and whitespace before and after
my $recstream = '	 
    
a: now
c: is
e: the
g: time

a: for
c: all
e: good
g: men

a: to
c: come
e: to
g: the

a: aid
c: of
e: the
g: party
';
my $x = flvl(">$td/file", $recstream);

$x = `$cmd --find "the" $td/file`;
like $x, qr/e: the.*\n\n.*g: the.*\n\n.*e: the/s,
	'find 3 records';

$x = `$cmd --show "the" $td/file`;
is $x, "e: the\n\n\ng: the\n\ne: the\n\n", 'show 3 lines in 4 records';

$x = `$cmd --find "(now|aid)" --show "^g" $td/file`;
is $x, "g: time\n\ng: party\n\n", 'find and show with regexes';

$x = `$cmd -m "anvl:e|a|c" $td/file`;
like $x, qr/(e:.*a:.*c:.*){4}/s, 'element order specified across 4 records';

$x = `$cmd -m "anvl:e|a|c|e" $td/file`;
like $x, qr/(e:.*a:.*c:.*e:.*){4}/s, 'element order specified with repeat';

$x = `$cmd -m "anvl: g|c|a" --find "party" $td/file`;
like $x, qr/party.*of.*aid/s, 'element order specified on found record';

remove_td();
}

{	# label-less value (name='_') tests

remake_td();

my $recstream = 'Smith, Jo
H: 555-1234
W: 555-9876
W: 555-5678
E: jsmith@example.com

Wong, Chris
H: 555-1111
W: 555-2222

N: Khan, H.
H: 555-3333
W: 555-4444
';

my $x = flvl(">$td/file", $recstream);

$x = `$cmd -m "anvl" $td/file`;
like $x, qr/_: Smith, Jo.*_: Wong, Chris/s,
	'all values, label-less values with name "_"';

$x = `$cmd -m "anvl:H|W" $td/file`;
like $x, qr/H: 555-1234\nW: 555-9876\n\n.*1111.*2222/s,
	'some selected values';

$x = `$cmd -m "anvl:H|_|W" $td/file`;
like $x, qr/H: 555-1234\n_: Smith, Jo\nW:.*_: Wong, Chris/s,
	'selected values, including label-less values with name "_"';

$x = `$cmd -m "anvl:H|xyz|W" $td/file`;
like $x, qr/H: 555-1111\nW: 555-2222/s,
	'selected values, absent element silently ignored';

$x = `$cmd -m "anvl:H||W" $td/file`;
like $x, qr/H: 555-1234\n.*W: 555-2222/s,
	'empty element name silently ignored in non-order-sensitive output';

remove_td();
}

{	# CSV and PSV tests

remake_td();

my $recstream = '

Smith, Jo
H: 555-1234
W: 555-9876
W: 555-5678
E: jsmith@example.com

Wong, Chris
H: 555-1111
W: 555-2222

N: Khan, H.
H: 555-3333
W: 555-4444
';

my $x = flvl(">$td/file", $recstream);

#$x = `$cmd -m "anvl" $td/file`;
#like $x, qr/_: Smith, Jo.*_: Wong, Chris/s,
#	'all values, label-less values with name "_"';

$x = `$cmd -m "csv:H||W" $td/file`;
like $x, qr/"555-1234",,".*555-2222"/s,
	'empty element name creates empty field in order-sensitive output';


$x = `$cmd -m "csv:H|W" $td/file`;
like $x, qr/"555-1234","555-9876".*1111.*2222.*4444"\n$/s,
	'some selected CSV values';

$x = `$cmd -m "psv:H|W" $td/file`;
like $x, qr/555-1234\|555-9876.*1111\|.*2222.*4444\n$/s,
	'some selected PSV values';

$recstream = '

example 1
Name: Fr|an "Doc" Smith
Home Phone: 555-1234
Work Phone: 555-9876
Mobile Phone: 510-555-9999
Email: fsmith@example.com
Group: family

example 2
Name: Chris Wong
Home Phone: 555-1111
Work Phone: 555-2222
Mobile Phone: 510-555-8888
Email: cwong@example.com
Group: friend

example 3
Name: Hashim Khan
Home Phone: 555-3333
Work Phone: 555-4444
Mobile Phone: 510-555-7777
Email: hkhan@example.com
Group: squash
';

$x = flvl(">$td/file", $recstream);

$x = `$cmd -m "csv:Name|Mobile Phone|Work Phone|Email|Group" $td/file`;
like $x, qr/"Fr\|an ""Doc"" Smith",.*555-8888".*2222.*cwong.*"squash"\n$/s,
	'CSV selected phone book values, with quoted internal chars';

$x = `$cmd -m "psv:Name|Mobile Phone|Work Phone|Email|Group" $td/file`;
like $x, qr/Fr%7can "Doc" Smith\|.*555-8888.*2222.*cwong.*\|squash\n$/s,
	'PSV selected phone book values, with quoted internal chars';

$x = `$cmd -m csv $td/file`;
like $x, qr/^_,Name,.*"example 1.*"Fr|an.*2222".*555-8888.*cwong.*"squash"\n$/s,
	'CSV default phone book values';

$x = `$cmd -m "csv:_" $td/file`;
like $x, qr/^_\n"example 1".*"example 3"\n$/s,
	'CSV single value, label-less value';

$x = `$cmd -m "csv:Group" $td/file`;
like $x, qr/^Group\n"family".*"squash"\n$/s,
	'CSV single value, last named value';

remove_td();
}
