use strict;
use warnings;

package Footprintless::Plugin::Ldap;
$Footprintless::Plugin::Ldap::VERSION = '1.00';
# ABSTRACT: A Footprintless plugin for working with LDAP
# PODNAME: Footprintless::Plugin::Ldap

use Footprintless::Util qw(dynamic_module_new);

use parent qw(Footprintless::Plugin);

sub ldap {
    my ( $self, $footprintless, $coordinate, @rest ) = @_;
    return dynamic_module_new( 'Footprintless::Plugin::Ldap::Ldap',
        $footprintless, $coordinate, @rest );
}

sub ldap_command_helper {
    my ( $self, $footprintless, $coordinate, @rest ) = @_;
    return ( $self->{config} && $self->{config}{command_helper} )
        ? dynamic_module_new( $self->{config}{command_helper} )
        : dynamic_module_new('Footprintless::Plugin::Ldap::DefaultCommandHelper');
}

sub factory_methods {
    my ($self) = @_;
    return {
        ldap => sub {
            return $self->ldap(@_);
        },
        ldap_command_helper => sub {
            return $self->ldap_command_helper(@_);
        },
    };
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Ldap - A Footprintless plugin for working with LDAP

=head1 VERSION

version 1.00

=head1 DESCRIPTION

Provides the C<ldap> factory method to the framework as well as the C<ldap> 
command to the CLI.

=head1 ENTITIES

As with all plugins, this must be registered on the C<footprintless> entity.  

    plugins => [
        'Footprintless::Plugin::Ldap',
    ],

You may supply your own C<command_helper> as outlined by 
L<Footprintless::Plugin::Ldap::DefaultCommandHelper>:

    'Footprintless::Plugin::Database' => {
        command_helper => 'My::Automation::CommandHelper',
    }

=head1 METHODS

=head2 ldap($footprintless, $coordinate, %options)

Returns a new ldap provider instance.  See L<Footprintless::Plugin::Ldap::Ldap>.

=head2 ldap_command_helper($footprintless, $coordinate, %options)

Returns a new ldap command helper.  See L<Footprintless::Plugin::Ldap::DefaultCommandHelper>.

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

L<Footprintless|Footprintless>

=item *

L<Footprintless::MixableBase|Footprintless::MixableBase>

=item *

L<Footprintless::Plugin::Ldap|Footprintless::Plugin::Ldap>

=item *

L<Footprintless::Plugin::Ldap::Ldap|Footprintless::Plugin::Ldap::Ldap>

=back

=for Pod::Coverage factory_methods

=cut
