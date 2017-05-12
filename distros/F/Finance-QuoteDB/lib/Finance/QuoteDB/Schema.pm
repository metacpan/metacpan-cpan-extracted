package Finance::QuoteDB::Schema;
use base qw/DBIx::Class::Schema/;

use strict;
use warnings;

__PACKAGE__->load_classes(qw/ Symbol Quote FQMarket /);

our $VERSION = '0.18'; # VERSION

=head1 METHODS

=head2 connect_and_deploy

connect_and_deploy($dsn)

Connects to $dsn and (re)generates the database structure

=cut

sub connect_and_deploy {
  my ($class,$dsn,$user,$password) = @_;
  my $self=$class->connect($dsn,$user,$password);
  $self->deploy({ add_drop_tables => 1});
  return $self;
} ;

=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 Erik Colson, all rights reserved.

This file is part of Finance::QuoteDB.

Finance::QuoteDB is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

Finance::QuoteDB is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with Finance::QuoteDB.  If not, see
<http://www.gnu.org/licenses/>.

=cut

1;
