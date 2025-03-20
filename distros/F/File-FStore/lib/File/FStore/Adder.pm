# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Module for interacting with file stores


package File::FStore::Adder;

use v5.10;
use strict;
use warnings;

use Carp;
use File::Spec;
use Data::Identifier;

our $VERSION = v0.01;


sub link_in {
    my ($self, $if) = @_;
    my $tmpname = $self->_temp_filename;

    link($if, $tmpname) or croak $!;
}


sub move_in {
    my ($self, $if) = @_;
    my $tmpname = $self->_temp_filename;

    rename($if, $tmpname) or croak $!;
}


sub set {
    my ($self, $domain, $key, $value) = @_;
    my $data;

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

    # now try to merge:
    foreach my $cdomain (keys %{$data}) {
        my $ddata = $data->{$cdomain};
        my $dd = $self->{data}{$cdomain} // croak 'Invalid domain: '.$cdomain;

        foreach my $key (keys %{$ddata}) {
            my $v = $ddata->{$key} // next;
            $dd->{$key} //= $v;
            croak 'Data missmatch domain '.$cdomain.' key '.$key if $dd->{$key} ne $v;
        }
    }
}


sub done {
    my ($self) = @_;
    my $link = $self->fii->for_link($self->_temp_filename);
    my $inode = $link->inode;
    my %data = (
        properties => {%{$self->{data}{properties}}},
        digests    => {%{$self->{data}{digests}}},
    );

    return if defined $self->{done};
    $self->{done} = 1;

    foreach my $lifecycle (qw(final current)) {
        if (defined(my $v = $link->get('size', default => undef))) {
            $data{properties}{size} //= $v;
            croak 'Invalid size' if $data{properties}{size} != $v;
        }

        if (defined(my $v = $link->get('mediatype', default => undef))) {
            $data{properties}{mediasubtype} //= $v;
            croak 'Invalid mediasubtype' if $data{properties}{mediasubtype} ne $v;
        }

        if (defined(my $v = $link->get('contentise', default => undef))) {
            $data{properties}{contentise} //= $v;
            croak 'Invalid contentise' if $data{properties}{contentise} ne $v;
        }

        foreach my $digest (@{$self->_used_digests}) {
            if (defined(my $v = $inode->digest($digest, lifecycle => $lifecycle, default => undef))) {
                $data{digests}{$digest} //= $v;
                croak 'Digest missmatch for '.$digest if $data{digests}{$digest} ne $v;
            }
        }
    }

    $self->set(\%data);

    {
        my $contentise = $self->{contentise} = Data::Identifier->new(ise => $data{properties}{contentise}) if defined $data{properties}{contentise};
        my @res = $self->store->query(properties => contentise => $contentise->uuid);
        if (scalar @res) {
            croak 'File already in store';
        }
    }
}


sub reset {
    my ($self) = @_;

    if (defined(my $fn = delete($self->{temp_filename}))) {
        unlink($fn);
    };

    %{$self} = (
        store => $self->store,
        data => {
            properties  => {},
            digests     => {},
        },
    );
}


#@returns File::FStore::File
sub insert {
    my ($self) = @_;
    my $tmpname = $self->_temp_filename;
    my $store = $self->store;
    my $dbname;
    my $fullname;
    my File::FStore::File $file;

    $self->done;
    $dbname = $self->_target_filename;

    {
        my @res = (
            $store->query(properties => contentise => $self->contentise),
            $store->query(dbname => $dbname),
        );
        if (scalar @res) {
            croak 'File already in store';
        }
    }

    $fullname = $store->_file(v2 => store => $dbname);
    if (-e $fullname) {
        croak 'File with duplicates dbname already in store';
    }

    mkdir($store->_directory(v2 => store => $self->_target_dirname)); # ignore errors.
    rename($tmpname => $fullname) or croak $!;

    $store->scan(update => 'none', no_digests => 1);
    $file = $store->query(dbname => $dbname);

    $file->set($self->{data});
    $file->update(no_digests => 1);

    $self->reset;
    
    return $file;
}


