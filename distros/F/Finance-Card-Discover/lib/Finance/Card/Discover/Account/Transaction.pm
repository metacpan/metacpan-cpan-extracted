package Finance::Card::Discover::Account::Transaction;

use strict;
use warnings;

use DateTime::Tiny;
use Object::Tiny qw( type date amount id name );


1;

__END__

=head1 NAME

Finance::Card::Discover::Account::Transaction

=head1 DESCRIPTION

This module provides a class representing a single transaction.

=head1 ACCESSORS

=over

=item * amount

=item * date

Date of the transaction, as a L<DateTime::Tiny> object.

=item * id

=item * name

=item * type

One of 'debit' or 'credit'.

=back

=cut
