package Image::Processor;
use strict;

use base ( 'Image::Processor::Base',
           'Image::Processor::CD',
           'Image::Processor::Interface::Console',
           'Image::Processor::Store::File',
           'Image::Processor::Mail::GetImages',
           'Image::Processor::Create::HTML'
           #'Image::Processor::Interface::Web',
         );

use vars ('$VERSION');

use Image::Magick;

$VERSION = '0.6';

sub process {
    my ($self) = @_;
    if ($self->{'orderid'} eq '' && $self->cdrom ne '') {
        $self->read_info_cd();        
    }
    
    $self->determine_source();    
    
    # exit conditions
    # - no output_directory
    $self->graceful_exit(
        "You have not set the 'output_directory'")
            if !$self->output_directory();

    # - no source_directory
        $self->graceful_exit(
        "You have not set the 'source_directory'")
            if !$self->source_directory();

    $self->get_image_list();
    
    # - no list of images
        $self->graceful_exit(
        qq~
    I have no list of images,
    double check the 'source_directory' or 'drive'.
    I had ~ . $self->cdrom . qq~ as a possible location~)
            if !$self->image_list();

    # - no modify_array
        $self->graceful_exit(
            qq~
    You didn't specify how I should process the images, I need
    an array ref that looks something like this:
        [
         { suffix => 'thumb_', percent => '15' },
         { suffix => 'med_', percent => '50' },
        ]
    pass as an argument into the 'modify_array' method~ )
            if !$self->modify_array() || ref($self->modify_array()) ne 'ARRAY';
    

    
    my $dir = $self->output_directory;
    $dir .= "/CD_" . $self->{'orderid'} if $self->cdrom;
    $self->output_directory($dir);
    print "Working on output for " , $self->output_directory() , "\n";
    # create a directory for storage    
    $self->prompt_to_verify_directory_creation($dir);

    # change to chdir for saving information
    chdir($self->output_directory);

    
    $self->create_path($dir);
    #foreach (@{ $self->image_list() }) {
    #    print "Copying $_\n";
    #    copy("$_","$dir/$_");
    #}
    #$self->create_index_html();
    #$self->create_all_full_size();
    #$self->create_all_medium_images();
    #$self->create_all_thumbnail();
    $self->make_various_sizes( $self->modify_array() );
    
    print "A total of " . @{$self->image_list()} . " images were processed\n";
}

sub list_images {
    my ($self,$set) = @_;
    return $self->{'list_images'} if !$set;
    $self->{'list_images'} = $set;
}

sub modify_array {
    my ($self,$set) = @_;
    return $self->{'modify_array'} if !$set;
    $self->{'modify_array'} = $set;
}

sub copy_images {
    my ($self,$set) = @_;
    return $self->{'copy_images'} if !$set;
    $self->{'copy_images'} = $set;
}

sub resize_image {

    my ($self,$file) = @_;
    
    my($image, $x);
    print "Creating image " . $self->percent . "% the size of $file\n";
    $image = Image::Magick->new;
    $x = $image->Read($self->source_directory . "/$file");
    warn "$x" if "$x";
    $x = $image->Resize('geometry' => $self->percent ."%" );
    warn "$x" if "$x";
    my $suffix = $self->suffix();
    $file =~ s/(\.\w\w\w)/$suffix$1/;
    $x = $image->Write($self->output_directory . "/" . "$file");

    warn $x if $x;        

}

sub make_various_sizes {
    my ($self,$size_list) = @_;
=pod
    # size list example
    $size_list = [
        { suffix => 'small_', percent => '15' },
        { suffix => 'medium_', percent => '50' },
    ];
=cut
    foreach my $size (@{$size_list}) {
        $self->suffix( $size->{'suffix'} );
        $self->percent( $size->{'percent'} );
        $self->resize_images();
    }   
}

sub resize_images {
    my ($self) = @_;
    foreach my $file (@{ $self->image_list() }) {
        $self->resize_image($file);
    }
    
}

sub suffix {
    my ($self,$set) = @_;
    return $self->{'suffix'} if !$set;
    if ($set =~ /none/i) { $self->{'suffix'} = ''; return }
    $self->{'suffix'} = $set;
}


sub percent {
    my ($self,$set) = @_;
    return $self->{'percent'} if !$set;
    
    $self->{'percent'} = $set;
}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Image::Processor - Perl extension for woking with disk stores of images

=head1 SYNOPSIS

  use Image::Processor;
  Part of the Image::Processor module

=head1 DESCRIPTION

NOTE - This module is in early stages of development. It is
hoped that others will help develop it or submit suggestions
for improvements.  I have tested this on the Windows platform
and all the features that support the reason behind
starting this project work fine, that is read a CD and create
more manageable directories with different image sizes on your
hard drive suitable for adding to a web site.  I have a modified
copy of HTML::PhotoAlbum that I can send if you need a way to
manage the albums.  Currently only captions and albums are
supported.

