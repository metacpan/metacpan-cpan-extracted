package Image::Randim::Image;
our $VERSION = '0.01';
use v5.20;
use warnings;
use Moose;
use namespace::autoclean;

has 'id' => ( is  => 'rw',
	      isa => 'Str',
    );
has 'width' => ( is  => 'rw',
		 isa => 'Int',
    );
has 'height' => ( is  => 'rw',
		  isa => 'Int',
    );
has 'url' => ( is  => 'rw',
	       isa => 'Str',
    );
has 'filename' => ( is  => 'rw',
		    isa => 'Str',
    );
has 'owner' => ( is  => 'rw',
		 isa => 'Maybe[Str]',
    );
has 'owner_name' => ( is  => 'rw',
		      isa => 'Maybe[Str]',
    );
has 'link' => ( is  => 'rw',
		isa => 'Str',
    );

__PACKAGE__->meta->make_immutable;
1;

=pod

=head1 NAME

Image::Randim::Image - Image object

=head1 SYNOPSIS

  use Image::Randim::Source;
  
  $source = Image::Randim::Source->new;
  $source->set_provider('Unsplash');
  $image = $source->get_image;

  say $image->url;

=head1 DESCRIPTION

This is the image object returned by Image::Randim::Source which
contains information about the image.

=head1 ATTRIBUTES

=head2 C<url>

The URL where the image can be reached.

=head2 C<link>

The URL that links to the page at the source that gives credit to the
creator and where you can find more detailed information about the
image.

=head2 C<owner>

The userid of the owner (author, creator) of the image. Not always
there.

=head2 C<owner_name>

The full name of the owner, which is not always there.

=head2 C<width>

The width in pixels, AS REPORTED BY THE SOURCE SITE.

=head2 C<height>

The height in pixels, AS REPORTED BY THE SOURCE SITE.

=head2 C<filename>

The local filename, either provided by the source site or created
locally. This is not set usually on the source call, but rather on the
download call -- don't count on this to be set unless you or a script
set it.

=head1 AUTHOR

Mark Rushing <mark@orbislumen.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Home Grown Systems, SPC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
