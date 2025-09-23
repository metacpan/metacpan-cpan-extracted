# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from filesystems


package File::Information::Inode;

use v5.10;
use strict;
use warnings;

use parent 'File::Information::Base';

use Carp;
use File::Spec;
use Fcntl qw(S_ISREG S_ISDIR S_ISLNK S_ISBLK S_ISCHR S_ISFIFO S_ISSOCK S_IWUSR S_IWGRP S_IWOTH SEEK_SET);

use Data::Identifier v0.08;
use Data::Identifier::Generate;

our $VERSION = v0.13;

my $HAVE_XATTR              = eval {require File::ExtAttr; 1;};
my $HAVE_FILE_VALUEFILE     = eval {require File::ValueFile::Simple::Reader; 1;};
my $HAVE_CONFIG_INI_READER  = eval {require Config::INI::Reader; 1;};

my %_ntfs_attributes = (
    FILE_ATTRIBUTE_READONLY             => 0x0001,
    FILE_ATTRIBUTE_HIDDEN               => 0x0002,
    FILE_ATTRIBUTE_SYSTEM               => 0x0004,
    FILE_ATTRIBUTE_ARCHIVE              => 0x0020,
    FILE_ATTRIBUTE_TEMPORARY            => 0x0100,
    FILE_ATTRIBUTE_COMPRESSED           => 0x0800,
    FILE_ATTRIBUTE_OFFLINE              => 0x1000,
    FILE_ATTRIBUTE_NOT_CONTENT_INDEXED  => 0x2000,
);

my %_tagpool_directory_setting_tagmap; # define here, but only load (below) if we $HAVE_FILE_VALUEFILE

my %_magic_map = (
    # image/*
    "\xff\xd8\xff"                      => 'image/jpeg',
    "\x89\x50\x4e\x47\x0d\x0a\x1a\x0a"  => 'image/png',
    'GIF87a'                            => 'image/gif',
    'GIF89a'                            => 'image/gif',
    "\0\0\1\0"                          => 'image/vnd.microsoft.icon',
    # audio/*
    'fLaC'                              => 'audio/flac',
    # application/*
    '%PDF-'                             => 'application/pdf',
    "PK\x03\x04"                        => 'application/zip',
    '%!PS-Adobe-'                       => 'application/postscript',
);

my %_wk_tagged_as_tags = (
    (map {$_ => {for => 'write-mode'}} qw(7b177183-083c-4387-abd3-8793eb647373 3877b2ef-6c77-423f-b15f-76508fbd48ed 4dc9fd07-7ef3-4215-8874-31d78ed55c22)),
    (map {$File::Information::Base::_mediatypes{$_} => {for => 'mediatype', mediatype => $_}} keys %File::Information::Base::_mediatypes),
    'f418cdb9-64a7-4f15-9a18-63f7755c5b47' => {for => 'finalmode', implies => [qw(7b177183-083c-4387-abd3-8793eb647373)]},
    'cb9c2c8a-b6bd-4733-80a4-5bd65af6b957' => {for => 'finalmode'},
);

my %_URLZONE = (
    # tag-ise             66294283-0a5d-4e78-a4b0-91df2c82068d # URLZONE-namespace
    0 => {ise => 'd0e96897-b82f-5696-aa8e-8c29a16ab613', displayname => 'URLZONE_LOCAL_MACHINE'},
    1 => {ise => 'cb576748-97f3-5fd7-80db-3682a94c67aa', displayname => 'URLZONE_INTRANET'},
    2 => {ise => '445acf47-7049-5af1-8ed9-fecb54a8c517', displayname => 'URLZONE_TRUSTED'},
    3 => {ise => 'a80b2f16-0db7-5536-a3ee-be8d85d123bd', displayname => 'URLZONE_INTERNET'},
    4 => {ise => '73ef6c11-cdef-5547-be38-aa2cede0d4ea', displayname => 'URLZONE_UNTRUSTED'},
);

my %_properties = (
    (map {$_ => {loader => \&_load_stat}}qw(st_dev st_ino st_mode st_nlink st_uid st_gid st_rdev st_size st_blksize st_blocks st_atime st_mtime st_ctime stat_readonly stat_cachehash)),
    magic_mediatype         => {loader => \&_load_magic, rawtype => 'mediatype'},
    magic_valuefile_version => {loader => \&_load_magic, rawtype => 'uuid'},
    magic_valuefile_format  => {loader => \&_load_magic, rawtype => 'ise'},
    db_inode_tag            => {loader => \&_load_db,    rawtype => 'Data::TagDB::Tag'},
    content_sha_3_512_uuid  => {loader => \&_load_contentise, rawtype => 'uuid'},
    content_sha_1_160_sha_3_512_uuid => {loader => \&_load_contentise, rawtype => 'uuid'},
    store_file              => {loader => \&_load_fstore, rawtype => 'File::FStore::File'},
    shebang_line            => {loader => \&_load_shebang},
    shebang_interpreter     => {loader => \&_load_shebang, rawtype => 'filename'},
);

$_properties{$_}{rawtype} = 'unixts' foreach qw(st_atime st_mtime st_ctime);
$_properties{$_}{rawtype} = 'bool'   foreach qw(stat_readonly);

