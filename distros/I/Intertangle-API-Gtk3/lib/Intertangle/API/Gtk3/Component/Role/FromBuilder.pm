use Renard::Incunabula::Common::Setup;
package Intertangle::API::Gtk3::Component::Role::FromBuilder;
# ABSTRACT: Role that loads a Glade UI file into a Gtk3::Builder
$Intertangle::API::Gtk3::Component::Role::FromBuilder::VERSION = '0.005';
use Moo::Role;
use Intertangle::API::Gtk3::Helper;
use Renard::Incunabula::Common::Types qw(InstanceOf);

requires 'ui_file';

has builder => (
	is => 'lazy', # _build_builder
	isa => InstanceOf['Gtk3::Builder'],
);

method _build_builder() :ReturnType(InstanceOf['Gtk3::Builder']) {
	return Gtk3::Builder->new;
}

before BUILD => method(@) {
	$self->builder->add_from_file( $self->ui_file );
	$self->builder->connect_signals;
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::API::Gtk3::Component::Role::FromBuilder - Role that loads a Glade UI file into a Gtk3::Builder

=head1 VERSION

version 0.005

=head1 DESCRIPTION

This role is used to load a Glade file into the C<builder> attribute.

This role can be combined with L<Intertangle::API::Gtk3::Component::Role::UIFileFromPackageName>
so that the contents of the C<ui_file> attribute are automatically populated
based on the package that the role is being included in.

=head1 ATTRIBUTES

=head2 ui_file

A C<Str> that contains the path to a Glade file to be loaded.

Consumers of this role must implement this.

=head2 builder

A C<Gtk3::Builder> that contains the contents of the Glade file referenced in
C<ui_file>.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
