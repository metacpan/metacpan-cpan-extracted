#!/usr/bin/perl

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>

=head1 DESCRIPTION

This script shows you examples how you can filter messages.

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
    screen => {
        maxlevel => 'info',
        newline  => 1,
        filter_message => {
            match1    => 'log this',
            match2    => qr/with that/,
            match3    => '(?:or this|or that)',
            condition => '(match1 && match2) || match3',
        }
    }
);

$log->info('log this with that');
$log->info('or this');
$log->info('or that');
$log->info('but not that');

