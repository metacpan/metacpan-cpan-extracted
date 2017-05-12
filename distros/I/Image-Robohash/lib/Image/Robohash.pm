package Image::Robohash;
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;
no  warnings 'portable';
use Digest::SHA qw/sha512_hex/;
use Graphics::Magick;

our $VERSION = 0.02;

has app_path      => ( isa => 'Str', is => 'rw', default => '.'    );

has req_string    => ( isa => 'Str', is => 'rw', default => ''     );
has req_set       => ( isa => 'Str', is => 'rw', default => 'set1' );
has req_bgset     => ( isa => 'Str', is => 'rw', default => ''     );
has req_size      => ( isa => 'Str', is => 'rw', default => 300    );
has req_ignoreext => ( isa => 'Str', is => 'rw', default => ''     );
has req_ext       => ( isa => 'Str', is => 'rw', default => 'png'  );

has hash_count    => ( isa => 'Int', is => 'ro', default => 11     );
has hash_index_bg => ( isa => 'Int', is => 'ro', default => 3      );
has iter          => ( isa => 'Int', is => 'rw', default => 4      );

has sets   => (
  isa      => 'HashRef[Str]',
  is       => 'ro',
  traits   => ['Hash'],
  handles  => { is_valid_set => 'get' },
  default  => sub { { set1 => 1, set2 => 1, set3 => 1 } }
);

has bgsets => (
  isa      => 'HashRef[Str]',
  is       => 'ro',
  traits   => ['Hash'],
  handles  => { is_valid_bgset => 'get' },
  default  => sub { { bg1 => 1, bg2 => 1 } }
);

has colors => (
  isa      => 'ArrayRef[Str]',
  is       => 'ro',
  traits   => ['Array'],
  handles  => { colors_count => 'count' },
  default  => sub { [qw/blue brown green grey orange pink purple red white yellow/] }
);

sub BUILD {
  $_[0]->validate_parameters;
}

has client_set  => (
  isa           => 'Str',
  is            => 'rw',
  lazy          => 1,
  default       => sub {
    my $self    =  shift;
    my $req_set =  lc $self->req_set;
    $req_set    =  'set1' unless $self->is_valid_set( $req_set );
    if ($req_set eq 'set1') {
      $req_set  =  $self->colors->[ $self->hash_array->[0] % $self->colors_count ]
    }
    return $req_set||'';
  }
);

has hex_digest => (
  isa          => 'Str',
  is           => 'rw',
  lazy         => 1,
  default      => sub { sha512_hex $_[0]->req_string }
);

has hash_array     => (
  isa              => 'ArrayRef[Str]',
  is               => 'rw',
  lazy             => 1,
  default          => sub {
    my $self       =  shift;
    my $hex_digest =  $self->hex_digest;
    my $block_size =  int( length( $hex_digest ) / $self->hash_count );

    my @hashes     =  map {
      my $start    =  $_ * $block_size - $block_size;
      hex substr( $hex_digest, $start, $block_size );
    } 1..$self->hash_count;

    return \@hashes;
  }
);

has dir_count  => (
  isa          => 'Int',
  is           => 'rw',
  lazy         => 1,
  default      => sub {
    my $self   =  shift;
    opendir (my $dh, $self->app_path) or die "Cannot open dir $!";
    my @dirs   =  grep -d $self->app_path."/$_", grep !/\A\.\.?\Z/, readdir $dh;
    closedir $dh;
    return scalar @dirs;
  }
);

sub validate_parameters {
  my $self = shift;

  if ( $self->req_string =~ m!\.(png|gif|jpg|jpeg|bmp|ppm)\Z!i ) {
  	my $ext = $1;
  	$ext    = 'jpg' if lc $ext eq 'jpeg';
  	$self->req_ext( lc $ext );

    if ( $self->req_ignoreext ) {
      my $string = $self->req_string;
      $string    =~ s!\.$ext\Z!!;
      $self->req_string( $string );
    }
  }
}

has lucky_robot_images => (
  isa          => 'ArrayRef[Str]',
  is           => 'rw',
  lazy         => 1,
  default      => sub {
    my $self   =  shift;
    my $images =  $self->get_hash_list( $self->app_path.'/'.$self->client_set );

    my %ranked;
    for my $image (@$images) {
      if ($image =~ m|#([^/]+)|) {
        $ranked{ $1 } = $image;
      }
    }

    my @sorted = map { $ranked{$_} } sort keys %ranked;

    return \@sorted;
  }
);

