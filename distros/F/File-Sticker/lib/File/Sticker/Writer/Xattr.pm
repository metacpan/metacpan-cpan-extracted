package File::Sticker::Writer::Xattr;
$File::Sticker::Writer::Xattr::VERSION = '1.01';
=head1 NAME

File::Sticker::Writer::Xattr - write and standardize meta-data from ExtAttr file

=head1 VERSION

version 1.01

=head1 SYNOPSIS

    use File::Sticker::Writer::Xattr;

    my $obj = File::Sticker::Writer::Xattr->new(%args);

    my %meta = $obj->write_meta(%args);

=head1 DESCRIPTION

This will write meta-data from extended user attributes of files, and standardize it to a common
nomenclature, such as "tags" for things called tags, or Keywords or Subject etc.

=cut

use common::sense;
use File::LibMagic;
use File::ExtAttr ':all';
use File::Basename;

use parent qw(File::Sticker::Writer);

# FOR DEBUGGING
=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 is_fallback

Is this writer a fallback writer (to be used when others don't work)?
This is mainly to prevent Xattr attributes being set when they don't need to be,
because we don't want duplicate information stored in two different ways.

=cut

sub is_fallback {
    my $self = shift;
    
    return 1;
} # is_fallback

=head2 allowed_file

If this writer can be used for the given file, then this returns true.
This can be used with any file, if the filesystem supports extended attributes.
I don't know how to test for that, so I'll just assume "yes".

=cut

sub allowed_file {
    my $self = shift;
    my $file = shift;
    say STDERR whoami(), " file=$file" if $self->{verbose} > 2;

    if (-f $file)
    {
        return 1;
    }
    return 0;
} # allowed_file

=head2 allowed_fields

If this writer can be used for the known and wanted fields, then this returns true.
For Xattr, this always returns true.

    if ($writer->allowed_fields())
    {
	....
    }

=cut

sub allowed_fields {
    my $self = shift;

    return 1;
} # allowed_fields

=head2 known_fields

Returns the fields which this writer knows about.
This writer has no limitations.

    my $known_fields = $writer->known_fields();

=cut

sub known_fields {
    my $self = shift;

    if ($self->{wanted_fields})
    {
        return $self->{wanted_fields};
    }
    return {};
} # known_fields

=head2 readonly_fields

Returns the fields which this writer knows about, which can't be overwritten,
but are allowed to be "wanted" fields. Things like file-size etc.

    my $readonly_fields = $writer->readonly_fields();

=cut

sub readonly_fields {
    my $self = shift;

    return {filesize=>'NUMBER'};
} # readonly_fields

=head2 delete_field_from_file

Completely remove the given field.
For multi-value fields, it removes ALL the values.

    $writer->delete_field_from_file(filename=>$filename,field=>$field);

=cut

sub delete_field_from_file {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $field = $args{field};

    if (-w $filename)
    {
        if ($field eq 'url')
        {
            delfattr($filename, 'dublincore.source');
        }
        elsif ($field eq 'title')
        {
            delfattr($filename, 'dublincore.title');
        }
        elsif ($field eq 'alt_title')
        {
            delfattr($filename, 'dublincore.alternative');
        }
        elsif ($field eq 'creator')
        {
            delfattr($filename, 'dublincore.creator');
        }
        elsif ($field eq 'description')
        {
            delfattr($filename, 'dublincore.description');
        }
        else
        {
            delfattr($filename, $field);
        }
    }
} # delete_field_from_file

=head2 replace_all_meta

Overwrite the existing meta-data with that given.

(This supercedes the parent method because we can do it more efficiently this way)

    $writer->replace_all_meta(filename=>$filename,meta=>\%meta);

=cut

sub replace_all_meta {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $meta = $args{meta};

    # write all the meta
    foreach my $field (sort keys %{$meta})
    {
        if (exists $meta->{$field}
                and defined $meta->{$field})
        {
            $self->replace_one_field(filename=>$filename,
                field=>$field,
                value=>$meta->{$field});
        }
        else # not defined, remove it
        {
            $self->delete_field_from_file(filename=>$filename,field=>$field);
        }
    }
    # delete the stuff that isn't in the replacement data
    foreach my $key (listfattr($filename))
    {
        if ($key eq 'dublincore.source')
        {
            if (!exists $meta->{url})
            {
                delfattr($filename, $key);
            }
        }
        elsif ($key eq 'dublincore.creator')
        {
            if (!exists $meta->{creator})
            {
                delfattr($filename, $key);
            }
        }
        elsif ($key eq 'dublincore.title')
        {
            if (!exists $meta->{title})
            {
                delfattr($filename, $key);
            }
        }
        elsif ($key eq 'dublincore.alternative')
        {
            if (!exists $meta->{alt_title})
            {
                delfattr($filename, $key);
            }
        }
        elsif ($key eq 'dublincore.description')
        {
            if (!exists $meta->{description})
            {
                delfattr($filename, $key);
            }
        }
        elsif (!exists $meta->{$key})
        {
            delfattr($filename, $key);
        }

    }
} # replace_all_meta

=head1 Helper Functions

Private interface.

=cut

=head2 replace_one_field

Overwrite the given field.
This does no checking for multi-value fields.

    $writer->replace_one_field(filename=>$filename,field=>$field,value=>$value);

=cut

sub replace_one_field {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $field = $args{field};
    my $value = $args{value};
    say STDERR "field=$field value=$value" if $self->{verbose} > 2;

    if (-w $filename)
    {
        if ($field eq 'url')
        {
            setfattr($filename, 'dublincore.source', $value);
        }
        elsif ($field eq 'title')
        {
            setfattr($filename, 'dublincore.title', $value);
        }
        elsif ($field eq 'alt_title')
        {
            setfattr($filename, 'dublincore.alternative', $value);
        }
        elsif ($field eq 'creator')
        {
            setfattr($filename, 'dublincore.creator', $value);
        }
        elsif ($field eq 'description')
        {
            setfattr($filename, 'dublincore.description', $value);
        }
        else
        {
            if (ref $value eq 'ARRAY')
            {
                $value = join(',', @{$value});
            }
            setfattr($filename, $field, $value);
        }
    }
} # replace_one_field

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Writer
__END__
