#!perl
# https://rt.cpan.org/Public/Bug/Display.html?id=53521
# Bug #53521 for List-Search: Needs to require Exporter

use strict;
use warnings;

BEGIN { print "1..3\n" };

#
# Test::More uses Exporter (obviously), so
# we have to make our own version of ok.
#
# (Partially based on perl5's t/test.t...)
#
my $t = 1;

sub ok {
    my ($pass, $name) = @_;
    my (undef, $filename, $lineno) = caller;

    my $out;
    $out  = $pass ? "ok" : "not ok";
    $out .= " " . $t++ . " - $name\n";
    print STDOUT $out;
    return $pass if $pass;

    my $bad;
    $bad  = "Failed test '$name' ";
    $bad .= "at $filename line $lineno\n";
    diag ($bad);

    $pass;
}

sub diag {
    for (split /^/, join q[], @_) {
        chomp;
        print STDERR "# $_\n";
    }
}

require List::Search;

# Let's see if you can import at all...
ok (List::Search->can("import"), "List::Search can import to us");

eval { List::Search->import(qw(list_search)); };

# This is likely to pass
ok (!$@, "List::Search->import(list_search) works");

# This is unlikely to pass
ok (exists &list_search, "list_search is imported");
