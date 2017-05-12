use 5.006;
use strict;
use warnings;
package HTML::Widget::Factory;
# ABSTRACT: churn out HTML widgets
$HTML::Widget::Factory::VERSION = '0.204';
use Carp ();
use Module::Load ();
use MRO::Compat;

#pod =head1 SYNOPSIS
#pod
#pod  my $factory = HTML::Widget::Factory->new();
#pod
#pod  my $html = $factory->select({
#pod    name    => 'flavor',
#pod    options => [
#pod      [ minty => 'Peppermint',     ],
#pod      [ perky => 'Fresh and Warm', ],
#pod      [ super => 'Red and Blue',   ],
#pod    ],
#pod    value   => 'minty',
#pod  });
#pod
#pod =head1 DESCRIPTION
#pod
#pod HTML::Widget::Factory provides a simple, pluggable system for constructing HTML
#pod form controls.
#pod
#pod =cut

#pod =head1 METHODS
#pod
#pod Most of the useful methods in an HTML::Widget::Factory object will be provided
#pod by its plugins.  Consult the documentation for the HTML::Widget::Plugin
#pod modules.
#pod
#pod =head2 new
#pod
#pod   my $factory = HTML::Widget::Factory->new(\%arg);
#pod
#pod This constructor returns a new widget factory.
#pod
#pod The only valid arguments are C<plugins> and C<extra_plugins>, which provide
#pod arrayrefs of plugins to be used.  If C<plugins> is not given, the default
#pod plugin list is used, which is those plugins that ship with
#pod HTML::Widget::Factory.  The plugins in C<extra_plugins> are loaded in addition
#pod to these.
#pod
#pod Plugins may be provided as class names or as objects.
#pod
#pod =cut

my %default_instance;
sub _default_instance {
  $default_instance{ $_[0] } ||= $_[0]->new;
}

my $LOADED_DEFAULTS;
my @DEFAULT_PLUGINS = qw(
  HTML::Widget::Plugin::Attrs
  HTML::Widget::Plugin::Button
  HTML::Widget::Plugin::Checkbox
  HTML::Widget::Plugin::Image
  HTML::Widget::Plugin::Input
  HTML::Widget::Plugin::Link
  HTML::Widget::Plugin::Multiselect
  HTML::Widget::Plugin::Password
  HTML::Widget::Plugin::Radio
  HTML::Widget::Plugin::Select
  HTML::Widget::Plugin::Submit
  HTML::Widget::Plugin::Textarea
);

sub _default_plugins {
  $LOADED_DEFAULTS ||= do {
    Module::Load::load("$_") for @DEFAULT_PLUGINS;
    1;
  };
  return @DEFAULT_PLUGINS;
}

sub new {
  my ($self, $arg) = @_;
  $arg ||= {};

  my $class = ref $self || $self;

  # XXX: I think we need to use default plugins when new is invoked on the
  # class, but get the parent object's plugins when it's called on an existing
  # factory. -- rjbs, 2014-02-21
  my @plugins = $arg->{plugins}
              ? @{ $arg->{plugins} }
              : $class->_default_plugins;

  unshift @plugins, @{ $self->{plugins} } if ref $self;

  if ($arg->{plugins} or $arg->{extra_plugins}) {
    push @plugins, @{ $arg->{extra_plugins} } if $arg->{extra_plugins};
  }

  # make sure plugins given as classes become objects
  ref $_ or $_ = $_->new for @plugins;

  my %widget;
  for my $plugin (@plugins) {
    for my $widget ($plugin->provided_widgets) {
      my ($method, $name) = ref $widget ? @$widget : ($widget) x 2;

      Carp::croak "$plugin tried to provide $name, already provided by $widget{$name}{plugin}"
        if $widget{$name};

      Carp::croak
        "$plugin claims to provide widget via ->$method but has no such method"
        unless $plugin->can($method);

      $widget{$name} = { plugin => $plugin, method => $method };
    }
  }

  # for some reason PPI/Perl::Critic think this is multiple statements:
  bless { ## no critic
    plugins => \@plugins,
    widgets => \%widget,
  } => $class;
}

#pod =head2 provides_widget
#pod
#pod   if ($factory->provides_widget($name)) { ... }
#pod
#pod This method returns true if the given name is a widget provided by the factory.
#pod This, and not C<can> should be used to determine whether a factory can provide
#pod a given widget.
#pod
#pod =cut

sub provides_widget {
  my ($self, $name) = @_;
  $self = $self->_default_instance unless ref $self;

  return 1 if $self->{widgets}{$name};

  return;
}

#pod =head2 provided_widgets
#pod
#pod   for my $name ($fac->provided_widgets) { ... }
#pod
#pod This method returns an unordered list of the names of the widgets provided by
#pod this factory.
#pod
#pod =cut

sub provided_widgets {
  my ($self) = @_;
  $self = $self->_default_instance unless ref $self;

  return keys %{ $self->{widgets} };
}

