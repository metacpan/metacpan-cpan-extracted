package Measure::Everything::Adapter::Null;
use strict;
use warnings;

use base qw(Measure::Everything::Adapter::Base);

# ABSTRACT: Null Adapter: ignore all stats

sub write { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Measure::Everything::Adapter::Null - Null Adapter: ignore all stats

=head1 VERSION

version 1.001

=head1 SYNOPSIS

    Measure::Everything::Adapter->set( 'Null' );

=head1 DESCRIPTION

Ignore all stats. This Adapter is used if you do not specify an Adapter.

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
