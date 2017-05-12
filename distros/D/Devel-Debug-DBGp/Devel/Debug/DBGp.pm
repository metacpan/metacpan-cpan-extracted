package Devel::Debug::DBGp;

=head1 NAME

Devel::Debug::DBGp - Perl DBGp debugger (derived from Komodo remote debugging helper)

=head1 SYNOPSIS

From the command line:

    DBGP_OPTS="RemotePort=localhost:9000" perl -I/path/to/lib/dbgp-helper -d myscript.pl

From an helper module:

    unshift @INC, Devel::Debug::DBGp->debugger_path;
    $ENV{DBGP_OPTS} = "RemotePort=localhost:9000";
    require 'perl5db.pl';

For L<Plack> applications see L<Plack::Middleware::DBGp>.

=head1 DESCRIPTION

A modified version of ActiveState's Komodo remote debugging helper. It
aims to be a compliant implementation of the L<DBGp
protocol|http://xdebug.org/docs-dbgp.php> by default, but with the
option of emulating Xdebug-specific quirks, for compatibility with
existing clients that assume Xdebug behaviour.

When debugging, the debugger running inside the application
establishes a connection to an external DBGp client (typically a GUI
program) that allows to inspect the program state from the outside.

This implementation has been tested with L<pugdebug|http://pugdebug.com>,
L<Sublime Text Xdebug plugin|https://github.com/martomo/SublimeTextXdebug>
and L<Vim VDebug plugin|https://github.com/joonty/vdebug>.

Note that it might not work with Komodo itself (by accident, I don't
own a copy to test compatibility, bug reports welcome).

=head1 ENVIRONMENT VARIABLES

=head2 PERLDB_OPTS

Space-separated list of debugger options:

=over 4

=item RemotePort

    PERLDB_OPTS="... RemotePort=hostname:port ..."

Host/port to which the debugger connects, alternative to
C<RemotePath>.

=item RemotePath

    PERLDB_OPTS="... RemotePath=/path/to/unix/socket ..."

Unix-domain socket path to which the debugger connects, alternative to
C<RemotePort>.

=item LogFile

    PERLDB_OPTS="... LogFile=/path/to/file ..."

If set, debugging information for the debugger itself is appended to
the specified path.

=item Alarm, Async

    PERLDB_OPTS="... Alarm=1 ..."
    PERLDB_OPTS="... Async=1 ..."

Periodically check for C<break> commands sent by the debugger (this
uses L<perlfunc/alarm> internally).

=item RecursionCheckDepth

    PERLDB_OPTS="... RecursionCheckDepth=N ..."

Break into the debugger when recursion level reaches the specified
value.

=item Xdebug

    PERLDB_OPTS="... Xdebug=[0,1] ..."
    PERLDB_OPTS="... Xdebug=opt1,opt2,... ..."

Set one or more Xdebug compatibility options:

=over 4

=item send_position_after_stepping

Whether to include an C<< <xdebug:message> >> tag in step command
response specifying the current file name and line number.

=item property_without_value_tag

Emit the value of scalar properties directly inside the C<< <property>
>> tag, without a C<< <value> >> wrapper.

=item nested_properties_in_context

Return up to C<max_depth> levels for properties in the C<context_get>
response, rather than returning just the root value and letting the
debugger drill down if needed.

=item temporary_breakpoint_state

Return temporary breakpoint state as C<temporary> instead of returning it
as C<enabled>.

=back

=item ConnectAtStart

    PERLDB_OPTS="... ConnectAtStart=[1|0] ..."

Defaults to C<1>; whether the debugger program should connect to the
DBGp client early during startup.

When set to C<0>, use L</connectOrReconnect> to initiate the connection.

=item KeepRunning

    PERLDB_OPTS="... KeepRunning=[0|1] ..."

Defaults to C<0>; whether the debugged program should keep running
with debugging disabled if the DBGp client drops the connection.

=back

=head2 RemotePort

Equivalent to adding C<RemotePort=...> to C<PERLDB_OPTS>.

=head2 DEBUGGER_APPID

If set, it is returned as the C<appid> attribute of the C<init>
message (defaults to L<perlvar/$$> otherwise.

=head2 DBGP_IDEKEY

If set, it is returned as the C<idekey> attribute of the C<init> message.

=head2 DBGP_COOKIE

If set, it is returned as the C<session> attribute of the C<init> message.

=head2 HOST_HTTP

If set, overrides the value of the C<hostname> attribute in the C<init> message.

=head2 DBGP_PERL_IGNORE_PADWALKER

If set to a true value, does not use L<PadWalker> to get the list of
local variables, but uses a combination of L<B> and C<eval STRING>.

=head2 DBGP_PURE_PERL, DBGP_XS_ONLY

The default is to try to load an XS helper for the debugger, and fall
back to the pure-Perl implementation if loading the XS helper fails
(or the helper has not been built). Setting C<DBGP_PURE_PERL> or
C<DBGP_XS_ONLY> allows to explicitly choose one or the other.

=head1 FUNCTIONS

There is no need to use any of the functions below unless you are
writing an higher-level interface to the debugger (for example
L<Plack::Middleware::DBGp>).

=head2 connectOrReconnect

    DB::connectOrReconnect();

Connects to the debugger client (closes the current connection if any).

If the debugger client is not listening at the specified endpoint,
debugging is disabled (via L</disable>) and execution continues
normally.

=head2 isConnected

    my $connected = DB::isConnected();

Whether the debugger is connected to a client.

=head2 disable

    DB::disable();

Disables debugging. The debugged program should run at nearly normal
speec with debugging disabled..

=head2 enable

    DB::enable();

Re-enables debugging after a L</disable> call.

=head2 disconnect

    DB::disconnect();

Disconnects from the debugger client.

=cut

use strict;
use warnings;

our $VERSION = '0.20';

sub debugger_path {
    for my $dir (@INC) {
        return "$dir/dbgp-helper"
            if -f "$dir/dbgp-helper/perl5db.pl"
    }

    die "Unable to find debugger library 'dbgp-helper' in \@INC (@INC)";
}

1;

__END__

=head1 SEE ALSO

L<perldebguts>, L<http://code.activestate.com/komodo/remotedebugging/>

=head1 AUTHORS

Mattia Barbon <mbarbon@cpan.org> - packaging and misc changes/fixes

derived from ActiveState Komodo Remote Debugging Helper

derived from the Perl 5 debugger (perl5db.pl)

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the
L<Artistic License|http://www.opensource.org/licenses/artistic-license.php>.

=cut
