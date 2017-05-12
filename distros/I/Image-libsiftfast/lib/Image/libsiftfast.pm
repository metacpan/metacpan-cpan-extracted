package Image::libsiftfast;
use strict;
use warnings;
use File::Which qw(which);
use Imager;

our $VERSION = '0.03';

sub new {
    my $class = shift;
    my $self  = bless {
        siftfast_path => which("siftfast") || undef,
        imager => Imager->new,
        @_,
    }, $class;
    return $self;
}

sub convert_to_pnm {
    my $self = shift;
    my $file = shift;

    my $imager = $self->{imager};
    $imager->read( file => $file ) or die $imager->errstr;
    my $new = $imager->convert( preset => 'grey' );
    $file =~ s/jpg/pnm/;
    $new->write( file => $file, type => "pnm", pnm_write_wide_data => 1 )
        or die($!);
    return $file;
}

sub extract_keypoints {
    my $self     = shift;
    my $pnm_file = shift;

    my $siftfast_path = $self->{siftfast_path};
    my @stdout        = `$siftfast_path < $pnm_file 2>&1`;

    my $stderr_message = shift @stdout;
    $stderr_message .= shift @stdout;
    my ($image_size)
        = $stderr_message =~ /Finding keypoints \(image ([^\)]+)\).../g;
    my ( $keypoint_num, $elapsed )
        = $stderr_message =~ /(\d+) keypoints found in ([0-9.]+) seconds./g;

    my @array = map { chomp $_; $_ } @stdout;
    shift @array;    # remove first line;
    my $return_string = join( "\n", @array );

    my @keypoints;
    for ( split "\n\n", $return_string ) {
        my @rec = split "\n", $_;
        my @array;
        for (@rec) {
            my @f = split " ", $_;
            push @array, @f;
        }
        my $X           = shift @array;
        my $Y           = shift @array;
        my $scale       = shift @array;
        my $orientation = shift @array;
        my $vector      = \@array;

        push @keypoints,
            {
            frames => {
                X           => $X,
                Y           => $Y,
                scale       => $scale,
                orientation => $orientation,
            },
            vector => $vector,
            };
    }

    return {
        keypoint_num => $keypoint_num,
        elapsed      => $elapsed,
        image_size   => $image_size,
        keypoints    => \@keypoints,
    };
}

1;
__END__

=head1 NAME

Image::libsiftfast - perl wrapper of siftfast (libsiftfast) command.

=head1 SYNOPSIS

  use Image::libsiftfast;

  my $sift = Image::libsiftfast->new(siftfast_path => "/usr/local/bin/siftfast");

  # $sift recieves only grayscale file.
  # If you don't have any grayscale file, convert it to pnmfile.

  my $pnm_file = $sift->convert_to_pnm($jpeg_file);

  # It returns a perl data structure. 
  my $data = $sift->extract_keypoints($pnm_file);


=head1 DESCRIPTION

Image::libsiftfast is a siftfast (libsiftfast) command wrapper.

The object returns a perl data structure that have 'keypoints_num', 'elapsed', 'image_size' and keypoints.
All of the keypoint data contains 'frames' and 'vector' block.
The frames have 'X', 'Y' coordinate  and 'scale' and 'orientaiton' information.
The vectors is constructed in 128 dimensions. That is array reference.


WARNING: This module relies on siftfast command ( libsiftfast c++ library ).
         If you want to know and install libsiftfast, see the maual site.
         ( http://sourceforge.net/projects/libsift/ )


=head1 METHODS

=head2 new( [SIFTFAST_PATH] )

=head2 convert_to_pnm(IMAGE FILE)

=head2 extract_keypoints(GRAYSCALE IMAGE FILE)


=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 SEE ALSO

http://sourceforge.net/projects/libsift/

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
