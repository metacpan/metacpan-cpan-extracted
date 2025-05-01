# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Module for interacting with file stores


package File::FStore::File;

use v5.10;
use strict;
use warnings;

use Carp;
use Fcntl qw(SEEK_SET S_IWUSR S_IWGRP S_IWOTH);
use File::Spec;

use Data::Identifier;
use Data::Identifier::Generate;

use File::FStore;

use parent qw(File::FStore::Base Data::Identifier::Interface::Known);

use constant {
    WRITE_BITS  => S_IWUSR|S_IWGRP|S_IWOTH,
    RE_ISE      => qr<^(?:[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}|[1-3](?:\.(?:0|[1-9][0-9]*))+|[a-zA-Z][a-zA-Z0-9\+\.\-]+:.*)$>,
};

our $VERSION = v0.05;

my @_xattr_hashes = qw(sha-1-160 sha-2-256 sha-3-512);

my %_valid_properties = (
    size            => qr<^(?:0|[1-9][0-9]*)$>,
    inode           => qr<>, # any
    mediasubtype    => qr<^(?:application|audio|example|font|haptics|image|message|model|multipart|text|video)/[0-9a-zA-Z][0-9a-zA-Z\!\#\$\&\-\^_\.\+]{0,126}$>,
    contentise      => RE_ISE,
    inodeise        => RE_ISE,
);

my %_exts = (
    'image/jpeg'                => 'jpg',
    'image/png'                 => 'png',
    'image/gif'                 => 'gif',
    'image/vnd.microsoft.icon'  => 'ico',
    'audio/flac'                => 'flac',
    'application/pdf'           => 'pdf',
    'application/zip'           => 'zip',
    'text/plain'                => 'txt',
);

my %_db_tags = (
    # well known tags:
    final_file_size     => Data::Identifier->new(uuid => '1cd4a6c6-0d7c-48d1-81e7-4e8d41fdb45d'),
    final_file_encoding => Data::Identifier->new(uuid => '448c50a8-c847-4bc7-856e-0db5fea8f23b'),
    final_file_hash     => Data::Identifier->new(uuid => '79385945-0963-44aa-880a-bca4a42e9002'),
    also_has_role       => Data::Identifier->new(uuid => 'd2750351-aed7-4ade-aa80-c32436cc6030'),
    also_has_state      => Data::Identifier->new(uuid => '4c426c3c-900e-4350-8443-e2149869fbc9'),
    has_final_state     => Data::Identifier->new(uuid => '54d30193-2000-4d8a-8c28-3fa5af4cad6b'),
    specific_proto_file_state => Data::Identifier->new(uuid => '63da70a8-78a4-51b0-8b87-86872b474a5d'),
);


sub dbname {
    my ($self) = @_;
    return $self->{dbname} //= do {
        my $sth = $self->_prepare('SELECT filename FROM file WHERE id = ?');
        my $res;

        $sth->execute($self->{dbid});
        $res = $sth->fetchall_arrayref;

        $res->[0][0] // croak 'Database error';
    };
}


sub filename {
    my ($self) = @_;
    return $self->{filename} //= do {
        $self->store->_file(qw(v2 store), $self->dbname);
    };
}


sub open {
    my ($self) = @_;
    my $fh = $self->_open;

    $self->stat;
    $self->_detach_fh;

    return $fh;
}


sub link_out {
    my ($self, $filename) = @_;
    link($self->filename, $filename) or croak $!;
}


sub symlink_out {
    my ($self, $filename) = @_;
    symlink($self->filename, $filename) or croak $!;
}


