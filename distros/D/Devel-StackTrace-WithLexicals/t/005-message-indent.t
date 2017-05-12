use strict;
use warnings;
use Test::More tests => 2;
use Devel::StackTrace;
use Devel::StackTrace::WithLexicals;

sub foo {
    return Devel::StackTrace::WithLexicals->new(message => "blah", indent => 1);
}

my $t = foo();
my $trace = $t->as_string;

unlike $trace, qr/^Trace begun/, "has the message";
like $trace, qr/^\tmain::foo/m, "indent works";


