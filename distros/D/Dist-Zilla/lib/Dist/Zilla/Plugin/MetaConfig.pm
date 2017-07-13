package Dist::Zilla::Plugin::MetaConfig 6.010;
# ABSTRACT: summarize Dist::Zilla configuration into distmeta

use Moose;
with 'Dist::Zilla::Role::MetaProvider';

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This plugin adds a top-level C<x_Dist_Zilla> key to the
#pod L<distmeta|Dist::Zilla/distmeta> for the distribution.  It describe the
#pod Dist::Zilla version used as well as all the plugins used.  Each plugin's name,
#pod package, and version will be included.  Plugins may augment their
#pod implementation of the L<Dist::Zilla::Role::ConfigDumper> role methods to add
#pod more data to this dump.
#pod
#pod More information may be added to the top-level of this metadata as time goes
#pod on.
#pod
#pod =cut

sub metadata {
  my ($self) = @_;

  my $dump = { };

  my @plugins;
  $dump->{plugins} = \@plugins;

  my $config = $self->zilla->dump_config;
  $dump->{zilla} = {
    class   => $self->zilla->meta->name,
    version => $self->zilla->VERSION,
      (keys %$config ? (config => $config) : ()),
  };

  $dump->{perl} = {
    version => "$]",
  };

  for my $plugin (@{ $self->zilla->plugins }) {
    my $config = $plugin->dump_config;

    push @plugins, {
      class   => $plugin->meta->name,
      name    => $plugin->plugin_name,
      version => $plugin->VERSION,
      (keys %$config ? (config => $config) : ()),
    };
  }

  return { x_Dist_Zilla => $dump };
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 SEE ALSO
#pod
#pod Dist::Zilla roles: L<MetaProvider|Dist::Zilla::Role::MetaProvider>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MetaConfig - summarize Dist::Zilla configuration into distmeta

=head1 VERSION

version 6.010

=head1 DESCRIPTION

This plugin adds a top-level C<x_Dist_Zilla> key to the
L<distmeta|Dist::Zilla/distmeta> for the distribution.  It describe the
Dist::Zilla version used as well as all the plugins used.  Each plugin's name,
package, and version will be included.  Plugins may augment their
implementation of the L<Dist::Zilla::Role::ConfigDumper> role methods to add
more data to this dump.

More information may be added to the top-level of this metadata as time goes
on.

=head1 SEE ALSO

Dist::Zilla roles: L<MetaProvider|Dist::Zilla::Role::MetaProvider>.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
