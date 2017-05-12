package Image::Processor::Store::File;

use strict;
use base ( 'Image::Processor::Base' );

use File::Path;
use File::Copy;

# handles all the File interaction

sub create_path {
    my ($self,$dir) = @_;
    print "Creating dir '$dir'\n\n" if (!-d $dir);
    my $print_dirs = 0;
    my $perms      = 0777;
    mkpath( "$dir", $print_dirs, $perms ) 
	or return "Can't create directory '$dir': $!";
}

sub extension {
    my ($self,$set) = @_;
    return $self->{'extension'} if !$set;
    $self->{'extension'} = $set;
}

sub get_image_list {
    my ($self,$set) = @_;
    chdir($self->source_directory());
    my $expression = $self->extension() || "jpg|gif";
    # get list of picture
    opendir(DIR, $self->source_directory());
    my @files;    
    @files = grep { /\.($expression)$/i } readdir(DIR);

    closedir(DIR);
    $self->image_list(\@files);
    # $self->image_list([ <*.jpg> ]);

}

sub image_list {
    my ($self,$set) = @_;
    return $self->{'image_list'} if !$set;
    $self->{'image_list'} = $set;
}

sub determine_source {
    my ($self) = @_;
    my $source_dir = $self->cdrom() . "/PICTURES" if $self->cdrom();

    
    $self->source_directory($source_dir);
}


1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Image::Processor::Store::File - Perl extension for Woking with disk stores of images

=head1 SYNOPSIS

  use Image::Processor::Store::File;
  Part of the Image::Processor module

=head1 DESCRIPTION

Image::Processor::Store::File

=head2 EXPORT

None this is all OOP.

=head2 METHODS

    'create_path' - creates the entire path passed to it if it doesn't exist
    
    'get_image_list' - reads a directory for images
    
    'image_list' - used internally to set the image list
    
    'determine_source' - this adds "/PICTURES" on the end of the source if the
                'cdrom' method is set.

    'extension' - used for the regular expression that reads the list of images
    in the source directory. defaults to jpg|gif

=head1 AUTHOR

Aaron Johnson E<lt>solution@gina.netE<gt>


=head1 SEE ALSO

L<perl>.

=cut
