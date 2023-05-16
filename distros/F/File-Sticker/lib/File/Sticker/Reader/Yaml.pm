package File::Sticker::Reader::Yaml;
$File::Sticker::Reader::Yaml::VERSION = '3.0006';
=head1 NAME

File::Sticker::Reader::Yaml - read and standardize meta-data from YAML file

=head1 VERSION

version 3.0006

=head1 SYNOPSIS

    use File::Sticker::Reader::Yaml;

    my $obj = File::Sticker::Reader::Yaml->new(%args);

    my %meta = $obj->read_meta($filename);

=head1 DESCRIPTION

This will read meta-data from YAML files, and standardize it to a common
nomenclature, such as "tags" for things called tags, or Keywords or Subject etc.

=cut

use common::sense;
use File::LibMagic;
use YAML::Any qw(Dump LoadFile);

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
    return 2;
} # priority

=head2 allowed_file

If this reader can be used for the given file, then this returns true.
File must be plain text and end with '.yml'

=cut

sub allowed_file {
    my $self = shift;
    my $file = shift;
    say STDERR whoami(), " file=$file" if $self->{verbose} > 2;

    my $ft = $self->{file_magic}->info_from_filename($file);
    # For some unfathomable reason, not every YAML file is recognised as text/plain
    # so just check for text
    if ($ft->{mime_type} =~ m{^text/}
            and $file =~ /\.yml$/)
    {
        say STDERR 'Reader ' . $self->name() . ' allows filetype ' . $ft->{mime_type} . ' of ' . $file if $self->{verbose} > 1;
        return 1;
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

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Reader
__END__
