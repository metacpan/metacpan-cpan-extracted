use strict;
use warnings;

package Footprintless::Plugin::Ldap::Command::ldap::copy_to;
$Footprintless::Plugin::Ldap::Command::ldap::copy_to::VERSION = '1.00';
# ABSTRACT: copy an ldap directory
# PODNAME: Footprintless::Plugin::Ldap::Command::ldap::copy_to;

use parent qw(Footprintless::App::Action);

use Carp;
use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ( $self, $opts, $args ) = @_;

    $logger->info('Performing copy...');
    $self->{command_helper}->copy( $self->{ldap}, $self->{destination}, %{ $self->{options} } );
    $logger->info('Done!');
}

sub opt_spec {
    return (
        [ 'base=s',         'base dn' ],
        [ 'filter=s',       'filter' ],
        [ 'live',           'do not use existing backup' ],
        [ 'scope=s',        'search scope' ],
        [ 'set-password=s', 'replaces all passwords' ]
    );
}

sub usage_desc {
    return 'fpl ldap LDAP_COORD copy-to LDAP_COORD %o';
}

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    eval { $self->{ldap} = $self->{footprintless}->ldap( $self->{coordinate} ); };
    $self->usage_error("invalid coordinate [$self->{coordinate}]: $@") if ($@);

    my ($destination_coordinate) = @$args;
    $self->usage_error('destination coordinate required for copy')
        unless ($destination_coordinate);
    $self->{command_helper} = $self->{footprintless}->ldap_command_helper();
    croak("destination [$self->{coordinate}] not allowed")
        unless $opts->{ignore_deny}
        || $self->{command_helper}->allowed_destination( $self->{coordinate} );

    eval { $self->{destination} = $self->{footprintless}->ldap($destination_coordinate); };
    $self->usage_error("invalid destination coordinate [$destination_coordinate]: $@")
        if ($@);

    $self->{options} = {
        attrs => [ '*', '+' ],
        filter => $opts->{filter} || '(objectClass=*)',
        scope  => $opts->{scope}  || 'sub',
        ( $opts->{base}         ? ( base         => $opts->{base} )         : () ),
        ( $opts->{live}         ? ( live         => $opts->{live} )         : () ),
        ( $opts->{set_password} ? ( set_password => $opts->{set_password} ) : () ),
    };
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Ldap::Command::ldap::copy_to; - copy an ldap directory

=head1 VERSION

version 1.00

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless::Plugin::Ldap|Footprintless::Plugin::Ldap>

=back

=for Pod::Coverage execute opt_spec usage_desc validate_args

=cut
