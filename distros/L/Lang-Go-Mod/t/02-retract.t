package main;
use Test2::V0;
use Lang::Go::Mod qw(_parse_retract);

# missing retract string
ok(
    dies {
        _parse_retract();
    }
  ) or note($@);

is( _parse_retract('v1.0.0'),   'v1.0.0', 'basic single version' );
is( _parse_retract(' v1.0.0 '), 'v1.0.0', 'single version with whitespace' );
is( _parse_retract(' v1.0.0 // why '),
    'v1.0.0', 'single version with whitespace and rationale' );
is( _parse_retract('v1.0.0 # why'), undef, 'bad comment' );
is( _parse_retract('v1.0.0 / why'), undef, 'bad comment' );
is( _parse_retract('unknown junk'), undef, 'not valid' );
is( _parse_retract('// what'),      undef, 'only comment' );

is( _parse_retract('[v1.0.0, v1.1.0]'), '[v1.0.0,v1.1.0]', 'range versions' );
is( _parse_retract('[ v1.0.0, v1.1.0] '),
    '[v1.0.0,v1.1.0]', 'range versions with whitespace' );
is( _parse_retract(' [ v1.0.0, v1.1.0]  // why '),
    '[v1.0.0,v1.1.0]', 'range versions with whitespace and rationale' );
is( _parse_retract('[v1.0.0, v1.1.0'), undef, 'range versions missing ]' );
is( _parse_retract('v1.0.0, v1.1.0]'), undef, 'range versions missing [' );
is( _parse_retract(' [ v1.0.0, v1.1.0] # why '), undef, 'bad comment' );
is( _parse_retract(' [ v1.0.0, v1.1.0] / why '), undef, 'bad comment' );
is( _parse_retract('[v1.0.0, v1.1.0, v1.2.0]'),
    undef, 'range version count not 2' );
is( _parse_retract('[v1.0.0]'),  undef, 'range version count not 2' );
is( _parse_retract('[v1.0.0,]'), undef, 'range version empty' );
is( _parse_retract('[,v1.0.0]'), undef, 'range version empty' );

done_testing;
