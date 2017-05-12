package Fey::Role::TableLike;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.43';

use Moose::Role;

with 'Fey::Role::Joinable';

requires 'sql_for_select_clause';

1;

# ABSTRACT: A role for things that are like a table

__END__

=pod

=head1 NAME

Fey::Role::TableLike - A role for things that are like a table

=head1 VERSION

version 0.43

=head1 SYNOPSIS

  use Moose 2.1200;

  with 'Fey::Role::TableLike';

=head1 DESCRIPTION

This role has no methods or attributes of its own. It does consume the
L<Fey::Role::Joinable> role.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
