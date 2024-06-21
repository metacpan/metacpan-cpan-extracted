package File::Sticker::Writer::Yaml;
$File::Sticker::Writer::Yaml::VERSION = '3.0204';
=head1 NAME

File::Sticker::Writer::Yaml - write and standardize meta-data from YAML file

=head1 VERSION

version 3.0204

=head1 SYNOPSIS

    use File::Sticker::Writer::Yaml;

    my $obj = File::Sticker::Writer::Yaml->new(%args);

    my %meta = $obj->write_meta(%args);

=head1 DESCRIPTION

This will write meta-data from YAML files, and standardize it to a common
nomenclature, such as "tags" for things called tags, or Keywords or Subject etc.

=cut

use common::sense;
use File::LibMagic;
use YAML::Any qw(Dump LoadFile DumpFile);

use parent qw(File::Sticker::Writer);

# FOR DEBUGGING
=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 priority

The priority of this writer.  Writers with higher priority get tried first.

=cut

sub priority {
    my $class = shift;
    return 2;
} # priority

=head2 allowed_file

If this writer can be used for the given file, then this returns true.
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

If this writer can be used for the known and wanted fields, then this returns true.
For YAML, this always returns true.

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
This does no checking for multi-valued fields, it just deletes the whole thing.

    $writer->delete_field_from_file(filename=>$filename,field=>$field);

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

    $writer->replace_all_meta(filename=>$filename,meta=>\%meta);

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

    $writer->replace_one_field(filename=>$filename,field=>$field,value=>$value);

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

1; # End of File::Sticker::Writer
__END__
