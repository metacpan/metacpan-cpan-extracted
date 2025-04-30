# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from filesystems


package File::Information::Tagpool;

use v5.10;
use strict;
use warnings;

use parent 'File::Information::Base';

use Carp;
use File::Spec;
use Sys::Hostname ();
use Scalar::Util qw(weaken);

use File::Information::Lock;

our $VERSION = v0.09;

my $HAVE_FILE_VALUEFILE = eval {require File::ValueFile::Simple::Reader; require File::ValueFile::Simple::Writer; 1;};

my %_properties = (
    tagpool_pool_path => {loader => \&_load_tagpool, rawtype => 'filename'},
);

if ($HAVE_FILE_VALUEFILE) {
    $_properties{tagpool_pool_uuid} = {loader => \&_load_tagpool, rawtype => 'uuid'};
}

sub _new {
    my ($pkg, %opts) = @_;
    my $self = $pkg->SUPER::_new(%opts, properties => \%_properties);

    croak 'No path is given' unless defined $self->{path};

    return $self;
}


#@returns File::Information::Lock
sub lock {
    my ($self) = @_;
    my $locks = $self->{locks} //= {};

    unless (scalar keys %{$locks}) {
        my $lockfile = $self->_catfile('lock');
        my $lockname = $self->_tempfile('lock');
        open(my $out, '>', $lockname) or die $!;
        print $out ".\n";
        close($out);

        for (my $i = 0; $i < 3; $i++) {
            if (link($lockname, $lockfile)) {
                # Success.
                $self->{lockfile} = $lockfile;
                $self->{lockname} = $lockname;
                {
                    my $lock = File::Information::Lock->new(parent => $self, on_unlock => \&_unlock);
                    $locks->{$lock} = $lock;
                    weaken($locks->{$lock}); # it holds a reference to us, so our's will be weak.
                    return $lock;
                }
            }
            sleep(1);
        }

        unlink($lockname);
        croak 'Can not lock pool';
    }

    {
        my $lock = File::Information::Lock->new(parent => $self, on_unlock => \&_unlock);
        $locks->{$lock} = $lock;
        weaken($locks->{$lock}); # it holds a reference to us, so our's will be weak.
        return $lock;
    }
}


sub locked {
    my ($self, $func) = @_;
    my $lock = $self->lock;
    return $func->();
}


sub load_sysfile_cache {
    my ($self) = @_;
    my $locks = $self->{locks} //= {};

    unless (scalar keys %{$locks}) {
        croak 'The pool must be locked to read the sysfile cache';
    }

    unless (defined $self->{sysfile_cache}) {
        my $local_cache = $self->instance->_tagpool_sysfile_cache->{$self->{path}} //= {};
        my $data_path = $self->_catdir('data');
        my %cache;

        opendir(my $dir, $data_path) or croak $!;

        while (my $entry = readdir($dir)) {
            my @c_stat;

            $entry =~ /^file\./ or next; # skip everything that is not a file.* to begin with.

            @c_stat = stat($self->_catfile('data', $entry));
            next unless scalar @c_stat;

            $cache{$c_stat[1].'@'.$c_stat[0]} = $entry;
        }

        %{$local_cache} = (%cache, complete => 1);

        return $self->{sysfile_cache} = \%cache;
    }

    return $self->{sysfile_cache};
}


