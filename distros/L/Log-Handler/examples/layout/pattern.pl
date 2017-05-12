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

$log->add(forward => {
    forward_to      => \&my_func,
    message_pattern => [ qw/%T %L %H/ ],
    message_layout  => '',
    maxlevel        => 'info',
});

$log->info('a forwarded message');

# now you can access it

sub my_func {
    my $msg = shift;
    print "Timestamp: $msg->{time}\n";
    print "Level:     $msg->{level}\n";
    print "Hostname:  $msg->{hostname}\n";
    print "Message:   $msg->{message}\n";
}
