
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..last_test_to_print\n"; }
END { print "not ok 1\n" unless $loaded; }

use HTML::Highlight;
# require "Highlight.pm";

###

print "2..first highlighting test\n";

my $doc = qq{
<html>
<text tag="value">Blah</text>
Textual car misinformation reality sex pride is your own destiny
purity seduction of miserable voices characters. For all your needs in this
world of piss and misbehaviour. We all are bullshit people here. No way from
this horrible place of death and sorrow.
<character>Text</character>
Contextual
</html>
};

my $hl = new HTML::Highlight (
	words => [ 'blah', 'text', 'character', 'span' ],
	wildcards => [ undef, '%', '*' ],
	colors => [ 'red', 'green' ],
	debug => 0
);

my $hldoc = $hl->highlight($doc);

if ($hldoc eq qq{
<html>
<text tag="value"><span style="background-color: red">Blah</span></text>
<span style="background-color: green">Textual</span> car misinformation reality sex pride is your own destiny
purity seduction of miserable voices <span style="background-color: red">characters</span>. For all your needs in this
world of piss and misbehaviour. We all are bullshit people here. No way from
this horrible place of death and sorrow.
<character><span style="background-color: green">Text</span></character>
Contextual
</html>
}) {
	print "ok 2\n";
}
else {
	print "not ok 2\n";
}

#print "$doc\n";
#print "$hldoc\n";

###

print "3..first preview context test\n";

my $sections = $hl->preview_context($doc, 10);

=item
print "$sections\n";
my $len = @{$sections};
print "len = $len\n";
{
	local $, = "\n---\n";
	print @{$sections};
}
print "\n";
=cut

if ($sections->[0] eq qq{

Blah
Textual car misinformation reality sex}
	and $sections->[1] eq qq{seduction of miserable voices characters. For all your needs in this
world of}) {
	print "ok 3\n";
}
else {
	print "not ok 3\n";
}

###

$loaded = 1;
print "ok 1\n";
