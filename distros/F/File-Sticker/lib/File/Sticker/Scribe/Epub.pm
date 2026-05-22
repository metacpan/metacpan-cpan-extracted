package File::Sticker::Scribe::Epub;
$File::Sticker::Scribe::Epub::VERSION = '4.605';
=head1 NAME

File::Sticker::Scribe::Epub - read, write and standardize meta-data from GIF file

=head1 VERSION

version 4.605

=head1 SYNOPSIS

    use File::Sticker::Scribe::Epub;

    my $obj = File::Sticker::Scribe::Epub->new(%args);

    my %meta = $obj->read_meta($filename);

    $obj->write_meta(%args);

=head1 DESCRIPTION

This will read meta-data from EPUB files, and standardize it to a common
nomenclature, such as "tags" for things called tags, or Keywords or Subject etc.

=cut

use common::sense;
use Carp;
use File::LibMagic;
use Image::ExifTool qw(:Public);
use YAML::Any;
use File::Spec;

use parent qw(File::Sticker::Scribe::Exif);

# FOR DEBUGGING
=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 priority

The priority of this scribe.  Scribes with higher priority get tried first.

=cut

sub priority {
    my $class = shift;
    return 2;
} # priority

=head2 allowed_file

If this scribe can be used for the given file, then this returns true.
File must be an EPUB file.

=cut

sub allowed_file {
    my $self = shift;
    my $file = shift;
    say STDERR whoami() if $self->{verbose} > 2;

    my $realfile = $self->_get_the_real_file(filename=>$file);
    my $ft = $self->{file_magic}->info_from_filename($realfile);
    # The mime type may not be correct, so check the extension as well
    if ($ft =~ /epub/ or $realfile =~ /\.epub/)
    {
        say STDERR 'Scribe ' . $self->name() . ' allows filetype ' . $ft->{mime_type} . ' of ' . $realfile if $self->{verbose} > 1;
        return 1;
    }
    return 0;
} # allowed_file

=head1 Helper Functions

Private interface.

=head2 _get_the_real_file

If the file is a soft link, look for the file it is pointing to
(because ExifTool behaves badly with soft links).

    my $real_file = $scribe->_get_the_real_file(filename=>$filename);

=cut

sub _get_the_real_file {
    my $self = shift;
    my %args = @_;
    say STDERR whoami() if $self->{verbose} > 2;

    my $filename = $args{filename};
    # ExifTool has a wicked habit of replacing soft-linked files with the
    # contents of the file rather than honouring the link.  While using the
    # exiftool script offers -overwrite_original_in_place to deal with this,
    # the Perl module does not appear to have such an option available.

    # So the way to get around this is to check if the file is a soft link, and
    # if it is, find the real file, and write to that. And if *that* file is
    # a soft link... go down the rabbit-hole as deep as it goes.

    while (-l $filename)
    {
        my $realfile = readlink $filename;
        if (-f $realfile)
        {
            $filename = $realfile;
        }
        else # give up and die
        {
            croak "$args{filename} is soft link, cannot find $realfile";
        }
    }

    return $filename;
} # _get_the_real_file

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Scribe::Epub
__END__
