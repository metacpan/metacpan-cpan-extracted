package Image::Randim::Source::Desktoppr;
our $VERSION = '0.01';
use v5.20;
use warnings;
use JSON;
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

__PACKAGE__->meta->make_immutable;
1;

=pod

=head1 NAME

Image::Randim::Source::Desktoppr - Desktoppr source plugin

=head1 SYNOPSIS

  use Image::Randim::Source;
  
  $source = Image::Randim::Source->new;
  $source->set_provider('Desktoppr');
  $image = $source->get_image;

  say $image->url;

=head1 DESCRIPTION

You will probably not want to call this directly, and instead ose
Image::Randim::Source as described in that class' documentation.

This "plugin" conforms to the Image::Randim::Source::Role and provides
access to a random image information from Desktoppr.

=head1 AUTHOR

Mark Rushing <mark@orbislumen.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Home Grown Systems, SPC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
