package Devel::REPL::InProcess;

=head1 NAME

Devel::REPL::InProcess - debugger-like in-process REPL

=head1 SYNOPSIS

    # start the client in a console
    inprocess-repl-client --port 7654 --once

    # somewhere in a running program
    Devel::REPL::Server::Select->run_repl(port => 7654);

=head1 DESCRIPTION

This distribution provides a debugger-like REPL session that can be
spawned in the middle of a program.

L<Devel::REPL::Plugin::InProcess> synchronized the lexical environment
of the REPL with the environemnt where the shell was spawned (which
means you will be able to inspect and modify in-scope lexicals).

C<Devel::REPL::Server::*> and C<Devel::REPL::Client::*> allow using
the REPL for processes not attached to a console.

=cut

use strict;
use warnings;

our $VERSION = '0.05';

1;

=head1 AUTHORS

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
