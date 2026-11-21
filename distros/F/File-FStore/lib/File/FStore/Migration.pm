# Copyright (c) 2025-2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Module for interacting with file stores


package File::FStore::Migration;

use v5.10;
use strict;
use warnings;

use Carp;
use File::Spec;
use Fcntl qw(SEEK_CUR);

use parent 'File::FStore::Base';

our $VERSION = v0.08;


sub upgrade {
    my ($self, @args) = @_;
    croak 'Stray options passed' if scalar @args;
    # Currently a no-op.
}


#@returns File::FStore::Adder
sub new_adder {
    my ($self, @args) = @_;
    return $self->store->new_adder(@args);
}


sub import_data {
    my ($self, $handle, %opts) = @_;
    my $store = $self->store;
    my $format = delete($opts{format}) // 'json';
    my $use_contentise = delete($opts{use_contentise});

    croak 'Stray options passed' if scalar keys %opts;

    $handle->binmode;

    $store->in_transaction(rw => sub {
            if ($format eq 'json') {
                require JSON;
                my $json = do {
                    local $/ = undef;
                    JSON::decode_json(<$handle>);
                }->{files};
                foreach my $dbname (keys %{$json}) {
                    my $d = $json->{$dbname};
                    my $file;

                    if ($use_contentise) {
                        $file = $store->query(properties => contentise => $d->{properties}{contentise} // croak 'No contentise');
                    } else {
                        $file = $store->query(dbname => $dbname);
                    }

                    $d = {
                        properties  => $d->{properties} // {},
                        digests     => $d->{hashes}     // {},
                    };
                    $file->set($d);
                }
            } elsif ($format eq 'bundle') {
                my $data;
                my $len = $handle->read($data, 8);
                my %index;

                croak 'Bad magic' unless $len == 8 && $data eq "!<arch>\x0A";

                # Read index:
                $len = $handle->read($data, 60);
                croak 'Bad archive header' unless $len == 60;

                {
                    my ($name, $date, $uid, $gid, $mode, $size, $magic) = unpack('A16A12A6A6A8A10a2', $data);

                    croak 'Bad archive header data' unless $magic eq "\x60\x0A" && $mode =~ /^[4-7]{3}\z/ && $name eq '.FSTORE_INDEX/';

                    $size = int $size;

                    $len = $handle->read($data, $size);
                    croak 'IO error while reading index body' unless $len == $size;

                    while ($data =~ s/^(data-\S+)\s+(\S+)\s+(\S+\/\S+|-)\s+(\S.+)\x0A//) {
                        my ($filename, $contentise, $mediasubtype, $hashes) = ($1, $2, $3, $4);
                        my %digests;
                        my %properties;
                        my %info = (properties => \%properties, digests => \%digests);
                        my $given_size;

                        croak 'Index entries without contentise are current not supported' unless length($contentise) == 36;

                        $index{$filename} = {filename => $filename, contentise => $contentise, info => \%info};
                        $properties{contentise} = $contentise;
                        $properties{mediasubtype} = $mediasubtype if $mediasubtype ne '-';

                        while ($hashes =~ s/^(v0m?) ([a-z]+)-([0-9]+)-([0-9]+) bytes 0-([0-9]+)\/([0-9]+) ([0-9a-f]+)( |$)//) {
                            my ($type, $name, $version, $bits, $end, $size, $hash, $mark) = ($1, $2, $3, $4, $5, $6, $7, $8);
                            next if $end != ($size - 1);
                            die if (length($hash) * 4) != $bits;
                            die if $type eq 'v0' && length($mark);

                            $given_size //= $size;
                            die unless $given_size == $size;
                            $digests{join('-', $name, $version, $bits)} = $hash;
                        }
                        $properties{size} = int($given_size) if defined $given_size;
                    }

                    croak 'Corrupted or unsupported index' if length($data);
                }

                # Read actual files:
                while (1) {
                    my ($name, $date, $uid, $gid, $mode, $size, $magic);
                    my $ent;
                    my $file;

                    $len = $handle->read($data, 60);

                    last if $len == 0;

                    croak 'Bad archive header' unless $len == 60;

                    ($name, $date, $uid, $gid, $mode, $size, $magic) = unpack('A16A12A6A6A8A10a2', $data);

                    croak 'Bad archive header data' unless $magic eq "\x60\x0A" && $mode =~ /^[4-7]{3}\z/;

                    $size = int $size;
                    $name =~ s#/\z##;

                    $ent = delete $index{$name};

                    croak 'Invalid file in archive' unless defined $ent;

                    $ent->{info}{properties}{size} //= $size;
                    croak 'Entry size mismatch' unless $ent->{info}{properties}{size} == $size;

                    ($file) = $store->query(properties => {contentise => $ent->{contentise}, size => $size});

                    if (defined $file) {
                        # we found the file
                        unless ($handle->seek($size, SEEK_CUR)) {
                            # seek didn't work, so we need to read...
                            my $left = $size;
                            while ($left > 0) {
                                my $todo = $left < 65536 ? $left : 65536;
                                $len = $handle->read($data, $todo);

                                if ($len < $todo) {
                                    croak 'IO error reading bundle';
                                }

                                $left -= $len;
                            }
                        }

                        $file->set($ent->{info});
                    } else {
                        # we need to add the file
                        my $adder = $self->new_adder;
                        my $filename = $adder->_temp_filename; # TODO: FIXME: Not part of public API!

                        $adder->set($ent->{info});

                        {
                            # IO transfer loop
                            my $left = $size;
                            open(my $out, '>', $filename) or die $!;
                            $out->binmode;

                            while ($left > 0) {
                                my $todo = $left < 65536 ? $left : 65536;
                                $len = $handle->read($data, $todo);

                                if ($len < $todo) {
                                    croak 'IO error reading bundle';
                                }

                                $out->print($data);

                                $left -= $len;
                            }
                        }

                        $file = $adder->insert;
                    }

                    if ($size & 1) {
                        # We need to read the padding.
                        $len = $handle->read($data, 1);
                        croak 'Corrupted archive, bad padding' unless $len == 1 && $data eq "\x0A";
                    }
                }

                if (keys %index) {
                    croak 'Unused index entries';
                }
            } else {
                croak 'Unsupported format given: '.$format;
            }
        });
}


sub export_data {
    my ($self, $handle, %opts) = @_;
    my $format = delete($opts{format}) // 'json';
    my $list = delete($opts{list});
    my $query = delete($opts{query});

    croak 'Stray options passed' if scalar keys %opts;

    $handle->binmode;

    $list //= do {
        $query //= ['all'];
        [$self->store->query(@{$query})];
    };

    if ($format eq 'json') {
        require JSON;
        $handle->say(JSON::encode_json({
                    files => {
                        map {
                            my $res = $_->get;
                            $res->{hashes} = delete $res->{digests};
                            $_->dbname => $res
                        } @{$list}
                    },
                }));
    } elsif ($format eq 'valuefile') {
        require File::ValueFile::Simple::Writer;
        my $writer = File::ValueFile::Simple::Writer->new($handle, format => 'e5da6a39-46d5-48a9-b174-5c26008e208e');
        my %mediasubtype_cache;

        foreach my $file (@{$list}) {
            my Data::Identifier $ise = Data::Identifier->new(uuid => $file->contentise(as => 'uuid'), displayname => $file->dbname);
            my $size = eval {$file->get(properties => 'size')};
            my $mediasubtype = eval {$file->get(properties => 'mediasubtype')};
            my $digests = $file->get('digests');

            if (defined $mediasubtype) {
                $mediasubtype = $mediasubtype_cache{$mediasubtype} //= Data::Identifier::Generate->generic(
                    namespace => '50d7c533-2d9b-4208-b560-bcbbf75ce3f9',
                    input => $mediasubtype,
                );
            }

            $writer->write;
            $writer->write_tag_ise($ise);

            if (defined $size) {
                $writer->write_tag_metadata($ise, '1cd4a6c6-0d7c-48d1-81e7-4e8d41fdb45d', $size);
                foreach my $digest (sort keys %{$digests}) {
                    $writer->write_tag_metadata($ise, '79385945-0963-44aa-880a-bca4a42e9002', sprintf('v0 %s bytes 0-%u/%u %s', $digest, $size - 1, $size, $digests->{$digest}));
                }
            }
            $writer->write_tag_relation($ise, '448c50a8-c847-4bc7-856e-0db5fea8f23b', $mediasubtype) if defined $mediasubtype;
            $writer->write_tag_relation($ise, 'd2750351-aed7-4ade-aa80-c32436cc6030', '52a516d0-25d8-47c7-a6ba-80983e576c54'); # also-has-role: proto-file
        }
    } elsif ($format eq 'bundle') {
        # Write magic:
        $handle->print("!<arch>\x0A");

        # Write index:
        {
            my $index = '';
            my $algos = $self->store->_used_digests;

            for (my $idx = 0; $idx < scalar(@{$list}); $idx++) {
                my $file = $list->[$idx];
                my $info = $file->get;
                my $size = $info->{properties}{size};
                my $name = 'data-'.$idx;
                my $ext = $file->_ext;
                my $hashes = '';
                my @hashes;

                $name .= '.'.$ext if defined $ext;

                foreach my $key (@{$algos}) {
                    my $value = $info->{digests}{$key} // next;

                    if ($size > 0) {
                        push(@hashes, sprintf('%s bytes 0-%u/%u %s', $key, $size - 1, $size, $value));
                    } else {
                        push(@hashes, sprintf('%s bytes 0-/%u %s', $key, $size, $value));
                    }
                }

                if (scalar(@hashes) > 1) {
                    my $last = pop(@hashes);
                    $hashes = 'v0m '.join(' v0m ', @hashes).' v0 '.$last;
                } elsif (scalar(@hashes)) {
                    $hashes = 'v0 '.$hashes[0];
                } elsif ($size > 0) {
                    $hashes = sprintf('v0 sha-3-512 0-%u/%u ...', $size - 1, $size);
                } else {
                    $hashes = 'v0 sha-3-512 0-/0 ...';
                }

                $index .= sprintf("%s %s %s %s\x0A", $name, $file->contentise, $info->{properties}{mediasubtype} // '-', $hashes);
            }

            $handle->print(pack('A16A12A6A6A8A10A2', '.FSTORE_INDEX/', 0, 0, 0, '444', length($index), "\x60\x0A"));
            $handle->print($index);
            $handle->print("\x0A") if length($index) & 1;
        }

        # Write data files:
        for (my $idx = 0; $idx < scalar(@{$list}); $idx++) {
            my $file = $list->[$idx];
            my $fh = $file->open;
            my $size = $file->get(properties => 'size');
            my $name = 'data-'.$idx;
            my $ext = $file->_ext;
            my $date = ($file->stat)[9] // 0;
            my $pad = $size & 1;

            $name .= '.'.$ext if defined $ext;

            $name .= '/';
            $handle->print(pack('A16A12A6A6A8A10A2', $name, $date, 0, 0, '444', $size, "\x60\x0A"));

            # Write data:
            $fh->binmode;
            while ($size) {
                my $todo = $size < 65536 ? $size : 65536;
                my $done = $fh->read(my $data, $todo);

                if ($done < $todo) {
                    croak 'IO error reading '.$file->dbname;
                }

                $handle->print($data);

                $size -= $done;
            }

            $handle->print("\x0A") if $pad;
        }
    } else {
        croak 'Unsupported format given: '.$format;
    }
}


