#!/usr/bin/perl -w
use strict;

use File::Basename          qw< dirname >;
use lib dirname(__FILE__) . '/../inc';

use TyeTest  qw<
    plan skip Okay True False Note Dump SkipIf Lives Dies Warns LinesLike >;

BEGIN {
    my $t = dirname( __FILE__ );
    if( -d "$t/../blib" ) {
        lib->import( "$t/../blib/arch", "$t/../blib/lib" );
    } elsif( -d "$t/../lib" ) {
        lib->import( "$t/../lib" );
    }
}

plan( tests => 22 );

require IPC::Semaphore::SmokeSignals;
my $mod = 'IPC::Semaphore::SmokeSignals';

Okay( 1, 1, 'Module loads' );

# Make this test die if it ever hangs:
alarm( 10 );

Okay( undef, *LightUp{CODE}, 'LightUp not yet imported' );

$mod->import();
Okay( undef, *LightUp{CODE}, 'LightUp not imported by default' );

$mod->import('LightUp');
Okay( sub{\&IPC::Semaphore::SmokeSignals::LightUp},
    sub{*LightUp{CODE}}, 'LightUp imported explicitly' );

Okay( *JoinUp{CODE}, *MeetUp{CODE}, 'JoinUp MeetUp not here' );
$mod->import('JoinUp');
Okay( sub{\&IPC::Semaphore::SmokeSignals::JoinUp},
    sub{*JoinUp{CODE}}, 'JoinUp imported explicitly' );
$mod->import('MeetUp');
Okay( sub{\&IPC::Semaphore::SmokeSignals::MeetUp},
    sub{*MeetUp{CODE}}, 'MeetUp imported explicitly' );

Dies( "Can't export nonsense", sub {
    $mod->import('Ignite');
}, qr/Ignite/, qr/not export/ );

my $pipe = LightUp();
True( $pipe, 'Can create a pipe' );

my $dragon = $pipe->Puff();
True( $dragon, 'Can toke' );

my $isWin = $^O =~ /MSWin/ ? 'blocking(0) is a no-op on Windows' : '';
if( $isWin ) {
    skip( $isWin );
} else {
    False( $pipe->Puff(1), 'Impatience fails' );
}

undef $dragon;
$dragon = $pipe->Puff();
True( $dragon, 'Can re-toke' );

if( $isWin ) {
    skip( $isWin );
} else {
    False( $pipe->Puff(1), 'Impatience re-fails' );
}

$dragon->Exhale();
my $puff = $pipe->Puff();
True( $puff, 'Can re-toke after Exhale' );

if( $isWin ) {
    skip( $isWin );
} else {
    True( $pipe->Extinguish(1), "Can't extinguish early" );
}

undef $puff;

False( $pipe->Extinguish(), "Can extinguish" );

Dies( "Can't toke cold pipe", sub {
    $pipe->Puff();
}, qr/going out/ );

if( $isWin ) {
    skip( $isWin )
        for 1..2;
} else {
    Dies( "Exceeding your system buffer size fails", sub {
        LightUp(99999)
    }, qr/Can't stoke/ );
    my $err = $@;
    if( $err =~ /Can't stoke pipe \(with '([0-9]+)'\): (.*)/ ) {
        my( $tokin, $errno ) = ( $1, $2 );
        Note( join ' ', " Pipe capacity <", $tokin*length($tokin), '?' );
        Note( " $errno" );
    } else {
        Note( " Error: $@" );
    }
}