sub contentise {
    my ($self, %opts) = @_;
    my $as = delete($opts{as}) // 'uuid';

    croak 'Stray options passed' if scalar keys %opts;
    croak 'No contentise available (done yet?)' unless defined $self->{contentise};

    return $self->{contentise}->as($as,
        db => $self->db(default => undef),
        extractor => $self->extractor(default => undef),
    );
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
sub DESTROY {
    my ($self) = @_;
    $self->reset;
}

sub _new {
    my ($pkg, %opts) = @_;
    my $self = bless \%opts, $pkg;

    croak 'No store is given' unless defined $self->{store};

    $self->reset;

    return $self;
}

sub _temp_filename {
    my ($self) = @_;
    return $self->{temp_filename} //= do {
        state $c = int(rand 65535);
        my $base = sprintf('tmp.%u.%u.%u.%u.%u.%u.%u',
            $$, $^T, time,
            int(rand 65535), int($self->store), int($self),
            $c++,
        );
        my $filename = $self->store->_file(v2 => store => $base);

        croak 'Tempfile already exists: '.$filename if -e $filename;

        $filename;
    };
}

sub _target_dirname {
    my ($self) = @_;
    return 'by-contentise';
}

sub _target_filename {
    my ($self) = @_;
    my $contentise = $self->contentise;
    return $self->{target_filename} //= File::Spec->catfile($self->_target_dirname, $contentise);
}

sub _used_digests {
    my ($self) = @_;
    return $self->{used_digests} //= $self->store->_used_digests;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::FStore::Adder - Module for interacting with file stores

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use File::FStore;

    my File::FStore $store = File::FStore->new(path => '...');

    my File::FStore::Adder $adder = $store->new_adder;

    $adder->move_in($filename);
    $adder->set(...);

    my File::FStore::File $file = $adder->insert;

This package implements an Adder, a helper object that can be used to add files to the store.

=head1 METHODS

=head2 link_in

    $adder->link_in($filename);

Moves the given file in by means of adding a new hardlink.
This will not destroy the original hardlink.

This however requires filesystem support for multiple hardlinks,
as well as the source file being on the same filesystem as the store.

Also after L</insert> has been called no changes to the file (using any of it's names)
are allowed anymore.

This method C<die>s if there is any problem.

See also:
L</move_in>.

=head2 move_in

    $adder->move_in($filename);

Moves the given file in by means of renaming the file.
This will destroy the original hardlink.

This will require the source file being on the same filesystem as the store.

Once this call was successful the file is no longer available under the old name.

If the file is not added to the store the file is unlinked.

This method C<die>s if there is any problem.

See also:
L</link_in>.

=head2 set

    $file->set($domain => $key => $value);
    # or:
    $file->set($domain => {$key => $value});
    # or:
    $file->set({$domain => {$key => $value}});

This sets a value on the file to be added alike L<File::FStore::File/set>.
This method works the same way as said method including safety checks.

=head2 done

    $adder->done;

Marks the adder as done with all changes, but not yet inserted.
This method C<die>s on error or on state missmatch.

B<Note:>
You normally don't need to call this method manually.

B<Note:>
All calls to L</set> must be done before calling this method.
Also all changes to the file must be done before.
After calling this method the file is considered read-only.

B<Note:>
Calling this early can cause errors to be hidden or placed out of context.

=head2 reset

    $adder->reset;

Resets the adder. Any data that has already been set is removed.
Any temporary files are removed.
Files moved in with L</move_in> are unlinked.

=head2 insert

    my File::FStore::File $file = $adder->insert;

Performs the actual insert of the file into the store.

This method C<die>s on error or returns the L<File::FStore::File> object of
the freshly inserted file.

B<Note:>
This adder is in undefined state after this call.
The only save method to call after this is L</reset>.

=head2 contentise

    my $ise = $file->contentise;
    # or:
    my $ise = $file->contentise(as => ...);

Returns the content based ISE (identifier) for the file.
See L<File::FStore::File/contentise> for details.

This value is only available once L</done> is called.

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

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