Image::Processor started out as a single module to interact
with a KodakCD.  It has grown into a more encompassing project
with some interesting tools that will help you hopfully manage your
images.  It can at present process KodakCD and Wal-Mart Photo CDs
produced in 2000.  It can also processor a directory of existing photos
as well, but this feature is not as mature as the CD reads.
One utility allows you to extact all your attachments from your email.
It works on all mbox style mail, that includes Netscape (4.7x) on
Windows.  This utility has not been tested on others, but it is based on
Mail::MboxParser which has.

Windows users will need to visit http:://www.imagemagick.org and get
the latest imagemagick dll's and PerlMagick.  PerlMagick is available
via ActiveStates PPM utility, but I have not tested with that version.

Processing is SLOW (2-5 seconds per CD image), due in part to the
fact that the images are very large by default on the CD and
partly because Image::Magick I believe is slow.

=head2 EXPORT

None this is all OOP.

=head1 EXAMPLES

use strict;
use Image::Processor;

my $improcessor = Image::Processor->new();

#Two techniques. The first will prompt you on the console.
#The second will not

#- CONSOLE WAY


$improcessor->console_get_drive();
$improcessor->modify_array( [
        { suffix => 'thumb_', percent => '15' },
        { suffix => 'med_', percent => '50' },
    ] );
$improcessor->prompt_for_output_directory();


#- AUTOMATED WAY



$improcessor->cdrom("E:\\"); # use if you want to get the images from
                       # a lab cd otherwise use something like the line below
#$improcessor->source_directory("c:/Program Files/Apache Group/Apache/htdocs/family/photos/CD_263577");
$improcessor->output_directory("c:/Program Files/Apache Group/Apache/htdocs/family/photos");

# this setups the processing information. you can have as many as you
# like.  Note the default thumbnail HTML page only supports two 
# different sizes.  I have found that the settings below work well
# for the CD that I have tested with. If you know your audience is on
# a good connection with running high resolution a 50 - 60 on the 'NONE'
# would be reasonable
$improcessor->modify_array( [
        { suffix => 'thumb_', percent => '10' },
        { suffix => 'NONE', percent => '30' },
    ] );


$improcessor->process();
$improcessor->create_index_html();

# this block shows how you can pass a different template
# to the thumbnail_template method or index_template method
# to override the default.

#$improcessor->thumbnail_template(qq!
#<html>
#    <head>
#    <title>COOL Thumbnails of Images from {\$orderid}</title>
#    </head>
#    <body>
#    <a href="../">Return to the Album List</a><br>
#    <a href="">Return to Album opening page</a><br>
#    
#    <table align="center">
#        <tr>
#    { my \$count = 1;
#      my \$html = '';
#    foreach my \$file (\@image_list) {
#        \$html .= qq~
#            <td valign="center" align="center"><a href="\$full_suffix\$file"><img src="\$thumb_suffix\$file"></a><td>~;
#        if (\$count % \$columns == 0) { \$html .= qq~
#        </tr>
#        <tr>~; }
#        \$count ++;
#    }
#    \$html    
#    }
#        </tr>
#    </table>
#    </body>
#</html>
#!);

$improcessor->create_index_html();

# create_thumbnails_html requires a minimum of the below
# when used with the default template. you can override
# this by passing 'is_custom' => 1 as the key value pair.

$improcessor->create_thumbnails_html( { thumb_suffix => 'thumb_',
                                  full_suffix  => 'med_' } );

Extract Email attachments

my $get_attachments = Image::Processor->new();

$get_attachments->mbox_file("c:/Program Files/Netscape/users/solution/mail/Inbox");
$get_attachments->attachment_output_directory("c:/tmp/test");
$get_attachments->process_file();

=head2 METHODS

    'process' accepts the following
        This method performs resizing and storing of your images
        from your source directory source.
        
    'list_images' accepts the following
        This will list the images that are in the que to be processed
        
    'copy_images' accepts the following
        This is copy an image from one location to another
        
    'write_caption_file' accepts the following
        Modifies the caption.xml file in the directory the image is in.

    'write_description_file' accepts the following
        Writes description.xml to disk, private.    

    'resize_image' can resize a single image if make_various_sizes
             array has at least one hashref in its element list.
    
    'make_various_sizes' - needs an array of hash refs that look like this:
        [
        { suffix => 'thumb_', percent => '10' },
        { suffix => 'med_', percent => '30' },
        ] );
        The key suffix is what the files will be suffixed with when resize to the
        value associated with the percent key.
        These modifications will not effect your source as long as you specify a different
        file name and/or output directory.

    'resize_images' - default method used to process a list of images, generally used
        internally, but can be accessed directly if needed.

    'suffix' - internal method used to set the suffix for processing

    'percent' - internal method used to set the precent for processing,
        but can be accessed externally if you understand how the process method works.
        In future releases this may change.
    


=head1 AUTHOR

Aaron Johnson E<lt>solution@gina.netE<gt>


=head1 SEE ALSO

L<perl>.

=cut
