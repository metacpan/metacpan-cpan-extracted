# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Heap-Simple.t'
#########################
use vars qw($VERSION);
$VERSION = "0.11";

use Test;
BEGIN {
    plan tests => 2;
    @Heap::Simple::implementors = qw(CGI);
}
use Heap::Simple;
ok(1); # We can load

my $cgi = Heap::Simple->new();
ok($cgi->isa("CGI"));
