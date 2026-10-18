#!/usr/bin/perl -w
# The palettes HTML::D3 carries, checked against the d3 that publishes them.
#
# t/palette.t is the offline oracle: it holds D3's scheme names, expressions and
# counts, so the suite can check the module on a machine with no JavaScript
# runtime.  An oracle is still a transcription, though, and a transcription can
# be wrong - a colour typed one digit out, or a scheme copied from the wrong
# version - and still agree with itself, because the test and the module were
# written from the same reading of D3's source.
#
# This test asks d3 itself instead.  It runs Node, loads the d3 package and
# compares each scheme's colours, and the number of them, with what
# HTML::D3->palette() hands back.  When d3 is there the comparison is against
# the library a browser draws with, not against a copy of it.
#
# Neither Node nor d3 is a prerequisite of this distribution: an installation
# without a JavaScript runtime is a normal installation, not a broken one, so
# the file skips - with the reason - when it cannot reach them.  To run it:
#
#     npm install d3         # in this directory
#     prove -l t/d3-schemes.t
#
# The script tries require() first, so NODE_PATH is honoured for an installation
# elsewhere, and falls back to import() for the ESM-only d3 v7 package.

use strict;
use warnings;

use IPC::Open3 qw(open3);
use JSON::MaybeXS qw(decode_json);
use Symbol qw(gensym);
use Test::Most;

use HTML::D3;

# The scheme names this distribution publishes, and the expression d3 publishes
# each one under.  The module's names are the keys; d3's are what the Node
# script reads from the package.  The list is written out here rather than read
# from the module, so that a scheme the module has lost or renamed is reported
# by this test too.
my %D3_SCHEME = (
	category10 => 'schemeCategory10',
	tableau10  => 'schemeTableau10',
	set2       => 'schemeSet2',
	set3       => 'schemeSet3',
	paired     => 'schemePaired',
);

# Read by d3 in the script below.  Sorted so that a missing scheme is reported
# in the same order every run.
my @D3_NAMES = map { $D3_SCHEME{$_} } sort keys %D3_SCHEME;

my $NODE_SCRIPT = <<'JS';
const names = ['schemeCategory10', 'schemeTableau10', 'schemeSet2', 'schemeSet3', 'schemePaired'];

function answer(d3) {
	const schemes = {};
	for (const name of names) {
		schemes[name] = d3[name];
	}
	process.stdout.write(JSON.stringify(schemes));
}

// d3 v7 is published as ES modules, which require() cannot load on older
// Node; anything else it can.  Either way the failing case is the same: no
// d3 installed, which is reported below as a skip rather than a failure.
let loaded;
try {
	loaded = Promise.resolve(require('d3'));
} catch (error) {
	loaded = import('d3');
}

loaded.then(answer).catch(error => {
	console.error(error && error.message ? error.message : String(error));
	process.exit(1);
});
JS

my $node_version = _node_output('--version');
plan skip_all => 'Node.js is not installed, so d3 cannot be asked for the palettes it publishes'
	unless defined($node_version);

my ($json, $stderr, $status) = _run('node', '-e', $NODE_SCRIPT);
plan skip_all => 'd3 is not installed for Node, so its palettes cannot be compared'
	. ($stderr =~ /\S/ ? ': ' . _first_line($stderr) : '')
	unless defined($status) && $status == 0 && defined($json) && length($json);

my $d3 = eval { decode_json($json) };
plan skip_all => 'd3 answered with output that is not JSON, so its palettes cannot be compared: '
	. ($@ || 'empty output')
	unless ref($d3) eq 'HASH';

# The vocabulary has to be d3's: a scheme added to one side and not the other
# would let a chart draw a palette a map cannot name, or a map name a palette
# the chart cannot draw.
is_deeply([sort @{HTML::D3->categorical_schemes()}], [sort keys %D3_SCHEME],
	'categorical_schemes() names exactly the schemes compared here');

for my $scheme (sort keys %D3_SCHEME) {
	my $js     = $D3_SCHEME{$scheme};
	my $theirs = $d3->{$js};

	# d3 answering without a scheme is a failure, not a skip: d3 was reached,
	# so the package is there and the module is describing a palette it does
	# not have.
	is(ref($theirs), 'ARRAY', "d3 publishes $js") or next;

	my $ours = HTML::D3->palette($scheme);
	isa_ok($ours, 'ARRAY', "palette('$scheme')");

	# The count first: when d3 has gained or lost a colour, "10, not 12" says
	# what changed, where the comparison below would print both whole lists.
	is(scalar(@$ours), scalar(@$theirs),
		"palette('$scheme') has the " . scalar(@$theirs) . " colours $js has");

	is_deeply($ours, $theirs,
		"palette('$scheme') is ${js}'s colours, in d3's order")
		or diag(explain({ html_d3 => $ours, d3 => $theirs }));
}

done_testing();

# The output of a node command that succeeded, or undef if node could not be
# run or answered with an error.  Used only for the version probe, where either
# answer means "no d3 to ask".
sub _node_output
{
	my @arguments = @_;

	my ($stdout, $stderr, $status) = _run('node', @arguments);

	return unless defined($status) && $status == 0;

	chomp(my $version = $stdout);
	return $version;
}

# Run a command without a shell, capturing both streams: (stdout, stderr, exit
# status), or undef if the command could not be started at all.  No shell means
# the JavaScript, with its quotes and newlines, reaches node as one argument.
sub _run
{
	my @command = @_;

	my ($stdin, $stdout);
	my $stderr = gensym;
	my $pid = eval { open3($stdin, $stdout, $stderr, @command); };
	return unless $pid;

	close($stdin);

	my $out = do { local $/; <$stdout> };
	my $err = do { local $/; <$stderr> };
	waitpid($pid, 0);

	return (defined($out) ? $out : '', defined($err) ? $err : '', $? >> 8);
}

# The first line of node's complaint, for a skip message that stays readable
# when the error is several lines of stack trace.
sub _first_line
{
	my ($text) = @_;

	($text) = split /\n/, $text;
	return $text;
}
