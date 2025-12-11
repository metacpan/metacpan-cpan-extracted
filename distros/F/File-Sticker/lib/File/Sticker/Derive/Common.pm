package File::Sticker::Derive::Common;
$File::Sticker::Derive::Common::VERSION = '4.301';
=head1 NAME

File::Sticker::Derive::Common - derive values from existing meta-data

=head1 VERSION

version 4.301

=head1 SYNOPSIS

    use File::Sticker::Derive::Common;

    my $deriver = File::Sticker::Derive::Common->new(%args);

    my $derived_meta = $deriver->derive(filename=>$filename,meta=>$meta);

=head1 DESCRIPTION

This will derive values from existing meta-data.
This is the Common plugin, which derives things common to all files,
such as paths, size, and date.

=cut

use common::sense;
use POSIX qw(strftime);
use Path::Tiny;

use parent qw(File::Sticker::Derive);

=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 order

The order of this deriver, ranging from 0 to 99.
This makes sure that the deriver is applied in order;
useful because a later deriver may depend on data created
by an earlier deriver.

=cut

sub order {
    return 10;
} # order

=head2 derive

Derive common values from the existing meta-data.
This is expected to update the given meta-data.

    $deriver->derive(filename=>$filename, meta=>$meta);

=cut

sub derive {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $meta = $args{meta};

    my $fp = path($filename);
    if (-r $filename)
    {
        $meta->{file} = $fp->realpath->stringify;
    }
    else
    {
        $meta->{file} = $fp->absolute->stringify;
    }
    $meta->{basename} = $fp->basename();
    $meta->{id_name} = $fp->basename(qr/\.\w+/);
    if ($meta->{basename} =~ /\.(\w+)$/)
    {
        $meta->{ext} = $1;
    }

    if ($self->{topdir})
    {
        $meta->{relpath} = $fp->relative($self->{topdir})->stringify;
        my $rel_parent = $fp->parent->relative($self->{topdir})->stringify;
        if ($meta->{relpath} =~ /\.\./) # we got a problem
        {
            $meta->{relpath} =~ s!\.\./!!g;
            $rel_parent =~ s!\.\./!!g;
        }

        # Check if a thumbnail exists
        # It could be a jpg or a png
        # Note that if the file itself is a jpg or png, we can use it as the thumbnail
        if (-r $fp->parent . '/.thumbnails/' . $meta->{id_name} . '.jpg')
        {
            $meta->{thumbnail} = $rel_parent . '/.thumbnails/' . $meta->{id_name} . '.jpg'
        }
        elsif (-r $fp->parent . '/.thumbnails/' . $meta->{id_name} . '.png')
        {
            $meta->{thumbnail} = $rel_parent . '/.thumbnails/' . $meta->{id_name} . '.png'
        }
        elsif ($meta->{ext} =~ /jpg|png|gif/)
        {
            $meta->{thumbnail} = $meta->{relpath};
        }

        # Make this grouping stuff simple:
        # take it as the *directory* where the file is;
        # this is because that's how it is *grouped* together with other files, yes?
        # But use the directory relative to the "top" directory, the first two or three parts of it.

        my @bits = split(/\//, $rel_parent);
        splice(@bits,3);
        $meta->{grouping} = join(' ', @bits);

        # also make "section" fields, which are each separate bit of the "grouping"
        for (my $i=0; $i < @bits; $i++)
        {
            my $id = $i + 1;
            $meta->{"section${id}"} = $bits[$i];
        }
    }
    if (-r $filename)
    {
        my $stat = $fp->stat;
        $meta->{filesize} = $stat->size;

        $meta->{filedate} = strftime '%Y-%m-%d %H:%M:%S', localtime $stat->mtime;
    }
} # derive

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Derive::Common
__END__