sub insert_directory {
    my ($self, $directory, %opts) = @_;
    my $adder = $self->new_adder;
    my $basename_filter = $opts{basename_filter};
    my $on_pre_insert = $opts{on_pre_insert};
    my $on_post_insert = $opts{on_post_insert};
    my $on_error = $opts{on_error} // sub {croak $@};
    my $update = $opts{update} // 'none'; # FIXME: $adder->insert already calls update, so this does not work as expected.
    my $in_mode = $opts{in_mode} // 'link_in';
    my $in_func = $in_mode eq 'move_in' ? $adder->can('move_in') : $adder->can('link_in');

    $update = 'new' if $update eq 'all';
    $on_error = undef if $on_error eq 'ignore';

    opendir(my $d, $directory) or croak $!;
    while (defined(my $e = readdir($d))) {
        my $path;

        next if $e =~ /^\./;
        next if defined($basename_filter) && $e !~ $basename_filter;

        $path = File::Spec->catfile($directory, $e);
        if (-f $path) {
            my $file;

            $adder->$in_func($path);

            $on_pre_insert->($adder, path => $path, basename => $e) if defined $on_pre_insert;
            $file = eval { $adder->insert };
            $on_error->(undef, path => $path, basename => $e) if $on_error && $@;
            $adder->reset;

            if (defined $file) {
                if ($update eq 'new') {
                    $file->update(%opts{qw(on_pre_set on_post_set)});
                }

                $on_post_insert->($file, path => $path, basename => $e) if defined $on_post_insert;
            }
        } else {
            $path = File::Spec->catdir($directory, $e);
            #warn 'D: '.$path;
            $self->insert_directory($path, %opts);
        }
    }
    closedir($d);
}


