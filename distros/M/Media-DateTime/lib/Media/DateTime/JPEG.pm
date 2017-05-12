package Media::DateTime::JPEG;

# ABSTRACT: A plugin for the C<Media::DateTime> module to support JPEG files

use strict;
use warnings;

our $VERSION = '0.49';

use Carp;
use Image::ExifTool;
use DateTime;
use Scalar::Util 'blessed';
use Try::Tiny;

my $exifTool;

sub datetime {
    my ( $self, $f ) = @_;

    $exifTool = Image::ExifTool->new() unless $exifTool;
    $exifTool->ExtractInfo($f) or do {
        warn "Exiftool unable to read: $f\nFallback to file timestamp.\n";
        return;
    };

    my $datetime = $exifTool->GetValue('DateTimeOriginal')
      or do {
        warn "JPEG does not contain DateTimeOriginal exif entry ($f),\n"
          . "Fallback to file timestamp.\n";
        return;
      };

    # DateTime format = yyyy:mm:dd hh:mm:ss
    my ( $y, $m, $d, $h, $min, $s ) = $datetime =~ m/
                        (\d{4})  :  # year
                        (\d{2})  :  # month
                        (\d{2})     # day
                            \s      # space
                        (\d{2})  :  # hour
                        (\d{2})  :  # min
                        (\d{2})     # sec
                    /x
      or do {
        warn "failed DateTime pattern match in $f\n"
          . "Fallback to file timestamp";
        return;
      };

    my $date = try {
        DateTime->new(
            year   => $y,
            month  => $m,
            day    => $d,
            hour   => $h,
            minute => $min,
            second => $s,
        );
    }
    catch {
        if ((blessed $_ && $_->isa('Specio::Exception')) || /to DateTime::new did not pass/) {
            warn
              "JPEG's DateTimeOriginal exif entry ($f) not a valid datetime.\n"
              . "Fallback to file timestamp.\n";
            return undef;
        } else {
            die;
        }
    };

    return $date;
}

sub match {
    my ( $self, $f ) = @_;

    return $f =~ /\.jpe?g$/i;    ## no critic
        # TODO: should we use something more complicated here? maybe mime type?
}

1;

__END__

=pod

=head1 NAME

Media::DateTime::JPEG - A plugin for the C<Media::DateTime> module to support JPEG files

=head1 VERSION

version 0.49

=head1 SYNOPSIS

C<Media::DateTime::JPEG> shouldn't be used directly. See C<Media::DateTime>.

=head1 METHODs

=over 2

=item match

Takes a filename as an arguement. Used by the plugin system to determine if
this plugin should be utilized for the file. Returns true if the filename
ends in .jpeg or .jpg. 

=item datetime

Takes a filename as an arguement and returns the creation date or a false
value if we are unable to parse it.

=back

=head1 SEE ALSO

See C<Media::DateTime> for usage. C<Image::Info> is used to extract data from
JPEG files.

=head1 FUTURE PLANS

May use a more flexible approach to assertaining if a file is a jpeg and 
might check that exif data exists in the C<match> method.

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
