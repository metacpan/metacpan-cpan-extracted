package Ereshkigal::App;

use 5.006;
use strict;
use warnings;
use App::Cmd::Setup -app;

=head1 NAME

Ereshkigal::App - App::Cmd app for the ereshkigal bin.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ereshkigal::App;

    Ereshkigal::App->run;

=head1 DESCRIPTION

L<App::Cmd> app providing the C<ereshkigal> CLI. See the various
Ereshkigal::App::Command modules for the subcommands.

=head1 METHODS

=head2 global_opt_spec

Global options available to every subcommand.

    -s|--socket :: Path of the manager unix socket.
        Default :: /var/run/ereshkigal/socket

=cut

sub global_opt_spec {
	return ( [ 'socket|s=s', 'path of the manager unix socket', { default => '/var/run/ereshkigal/socket' } ], );
}

1;