my $ErrorMsg = qq{Can\'t locate object method "%s" via package "%s" }.
               qq{at %s line %d.\n};

sub AUTOLOAD {
  my $widget_name = our $AUTOLOAD;
  $widget_name =~ s/.*:://;

  return if $widget_name eq 'DESTROY' or $widget_name eq 'CLONE';

  my ($self, $given_arg) = @_;
  my $class = ref $self || $self;
  my $howto = $self->{widgets}{$widget_name};

  unless ($howto) {
    my ($callpack, $callfile, $callline) = caller;
    die sprintf $ErrorMsg, $widget_name, $class, $callfile, $callline;
  }

  return $self->_build_widget(@$howto{qw(plugin method)}, $given_arg);
}

sub _build_widget {
  my ($self, $plugin, $method, $given_arg) = @_;

  my $arg = $plugin->rewrite_arg($given_arg, $method);

  return $plugin->$method($self, $arg);
}

sub can {
  my ($self, $method) = @_;

  return sub { $self->$method(@_) }
    if ref $self and $self->{widgets}{$method};

  return $self->SUPER::can($method);
}

#pod =head2 plugins
#pod
#pod This returns a list of the plugins loaded by the factory.
#pod
#pod =cut

sub plugins { @{ $_[0]->{plugins} } }

#pod =head1 TODO
#pod
#pod =over
#pod
#pod =item * fixed_args for args that are fixed, like (type => 'checkbox')
#pod
#pod =item * a simple way to say "only include this output if you haven't before"
#pod
#pod This will make it easy to do JavaScript inclusions: if you've already made a
#pod calendar (or whatever) widget, don't bother including this hunk of JS, for
#pod example.
#pod
#pod =item * giving the constructor a data store
#pod
#pod Create a factory that has a CGI.pm object and let it default values to the
#pod param that matches the passed name.
#pod
#pod =item * include id attribute where needed
#pod
#pod =item * optional labels (before or after control, or possibly return a list)
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item L<HTML::Widget::Plugin>
#pod
#pod =item L<HTML::Widget::Plugin::Input>
#pod
#pod =item L<HTML::Widget::Plugin::Submit>
#pod
#pod =item L<HTML::Widget::Plugin::Link>
#pod
#pod =item L<HTML::Widget::Plugin::Image>
#pod
#pod =item L<HTML::Widget::Plugin::Password>
#pod
#pod =item L<HTML::Widget::Plugin::Select>
#pod
#pod =item L<HTML::Widget::Plugin::Multiselect>
#pod
#pod =item L<HTML::Widget::Plugin::Checkbox>
#pod
#pod =item L<HTML::Widget::Plugin::Radio>
#pod
#pod =item L<HTML::Widget::Plugin::Button>
#pod
#pod =item L<HTML::Widget::Plugin::Textarea>
#pod
#pod =item L<HTML::Element>
#pod
#pod =back
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widget::Factory - churn out HTML widgets

=head1 VERSION

version 0.204

=head1 SYNOPSIS

 my $factory = HTML::Widget::Factory->new();

 my $html = $factory->select({
   name    => 'flavor',
   options => [
     [ minty => 'Peppermint',     ],
     [ perky => 'Fresh and Warm', ],
     [ super => 'Red and Blue',   ],
   ],
   value   => 'minty',
 });

=head1 DESCRIPTION

HTML::Widget::Factory provides a simple, pluggable system for constructing HTML
form controls.

=head1 METHODS

Most of the useful methods in an HTML::Widget::Factory object will be provided
by its plugins.  Consult the documentation for the HTML::Widget::Plugin
modules.

=head2 new

  my $factory = HTML::Widget::Factory->new(\%arg);

This constructor returns a new widget factory.

The only valid arguments are C<plugins> and C<extra_plugins>, which provide
arrayrefs of plugins to be used.  If C<plugins> is not given, the default
plugin list is used, which is those plugins that ship with
HTML::Widget::Factory.  The plugins in C<extra_plugins> are loaded in addition
to these.

Plugins may be provided as class names or as objects.

=head2 provides_widget

  if ($factory->provides_widget($name)) { ... }

This method returns true if the given name is a widget provided by the factory.
This, and not C<can> should be used to determine whether a factory can provide
a given widget.

=head2 provided_widgets

  for my $name ($fac->provided_widgets) { ... }

This method returns an unordered list of the names of the widgets provided by
this factory.

=head2 plugins

This returns a list of the plugins loaded by the factory.

=head1 TODO

=over

=item * fixed_args for args that are fixed, like (type => 'checkbox')

=item * a simple way to say "only include this output if you haven't before"

This will make it easy to do JavaScript inclusions: if you've already made a
calendar (or whatever) widget, don't bother including this hunk of JS, for
example.

=item * giving the constructor a data store

Create a factory that has a CGI.pm object and let it default values to the
param that matches the passed name.

=item * include id attribute where needed

=item * optional labels (before or after control, or possibly return a list)

=back

=head1 SEE ALSO

=over

=item L<HTML::Widget::Plugin>

=item L<HTML::Widget::Plugin::Input>

=item L<HTML::Widget::Plugin::Submit>

=item L<HTML::Widget::Plugin::Link>

=item L<HTML::Widget::Plugin::Image>

=item L<HTML::Widget::Plugin::Password>

=item L<HTML::Widget::Plugin::Select>

=item L<HTML::Widget::Plugin::Multiselect>

=item L<HTML::Widget::Plugin::Checkbox>

=item L<HTML::Widget::Plugin::Radio>

=item L<HTML::Widget::Plugin::Button>

=item L<HTML::Widget::Plugin::Textarea>

=item L<HTML::Element>

=back

=head1 AUTHOR

Ricardo SIGNES

=head1 CONTRIBUTORS

=for stopwords Hans Dieter Pearcey Ricardo SIGNES Signes

=over 4

=item *

Hans Dieter Pearcey <hdp@cpan.org>

=item *

Ricardo SIGNES <rjbs@codesimply.com>

=item *

Ricardo SIGNES <rjbs@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
