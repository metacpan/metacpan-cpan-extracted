package Measure::Everything::Adapter::Null;

# ABSTRACT: Null Adapter: ignore all stats
our $VERSION = '1.003'; # VERSION

use strict;
use warnings;

use base qw(Measure::Everything::Adapter::Base);

sub write { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Measure::Everything::Adapter::Null - Null Adapter: ignore all stats

=head1 VERSION

version 1.003

=head1 SYNOPSIS

    Measure::Everything::Adapter->set( 'Null' );

=head1 DESCRIPTION

Ignore all stats. This Adapter is used if you do not specify an Adapter.

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
