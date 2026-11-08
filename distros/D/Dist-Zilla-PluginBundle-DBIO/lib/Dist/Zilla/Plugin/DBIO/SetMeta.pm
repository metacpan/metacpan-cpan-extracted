package Dist::Zilla::Plugin::DBIO::SetMeta;
# ABSTRACT: Set author, copyright_holder, and license on the Dist::Zilla object
our $VERSION = '0.900004';
use Moose;
with 'Dist::Zilla::Role::Plugin', 'Dist::Zilla::Role::BeforeBuild';


has author => (is => 'ro', isa => 'Str', required => 1);
has holder => (is => 'ro', isa => 'Str', required => 1);

sub before_build {
  my ($self) = @_;
  my $zilla = $self->zilla;

  my %attr = map { $_->name => $_ } $zilla->meta->get_all_attributes;

  $attr{authors}->set_value($zilla, [$self->author]);
  $attr{_copyright_holder}->set_value($zilla, $self->holder);
  $attr{_license_class}->set_value($zilla, 'Perl_5');
}

__PACKAGE__->meta->make_immutable;
no Moose;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DBIO::SetMeta - Set author, copyright_holder, and license on the Dist::Zilla object

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Internal plugin of the C<[@DBIO]> bundle; it is added by
L<Dist::Zilla::PluginBundle::DBIO> and is not meant to be configured in a
C<dist.ini>. A bundle has no access to the L<Dist::Zilla> object while it
builds its plugin list, so the bundle derives the values (C<heritage = 1>
gives C<DBIO & DBIx::Class Authors>, otherwise C<DBIO Authors>; the copyright
holder defaults to the same string and can be overridden with
C<copyright_holder>) and hands them to this plugin, which applies them to the
distribution before the build starts.

Dist::Zilla offers no public way to set these values from a plugin:
C<authors>, C<_copyright_holder> and C<_license_class> are read-only
attributes filled from the C<dist.ini> top level (or the C<%User> / C<%Rights>
stashes). The plugin therefore writes them through the Moose meta attributes
in C<before_build>. That reaches into private Dist::Zilla fields
(C<_copyright_holder>, C<_license_class>), which is why it lives in its own
module: it is the one place that depends on Dist::Zilla internals. The license
is always set to C<Perl_5>.

=head1 ATTRIBUTES

=head2 author

The author, set as the only entry of Dist::Zilla's C<authors>. Required.

=head2 holder

The copyright holder, written to Dist::Zilla's private C<_copyright_holder>.
Required.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