sub file_add {
    my ($self, $files, %opts) = @_;
    my $instance = $self->instance;
    my $local_cache = $instance->_tagpool_sysfile_cache->{$self->{path}} //= {};
    my $lock;
    my $sysfile_cache;
    my %to_add;

    # First setup %to_add:
    $files = [$files] unless ref($files) eq 'ARRAY';
    foreach my $file (@{$files}) {
        my $link;
        my $inode;
        my $path;
        my $key;

        croak 'File is undefined' unless $file;

        if (ref($file)) {
            if ($file->isa('File::Information::Link')) {
                $link = $file;
            } elsif ($file->isa('File::Information::Inode')) {
                $inode = $file;
            } else {
                $inode = $instance->for_handle($file);
            }
        } else {
            $link = $instance->for_link($file);
        }

        $inode = $link->inode if !defined($inode) && defined($link);

        $path //= $link->{path}  if defined $link;
        $path //= $inode->{path} if defined $inode;

        croak 'Cannot find any inode for file' unless defined $inode;

        $key = $inode->get('stat_cachehash');

        $to_add{$key} = {
            inode => $inode,
            link => $link,
            path => $path,
            type => $inode->get('tagpool_inode_type', as => 'ise'),
            uuid => $inode->get('uuid',               as => 'uuid', default => undef),
        };
    }

    # Lock the pool and figure out what to add.
    $lock = $self->lock;
    $sysfile_cache = $self->load_sysfile_cache;

    # Check if we have any valid files.
    foreach my $key (keys %to_add) {
        my $file = $to_add{$key};
        my $invalid;

        $invalid ||= !defined($file->{path}) && length($file->{path});
        $invalid ||= $file->{type} ne 'e6d6bb07-1a6a-46f6-8c18-5aa6ea24d7cb';

        if (exists $sysfile_cache->{$key}) {
            if ($opts{skip_already}) {
                delete $to_add{$key};
                next;
            }
            $invalid ||= 1;
        }

        if ($invalid && $opts{skip_invalid}) {
            delete $to_add{$key};
            next;
        }

        unless (defined $file->{uuid}) {
            $file->{uuid} = Data::Identifier->random(type => 'uuid')->uuid;
        }

        $invalid ||= !defined($file->{uuid});

        $invalid ||= -e $self->_catfile('data', 'info.'.$file->{uuid});

        if ($invalid) {
            croak 'Cannot add file '.$key.': Not permissible for adding';
        }
    }

    # Now we only have files in %to_add which we can actually add.
    # We also have a lock.
    # So add them!

    foreach my $key (keys %to_add) {
        my $file = $to_add{$key};
        my $uuid = $file->{uuid};
        my $inode = $file->{inode},
        my $pool_name_suffix = 'file.'.$uuid.'.x';
        my $writer;
        my %data = (
        );
        my %info;
        my %tags;
        my %_base_key_to_tagpool_info = (
            st_ino      => 'inode',
            st_mtime    => 'mtime',
            size        => 'size',
        );

        foreach my $lifecycle (qw(current final)) {
            my $c = $data{$lifecycle} = {};

            foreach my $base_key (qw(st_ino st_mtime size)) {
                $c->{$_base_key_to_tagpool_info{$base_key}} = $inode->get($base_key, lifecycle => $lifecycle, default => undef);
            }
        }

        foreach my $lifecycle (qw(current final)) {
            foreach my $tagpool_name (qw(sha1 sha512)) {
                my $utag_name = $File::Information::Base::_digest_name_converter{$tagpool_name} or next;
                my $digest = $inode->digest($utag_name, lifecycle => $lifecycle, as => 'hex', default => undef);
                next unless defined $digest;
                $data{$lifecycle}{'hash-'.$tagpool_name} = $digest;
            }
        }

        $data{current}{timestamp} = time();

        %info = (
            (map {$_ => $inode->get($_, default => undef)} qw(title comment description)),
            (map {'initial-'.$_ => $data{current}{$_}, 'last-'.$_ => $data{current}{$_}} keys %{$data{current}}),
            (map {'final-'.$_ => $data{final}{$_}} keys %{$data{final}}),
            'pool-name-suffix' => $pool_name_suffix,
        );

        # Fixup:
        foreach my $c (keys %info) {
            delete($info{$c}) unless defined $info{$c};
        }

        foreach my $base_key (qw(writemode mediatype finalmode)) {
            my $uuid = $inode->get($base_key, as => 'uuid', default => undef);
            next unless $uuid;
            $tags{$uuid} = undef;
        }

        warn $uuid;

        link($file->{path}, $self->_catfile('data', $pool_name_suffix)) or die $!;

        $writer = File::ValueFile::Simple::Writer->new($self->_catfile('data', 'info.'.$uuid));
        $writer->write_hash(\%info);

        $writer = File::ValueFile::Simple::Writer->new($self->_catfile('data', 'tags.'.$uuid));
        $writer->write('tagged-as', $_) foreach keys %tags;

        $sysfile_cache->{$key} = $pool_name_suffix;
        $local_cache->{$key} = $pool_name_suffix;
    }
}

# ----------------

