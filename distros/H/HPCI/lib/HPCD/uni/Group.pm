package HPCD::uni::Group;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;

use Moose;
use namespace::autoclean;

use HPCD::uni::Stage;

with 'HPCI::Group'    => { theDriver => 'HPCD::uni' },
	 'HPCI::JobGroup' => { theDriver => 'HPCD::uni' },
	 HPCI::get_extra_roles('uni', 'group');

=head1 NAME

    HPCD::uni::Group

=head1 SYNOPSIS

    my $group = HPCI->group( cluster => 'uni', ... );

=head1 DESCRIPTION

This module, distributed internal to the HPCI module, provides
the translation required to implement a generic HPCI group using a
uni(processor) "cluster".  (That means simply forking off processes
on the same host system as the original process.)

This is mostly useful for testing - as a "cluster" type that is
always available on any (POSIX-compatible) host.  It is also useful
as a fallback when your only cluster is broken or inaccessible.

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

