package MasonX::Resolver::WidgetFactory;
{
  $MasonX::Resolver::WidgetFactory::VERSION = '0.009';
}
# ABSTRACT: resolve paths to HTML::Widget::Factory plugins

use Moose;
BEGIN { extends 'HTML::Mason::Resolver' }

use HTML::Widget::Factory 0.067; # provides_widget
use HTML::Mason::Tools qw(paths_eq);
use File::Spec;
use Storable qw(nfreeze);
use Digest::MD5 qw(md5_hex);


sub validation_spec {
  my $self = shift;
  return {
    %{ $self->SUPER::validation_spec || {} },
    prefix  => 1,
    strict  => { optional => 1 },
    factory => { optional => 1 },
  },
}

has factory => (
  is => 'rw',
  isa => 'HTML::Widget::Factory',
  lazy => 1,
  default => sub { HTML::Widget::Factory->new },
);

has prefix => (
  is => 'rw',
  isa => 'Str',
  required => 1,
);

has strict => (
  is => 'rw',
  isa => 'Bool',
  default => 0,
);

has source_cache => (
  is => 'rw',
  isa => 'HashRef',
  lazy => 1,
  default => sub { {} },
);

sub _stupid_global {
  my ($self) = @_;
  return ref($self) . '::factory_' . _signature($self->factory);
}

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  # this is terrible, but I can't see a better way to share the factory
  my $stupid_global = $self->_stupid_global;
  my $factory = $self->factory;
  {
    no strict 'refs';
    defined &{$stupid_global} or *{$stupid_global} = sub () { $factory };
  }
  return $self;
}

sub _matches {
  my ($self, $path) = @_;
  my $prefix = $self->prefix;
  return $path =~ m{^$prefix(?:/([^/]+))?$};
}

sub get_info {
  my ($self, $path, $comp_root_key, $comp_root_path) = @_;

  my ($widget) = $self->_matches($path) or return;

  unless ($self->factory->provides_widget($widget)) {
    die "factory does not provide '$widget' ($path)" if $self->strict;
    return;
  }

  return HTML::Mason::ComponentSource->new(
    friendly_name   => "$widget widget",
    comp_id         => "widget:$path",
    last_modified   => $^T,
    comp_path       => $path,
    comp_class      => 'HTML::Mason::Component',
    source_callback => sub { $self->generate_source($widget) },
  );
}

sub glob_path {
  my ($self, $pattern, $comp_root_path) = @_;
  return; # meaningless
}

my %content_default = (
  link     => 'html',
  button   => 'html',
  textarea => 'value',
);

sub _signature {
  my ($factory) = @_;
  return md5_hex(nfreeze($factory));
}

sub generate_source {
  my ($self, $widget) = @_;

  return $self->source_cache->{$widget} if $self->source_cache->{$widget};

  $self->source_cache->{$widget} = do {
    sprintf <<'END',
<%%init>
my $content_param = $ARGS{'-content'} || '%s';
if ($m->has_content) {
  die "content passed to widget '%s', but no -content argument given "
    . "and no default content argument exists"
    unless $content_param;
  die "component-with-content call for widget '%s' has content bound "
    . "to '$content_param' but also includes an argument with that name"
    if exists $ARGS{$content_param};
  $ARGS{$content_param} = $m->content;
  } # stupid vim syntax highlighting gets this wrong if in column 0
</%%init>
<%% %s->%s(\%%ARGS) %%>
END
      $content_default{$widget} || '',
      $widget, $widget,
      $self->_stupid_global, $widget;
  };

  chomp $self->source_cache->{$widget};
  return $self->source_cache->{$widget};
}

# we don't need apache_request_to_comp_path if we're being used with
# Resolver::File and Multiplex

1;

__END__

=pod

=head1 NAME

MasonX::Resolver::WidgetFactory - resolve paths to HTML::Widget::Factory plugins

=head1 VERSION

version 0.009

=head1 SYNOPSIS

  use MasonX::Resolver::WidgetFactory;

  my $res = MasonX::Resolver::WidgetFactory->new(
    factory => My::Widget::Factory->new,
    prefix => '/widget',
  );

  my $interp = HTML::Mason::Interp->new(
    resolver => $res,
    # ... other options ...
  );

=head1 DESCRIPTION

This Resolver exposes the plugins of a L<HTML::Widget::Factory> object as
virtual components under a given prefix.

For example:

  my $res = MasonX::Resolver::WidgetFactory->new(
    prefix => '/widget',
  );

  # elsewhere:
  
  <& /widget/select, name => "myselect", options => \@options &>

The component call to C</widget/select> is translated to C<< $factory->select(...arguments...) >>.

Among other things, this means that you can use component-with-content calls,
which may be easier in some situations:

  <&| /widget/button &>
  This is normal mason content, including <% $various_interpolations %>
  and other <& /component/calls &>
  </&>

=head2 prefix

The component path root under which to respond.

=head2 factory

The HTML::Widget::Factory object to use.  Defaults to a new
HTML::Widget::Factory object.

=head2 strict

Boolean.  If false (the default), the resolver will return false when asked to
resolve a path that does not correspond to a widget provided by the factory.
If true, it will die instead.

=head1 AUTHOR

Hans Dieter Pearcey, <hdp at pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
