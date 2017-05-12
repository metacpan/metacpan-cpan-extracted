package Hubot::Scripts::help;
$Hubot::Scripts::help::VERSION = '0.2.8';
use strict;
use warnings;

sub load {
    my ( $class, $robot ) = @_;
    $robot->respond(
        qr/help\s*(.*)?$/i,
        sub {
            my $msg   = shift;           # Hubot::Response
            my @helps = $robot->helps;

            my $robotName = $robot->name;
            unless ( $robotName =~ m/^hubot$/ ) {
                map {s/hubot/$robotName/ig} @helps;
            }

            if ( $msg->match->[0] ) {
                my $regex = $msg->match->[0];
                @helps = grep { $_ =~ /$regex/i } @helps;
            }

            map {s/^/\# /} @helps;
            $msg->send(@helps);
        }
    );

    $robot->respond(
        qr/commands? *$/i,
        sub {
            my $msg = shift;
            $msg->send( join( ', ', $robot->commands ) );
        }
    );
}

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Scripts::help

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    hubot commands - Displays all commands at oneline
    hubot help - Displays all of the help commands that Hubot knows about
    hubot help <query> - Displays all help commands that match <query>

=head1 DESCRIPTION

These commands are grabbed from pod at the C<SYNOPSIS> section each file.

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