sub update {
    my ($self, %opts) = @_;
    my File::FStore $store = $self->store;
    my $no_digests  = delete($opts{no_digests});
    my $on_pre_set  = delete($opts{on_pre_set});
    my $on_post_set = delete($opts{on_post_set});
    my $inode;
    my $properties;
    my $digests;

    croak 'Stray options passed' if scalar keys %opts;

    $store->_init_link_style;

    $store->in_transaction(rw => sub {
            my $fh = $self->_open;

            delete $self->{stat}; #clear stat cache.

            $inode = $self->as('File::Information::Inode');

            # Perform a verify via File::Information
            unless ($no_digests) {
                my $verify_result = $inode->verify;
                unless ($verify_result->has_passed || $verify_result->has_no_data || $verify_result->has_insufficient_data) {
                    croak sprintf('File (%s) is in bad state: %s', $self->dbname, $verify_result->status);
                }
            }

            # Perform a verify with our own data.
            {
                my $data = $self->get;
                my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
                    $atime,$mtime,$ctime,$blksize,$blocks) = $self->stat;

                $properties = $data->{properties} //= {};
                $digests = $data->{digests} //= {};

                $properties->{size} //= $size;
                croak 'Size missmatch' if $properties->{size} != $size;
                $properties->{inode} //= $ino;
                croak 'inode missmatch' if $properties->{inode} != $ino;

                # Load some basic properties, first the final values, than the current ones.
                foreach my $lifecycle (qw(final current)) {
                    if (defined(my $v = $inode->get('size', lifecycle => $lifecycle, default => undef))) {
                        $properties->{size} //= $v;
                        croak 'Size missmatch' if $properties->{size} != $v;
                    }

                    if (defined(my $v = $inode->get('mediatype', lifecycle => $lifecycle, default => undef, as => 'mediatype'))) {
                        $properties->{mediasubtype} //= $v;
                        croak sprintf('Media subtype missmatch on (%s): "%s" vs. "%s"', $self->dbname, $properties->{mediasubtype}, $v) if $properties->{mediasubtype} ne $v;
                    }

                    if (defined(my $v = $inode->get('inodeise', lifecycle => $lifecycle, default => undef, as => 'mediatype'))) {
                        $properties->{inodeise} //= $v;
                        # XXX:  We ignore missmatches here. This can be for a number of reasons. Such as switches between different sources of the value.
                        # TODO: A better policy should be implemented later on.
                    }

                    if (defined(my $v = $inode->get('st_ino', lifecycle => $lifecycle, default => undef))) {
                        $properties->{inode} //= $v;
                        croak 'inode missmatch' if $properties->{inode} != $v;
                    }
                }

                # First load all known final ones.
                foreach my $digest (@{$self->_used_digests}) {
                    if (defined(my $v = $inode->digest($digest, lifecycle => 'final', default => undef))) {
                        $digests->{$digest} //= $v;
                        croak 'Digest missmatch for '.$digest if $digests->{$digest} ne $v;
                    }
                }

                # Then test against the current ones.
                unless ($no_digests) {
                    foreach my $digest (@{$self->_used_digests}) {
                        if (defined(my $v = $inode->digest($digest, default => undef))) {
                            $digests->{$digest} //= $v;
                            croak 'Digest missmatch for '.$digest if $digests->{$digest} ne $v;
                        }
                    }
                }

                if (defined(my $contentise = eval {$self->_calculate_contentise($data)->uuid})) {
                    $properties->{contentise} //= $contentise;
                    croak 'Content ISE missmatch' if $properties->{contentise} ne $contentise;
                }

                $on_pre_set->($self) if defined $on_pre_set;
                $self->set($data);
            }

            # Create symlinks:
            if ((my $link_style = $store->setting('link_style')) ne 'none') {
                state $up = File::Spec->updir;
                my $dbname = $self->dbname;
                my $level = $link_style =~ /^([0-9]+)-level$/ ? int($1): 1;
                my $filename = File::Spec->catfile(( map {$up} 0 .. $level), 'store', $dbname);

                foreach my $fn ($self->_linknames($digests, $link_style)) {
                    next if -l $fn;
                    symlink($filename, $fn) or croak $!;
                }
            }

            if (defined(my $handle = File::FStore::File::_DUMMY_FOR_XATTR->new($fh))) {
                if (defined($properties->{size}) && !defined($handle->getfattr('utag.final.file.size'))) {
                    $handle->setfattr('utag.final.file.size' => $properties->{size});
                }

                if (defined($properties->{mediasubtype}) && !defined($handle->getfattr('mime_type'))) {
                    $handle->setfattr('mime_type' => $properties->{mediasubtype});
                }

                if (defined($properties->{mediasubtype}) && !defined($handle->getfattr('utag.final.file.encoding'))) {
                    my $v = Data::Identifier::Generate->generic(
                        namespace => '50d7c533-2d9b-4208-b560-bcbbf75ce3f9',
                        input => $properties->{mediasubtype},
                    )->uuid;
                    $handle->setfattr('utag.final.file.encoding' => $v);
                }

                if (!defined($handle->getfattr('utag.write-mode'))) {
                    $handle->setfattr('utag.write-mode' => '7b177183-083c-4387-abd3-8793eb647373');
                }

                if (!defined($handle->getfattr('utag.final-mode'))) {
                    $handle->setfattr('utag.final-mode' => 'f418cdb9-64a7-4f15-9a18-63f7755c5b47');
                }

                if (defined(my $size = $properties->{size}) && !defined($handle->getfattr('utag.final.file.hash'))) {
                    my @el;
                    my $v = '';

                    foreach my $algo (@_xattr_hashes) {
                        push(@el, sprintf(' %s bytes 0-%u/%u %s', $algo, $size - 1, $size, $digests->{$algo} // next));
                    }

                    for (my $i = 0; $i < scalar(@el); $i++) {
                        $v .= ' ' if $i;
                        $v .= $i == $#el ? 'v0' : 'v0m';
                        $v .= $el[$i];
                    }

                    $handle->setfattr('utag.final.file.hash' => $v) if length $v;
                }
            }

            # Try to alter the file mode to make the file read only.
            {
                my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
                    $atime,$mtime,$ctime,$blksize,$blocks) = $self->stat;

                if (defined($mode) && ($mode & WRITE_BITS)) {
                    my $n = $mode & (07777 ^ WRITE_BITS);
                    eval { chmod($n, $fh) }; # we don't care if it fails.
                }
            }

            $on_post_set->($self) if defined $on_post_set;
        });
}


