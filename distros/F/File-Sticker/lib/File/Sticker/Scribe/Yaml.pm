package File::Sticker::Scribe::Yaml;
$File::Sticker::Scribe::Yaml::VERSION = '4.301';
=head1 NAME

File::Sticker::Scribe::Yaml - read, write and standardize meta-data from YAML file

=head1 VERSION

version 4.301

=head1 SYNOPSIS

    use File::Sticker::Scribe::Yaml;

    my $obj = File::Sticker::Scribe::Yaml->new(%args);

    my %meta = $obj->read_meta($filename);

    $obj->write_meta(%args);

=head1 DESCRIPTION

This will read and write meta-data from YAML files, and standardize it to a common
nomenclature, such as "tags" for things called tags, or Keywords or Subject etc.

=cut

use common::sense;
use File::LibMagic;
use YAML::Any qw(Dump LoadFile DumpFile);

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

=cut

sub priority {
    my $class = shift;
    return 2;
} # priority

=head2 allowed_file

If this scribe can be used for the given file, then this returns true.
File must be plain text and end with '.yml'
Howwever, if the file DOES NOT EXIST, it CAN be WRITTEN TO, so return true then as well.
This is the only case where the file doesn't need to exist beforehand.
Note that if the file exists and is a directory, then it is not an allowed file!
If the file exists and is empty, that's okay too.

=cut

sub allowed_file {
    my $self = shift;
    my $file = shift;
    say STDERR whoami(), " file=$file" if $self->{verbose} > 2;

    if ($file !~ /\.yml$/)
    {
        say STDERR "$file does not end with .yml" if $self->{verbose} > 2;
        return 0;
    }
    if (-d $file)
    {
        return 0;
    }
    if (! -r $file)
    {
        say STDERR "$file does not exist, but that's okay" if $self->{verbose} > 2;
        return 1;
    }
    # Perhaps the file exists and is empty
    if (-z $file)
    {
        say STDERR "$file is empty, but that's okay" if $self->{verbose} > 2;
        return 1;
    }

    my $ft = $self->{file_magic}->info_from_filename($file);
    # For some unfathomable reason, not every YAML file is recognised as text/plain
    # so just check for text
    if ($ft->{mime_type} =~ m{^text/})
    {
        return 1;
    }
    return 0;
} # allowed_file

=head2 allowed_fields

If this scribe can be used for the known and wanted fields, then this returns true.
For YAML, this always returns true.

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

    my ($info) = LoadFile($filename);
    my %meta = ();
    foreach my $key (sort keys %{$info})
    {
        my $val = $info->{$key};
        if ($val)
        {
            if ($key eq 'tags')
            {
                $meta{tags} = $val;
                # If there are no commas, change spaces to commas.  This is
                # because if we are using commas to separate, we allow
                # multi-word tags with spaces in them, so we don't want to turn
                # those spaces into commas!
                if ($meta{tags} !~ /,/)
                {
                    $meta{tags} =~ s/ /,/g; # spaces to commas
                }
            }
            elsif ($key eq 'dublincore.source')
            {
                $meta{'url'} = $val;
            }
            elsif ($key eq 'dublincore.title')
            {
                $meta{'title'} = $val;
            }
            elsif ($key eq 'dublincore.creator')
            {
                $meta{'creator'} = $val;
            }
            elsif ($key eq 'dublincore.description')
            {
                $meta{'description'} = $val;
            }
            elsif ($key eq 'private')
            {
                # deal with this after tags
            }
            else
            {
                $meta{$key} = $val;
            }
        }
    }
    if ($info->{private})
    {
        $meta{tags} .= ",private";
    }
    return \%meta;
} # read_meta

=head2 delete_field_from_file

Completely remove the given field.
This does no checking for multi-valued fields, it just deletes the whole thing.

    $scribe->delete_field_from_file(filename=>$filename,field=>$field);

=cut

sub delete_field_from_file {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $field = $args{field};

    my ($info) = LoadFile($filename);
    delete $info->{$field};
    DumpFile($filename, $info);
} # delete_field_from_file

=head2 replace_all_meta

Overwrite the existing meta-data with that given.

(This supercedes the parent method because we can do it more efficiently this way)

    $scribe->replace_all_meta(filename=>$filename,meta=>\%meta);

=cut

sub replace_all_meta {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $meta = $args{meta};

    DumpFile($filename, $meta);
} # replace_all_meta

=head1 Helper Functions

Private interface.

=head2 replace_one_field

Overwrite the given field. This does no checking.

    $scribe->replace_one_field(filename=>$filename,field=>$field,value=>$value);

=cut

sub replace_one_field {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $field = $args{field};
    my $value = $args{value};

    my ($info) = LoadFile($filename);
    $info->{$field} = $value;
    DumpFile($filename, $info);
} # replace_one_field

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Scribe
__END__
