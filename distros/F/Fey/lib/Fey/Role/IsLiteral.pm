package Fey::Role::IsLiteral;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.43';

use Moose::Role;

requires 'sql';

sub id {
    return $_[0]->sql('Fey::FakeDBI');
}

1;

# ABSTRACT: A role for things that are literals

__END__

=pod

=head1 NAME

Fey::Role::IsLiteral - A role for things that are literals

=head1 VERSION

version 0.43

=head1 SYNOPSIS

  use Moose 2.1200;

  with 'Fey::Role::IsLiteral';

=head1 DESCRIPTION

This role provides an C<id()> method that simply calls C<<
$object->sql('Fey::FakeDBI') >>.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
