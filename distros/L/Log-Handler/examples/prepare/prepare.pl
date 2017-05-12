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
use Data::Dumper;

my $log = Log::Handler->new();

$log->add(
    screen => {
        newline => 1,
        message_layout  => '%m (%t)',
        message_pattern => [ qw/%T %L %H %m/ ],
        prepare_message => \&format,
    }
);

$log->error("foo bar baz");
$log->error("foo bar baz");
$log->error("foo bar baz");

sub format {
    my $m = shift;

    $m->{message} = sprintf('%-20s %-20s %-20s %s',
        $m->{time}, $m->{level}, $m->{hostname}, $m->{message});
}

