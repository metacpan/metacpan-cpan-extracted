package Image::Randim::Source::Unsplash;
our $VERSION = '0.01';
use v5.20;
use warnings;
use JSON;
use Moose;

has 'name' => ( is  => 'ro',
		isa => 'Str',
		default => 'Unsplash',
    );
has 'api_url' => ( is  => 'ro',
		   isa => 'Str',
		   default => 'https://api.unsplash.com/photos/random?client_id=',
    );
has 'api_key' => ( is  => 'rw',
		   isa => 'Str',
		   default => '03ad5bfbaa0acd6c96a728d425e533683ec25e5fb7fcf99f6461720b3d0d75a1',
    );

with 'Image::Randim::Source::Role';

sub url {
    my $self = shift;
    return $self->api_url.$self->api_key;
}

sub get_image {
    my $self = shift;
    my $data = JSON->new->decode($self->get_response);
    
    my $image = Image::Randim::Image->new(
	url    => $$data{'urls'}{'full'},
	id     => $$data{'id'},
	width  => $$data{'width'},
	height => $$data{'height'},
	link   => $$data{'links'}{'html'},
	);
    
    if (exists $$data{'user'}{'username'}) {
	$image->owner($$data{'user'}{'username'});
    }
    if (exists $$data{'user'}{'name'}) {
	$image->owner_name($$data{'user'}{'name'});
    }
    
    return $image;
}

__PACKAGE__->meta->make_immutable;
1;

=pod

=head1 NAME

Image::Randim::Source::Unsplash - Unsplash source plugin

=head1 SYNOPSIS

  use Image::Randim::Source;
  
  $source = Image::Randim::Source->new;
  $source->set_provider('Unsplash');
  $image = $source->get_image;

  say $image->url;

  # OR if you want to use your own Unsplash API client key
  # access the src_obj and set it there before calling get_image

  $source->src_obj->api_key('980ef8da882...');

=head1 DESCRIPTION

You will probably not want to call this directly, and instead ose
Image::Randim::Source as described in that class' documentation.

Unsplash requires that you use a so-called developer API client key to
get a random image information. However, these client keys can be
rate-limited.

If you experience this, you can register for your own developer client
API key and use it instead as outlined in the SYNOPSIS.

Otherwise, this "plugin" conforms to the Image::Randim::Source::Role
just like the others.

=head1 AUTHOR

Mark Rushing <mark@orbislumen.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Home Grown Systems, SPC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
