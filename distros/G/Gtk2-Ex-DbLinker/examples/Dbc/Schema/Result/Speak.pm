use utf8;
package Dbc::Schema::Result::Speak;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Dbc::Schema::Result::Speak

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<speaks>

=cut

__PACKAGE__->table("speaks");

=head1 ACCESSORS

=head2 countryid

  data_type: 'integer'
  is_nullable: 0

=head2 langid

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "countryid",
  { data_type => "integer", is_nullable => 0 },
  "langid",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</countryid>

=item * L</langid>

=back

=cut

__PACKAGE__->set_primary_key("countryid", "langid");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-06-03 14:50:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7fMkcP46W8yKh0n3IOH1Og


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->belongs_to(speakslang => 'Dbc::Schema::Result::Langue',  {'foreign.langid' => 'self.langid'});

__PACKAGE__->belongs_to(speakscountry => 'Dbc::Schema::Result::Country',  {'foreign.countryid' => 'self.countryid'});

1;