sub stat {
    my ($self) = @_;

    $self->{stat} //= do {
        my @s;

        if (defined $self->{fh}) {
            @s = stat($self->{fh});
        } else {
            @s = stat($self->filename);
        }

        croak 'File missing on filesystem, store is corruped: '.$self->dbname unless scalar(@s);

        \@s;
    };

    return @{$self->{stat}};
}


sub get {
    my ($self, $domain, $key) = @_;
    if (defined($domain)) {
        if (defined($key)) {
            my $sth;
            my $res;

            if ($domain eq 'properties') {
                $sth = $self->_prepare('SELECT value FROM file_properties WHERE file = ? AND key = ?');
            } elsif ($domain eq 'digests') {
                $sth = $self->_prepare('SELECT hash FROM file_hash WHERE file = ? AND algo = ?');
            }

            croak 'Invalid domain: '.$domain unless defined $sth;

            $sth->execute($self->{dbid}, $key);
            $res = $sth->fetchall_arrayref;

            return $res->[0][0] // croak 'No value for domain '.$domain.' key '.$key;
        } else {
            my $sth;
            my %res;

            if ($domain eq 'properties') {
                $sth = $self->_prepare('SELECT key,value FROM file_properties WHERE file = ?');
            } elsif ($domain eq 'digests') {
                $sth = $self->_prepare('SELECT algo,hash FROM file_hash WHERE file = ?');
            }

            croak 'Invalid domain: '.$domain unless defined $sth;

            $sth->execute($self->{dbid});

            while (my $row = $sth->fetchrow_arrayref) {
                $res{$row->[0]} = $row->[1];
            }

            return \%res;
        }
    } else {
        return {map {$_ => $self->get($_)} qw(properties digests)};
    }
}


sub set {
    my ($self, $domain, $key, $value) = @_;
    my $dbid = $self->{dbid};
    my $data;

    croak 'No data given' unless defined $domain;

    # get things in standard format:
    if (defined($key)) {
        if (defined($value)) {
            $data = {$domain => {$key => $value}};
        } else {
            $data = {$domain => $key};
        }
    } else {
        $data = $domain;
    }

    $self->store->in_transaction(rw => sub {
            foreach my $cdomain (keys %{$data}) {
                my $d = $data->{$cdomain};
                my $sth;
                my $valids;

                if ($cdomain eq 'properties') {
                    $sth = $self->_prepare('INSERT INTO file_properties (file,key,value) SELECT ?, ?, ? WHERE NOT EXISTS (SELECT TRUE FROM file_properties WHERE file = ? AND key = ? AND value = ?)');
                    $valids = \%_valid_properties;
                } elsif ($cdomain eq 'digests') {
                    $sth = $self->_prepare('INSERT INTO file_hash (file,algo,hash) SELECT ?, ?, ? WHERE NOT EXISTS (SELECT TRUE FROM file_hash WHERE file = ? AND algo = ? AND hash = ?)');
                    $valids = $self->_valid_digests;
                }

                croak 'Invalid domain: '.$domain unless defined $sth;

                foreach my $key (keys %{$d}) {
                    croak 'Invalid key '.$key.' for domain '.$cdomain unless defined $valids->{$key};
                    croak 'Invalid value for key '.$key.' for domain '.$cdomain unless $d->{$key} =~ $valids->{$key};
                    $sth->execute($dbid, $key, $d->{$key}, $dbid, $key, $d->{$key});
                }
            }
        });
}


