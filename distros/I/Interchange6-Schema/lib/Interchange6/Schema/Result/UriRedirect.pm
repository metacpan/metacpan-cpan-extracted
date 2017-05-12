use utf8;

package Interchange6::Schema::Result::UriRedirect;

=head1 NAME

Interchange6::Schema::Result::UriRedirect

=cut

use Interchange6::Schema::Candy -components =>
  [qw(InflateColumn::DateTime TimeStamp)];

=head1 DESCRIPTION

The uri_redirects table stores uri_source and uri_target mappings.

=cut

=head1 ACCESSORS

=head2 uri_source

Primary key.

=cut

primary_column uri_source => {
    data_type         => "varchar",
    size              => 255
};

=head2 uri_target

The target uri for redirect.

=cut

column uri_target => {
    data_type         => "varchar",
    size              => 255
};

=head2 status_code

Http status code passed during redirect.
Default 301 "Moved Permanently".

=cut

column status_code => {
    data_type         => "integer",
    default_value     => 301
};

=head2 created

Date and time when this record was created returned as L<DateTime> object.
Value is auto-set on insert.

=cut

column created => {
    data_type         => "datetime",
    set_on_create     => 1
};

=head2 last_used

Date and time when this record was last used returned as L<DateTime> object.
Value is auto-set on insert and update.

=cut

column last_used => {
    data_type     => "datetime",
    set_on_create => 1,
};

1;
