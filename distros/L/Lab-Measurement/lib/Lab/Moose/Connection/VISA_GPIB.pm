package Lab::Moose::Connection::VISA_GPIB;
$Lab::Moose::Connection::VISA_GPIB::VERSION = '3.901';
#ABSTRACT: compatiblity alias for VISA::GPIB

use v5.20;

use Moose;
use namespace::autoclean;

extends 'Lab::Moose::Connection::VISA::GPIB';

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Connection::VISA_GPIB - compatiblity alias for VISA::GPIB

=head1 VERSION

version 3.901

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
