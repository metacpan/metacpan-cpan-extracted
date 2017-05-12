use utf8;

package Interchange6::Schema;

=encoding utf8

=head1 NAME

Interchange6::Schema - Database Schema for Interchange 6

=head1 VERSION

0.133

=cut

our $VERSION = '0.133';

=head1 MANUAL

Please see the L<Interchange6 Schema Manual|Interchange6::Schema::Manual>
for an overview of available documentation.

=head1 DESCRIPTION

Database schema classes for Interchange6 Open Source eCommerce software.

The minimum Perl version for Interchange6::Schema is 5.8.

=head1 BASE CLASS

L<DBIx::Class::Schema::Config>

If you inherit from L<Interchange6::Schema> then in order to make use of
L<DBIx::Class::Schema::Config> in your own schema you must load it as a
component.

=head1 COMPONENTS

Components used:

=over

=item * L<DBIx::Class::Helper::Schema::DateTime>

=item * L<DBIx::Class::Helper::Schema::QuoteNames>

=back

=cut

use strict;
use warnings;

use base 'DBIx::Class::Schema::Config';

__PACKAGE__->load_components( 'Helper::Schema::DateTime',
    'Helper::Schema::QuoteNames' );

__PACKAGE__->load_namespaces(
    default_resultset_class => 'ResultSet',
);

=head1 ATTRIBUTES

=head2 current_user

This attribute can be used to stash the L<Interchange6::Schema::Result::User>
object of the currently logged in user. If set then any result class and
resultset methods which take C<users_id> as an argument will make use of
the value of this attribute to set C<users_id>.

=over

=item writer: set_current_user

=back

=cut

=head2 user_locale

This attribute can be used to store the locale of the current user.

=over

=item writer: set_user_locale

=back

=cut

__PACKAGE__->mk_group_ro_accessors(
    inherited => (
        [ 'current_user' => '_ic6_current_user' ],
        [ 'user_locale'  => '_ic6_user_locale' ],
    )
);

__PACKAGE__->mk_group_wo_accessors(
    inherited => (
        [ 'set_current_user' => '_ic6_current_user' ],
        [ 'set_user_locale'  => '_ic6_user_locale' ],
    )
);

=head1 METHODS

=head2 deploy

Overload L<DBIx::Class::Schema/deploy> in order to add some core fixtures
via L<Interchange6::Schema::Populate>.

=cut

{
    use Interchange6::Schema::Populate;

    sub deploy {
        my $self = shift;
        my $new  = $self->next::method(@_);

        Interchange6::Schema::Populate->new( schema => $self )->populate;

#        $self->resultset('Website')->create(
#            {
#                fqdn        => "*",
#                name        => "Default",
#                description => "Default Website"
#            }
#        );
    }
}

1;

__END__

=head1 CREATE SQL FILES FOR DATABASE SCHEMA

This command creates SQL files for our database schema
in the F<sql/> directory:

   interchange6-create-database

=head1 POLICY FOR RELATIONSHIP ACCESSORS

=over 4

=item All lower case

=item Singular names for belongs_to and has_one relationships

=item Pluralised names for many_to_many and has_many relationships

=item Use underscores for things like C<shipment_destinations>.

=back

=head1 AUTHORS

Stefan Hornburg (Racke), C<racke@linuxia.de>

Peter Mottram, C<peter@sysnix.com>

Jeff Boes, C<jeff@endpoint.com>

Sam Batschelet C<sbatschelet@mac.com>

=head1 CONTRIBUTORS

Kaare Rasmussen
Šimun Kodžoman
Grega Pompe

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2014 Stefan Hornburg (Racke), Jeff Boes.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
