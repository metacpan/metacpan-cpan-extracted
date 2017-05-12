package Interchange6;

=head1 NAME

Interchange6 - Open Source Shop Machine

=head1 VERSION

0.120

=cut

our $VERSION = '0.120';

=head1 DESCRIPTION

Interchange6, the Open Source Shop Machine, is the Modern Perl ecosystem
for online business.
It uses the L<DBIx::Class> database schema L<Interchange6::Schema>.

This module provides the following APIs:

=over 4

=item Carts

L<Interchange6::Cart>

=item Cart Products

L<Interchange6::Cart::Product>

=item Cart Costs

L<Interchange6::Cart::Cost>

Cart costs can be applied to both Carts and Cart Products and are integrated
into each via the role L<Interchange6::Role::Costs>.

=back

To build your own business website, please take a look at
our Dancer plugin: L<Dancer::Plugin::Interchange6>.

=head1 CART

Interchange6 supports multiple carts, automatic collapsing of similar items
and price caching.

=head1 CAVEATS

Please anticipate API changes in this early state of development.

=head1 ACKNOWLEDGEMENTS

Hunter McMillen, GH #31, #33, #34.

=head1 AUTHORS

Stefan Hornburg (Racke), C<racke@linuxia.de>

Peter Mottram C<peter@sysnix.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2016 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
