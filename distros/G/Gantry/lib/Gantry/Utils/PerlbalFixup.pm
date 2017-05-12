package Gantry::Utils::PerlbalFixup;

use strict;

sub handler {
    my $r = shift;

    $r->connection->remote_ip( $r->header_in('X-Forwarded-For') )
        if $r->header_in('X-Forwarded-For') ne "";

    return 1;
}
1;

=head1 NAME

Gantry::Utils::PerlbalFixup - This module will set the client ip

=head1 SYNOPSIS

 #httpd.conf or some such
 #can be any Perl*Handler
 PerlInitHandler Gantry::Utils::PerlbalFixup

=head1 DESCRIPTION

This module will set the proper client ip using the X-Forwarded-For header
which is set by Perlbal and other proxy methods. This module should be loaded
at the PerlInitHandler or PerlReadParseHeaders phase during the request life-
cycle

=head1 METHODS

=head2 handler

The apache fixup handler.  Stores the value of the X-Forwarded-For header
in the remote_ip of the request's connection, so apps behind a perlbal proxy
can tell who their client is.

=head1 SEE ALSO

mod_perl(3)

=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>

