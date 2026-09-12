# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to interact with the modifiers of words of any language


package Lingua::Generic::Interface::Modifier;

use v5.20;
use strict;
use warnings;

use Carp;
use Data::Identifier v0.34;

our $VERSION = v0.03;

use parent 'Lingua::Generic::Interface::Base';


# ---- Private helpers ----

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Generic::Interface::Modifier - module to interact with the modifiers of words of any language

=head1 VERSION

version v0.03

=head1 SYNOPSIS

    use parent 'Lingua::Generic::Interface::Modifier';

    my Lingua::Generic::Interface::Modifier $modifier = Lingua::XXX::Modifier->new(string => 'il');

    say $modifier->as_string;

This module implements a generic interface to language specific implementations of a modifier object.
A modifier is any entity that is applied to a word to modify it.
This can be a prefix, suffix, or even invisible part.
A modifier might indicate e.g. numerus, or tempus.

An language specific implementation B<should> keep modifiers with the same spelling but different meanings apart.

This module provides a base implementation for some of it's required methods.
Methods which this module cannot provide a useful default implementation for will have an implementation that dies on call.

This module inherits from
L<Lingua::Generic::Interface::Base>.

Packages may also want to implement L<Data::Identifier::Interface::Known>.

=head1 METHODS

=head1 RESERVED METHODS

See L<Lingua::Generic::Interface::Base> for a list of reserved methods.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
