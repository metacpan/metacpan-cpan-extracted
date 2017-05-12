package Fey::SQL::Union;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.43';

use Moose 2.1200;

with 'Fey::Role::SetOperation' => { keyword => 'UNION' };

with 'Fey::Role::SQL::Cloneable';

1;

# ABSTRACT: Represents a UNION operation

__END__

=pod

=head1 NAME

Fey::SQL::Union - Represents a UNION operation

=head1 VERSION

version 0.43

=head1 SYNOPSIS

  my $union = Fey::SQL->new_union;

  $union->union( Fey::SQL->new_select->select(...),
                 Fey::SQL->new_select->select(...),
                 Fey::SQL->new_select->select(...),
                 ...
               );

  $union->order_by( $part_name, 'DESC' );
  $union->limit(10);

  print $union->sql($dbh);

=head1 DESCRIPTION

This class represents a UNION set operator.

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
