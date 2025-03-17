package File::Sticker::Scribe::Xattr;
$File::Sticker::Scribe::Xattr::VERSION = '4.01';
=head1 NAME

File::Sticker::Scribe::Xattr - read, write and standardize meta-data from ExtAttr file

=head1 VERSION

version 4.01

=head1 SYNOPSIS

    use File::Sticker::Scribe::Xattr;

    my $obj = File::Sticker::Scribe::Xattr->new(%args);

    my %meta = $obj->read_meta($filename);

    $obj->write_meta(%args);

=head1 DESCRIPTION

This will read and write meta-data from extended user attributes of files, and standardize it to a common
nomenclature, such as "tags" for things called tags, or Keywords or Subject etc.

=cut

use common::sense;
use File::LibMagic;
use File::ExtAttr ':all';
use File::Basename;

use parent qw(File::Sticker::Scribe);

# FOR DEBUGGING
=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 priority

The priority of this scribe.  Scribes with higher priority get tried first.
Xattr is a low-priority scribe.

=cut

sub priority {
    my $class = shift;
    return 0;
} # priority

=head2 allowed_file

If this scribe can be used for the given file, then this returns true.
This can be used with any file, if the filesystem supports extended attributes.
I don't know how to test for that, so I'll just assume "yes".

=cut

sub allowed_file {
    my $self = shift;
    my $file = shift;
    say STDERR whoami(), " file=$file" if $self->{verbose} > 2;

    if (-r $file)
    {
        return 1;
    }
    return 0;
} # allowed_file

=head2 allowed_fields

If this scribe can be used for the known and wanted fields, then this returns true.
For Xattr, this always returns true.

    if ($scribe->allowed_fields())
    {
	....
    }

=cut

sub allowed_fields {
    my $self = shift;

    return 1;
} # allowed_fields

=head2 known_fields

Returns the fields which this scribe knows about.
This scribe has no limitations.

    my $known_fields = $scribe->known_fields();

=cut

sub known_fields {
    my $self = shift;

    if ($self->{wanted_fields})
    {
        return $self->{wanted_fields};
    }
    return {};
} # known_fields

=head2 read_meta

Read the meta-data from the given file.

    my $meta = $obj->read_meta($filename);

=cut

sub read_meta {
    my $self = shift;
    my $filename = shift;
    say STDERR whoami(), " filename=$filename" if $self->{verbose} > 2;

    my %meta = ();
    foreach my $key (listfattr($filename))
    {
        if ($key eq 'dublincore.source' or $key eq 'xdg.referrer.url')
        {
            $meta{url} = getfattr($filename, $key);
        }
        elsif ($key eq 'dublincore.creator')
        {
            $meta{creator} = getfattr($filename, $key);
        }
        elsif ($key eq 'dublincore.title')
        {
            $meta{title} = getfattr($filename, $key);
        }
        elsif ($key eq 'dublincore.alternative')
        {
            $meta{alt_title} = getfattr($filename, $key);
        }
        elsif ($key eq 'dublincore.description')
        {
            $meta{description} = getfattr($filename, $key);
        }
        else
        {
            $meta{$key} = getfattr($filename, $key);
        }
    }

    return \%meta;
} # read_meta

=head2 delete_field_from_file

Completely remove the given field.
For multi-value fields, it removes ALL the values.

    $scribe->delete_field_from_file(filename=>$filename,field=>$field);

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

=head1 Helper Functions

Private interface.

=cut

=head2 replace_one_field

Overwrite the given field.
This does no checking for multi-value fields.

    $scribe->replace_one_field(filename=>$filename,field=>$field,value=>$value);

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

1; # End of File::Sticker::Scribe
__END__
