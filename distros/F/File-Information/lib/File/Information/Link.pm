# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from filesystems


package File::Information::Link;

use v5.10;
use strict;
use warnings;

use parent 'File::Information::Base';

use Carp;
use Fcntl qw(O_RDONLY O_NOFOLLOW SEEK_SET);
use File::Spec;
use File::Basename ();

use File::Information::Inode;

our $VERSION = v0.04;

my $HAVE_XML_SIMPLE = eval {require XML::Simple; 1;};
my $HAVE_URI_FILE = eval {require URI::file; 1;};
my $HAVE_DIGEST = eval {require Digest; 1;};

my %_properties = (
    link_basename       => {loader => \&_load_basename},
    link_basename_clean => {loader => \&_load_basename},
);

if ($HAVE_XML_SIMPLE) {
    $_properties{'dotcomments_'.$_} = {loader => \&_load_dotcomments, dotcomments_key => $_} foreach qw(version note place time_v2_0 time_v3_0 keywords caption rating categories);
    $_properties{dotcomments_time_v2_0}{rawtype} = 'unixts';
}

if ($HAVE_URI_FILE && $HAVE_DIGEST) {
    $_properties{link_thumbnail} = {loader => \&_load_thumbnail, rawtype => 'filename'};
}

sub _new {
    my ($pkg, %opts) = @_;
    my $self = $pkg->SUPER::_new(%opts, properties => \%_properties);

    croak 'No path is given' unless defined $self->{path};

    return $self;
}


#@returns File::Information::Inode;
sub inode {
    my ($self) = @_;

    unless (defined $self->{inode}) {
        my $fh;
        my $mode = 0;

        if (($self->{symlinks} // '') ne 'follow') {
            $mode |= O_NOFOLLOW;
        }

        sysopen($fh, $self->{path}, O_RDONLY|$mode) or opendir($fh, $self->{path}) or die $!;
        $self->{inode} = File::Information::Inode->_new(
            (map {$_ => $self->{$_}} qw(instance path)),
            handle => $fh,
        );
    }

    return $self->{inode} // croak 'No Inode';
}


#@returns File::Information::Filesystem
sub filesystem {
    my ($self, @args) = @_;
    return $self->{filesystem} //= $self->inode->filesystem(@args);
}


sub tagpool {
    my ($self, @args) = @_;
    return $self->inode->tagpool(@args);
}

sub _load_dotcomments {
    my ($self, $key) = @_;
    unless ($self->{_loaded_dotcomments}) {
        my $info = $self->{properties}{$key};
        my $pv = ($self->{properties_values} //= {})->{current} //= {};
        my ($volume, $directories, $file) = File::Spec->splitpath($self->{path});
        my $comments_file = File::Spec->catfile($volume, $directories, '.comments', $file.'.xml');
        my $xml;

        $self->{_loaded_dotcomments} = 1;

        return unless -f $comments_file;

        croak 'Not supported, requires XML::Simple' unless $HAVE_XML_SIMPLE;

        eval {
            my $magic;
            my $fh;

            open($fh, '<', $comments_file) or die $!;
            binmode($fh);

            read($fh, $magic, 2);
            seek($fh, 0, SEEK_SET);

            if ($magic eq "\x1f\x8b") {
                binmode($fh, ':gzip');
            }

            $xml = XML::Simple::XMLin($fh);
        };

        croak 'No valid .comments/ XML at: '.$comments_file unless defined $xml;

        foreach my $key (qw(version note place caption keywords)) {
            my $value = $xml->{$key} // $xml->{ucfirst $key};

            if (defined($value) && !ref($value) && length($value)) {
                $pv->{'dotcomments_'.$key} = {raw => $value};
            }
        }

        {
            my $value = $xml->{time} // $xml->{Time};
            if (defined($value)) {
                if ($xml->{version} eq '2.0') {
                    if (!ref($value) && $value =~ /^[0-9][1-9]+$/ && int($value)) {
                        $pv->{dotcomments_time_v2_0} = {raw => int($value)};
                    }
                } elsif ($xml->{version} eq '3.0') {
                    if (ref($value) && defined($value->{value}) && !ref($value->{value}) && $value->{value} =~ /^[0-9]{4}:[0-9]{2}:[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$/) {
                        $pv->{dotcomments_time_v3_0} = {raw => $value->{value}};
                    }
                }
            }
        }

        {
            my $value = $xml->{rating} // $xml->{Rating};
            if (defined($value) && ref($value) && defined($value->{value}) && !ref($value->{value}) && $value->{value} =~ /^[1-5]$/) {
                $pv->{dotcomments_rating} = {raw => int($value->{value})};
            }
        }

        {
            my $value = $xml->{categories} // $xml->{Categories};
            my @list;

            if (defined($value) && ref($value) && defined($value->{category}) && ref($value->{category})) {
                $value = $value->{category};
                if (ref($value)) {
                    foreach my $entry (@{$value}) {
                        if (ref($entry) && defined($entry->{value}) && length($entry->{value})) {
                            push(@list, $entry->{value});
                        }
                    }
                }
            }

            if (defined($pv->{dotcomments_keywords}) && defined($pv->{dotcomments_keywords}{raw})) {
                push(@list, grep {length} split(/\s*,\s*/, $pv->{dotcomments_keywords}{raw}));
            }

            $pv->{dotcomments_categories}{raw} = \@list;
        }
    }
}

sub _load_basename {
    my ($self) = @_;
    my $basename = File::Basename::basename($self->{path});
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    $pv->{link_basename} = {raw => $basename};

    $basename =~ s/(.)(?:\.tar)?\.[^\.]+$/$1/;
    $basename =~ s/^[a-z]+\.[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\.(.)/$1/;

    $pv->{link_basename_clean} = {raw => $basename};
}

sub _load_thumbnail {
    my ($self) = @_;
    unless ($self->{_loaded_thumbnail}) {
        my $instance = $self->instance;
        my $pv = ($self->{properties_values} //= {})->{current} //= {};
        my $uri = URI::file->new_abs($self->{path});
        my $digest = Digest->new('MD5')->add($uri)->hexdigest;
        my $mtime = $self->inode->get('st_mtime', default => undef);

        $self->{_loaded_thumbnail} = 1;

        return unless defined $mtime;

        foreach my $size (qw(normal large x-large xx-large)) {
            my $file = $instance->_path(XDG_CACHE_HOME => file => thumbnails => $size => $digest.'.png');
            my @stat = stat($file);
            if (scalar(@stat)) {
                if ($mtime < $stat[9]) {
                    $pv->{link_thumbnail} = {raw => $file};
                    return;
                }
            }
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Information::Link - generic module for extracting information from filesystems

=head1 VERSION

version v0.04

=head1 SYNOPSIS

    use File::Information;

    my File::Information $instance = File::Information->new(%config);

    my File::Information::Link $link = $instance->for_link($path);

B<Note:> This package inherits from L<File::Information::Base>.

This module represents a hardlink on a filesystem. A hardlink is is basically a name for an inode.
Each inode can have zero or more hardlinks. (The exact limits are subject to filesystem limitations.)
See also L<File::Information::Inode>.

=head1 METHODS

=head2 inode

    my File::Information::Inode $inode = $link->inode;

Provide the inode object for the current link.

=head2 filesystem

    my File::Information::Filesystem $filesystem = $link->filesystem;

Proxy for L<File::Information::Inode/filesystem>.

=head2 tagpool

    my File::Information::Tagpool $tagpool = $link->tagpool;
    # or:
    my                            @tagpool = $link->tagpool;

Proxy for L<File::Information::Inode/tagpool>.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
