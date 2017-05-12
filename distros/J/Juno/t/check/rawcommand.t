#!perl

use strict;
use warnings;

use AnyEvent;
use Test::More;
use Test::Fork;
use Test::Fatal;
use Juno::Check::RawCommand;
use File::Temp 'tempfile';

{
    local $@ = undef;
    eval 'use System::Command';
    $@ and plan skip_all => 'System::Command is required for this test';
}

plan tests => 6;

like(
    exception { Juno::Check::RawCommand->new },
    qr/^\QMissing required arguments: cmd\E/,
    'Attribute cmd required',
);

is(
    exception { Juno::Check::RawCommand->new( host => 'this', cmd => 'that' ) },
    undef,
    'Successfully created RawCommand check object',
);

my $cv    = AnyEvent->condvar;
my $check = Juno::Check::RawCommand->new(
    hosts     => ['thedude'],
    cmd        => 'pick %h',
    on_success => sub { $cv->send },
);

{
    no warnings qw/redefine once/;
    *System::Command::new = sub {
        my $class = shift;
        my $run   = shift;

        is( $class, 'System::Command', 'Correct class'          );
        is( $run,   'pick thedude',    'Command template works' );

        return bless {}, $class;
    };

    *System::Command::stdout = sub {
        my ( $fh, $file ) = tempfile;
        return $fh;
    };

    *System::Command::stderr = sub {
        my ( $fh, $file ) = tempfile;
        return $fh;
    };

    *System::Command::exit = sub {0};

    # appease System::Command
    *System::Command::_reap = sub {0};
    *System::Command::close = sub {0};
}

isa_ok( $check, 'Juno::Check::RawCommand' );
fork_ok( 2, sub {
    $check->check;
    $cv->recv;
} );

