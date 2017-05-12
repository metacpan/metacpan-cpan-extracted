use utf8;
package Dbc::Schema::Result::Country;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Dbc::Schema::Result::Country

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<countries>

=cut

__PACKAGE__->table("countries");

=head1 ACCESSORS

=head2 countryid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 country

  data_type: 'text'
  is_nullable: 1

=head2 mainlangid

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "countryid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "country",
  { data_type => "text", is_nullable => 1 },
  "mainlangid",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</countryid>

=back

=cut

__PACKAGE__->set_primary_key("countryid");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-06-03 14:50:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DofKL1V25SEjAftLI+rF2w

 __PACKAGE__->has_many(countryspeaks => 'Dbc::Schema::Result::Speak',  {'foreign.countryid' => 'self.countryid'});

  __PACKAGE__->belongs_to(countrylang => 'Dbc::Schema::Result::Langue',  {'foreign.langid' => 'self.mainlangid'});

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
