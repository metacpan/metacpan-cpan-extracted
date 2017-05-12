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

my $foo = sub {
    swarn( "foo" );
};

my $bar = sub {
    swarn( "foo" );
    swarn( "bar" );
};

$foo->( );
is( $warnings[0], "+++ foo by t/05-swarn.anon.t[14]: main::__ANON__::22" );

$bar->( );
is( $warnings[1], "!!! foo by t/05-swarn.anon.t[18]: main::__ANON__::25" );
is( $warnings[2], "!!! bar by t/05-swarn.anon.t[19]: main::__ANON__::25" );