sub delete {
    my ($self) = @_;
    my $store = $self->store;
    my $dbid = $self->{dbid} or croak 'Call on invalid object';

    $store->in_transaction(rw => sub {
            my $filename = $self->filename;
            my @linknames = $self->_linknames(undef, 'all');
            my $sth;

            unlink($filename) or croak 'Cannot unlink file: '.$!;
            unlink($_) foreach @linknames;

            $sth = $self->_prepare('DELETE FROM file_hash WHERE file = ?');
            $sth->execute($dbid);
            $sth = $self->_prepare('DELETE FROM file_properties WHERE file = ?');
            $sth->execute($dbid);
            $sth = $self->_prepare('DELETE FROM file WHERE id = ?');
            $sth->execute($dbid);
        });

    %{$self} = ();
}


sub sync_with_db {
    my ($self, %opts) = @_;
    my $db = $opts{db} // $self->db;
    my $fii_inode = $self->as('File::Information::Inode');
    $db->in_transaction(rw => sub {
            my $data = $self->get;
            my %ids = (
                contentise          => $self->contentise(as => 'Data::Identifier'),
                inodeise            => $fii_inode->get('inodeise', as => 'Data::Identifier', default => undef),
                proto               => (defined($opts{proto}) ? $opts{proto}->Data::Identifier::as('Data::Identifier') : undef),

                # Related values:

                encoding            => (defined($data->{properties}{mediasubtype}) ? Data::Identifier::Generate->generic(
                        namespace   => '50d7c533-2d9b-4208-b560-bcbbf75ce3f9',
                        input       => $data->{properties}{mediasubtype},
                    ): undef),

                %_db_tags,
            );
            my %tags = map {$_ => scalar(eval {$ids{$_}->as('Data::TagDB::Tag', %opts{autocreate}, db => $db)})} grep {defined $ids{$_}} keys %ids;

            if (defined(my $tag = $tags{contentise})) {
                my $size = $data->{properties}{size};

                if (defined($tags{also_has_role}) && defined($tags{specific_proto_file_state})) {
                    $db->create_relation(tag => $tag, relation => $tags{also_has_role}, related => $tags{specific_proto_file_state});
                }

                if (defined($size) && defined($tags{final_file_size})) {
                    $db->create_metadata(tag => $tag, relation => $tags{final_file_size}, data_raw => $size);
                }

                if (defined($tags{encoding}) && defined($tags{final_file_encoding})) {
                    $db->create_relation(tag => $tag, relation => $tags{final_file_encoding}, related => $tags{encoding});
                }

                if (defined($tags{final_file_hash}) && defined($size) && $size > 0) {
                    foreach my $digest (keys %{$data->{digests}}) {
                        my $v = sprintf('v0 %s bytes 0-%u/%u %s', $digest, $size - 1, $size, $data->{digests}{$digest} // next);
                        $db->create_metadata(tag => $tag, relation => $tags{final_file_hash}, data_raw => $v);
                    }
                }
            }

            if (defined(my $proto = $tags{proto})) {
                if (defined(my $tag = $tags{contentise})) {
                    if (defined(my $relation = $opts{final_of_proto} ? $tags{has_final_state} : $tags{also_has_state})) {
                        $db->create_relation(tag => $proto, relation => $relation, related => $tag);
                    }
                }
            }

            if (defined(my $inode = $tags{inodeise})) {
                if (defined(my $tag = $tags{contentise})) {
                    if (defined($tags{has_final_state})) {
                        $db->create_relation(tag => $inode, relation => $tags{has_final_state}, related => $tag);
                    }
                }
            }
        });
}


# --- Overrides for Data::URIID::Base ---
sub contentise {
    my ($self, @args) = @_;

    $self->{contentise} //= eval {Data::Identifier->new(ise => $self->get(properties => 'contentise'))};
    $self->{contentise} //= $self->_calculate_contentise;

    return $self->SUPER::contentise(@args);
}

sub as {
    my ($self, $as, %opts) = @_;

    if ($as eq 'File::Information::Inode' || $as eq 'File::Information::Base') {
        if (defined $opts{fii}) {
            return $opts{fii}->for_handle($self->_open);
        } else {
            return $self->{fii_inode} //= $self->fii->for_handle($self->_open);
        }
    } elsif ($as eq 'File::Information::Link') {
        if (defined $opts{fii}) {
            return $opts{fii}->for_link($self->filename);
        } else {
            return $self->{fii_inode} //= $self->fii->for_link($self->filename);
        }
    }

    return $self->SUPER::as($as, %opts);
}


# --- Overrides for Data::Identifier::Interface::Known ---
sub _known_provider {
    my ($pkg, $class, %opts) = @_;
    state $classes = {
        properties      => [[keys %_valid_properties], not_identifiers => 1],
        digests         => [[keys %File::FStore::_valid_digests], not_identifiers => 1],
        link_styles     => [[keys %File::FStore::_valid_link_styles], not_identifiers => 1],
        store_styles    => [[keys %File::FStore::_valid_store_styles], not_identifiers => 1],
        domains         => [[qw(properties digests)], not_identifiers => 1],
        other_tags      => [[values %_db_tags], rawtype => 'Data::Identifier'],
    };
    croak 'Unsupported options passed' if scalar(keys %opts);
    $class =~ tr/-/_/;
    return @{$classes->{$class}} if defined $classes->{$class};
    return ([map {@{$_->[0]}} values %{$classes}], not_identifiers => 1) if $class eq ':all';
    croak 'Unsupported class';
}



# ---- Private helpers ----
sub _valid_digests {
    return state $digests = {map {$_ => qr/^[0-9a-f]{$File::FStore::_valid_digests{$_}}$/} keys %File::FStore::_valid_digests};
}

sub _new {
    my ($pkg, %opts) = @_;
    my $self = bless \%opts, $pkg;

    croak 'No store is given' unless defined $self->{store};
    croak 'No dbid is given' unless defined $self->{dbid};

    return $self;
}

sub _prepare {
    my ($self, $q) = @_;
    my $dbh = $self->{dbh} //= $self->store->{dbh};
    return $dbh->prepare($q);
}

sub _open {
    my ($self, %opts) = @_;
    my $fh;

    $self->{fh} = $opts{fh} if defined $opts{fh};

    $fh = $self->{fh} //= do {
        CORE::open(my $in, '<', $self->filename) or croak $!;
        $in;
    };

    seek($fh, 0, SEEK_SET) or croak $!;

    return $fh;
}

