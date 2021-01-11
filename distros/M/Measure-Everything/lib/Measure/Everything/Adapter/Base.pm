package Measure::Everything::Adapter::Base;

# ABSTRACT: Base class for adapters
our $VERSION = '1.003'; # VERSION

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self  = {@_};
    bless $self, $class;
    $self->init(@_);
    return $self;
}

sub init { }

sub write {
    my $class = ref( $_[0] ) || $_[0];
    die "$class does not implement 'write'";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Measure::Everything::Adapter::Base - Base class for adapters

=head1 VERSION

version 1.003

=head1 DESCRIPTION

Base class for all Adapters. You won't need this unless you want to write an Adapter.

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