sub DESTROY {
    my ($self) = @_;

    if (defined($self->{locks}) && scalar(keys %{$self->{locks}})) {
        warn 'DESTROY on locked pool. BUG.';
        warn sprintf('LOCK: %s -> %s', $_, $self->{locks}{$_} // '<undef>') foreach keys %{$self->{locks}};
        warn 'END OF LOCK LIST';
    }
}

sub _catfile {
    my ($self, @c) = @_;
    File::Spec->catfile($self->{path}, @c);
}

sub _catdir {
    my ($self, @c) = @_;
    File::Spec->catdir($self->{path}, @c);
}

sub _tempfile {
    my ($self, $task, $instance) = @_;

    $task ||= 'UNKNOWN';
    $instance ||= int($self);;

    return $self->_catfile('temp', sprintf('%s.%i.%s.%s', Sys::Hostname::hostname(), $$, $task, $instance));
}

sub _unlock {
    my ($self, $lock) = @_;
    my $locks = $self->{locks};

    delete $locks->{$lock};

    unless (scalar keys %{$locks}) {
        unlink($self->{lockfile}) if defined $self->{lockfile};
        unlink($self->{lockname}) if defined $self->{lockname};
        $self->{lockfile} = undef;
        $self->{lockname} = undef;
        $self->{sysfile_cache} = undef;
    }
}

sub _load_tagpool {
    my ($self, $key, %opts) = @_;
    my $pv = $self->{properties_values} //= {};
    my $config;

    return if $self->{_loaded_tagpool_pool};
    $self->{_loaded_tagpool_pool} = 1;

    $pv->{current} //= {};
    $pv->{current}{tagpool_pool_path} = {raw => $self->{path}};

    return unless $HAVE_FILE_VALUEFILE;

    eval {
        my $path = $self->_catfile('config');
        my $reader = File::ValueFile::Simple::Reader->new($path, supported_formats => undef, supported_features => []);
        $config = $reader->read_as_hash;
    };

    return unless defined $config;

    $pv->{current}{tagpool_pool_uuid} = {raw => $config->{'pool-uuid'}} if defined($config->{'pool-uuid'}) && length($config->{'pool-uuid'}) == 36;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Information::Tagpool - generic module for extracting information from filesystems

=head1 VERSION

version v0.09

=head1 SYNOPSIS

    use File::Information;

    my @tagpool = $instance->tagpool;

    my @tagpool = $inode->tagpool;

    my File::Information::Tagpool $tagpool = ...;

This module represents an instance of a tagpool.

B<Note:> This package inherits from L<File::Information::Base>.

=head1 METHODS

=head2 lock

    my File::Information::Lock $lock = $pool->lock;

Locks the pool and returns the lock.

Some operations require the pool to be in locked state. Specifically all write operations.
When the pool is locked no other process or instance can access it.

The lock stays valid as long as a reference to C<$lock> is kept alive. See L<File::Information::Lock> about locks.
It is possible to acquire multiple lock objects from the same instance (C<$pool>). In that case the pool stays locked
until all lock references are gone.

B<Note:>
Locking the pool may take time as we might wait on other locks.
It may also fail (C<die>ing if it does) if no lock can be acquired.

B<Note:>
If you perform multiple write operations it will generally improve performance significantly to keep it locked.
To do this acquire a lock before you start your operations and hold for as long as you keep working on the pool.
However you should not lock the pool while idle to allow other processes to interact with it as well.
How long is too long is hard to answer in a general manner.

B<See also>:
L</locked>

=head2 locked

    $pool->locked(sub {
        # your code ...
    });

This call run the passed coderef with an active lock. It is similar to:

    {
        my File::Information::Lock $lock = $pool->lock;
        {
            # your code ....
        }
    }

B<Note:>
It is safe to use this method even if you already hold a lock. This allows code calling this method
to not need to take notice about the current state of locking.

B<See also:>
L</lock>

=head2 load_sysfile_cache

    my File::Information::Lock $lock ...;
    $pool->load_sysfile_cache;

This method loads the pool's sysfile cache into memory. It will do nothing if the cache is already loaded.
The sysfile cache is only valid as long as the pool is locked. It is automatically discarded on unlock.

This method will also seed the instance's sysfile cache (see L<File::Information>).
The instance's cache may survive pool unlock.

B<Note:>
This method is normally not needed to be called manually. However if you perform a lot of read operations on the pool
(such as calling L<File::Information/for_link> or L<File::Information/for_handle> on a large number of different files)
this can be beneficial. It also allows to seed the cache ahead of time to speed up lookups later on.

B<Note:>
This method caches information on all sysfiles in the pool in memory. This can be memory expensive.
One should expect at least 1024 Byte of memory usage per file in the pool. For small pools this is of no concern.
However for larger pools it must be considered. Also, as this seeds the instance's cache not all of it may be gone
once the pool is unlocked. See L<File::Information> for it's cache handling.

=head2 file_add

    $pool->file_add(\@files [, %opts ]);

Adds the given files to the pool. On error this method C<die>s.

The pool is automatically locked if it is not yet locked.
If you want to add multiple files you can pass them. If you want to call this method multiple times
it might be more performant to acquire a lock before and hold it until you're done.

The following (all optional) options are supported:

=over

=item C<skip_already>

Files that are already in the pool are silently skipped.

=item C<skip_invalid>

Silently skip files that are invalid for any reason.

=back

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
