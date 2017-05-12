package Jifty::Plugin::Authentication::ModShibb::Mixin::Model::User;
use strict;
use warnings;
use Jifty::DBI::Schema;
use base 'Jifty::DBI::Record::Plugin';

=head1 NAME

Jifty::Plugin::Authentication::ModShibb::Mixin::Model::User - ModShibb mixin for User model

=head1 DESCRIPTION

L<Jifty::Plugin::Authentication::ModShibb> mixin for the User model.  Provides a 'shibb_id' column.

=cut

our @EXPORT = qw(has_alternative_auth);

use Jifty::Plugin::Authentication::ModShibb::Record schema {

column shibb_id =>
  type is 'text',
  label is 'Shibboleth ID',
  is distinct,
  is immutable;

};

=head2 has_alternative_auth

=cut

sub has_alternative_auth { 1 }

1;

