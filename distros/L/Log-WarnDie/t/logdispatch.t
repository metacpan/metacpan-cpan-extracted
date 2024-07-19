#!perl -w

use warnings;
use strict;

BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

my $tests;
BEGIN {
    eval { require Log::Dispatch::Buffer };
    $tests = $@ ? 1 : 24;
} #BEGIN

use Test::More tests => 2 + $tests;
use strict;
use warnings;

use_ok( 'Log::WarnDie' );
can_ok( 'Log::WarnDie',qw(
 dispatcher
 import
 unimport
) );

SKIP : {
    skip "Log::Dispatch::Buffer not available", $tests unless $tests > 1;

    my $dispatcher = Log::Dispatch->new;
    isa_ok( $dispatcher,'Log::Dispatch' );

    my $channel = Log::Dispatch::Buffer->new( qw(name default min_level debug));
    isa_ok( $channel,'Log::Dispatch::Buffer' );

    $dispatcher->add( $channel );
    is( $dispatcher->output( 'default' ),$channel,'Check if channel activated');

    Log::WarnDie->dispatcher( $dispatcher );

    my $warn = "This warning will be displayed\n";
    warn $warn;
    my $message = $channel->flush;
    is( scalar( @{$message} ),1,"Check if number of messages ok" );
    is( $message->[0]->{'level'},'warning',"Check type of message" );
    is( $message->[0]->{'message'},$warn,"Check message contents" );

    my $carp = "This carp will be displayed\n";
    Carp::carp $carp;
    $message = $channel->flush;
    is( scalar( @{$message} ),1,"Check if number of messages ok" );
    is( $message->[0]->{'level'},'warning',"Check type of message" );
    like( $message->[0]->{'message'},qr#^$carp#,"Check message contents" );

    my $cluck = "This cluck will be displayed\n";
    Carp::cluck $cluck;
    $message = $channel->flush;
    is( scalar( @{$message} ),1,"Check if number of messages ok" );
    is( $message->[0]->{'level'},'warning',"Check type of message" );
    like( $message->[0]->{'message'},qr#^$cluck#,"Check message contents" );

    my $die = "This die will be displayed\n";
    eval {die $die};
    $message = $channel->flush;
    is( scalar( @{$message} ), 1,"Check if number of messages ok" );
    is( $message->[0]->{'level'},'critical',"Check type of message" );
    is( $message->[0]->{'message'},$die, "This die will be displayed" );

    my $croak = "This croak will be displayed\n";
    eval {Carp::croak $croak};
    $message = $channel->flush;
    is( scalar( @{$message} ), 1,"Check if number of messages ok" );
    is( $message->[0]->{'level'},'critical',"Check type of message" );
    like( $message->[0]->{'message'},qr#^$croak#,"Check message contents" );

    my $confess = "This confess will be displayed\n";
    eval {Carp::confess $confess};
    $message = $channel->flush;
    is( scalar( @{$message} ), 1,"Check if number of messages ok" );
    is( $message->[0]->{'level'},'critical',"Check type of message" );
    like( $message->[0]->{'message'},qr#^$confess#,"Check message contents" );

    my $stderr = "This stderr will be displayed\n";
    printf STDERR '%s', $stderr;
    $message = $channel->flush;
    is( scalar( @{$message} ),1,"Check if number of messages ok" );
    is( $message->[0]->{'level'},'error',"Check type of message" );
    like( $message->[0]->{'message'},qr#^$stderr#,"Check message contents" );
} #SKIP
