#!/usr/bin/env perl
use strict;
use warnings;
use lib::projectroot qw(lib local::lib=local);

# ABSTRACT: Compact all files that are currently not watched

package Runner;
use Moose;
extends 'InfluxDB::Writer::CompactFiles';
with 'MooseX::Getopt';

use Log::Any::Adapter ('Stderr');

my $runner = Runner->new_with_options->run;

__END__

=pod

=encoding UTF-8

=head1 NAME

Runner - Compact all files that are currently not watched

=head1 VERSION

version 1.002

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
