package Image::Randim::Source::Role;
our $VERSION = '0.01';
use v5.20;
use warnings;
use Moose::Role;
use REST::Client;
use Image::Randim::Image;
use namespace::autoclean;

requires 'url', 'name', 'get_image';

has 'timeout' => ( is  => 'rw',
		   isa => 'Int',
		   default => 20,
    );

sub get_response {
    my $self = shift;
    my $client = REST::Client->new;
    $client->setTimeout($self->timeout);
    $client->GET($self->url);
    my $rc = $client->responseCode;
    if ($rc > 200) {
	die 'Source '.$self->name
	    . " received a response code of $rc from "
	    . $self->url . "\n";
    }
    return $client->responseContent;
}

1;

=pod

=head1 NAME

Image::Randim::Source::Role - Source plugins must implement this role

=head1 SYNOPSIS

  package Image::Randim::Source::Desktoppr
  use Moose;

  has 'name' => ( is  => 'ro',
		  isa => 'Str',
		  default => 'Desktoppr',
      );
  has 'url' => ( is  => 'ro',
		 isa => 'Str',
		 default => 'https://api.desktoppr.co/1/wallpapers/random',
      );

  with 'Image::Randim::Source::Role';

  sub get_image {
      my $self = shift;
      my $data = JSON->new->decode($self->get_response);
      $data = $$data{'response'};

      my $image = Image::Randim::Image->new(
	  url    => $$data{'image'}{'url'},
	  id     => $$data{'id'},
	  width  => $$data{'width'},
	  height => $$data{'height'},
	  link   => $$data{'url'},
	  );

      if (exists $$data{'uploader'}) {
	  $image->owner($$data{'uploader'});
      }

      return $image;
  }

=head1 DESCRIPTION

To create a source "plugin" for this library, the plugin must be a
Moose class which implements this role and is named in the
Image::Randim::Source::* namespace.

The class must provide "name", "url" and "get_image" methods or
attributes. "timeout" and "get_response are provided as a convience in
the role but may be overridden.

=head1 ROLE INTERFACE

=head2 C<name>

Plugins must return a name, which is a string representing the source (such as "Desktoppr").

This name must be the same as the name of module's end. For example,
in the case of the module "Image::Randim::Source::Desktoppr", the name
must be "Desktoppr".

=head2 C<url>

Plugins must return a URL, which is a string representing the link
that must be called on the provider's site to get the random image's
data.

This is typically a API call that returns JSON.

=head2 C<get_image>

Plugins must return an Image::Randim::Image object, which is populated
with the information retrieved from the URL call to the provider.

In the SYNOPSIS example, you see that JSON is returned from the
get_response() call to the provider's API (which uses the provided
url()) -- and then that JSON is parsed into a hash that is used to set
the image object attributes, and return it.

=head2 C<timeout($integer)>

How many seconds to wait for a response from the provider's site. This
value is up to the individual plugins to honor, but the provided
convenience method "get_response" honors it.

=head1 CONVENIENCE METHODS

=head2 C<get_response>

Convenience method that will call the given "url" with a GET, and
expect a JSON response within the "timeout" time period.

Whatever is returned can then be used to create that
Image::Randim::Image object. Usually what is returned in JSON -- but
your "get_image" method should handle this reponse and populate the
image object accordingly.

=head1 AUTHOR

Mark Rushing <mark@orbislumen.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Home Grown Systems, SPC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
