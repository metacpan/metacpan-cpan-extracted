#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use lib 't/lib';
use Test::More;
use EO::Twin qw(imp fresh);

BEGIN { plan skip_all => 'package names beyond ASCII need perl 5.16' if $] < 5.016 }

no strict 'refs';

{ package EO::Plus;  use Ex::Op; our @EXPORT_OK = ('+été'); sub été { 'ete' } }
{ package EO::Mixed; use Ex::Op; our @EXPORT_OK = ('aé', 'été'); our %EXPORT_TAGS = ('tàg' => ['été']); sub aé { 'ae' } sub été { 'ete' } }
{ package EO::Latin; use Ex::Op; our @EXPORT_OK = ('été'); sub été { 'latin' } }
{ package EO::Ωmega;   use Ex::Op; our @EXPORT_OK = ('plain', 'été'); sub plain { 'plain' } sub été { 'été' } }

{
    my $p = fresh();
    is( imp('EO::Latin', $p, 'été'), undef, 'a name beyond ASCII from a package within it' );
    is( &{"${p}::été"}(), 'latin', '... is installed' );
}

{
    my $p = fresh();
    is( imp('EO::Ωmega', $p, 'plain'), undef, 'a plain name from a package named beyond Latin-1' );
    is( &{"${p}::plain"}(), 'plain', '... is installed' );
    is( imp('EO::Ωmega', $p, 'été'), undef, '... and so is one beyond ASCII from it' );
    is( &{"${p}::été"}(), 'été', '... with the right body' );
}

{
    my $p = fresh();
    is( imp('EO::Mixed', $p, 'aé'), undef, 'a name beyond ASCII after its first character' );
    is( &{"${p}::aé"}(), 'ae', '... is installed' );
    like( imp('EO::Plus', fresh(), '+été'), qr/^Can't export symbol: \+été at /, 'an unknown sigil on a name beyond ASCII' );
    is( imp('EO::Mixed', $p, '/é/'), undef, 'a pattern beyond ASCII' );
    is( &{"${p}::été"}(), 'ete', '... matches' );
    is( imp('EO::Mixed', fresh(), ':tàg'), undef, 'a tag beyond ASCII' );
    is( imp('EO::Mixed', fresh(), 'été', ':tàg'), undef, 'a name beyond ASCII beside a tag' );
}

done_testing;