sub _detach_fh {
    my ($self) = @_;
    $self->{fh} = undef;
}

sub _used_digests {
    my ($self) = @_;
    return $self->{used_digests} //= $self->store->_used_digests;
}

sub _calculate_contentise {
    my ($self, $data) = @_;
    my $sha_1_160 = eval { $self->get(digests => 'sha-1-160') };
    my $sha_3_512 = eval { $self->get(digests => 'sha-3-512') };
    my $size      = eval { $self->get(properties => 'size')   };

    if (defined $data) {
        $data->{digests} //= {};
        $data->{properties} //= {};
        $sha_1_160 //= $data->{digests}{'sha-1-160'};
        $sha_3_512 //= $data->{digests}{'sha-3-512'};
        $size      //= $data->{properties}{size};
    }

    if (defined($sha_1_160) && defined($sha_3_512) && defined($size)) {
        my $digest = sprintf('v0m sha-1-160 bytes 0-%u/%u %s v0 sha-3-512 bytes 0-%u/%u %s',
            $size - 1, $size, $sha_1_160,
            $size - 1, $size, $sha_3_512,
        );

        return Data::Identifier::Generate->generic(
            namespace => '66d488c0-3b19-4e6c-856f-79edf2484f37',
            input => $digest,
        );
    }
    return undef;
}

sub _ext {
    my ($self) = @_;

    return $self->{ext} if exists $self->{ext};

    {
        my $mediasubtype = eval {$self->get(properties => 'mediasubtype')} // 'x.x/x.x';
        return $self->{ext} = $_exts{$mediasubtype} if defined $_exts{$mediasubtype};
    }

    {
        my $dbname = $self->dbname;
        if ($dbname =~ /\.([a-z0-9]{1,4})$/) {
            my $ext = $1;

            if ($dbname =~ /\.(tar\.(?:gz|bz2|xz|lz|zst))$/) {
                $ext = $1;
            }

            return $self->{ext} = $ext;
        }
    }

    return $self->{ext} = undef;
}

