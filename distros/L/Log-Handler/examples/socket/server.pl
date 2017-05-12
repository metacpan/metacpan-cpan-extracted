#!/usr/bin/perl

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>

=head1 DESCRIPTION

This is a server example for Log::Handler::Output::Socket.

=head1 POWERED BY

     _    __ _____ _____ __  __ __ __   __
    | |__|  |     |     |  \|  |__|\  \/  /
    |  . |  |  |  |  |  |      |  | >    <
    |____|__|_____|_____|__|\__|__|/__/\__\

=head1 COPYRIGHT

Copyright (C) 2007-2009 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;
use warnings;
use IO::Socket::INET;
use Log::Handler::Output::File;

my $sock = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 44444,
    Listen    => 1,
) or die $!;

my $file = Log::Handler::Output::File->new(
    filename => 'server.log',
    mode     => 'append',
    fileopen => 1,
    reopen   => 1,
);

while ( 1 ) {
    $file->log(message => "waiting for next connection\n");

    while (my $request = $sock->accept) {
        while (my $message = <$request>) {
            $file->log(message => $message);
        }
    }
}

