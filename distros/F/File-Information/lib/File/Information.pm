# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extrating information from filesystems


package File::Information;

use v5.16;
use strict;
use warnings;

use Carp;
use Fcntl qw(S_ISBLK);
use File::Spec;

use File::Information::Link;
use File::Information::Inode;
use File::Information::Filesystem;
use File::Information::Tagpool;

our $VERSION = v0.02;

my $HAVE_FILE_VALUEFILE = eval {require File::ValueFile::Simple::Reader; 1;};


my %_new_subobjects = (
    extractor   => 'Data::URIID',
    db          => 'Data::TagDB',
);

sub new {
    my ($pkg, %opts) = @_;
    my $self = bless {};

    foreach my $key (keys %_new_subobjects) {
        if (defined($opts{$key})) {
            croak 'Bad package for option '.$key unless eval {$opts{$key}->isa($_new_subobjects{$key})};
            $self->{$key} = $opts{$key};
        }
    }

    $self->{$_} = $opts{$_} foreach qw(tagpool_rc tagpool_path device_path digest_sizelimit);

    $self->{digest_sizelimit} //= 512*1024*1024; # 512MB

    if ($self->{digest_sizelimit} eq 'infinite') {
        $self->{digest_sizelimit} = -1;
    } else {
        $self->{digest_sizelimit} =  int($self->{digest_sizelimit}); # ensure it's an int. This will also set to 0 in case of error.
        $self->{digest_sizelimit} = 0 if $self->{digest_sizelimit} < 0;
    }

    if (defined $opts{digest_unsafe}) {
        my $unsafe = $opts{digest_unsafe};

        $unsafe = [$unsafe] unless ref($unsafe) eq 'ARRAY';

        $_->{unsafe} = 1 foreach $self->digest_info(@{$unsafe});
    }

    $self->_tagpool_locate;

    return $self;
}


sub for_link {
    my ($self, %opts);

    if (scalar(@_) == 2) {
        ($self, $opts{path}) = @_;
    } else {
        ($self, %opts) = @_;
    }

    return File::Information::Link->_new(instance => $self, (map {$_ => $opts{$_}} qw(path symlinks)));
}


#@returns File::Information::Inode
sub for_handle {
    my ($self, %opts);

    if (scalar(@_) == 2) {
        ($self, $opts{handle}) = @_;
    } else {
        ($self, %opts) = @_;
    }

    return File::Information::Inode->_new(instance => $self, (map {$_ => $opts{$_}} qw(handle)));
}


sub tagpool {
    my ($self) = @_;
    return values %{$self->_tagpool}
}


#@returns Data::URIID
sub extractor {
    my ($self) = @_;

    return $self->{extractor} // croak 'No extractor available';
}


#@returns Data::TagDB
sub db {
    my ($self) = @_;

    return $self->{db} // croak 'No database available';
}


sub lifecycles {
    return qw(initial last current final);
}


