package Image::Randim::Source;
our $VERSION = '0.02';
use v5.20;
use Moose;
use Module::Find;
use namespace::autoclean;

usesub Image::Randim::Source;

has 'src_obj' => (
  is  => 'ro',
  isa => 'Image::Randim::Source::Role',
);

has 'timeout' => (
  is  => 'rw',
  isa => 'Int',
  default => 20,
);

# This property will be removed - it's only here to fix the badness
# of people who don't keep their module libraries clean between
# released versions of this module.
has 'autoload_blacklist' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { {'Image::Randim::Source::Role'      => 1,
                    'Image::Randim::Source::Desktoppr' => 1,
                  }
                },
);

sub list {
  my $self = shift;
  #my @class = map { s/.+::(.+)$/$1/r } grep {!/::Role$/ && !/::Desktoppr$/} findsubmod Image::Randim::Source;
  my @class;
  foreach (findsubmod Image::Randim::Source) {
    next if defined ${$self->autoload_blacklist}{$_};
    push @class, s/.+::(.+)$/$1/r;
  }
  return \@class;
}

sub set_provider {
    my ($self, $source_name) = @_;
    $self->{src_obj} = "Image::Randim::Source::$source_name"->new;
    $self->{src_obj}->timeout($self->timeout);
    return $self->src_obj;
}

sub set_random_provider {
    my ($self, $provider_names) = @_;
    my $source = $provider_names ? $provider_names : $self->list;
    return $self->set_provider($$source[int(rand(scalar @$source))]);
}

sub url {
    my $self = shift;
    die 'No valid provider' unless $self->src_obj;
    return $self->src_obj->url;
}

sub name {
    my $self = shift;
    die 'No valid provider' unless $self->src_obj;
    return $self->src_obj->name;
}

sub get_image {
    my $self = shift;
    die 'No valid provider' unless $self->src_obj;
    return $self->src_obj->get_image;
}

__PACKAGE__->meta->make_immutable;
1;

=pod

=head1 NAME

Image::Randim::Source - Pull a random image from a source

=head1 SYNOPSIS

  use Image::Randim::Source;
  
  $source = Image::Randim::Source->new;
  $source->set_random_provider;
  $image = $source->get_image;

  say $image->url;

=head1 DESCRIPTION

This is the main class to instantiate when wanting to pull random
image information from the defined sources.

You can specifically state which source to use to pull a random image
from by using the set_provider() method, or you can also let the
provider be a random choice too by calling the method
set_random_provider() instead.

Nothing much will work until you call one of those two methods, except
for list(), which returns a list of defined sources (providers of
images).

=head1 METHODS

=head2 C<list>

Return a list of supported providers (ones with "plugins").

=head2 C<set_provider($provider_name)>

Sets the provider name to use, to grab a random image. Valid ones can
be found with the list() method.

"Plugins" can be created to support more providers by implementing the
Image::Randim::Source::Role

=head2 C<set_random_provider(['name1', 'name2'])>

Without any parameters, chooses a random provider from the list() of
possible providers and set_provider()'s to it.

An array ref - a list of source providers names - can be provided if
you want to limit the random choice to just those providers.

=head2 C<url>

Returns the URL from which the provider information is gathered. You
probably don't need to care about this.

=head2 C<name>

Returns the provider name (as it was set by set_provider())

=head2 C<get_image>

Returns an Image::Randim::Image object, populated with the necessary
information to download the image, and image credits for the owner of
the image, as well as reported dimensions of the image.

=head1 ATTRIBUTES

=head2 C<timeout>

Gets or sets the timeout in seconds we will wait for a response from
the provider's server for the information. If you want something
different than the default (25 seconds) you must set this attribute
before calling the set_* methods.

=head2 C<src_obj>

Gives access to the provider "plugin" object directly. Not typically
needed.

=head1 AUTHOR

Mark Rushing <mark@orbislumen.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Home Grown Systems, SPC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
