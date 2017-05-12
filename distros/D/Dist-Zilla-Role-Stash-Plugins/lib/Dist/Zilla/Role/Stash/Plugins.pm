# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Zilla-Role-Stash-Plugins
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Zilla::Role::Stash::Plugins;
{
  $Dist::Zilla::Role::Stash::Plugins::VERSION = '1.006';
}
# git description: v1.005-2-g3d6e9bb

BEGIN {
  $Dist::Zilla::Role::Stash::Plugins::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: A Stash that stores arguments for plugins

use Config::MVP::Slicer ();
use Moose::Role;
with qw(
  Dist::Zilla::Role::DynamicConfig
  Dist::Zilla::Role::Stash
);

# we could define a 'plugged' module attribute and create a generic
# method like sub expand_package { $_[0]->plugged_module->expand_package($_[1]) }
# but this is a Role (not an actual stash) and is that really useful?

requires 'expand_package';


has argument_separator => (
  is       => 'ro',
  isa      => 'Str',
  # "Module::Name:variable" "-Plugin/variable"
  default  => '(.+?)\W+(\w+)',
);


# _config inherited


has slicer => (
  is       => 'ro',
  isa      => 'Config::MVP::Slicer',
  lazy     => 1,
  default  => sub {
    my $self = shift;
    Config::MVP::Slicer->new({
      config        => $self->_config,
      separator     => $self->argument_separator,
      match_package => sub { $self->expand_package($_[0]) eq $_[1] },
    })
  },
);


sub get_stashed_config {
  my ($self, $plugin) = @_;

  # TODO: should we compare liberal argument_separator to strict one and warn if not matched?

  return $self->slicer->slice($plugin);
}


sub merge_stashed_config {
  my ($self, $plugin, $opts) = @_;
  $opts ||= {};
  $opts->{stashed} ||= $self->get_stashed_config($plugin);
  $opts->{slice} = delete $opts->{stashed};
  return $self->slicer->merge($plugin, $opts);
}


# this is a class method required by Dist::Zilla::Role::DynamicConfig

sub separate_local_config {
  my ($self, $config) = @_;
  # keys for other plugins should include non-word characters
  # (like "-Plugin::Name:variable"), so any keys that are only
  # word characters (valid identifiers) are for this object.
  my @local = grep { /^\w+$/ } keys %$config;
  my %other;
  @other{@local} = delete @$config{@local}
    if @local;

  return \%other;
}

no Moose::Role;
1;

__END__

=pod

=encoding utf-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS dist-zilla zilla cpan testmatrix url
annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata
placeholders metacpan

=head1 NAME

Dist::Zilla::Role::Stash::Plugins - A Stash that stores arguments for plugins

=head1 VERSION

version 1.006

=head1 SYNOPSIS

  # in Dist::Zilla::Stash::MyStash

  with 'Dist::Zilla::Role::Stash::Plugins';

=head1 DESCRIPTION

This is a role for a L<Stash|Dist::Zilla::Role::Stash>
that stores arguments for other plugins.

Stashes performing this role must define I<expand_package>.

=head1 ATTRIBUTES

=head2 argument_separator

A regular expression that will capture
the package name in C<$1> and
the attribute name in C<$2>.

Defaults to C<< (.+?)\W+(\w+) >>
which means the package variable and the attribute
will be separated by non-word characters
(which assumes the attributes will be
only word characters/valid perl identifiers).

You will need to set this attribute in your stash
if you need to assign to an attribute in a package that contains
non-word characters.
This is an example (taken from the tests in F<t/ini-sep>).

  # dist.ini
  [%Example]
  argument_separator = ([^|]+)\|([^|]+?)
  -PlugName|Attr::Name = oops
  +Mod::Name|!goo-ber = nuts

B<Note> that the regexp should not be anchored as it actually becomes
the middle of a larger regexp (see L<Config::MVP::Slicer/separator>).

=head2 _config

Contains the dynamic options.

Inherited from L<Dist::Zilla::Role::DynamicConfig>.

Rather than accessing this directly,
consider L</get_stashed_config> or L</merge_stashed_config>.

=head2 slicer

Instance of C<Config::MVP::Slicer>
which handles plugin configuration extraction.

=head1 METHODS

=head2 get_stashed_config

Return a hashref of the config arguments for the plugin.
This is a thin wrapper around L<Config::MVP::Slicer/slice>.

  # with a stash of:
  # _config => {
  #   'APlug.attr1'   => 'value1',
  #   'APlug.second'  => '2nd',
  #   'OtherPlug.attr => '0'
  # }

  # from inside Dist::Zilla::Plugin::APlug

  if( my $stash = $self->zilla->stash_named('%Example') ){
    my $stashed = $stash->get_stashed_config($self);
  }

  # $stashed => {
  #   'attr1'   => 'value1',
  #   'second'  => '2nd'
  # }

=head2 merge_stashed_config

  $stash->merge_stashed_config($plugin, \%opts);

Get the stashed config (see L</get_stashed_config>),
then attempt to merge it into the plugin.

This require the plugin's attributes to be writable (C<'rw'>).

This is a thin wrapper around L<Config::MVP::Slicer/merge>.

Possible options:

=over 4

=item *

I<stashed>

A hashref like that returned from L</get_stashed_config>.
If not present, L</get_stashed_config> will be called.

=back

=head2 separate_local_config

Removes any hash keys that are only word characters
(valid perl identifiers (including L</argument_separator>))
because the dynamic keys intended for other plugins will all
contain non-word characters.

Overwrite this if necessary.

=for test_synopsis sub with;

=head1 SEE ALSO

=over 4

=item *

L<Config::MVP::Slicer>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Role::Stash::Plugins

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-Role-Stash-Plugins>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Role-Stash-Plugins>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-Role-Stash-Plugins>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Role-Stash-Plugins>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Role-Stash-Plugins>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Role::Stash::Plugins>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-role-stash-plugins at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Role-Stash-Plugins>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/Dist-Zilla-Role-Stash-Plugins>

  git clone https://github.com/rwstauner/Dist-Zilla-Role-Stash-Plugins.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
