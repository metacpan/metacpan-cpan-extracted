#!/usr/bin/perl

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>

=head1 DESCRIPTION

This script shows you examples for all patterns.

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

$log->set_pattern('%x', 'x-name', 'x-value');

$log->add(
    screen => {
        message_layout => 
            'level       %L%N'.
            'time        %T%N'.
            'date        %D%N'.
            'pid         %P%N'.
            'hostname    %H%N'.
            'caller      %C%N'.
            'package     %p%N'.
            'filename    %f%N'.
            'line        %l%N'.
            'subroutine  %s%N'.
            'progname    %S%N'.
            'runtime     %r%N'.
            'mtime       %t%N'.
            'message     %m%N'.
            'procent     %%%N'.
            'x-name      %x%N',
    }
);

$log->error('your message');
