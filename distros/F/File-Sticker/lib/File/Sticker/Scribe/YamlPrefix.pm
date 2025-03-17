package File::Sticker::Scribe::YamlPrefix;
$File::Sticker::Scribe::YamlPrefix::VERSION = '4.01';
=head1 NAME

File::Sticker::Scribe::YamlPrefix - write and standardize meta-data from YAML file

=head1 VERSION

version 4.01

=head1 SYNOPSIS

    use File::Sticker::Scribe::YamlPrefix;

    my $obj = File::Sticker::Scribe::YamlPrefix->new(%args);

    my %meta = $obj->read_meta($filename);

    $obj->write_meta(%args);

=head1 DESCRIPTION

This will read and write meta-data from plain text files where the first part
of the file contains YAML data, set up as if it is a YAML stream. That is, the
file starts with '---' on one line, then there is YAML data, then there is
another '---' line, and all content after that is ignored.  Then it will
standardize it to a common nomenclature, such as "tags" for things called tags,
or Keywords or Subject etc.

This format can be useful as a way of storing meta-data in documents or in
wiki pages.

=cut

use common::sense;
use File::LibMagic;
use YAML::Any;

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
    return 1;
} # priority

=head2 allowed_file

If this scribe can be used for the given file, then this returns true.
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

    my ($yaml_str,$more) = $self->_yaml_and_more($filename);
    my %meta = ();
    my $info;
    eval {$info = Load($yaml_str);};
    if ($@)
    {
        warn __PACKAGE__, " Load of data failed: $@";
        say "======\n$yaml_str\n=====" if $self->{verbose} > 1;
        return \%meta;
    }
    if (!$info)
    {
        warn __PACKAGE__, " no legal YAML";
        return \%meta;
    }
    # now standardize the meta-data
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

    # Check for wiki-specific meta-data in the "more" part
    if ($more =~ m/\[\[\!meta title="([^"]+)"\]\]/)
    {
        $meta{title} = $1 if !$meta{title};
        $more =~ s/\[\[\!meta title="([^"]+)"\]\]//;
    }
    if ($more =~ m/\[\[\!meta description="([^"]+)"\]\]/)
    {
        $meta{description} = $1 if !$meta{description};
        $more =~ s/\[\[\!meta description="([^"]+)"\]\]//;
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

    my $info = $self->_load_meta($filename);
    delete $info->{$field};
    $self->_write_meta(filename=>$filename,meta=>$info);
    
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

    $self->_write_meta(filename=>$filename,meta=>$meta);
    
} # replace_all_meta

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

=head2 _yaml_and_more

Get the YAML part of the file (if any)
by reading the stuff between the first set of --- lines
and also the rest of the file as a separate part.

=cut
sub _yaml_and_more {
    my $self = shift;
    my $filename = shift;
    say STDERR whoami(), " filename=$filename" if $self->{verbose} > 2;

    my $fh;
    if (!open($fh, '<', $filename))
    {
        die __PACKAGE__, " Unable to open file '" . $filename ."': $!\n";
    }

    my $yaml_str = '';
    my $more_str = '';
    my $yaml_started = 0;
    my $yaml_finished = 0;
    while (<$fh>) {
        if (/^---$/) {
            # There could be "---" lines after the YAML is finished!
            if (!$yaml_started and !$yaml_finished)
            {
                $yaml_started = 1;
                next;
            }
            elsif (!$yaml_finished) # end of the YAML part
            {
                $yaml_started = 0;
                $yaml_finished = 1;
                next;
            }
        }
        if ($yaml_started)
        {
            $yaml_str .= $_;
        }
        elsif ($yaml_finished)
        {
            $more_str .= $_;
        }
    }
    close($fh);
    return ($yaml_str,$more_str);
} # _yaml_and_more

=head2 _load_meta

Quick non-checking loading of the meta-data. Does not standardize any fields.

=cut
sub _load_meta {
    my $self = shift;
    my $filename = shift;
    say STDERR whoami(), " filename=$filename" if $self->{verbose} > 2;

    my ($yaml_str,$more) = $self->_yaml_and_more($filename);
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

    my ($yaml_str,$file_rest) = $self->_yaml_and_more($filename);
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

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Scribe
__END__
