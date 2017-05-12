package Image::ObjectDetect;
use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT);

BEGIN {
    $VERSION = '0.12';
    if ($] > 5.006) {
        require XSLoader;
        XSLoader::load(__PACKAGE__, $VERSION);
    } else {
        require DynaLoader;
        @ISA = qw(DynaLoader);
        __PACKAGE__->bootstrap;
    }
    require Exporter;
    push @ISA, 'Exporter';
    @EXPORT = qw(detect_objects);
}

sub detect {
    my ($self, $file) = @_;
    my $ret = $self->xs_detect($file);
    wantarray ? @$ret : $ret;
}

sub detect_objects {
    __PACKAGE__->new($_[0])->detect($_[1]);
}

1;
__END__

=head1 NAME

Image::ObjectDetect - detects objects from picture(using opencv)

=head1 SYNOPSIS

  use Image::ObjectDetect;

  my $cascade = 'haarcascade_frontalface_alt2.xml';
  my $file = 'picture.jpg';
  my $detector = Image::ObjectDetect->new($cascade);
  @faces = $detector->detect($file);
  for my $face (@faces) {
      print $face->{x}, "\n";
      print $face->{y}, "\n";
      print $face->{width}, "\n";
      print $face->{height}, "\n";
  }
  # or just like this
  my @faces = detect_objects($cascade, $file);

=head1 DESCRIPTION

Image::ObjectDetect is a simple module to detect objects from picture using opencv.

It is available at: http://sourceforge.net/projects/opencvlibrary/

=head1 METHODS

=over 4

=item new($cascade)

Returns an instance of this module.

=item detect($file)

Detects objects from picture.

=back

=head1 FUNCTIONS

=over 4

=item detect_objects($cascade, $file)

Detects objects from picture.

=back

=head1 EXPORT

detect_objects

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://sourceforge.net/projects/opencvlibrary/>

=cut

