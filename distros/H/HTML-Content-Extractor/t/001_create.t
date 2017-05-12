BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $create;}

use HTML::Content::Extractor;

my $obj = HTML::Content::Extractor->new();
undef $obj;
$create = 1;

print "ok 1\n";
