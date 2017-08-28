package Mercury::Command::mercury::broker;
our $VERSION = '0.015';
# ABSTRACT: Mercury message broker command

#pod =head1 SYNOPSIS
#pod
#pod   Usage: mercury broker [OPTIONS]
#pod
#pod     mercury broker
#pod     mercury broker -m production -l http://*:8080
#pod     mercury broker -l http://127.0.0.1:8080 -l https://[::]:8081
#pod     mercury broker -l 'https://*:443?cert=./server.crt&key=./server.key'
#pod
#pod   Options:
#pod     -m, --mode <mode>                    Set the mode, defaults to the value
#pod                                          of MOJO_MODE, PLACK_ENV, or 
#pod                                          "development"
#pod     -b, --backlog <size>                 Listen backlog size, defaults to
#pod                                          SOMAXCONN
#pod     -c, --clients <number>               Maximum number of concurrent
#pod                                          connections, defaults to 1000
#pod     -i, --inactivity-timeout <seconds>   Inactivity timeout, defaults to 4
#pod                                          hours
#pod     -l, --listen <location>              One or more locations you want to
#pod                                          listen on, defaults to the value of
#pod                                          MOJO_LISTEN or "http://*:3000"
#pod     -p, --proxy                          Activate reverse proxy support,
#pod                                          defaults to the value of
#pod                                          MOJO_REVERSE_PROXY
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<Mercury::Command::broker> starts the L<Mercury> application.
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Command';
use Mercury;

use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use Mojo::Server::Daemon;

#pod =attr description
#pod
#pod     my $description = $cmd->description;
#pod     $cmd = $cmd->description('Foo');
#pod
#pod Short description of this command, used for the command list.
#pod
#pod =cut

has description => 'Start WebSocket message broker';

#pod =attr usage
#pod
#pod     my $usage = $cmd->usage;
#pod     $cmd = $cmd->usage('Foo');
#pod
#pod Usage information for this command, used for the help screen.
#pod
#pod =cut

has usage => sub { shift->extract_usage };

#pod =method run
#pod
#pod   $cmd->run(@ARGV);
#pod
#pod Run this command.
#pod
#pod =cut

sub run {
    my ( $self, @args ) = @_;

    # If we're started with the 'mercury' script, we're our own app and we need
    # to serve ourselves. This ensures that the initialization already done
    # isn't done twice.
    my $app = $self->app->isa( 'Mercury' ) ? $self->app : Mercury->new;

    my $daemon = Mojo::Server::Daemon->new(
        app => $app,
        inactivity_timeout => 4 * 60 * 60,
    );

    GetOptionsFromArray( \@args,
        'b|backlog=i' => sub { $daemon->backlog($_[1]) },
        'c|clients=i' => sub { $daemon->max_clients($_[1]) },
        'i|inactivity-timeout=i' => sub { $daemon->inactivity_timeout($_[1]) },
        'l|listen=s' => \my @listen,
        'p|proxy' => sub { $daemon->reverse_proxy(1) },
    );

    if ( @listen ) {
        $daemon->listen(\@listen);
    }
    elsif ( my $conf = eval { $app->config->{ broker } } ) {
        if ( $conf->{listen} ) {
            $daemon->listen( [ $conf->{listen} ] );
        }
    }

    $daemon->run;
}

1;

__END__

=pod

=head1 NAME

Mercury::Command::mercury::broker - Mercury message broker command

=head1 VERSION

version 0.015

=head1 SYNOPSIS

  Usage: mercury broker [OPTIONS]

    mercury broker
    mercury broker -m production -l http://*:8080
    mercury broker -l http://127.0.0.1:8080 -l https://[::]:8081
    mercury broker -l 'https://*:443?cert=./server.crt&key=./server.key'

  Options:
    -m, --mode <mode>                    Set the mode, defaults to the value
                                         of MOJO_MODE, PLACK_ENV, or 
                                         "development"
    -b, --backlog <size>                 Listen backlog size, defaults to
                                         SOMAXCONN
    -c, --clients <number>               Maximum number of concurrent
                                         connections, defaults to 1000
    -i, --inactivity-timeout <seconds>   Inactivity timeout, defaults to 4
                                         hours
    -l, --listen <location>              One or more locations you want to
                                         listen on, defaults to the value of
                                         MOJO_LISTEN or "http://*:3000"
    -p, --proxy                          Activate reverse proxy support,
                                         defaults to the value of
                                         MOJO_REVERSE_PROXY

=head1 DESCRIPTION

L<Mercury::Command::broker> starts the L<Mercury> application.

=head1 ATTRIBUTES

=head2 description

    my $description = $cmd->description;
    $cmd = $cmd->description('Foo');

Short description of this command, used for the command list.

=head2 usage

    my $usage = $cmd->usage;
    $cmd = $cmd->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

=head2 run

  $cmd->run(@ARGV);

Run this command.

=head1 SEE ALSO

=over 4

=item *

L<mercury>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
