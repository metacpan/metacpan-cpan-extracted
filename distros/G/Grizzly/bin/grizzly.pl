#!/usr/bin/perl

# PODNAME: grizzly

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Grizzly;

my %arg = ( show_version_cmd => 1, );
my $cmd = Grizzly->new( \%arg );
$cmd->run;

__END__

=pod

=encoding UTF-8

=head1 NAME

grizzly

=head1 VERSION

version 0.102

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Nobunaga.

This is free software, licensed under:

  The MIT (X11) License

=cut
