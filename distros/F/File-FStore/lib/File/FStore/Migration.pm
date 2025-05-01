# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Module for interacting with file stores


package File::FStore::Migration;

use v5.10;
use strict;
use warnings;

use Carp;
use File::Spec;

use parent 'File::FStore::Base';

our $VERSION = v0.05;


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

    croak 'Stray options passed' if scalar keys %opts;

    $store->in_transaction(rw => sub {
            if ($format eq 'json') {
                require JSON;
                my $json = do {
                    local $/ = undef;
                    JSON::decode_json(<$handle>);
                }->{files};
                foreach my $dbname (keys %{$json}) {
                    my $file = $store->query(dbname => $dbname);
                    my $d = $json->{$dbname};
                    $d = {
                        properties  => $d->{properties} // {},
                        digests     => $d->{hashes}     // {},
                    };
                    $file->set($d);
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

# ---- Private helpers ----
sub _new {
    my ($pkg, %opts) = @_;
    my $self = bless \%opts, $pkg;

    croak 'No store is given' unless defined $self->{store};

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::FStore::Migration - Module for interacting with file stores

=head1 VERSION

version v0.05

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

The format to use. Currently supported is C<json> for the classic JSON format.

=back

=head2 export_data

    $migration->export_data($handle, %opts);

(since v0.04)

Exports the store metadata.

The following (all optional) options are supported:

=over

=item C<format>

The format to use.
Currently supported is C<json> for the classic JSON format.
And C<valuefile> for universal tag based ValueFile output.

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

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
