use utf8;

package Interchange6::Schema::Result::Setting;

=head1 NAME

Interchange6::Schema::Result::Setting

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 settings_id

Primary key.

=cut

primary_column settings_id => {
    data_type         => "integer",
    is_auto_increment => 1,
    sequence          => "settings_settings_id_seq",
};

=head2 scope

Scope of this setting.

=cut

column scope => { data_type => "varchar", size => 32 };

=head2 site

Site (shop) that this setting applies to.

Defaults to empty string.

=cut

column site =>
  { data_type => "varchar", default_value => "", size => 32 };

=head2 name

Name of this setting.

=cut

column name => { data_type => "varchar", size => 32 };

=head2 value

Value of this setting.

=cut

column value => { data_type => "text" };

=head2 category

Category of this setting.

Defaults to empty string.

=cut

column category =>
  { data_type => "varchar", default_value => "", size => 32 };

1;
