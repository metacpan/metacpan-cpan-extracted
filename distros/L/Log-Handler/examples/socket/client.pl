#!/usr/bin/perl

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>

=head1 DESCRIPTION

This is a client example for Log::Handler::Output::Socket.

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
use Log::Handler;

my $log = Log::Handler->new();

$log->add(
    socket => {
        peeraddr => '127.0.0.1',
        peerport => 44444,
        newline  => 1,
        maxlevel => 'info',
        die_on_errors  => 0,
        message_layout => '%T [%L] %U %H %S[%P] %m',
    }
);

my $err = Log::Handler->new();
$err->add(screen => { newline => 1 });

while ( 1 ) {
    $log->info('test')
        or warn "unable to send message: ", $log->errstr;
    sleep 1;
}

