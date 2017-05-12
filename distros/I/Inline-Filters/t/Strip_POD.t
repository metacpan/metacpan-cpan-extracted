BEGIN { print "1..2\n"; }

use Inline C => <<'END', FILTERS => 'Strip_POD';

=head1 NAME

add - returns the sum of two integers

=cut

int add(int x, int y) { return x + y; }

=head1 NAME

subtract - returns the difference of two integers

=cut

int subtract(int x, int y) { return x - y; }

END

print "not " unless add(5, 7) == 12;
print "ok 1\n";

print "not " unless subtract(5, 7) == -2;
print "ok 2\n";
