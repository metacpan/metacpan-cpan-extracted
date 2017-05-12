#!/usr/bin/env perl
use strict;
use warnings;
use IO::Multiplex::Intermediary;

my $intermediary = IO::Multiplex::Intermediary->new(
    external_port => (@ARGV ? $ARGV[0] : 6715),
);

$intermediary->run;

__END__

=head1 NAME

intermediary.pl - runs an intermediary instnace

=head1 DESCRIPTION

This script is associated with the Perl module L<IO::Multiplex::Intermediary>.

=head1 USAGE

  intermediary.pl <port>
