use strict;
use warnings;
use Log::Sigil qw( swarn );
use Test::More tests => 3;
use Test::Output;

my @warnings;
$SIG{__WARN__} = sub {
    chomp( my $swarn = join q{ }, @_ );
    push @warnings, $swarn;
};

sub foo {
    swarn( "foo" );
}

sub bar {
    swarn( "foo" );
    swarn( "bar" );
}

foo( );
is( $warnings[0], "+++ foo by t/04-swarn.sub.t[14]: main::foo" );

bar( );
is( $warnings[1], "!!! foo by t/04-swarn.sub.t[18]: main::bar" );
is( $warnings[2], "!!! bar by t/04-swarn.sub.t[19]: main::bar" );
