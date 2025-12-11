package File::Sticker::Scribe::Exif;
$File::Sticker::Scribe::Exif::VERSION = '4.301';
=head1 NAME

File::Sticker::Scribe::Exif - read, write and standardize meta-data from EXIF file

=head1 VERSION

version 4.301

=head1 SYNOPSIS

    use File::Sticker::Scribe::Exif;

    my $obj = File::Sticker::Scribe::Exif->new(%args);

    my %meta = $obj->read_meta($filename);

    $obj->write_meta(%args);

=head1 DESCRIPTION

This will write meta-data from EXIF files, and standardize it to a common
nomenclature, such as "tags" for things called tags, or Keywords or Subject etc.

=cut

use v5.10;
use Carp;
use common::sense;
use File::LibMagic;
use Image::ExifTool qw(:Public);
use Image::ExifTool::XMP;
use YAML::Any;
use File::Spec;
use List::MoreUtils qw(uniq);

use parent qw(File::Sticker::Scribe);

=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 init

Initialize the object.

    $scribe->init(wanted_fields=>{title=>'TEXT',count=>'NUMBER',tags=>'MULTI'});

=cut

sub init {
    my $self = shift;
    my %parameters = @_;

    $self->SUPER::init(%parameters);

} # init

=head2 priority

The priority of this writer.  Scribes with higher priority get tried first.

=cut

sub priority {
    my $class = shift;
    return 1;
} # priority

=head2 allowed_file

