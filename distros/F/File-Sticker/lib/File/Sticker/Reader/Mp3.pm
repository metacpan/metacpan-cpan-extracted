package File::Sticker::Reader::Mp3;
$File::Sticker::Reader::Mp3::VERSION = '3.0204';
=head1 NAME

File::Sticker::Reader::Mp3 - read and standardize meta-data from MP3 file

=head1 VERSION

version 3.0204

=head1 SYNOPSIS

    use File::Sticker::Reader::Mp3;

    my $obj = File::Sticker::Reader::Mp3->new(%args);

    my %meta = $obj->read_meta($filename);

=head1 DESCRIPTION

This will read meta-data from MP3 files, and standardize it to a common
nomenclature, such as "tags" for things called tags, or Keywords or Subject etc.

=cut

use common::sense;
use File::LibMagic;
use MP3::Tag;

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
File must be an MP3 file.

=cut

sub allowed_file {
    my $self = shift;
    my $file = shift;
    say STDERR whoami(), " file=$file" if $self->{verbose} > 2;

    my $ft = $self->{file_magic}->info_from_filename($file);
    if ($ft->{mime_type} eq 'audio/mpeg')
    {
        say STDERR 'Reader ' . $self->name() . ' allows filetype ' . $ft->{mime_type} . ' of ' . $file if $self->{verbose} > 1;
        return 1;
    }
    return 0;
} # allowed_file

=head2 known_fields

Returns the fields which this reader knows about.
This writer has no limitations.

    my $known_fields = $reader->known_fields();

=cut

sub known_fields {
    my $self = shift;

    return {
        title=>'TEXT',
        creator=>'TEXT',
        author=>'TEXT',
        description=>'TEXT',
        song=>'TEXT',
        genre=>'TEXT',
        url=>'TEXT',
        year=>'NUMBER',
        track=>'NUMBER',
        tags=>'MULTI',
        %{$self->{wanted_fields}}
        };
} # known_fields

=head2 read_meta

Read the meta-data from the given file.

    my $meta = $obj->read_meta($filename);

=cut

sub read_meta {
    my $self = shift;
    my $filename = shift;
    say STDERR whoami(), " filename=$filename" if $self->{verbose} > 2;

    my $mp3 = MP3::Tag->new($filename);
    my %meta = ();

    my $known_fields = $self->known_fields();
    foreach my $field (sort keys %{$known_fields})
    {
        if ($field eq 'title')
        {
            $meta{'title'} = $mp3->album();
        }
        elsif ($field eq 'song')
        {
            $meta{'song'} = $mp3->title();
        }
        elsif ($field eq 'description')
        {
            $meta{'description'} = $mp3->comment();
            if (!$meta{description}) # try the COMM field
            {
                $meta{$field} = $mp3->select_id3v2_frame_by_descr('COMM');
            }
        }
        elsif ($field eq 'creator')
        {
            $meta{'creator'} = $mp3->artist();
        }
        elsif ($field eq 'genre')
        {
            $meta{'genre'} = $mp3->genre();
        }
        elsif ($field eq 'year')
        {
            $meta{'year'} = $mp3->year();
        }
        elsif ($field eq 'track')
        {
            $meta{'track'} = $mp3->track();
        }
        elsif ($field eq 'author')
        {
            # author (as distinct from artist) use the 'composer' field
            $meta{'author'} = $mp3->composer();
        }
        elsif ($field eq 'url')
        {
            # get url
            # official audio file webpage
            my $value = $mp3->select_id3v2_frame_by_descr('WOAF');
            $meta{url} = $value if $value;
            # official audio source webpage
            $value = $mp3->select_id3v2_frame_by_descr('WOAS');
            $meta{url} = $value if !$meta{url} and $value;
        }
        else # freeform text fields
        {
            if ($mp3->have_id3v2_frame('TXXX', [$field]))
            {
                my $tagframe = $mp3->select_id3v2_frame('TXXX', [$field], undef);
                $meta{$field} = $tagframe;
            }
        }
        # Delete any fields that are undefined
        delete $meta{$field} if !defined $meta{$field};
    }

    return \%meta;
} # read_meta

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Reader
__END__
