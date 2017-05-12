package Image::EXIF;

use 5.008;
use strict;
use warnings;

our $VERSION = '2.01';

use Carp ();

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub new {
    my ($class, $file_name) = @_;

    my $self = $class->_new_instance;

    $self->file_name("$file_name") if defined $file_name;

    return $self;
}

# These exist for compatibility with the historical API
sub error  { 0 }
sub errstr { undef }

sub file_name {
    my $self = shift;
    if (@_) {
        my $file_name = shift;
        Carp::croak("Image::EXIF file name undefined")
            if !defined $file_name;
        $self->_load_file("$file_name");
    }
    return $self->_file_name if defined wantarray;
}

sub get_all_info {
    my ($self) = @_;

    my %hash;
    for my $key (qw<camera image other unknown>) {
        my $method = "get_$key\_info";
        my $data = $self->$method or next;
        $hash{$key} = $data;
    }

    return %hash ? \%hash : undef;
}

sub DESTROY {
    my ($self) = @_;
    $self->_destroy_instance;
}

1;
__END__

=head1 NAME

Image::EXIF - Perl extension for exif library

=head1 SYNOPSIS

  use Image::EXIF;
  use Data::Dumper;

  my $exif = Image::EXIF->new($file_name);

  # or:
  my $exif = Image::EXIF->new;
  $exif->file_name($file_name);

  my $image_info = $exif->get_image_info(); # hash reference
  my $camera_info = $exif->get_camera_info(); # hash reference
  my $other_info = $exif->get_other_info(); # hash reference
  my $point_shoot_info = $exif->get_point_shoot_info(); # hash reference
  my $unknown_info = $exif->get_unknown_info(); # hash reference
  my $all_info = $exif->get_all_info(); # hash reference

  print Dumper($all_info);

=head1 DESCRIPTION

Perl package Image::EXIF based on exiftags by Eric M. Johnston:
L<http://johnst.org/sw/exiftags/>.

=head1 AUTHORS

=over 4

=item * Aaron Crane E<lt>arc@cpan.orgE<gt> (current maintainer)

=item * sergey s prozhogin E<lt>ccpro@rrelaxo.org.ruE<gt>

=back

=head1 REPORTING BUGS

Please report bugs at either of the following locations:

=over 4

=item *

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Image-EXIF>

=item *

L<https://github.com/arc/p5-image-exif>

=back

=head1 SEE ALSO

L<exiftags>.

=cut
