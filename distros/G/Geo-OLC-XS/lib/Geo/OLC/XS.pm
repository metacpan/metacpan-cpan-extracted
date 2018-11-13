package Geo::OLC::XS;
use strict;
use warnings;
use parent 'Exporter';

use XSLoader;

our $VERSION = '0.000001';
XSLoader::load( __PACKAGE__, $VERSION );

our @EXPORT_OK = qw[];

1;
__END__

=pod

=encoding utf8

=head1 NAME

Geo::OLC::XS - Perl XS binding for Open Location Code, a library to generate
short codes that can be used like street addresses, for places where street
addresses don't exist.

=head1 VERSION

Version 0.000001

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS/ATTRIBUTES

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Gonzalo Diethelm.

This library is free software; you can redistribute it and/or modify it under
the terms of the MIT license.

=head1 AUTHOR

=over 4

=item * Gonzalo Diethelm C<< gonzus AT cpan DOT org >>

=back

=head1 THANKS

=cut