If this scribe can be used for the given file, then this returns true.
File must be one of: PDF or an image which is not a GIF.
(GIF files need to be treated separately)
(ExifTool can't write to EPUB)

=cut

sub allowed_file {
    my $self = shift;
    my $file = shift;
    say STDERR whoami(), " file=$file" if $self->{verbose} > 2;

    $file = $self->_get_the_real_file(filename=>$file);
    my $ft = $self->{file_magic}->info_from_filename($file);
    if ($ft->{mime_type} =~ /(image|pdf)/
            and $ft->{mime_type} !~ /gif/)
    {
        return 1;
    }
    return 0;
} # allowed_file

=head2 known_fields

Returns the fields which this scribe knows about.

    my $known_fields = $scribe->known_fields();

=cut

sub known_fields {
    my $self = shift;

    return {
        title=>'TEXT',
        creator=>'TEXT',
        description=>'TEXT',
        location=>'TEXT',
        tags=>'MULTI',
        %{$self->{wanted_fields}},
    };
} # known_fields

=head2 readonly_fields

Returns the fields which this scribe knows about, which can't be overwritten,
but are allowed to be "wanted" fields. Things like file-size etc.

    my $readonly_fields = $scribe->readonly_fields();

=cut

sub readonly_fields {
    my $self = shift;

    return {
        date=>'TEXT',
        copyright=>'TEXT',
        flash=>'TEXT',
        filesize=>'NUMBER',
        imagesize=>'TEXT',
        imageheight=>'NUMBER',
        imagewidth=>'NUMBER',
        megapixels=>'NUMBER'};
} # readonly_fields

=head2 read_meta

Read the meta-data from the given file.

    my $meta = $obj->read_meta($filename);

=cut

sub read_meta {
    my $self = shift;
    my $filename = shift;
    say STDERR whoami(), " filename=$filename" if $self->{verbose} > 2;

    $filename = $self->_get_the_real_file(filename=>$filename);
    my $exif_options = {DateFormat => "%Y-%m-%d %H:%M:%S"};
    my $info = ImageInfo($filename,$exif_options);
    my %meta = ();

    # Check if this is a Gutenberg book; they have quirks.
    my $is_gutenberg_book = 0;
    if (exists $info->{Identifier}
            and $info->{'Identifier'} =~ m!http://www.gutenberg.org/ebooks/\d+!)
    {
        $is_gutenberg_book = 1;
        # If this is a Gutenberg book, the Identifier holds the correct URL
        $meta{'url'} = $info->{'Identifier'};
    }
    # There are multiple fields which could be used as a file "description".
    # Check through them until you find a non-empty one.
    my $description = '';
    foreach my $field (qw(Caption-Abstract Comment UserComment ImageDescription Description))
    {
        if (exists $info->{$field}
                and $info->{$field}
                and $info->{$field} !~ /^---/ # YAML - not a description!
                and !$description)
        {
            $description = $info->{$field};
            $description =~ s/\n$//; # remove trailing newlines
        }
    }
    $meta{description} = $description if $description;
    # There are multiple fields which could be used as a file content creator.
    # Check through them until you find a non-empty one.
    my $creator = '';
    foreach my $field (qw(Author Artist Creator))
    {
        if (exists $info->{$field} and $info->{$field} and !$creator)
        {
            $creator = $info->{$field};
        }
    }
    $meta{creator} = $creator if $creator;

    # There are multiple fields which could be used as a copyright notice.
    # Check through them until you find a non-empty one.
    my $copyright = '';
    foreach my $field (qw(License Rights))
    {
        if (exists $info->{$field} and $info->{$field} and !$copyright)
        {
            $copyright = $info->{$field};
        }
    }
    $meta{copyright} = $copyright if $copyright;

    # Alt text!
    my $alt_text = '';
    foreach my $field (qw(AltTextAccessibility))
    {
        if (exists $info->{$field} and $info->{$field} and !$alt_text)
        {
            $alt_text = $info->{$field};
        }
    }
    $meta{alt_text} = $alt_text if $alt_text;

    # CreateDate is going to be treated as a separate field
    my $create_date = '';
    foreach my $field (qw(CreateDate))
    {
        if (exists $info->{$field} and $info->{$field} and !$create_date)
        {
            $create_date = $info->{$field};
        }
    }
    $meta{create_date} = $create_date if $create_date;

    # There are multiple fields which could be used as a file date.
    # Check through them until you find a non-empty one.
    my $date = '';
    foreach my $field (qw(DateTimeOriginal Date PublishedDate PublicationDate))
    {
        if (exists $info->{$field} and $info->{$field} and !$date)
        {
            $date = $info->{$field};
        }
    }
    $meta{date} = $date if $date;

    # Use a consistent naming for tag fields.
    # Combine the tag-like fields together.
    # Preserve the order and check for dupicates later with uniq
    my @tags = ();
    foreach my $field (qw(Keywords Subject))
    {
        if (exists $info->{$field} and $info->{$field})
        {
            my $val = $info->{$field};
            my @these_tags;
            if ($is_gutenberg_book)
            {
                # gutenberg tags are multi-word, separated by comma-space or ' -- '
                # and can have parens in them
                $val =~ s/\(//g;
                $val =~ s/\)//g;
                $val =~ s/\s--\s/,/g;
                @these_tags = split(/,\s?/, $val);
            }
            else
            {
                @these_tags = split(/,\s*/, $val);
            }
            foreach my $t (@these_tags)
            {
                $t =~ s/ - / /g; # remove isolated dashes
                $t =~ s/[^\w\s,-]//g; # remove non-word characters
                push @tags, $t;
            }
        }
    }
    # Are there any tags?
    if (@tags)
    {
        # remove duplicates
        $meta{tags} = [uniq @tags];
    }
    else # remove empty tag-field
    {
        delete $meta{tags};
    }

    # There are SOOOOOO many fields in EXIF data, just remember a subset of them
    foreach my $field (qw(
Flash
ImageHeight
ImageSize
ImageWidth
Megapixels
PageCount
Location
Title
))
    {
        if (exists $info->{$field} and $info->{$field})
        {
            $meta{lc($field)} = $info->{$field};
        }
    }

    # -------------------------------------------------
    # Freeform Fields
    # These are stored as YAML data in the Instructions field.
    # They used to be stored in the XMP:Description field,
    # before then the ImageDescription field, before then the UserComment field
    # so they need to be checked too.
    # -------------------------------------------------
    if (exists $info->{Instructions}
            and $info->{Instructions}
            and $info->{Instructions} =~ /^---/)
    {
        say STDERR sprintf("Instructions='%s'", $info->{Instructions}) if $self->{verbose} > 2;
        my $data;
        eval {$data = Load($info->{Instructions});};
        if ($@)
        {
            warn __PACKAGE__, " Load of YAML data failed: $@";
        }
        elsif (!$data)
        {
            warn __PACKAGE__, " no legal YAML" if $self->{verbose} > 2;
        }
        else # okay
        {
            foreach my $field (sort keys %{$data})
            {
                $meta{$field} = $data->{$field};
            }
        }
    }
    elsif (exists $info->{Description}
            and $info->{Description}
            and $info->{Description} =~ /^---/)
    {
        say STDERR sprintf("Description='%s'", $info->{Description}) if $self->{verbose} > 2;
        my $data;
        eval {$data = Load($info->{Description});};
        if ($@)
        {
            warn __PACKAGE__, " Load of YAML data failed: $@";
        }
        elsif (!$data)
        {
            warn __PACKAGE__, " no legal YAML" if $self->{verbose} > 2;
        }
        else # okay
        {
            foreach my $field (sort keys %{$data})
            {
                $meta{$field} = $data->{$field};
            }
        }
    }
    elsif (exists $info->{ImageDescription}
            and $info->{ImageDescription}
            and $info->{ImageDescription} =~ /^---/)
    {
        say STDERR sprintf("ImageDescription='%s'", $info->{ImageDescription}) if $self->{verbose} > 2;
        my $data;
        eval {$data = Load($info->{ImageDescription});};
        if ($@)
        {
            warn __PACKAGE__, " Load of YAML data failed: $@";
        }
        elsif (!$data)
        {
            warn __PACKAGE__, " no legal YAML" if $self->{verbose} > 2;
        }
        else # okay
        {
            foreach my $field (sort keys %{$data})
            {
                $meta{$field} = $data->{$field};
            }
        }
    }
    elsif (exists $info->{UserComment}
            and $info->{UserComment}
            and $info->{UserComment} =~ /^---/)
    {
        say STDERR sprintf("UserComment='%s'", $info->{UserComment}) if $self->{verbose} > 2;
        my $data;
        eval {$data = Load($info->{UserComment});};
        if ($@)
        {
            warn __PACKAGE__, " Load of YAML data failed: $@";
        }
        elsif (!$data)
        {
            warn __PACKAGE__, " no legal YAML" if $self->{verbose} > 2;
        }
        else # okay
        {
            foreach my $field (sort keys %{$data})
            {
                $meta{$field} = $data->{$field};
            }
        }
    }

    return \%meta;
} # read_meta

=head1 Helper Functions

Private interface.

=head2 replace_one_field

Overwrite the given field. This does no checking.

    $writer->replace_one_field(filename=>$filename,field=>$field,value=>$value);

=cut

sub replace_one_field {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " field=$args{field},value=$args{value}" if $self->{verbose} > 2;

    my $filename = $self->_get_the_real_file(filename=>$args{filename});
    my $field = $args{field};
    my $value = $args{value};

    my $ft = $self->{file_magic}->info_from_filename($filename);
    my $et = new Image::ExifTool;
    $et->Options(ListSep=>',',ListSplit=>',');
    $et->ExtractInfo($filename);

    my $success;
    if ($field eq 'creator')
    {
        $success = $et->SetNewValue('Creator', $value);
    }
    elsif ($field eq 'copyright')
    {
        $success = $et->SetNewValue('License', $value);
    }
    elsif ($field eq 'title')
    {
        $success = $et->SetNewValue('Title', $value);
    }
    elsif ($field eq 'location')
    {
        $success = $et->SetNewValue('Location', $value);
    }
    elsif ($field eq 'create_date')
    {
        $success = $et->SetNewValue('CreateDate', $value);
    }
    elsif ($field eq 'alt_text')
    {
        $success = $et->SetNewValue('AltTextAccessibility', $value);
    }
    elsif ($field eq 'description')
    {
        # Okay, here's the messy relationship between the description,
        # the freeform data, and GIMP.
        #
        # I originally wrote the freeform data in the UserComment field, and
        # the description into the Description and Comment fields, then I found
        # that GIMP uses the UserComment field as the description field at a
        # higher priority than the Comment field.
        #
        # So then I wrote the freeform data in the ImageDescription field,
        # then I found that GIMP ALSO uses THAT field as the description field
        # at a higher priority than the Comment field.
        #
        # And that GIMP overwrites ALL THREE fields (Comment, UserComment, 
        # ImageDescription) with what it considers the description
        # when saving a file.
        #
        # So then I used the XMP:Description (Description) field for the
        # freeform data, because GIMP neither reads nor overwrites that.
        # But other things do...
        # 
        # So now I use the Instructions field.

        # Before the decription is written, the freeform data
        # needs to be converted to its new home.
        $self->_convert_freeform_data(exif=>$et);

        # GIMP reads and overwrites the Comment, UserComment
        # and ImageDescription fields, so we need to do that too.
        # Escpecially since GIMP does not look at the Comment field
        # if one of the other two is not empty.
        $success = $et->SetNewValue('UserComment', $value);
        $success = $et->SetNewValue('ImageDescription', $value);
        
        if ($ft->{mime_type} =~ /image\/jpeg/)
        {
            $success = $et->SetNewValue('Comment', $value);
        }
    }
    elsif ($field eq 'tags')
    {
        if (ref $value eq 'ARRAY')
        {
            $success = $et->SetNewValue('Keywords', $value);
            $success = $et->SetNewValue('Subject', $value);
        }
        else
        {
            my @tags = split(/,/,$value);
            $success = $et->SetNewValue('Keywords', \@tags);
            $success = $et->SetNewValue('Subject', \@tags);
        }
    }
    else # freeform field
    {
        # Need to read all the YAML, change this field, and write it again
        my $fdata = $self->_read_freeform_data(exif=>$et);
        $fdata->{$field} = $value;
        $success = $self->_write_freeform_data(newdata=>$fdata,exif=>$et);
    }

    if ($success)
    {
        $et->WriteInfo($filename);
    }
    return $success;
} # replace_one_field

=head2 delete_field_from_file

Completely remove the given field. This does no checking.

    $writer->delete_field_from_file(filename=>$filename,field=>$field);

=cut

sub delete_field_from_file {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " field=$args{field}" if $self->{verbose} > 2;

    my $filename = $self->_get_the_real_file(filename=>$args{filename});
    my $field = $args{field};

    my $ft = $self->{file_magic}->info_from_filename($filename);
    my $et = new Image::ExifTool;
    $et->Options(ListSep=>',',ListSplit=>',');
    $et->ExtractInfo($filename);

    my $success;
    if ($field eq 'creator')
    {
        $success = $et->SetNewValue('Creator')
    }
    elsif ($field eq 'title')
    {
        $success = $et->SetNewValue('Title')
    }
    elsif ($field eq 'description')
    {
        # GIMP reads and overwrites the Comment, UserComment
        # and ImageDescription fields, so we need to do that too.
        if ($ft->{mime_type} =~ /image\/jpeg/)
        {
            $success = $et->SetNewValue('Comment');
        }
        $success = $et->SetNewValue('ImageDescription');
        $success = $et->SetNewValue('UserComment');
    }
    elsif ($field eq 'tags')
    {
        $success = $et->SetNewValue('Keywords');
        $success = $et->SetNewValue('Subject');
    }
    else # freeform field
    {
        # Need to read all the YAML, change this field, and write it again
        my $fdata = $self->_read_freeform_data(exif=>$et);
        if (exists $fdata->{$field})
        {
            delete $fdata->{$field};
            $success = $self->_write_freeform_data(newdata=>$fdata,exif=>$et);
        }
    }

    if ($success)
    {
        $et->WriteInfo($filename);
    }
    return $success;
} # delete_field_from_file

=head2 _get_the_real_file

If the file is a directory, look for a cover file.
If the file is a soft link, look for the file it is pointing to
(because ExifTool behaves badly with soft links).

    my $real_file = $scribe->_get_the_real_file(filename=>$filename);

=cut

sub _get_the_real_file {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    if (-d $filename) # is a directory, look for a cover file
    {
        my $cover_file = ($self->{cover_file} ? $self->{cover_file} : 'cover.jpg');
        $cover_file = File::Spec->catfile($filename, $cover_file);
        if (-f $cover_file)
        {
            $filename = $cover_file;
        }
        else # give up and die
        {
            croak "$args{filename} is directory, cannot find $cover_file";
        }
    }

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

=head2 _read_freeform_data

Read the freeform data as YAML data from the Instructions field.
 
    my $ydata = $self->_read_freeform_data(exif=>$exif);

=cut

sub _read_freeform_data {
    my $self = shift;
    my %args = @_;
    say STDERR whoami() if $self->{verbose} > 2;

    # CONVERT FREEFORM DATA if needed BEFOREHAND
    $self->_convert_freeform_data(%args);

    my $ydata;
    my $et = $args{exif};
    my $ystring = $et->GetValue('Instructions');
    $ystring = $et->GetNewValue('Instructions') if !$ystring;
    say STDERR "ystring=$ystring" if $self->{verbose} > 2;
    if ($ystring and $ystring =~ /^---/) # YAML data needs prefix
    {
        eval {$ydata = Load($ystring);};
        if ($@)
        {
            warn __PACKAGE__, " Load of YAML data failed: $@ // '$ystring'";
        }
        elsif (!$ydata)
        {
            warn __PACKAGE__, " no legal YAML" if $self->{verbose} > 1;
        }
    }
    say STDERR Dump($ydata) if $self->{verbose} > 2;
    return $ydata;
} # _read_freeform_data

=head2 _write_freeform_data

Write the freeform data as YAML data into the Instructions field
This overwrites whatever is there, it does not check.
    
    $self->_write_freeform_data(newdata=>\%newdata,exif=>$exif);

=cut

sub _write_freeform_data {
    my $self = shift;
    my %args = @_;
    say STDERR whoami() if $self->{verbose} > 2;

    my $newdata = $args{newdata};
    my $et = $args{exif};
    # restore multi-value comma-separated fields to arrays
    foreach my $fn (keys %{$self->{wanted_fields}})
    {
        if ($self->{wanted_fields}->{$fn} eq 'MULTI'
                and exists $newdata->{$fn}
                and defined $newdata->{$fn}
                and $newdata->{$fn} =~ /,/)
        {
            my @vals = split(/,/, $newdata->{$fn});
            $newdata->{$fn} = \@vals;
        }
    }
    my $ystring = Dump($newdata);
    say STDERR "ystring=$ystring" if $self->{verbose} > 2;
    my $success = $et->SetNewValue('Instructions', $ystring);
    return $success;
} # _write_freeform_data

=head2 _convert_freeform_data

Convert the freeform data so that it is placed into the Instructions
field rather than the XMP:Description, UserComment or ImageDescription field.
 
    $self->_convert_freeform_data(exif=>$exif);

=cut

sub _convert_freeform_data {
    my $self = shift;
    my %args = @_;
    say STDERR whoami() if $self->{verbose} > 2;

    my $et = $args{exif};
    # Check if it needs conversion at all.
    # If the Instructions field is not empty
    # and contains YAML data, then nothing needs to be done.
    my $ystring = $et->GetValue('Instructions');
    $ystring = $et->GetNewValue('Instructions') if !$ystring;
    if ($ystring and $ystring =~ /^---/) # Assume YAML data
    {
        # no conversion needed
        return 1;
    }

    # ------------------------------------
    # Conversion needed
    # Read from XMP:Description, write into Instructions
    # Otherwise read from ImageDescription. 
    # The YAML data might be in UserComment instead if old.
    # ------------------------------------
    $ystring = $et->GetValue('Description');
    $ystring = $et->GetNewValue('Description') if !$ystring;
    if (!$ystring or $ystring !~ /^---/) # Try ImageDescription
    {
        $ystring = $et->GetValue('ImageDescription');
        $ystring = $et->GetNewValue('ImageDescription') if !$ystring;
    }
    if (!$ystring or $ystring !~ /^---/) # Try UserComment
    {
        $ystring = $et->GetValue('UserComment');
        $ystring = $et->GetNewValue('UserComment') if !$ystring;
    }

    my $ydata;
    my $success = 0;
    if ($ystring and $ystring =~ /^---/) # Probably YAML data
    {
        # Check if the YAML data is valid
        eval {$ydata = Load($ystring);};
        if ($@)
        {
            warn __PACKAGE__, " Load of YAML data failed: $@ ## '$ystring'";
        }
        elsif (!$ydata)
        {
            warn __PACKAGE__, " no legal YAML" if $self->{verbose} > 1;
        }
        else # data is okay
        {
            $success = $et->SetNewValue('Instructions', $ystring);
            if ($success)
            {
                # Clear out the XMP:Description field
                $et->SetNewValue('XMP:Description');

                # Put the description, if there is one,
                # into the UserComment, ImageDescription
                my $desc = $et->GetValue('Comment');
                $desc = $et->GetNewValue('Comment') if !$desc;
                $desc = $et->GetValue('Caption-Abstract') if !$desc;
                if ($desc)
                {
                    $et->SetNewValue('UserComment', $desc);
                    $et->SetNewValue('ImageDescription', $desc);
                }
                else
                {
                    # Otherwise clear out no longer valid data
                    $et->SetNewValue('ImageDescription');
                    $et->SetNewValue('UserComment');
                }
            }
        }
    }
    else # No YAML data to convert
    {
        # Put some empty data in there.
        my %newdata = ();
        my $nystring = Dump(\%newdata);
        $success = $et->SetNewValue('Instructions', $nystring);
    }

    return $success;
} # _convert_freeform_data

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Scribe
__END__
