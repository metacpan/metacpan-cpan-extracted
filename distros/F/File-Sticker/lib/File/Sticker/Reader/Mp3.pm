package File::Sticker::Reader::Mp3;
$File::Sticker::Reader::Mp3::VERSION = '0.9301';
=head1 NAME

File::Sticker::Reader::Mp3 - read and standardize meta-data from MP3 file

=head1 VERSION

version 0.9301

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
        url=>'TEXT',
        genre=>'TEXT',
        tags=>'MULTI'};
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

    # album => dublincore.title
    # title => song
    # artist => dublincore.creator
    # comment => dublincore.description
    # Skip the following fields: track
    my $comment;
    my $info = $mp3->autoinfo(1);
    my @tags = ();
    foreach my $key (sort keys %{$info})
    {
        my $val = $info->{$key};
        say STDERR "$key=", $val->[0] if $self->{verbose} > 2;
        if ($key eq 'album')
        {
            $meta{'title'} = $val->[0];
        }
        elsif ($key =~ /song|title/)
        {
            $meta{'song'} = $val->[0];
        }
        elsif ($key eq 'artist')
        {
            $meta{'creator'} = $val->[0];
        }
        elsif ($key eq 'comment')
        {
            $meta{'description'} = $val->[0];
        }
        elsif ($key eq 'year')
        {
            $meta{'year'} = $val->[0];
        }
        elsif ($key eq 'genre')
        {
            $meta{'genre'} = $val->[0];
        }
        elsif ($key =~ /track/)
        {
            # skip
        }
        else
        {
            if ($val->[0])
            {
                my $tag = $key . "-" . $val->[0];
                $tag =~ s/\&/and/g;
                $tag =~ s/[^-_\s0-9a-zA-Z]//g;
                $tag =~ s/\s+/_/g; # replace spaces with underscores
                $tag =~ s/_-_/-/g; # replace _-_ with -
                push @tags, $tag;
            }
        }
    }

    # get url
    # official audio file webpage
    my $value = $mp3->select_id3v2_frame_by_descr('WOAF');
    $meta{url} = $value if $value;
    # official audio source webpage
    $value = $mp3->select_id3v2_frame_by_descr('WOAS');
    $meta{url} = $value if !$meta{url} and $value;

    # author (as distinct from artist)
    $value = $mp3->composer();
    $meta{author} = $value if $value;

    # get freeform tags from the TXXX field (see setpod)
    if ($mp3->have_id3v2_frame('TXXX', [qw(tags)]))
    {
        my $tagframe = $mp3->select_id3v2_frame('TXXX', [qw(tags)], undef);
        my @ftags = split(/,/, $tagframe);
        push @tags, @ftags;
    }
    if (@tags)
    {
        $meta{tags} = join(',', @tags);
    }

    return \%meta;
} # read_meta

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Reader
__END__
