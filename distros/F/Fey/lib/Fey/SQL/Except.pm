package Fey::SQL::Except;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.43';

use Moose 2.1200;

with 'Fey::Role::SetOperation' => { keyword => 'EXCEPT' };

with 'Fey::Role::SQL::Cloneable';

1;

# ABSTRACT: Represents an EXCEPT operation

__END__

=pod

=head1 NAME

Fey::SQL::Except - Represents an EXCEPT operation

=head1 VERSION

version 0.43

=head1 SYNOPSIS

  my $except = Fey::SQL->new_except;

  $except->except(
    Fey::SQL->new_select->select(...),
    Fey::SQL->new_select->select(...),
    Fey::SQL->new_select->select(...),
    ...
  );

  $except->order_by( $part_name, 'DESC' );
  $except->limit(10);

  print $except->sql($dbh);

=head1 DESCRIPTION

This class represents an EXCEPT set operator.

=head1 METHODS

See L<Fey::Role::SetOperation> for all methods.

=head1 ROLES

=over 4

=item * L<Fey::Role::SetOperation>

=item * L<Fey::Role::SQL::Cloneable>

=back

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