sub _linknames {
    my ($self, $digests, $link_style) = @_;
    my File::FStore $store = $self->store;
    my $ext = $self->_ext;
    my @res;

    $ext = '.'.$ext if defined $ext;

    $digests //= $self->get('digests');
    $link_style //= $store->setting('link_style');

    foreach my $digest (keys %{$digests}) {
        my $v = $digests->{$digest} // next;

        $v .= $ext if defined $ext;

        if ($link_style eq '1-level' || $link_style eq 'all') {
            push(@res, $store->_file(v2 => by => $digest => $v));
        }
        if ($link_style eq '2-level' || $link_style eq 'all') {
            push(@res, $store->_file(v2 => by => $digest => substr($v, 0, 2) => $v));
        }
    }

    return @res;
}

# Bad workaround for File::ExtAttr
package File::FStore::File::_DUMMY_FOR_XATTR {

    sub new {
        my ($pkg, $fh) = @_;
        return undef unless eval {require File::ExtAttr; File::ExtAttr->import; 1;};
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
    sub getfattr {
        my ($self, $key) = @_;
        return eval { $self->File::ExtAttr::getfattr($key, { namespace => 'user' }) };
    }
    sub setfattr {
        my ($self, $key, $value) = @_;
        return eval { $self->File::ExtAttr::setfattr($key => $value, { namespace => 'user' }) };
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::FStore::File - Module for interacting with file stores

=head1 VERSION

version v0.05

=head1 SYNOPSIS

    use File::FStore;

    my File::FStore $store = File::FStore->new(path => '...');

    my File::FStore::File $file = $store->query(...);

This package provides access to file level values.

This package inherits from L<File::FStore::Base>, and L<Data::Identifier::Interface::Known>.

=head1 METHODS

=head2 dbname

    my $dbname = $file->dbname;

This returns the name of the file relative to the store's data directory.

B<Note:>
This method is generally not very useful for most applications.

See also:
L</filename>,
L</open>.

=head2 filename

    my $filename = $file->filename;

This returns the filename within the store.
The filename is returned in a format that is suitable to be passed to operating system functions.

B<Note:>
When possible L</open> should be preferred.

See also:
L</open>.

=head2 open

    my $fh = $file->open;

    $fh->binmode; # allow binary data.

Opens the file and returns a filehandle.
The file is opened read-only (as all files in the store are read-only to begin with).

B<Note:>
This module doesn't set the handle to binary mode similar to L<perlfunc/open>.
See L<perlfunc/binmode> for details.

See also:
L</filename>.

=head2 link_out

    $file->link_out($filename);

Creates an hardlink to this file as C<$filename>.
C<die>s on any error.

See also:
L<perlfunc/link>.

=head2 symlink_out

    $file->symlink_out($filename);

Creates an symlink to this file as C<$filename>.
C<die>s on any error.

See also:
L<perlfunc/symlink>.

=head2 update

    $file->update;
    # or:
    $file->update(%opts);

Updates the file in the database. Also performs a verify of the file as part of the update.

The following (all optional) options are supported:

=over

=item C<no_digests>

This will try to skip digest calculation.

=item C<on_pre_set>

A callback that is called before any data is set (see L</set>) on this file.
C<$file> is passed as first argument.

=item C<on_post_set>

A callback that is called after all data is set (see L</set>) on this file.
C<$file> is passed as first argument.

=back

=head2 stat

    my @res = $file->stat;

This method performs the same task and returns the same values as L<perlfunc/stat>.
In contrast however it C<die>s if the request cannot be performed. This however can only happen if the store is corruped.

The value is cached. Therefore some attributes (mostly C<atime>) might be out of sync.
However those attributes are unreliable to begin with, hence the cache doesn't really make this worse.

B<Note:>
If you plan to perform an L</open> on this file call that first and then this method.
This will improve performance and reduce the chance of race conditions.

=head2 get

    my $value = $file->get($domain => $key);
    # or:
    my $hashref = $file->get($domain);
    # or:
    my $hashhashref = $file->get;

Returns information about the file.
If a C<$domain> and C<$key> is given the value is returned as scalar.
If only a C<$domain> is given all values for that domain are returned as a hashref.
If no parameters are given a hashref with the domains as keys and the hashrefs of the per-domain values is returned.

If a value is unknown this method C<die>s.

The following domains are supported:

=over

=item C<properties>

This domain contains flat properties of the file sich as it's size.

See L</PROPERTIES>.

=item C<digests>

This domain contains digests for the file as known. Those are the I<final> digests.
If the file does not match the those values at this point it is corruped.

The key is the digest name in universal tag (utag) format (e.g. C<sha-3-224>).

=back

=head2 set

    $file->set($domain => $key => $value);
    # or:
    $file->set($domain => {$key => $value});
    # or:
    $file->set({$domain => {$key => $value}});

This sets a value on the file.
The value is checked against already known values.
If a value is set for a key that already holds a value this method C<die>s if the values missmatch.

This method takes a domain-key-value triplet, or a domain and a hashref with multiple values, or
a single hashref with the domain(s) as keys and hashrefs with key-value pairs as values.

See also:
L</get>.

=head2 delete

    $file->delete;

Removes the given file from the store.
This also unlinks all links within the store.

If there is no hardlink outside the store to the given file it is
fully removed from the filesystem.

B<Note:>
After this call B<no> future calls are allowed on this handle
or any other handle referencing the same file.

=head2 sync_with_db

    $file->sync_with_db;
    # or:
    $file->sync_with_db(%opts);

Syncs the file with the database.
It may read data from, and write data to the database related to this file.

B<Note:>
This method calls L<Data::TagDB/in_transaction> with type C<rw>.

It mainly operates on three tags:

=over

=item content

The content tag is the tag that represents the state of this file (size, digests, ...)
(but not the filesystem object or other objects).

See also L</contentise>.

=item inode

The inode tag represents the actual file on the filesystem.
This is the tag file system browsing software will use.

The inode tag has the content tag as it's final state.

See also L<File::Information::Base/inodeise>.

=item proto

The proto tag represents the work independent on the filesystem.
This is often used by software that implement some kind of catalogue.

The proto tag has the content tag as a state, maybe as it's final state.

=back

The following (all optional) options are supported:

=over

=item C<autocreate>

Whether tags should be automatically created if not yet part of the database.

Defaults to false.

See also L<Data::Identifier/as>.

=item C<db>

The database object to use.

Defaults to the value returned by L</db>.

=item C<final_of_proto>

Whether this file is the final state of the proto tag (true value) or
just one of it's states (false value).

Defaults to false.

=item C<proto>

The tag to be used as proto tag (if any).
This may be anything that L<Data::Identifier/as> will accept.

Defaults to C<undef>.

=back

=head2 known

    my @list = File::FStore::File->known($class [, %opts ] );
    # or:
    my @list = $file->known($class [, %opts ] );

(since v0.05)

Lists known objects. See L<Data::Identifier::Interface::Known/known> for details.

The following classes are defined:

=over

=item C<domains>

The list of domains this module supports.

=item C<properties>

The list of keys for the C<properties> domain this module knows.

=item C<digests>

The list of keys for the C<domains> domain this module knows.
Note that actual support of those digests depend on installed modules and is not reflected by this list.

=item C<link_styles>

The list of supported link styles. See L<File::FStore/new>.

=item C<store_styles>

The list of supported store styles. See L<File::FStore/new>.

=item C<other-tags>

A list of other tags this module knows about.
This list is hardly useful for most operations.
However it can be used to prime a database.

=back

=head1 PROPERTIES

The following properties are known.

=head2 size

The file size in bytes.

=head2 inode

The inode number. The value is specific to the filesystem the file is on.

=head2 mediasubtype

The media subtype of the file.

B<Warning:>
This property is commonly very missunderstood.
It is best to not set this manually and let the store maintain the value.
Setting this value is acceptable when importing data from another store or from a L<File::Information::Base> object.

B<Note:>
Only values listed at L<https://www.iana.org/assignments/media-types/media-types.xhtml> are valid.
Any value not listed by IANA is invalid.

=head2 contentise

The content ISE (identifier) value.
This value is mainly maintained internally, however may be set early as a mean to verify the file integrity.
For reading the value there is a special method L</contentise>.

=head2 inodeise

The inode ISE (identifier) value.
This value represents the inode on the file system.
It is mainly maintained internally, but used by and imported from external sources
such as tagpool.
The value is stable for the inode's lifetime.
It may be different or the same if the inode number is reused.
It is stable since when the inode was created and also doesn't change when the inode is written to (in contrast to L</contenise>.

See also:
L<File::Information::Base/get>.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