if ($HAVE_XATTR) {
    $_properties{'xattr_'.$_} = {loader => \&_load_xattr, xattr_key => $_} foreach qw(mime_type charset creator);
    $_properties{'xattr_mime_type'}{rawtype} = 'mediatype';

    $_properties{'xattr_xdg_'.($_ =~ tr/.-/__/r)}   = {loader => \&_load_xattr, xattr_key => 'xdg.'.$_} foreach qw(comment origin.url origin.email.subject origin.email.from origin.email.message-id language creator publisher);

    $_properties{'xattr_dublincore_'.($_ =~ tr/.-/__/r)}   = {loader => \&_load_xattr, xattr_key => 'dublincore.'.$_} foreach qw(title creator subject description publisher contributor date type format identifier source language relation coverage rights);

    $_properties{'xattr_utag_'.($_ =~ tr/.-/__/r)} = {loader => \&_load_xattr, rawtype => 'ise', xattr_key => 'utag.'.$_} foreach qw(ise write-mode final-mode);
    $_properties{'xattr_utag_final_'.($_ =~ tr/.-/__/r)} = {loader => \&_load_xattr, lifecycle => 'final', xattr_key => 'utag.final.'.$_} foreach qw(file.size file.encoding file.hash);
    $_properties{'xattr_utag_final_file_encoding'}{parts} = [qw(ise mediatype)];
    $_properties{'xattr_utag_final_file_hash'}{parsing} = 'utag';
    $_properties{'xattr_utag_final_file_hash_size'} = {loader => \&_load_redirect, redirect => 'xattr_utag_final_file_hash'};

    $_properties{'ntfs_'.lc($_)} = {loader => \&_load_ntfs_xattr, ntfs_attribute => $_, rawtype => 'bool'} foreach keys %_ntfs_attributes;
}

if ($HAVE_FILE_VALUEFILE) {
    my $config = {loader => \&_load_tagpool_directory};
    $_properties{'tagpool_directory_'.$_} = {%{$config}} foreach qw(title comment description inode mtime pool_uuid timestamp);
    $_properties{'tagpool_directory_setting_'.($_ =~ tr/-/_/r)} = {%{$config}} foreach qw(thumbnail-uri thumbnail-mode update-mode add-mode file-tags tag-mode tag-implies entry-sort-order tag tag-root tag-parent tag-type entry-display-name entry-sort-key);
    $_properties{'tagpool_directory_'.$_}{rawtype} = 'unixts' foreach qw(mtime timestamp);
    $_properties{'tagpool_directory_'.$_}{rawtype} = 'uuid' foreach qw(pool_uuid);
    $_properties{'tagpool_directory_setting_'.($_ =~ tr/-/_/r)}{rawtype} = 'ise' foreach qw(tag tag-root tag-parent tag-type);
    $_properties{'tagpool_directory_throw_option_'.$_} = {%{$config}} foreach qw(linkname linktype filter);

    $_properties{'tagpool_file_'.($_ =~ tr/-/_/r)} = {loader => \&_load_tagpool_file} foreach qw(title comment description mtime timestamp inode size actual-size original-url original-description-url pool-name-suffix original-filename uuid mediatype write-mode finalmode thumbnail tags);
    $_properties{'tagpool_file_'.$_}{rawtype} = 'unixts' foreach qw(mtime timestamp);
    $_properties{'tagpool_file_'.($_ =~ tr/-/_/r)}{rawtype} = 'uuid' foreach qw(uuid write-mode finalmode tags);
    $_properties{'tagpool_file_'.($_ =~ tr/-/_/r)}{rawtype} = 'mediatype' foreach qw(mediatype);
    $_properties{'tagpool_file_'.($_ =~ tr/-/_/r)}{rawtype} = 'filename' foreach qw(thumbnail);


    %_tagpool_directory_setting_tagmap = (
        'thumbnail-mode' => {
            'file-uri'      => 'e4c80ac0-7c71-4548-9e84-9422bf1dae11',
            'tag-uri'       => '0025b1b2-20db-40e6-9345-baf0f9b5e166',
            'tag'           => '30c09ebd-bc14-48a3-8c0f-2d66c3d6e429',
            'throw-filter'  => 'c4438812-6011-42ee-984a-183745d9b013',
        },
        'update-mode' => {
            'add'           => 'dd1ff55a-fd87-428d-bd7e-57fc56488e72',
            'throw'         => '41217e01-4468-4d54-b613-902835ae0596',
        },
        'add-mode' => {
            'all'           => '65de001a-9063-4591-8b67-99ee1f91c4dd',
            'no-boring'     => 'db7c2ac0-4205-4f99-8556-c48cbb51138e',
            'none'          => '36fd66fd-b07f-4010-b796-05b488826571',
        },
        'file-tags' => {
            'root'                      => '908c9015-b760-441e-85bf-ba98b5ff452b',
            'level'                     => '53e36ce9-8afb-425e-9cae-2016cbdc27fe',
            'root-and-level'            => 'f8733429-8dc8-493b-8b91-958c6485afeb',
            'parent-and-level'          => 'e2cbc030-447a-4ee3-8adc-5b84c0400038',
            'root-and-parent-and-level' => 'fe58aa1a-4cd7-49ca-a11d-ceab5223ccd9',
        },
        'tag-mode' => {
            'random'        => '02110f2e-b2c1-45a8-910b-0210f87cb7a1',
            'named-random'  => '7c6b6534-bd85-40c6-99f0-c0d308f790b6',
            'namebased'     => '39a2be03-7d07-41c4-93da-815c5f5d6f8d',
        },
        'tag-implies' => {
            'root'                      => '60384e20-8d88-4171-970b-560ddafc1f95',
            'parent'                    => '5e5acf8e-4e07-4ce9-8516-a014a7fbf91a',
            'root-and-parent'           => '112db395-84c3-4711-b99f-b5c6d6051781',
        },
        'entry-sort-order' => {
            'asc'           => '994e3f9c-79c1-40d1-892f-d66d406538a1',
            'desc'          => '54140078-a52a-4693-9f66-30b4ac4f1da4',
        },
    );

    foreach my $setting (values %_tagpool_directory_setting_tagmap) {
        foreach my $entry (values %{$setting}) {
            $entry = {ise => $entry} unless ref $entry;
        }
    }
}

