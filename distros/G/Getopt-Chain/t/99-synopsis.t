#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

our @did;

package My::Command;

    use Getopt::Chain::Declare;

    start [qw/ verbose|v /]; # These are "global"
                             # my-command --verbose initialize ...

    # my-command ? initialize ... --> my-command help initialize ...
    rewrite qr/^\?(.*)/ => sub { "help ".($1||'') };

    # NOTE: Rewriting applies to the command sequence, NOT options

    # my-command about ... --> my-command help about
    rewrite [ ['about', 'copying'] ] => sub { "help $1" };

    # my-command initialize --dir=...
    on initialize => [qw/ dir|d=s /], sub {
        my $context = shift;

        my $dir = $context->option( 'dir' );

        push @did, [ $context->command, dir => $dir ];
        # Do initialize stuff with $dir
    };

    # my-command help
    on help => undef, sub {
        my $context = shift;

        # Do help stuff ...
        # First argument is undef because help
        # doesn't take any options
        
        push @did, [ $context->command, ];
    };

    under help => sub {

        # my-command help create
        # my-command help initialize
        on [ [ qw/create initialize/ ] ] => undef, sub {
            my $context = shift;

            # Do help for create/initialize
            # Both: "help create" and "help initialize" go here

            push @did, [ $context->command, ];
        };

        # my-command help about
        on 'about' => undef, sub {
            my $context = shift;

            # Help for about...

            push @did, [ $context->command, ];
        };

        # my-command help copying
        on 'copying' => undef, sub {
            my $context = shift;

            # Help for copying...

            push @did, [ $context->command, ];
        };

        # my-command help ...
        on qr/^(\S+)$/ => undef, sub {
           my $context = shift;
           my $topic = $1;

            # Catch-all for anything not fitting into the above...
            
            push @did, [ $context->command, "I don't know about \"$topic\"\n" ]
        };
    };

no Getopt::Chain::Declare;

package main;

my $options;

sub run {
    undef @did;
    $options = My::Command->new->run( [ @_ ] );
}

run qw/--verbose/;
ok( $options->{verbose} );
ok( ! @did );

run qw/--verbose about/;
ok( $options->{verbose} );
cmp_deeply( \@did, [ [ "about" ] ] );

run qw/help copying/;
ok( ! $options->{verbose} );
cmp_deeply( \@did, [ [ "copying" ] ] );

run qw/initialize/;
ok( ! $options->{verbose} );
cmp_deeply( \@did, [ [ "initialize", dir => undef ] ] );

run qw/initialize --dir ./;
ok( ! $options->{verbose} );
cmp_deeply( \@did, [ [ "initialize", dir => '.' ] ] );

run qw/-v ? create/;
ok( $options->{verbose} );
cmp_deeply( \@did, [ [ "create" ] ] );

run qw/? xyzzy/;
cmp_deeply( \@did, [ [ "xyzzy", "I don't know about \"xyzzy\"\n" ] ] );
