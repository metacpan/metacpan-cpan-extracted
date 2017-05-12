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

swarn( "foo" );
is( $warnings[0], "=== foo by t/03-swarn.main.t[13]: main::" );

swarn( "bar" );
is( $warnings[1], "=== bar by t/03-swarn.main.t[16]: main::" );
