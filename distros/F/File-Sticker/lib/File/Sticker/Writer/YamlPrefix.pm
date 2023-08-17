package File::Sticker::Writer::YamlPrefix;
$File::Sticker::Writer::YamlPrefix::VERSION = '3.0101';
=head1 NAME

File::Sticker::Writer::YamlPrefix - write and standardize meta-data from YAML file

=head1 VERSION

version 3.0101

=head1 SYNOPSIS

    use File::Sticker::Writer::YamlPrefix;

    my $obj = File::Sticker::Writer::YamlPrefix->new(%args);

    my %meta = $obj->write_meta(%args);

=head1 DESCRIPTION

This will write meta-data to text files as a YAML prefix to the file.
This will standardize it to a common nomenclature, such as "tags" for things
called tags, or Keywords or Subject etc.

=cut

use common::sense;
use File::LibMagic;
use YAML::Any;

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
    return 1;
} # priority

=head2 allowed_file

If this writer can be used for the given file, then this returns true.
File must be plain text and NOT end with '.yml'
If the file does not exist, it cannot be written to.
If it does exist, the YAML-prefix area must exist also.

=cut

sub allowed_file {
    my $self = shift;
    my $file = shift;
    say STDERR whoami(), " file=$file" if $self->{verbose} > 2;

    my $ft = $self->{file_magic}->info_from_filename($file);
    # This needs to be a plain text file
    # We don't want to include .yml files because they are dealt with separately
    if (-r $file
            and $ft->{mime_type} =~ m{^text/plain}
            and $file !~ /\.yml$/)
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

    my $info = $self->_load_meta($filename);
    delete $info->{$field};
    $self->_write_meta(filename=>$filename,meta=>$info);
    
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

    $self->_write_meta(filename=>$filename,meta=>$meta);
    
} # replace_all_meta

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

    my $info = $self->_load_meta($filename);
    $info->{$field} = $value;
    $self->_write_meta(filename=>$filename,meta=>$info);
} # replace_one_field

=head1 Helper Functions

Private interface.

=head2 _has_yaml

The file has YAML if the FIRST line is '---'

=cut
sub _has_yaml {
    my $self = shift;
    my $filename = shift;

    my $fh;
    if (!open($fh, '<', $filename))
    {
        die __PACKAGE__, " Unable to open file '" . $filename ."': $!\n";
    }

    my $first_line = <$fh>;
    close($fh);
    return 0 if !$first_line;

    chomp $first_line;
    return ($first_line eq '---');
} # _has_yaml

=head2 _load_meta

Quick non-checking loading of the meta-data. Does not standardize any fields.

=cut
sub _load_meta {
    my $self = shift;
    my $filename = shift;
    say STDERR whoami(), " filename=$filename" if $self->{verbose} > 2;

    my $yaml_str = $self->_get_yaml_part($filename);
    my $meta;
    eval {$meta = Load($yaml_str);};
    if ($@)
    {
        warn __PACKAGE__, " Load of data failed: $@";
        return {};
    }
    if (!$meta)
    {
        warn __PACKAGE__, " no legal YAML";
        return {};
    }
    return $meta;
} # _load_meta

=head2 _write_meta

Overwrites the file completely with the given metadata
plus the rest of its contents
This saves multi-value comma-separated fields as arrays.

=cut
sub _write_meta {
    my $self = shift;
    my %args = @_;

    my $filename = $args{filename};
    my $meta = $args{meta};
    # restore multi-value comma-separated fields to arrays
    foreach my $fn (keys %{$self->{wanted_fields}})
    {
        if ($self->{wanted_fields}->{$fn} eq 'MULTI'
                and exists $meta->{$fn}
                and defined $meta->{$fn}
                and $meta->{$fn} =~ /,/)
        {
            my @vals = split(/,/, $meta->{$fn});
            $meta->{$fn} = \@vals;
        }
    }

    my $file_rest = $self->_get_rest_of_file($filename);
    my $fh;
    if (!open($fh, '>', $filename))
    {
        die __PACKAGE__, " Unable to open file '" . $filename ."': $!\n";
    }
    print $fh Dump($meta);
    print $fh "---\n";
    print $fh $file_rest;
    close $fh;
} # _write_meta

=head2 _get_yaml_part

Get the YAML part of the file (if any)
by reading the stuff between the first set of --- lines

=cut
sub _get_yaml_part {
    my $self = shift;
    my $filename = shift;
    say STDERR whoami(), " filename=$filename" if $self->{verbose} > 2;

    my $fh;
    if (!open($fh, '<', $filename))
    {
        die __PACKAGE__, " Unable to open file '" . $filename ."': $!\n";
    }

    my $yaml_str = '';
    my $yaml_started = 0;
    while (<$fh>) {
        if (/^---$/) {
            if (!$yaml_started)
            {
                $yaml_started = 1;
                next;
            }
            else # end of the yaml part
            {
                last;
            }
        }
        if ($yaml_started)
        {
            $yaml_str .= $_;
        }
    }
    close($fh);
    return $yaml_str;
} # _get_yaml_part

=head2 _get_rest_of_file

Get the stuff after the YAML prefix.

=cut
sub _get_rest_of_file {
    my $self = shift;
    my $filename = shift;
    say STDERR whoami(), " filename=$filename" if $self->{verbose} > 2;

    my $fh;
    if (!$self->_has_yaml($filename))
    {
        # read the whole file
        my $fn = $filename;
        open $fh, '<:encoding(UTF-8)', $fn or die "couldn't open $fn: $!";

        # slurp
        return do { local $/; <$fh> };
    }

    if (!open($fh, '<', $filename))
    {
        die __PACKAGE__, " Unable to open file '" . $filename ."': $!\n";
    }

    my $content = '';
    my $yaml_started = 0;
    my $content_started = 0;
    while (<$fh>) {
        if (/^---$/) {
            if (!$yaml_started)
            {
                $yaml_started = 1;
            }
            else # end of the yaml part
            {
                $content_started = 1;
            }
            next;
        }
        if ($content_started)
        {
            $content .= $_;
        }
    }
    close($fh);
    return $content;
} # _get_rest_of_file

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Writer
__END__
