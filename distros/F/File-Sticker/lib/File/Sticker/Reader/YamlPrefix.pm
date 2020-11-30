package File::Sticker::Reader::YamlPrefix;
$File::Sticker::Reader::YamlPrefix::VERSION = '1.0603';
=head1 NAME

File::Sticker::Reader::YamlPrefix - read and standardize meta-data from YAML-prefixed text file

=head1 VERSION

version 1.0603

=head1 SYNOPSIS

    use File::Sticker::Reader::YamlPrefix;

    my $obj = File::Sticker::Reader::YamlPrefix->new(%args);

    my %meta = $obj->read_meta($filename);

=head1 DESCRIPTION

This will read meta-data from plain text files where the first part of the file
contains YAML data, set up as if it is a YAML stream. That is, the file starts
with '---' on one line, then there is YAML data, then there is another '---'
line, and all content after that is ignored.  Then it will standardize it to a
common nomenclature, such as "tags" for things called tags, or Keywords or
Subject etc.

This format can be useful as a way of storing meta-data in documents or in
wiki pages.

=cut

use common::sense;
use File::LibMagic;
use YAML::Any;

use parent qw(File::Sticker::Reader);

# FOR DEBUGGING
=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 priority

The priority of this reader.  Readers with higher priority get tried first.

=cut

sub priority {
    my $class = shift;
    return 1;
} # priority

=head2 allowed_file

If this reader can be used for the given file, then this returns true.
File must be plain text and NOT end with '.yml'

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
        # Now we actually have to check if the file begins with '---'
        return $self->_has_yaml($file);
    }
    return 0;
} # allowed_file

=head2 known_fields

Returns the fields which this reader knows about.
This reader has no limitations.

    my $known_fields = $reader->known_fields();

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

    my $yaml_str = $self->_get_yaml_part($filename);
    my %meta = ();
    my $info;
    eval {$info = Load($yaml_str);};
    if ($@)
    {
        warn __PACKAGE__, " Load of data failed: $@";
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
    return \%meta;
} # read_meta

=head1 Private Helper Functions

Private interface, just this file

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

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Reader
__END__
