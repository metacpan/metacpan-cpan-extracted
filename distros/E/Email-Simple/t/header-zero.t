use Test::More tests => 1;
use Email::Simple;

my $m = Email::Simple->new("Foo-bar: foo\n");
$m->header_set("Foo-bar", "0000000000000000000000000000000000000000000000000000000000000000000 0");
is($m->as_string, "Foo-bar: 0000000000000000000000000000000000000000000000000000000000000000000\n 0\n\n", "Number zero in header");
