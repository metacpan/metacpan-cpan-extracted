#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Docker::Client;
use Mojo::Util qw( trim );

my $client = Docker::Client->new();

eval { $client->SystemPing()->result()->is_success() };
plan skip_all => 'Docker is not running!'
  if ($@);

my $ctx = $client->ContainerCreate(
    {},
    json => {
        Image        => 'ubuntu',
        AttachStdin  => 0,
        AttachStdout => 1,
        AttachStderr => 1,
        Tty          => 1,
        Cmd          => [ '/bin/bash', '-c', 'tail -f /etc/resolv.conf' ],
        OpenStdin    => 0,
        StdinOnce    => 0
    }
);

ok( $ctx->result()->is_success(), 'ContainerCreate' );
my $container = $ctx->result()->json();

## ContainerInspect
{
    my $data =
      $client->ContainerInspect( { id => $container->{Id} } )->result()->json();

    ok( defined $data, 'ContainerInspect' );
};

## ContainerStart
{
    my $tx = $client->ContainerStart( { id => $container->{Id} } );
    ok( $tx->result()->is_success(), 'ContainerStart' );
};

## ContainerStop
{
    my $tx = $client->ContainerStop( { id => $container->{Id} } );
    ok( $tx->result()->is_success(), 'ContainerStop' );
};

## ContainerLogs
{
    my $container =    ## no critic (Variables::ProhibitReusedNames)
      $client->ContainerCreate(
        {},
        json => {
            Image => 'ubuntu',
            Tty   => 1,
            Cmd   => [
                '/bin/bash', '-c',
                'for i in $(seq 5); do echo $i; sleep 1; done' ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
            ],
        }
    )->result()->json();

    $client->ContainerStart( { id => $container->{Id} } );

    my @lines = ();
    $client->api()->on(
        after_build_tx => sub {
            my ( $ua, $tx ) = @_;

            $tx->res()->content()->unsubscribe('read')->on(
                read => sub {
                    my ( $content, $bytes ) = @_;
                    push @lines, $bytes;
                }
            );
        }
    );

    $client->ContainerLogs(
        {
            id     => $container->{Id},
            stderr => 1,
            stdout => 1,
            follow => 1,
        }
    );

    $client->api()->unsubscribe('after_build_tx');

    my $output = trim( join q{}, @lines );
    $output =~ s/\R//gmxs;
    is( $output, '12345', 'ContainerLogs' );

    $client->ContainerStop( { id => $container->{Id} } );
}

done_testing();