sub insert_tagpool {
    my ($self, $path, %opts) = @_;
    my $on_pre_insert = $opts{on_pre_insert};

    $opts{on_pre_insert} = sub {
        my ($adder, %opts) = @_;
        my ($uuid) = $opts{basename} =~ /^file\.([0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12})(?:\..*)?$/;

        $adder->set(properties => inodeise => $uuid) if defined $uuid;

        $on_pre_insert->($adder, %opts) if defined $on_pre_insert;
    };

    $opts{basename_filter} = qr/^file\./;

    $self->insert_directory(
        File::Spec->catdir($path, 'data'),
        %opts,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::FStore::Migration - Module for interacting with file stores

=head1 VERSION

version v0.08

=head1 SYNOPSIS

    use File::FStore;

    my File::FStore::Migration $migration = $store->migration;

This package provides simple migration utilities.

This package inherits from L<File::FStore::Base>.
However L<File::FStore::Base/contentise> is not supported by this package.
Calling that method will C<die>.

=head1 METHODS

=head2 upgrade

    $migration->upgrade;

Upgrade database to current schema.

=head2 new_adder

    my File::FStore::Adder $adder = $migration->new_adder;

Proxy for L<File::FStore/new_adder>.

=head2 import_data

    $migration->import_data($handle);
    # or:
    $migration->import_data($handle, format => ...);

(since v0.04)

This method allows importing data into the database from an open handle.

The data is imported the same way as per L<File::FStore::File/set> including all safety checks.

The following (all optional) options are supported:

=over

=item C<format>

The format to use. Currently supported are C<json> for the classic JSON format (since v0.04 (v0.01)),
and C<bundle> (experimental since v0.08).

=item C<use_contentise>

(experimental since v0.08)

If set to a true value the contentise property is used to find the corresponding local entry.
If set to a false value (the default), the dbname value is used for the match.

=back

=head2 export_data

    $migration->export_data($handle, %opts);

(since v0.04)

Exports the store metadata.

The following (all optional) options are supported:

=over

=item C<format>

The format to use.
Currently supported are C<json> for the classic JSON format (since v0.04 (v0.01)),
C<valuefile> for universal tag based ValueFile output (since v0.04 (v0.01)),
and C<bundle> (experimental since v0.08).

=item C<list>

A arrayref to a list of files to include.

=item C<query>

A arrayref with a query in the same format as L</query> takes it.

=back

B<Note:>
If you want a stringified result you can use a memory handle as documented in L<perlfunc/open>.
E.g.: C<open(my $fh, 'E<gt>', \$result)>.

=head2 insert_directory

    $migration->insert_directory($path, %opts);

Inserts the files in the given directory into the store.

C<$path> is the path of the directory (in OS specific format).

The following options (all optional) are supported:

=over

=item C<basename_filter>

A regex used to filter files before insert by basename.
See L<perlop/qr>.

B<Note:>
This filter applies to files and sub-directories alike.
It matches the OS specific basename format.

=item C<in_mode>

The mode to use. C<link_in> (the default) or C<move_in>.
See L<File::FStore::Adder/link_in> and L<File::FStore::Adder/move_in>.

B<Note:>
While C<move_in> can be more easy to use and slightly more portable,
it comes at a higher risk of loosing files if the insert fails.

=item C<on_error>

A function to call on insert errors.
The first argument is undefined.
The following arguments are a hash.

The key C<path> holds the path to the file to be inserted (in OS specific format).
The key C<basename> holds the basename of the file (in OS specific format).

The error can be found in C<$@>.

=item C<on_post_insert>

A function to be called after the insert.
The first argument is the newly created L<File::FStore::File>.
The rest is a hash as per C<on_error>.

=item C<on_pre_insert>

A function to be called before the insert.
The first argument is the used L<File::FStore::Adder>.
The rest is a hash as per C<on_error>.

=back

=head2 insert_tagpool

    $migration->insert_tagpool($path, %opts);

Inserts the content of a tagpool into the store.

C<$path> is the same path to the pool (in OS specific format).

This method accepts all options of L</insert_directory> but C<basename_filter>.

B<Note:>
For best performace the object returned by L<File::FStore::Base/fii> should be aware of the pool.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