sub get_hash_list {
  my ($self,$path) = @_;
  return [] unless $path && -d $path;
  my @complete;
  my @local;

  opendir (my $dh, $path) or die "cannot open directory $!";
  my @items = grep !/\A\./, readdir $dh;
  closedir $dh;

  for my $item (sort @items) {
    if (-d "$path/$item") {
      my $sub_files = $self->get_hash_list( "$path/$item" );
      push @complete, @$sub_files if @$sub_files;
    } else {
      push @local, "$path/$item";
    }
  }

  if (my $count = scalar @local) {
    my $element_choice = $self->hash_array->[ $self->iter ] % $count;
    push @complete, $local[ $element_choice ];
    $self->iter( $self->iter + 1 );
  }
  return \@complete;
}

has lucky_background_image => (
  isa          => 'Str',
  is           => 'rw',
  lazy         => 1,
  default      => sub {
    my $self   =  shift;
    return '' unless my $bgset = $self->req_bgset;
    my $dir    =  $self->app_path."/$bgset";
    return '' unless $self->is_valid_bgset( $bgset ) && -d $dir;

    opendir (my $dh,$dir);
    my @pngs = sort grep /\.png\Z/, readdir $dh;
    closedir $dh;

    my $lucky = $pngs[ $self->hash_array->[ $self->hash_index_bg ] % scalar @pngs ];
    join('/',$self->app_path,$bgset,$lucky);
  }
);

has image      => (
  isa          => 'Graphics::Magick',
  is           => 'rw',
  lazy         => 1,
  default      => sub {
    my $self   =  shift;
    my $img    =  Graphics::Magick->new;

    if (my $bg =  $self->lucky_background_image) {
      $img->Read("png:$bg");
      $img->Resize(geometry => '1024x1024');
    } else {
      $img->Set(size => '1024x1024');
      $img->Read('xc:transparent');
    }
    my $limages = $self->lucky_robot_images;

    for my $image (@$limages) {
      my $gmi = Graphics::Magick->new;
      $gmi->Read( "png:$image" );
      $gmi->Resize(    geometry => '1024x1024' );
      $img->Composite( image    => $gmi, compose => 'over' );
    }

    if ( my $geo = $self->req_size ){
      if ( $geo  =~ m|\A[0-9]+\Z|) {
        $geo = $geo.'x'.$geo;
      } elsif ( $geo !~ m|\A[0-9]+x[0-9]+\Z|) {
        $geo = '300x300';
      }
      $img->Resize( geometry => $geo );
    }
    return $img;
  }
);

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Image::Robohash - Headless library to generate Robohash images

=head1 SYNOPSIS

	use Image::Robohash;

	my $robot       =  Image::Robohash->new(
		app_path      => '/path/to/robohash_package',
		req_string    => $string,
		req_set       => 'set1',
		req_bgset     => 'bg1',
		req_size      => '100x100',
		req_ignoreext => 1,
		req_ext       => 'png'
	);

	$robot->image->Write( '/path/to/image.png' );

=head1 DESCRIPTION

Image::Robohash is a Perl port of the Robohash library in Python. It creates
images locally using a local copy of the Robohash image files available on
GitHub (L<https://github.com/e1ven/Robohash>).

In addition to this library, an example L<Mojolicious> webapp and template
are available to run a Robohash mirror. These files are currently available
from the author and may be released in this distribution in the future.

This library does not generate Robohash.org URLs.

=head1 EXPORT

No functions are exported.

=head1 METHODS

=head2 $robot->image

Returns a Graphics::Magick object for the current robot image.

=head1 SEE ALSO

=item * Robohash.org

L<http://robohash.org/>

=item * Robohash.org GitHub repository

L<https://github.com/e1ven/Robohash>

=head1 AUTHORS

John Wang (L<http://johnwang.com>).

Colin Davis created Robohash.org project in Python upon which this code is based.
Thanks to Colin for updating the Robohash.org code to support cross-machine
robot compability based on work in this project.

=head1 COPYRIGHT AND LICENSE (The MIT License)

Copyright (c) 2011 John Wang

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut