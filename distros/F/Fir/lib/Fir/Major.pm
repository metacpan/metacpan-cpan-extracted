package Fir::Major;
use Moose;
extends 'Fir::Minor';
has 'is_open' => ( is => 'rw', isa => 'Bool', default => 0 );

1;

__END__

=head1 NAME

Fir::Major - a navigation node with subnodes

=head1 SYNOPSIS

  my $about = Fir::Major->new();
  $about->name('About');
  $about->path('/about/');

=head1 DESCRIPTION

A L<Fir::Major> node is a navigation node which can have subnodes.

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2008, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
