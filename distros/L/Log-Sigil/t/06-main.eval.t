use strict;
use warnings;
use Log::Sigil qw( swarn );
use Test::More tests => 2;
use Test::Output;

my @warnings;
$SIG{__WARN__} = sub {
    chomp( my $swarn = join q{ }, @_ );
    push @warnings, $swarn;
};

eval {
    swarn( "foo" );
    swarn( "bar" );
};

is( $warnings[0], "+++ foo by t/06-main.eval.t[14]: (eval)::13" );
is( $warnings[1], "+++ bar by t/06-main.eval.t[15]: (eval)::13" );
