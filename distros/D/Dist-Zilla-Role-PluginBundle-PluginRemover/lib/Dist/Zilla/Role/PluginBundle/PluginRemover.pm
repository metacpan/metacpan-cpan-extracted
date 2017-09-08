# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Zilla-Role-PluginBundle-PluginRemover
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Zilla::Role::PluginBundle::PluginRemover;
# git description: v0.104-1-g5f9ab18

our $AUTHORITY = 'cpan:RWSTAUNER';
# ABSTRACT: Add '-remove' functionality to a bundle
$Dist::Zilla::Role::PluginBundle::PluginRemover::VERSION = '0.105';
use Moose::Role;
use Dist::Zilla::Util ();

requires 'bundle_config';


sub plugin_remover_attribute { '-remove' };

# Stub an empty sub so we can use 'around'.
# A consuming class can overwrite the empty sub
# and the 'around' will modify that sub at composition time.
sub mvp_multivalue_args { }

around mvp_multivalue_args => sub {
  my $orig = shift;
  my $self = shift;
  $self->plugin_remover_attribute, $self->$orig(@_)
};


sub remove_plugins {
  my ($self, $remove, @plugins) = @_;

  # plugin specifications look like:
  # [ plugin_name, plugin_class, arguments ]

  # stolen 99% from @Filter (thanks rjbs!)
  require List::Util;
  for my $i (reverse 0 .. $#plugins) {
    splice @plugins, $i, 1 if List::Util::any(sub {
      $plugins[$i][0] eq $_
        or
      $plugins[$i][1] eq Dist::Zilla::Util->expand_config_package_name($_)
    }, @$remove);
  }

  return @plugins;
}

around bundle_config => sub {
  my ($orig, $class, $section) = @_;

  # is it better to delete this or allow the bundle to see it?
  my $remove = $section->{payload}->{ $class->plugin_remover_attribute };

  my @plugins = $orig->($class, $section);

  return @plugins unless $remove;

  return $class->remove_plugins($remove, @plugins);
};

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS cpan testmatrix url annocpan anno bugtracker
rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

Dist::Zilla::Role::PluginBundle::PluginRemover - Add '-remove' functionality to a bundle

=head1 VERSION

version 0.105

=head1 SYNOPSIS

  # in Dist::Zilla::PluginBundle::MyBundle

  with (
    'Dist::Zilla::Role::PluginBundle', # or PluginBundle::Easy
    'Dist::Zilla::Role::PluginBundle::PluginRemover'
  );

  # PluginRemover should probably be last
  # (unless you're doing something more complex)

=head1 DESCRIPTION

This role enables your L<Dist::Zilla> Plugin Bundle
to automatically remove any plugins specified
by the C<-remove> attribute
(like L<@Filter|Dist::Zilla::PluginBundle::Filter> does):

  [@MyBundle]
  -remove = PluginIDontWant
  -remove = OtherDumbPlugin

If you want to use an attribute named C<-remove> for your own bundle
you can override the C<plugin_remover_attribute> sub
to define a different attribute name:

  # in your bundle package
  sub plugin_remover_attribute { 'scurvy_cur' }

This role adds a method modifier to C<bundle_config>,
which is the method that the root C<PluginBundle> role requires,
and that C<PluginBundle::Easy> wraps.

=head1 METHODS

=head2 plugin_remover_attribute

Returns the name of the attribute
containing the array ref of plugins to remove.

Defaults to C<-remove>.

=head2 remove_plugins

  $class->remove_plugins(\@to_remove, @plugins);
  $class->remove_plugins(['Foo'], [Foo => 'DZP::Foo'], [Bar => 'DZP::Bar']);

Takes an arrayref of plugin names to remove
(like what will be in the config payload for C<-remove>),
removes them from the list of plugins passed,
and returns the remaining plugins.

This is used by the C<bundle_config> modifier
but is defined separately in case you would like
to use the functionality without the voodoo that occurs
when consuming this role.

The plugin name to match against all plugins can be given as either the plugin
moniker (like you might provide in your config file, expanded via
L<Dist::Zilla::Util/expand_config>), or the unique plugin name used to
differentiate multiple plugins of the same type. For example, in this
configuration:

    [Foo::Bar / plugin 1]
    [Foo::Bar / plugin 2]

passing C<'Foo::Bar'> to C<remove_plugins> will remove both these plugins from
the configuration, but only the first is removed when passing C<'plugin 1'>.

=for Pod::Coverage mvp_multivalue_args

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Role::PluginBundle::PluginRemover

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Dist-Zilla-Role-PluginBundle-PluginRemover>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-role-pluginbundle-pluginremover at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Dist-Zilla-Role-PluginBundle-PluginRemover>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/Dist-Zilla-Role-PluginBundle-PluginRemover>

  git clone https://github.com/rwstauner/Dist-Zilla-Role-PluginBundle-PluginRemover.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Karen Etheridge

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
