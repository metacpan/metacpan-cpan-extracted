package File::Sticker::Scribe::Mp3;
$File::Sticker::Scribe::Mp3::VERSION = '4.0101';
=head1 NAME

File::Sticker::Scribe::Mp3 - read, write and standardize meta-data from MP3 file

=head1 VERSION

version 4.0101

=head1 SYNOPSIS

    use File::Sticker::Scribe::Mp3;

    my $obj = File::Sticker::Scribe::Mp3->new(%args);

    my %meta = $obj->write_meta(%args);

=head1 DESCRIPTION

This will write meta-data from MP3 files, and standardize it to a common
nomenclature, such as "tags" for things called tags, or Keywords or Subject etc.

=cut

use common::sense;
use File::LibMagic;
use MP3::Tag;

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
File must be an MP3 file.

=cut

sub allowed_file {
    my $self = shift;
    my $file = shift;
    say STDERR whoami(), " file=$file" if $self->{verbose} > 2;

    my $ft = $self->{file_magic}->info_from_filename($file);
    if ($ft->{mime_type} eq 'audio/mpeg')
    {
        say STDERR 'Scribe ' . $self->name() . ' allows filetype ' . $ft->{mime_type} . ' of ' . $file if $self->{verbose} > 1;
        return 1;
    }
    return 0;
} # allowed_file

=head2 allowed_fields

If this scribe can be used for the known and wanted fields, then this returns true.
For this scribe, this always returns true.

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

    my $known_fields = $scribe->known_fields();

=cut

sub known_fields {
    my $self = shift;

    return {
        title=>'TEXT',
        creator=>'TEXT',
        author=>'TEXT',
        composer=>'TEXT',
        performer=>'TEXT',
        description=>'TEXT',
        genre=>'TEXT',
        song=>'TEXT',
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
        elsif ($field eq 'composer')
        {
            $meta{'composer'} = $mp3->composer();
        }
        elsif ($field eq 'performer')
        {
            $meta{'performer'} = $mp3->performer();
        }
        elsif ($field eq 'author')
        {
            # author (as distinct from artist) use the 'composer' field
            # This is used for podfic, whereas composer is used for music.
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

=head1 Helper Functions

=cut

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

    my $mp3 = MP3::Tag->new($filename);
    $mp3->config(write_v24=>1);

    if ($field eq 'title')
    {
        $mp3->album_set($value);
    }
    elsif ($field eq 'song')
    {
        $mp3->title_set($value);
    }
    elsif ($field eq 'description')
    {
        $mp3->comment_set($value);
    }
    elsif ($field eq 'creator')
    {
        $mp3->artist_set($value);
    }
    elsif ($field eq 'genre')
    {
        $mp3->genre_set($value);
    }
    elsif ($field eq 'year')
    {
        $mp3->year_set($value);
    }
    elsif ($field eq 'track')
    {
        $mp3->track_set($value);
    }
    elsif ($field eq 'performer')
    {
        $mp3->select_id3v2_frame_by_descr('TPE1', $value);
    }
    elsif ($field eq 'composer')
    {
        $mp3->select_id3v2_frame_by_descr('TCOM', $value);
    }
    elsif ($field eq 'author')
    {
        # Use the 'composer' field
        # This is used for podfic, whereas composer is used for music.
        $mp3->select_id3v2_frame_by_descr('TCOM', $value);
    }
    elsif ($field eq 'url')
    {
        # official audio file webpage
        $mp3->select_id3v2_frame_by_descr('WOAF', $value);
    }
    else
    {
        my $newval = $value;
        if (ref $value eq 'ARRAY')
        {
            $newval = join(',', @{$value});
        }
        $mp3->select_id3v2_frame_by_descr("TXXX[${field}]", $newval);
    }
    $mp3->update_tags();
} # replace_one_field

=head2 delete_field_from_file

Remove the given field. This does no checking.
This doesn't completely remove it, merely sets it to the empty string.

    $scribe->delete_field_from_file(filename=>$filename,field=>$field);

=cut

sub delete_field_from_file {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $field = $args{field};

    my $mp3 = MP3::Tag->new($filename);
    $mp3->config(write_v24=>1);

    if ($field eq 'title')
    {
        $mp3->album_set('');
    }
    elsif ($field eq 'song')
    {
        $mp3->title_set('');
    }
    elsif ($field eq 'description')
    {
        $mp3->comment_set('');
    }
    elsif ($field eq 'creator')
    {
        $mp3->artist_set('');
    }
    elsif ($field eq 'performer')
    {
        $mp3->select_id3v2_frame_by_descr('TPE1', undef);
    }
    elsif ($field eq 'composer')
    {
        $mp3->select_id3v2_frame_by_descr('TCOM', undef);
    }
    elsif ($field eq 'author')
    {
        # use the 'composer' field
        $mp3->select_id3v2_frame_by_descr('TCOM', undef);
    }
    elsif ($field eq 'url')
    {
        # official audio file webpage
        $mp3->select_id3v2_frame_by_descr('WOAF', undef);
    }
    else
    {
        $mp3->select_id3v2_frame_by_descr("TXXX[${field}]", undef);
    }
    $mp3->update_tags();
} # delete_field_from_file

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Scribe
__END__