sub digest_info {
    my ($self, @algos) = @_;
    my @ret;

    unless ($self->{hash_info}) {
        my %hashes = map {$_ => {
                name => $_,
                bits => int(($_ =~ /-([0-9]+)$/)[0]),
                aliases => [],
            }} (
            values(%File::Information::Base::_digest_name_converter),
            qw(md-4-128 ripemd-1-160 tiger-1-192 tiger-2-192),
        );
        $self->{hash_info} = \%hashes;

        $hashes{$_}{unsafe} = 1 foreach qw(md-4-128 md-5-128 sha-1-160);
        push(@{$hashes{$File::Information::Base::_digest_name_converter{$_}}{aliases}}, $_) foreach keys %File::Information::Base::_digest_name_converter;
    }

    @algos = keys %{$self->{hash_info}} unless scalar @algos;

    croak 'Request for more than one hash in scalar context' if !wantarray && scalar(@algos) != 1;

    @ret = map{
        $self->{hash_info}{$_} ||
        $self->{hash_info}{$File::Information::Base::_digest_name_converter{fc($_)} // ''} ||
        croak 'Unknown digest: '.$_
    } map { s#^v0 (\S+) bytes [0-9]+-[0-9]*/(?:[0-9]+|\*) [0-9a-f\.]+$#$1#r } @algos;

    if (wantarray) {
        return @ret;
    } else {
        return $ret[0];
    }
}

# ----------------

sub _home {
    my ($self) = @_;
    my $home;

    return $self->{home} if defined $self->{home};

    if ($^O eq 'MSWin32') {
        return $self->{home} = $home if defined($home = $ENV{USERPROFILE}) && length($home);
        if (defined($ENV{HOMEDRIVE}) && defined($ENV{HOMEPATH})) {
            $home = $ENV{HOMEDRIVE}.$ENV{HOMEPATH};
            return $self->{home} = $home if length($home);
        }
        return $self->{home} = 'C:\\';
    } else {
        return $self->{home} = $home if defined($home = $ENV{HOME}) && length($home);
        return $self->{home} = $home if defined($home = eval { [getpwuid($>)]->[7] }) && length($home);
        return $self->{home} = File::Spec->rootdir;
    }

    croak 'BUG';
}

sub _path {
    my ($self, $xdg, $type, @el) = @_;
    my $base;

    if (defined $xdg) {
        $base = $ENV{$xdg} // $self->{$xdg};
        if (!defined($base) || !length($base)) {
            if ($xdg eq 'XDG_CACHE_HOME') {
                $base = File::Spec->catdir($self->_home, qw(.cache));
            } elsif ($xdg eq 'XDG_DATA_HOME') {
                $base = File::Spec->catdir($self->_home, qw(.local share));
            } elsif ($xdg eq 'XDG_CONFIG_HOME') {
                $base = File::Spec->catdir($self->_home, qw(.config));
            } elsif ($xdg eq 'XDG_STATE_HOME') {
                $base = File::Spec->catdir($self->_home, qw(.local state));
            } else {
                croak 'Unknown XDG path: '.$xdg;
            }

            $self->{$xdg} = $base;
        }
    } else {
        $base = $self->_home;
    }

    if ($type eq 'file') {
        return File::Spec->catfile($base, @el);
    } else {
        return File::Spec->catdir($base, @el);
    }
}

sub _tagpool_locate {
    my ($self) = @_;
    my %candidates;

    return unless $HAVE_FILE_VALUEFILE;

    unless (defined $self->{tagpool_rc}) {
        # Set defaults:
        $self->{tagpool_rc} = ['/etc/tagpoolrc', $self->_path(undef, file => '.tagpoolrc')]; # Values taken from tagpool as is. Should be updated.
    }

    unless (defined $self->{tagpool_path}) {
        # Set defaults:
        $self->{tagpool_path} = []; # none at this point.
    }

    $self->{tagpool_rc} = [$self->{tagpool_rc}] unless ref $self->{tagpool_rc};
    $self->{tagpool_path} = [$self->{tagpool_path}] unless ref $self->{tagpool_path};

    %candidates = map {$_ => undef} grep {defined} @{$self->{tagpool_path}};

    foreach my $tagpool_rc_path (@{$self->{tagpool_rc}}) {
        my $hash = eval {File::ValueFile::Simple::Reader->new($tagpool_rc_path)->read_as_hash};
        if (defined $hash) {
            foreach my $key (qw(pool-path pool)) {
                if (defined $hash->{$key}) {
                    $candidates{$hash->{$key}} = undef;
                }
            }
        }
    }

    # eliminate all but the ones that look like actual pools:
    foreach my $path (keys %candidates) {
        unless (-d $path) {
            delete $candidates{$path};
            next;
        }

        foreach my $subdir (qw(data temp)) {
            unless (-d File::Spec->catdir($path, $subdir)) {
                delete $candidates{$path};
                next;
            }
        }

        foreach my $subfile (qw(config)) {
            unless (-f File::Spec->catfile($path, $subfile)) {
                delete $candidates{$path};
                next;
            }
        }
    }

    $self->{tagpool_path} = [keys %candidates];
}

sub _tagpool_path {
    my ($self) = @_;
    return $self->{tagpool_path};
}

sub _tagpool_sysfile_cache {
    my ($self) = @_;
    return $self->{_tagpool_sysfile_cache} //= {};
}

sub _tagpool {
    my ($self) = @_;
    my $pools = $self->{tagpool} //= {
        map {$_ => File::Information::Tagpool->_new(instance => $self, path => $_)} @{$self->_tagpool_path}
    };

    return $pools;
}

sub _load_filesystems {
    my ($self) = @_;
    unless (defined $self->{filesystems}) {
        my %dirs;
        my %found;
        my %filesystems;

        $self->{device_path} //= File::Information::Filesystem->_default_device_search_paths;

        $self->{device_path} = [$self->{device_path}] unless ref($self->{device_path}) eq 'ARRAY';

        %dirs = map {$_ => undef} @{$self->{device_path}};

        foreach my $dir_path (keys %dirs) {
            if (opendir(my $dir, $dir_path)) {
                while (my $entry = readdir($dir)) {
                    my $devpath = File::Spec->catfile($dir_path, $entry);
                    my @stat = stat($devpath);

                    next unless scalar @stat;
                    next unless S_ISBLK($stat[2]);

                    $found{$stat[6]} //= {};
                    $found{$stat[6]}{''} = \@stat;
                    $found{$stat[6]}{$dir_path} //= [];
                    push(@{$found{$stat[6]}{$dir_path}}, $entry);
                }
            }
        }

        foreach my $key (keys %found) {
            my $entry = $found{$key};
            my $stat = delete $entry->{''};
            $filesystems{$key} = File::Information::Filesystem->_new(instance => $self, stat => $stat, paths => $entry);
        }
        $self->{dev_found} = \%found;
        $self->{filesystems} = \%filesystems;
    }
}

sub _filesystem_for {
    my ($self, $dev) = @_;
    $self->_load_filesystems;
    return $self->{filesystems}{$dev};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Information - generic module for extrating information from filesystems

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use File::Information;

    my File::Information $instance = File::Information->new(%config);

=head1 METHODS

=head2 new

    my File::Information $instance = File::Information->new(%config);

Creates a new instance that can be used to do lookups later on.

The following options (all optional) are supported:

=over

=item C<extractor>

An instance of L<Data::URIID> used to create related objects.

=item C<db>

An instance of L<Data::TagDB> used to interact with a database.

=item C<tagpool_rc>

A filename (or list of filenames) of tagpool rc files. Pool locations will be read from those files.
Default is to try standard locations. To disable this it is possible to set the option to C<[]>.

=item C<tagpool_path>

A path (or a list of paths) of tagpool directories. This is where a pool is located.
Default is to try standard locations. To disable this it is possible to set the option to C<[]>.
However to disable tagpool support fully C<tagpool_rc> also needs to be set to C<[]>.

Only valid pools are accepted. Invalid pools are rejected without warning.

=item C<device_path>

The path (or list of paths) to look for device inodes. This is used as part of filesystem detection.
Default is to try a list of standard locations. To disable this it is possible to set the option to C<[]>.

This module does B<not> perform recursive searches. Therefore on systems that include paths like C</dev/disk>
those also need to be included for this module to work correctly. It is therefore recommended not to alter this
setting.

=item C<digest_sizelimit>

The size limit (in bytes) for how large of a datablock (such as a file) the module will perform hashing.
This can be set to C<0> to disable hashing. When set to C<'infinite'> the limit is disabled.
The default is suitable for modern machines and will be not less than 16MiB.

=item C<digest_unsafe>

An digest or a list of digests to be defined unsafe. See L</digest_info> for details.
Dies if a digest in the list is unknown (this is for security reasons).
This option only allows to mark additinal digests unsafe. It does not allow to mark already marked ones safe again.

=back

=head2 for_link

    my File::Information::Link $link = $instance->for_link($path);
    # or:
    my File::Information::Link $link = $instance->for_link(path => $path [, %opts ]);

Creates a new link instance.

The following options are supported:

=over

=item C<path>

Required if not using the one-argument form. Gives the path (filename) of the link.

=item C<symlinks>

Whether (C<follow>) or not (C<nofollow>; default) symlinks.

=back

=head2 for_handle

    my File::Information::Inode $inode = $instance->for_handle($handle);
    # or:
    my File::Information::Inode $inode = $instance->for_handle(handle => $handle [, %opts ]);

Creates a new inode instance.

The following options are supported:

=over

=item C<handle>

Required if not using the one-argument form. Gives an open handle to the inode.

=back

=head2 tagpool

    my @tagpool = $inode->tagpool;

Returns the list of found tagpools if any (See L<File::Information::Tagpool>).

B<Note:>
There is no order to the returned values. The order may change between any two calls.

=head2 extractor

    my Data::URIID $extractor = $instance->extractor;

Returns the extractor given via the configuration. Will die if no extractor is available.

=head2 db

    my Data::TagDB $db = $instance->db;

Returns the database given via the configuration. Will die if no database is available.

=head2 lifecycles

    my @lifecycles = $instance->lifecycles;

Returns the list of known lifecycles.
The order of the list is not defined. However the method will return them in a way suitable for display to an user.

Currently defined are the following lifecycles:

=over

=item C<initial>

The initial state. This is the state the object is in when it becomes known.
The exact meaning depend on the used data source.

=item C<last>

The state the object was in when last interacted with a non-read-only manner.
The exact meaning depend on the used data source.

=item C<current>

The current state of the object.

=item C<final>

The state the object will be in when it is I<final>.
Most commonly this is used to compare to when checking if a object is corrupted.

=back

=head2 digest_info

    my $info = $instance->digest_info('sha-3-512');
    # or:
    my @info = $instance->digest_info;
    # or:
    my @info = $instance->digest_info('sha-2-512', 'sha-3-512');

Returns information on one or more digests. If no digest is given returns infos for all known ones.

The digest can be given in the universal tag format (preferred), one of it's aliases (dissuaded),
or a complete digest-and-value string in universal tag format (only version C<v0>).

The return value is a hashref or an array of hashrefs which contain the following keys:

=over

=item C<name>

The name of the digest in universal tag format (the format used in this module).

=item C<bits>

The number of bits the digest will return.

=item C<aliases>

An arrayref to a list of aliases for this digest.

=item C<unsafe>

A boolean indicating if the digest is considered unsafe by this module.
B<Security:> Note that a digest not defined unsafe by this module may still be unsafe to use.
This can for example happen if the digest became unsafe after the release of the version of this module.

=back

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
