package Fir::Minor;
use Moose;
extends 'Tree::DAG_Node';
has 'path' => ( is => 'rw', isa => 'Str' );
has 'is_selected' => ( is => 'rw', isa => 'Bool', default => 0 );

1;

__END__

=head1 NAME

Fir::Minor - a navigation node without subnodes

=head1 SYNOPSIS

  my $leon = Fir::Minor->new();
  $leon->name('Leon');
  $leon->path('/about/leon/');

=head1 DESCRIPTION

A L<Fir::Major> node is a navigation node which can not have subnodes.

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2008, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
