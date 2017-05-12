package JS::JSORB;
use Moose;

use Class::Inspector;
use File::Copy  'copy';
use Path::Class ();

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

has 'file' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    lazy     => 1,
    default  => sub {
        Path::Class::File->new(
            Class::Inspector->loaded_filename( __PACKAGE__ )
        )->parent->file(
            'JSORB.js'
        )
    },
);

sub copy_file_to {
    my ($self, $to) = @_;
    (defined $to)
        || confess "You must provide a place to copy to";
    copy( $self->file->stringify, $to )
        || confess "Could not copy JSORB.js to $to because: $!";
}

no Moose; 1;

__END__

=pod

=head1 NAME

JS::JSORB - Javascript client for JSORB

=head1 SYNOPSIS

  # in your Perl ...
  use JS::JSORB;

  my $js_jsorb = JS::JSORB->new;

  # get a Path::Class::File
  # representing the path to
  # the JSORB.js file
  my $jsorb_js_file = $js_jsorb->file;

  # install a local copy
  $js_jsorb->copy_file_to( '/webroot/js/JSORB.js' );

  // in your javascript ...

  var c = new JSORB.Client ({
      base_url : 'http://localhost:8080/',
  })

  c.call({
      method : '/math/simple/add',
      params : [ 2, 2 ]
  }, function (result) {
      alert(result)
  });

=head1 DESCRIPTION

This is basically the JS:: module for the JSORB Javascript client.
If you don't know about JS.pm, you should really check it out.

We also provide some basic functions to make it easy for you to
retrieve the path to the installed JSORB.js file, to slurp the
contents of the file into a string and to copy the file into another
directory (such as your web directory).

=head1 METHODS

=over 4

=item I<file>

This returns L<Path::Class::File> instance that represents the path
to the JSORB.js file.

=item I<copy_file_to( $dest )>

This will copy the JSORB.js file to C<$dest>.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
