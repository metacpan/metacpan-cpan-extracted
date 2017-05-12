package File::Type::WebImages;
use strict;
use warnings;
use base 'Exporter';
use vars '@EXPORT_OK';
@EXPORT_OK = 'mime_type';

use IO::File;

our $VERSION = "1.01";

sub mime_type {
  # magically route argument

  my $argument = shift;
  return undef unless defined $argument;

  if (length $argument > 1024 || $argument =~ m/\n/) {
    # assume it's data. Saves a stat call if the data's long
    # also avoids stat warning if there's a newline
    return checktype_contents($argument);
  }
  
  if (-e $argument) {
    if (!-d $argument) {
      return checktype_filename($argument);
    } else {
      return undef; # directories don't have mime types
    }
  }  
  # otherwise, fall back to checking the string as if it's data again
  return checktype_contents($argument);
}

# reads in 16k of selected file, or returns undef if can't open,
# then checks contents
sub checktype_filename {
  my $filename = shift;
  my $fh = IO::File->new($filename) || return undef;
  my $data;
  $fh->read($data, 16*1024);
  $fh->close;
  return checktype_contents($data);
}

# Matches $data against the magic database criteria and returns the MIME
# type of the file.
sub checktype_contents {
  my $data = shift;
  my $substr;

  return undef unless defined $data;

  if ($data =~ m[^\x89PNG]) {
    return q{image/png};
  } 
  elsif ($data =~ m[^GIF8]) {
    return q{image/gif};
  }
  elsif ($data =~ m[^BM]) {
    return q{image/bmp};
  }

  if (length $data > 1) {
    $substr = substr($data, 1, 1024);
    if (defined $substr && $substr =~ m[^PNG]) {
      return q{image/png};
    }
  }
  if (length $data > 0) {
    $substr = substr($data, 0, 2);
    if (pack('H*', 'ffd8') eq $substr ) {
      return q{image/jpeg};
    }
  }

  return undef;
}

1;

__END__

=head1 NAME

File::Type::WebImages - determine web image file types using magic

=head1 SYNOPSIS

    use File::Type::WebImages 'mime_type';
    
    my $type_1 = mime_type($file);
    my $type_2 = mime_type($data);

=head1 DESCRIPTION

C<mime_type()> can use either a filename, or file contents, to determine the
type of a file. The process involves looking the data at the beginning of the file,
sometimes called "magic numbers".

=head1 THE BIG TRADE OFF

For minimum memory consumption, only the following common web image  file types are supported:

BMP, GIF, JPEG and PNG. 
( image/bmp, image/gif, image/jpeg and image/png ).

Unlike with L<File::Type> and L<File::MMagic>, 'undef', not
"application/octet-stream" will be returned for unknown formats. 

Unlike L<File::Type>, we return "image/png" for PNGs, I<not> "image/x-png";

If you want more mime types detected use L<File::Type> or some other module. 

=head1 TODO

It would be even better to have a pluggable system that would allow you 
to plug-in different sets of MIME-types you care about.

=head1 SEE ALSO

L<File::Type>. Similar, but supports over 100 file types.

=head1 ACKNOWLEDGMENTS

File::Type::WebImages is built from a mime-magic file from cleancode.org. The original
can be found at L<http://cleancode.org/cgi-bin/viewcvs.cgi/email/mime-magic.mime?rev=1.1.1.1>.

=head1 AUTHORS

Paul Mison <pmison@fotango.com> - wrote original File::Type
Mark Stosberg <mark@summersault.com> - hacked up this. 

=head1 COPYRIGHT 

Copyright 2003-2004 Fotango Ltd.

=head1 LICENSE

Licensed under the same terms as Perl itself. 

=cut
