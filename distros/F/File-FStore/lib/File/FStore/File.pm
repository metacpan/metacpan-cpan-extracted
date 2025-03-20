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

use constant WRITE_BITS => S_IWUSR|S_IWGRP|S_IWOTH;

our $VERSION = v0.01;

my @_xattr_hashes = qw(sha-1-160 sha-2-256 sha-3-512);

my %_valid_properties = map {$_ => 1} qw(size inode mediasubtype contentise);

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


sub contentise {
    my ($self, %opts) = @_;
    my $as = delete($opts{as}) // 'uuid';

    croak 'Stray options passed' if scalar keys %opts;

    $self->{contentise} //= eval {Data::Identifier->new(ise => $self->get(properties => 'contentise'))};
    $self->{contentise} //= $self->_calculate_contentise;

    croak 'No contentise known for this file' unless defined $self->{contentise};

    return $self->{contentise}->as($as,
        db => $self->db(default => undef),
        extractor => $self->extractor(default => undef),
    );
}


sub ise {
    my ($self, @args) = @_;
    return $self->contentise(@args);
}


sub open {
    my ($self) = @_;
    my $fh = $self->_open;

    $self->stat;
    $self->_detach_fh;

    return $fh;
}


sub update {
    my ($self, %opts) = @_;
    my File::FStore $store = $self->store;
    my $no_digests = delete($opts{no_digests});
    my $inode;
    my $properties;
    my $digests;

    croak 'Stray options passed' if scalar keys %opts;

    $store->in_transaction(rw => sub {
            my $fh = $self->_open;

            delete $self->{stat}; #clear stat cache.

            $inode = $self->_fii_inode;

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

                $self->set($data);
            }

            # Create symlinks:
            {
                my $ext = $_exts{$properties->{mediasubtype} // 'x.x/x.x'};
                my $dbname = $self->dbname;
                my $filename = File::Spec->catfile('..', '..', 'store', $dbname);

                unless (defined $ext) {

                    if ($dbname =~ /\.([a-z0-9]{1,4})$/) {
                        $ext = $1;

                        if ($dbname =~ /\.(tar\.(?:gz|bz2|xz|lz|zst))$/) {
                            $ext = $1;
                        }
                    }
                }

                $ext = '.'.$ext if defined $ext;

                foreach my $digest (keys %{$digests}) {
                    my $v = $digests->{$digest} // next;
                    my $fn;

                    $v .= $ext if defined $ext;
                    $fn = $store->_file(v2 => by => $digest => $v);

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
                    $valids = \%File::FStore::_valid_digests;
                }

                croak 'Invalid domain: '.$domain unless defined $sth;

                foreach my $key (keys %{$d}) {
                    croak 'Invalid key '.$key.' for domain '.$cdomain unless defined $valids->{$key};
                    $sth->execute($dbid, $key, $d->{$key}, $dbid, $key, $d->{$key});
                }
            }
        });
}


#@returns File::FStore
sub store {
    my ($self) = @_;
    return $self->{store};
}


#@returns Data::TagDB
sub db {
    my ($self, %opts) = @_;
    return $self->{db} //= $self->store->db(%opts);
}


#@returns Data::URIID
sub extractor {
    my ($self, %opts) = @_;
    return $self->{extractor} if defined $self->{extractor};
    return $opts{default} if exists $opts{default};
    croak 'No extractor known';
}


sub fii {
    my ($self) = @_;
    return $self->{fii} //= $self->store->fii;
}

# ---- Private helpers ----
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

sub _fii_inode {
    my ($self) = @_;
    return $self->{fii_inode} //= $self->fii->for_handle($self->_open);
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

# Bad workaround for File::ExtAttr
package File::FStore::File::_DUMMY_FOR_XATTR {
    my $HAVE_XATTR              = eval {require File::ExtAttr; File::ExtAttr->import; 1;};

    sub new {
        my ($pkg, $fh) = @_;
        return undef unless $HAVE_XATTR;
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

version v0.01

=head1 SYNOPSIS

    use File::FStore;

    my File::FStore $store = File::FStore->new(path => '...');

    my File::FStore::File $file = $store->query(...);

This package provides access to file level values.

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

=head2 contentise

    my $ise = $file->contentise;
    # or:
    my $ise = $file->contentise(as => ...);

Returns the content based ISE (identifier) for the file.
This can be used as a primary key for the given file in databases.
It is globally unique (so can be transfered to unrelated systems without worry of of collisions).

Takes a single optional option C<as> which is documented in L<Data::Identifier/as>.
Defaulting to C<uuid>.

B<Note:>
Calculation of this identifier requires the values for C<size> from the C<properties> domain
and the values for C<sha-1-160> and C<sha-3-512> from the C<digests> domain.

=head2 ise

    my $ise = $file->ise;
    # or:
    my $ise = $file->ise(%opts);

Returns an ISE (identifier) for this file.

Currently an alias for L</contentise>. Later versions may add more logic.

=head2 open

    my $fh = $file->open;

Opens the file and returns a filehandle.
The file is opened read-only (as all files in the store are read-only to begin with).

See also:
L</filename>.

=head2 update

    $file->update;
    # or:
    $file->update(%opts);

Updates the file in the database. Also performs a verify of the file as part of the update.

The following (all optional) options are supported:

=over

=item C<no_digests>

This will try to skip digest calculation.

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

=head2 store

    my File::FStore $store = $file->store;

Returns the store this file belongs to.

=head2 db

    my Data::TagDB $db = $file->db;
    # or:
    my Data::TagDB $db = $file->db(default => $def);

Proxy for L<File::FStore/db>.

=head2 extractor

    my Data::URIID $extractor = $file->extractor;
    # or:
    my Data::URIID $extractor = $file->extractor(default => $def);

Proxy for L<File::FStore/extractor>.

=head2 fii

    my File::Information $fii = $file->fii;

Proxy for L<File::FStore/fii>.

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

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
