# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to interact with the famibeib language


package Lingua::famibeib;

use v5.16;
use strict;
use warnings;

use Carp;

our $VERSION = v0.02;

use parent 'Data::Identifier::Interface::Known';

my @_wellknown = (
    Data::Identifier->new(uuid => '1d668738-8aef-4cb4-a4ed-9368e872a93f', displayname => 'famibeib')->register,
);

# ---- Private helpers ----

sub _known_provider {
    my ($pkg, $class, %opts) = @_;
    croak 'Unsupported options passed' if scalar(keys %opts);
    return (\@_wellknown, rawtype => 'uuid') if $class eq ':all';
    croak 'Unsupported class';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::famibeib - module to interact with the famibeib language

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use Lingua::famibeib;

This is the top level module for famibeib support.
famibeib is a artificial language.

Most users are likely interested in
L<Lingua::famibeib::Text> (for text handling and parsing),
L<Lingua::famibeib::Sentence> (for sentence related actions),
and L<Lingua::famibeib::Word> (for everything about words).

This module inherits from L<Data::Identifier::Interface::Known>.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
