use 5.14.0;
use strict;
use warnings;

package Dist::Iller::Elk;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
# ABSTRACT: A slightly extended Moose
our $VERSION = '0.1411';

use Moose();
use MooseX::AttributeShortcuts();
use MooseX::AttributeDocumented();
use namespace::autoclean();
use Moose::Exporter;

Moose::Exporter->setup_import_methods(also => ['Moose']);

sub init_meta {
    my $class = shift;

    my %params = @_;
    my $for_class = $params{'for_class'};
    Moose->init_meta(@_);
    MooseX::AttributeShortcuts->init_meta(for_class => $for_class);
    MooseX::AttributeDocumented->init_meta(for_class => $for_class);
    namespace::autoclean->import(-cleanee => $for_class);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Iller::Elk - A slightly extended Moose

=head1 VERSION

Version 0.1411, released 2020-01-01.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Iller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Iller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