{
    my %_wk = (
        # tagpool-sysfile-type:
        'e6d6bb07-1a6a-46f6-8c18-5aa6ea24d7cb' => {displayname => 'regular'},
        '577c3095-922b-4569-805d-a5df94686b35' => {displayname => 'directory'},
        '76ae899c-ad0c-4bbc-b693-485f91779b9f' => {displayname => 'symlink'},
        'f1765bfc-96d5-4ff3-ba2e-16a2a9f24cb3' => {displayname => 'blockdevice'},
        '241431a9-c83f-4bce-93ff-0024021cd754' => {displayname => 'characterdevice'},
        '3d680b7b-115c-486a-a186-4ad77facc52e' => {displayname => 'fifo'},
        '3d1cb160-5fc5-4d8e-a8d3-3b0ec85bb000' => {displayname => 'socket'},

        # write-mode:
        '7b177183-083c-4387-abd3-8793eb647373' => {displayname => 'none'},
        '3877b2ef-6c77-423f-b15f-76508fbd48ed' => {displayname => 'random access'},
        '4dc9fd07-7ef3-4215-8874-31d78ed55c22' => {displayname => 'append only'},

        # Final states:
        'f418cdb9-64a7-4f15-9a18-63f7755c5b47' => {displayname => 'final'},
        'cb9c2c8a-b6bd-4733-80a4-5bd65af6b957' => {displayname => 'auto-final'},

        # ValueFile:
        '54bf8af4-b1d7-44da-af48-5278d11e8f32' => {displayname => 'ValueFile'},
        'e5da6a39-46d5-48a9-b174-5c26008e208e' => {displayname => 'tagpool-source-format'},
        'afdb46f2-e13f-4419-80d7-c4b956ed85fa' => {displayname => 'tagpool-taglist-format-v1'},
        '25990339-3913-4b5a-8bcf-5042ef6d8b5e' => {displayname => 'tagpool-httpd-htdirectories-format'},
        '11431b85-41cd-4be5-8d88-a769ebbd603f' => {displayname => 'tagpool-directory-info-format'},

        #'' => {displayname => ''},
    );

    foreach my $setting (values %_tagpool_directory_setting_tagmap) {
        foreach my $key (keys %{$setting}) {
            my $value = $setting->{$key};
            $value->{displayname} //= $key;
            $_wk{$value->{ise}} = $value;
        }
    }

    while (my ($mediatype, $ise) = each %File::Information::Base::_mediatypes) {
        ($_wk{$ise} //= {})->{displayname} //= $mediatype;
    }


    while (my ($key, $value) = each %_wk) {
        Data::Identifier->new(ise => $key, %{$value})->register;
    }

    foreach my $value (values %_URLZONE) {
        Data::Identifier->new(ise => $value->{ise}, displayname => $value->{displayname})->register;
    }
}

if ($HAVE_CONFIG_INI_READER) {
    $_properties{'zonetransfer_'.lc($_)} = {loader => \&_load_zonetransfer, zonetransfer_key => $_} foreach qw(HostIpAddress ZoneId ReferrerUrl HostUrl);
}

{
    my %_S_IS_to_tagpool_ise = (
        S_ISREG  => 'e6d6bb07-1a6a-46f6-8c18-5aa6ea24d7cb',
        S_ISDIR  => '577c3095-922b-4569-805d-a5df94686b35',
        S_ISLNK  => '76ae899c-ad0c-4bbc-b693-485f91779b9f',
        S_ISBLK  => 'f1765bfc-96d5-4ff3-ba2e-16a2a9f24cb3',
        S_ISCHR  => '241431a9-c83f-4bce-93ff-0024021cd754',
        S_ISFIFO => '3d680b7b-115c-486a-a186-4ad77facc52e',
        S_ISSOCK => '3d1cb160-5fc5-4d8e-a8d3-3b0ec85bb000',
    );

    $_properties{tagpool_inode_type} = {loader => sub {
            my ($self, undef, %opts) = @_;
            if ($opts{lifecycle} eq 'current') {
                my $mode = $self->get('st_mode', default => undef, as => 'raw');
                my $ise;

                if (defined($mode)) {
                    foreach my $key (keys %_S_IS_to_tagpool_ise) {
                        my $func = __PACKAGE__->can($key);
                        if (defined $func) {
                            if (eval {$func->($mode)}) {
                                $ise = $_S_IS_to_tagpool_ise{$key};
                                last;
                            }
                        }
                    }
                }

                if (defined $ise) {
                    (($self->{properties_values} //= {})->{current} //= {})->{tagpool_inode_type} = {raw => $ise};
                }
            }
        }, rawtype => 'ise'},
}

sub _new {
    my ($pkg, %opts) = @_;
    my $self = $pkg->SUPER::_new(%opts, properties => \%_properties);

    croak 'No handle is given' unless defined $self->{handle};

    return $self;
}


#@returns File::Information::Filesystem
sub filesystem {
    my ($self, %opts) = @_;
    my $filesystem = $self->{filesystem} //= eval {
        my $instance = $self->instance;
        my $st_dev = $self->get('st_dev');
        $instance->_filesystem_for($st_dev);
    };

    return $filesystem if defined $filesystem;
    return $opts{default} if exists $opts{default};
    croak 'Cannot locate filesystem for inode';
}


sub tagpool {
    my ($self) = @_;
    my $tagpools = $self->{_tagpools} //= do {
        my $pools = $self->instance->_tagpool;
        [map {$pools->{$_}} keys %{$self->_tagpool_paths}]
    };

    return wantarray ? @{$tagpools} : ($tagpools->[0] // croak 'Not part of any tagpool');
}


sub peek {
    my ($self, %opts) = @_;
    my $wanted = $opts{wanted} || 0;
    my $required = $opts{required} || 0;
    my $buffer;

    if (defined($self->{_peek_buffer}) && length($self->{_peek_buffer}) >= $required) {
        return $self->{_peek_buffer};
    }

    $wanted = $required if $required > $wanted;
    $wanted = 4096 if $wanted < 4096; # enforce some minimum

    croak 'Requested peek too big: '.$wanted if $wanted > 65536;

    $self->_get_fh->read($buffer, $wanted);

    croak 'Cannot peek required amount of data' if length($buffer) < $required;

    return $self->{_peek_buffer} = $buffer;
}

# ----------------

sub _get_fh {
    my ($self) = @_;
    my $fh = $self->{handle};

    $fh->seek(0, SEEK_SET) or croak $!;

    return $fh;
}

sub _tagpool_paths {
    my ($self) = @_;

    unless (defined $self->{_tagpool_paths}) {
        my File::Information $instance = $self->instance;
        my $sysfile_cache = $instance->_tagpool_sysfile_cache;
        my @stat;
        my %paths;
        my $found;

        return unless scalar @{$instance->_tagpool_path};

        @stat = eval {stat($self->{handle})};
        return $self->{_tagpool_paths} = {} unless scalar(@stat) && S_ISREG($stat[2]);

        # Try the cache first:
        {
            my $key = $stat[1].'@'.$stat[0];

            foreach my $pool_path (keys %{$sysfile_cache}) {
                $found = $sysfile_cache->{$pool_path}{$key};
                if (defined $found) {
                    $paths{$pool_path} = $found;
                }
            }
        }

        # Then guess:
        unless (defined($found)) {
            if (defined $self->{path}) {
                outer:
                foreach my $uuid ($self->{path} =~ /([0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12})/g) {
                    foreach my $pool_path (@{$instance->_tagpool_path}) {
                        my $info_path = File::Spec->catdir($pool_path => 'data', 'info.'.$uuid);
                        my $info;

                        next unless -f $info_path;
                        $info = eval {
                            my $reader = File::ValueFile::Simple::Reader->new($info_path, supported_formats => [], supported_features => []);
                            $reader->read_as_simple_tree;
                        };

                        if (defined($info) && defined($info->{'pool-name-suffix'})) {
                            my $local_cache = $sysfile_cache->{$pool_path} //= {};
                            my @c_stat = stat(File::Spec->catfile($pool_path, 'data', $info->{'pool-name-suffix'}));

                            next unless scalar @c_stat;

                            $local_cache->{$c_stat[1].'@'.$c_stat[0]} = $info->{'pool-name-suffix'};

                            if ($c_stat[0] eq $stat[0] && $c_stat[1] eq $stat[1]) {
                                $found = $info->{'pool-name-suffix'};
                                $paths{$pool_path} = $found;
                            }
                        }
                    }
                }
            }
        }

        # Then try the pool:
        unless (defined($found)) {
            outer:
            foreach my $pool_path (@{$instance->_tagpool_path}) {
                my $data_path = File::Spec->catdir($pool_path => 'data');
                my $local_cache = $sysfile_cache->{$pool_path} //= {};

                next if $local_cache->{complete};

                if (opendir(my $dir, $data_path)) {
                    my @c_stat = stat($dir);

                    next if $c_stat[0] ne $stat[0];

                    while (my $entry = readdir($dir)) {
                        $entry =~ /^file\./ or next; # skip everything that is not a file.* to begin with.

                        @c_stat = stat(File::Spec->catfile($data_path, $entry));
                        next unless scalar @c_stat;

                        $local_cache->{$c_stat[1].'@'.$c_stat[0]} = $entry;

                        if ($c_stat[0] eq $stat[0] && $c_stat[1] eq $stat[1]) {
                            $found = $entry;
                            $paths{$pool_path} = $found;
                        }
                    }

                    $local_cache->{complete} = 1;
                }
            }
        }

        $self->{_tagpool_paths} = \%paths;
    }

    return $self->{_tagpool_paths};
}

sub _load_stat {
    my ($self, undef, %opts) = @_;
    if ($opts{lifecycle} eq 'current' && !$self->{_loaded_stat}) {
        my $pv = ($self->{properties_values} //= {})->{current} //= {};
        my @values = eval {stat($self->{handle})};
        my @keys = qw(st_dev st_ino st_mode st_nlink st_uid st_gid st_rdev st_size st_atime st_mtime st_ctime st_blksize st_blocks);

        if (scalar @values) {
            for (my $i = 0; $i < scalar(@keys); $i++) {
                my $value = $values[$i];
                my $key = $keys[$i];

                next if $key eq ':skip';
                next if $value eq '';
                next if $value == 0 && ($key eq 'st_ino' || $key eq 'st_rdev' || $key eq 'st_blksize');
                next if $value < 0;

                $pv->{$key} = {raw => $values[$i]};
            }

            $pv->{stat_readonly} = {raw => !($values[2] & (S_IWUSR|S_IWGRP|S_IWOTH))};
            $pv->{stat_cachehash} = {raw => $values[1].'@'.$values[0]} if $values[1] > 0 && $values[0] ne '';
        }

        $self->{_loaded_stat} = 1;
    }
}

sub _load_contentise {
    my ($self, $key, %opts) = @_;
    my $lifecycle = $opts{lifecycle};
    my $pv = ($self->{properties_values} //= {})->{$lifecycle} //= {};
    my $digest_sha_1_160 = $self->digest('sha-1-160', as => 'utag', lifecycle => $lifecycle, default => undef);
    my $digest_sha_3_512 = $self->digest('sha-3-512', as => 'utag', lifecycle => $lifecycle, default => undef);

    if (defined $digest_sha_3_512) {
        my $id = Data::Identifier::Generate->generic(namespace => '66d488c0-3b19-4e6c-856f-79edf2484f37', input => $digest_sha_3_512);
        $pv->{content_sha_3_512_uuid} = {raw => $id->uuid};
    }

    if (defined($digest_sha_1_160) && defined($digest_sha_3_512)) {
        my $digest = $digest_sha_1_160.' '.$digest_sha_3_512;
        $digest =~ s/^v0 /v0m /;
        my $id = Data::Identifier::Generate->generic(namespace => '66d488c0-3b19-4e6c-856f-79edf2484f37', input => $digest);
        $pv->{content_sha_1_160_sha_3_512_uuid} = {raw => $id->uuid};
    }
}

sub _load_xattr {
    my ($self, $key, %opts) = @_;
    my $info = $self->{properties}{$key};
    my $lifecycle = $info->{lifecycle} // 'current';
    my $pv = ($self->{properties_values} //= {})->{$lifecycle} //= {};
    my $value;
    my $fh;

    return unless ($opts{lifecycle} // 'current') eq $lifecycle;

    croak 'Not supported, requires File::ExtAttr' unless $HAVE_XATTR;

    $self->{_loaded_xattr} //= {};
    return if $self->{_loaded_xattr}{$key};
    $self->{_loaded_xattr}{$key} = 1;

    $fh = File::Information::Inode::_DUMMY_FOR_XATTR->new($self->{handle});
    $value = eval {File::ExtAttr::getfattr($fh, $info->{xattr_key})};

    return unless defined($value) && length($value);

    $pv->{$key} = {raw => $value};

    if (defined(my $parts = $info->{parts})) {
        my @values = split(/\s+/, $value);
        my $out = $pv->{$key};

        for (my $i = 0; $i < scalar(@{$parts}); $i++) {
            if (defined($values[$i]) && length($values[$i])) {
                $out->{$parts->[$i]} = $values[$i];
            }
        }
        $out->{rawtype} = 'multipart';
    }

    if (defined(my $parsing = $info->{parsing})) {
        if ($parsing eq 'utag') {
            my $v = $value;
            my %digest;
            my $given_size;

            $given_size = $self->_set_digest_utag($lifecycle => $v, $given_size);

            $pv->{xattr_utag_final_file_hash_size} = {raw => $given_size} if defined $given_size;
            $self->{digest} //= {};

            {
                my $digests = $self->{digest}{$lifecycle} //= {};
                foreach my $algo (keys %digest) {
                    $digests->{$algo} //= $digest{$algo};
                }
            }
        }
    }
}

# Bad workaround for File::ExtAttr
package File::Information::Inode::_DUMMY_FOR_XATTR {
    sub new {
        my ($pkg, $fh) = @_;
        return bless \$fh;
    }
    sub isa {
        my ($self, $pkg) = @_;
        return 1 if $pkg eq 'IO::Handle';
        return $self->SUPER::isa($pkg);
    }
    sub fileno {
        my ($self) = @_;
        return ${$self}->fileno;
    }
}

sub _load_tagpool_directory {
    my ($self) = @_;
    my $pv = $self->{properties_values} //= {};
    my $tree;

    return if $self->{_loaded_tagpool_directory};
    $self->{_loaded_tagpool_directory} = 1;

    eval {
        my @stat = stat($self->{handle});

        if (scalar(@stat) && S_ISDIR($stat[2])) {
            my $c = $pv->{current} //= {};
            $c->{tagpool_directory_timestamp} = {raw => time()};

            $c->{tagpool_directory_inode} = {raw => $stat[1]};
            $c->{tagpool_directory_mtime} = {raw => $stat[9]};
        }
    };

    return unless defined $self->{path};
    return unless $HAVE_FILE_VALUEFILE;

    eval {
        my $path = File::Spec->catfile($self->{path}, '.tagpool-info', 'directory');
        my $reader = File::ValueFile::Simple::Reader->new($path, supported_formats => '11431b85-41cd-4be5-8d88-a769ebbd603f', supported_features => []);
        $tree = $reader->read_as_simple_tree;
    };

    if (defined $tree) {
        foreach my $key (qw(title comment description)) {
            my $value = $tree->{$key};
            if (defined($value) && !ref($value) && length($value)) {
                $pv->{current} //= {};
                $pv->{current}{'tagpool_directory_'.$key} = {raw => $value};
            }
        }

        foreach my $key (qw(inode mtime pool-uuid timestamp)) {
            foreach my $lifecycle (qw(initial last)) {
                my $value = $tree->{$lifecycle.'-'.$key};
                if (defined($value) && !ref($value) && length($value)) {
                    my $c = $pv->{$lifecycle} //= {};

                    $c->{'tagpool_directory_'.($key =~ tr/-/_/r)} = {raw => $value};
                }
            }
        }

        if (defined(my $setting = $tree->{'directory-setting'})) {
            foreach my $key (qw(thumbnail-uri thumbnail-mode update-mode add-mode file-tags tag-mode tag-implies entry-sort-order tag tag-root tag-parent tag-type entry-display-name entry-sort-key)) {
                my $value = $setting->{$key};
                if (defined($value) && !ref($value) && length($value)) {
                    my $val = {raw => $value};
                    $pv->{current} //= {};
                    $pv->{current}{'tagpool_directory_setting_'.($key =~ tr/-/_/r)} = $val;

                    # Add ise if known:
                    if (defined(my $info = $_tagpool_directory_setting_tagmap{$key})) {
                        if (defined(my $entry = $info->{$value})) {
                            $val->{ise} = $entry->{ise};
                        }
                    }
                }
            }
        }

        if (defined(my $option = $tree->{'throw-option'})) {
            foreach my $key (qw(linkname linktype filter)) {
                my $value = $option->{$key};
                if (defined($value) && !ref($value) && length($value)) {
                    $pv->{current} //= {};
                    $pv->{current}{'tagpool_directory_throw_option_'.$key} = {raw => $value};
                }
            }
        }
    }
}

sub _load_tagpool_file {
    my ($self) = @_;
    my File::Information $instance = $self->instance;
    my $sysfile_cache = $instance->_tagpool_sysfile_cache;
    my $pv = $self->{properties_values} //= {};
    my @stat;
    my $found;
    my $in_pool;

    return if $self->{_loaded_tagpool_file};
    $self->{_loaded_tagpool_file} = 1;

    return unless scalar @{$instance->_tagpool_path};

    @stat = eval {stat($self->{handle})};
    return unless scalar(@stat) && S_ISREG($stat[2]);

    {
        my $c = $pv->{current} //= {};
        $c->{tagpool_file_timestamp} = {raw => time()};

        $c->{tagpool_file_inode} = {raw => $stat[1]};
        $c->{tagpool_file_size}  = {raw => $stat[7]};
        $c->{tagpool_file_mtime} = {raw => $stat[9]};
    }

    # Try to find the file:
    ($in_pool, $found) = %{$self->_tagpool_paths};

    return unless defined($in_pool) && defined($found);

    if ($found =~ /^file\.([0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12})(?:\..*)?$/) {
        my $uuid = $1;
        my $info = eval {
            my $path = File::Spec->catfile($in_pool, 'data' => 'info.'.$uuid);
            my $reader = File::ValueFile::Simple::Reader->new($path, supported_formats => [], supported_features => []);
            $reader->read_as_simple_tree;
        };
        my $tags = eval {
            my $path = File::Spec->catfile($in_pool, 'data' => 'tags.'.$uuid);
            my $reader = File::ValueFile::Simple::Reader->new($path, supported_formats => [], supported_features => []);
            $reader->read_as_hash_of_arrays;
        };
        if (defined($info) && defined($tags)) {
            $pv->{current} //= {};
            $pv->{current}{tagpool_file_uuid} = {raw => $uuid};

            foreach my $key (qw(title comment description original-url original-description-url pool-name-suffix original-filename)) {
                my $value = $info->{$key};
                if (defined($value) && !ref($value) && length($value)) {
                    $pv->{current}{'tagpool_file_'.($key =~ tr/-/_/r)} = {raw => $value};
                }
            }

            foreach my $key (qw(mtime timestamp inode size actual-size)) {
                foreach my $lifecycle (qw(initial last final)) {
                    my $value = $info->{$lifecycle.'-'.$key};
                    if (defined($value) && !ref($value) && length($value)) {
                        my $c = $pv->{$lifecycle} //= {};

                        $c->{'tagpool_file_'.($key =~ tr/-/_/r)} = {raw => $value};
                    }
                }
            }

            # Digest:
            foreach my $key (keys %{$info}) {
                if (my ($lifecycle, $tagpool_name) = $key =~ /^(initial|last|final)-hash-(.+)$/) {
                    my $utag_name = $File::Information::Base::_digest_name_converter{$tagpool_name} or next;
                    my $value = $info->{$key};
                    my ($size) = $utag_name =~ /-([0-9]+)$/ or next;

                    next unless $value =~ /^[0-9a-f]+$/;
                    next unless length($value) == ($size / 4);
                    $self->{digest} //= {};
                    $self->{digest}{$lifecycle} //= {};
                    $self->{digest}{$lifecycle}{$utag_name} = $value;
                }
            }

            # Tags:
            {
                my @next = @{$tags->{'tagged-as'} // []};

                $pv->{current}{tagpool_file_tags} = [map {{raw => $_}} @next];

                while (scalar(@next)) {
                    my @current = @next;
                    @next = ();

                    foreach my $tag (@current) {
                        my $info = $_wk_tagged_as_tags{$tag};
                        next unless defined($info) && defined($info->{for});

                        if ($info->{for} eq 'write-mode') {
                            $pv->{current}{tagpool_file_write_mode} = {raw => $tag};
                        } elsif ($info->{for} eq 'mediatype') {
                            $pv->{current}{tagpool_file_mediatype} = {raw => $info->{mediatype}, ise => $tag};
                        } elsif ($info->{for} eq 'finalmode') {
                            $pv->{current}{tagpool_file_finalmode} = {raw => $tag};
                        } else {
                            croak 'BUG!';
                        }

                        push(@next, @{$info->{implies}}) if defined $info->{implies};
                    }
                }
            }

            # Media Type:
            {
                my $value = readlink(File::Spec->catfile($in_pool, qw(cache mimetype file), $uuid));
                if (defined($value) && length($value)) {
                    $pv->{current}{tagpool_file_mediatype} //= {raw => $value};
                }
            }

            # Write mode:
            {
                my $value = readlink(File::Spec->catfile($in_pool, qw(cache write-mode file), $uuid));
                if (defined($value) && length($value)) {
                    $pv->{current}{tagpool_file_write_mode} //= {raw => $value};
                }
            }

            {
                my $value = File::Spec->catfile($in_pool, qw(cache thumbnail file), $uuid.'.png');
                my @c_stat = stat($value);
                if (scalar(@c_stat)) {
                    if ($stat[9] < $c_stat[9]) {
                        $pv->{current}{tagpool_file_thumbnail} //= {raw => $value};
                    }
                }
            }
        }
    }
}

sub _load_magic {
    my ($self) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};
    my $data;
    my $media_type;

    return if $self->{_loaded_magic};
    $self->{_loaded_magic} = 1;

    $data = eval {$self->peek};

    return unless defined $data;

    if (substr($data, 0, 22) eq '<!DOCTYPE HTML PUBLIC ' || substr($data, 0, 22) eq '<!DOCTYPE html PUBLIC ' || substr($data, 0, 22) eq '<!DOCTYPE HTML SYSTEM ' || uc(substr($data, 0, 15)) eq '<!DOCTYPE HTML>' ||
        lc(substr($data, 0, 6)) eq '<html>' ||
        $data =~ /^<\?xml version="1\.0" encoding="utf-8"\?>\r?\n?<\!DOCTYPE html PUBLIC /) {
        $media_type = 'text/html';
    } elsif ($data =~ /^<\?xml version="1\.0" encoding="UTF-8"\?>\s*<office:document xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1\.0"[^>]+office:mimetype="(application\/vnd\.oasis\.opendocument\.(?:text|spreadsheet|presentation|graphics|chart|formula|image|text-master|(?:text|spreadsheet|presentation|graphics)-template))"[^>]*>/) {
        $media_type = $1;
    } elsif ($data =~ /^PK\003\004....\0\0................\010\0\0\0mimetype(application\/vnd\.oasis\.opendocument\.(?:text|spreadsheet|presentation|graphics|chart|formula|image|text-master|(?:text|spreadsheet|presentation|graphics)-template))PK\003\004/) {
        $media_type = $1;
    } elsif (substr($data, 0, 8) eq "!<arch>\n") {
        if ($data =~ /^!<arch>\ndebian-binary   [0-9 ]{12}0     0     [0-7 ]{8}[0-9]         `\n/) {
            $media_type = 'application/vnd.debian.binary-package';
        } else {
            $media_type = 'application/x-archive';
        }
    } elsif ($data =~ /^!!ValueFile ([0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12})\s+(!null|[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}|[0-2](?:\.(?:0|[1-9][0-9]*))+|[a-zA-Z][a-zA-Z0-9\+\.\-]+[^\s%]+)[\s\r\n]/) {
        my ($version, $format) = ($1, $2);
        $pv->{magic_valuefile_version} = {raw => $version};
        $pv->{magic_valuefile_format}  = {raw => $format} unless $format =~ /^!/;
    } elsif ($data =~ /^\0([\x07-\x3f])VM\x0d\x0a\xc0\x0a/ && (ord($1) & 07) == 07) {
        $media_type = 'application/vnd.sirtx.vmv0';
    } elsif ($data =~ /^RIFF.{4}WEBPVP8/) {
        $media_type = 'image/webp';
    } else {
        foreach my $magic (sort {length($b) <=> length($a)} keys %_magic_map) {
            if (substr($data, 0, length($magic)) eq $magic) {
                $media_type = $_magic_map{$magic};
                last;
            }
        }
    }

    $pv->{magic_mediatype} = {raw => $media_type} if defined $media_type;
}

sub _load_db {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    return if $self->{_loaded_db};
    $self->{_loaded_db} = 1;

    if (defined(my $db = eval { $self->instance->db })) {
        eval {
            my $inode = $self->get('st_ino', as => 'raw');
            my $fs    = $self->filesystem->get('ise', as => 'Data::TagDB::Tag');
            my $inode_number = $db->tag_by_id(uuid => 'd2526d8b-25fa-4584-806b-67277c01c0db');
            my $also_on_filesystem = $db->tag_by_id(uuid => 'cd5bfb11-620b-4cce-92bd-85b7d010f070');
            my $wk = $db->wk;
            my $metadata = $db->metadata(relation => $wk->also_shares_identifier, type => $inode_number, data_raw => $inode);
            my $res;

            #warn sprintf('inode=%s, inode_number=%s, fs=%s', $inode, $inode_number, $fs);
            $metadata->foreach(sub {
                    my ($entry) = @_;
                    my $fs_relation = $db->relation(tag => $entry->tag, relation => $also_on_filesystem, related => $fs)->one;
                    $res = $entry->tag;
                    #warn $fs_relation;
                });

            $pv->{db_inode_tag} = {raw => $res} if defined $res;
        };
    }
}

sub _load_redirect {
    my ($self, $key, %opts) = @_;
    my $info = $self->{properties}{$key};

    $self->get($info->{redirect}, lifecycle => $opts{lifecycle}, default => undef, as => 'raw');
}

sub _load_zonetransfer {
    my ($self, $key, %opts) = @_;
    my $info = $self->{properties}{$key};
    my $pv = ($self->{properties_values} //= {})->{current} //= {};
    my $raw;
    my $parsed;

    return if $self->{_loaded_zonetransfer};
    $self->{_loaded_zonetransfer} = 1;

    if ($HAVE_XATTR) {
        my $fh = File::Information::Inode::_DUMMY_FOR_XATTR->new($self->{handle});
        $raw = eval {File::ExtAttr::getfattr($fh, 'Zone.Identifier')};
    }

    if (!defined($raw) && $^O eq 'MSWin32' && defined($self->{path})) {
        if (open(my $ads, '<', sprintf('%s:Zone.Identifier', $self->{path}))) {
            local $/ = undef;
            $raw = <$ads>;
            close($ads);
        }
    }

    return unless defined $raw;

    $parsed = Config::INI::Reader->read_string($raw);

    if (defined(my $ZoneTransfer = $parsed->{ZoneTransfer})) {
        foreach my $key (qw(HostIpAddress ZoneId ReferrerUrl HostUrl)) {
            my $value = $ZoneTransfer->{$key};

            next unless defined($value) && length($value);

            $pv->{'zonetransfer_'.lc($key)} = {raw => $value};

            if ($key eq 'ZoneId' && defined(my $zone = $_URLZONE{$value})) {
                $pv->{'zonetransfer_'.lc($key)}{ise} //= $zone->{ise};
            }
        }
    }
}

sub _load_ntfs_xattr {
    my ($self, $key, %opts) = @_;
    my $info = $self->{properties}{$key};
    my $pv = ($self->{properties_values} //= {})->{current} //= {};
    my $attrb;

    return if $self->{_loaded_ntfs_xattr};
    $self->{_loaded_ntfs_xattr} = 1;

    if ($HAVE_XATTR) {
        my $fh = File::Information::Inode::_DUMMY_FOR_XATTR->new($self->{handle});
        my $raw = eval {File::ExtAttr::getfattr($fh, 'ntfs_attrib_be', {namespace => 'system'})};
        $attrb = unpack('N', $raw) if defined $raw;
    }

    if (defined $attrb) {
        foreach my $key (keys %_ntfs_attributes) {
            $pv->{'ntfs_'.lc($key)} = {raw => ($attrb & $_ntfs_attributes{$key})};
        }
    }
}

sub _load_fstore {
    my ($self, $key, %opts) = @_;
    my $dev;
    my $inode;
    my @candidates;

    return if $self->{_loaded_fstore};
    $self->{_loaded_fstore} = 1;

    $dev    = $self->get('st_dev', default => undef);
    $inode  = $self->get('st_ino', default => undef);

    return unless defined($dev) && defined($inode);

    foreach my $store ($self->instance->store(as => 'File::FStore')) {
        foreach my $candidate ($store->query(properties => inode => $inode)) {
            my @stat = $candidate->stat;

            if (defined($stat[0]) && length($stat[0]) && $stat[0] != 0) {
                if (defined($stat[1]) && length($stat[1]) && $stat[1] > 0) {
                    if ($stat[0] == $dev && $stat[1] == $inode) {
                        push(@candidates, $candidate);
                    }
                }
            }
        }
    }

    if (scalar(@candidates)) {
        my $pv_current = ($self->{properties_values} //= {})->{current} //= {};
        my $pv_final   = ($self->{properties_values} //= {})->{final} //= {};

        $pv_current->{store_file} = [map {{raw => $_}} @candidates];
        $pv_final->{store_file} = [map {{raw => $_}} @candidates];
    }
}

sub _load_shebang {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    return if $self->{_loaded_shebang};
    $self->{_loaded_shebang} = 1;

    if ($self->peek =~ /^(#\!.+)\r?\n/) {
        my $line = $1;
        my $interpreter;

        $pv->{shebang_line} = {raw => $line};

        if ($line =~ m(^#\!(?:(?:/usr)?(?:/local)?/s?bin/)?env\s+(\S+)(\s.*)?$)) {
            $interpreter = $1;
            eval {
                require File::Which;

                $interpreter = File::Which::which($interpreter);

            };
        } elsif ($line =~ m(^#\!(\S+)(?:\s.*)?$)) {
            $interpreter = $1;
        }

        $pv->{shebang_interpreter} = {raw => $interpreter} if defined($interpreter) && length($interpreter);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Information::Inode - generic module for extracting information from filesystems

=head1 VERSION

version v0.13

=head1 SYNOPSIS

    use File::Information;

    my File::Information $instance = File::Information->new(%config);

    my File::Information::Inode $inode = $instance->for_handle($handle);

    my File::Information::Inode $inode = $instance->for_link($path)->inode;

B<Note:> This package inherits from L<File::Information::Base>.

This module represents an inode on a filesystem. An inode contains basic file metadata (such as type and size) and the file's content.
Inodes are commonly represented by an inode number (but this is subject to filesystem implementation and limitations).
In order to access inodes they most commonly need to have at least one hardlink pointing to them.
See also L<File::Information::Link>.

=head1 METHODS

=head2 filesystem

    my File::Information::Filesystem $filesystem = $inode->filesystem([ %opts ]);

Provides access to the filesystem object for the filesystem this inode is on.
Dies if no filesystem could be found.

Takes the following options (all optional):

=over

=item C<default>

The value to be returned when no filesystem could be found.
This can also be C<undef> which switches
from C<die>-ing when no value is available to returning C<undef>.

=back

=head2 tagpool

    my File::Information::Tagpool $tagpool = $inode->tagpool;
    # or:
    my                            @tagpool = $inode->tagpool;

This method returns any tagpool instances this file is part of.
If called in scalar context only one is returned and if none have been found this function C<die>s.
If called in list context the list is returned and an empty list is returned in case none have been found.

If called in scalar context it is not clear which is returned in case the file is part of multiple pools.
However the result is cached and for the same instance of this object always the same tagpool instance is returned.

=head2 peek

    my $data = $inode->peek( [ %opts ] );

Peeks the first few bytes of a file. The main usage of this method is to check for magic numbers.

The following options (all optional) are supported:

=over

=item C<wanted>

The number of bytes wanted. If this number of bytes can't be provided less is returned.

=item C<required>

The number of bytes that are needed. If this number of bytes can't be provided the method C<die>s.

=back

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
