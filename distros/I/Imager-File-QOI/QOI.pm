package Imager::File::QOI;
use strict;
use Imager;
use vars qw($VERSION @ISA);

BEGIN {
  $VERSION = "1.000";

  require XSLoader;
  XSLoader::load('Imager::File::QOI', $VERSION);
}

Imager->register_reader
  (
   type=>'qoi',
   single => 
   sub { 
     my ($im, $io, %hsh) = @_;

     my $page = $hsh{page};
     defined $page or $page = 0;
     $im->{IMG} = i_readqoi($io, $page);

     unless ($im->{IMG}) {
       $im->_set_error(Imager->_error_as_msg);
       return;
     }

     return $im;
   },
   multiple =>
   sub {
     my ($io, %hsh) = @_;

     my @imgs = i_readqoi_multi($io);
     unless (@imgs) {
       Imager->_set_error(Imager->_error_as_msg);
       return;
     }

     return map bless({ IMG => $_, ERRSTR => undef }, "Imager"), @imgs;
   },
  );

Imager->register_writer
  (
   type=>'qoi',
   single => 
   sub { 
     my ($im, $io, %hsh) = @_;

     $im->_set_opts(\%hsh, "i_", $im);
     $im->_set_opts(\%hsh, "qoi_", $im);

     unless (i_writeqoi($im->{IMG}, $io)) {
       $im->_set_error(Imager->_error_as_msg);
       return;
     }
     return $im;
   },
   multiple =>
   sub {
     my ($class, $io, $opts, @ims) = @_;

     Imager->_set_opts($opts, "qoi_", @ims);

     my @work = map $_->{IMG}, @ims;
     my $result = i_writeqoi_multi($io, @work);
     unless ($result) {
       $class->_set_error($class->_error_as_msg);
       return;
     }

     return 1;
   },
  );

eval {
  # from Imager 1.008
  Imager->add_type_extensions("qoi", "qoi");
};

1;


__END__

=head1 NAME

Imager::File::QOI - read and write QOI image files

=head1 SYNOPSIS

  use Imager;

  my $img = Imager->new;
  $img->read(file => "foo.qoi")
    or die $img->errstr;

  $img->write(file => "foo.qoi", type => "qoi")
    or die $img->errstr;

=head1 DESCRIPTION

Implements QOI file support for Imager.

=head1 LIMITATIONS

=over

=item *

Due to the limitations of C<QOI> grayscale images are written as RGB
images.

=item *

The decoder limits image sizes to 400 000 000 pixels.

=back

=head2 Image tags

The C<i_format> tag is set to C<qoi> on reading a QOI image.

The C<qoi_colorspace> tag is set based on the colorspace value in the
QOI header when reading.

=head1 BUGS

The bundled reference decoder doesn't fail on truncated files.
https://github.com/phoboslab/qoi/issues/98

The bundled reference decoder doesn't validate the end of file marker.
https://github.com/phoboslab/qoi/issues/96

=head1 LICENSE

Imager::File::QOI is licensed under the same terms as Perl itself.

=head1 AUTHOR

Tony Cook <tony@develop-help.com>

=head1 SEE ALSO

L<Imager>, <Imager::Files>.

L<https://qoiformat.org/>, L<https://github.com/phoboslab/qoi>

=cut
