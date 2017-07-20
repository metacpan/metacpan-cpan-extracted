use Test::Most;
use JSON::Path;

# Test demonstrating RT 122493, "Changed behavior - get() returns an array with a single, undef element when no results are found"
# https://rt.cpan.org/Ticket/Display.html?id=122493
my $orig = { bar => 1 };

my $p = JSON::Path->new("\$foo");

my $res = $p->get($orig);

is_deeply ( $orig, { bar => 1 }, "hashref is unchanged");

done_testing();
