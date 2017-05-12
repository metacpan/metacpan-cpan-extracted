package Mail::Decency::Core::Meta::Maintenance;

use Moose::Role;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Mail::Decency::Helper::IntervalParse qw/ interval_to_int /;

=head1 NAME

Mail::Decency::Core::Meta::Maintenance

=head1 DESCRIPTION

Role for modules with maintenance capabilities

=head1 CLASS ATTRIBUTES

=head2 maintenance_ttl : Int

Time to live database entry before being wiped via maintenance (depending on the module).

=cut

has maintenance_ttl => ( is => 'rw', isa => 'Int', default => interval_to_int( '1d' ) );

=head1 MODIFICATIONS

=head2 after init

Read maintenance_ttl from config

=cut

after init => sub {
    my ( $self ) = @_;
    $self->maintenance_ttl( interval_to_int( $self->config->{ maintenance_ttl } ) )
        if defined $self->config->{ maintenance_ttl };
};

=head1 REQUIRE METHODS

=head2 maintenance

=cut

requires 'maintenance';

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
