#!/usr/bin/perl

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>

=head1 DESCRIPTION

This script shows you examples how you can filter
messages from different callers.

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
        message_layout => '%L - (filter:foo) %m',
        filter_caller  => 'foo',
    }
);

$log->add(
    screen => {
        maxlevel => 'info',
        newline  => 1,
        message_layout => '%L - (filter:bar) %m',
        filter_caller  => 'bar',
    }
);

$log->add(
    screen => {
        maxlevel => 'info',
        newline  => 1,
        message_layout => '%L - (except:baz) %m',
        except_caller  => 'baz',
    }
);

package foo;
$log->info('foo');

package bar;
$log->info('bar');

package baz;
$log->info('baz');

1;
