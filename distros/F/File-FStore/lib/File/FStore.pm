# Copyright (c) 2025-2026 Philipp Schafft
    
# licensed under Artistic License 2.0 (see LICENSE file)
    
# ABSTRACT: Module for interacting with file stores
        
     
package File::FStore;

use v5.10;
use strict;
use warnings;

use Carp;
use DBI;
use File::Spec;
use Data::Identifier;
use Data::Identifier::Generate;
use Scalar::Util qw(weaken);

use File::FStore::File;

use parent qw(Data::Identifier::Interface::Known Data::Identifier::Interface::Userdata Data::Identifier::Interface::Subobjects);

our $VERSION = v0.07;

use constant {
    DEFAULT_LINK_STYLE  => '1-level',
    DEFAULT_STORE_STYLE => '1-level-contentise',
};

my %_types = (
    db          => 'Data::TagDB',
    extractor   => 'Data::URIID',
    fii         => 'File::Information',
);

our %_valid_digests = map {$_ => int((/^[^-]+-[^-]-([0-9]+)$/)[0]/4)} (
    qw(md-5-128 sha-1-160),
    (map {'sha-2-'.$_, 'sha-3-'.$_} 224, 256, 384, 512),
);

our %_valid_link_styles = map {$_ => 1} qw(none 1-level 2-level);
our %_valid_store_styles = map {$_ => 1} qw(1-level-contentise 2-level-contentise);

my %_flat_settings = map {$_ => $_} qw(link_style store_style);

our %_ni_hashes = (
    'sha-2-256' => 'sha-256',
    'sha-2-384' => 'sha-384',
    'sha-2-512' => 'sha-512',
    'sha-3-224' => 'sha3-224',
    'sha-3-256' => 'sha3-256',
    'sha-3-384' => 'sha3-384',
    'sha-3-512' => 'sha3-512',
);
my %_ni_hashes_reverse = map {$_ni_hashes{$_} => $_} keys %_ni_hashes;


sub create {
    my ($pkg, %opts) = @_;
    my $path = delete($opts{path});
    my $digests = delete($opts{digests}) // [keys %_valid_digests];
    my %extra;
    my $dbh;

    foreach my $key (keys(%_types), qw(weak)) {
        my $v = delete $opts{$key};
        $extra{$key} = $v if defined $v;
    }

    croak 'Stray options passed' if scalar keys %opts;

    $digests = [split(/\s*,\s*|\s+/, $digests)] unless ref $digests;
    foreach my $digest (@{$digests}) {
        croak 'Invalid digest: '.$digest unless defined $_valid_digests{$digest};
    }

    mkdir($path) or croak $!;
    mkdir(File::Spec->catdir($path, qw(v2))) or croak $!;
    mkdir(File::Spec->catdir($path, qw(v2 store))) or croak $!;
    mkdir(File::Spec->catdir($path, qw(v2 by))) or croak $!;
    foreach my $digest (@{$digests}) {
        mkdir(File::Spec->catdir($path, qw(v2 by), $digest)) or croak $!;
    }

    $dbh = DBI->connect('dbi:SQLite:dbname='.File::Spec->catfile($path => v2 => store => 'db.sqlite'), undef, undef, { RaiseError => 1, PrintError => undef });
    #@inject SQLITE
    $dbh->do($_) for split /;/, << 'SQL';
CREATE TABLE file (
    id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
    filename VARCHAR(128) NOT NULL UNIQUE
);

CREATE TABLE file_properties (
    file INTEGER NOT NULL REFERENCES file (id),
    key VARCHAR(64) NOT NULL,
    value VARCHAR(128) NOT NULL,
    UNIQUE (file, key)
);

CREATE TABLE file_hash (
    file INTEGER NOT NULL REFERENCES file (id),
    algo VARCHAR(32) NOT NULL,
    hash VARCHAR(255) NOT NULL UNIQUE,
    UNIQUE (file, algo)
);
SQL
    $dbh->disconnect;

    return $pkg->new(path => $path, %extra);
}


#@returns __PACKAGE__
sub new {
    my ($pkg, %opts) = @_;
    my $path = delete $opts{path} // croak 'No path given';
    my $weak = delete $opts{weak};
    my @used_digests;
    my @used_digests_ni;
    my $self = bless {
        path => $path,
        used_digests => \@used_digests,
        used_digests_ni => \@used_digests_ni,
        transaction_count => 0,
        link_style => DEFAULT_LINK_STYLE,
        store_style => DEFAULT_STORE_STYLE,
    }, $pkg;

    foreach my $key (keys %_types) {
        my $v = delete $opts{$key};
        next unless defined $v;
        $self->so_attach($key => $v, weak => $weak);
    }

    if (defined(my $link_style = delete $opts{link_style})) {
        $link_style = DEFAULT_LINK_STYLE if $link_style eq 'default';
        croak 'Not a valid link style: '.$link_style unless defined $_valid_link_styles{$link_style};
        $self->{link_style} = $link_style;
    }

    if (defined(my $store_style = delete $opts{store_style})) {
        $store_style = DEFAULT_STORE_STYLE if $store_style eq 'default';
        croak 'Not a valid store style: '.$store_style unless defined $_valid_store_styles{$store_style};
        $self->{store_style} = $store_style;
    }

    croak 'Stray options passed' if scalar keys %opts;

    {
        opendir(my $dir, $self->_directory(v2 => 'by')) or croak $!;
        while (defined(my $ent = readdir($dir))) {
            next if $ent =~ /^\./;
            croak 'Invalid store, unsupported/invalid digest used: '.$ent unless $_valid_digests{$ent};
            push(@used_digests, $ent);
        }
        closedir($dir);
    }

    if (opendir(my $dir, $self->_directory(v2 => 'ni'))) {
        while (defined(my $ent = readdir($dir))) {
            next if $ent =~ /^\./;
            push(@used_digests_ni, $_ni_hashes_reverse{$ent} // next);
        }
        closedir($dir);
    }

    $self->{dbh} = DBI->connect('dbi:SQLite:dbname='.$self->_file(v2 => store => 'db.sqlite'), undef, undef, { RaiseError => 1, PrintError => undef });

    return $self;
}


sub close {
    my ($self) = @_;
    $self->DESTROY;
}


sub setting {
    my ($self, $key) = @_;

    croak 'No key given' unless defined $key;

    if (defined(my $flatkey = $_flat_settings{$key})) {
        return $self->{$flatkey};
    }

    croak 'Unknown key: '.$key;
}


sub in_transaction {
    my ($self, $type, $code) = @_;
    my $error;

    croak 'Bad transaction type' unless $type eq 'ro' || $type eq 'rw';

    return undef if defined $self->{transaction_error};

    if ($self->{transaction_count}) {
        if ($type ne 'ro' && $type ne $self->{transaction_type}) {
            croak 'Invalid inner transaction type '.$type.' within outer '.$self->{transaction_type}.' transaction';
        }
    } else {
        $self->{dbh}->begin_work;
        $self->{transaction_type}  = $type;
        $self->{transaction_error} = undef;
    }

    $self->{transaction_count}++;

    eval {
        $code->();
    };
    $error = $@ if $@;

    $self->{transaction_error} //= $error;

    $self->{transaction_count}--;

    unless ($self->{transaction_count}) {
        if (defined $self->{transaction_error}) {
            $self->{dbh}->rollback;
        } else {
            $self->{dbh}->commit;
        }
    }

    croak $error if defined $error;
}


sub query {
    my ($self, @query) = @_;
    my %fields = (properties => {}, digests => {});
    my $limit;
    my $offset;
    my $order;
    my @q;
    my @p;

    while (defined(my $cmd = shift(@query))) {
        $cmd = 'digests' if $cmd eq 'hashes';

        if ($cmd eq 'properties' || $cmd eq 'digests') {
            my $n = shift(@query) // croak 'Incomplete query';
            my $t = $fields{$cmd};

            if (ref($n)) {
                %{$t} = (%{$t}, %{$n});
            } else {
                my $v = shift(@query) // croak 'Incomplete query';
                $t->{$n} = $v;
            }
        } elsif ($cmd eq 'all') {
            push(@q, 'SELECT id FROM file');
        } elsif ($cmd eq 'limit') {
            $limit = shift(@query) // croak 'Incomplete query';
        } elsif ($cmd eq 'offset') {
            $offset = shift(@query) // croak 'Incomplete query';
        } elsif ($cmd eq 'order') {
            $order = shift(@query) // croak 'Incomplete query';
            $order = uc($order);
            croak 'Bad order' if $order ne 'ASC' && $order ne 'DESC';
        } elsif ($cmd eq 'min_size') {
            my $v = shift(@query) // croak 'Incomplete query';
            push(@q, 'SELECT file AS id FROM file_properties WHERE key = \'size\' AND CAST(value AS BIG INTEGER) >= ?');
            push(@p, $v);
        } elsif ($cmd eq 'max_size') {
            my $v = shift(@query) // croak 'Incomplete query';
            push(@q, 'SELECT file AS id FROM file_properties WHERE key = \'size\' AND CAST(value AS BIG INTEGER) <= ?');
            push(@p, $v);
        } elsif ($cmd eq 'dbname') {
            my $v = shift(@query) // croak 'Incomplete query';

            $v = [$v] unless ref $v;

            croak 'Empty list for dbname' unless scalar(@{$v});

            push(@q, 'SELECT id FROM file WHERE '.$self->_placeholders(filename => $v));
            push(@p, @{$v});
        } elsif ($cmd eq 'ise') {
            my $v = shift(@query) // croak 'Incomplete query';

            if (ref $v) {
                if (eval {$v->isa('Data::Identifier::Cloudlet')}) {
                    $v = [$v->entries];
                } elsif (eval {$v->can('ise')}) {
                    $v = [$v];
                }
            } else {
                $v = [$v];
            }

            croak 'Empty list for ise' unless scalar(@{$v});

            foreach my $s (@{$v}) {
                $s = $s->ise if ref $s;
            }

            push(@q, 'SELECT file AS id FROM file_properties WHERE key IN (\'contentise\', \'inodeise\') AND '.$self->_placeholders(value => $v));
            push(@p, @{$v});
        } else {
            croak 'Invalid query command: '.$cmd;
        }
    }

    foreach my $digest (keys %{$fields{digests}}) {
        my $v = $fields{digests}{$digest};
        $v = [$v] unless ref($v) eq 'ARRAY';
        unshift(@q, 'SELECT file AS id FROM file_hash WHERE algo = ? AND '.$self->_placeholders(hash => $v));
        unshift(@p, $digest, @{$v});
    }

    foreach my $property (keys %{$fields{properties}}) {
        my $v = $fields{properties}{$property};
        $v = [$v] unless ref($v) eq 'ARRAY';
        push(@q, 'SELECT file AS id FROM file_properties WHERE key = ? AND '.$self->_placeholders(value => $v));
        push(@p, $property, @{$v});
    }

    unless (scalar @q) {
        croak 'No filter given';
    }

    {
        my $q = join(' INTERSECT ', @q);
        my $sth;
        my @result;

        if (defined $order) {
            $q .= ' ORDER BY id '.$order;
        }

        $limit = 2 unless wantarray;

        if (defined $limit) {
            $q .= ' LIMIT ?';
            push(@p, $limit);
        }

        if (defined $offset) {
            $q .= ' OFFSET ?';
            push(@p, $offset);
        }
        $sth = $self->{dbh}->prepare($q);
        $sth->execute(@p);

        while (my $row = $sth->fetchrow_arrayref) {
            push(@result, File::FStore::File->_new(store => $self, dbid => $row->[0]));
        }

        $sth->finish;

        if (wantarray) {
            return @result;
        } else {
            croak 'Multiple results for query but called in scalar context' if scalar(@result) > 1;
            croak 'No results for query but called in scalar context' if scalar(@result) < 1;
            return $result[0];
        }
    }

    die 'BUG';
}


sub scrub {
    my ($self, %opts) = @_;

    croak 'Stray options passed' if scalar keys %opts;

    $self->in_transaction(ro => sub {
            opendir(my $algodir, $self->_directory('v2' => 'by')) or croak $!;
            while (defined(my $algoent = readdir($algodir))) {
                next if $algoent =~ /^\./;
                $self->_scrub_dir($algoent => $self->_directory(v2 => by => $algoent));
            }
            closedir($algodir);
        });

    {
        if (opendir(my $algodir, $self->_directory('v2' => 'ni'))) {
            $self->in_transaction(ro => sub {
                    while (defined(my $algoent = readdir($algodir))) {
                        my $dirname;

                        next if $algoent =~ /^\./;

                        $dirname = $self->_directory(v2 => ni => $algoent);

                        opendir(my $dir, $dirname) or next;
                        while (defined(my $fn = readdir($dir))) {
                            my $fullname = File::Spec->catfile($dirname, $fn);
                            next if $fn =~ /^\./;
                            unlink($fullname) unless -e $fullname;
                        }
                        closedir($dir);
                    }
                });
            closedir($algodir);
        }
    }
}


sub scan {
    my ($self, %opts) = @_;
    my %extra;

    foreach my $key (qw(update no_digests on_pre_set on_post_set)) {
        $extra{$key} = delete $opts{$key};
    }

    $extra{update} //= 'all';

    croak 'Stray options passed' if scalar keys %opts;

    $self->in_transaction(rw => sub {
            my $insert = $self->{dbh}->prepare('INSERT OR IGNORE INTO file (filename) VALUES (?)');

            opendir(my $dir, $self->_directory('v2', 'store')) or croak $!;
            while (defined(my $ent = readdir($dir))) {
                my $dirname;

                next if $ent =~ /^\./;

                $dirname = $self->_directory('v2', 'store', $ent);

                if (-d $dirname) {
                    $self->_scan_subdir($dirname, dbprefix => $ent, insert => $insert, %extra);
                }
            }
            closedir($dir);
        });
}


sub fix {
    my ($self, @fixes) = @_;
    my %fixes = map {$_ => 1} @fixes;

    foreach my $fix (qw(upgrade scrub remove-inode remove-mediasubtype remove-inodeise scan)) {
        next unless delete $fixes{$fix};

        if ($fix eq 'scrub') {
            $self->scrub;
        } elsif ($fix eq 'scan') {
            $self->scan;
        } elsif ($fix eq 'upgrade') {
            $self->migration->upgrade;
        } elsif ($fix =~ /^remove-(inode|mediasubtype|inodeise)$/) {
            my $what = $1;
            my $sth = $self->{dbh}->prepare('DELETE FROM file_properties WHERE key = ?');
            $sth->execute($what);;
        } else {
            croak 'BUG';
        }
    }

    if (scalar keys %fixes) {
        croak 'Invalid/unknown fixes passed: '.join(', ', keys %fixes);
    }
}


#@returns File::FStore::Adder
sub new_adder {
    my ($self) = @_;
    require File::FStore::Adder;
    return File::FStore::Adder->_new(store => $self);
}


#@returns File::FStore::Migration
sub migration {
    my ($self) = @_;
    require File::FStore::Migration;
    return File::FStore::Migration->_new(store => $self);
}


#@deprecated
sub export {
    my ($self, @args) = @_;
    return $self->migration->export_data(@args);
}


#@deprecated
sub import_data {
    my ($self, @args) = @_;
    return $self->migration->import_data(@args);
}


sub add_digest {
    my ($self, $digests, @opts) = @_;
    my $path = $self->{path};
    my %used_digests = map {$_ => undef} @{$self->{used_digests}};

    croak 'Stray options passed' if scalar @opts;

    $digests = [split(/\s*,\s*|\s+/, $digests)] unless ref $digests;

    foreach my $d (@{$digests}) {
        next if exists $used_digests{$d};

        croak 'Invalid digest: '.$d unless defined $_valid_digests{$d};
        mkdir(File::Spec->catdir($path, qw(v2 by), $d)) or croak $!;

        $used_digests{$d} = undef;
    }

    @{$self->{used_digests}} = keys %used_digests;
}


#@deprecated
sub attach {
    my ($self, %opts) = @_;
    $self->so_attach(%opts);
}


#@deprecated
sub db {
    my ($self, %opts) = @_;
    return $self->so_get('db', %opts);
}


#@deprecated
sub extractor {
    my ($self, %opts) = @_;
    return $self->so_get('extractor', %opts);
}


#@returns File::Information
sub fii {
    my ($self) = @_;
    my $fii = $self->so_get('fii', default => undef, no_defaults => 1);
    return $fii if defined $fii;

    require File::Information;
    File::Information->VERSION(v0.06);
    $fii = File::Information->new(
        db        => $self->so_get('db', default => undef, no_defaults => 1),
        extractor => $self->so_get('extractor', default => undef, no_defaults => 1),
    );

    $self->so_attach(fii => $fii);
    return $fii;
}

# --- Overrides for Data::Identifier::Interface::Known ---
sub _known_provider {
    my ($pkg, @args) = @_;
    return $pkg->File::FStore::File::_known_provider(@args);
}



# ---- Private helpers ----

sub _placeholders {
    my ($self, $field, $list) = @_;
    my $placeholders = '?,' x scalar(@{$list});

    $placeholders =~ s/,$//;

    return sprintf('%s IN (%s)', $field, $placeholders);
}

sub DESTROY {
    my ($self) = @_;
    $self->{dbh}->disconnect if defined $self->{dbh};
    %{$self} = ();
}

sub _file {
    my ($self, @comp) = @_;
    return File::Spec->catfile($self->{path}, @comp);
}

sub _directory {
    my ($self, @comp) = @_;
    return File::Spec->catdir($self->{path}, @comp);
}

sub _used_digests {
    my ($self) = @_;
    return $self->{used_digests};
}

sub _used_digests_ni {
    my ($self) = @_;
    return $self->{used_digests_ni};
}

sub _init_link_style {
    my ($self) = @_;

    unless ($self->{_init_link_style}) {
        my $link_style = $self->setting('link_style');

        $self->{_init_link_style} = 1;

        if ($link_style eq '2-level') {
            foreach my $digest (@{$self->_used_digests}) {
                for (my $i = 0; $i < 0x100; $i++) {
                    mkdir($self->_directory(v2 => by => $digest => sprintf('%02x', $i)));
                }
            }
        }
    }
}

sub _init_store_style {
    my ($self) = @_;

    unless ($self->{_init_store_style}) {
        my $store_style = $self->setting('store_style');

        $self->{_init_store_style} = 1;

        if ($store_style eq '2-level-contentise' || $store_style eq '1-level-contentise') {
            mkdir($self->_directory(v2 => store => 'by-contentise'));
        }

        if ($store_style eq '2-level-contentise') {
            for (my $i = 0; $i < 0x100; $i++) {
                mkdir($self->_directory(v2 => store => 'by-contentise' => sprintf('%02x', $i)));
            }
        }
    }
}

sub _scan_subdir {
    my ($self, $dirname, %opts) = @_;
    my $dbprefix = $opts{dbprefix};

    opendir(my $dir, $dirname) // croak $!;
    while (defined(my $ent = readdir($dir))) {
        my $filename;
        my $fh;

        next if $ent =~ /^\./;

        $filename = File::Spec->catfile($dirname, $ent);
        open($fh, '<', $filename);
        if ($fh && -f $fh) {
            my $dbname = File::Spec->catfile($dbprefix, $ent);
            $self->_scan_file($fh, $dbname, %opts);
            #warn sprintf('ent=<%s>, filename=<%s>, dbprefix=<%s>, dbname=<%s>', $ent, $filename, $dbprefix, $dbname);
        } else {
            $self->_scan_subdir(File::Spec->catdir($dirname, $ent), %opts, dbprefix => File::Spec->catdir($dbprefix, $ent));
        }
    }
    closedir($dir);
}

sub _scan_file {
    my ($self, $fh, $dbname, %opts) = @_;
    my File::FStore::File $file;
    my $update = $opts{update};
    my $new;

    $opts{insert}->execute($dbname);
    $new = $opts{insert}->rows;

    $file = $self->query(dbname => $dbname);
    $file->_open(fh => $fh);

    if ($update eq 'all' || ($new && $update eq 'new')) {
        $file->update(%opts{qw(no_digests on_pre_set on_post_set)});
    } else {
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
            $atime,$mtime,$ctime,$blksize,$blocks) = $file->stat;

        $opts{on_pre_set}->($file) if defined $opts{on_pre_set};
        $file->set({
                properties => {
                    size => $size,
                    inode => $ino,
                },
            });
        $opts{on_post_set}->($file) if defined $opts{on_post_set};
    }
}

sub _scrub_dir {
    my ($self, $algoent, $dirname) = @_;

    opendir(my $dir, $dirname) or croak $!;
    while (defined(my $ent = readdir($dir))) {
        my $fullname;
        my $hash;
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
            $atime,$mtime,$ctime,$blksize,$blocks);
        my $bad = 1;

        next if $ent =~ /^\./;

        $fullname = File::Spec->catdir($dirname, $ent);
        if (-d $fullname) {
            $self->_scrub_dir($algoent => $fullname);
            next;
        }

        $fullname = File::Spec->catfile($dirname, $ent);
        ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
            $atime,$mtime,$ctime,$blksize,$blocks) = stat($fullname);

        if (defined $size) {
            my ($hash) = $ent =~ /^([0-9a-fA-F]+)(?:\..+)?$/;
            if (defined $hash) {
                my $file;

                $hash = lc($hash);
                $file = eval {$self->query(digests => $algoent => $hash)};

                if (defined $file) {
                    my $want_size = eval { $file->get(properties => 'size') } // $size;
                    if ($size == $want_size) {
                        $bad = 0;
                    }
                }
            }
        }

        #warn $algoent.' -> '.$ent.' -> '.$bad;
        if ($bad) {
            unlink($fullname) or croak $!;
        }
    }
    closedir($dir);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::FStore - Module for interacting with file stores

=head1 VERSION

version v0.07

=head1 SYNOPSIS

    use File::FStore;

    my File::FStore $store = File::FStore->new(path => '...');

    my @files = $store->query(properties => mediasubtype => 'image/png', order => 'asc', offset => 10, limit => 5);

    my $fh = $store->query(digests => 'sha-3-224' => '6b4e03423667dbb73b6e15454f0eb1abd4597f9a1b078e3f5b5a6bc7')->open;

This package provides access to a hash based/final state file store in Fellig format.
Files in such a store are considered final, meaning their content will no longer be altered.

In addition to digests (hashes) some file level metadata is kept in the store (see L<File::FStore::File/PROPERTIES>).
This metadata is mainly used to ensure the integrity of the store.
Other metadata is intentionally not supported.
For storage of other metadata see L<Data::TagDB> and L</db>.
For reading metadata and file analysis see L<File::Information> and L</fii>.

This package inherits from L<Data::Identifier::Interface::Known>, and L<Data::Identifier::Interface::Userdata>.

=head1 METHODS

=head2 create

    my File::FStore $store = File::FStore->create(path => ..., ...);

Creates a new file store.
C<die>s if the store cannot be created or already exists or invalid options are passed.
Takes the same options as L</new> plus the following:

=over

=item C<digests>

List of digests to be used in the store. Each digest is given in the universal tag format (or utag)
(e.g. C<sha-3-224>.
The list can be passed as a arrayref or as a comma separated list.

The list can contain digests that are not supported by the system this runs on.
They may for example still be used with import/export functions.

The list can be adjusted at a later time.

=back

=head2 new

    my File::FStore $store = File::FStore->new(path => ..., ...);

Creates a new instance of the store and opens it.

The following options are supported:

=over

=item C<db>

A L<Data::TagDB> object. See L</db>.

=item C<extractor>

A L<Data::URIID> object. See L</extractor>.

=item C<fii>

A L<File::Information> object. See L</fii>.

=item C<link_style>

(since v0.05)

The style to use for links. One of: C<none>, C<1-level>, or C<2-level>.

B<Note:>
This does not affect already existing links unless one of the relevant calls is made.

=item C<path>

The path to the store.

=item C<store_style>

(since v0.05)

The style to use for storing files. One of: C<1-level-contentise>, or C<2-level-contentise>.

B<Note:>
This does not affect already existing files.

=item C<weak>

Marks the value for C<db>, C<extractor>, C<fii> as weak.
If only a specific one needs needs to be weaken use L</attach>.

=back

=head2 close

    $store->close;

Closes the store. Any interaction with this object or any related objects after this call is invalid.

=head2 setting

    my $value = $store->setting($key);

(since v0.05)

Gets a setting of the store.

The type of the returned value depends on the key.

=head2 in_transaction

    $db->in_transaction(ro => sub { ....});
    # or:
    $db->in_transaction(rw => sub { ....});

Runs a block of code (a subref) inside a transaction.

The passed block is run in a transaction. The transaction is commited after the code finishes.

The type of the transaction can be C<ro> (read only) or C<rw> (read-write).
The module may optimise based on this information.
If a write operation is performed in a transaction that is marked C<ro> the behaviour is unspecified.

Calls to this method can be stacked freely.
For example the following is valid:

    $store->in_transaction(ro => sub {
        # do some read...
        $store->in_transaction(rw => sub {
            # do some write...
        });
        # do more reading, writing is invalid here
    });

B<Note:>
If the code C<die>s the transaction is aborted and the error is raised again.
Note that this affects all currently open transactions (as per stacking).
If the (parent) transaction is already aborted when this method is called the code block might not be run at all.

B<Note:>
Data written might only be visible to other handles of the same database once I<all>
transactions have been finished.

B<Note:>
It is undefined what the state of C<@_> is within the callback.

=head2 query

    my File::FStore::File $file = $store->query(...);
    # or:
    my @files = $store->query(...);

    # e.g.:
    my File::FStore::File $file = $store->query(digests => 'sha-3-512' => $digest);
    # or:
    my File::FStore::File $file = $store->query(digests => {'sha-3-512' => $digest});
    # or:
    foreach my File::FStore::File $file ($store->query(properties => size => 64)) {
        # ...
    }

Returns files matching the given query.
If called in scalar context the method will return the file if the query matches one file.
If it matches zero or more than one it will C<die>.

The query contains of commands followed by arguments.
It is optimised internally for performance, so order of arguments does not matter.

Currently the following commands are defined:

=over

=item C<properties>

This takes a key and value or a single hashref with properties to match exactly.
The value can also be an arrayref of values (which are or-ed).

=item C<digests>

This works the same as C<properties> but matches the digests.

=item C<all>

Selects all files. Takes no arguments.
This should be used with care as a very long list might be returned.

=item C<dbname>

Selects files by their I<dbname> (see L<File::FStore::File/dbname>).
Takes a single filename or a list of filenames (as an arrayref).

=item C<ise>

Selects files by their I<ise> (such as their L<File::FStore::File/contentise>, or L<File::FStore::File/inodeise>).
Takes a single ISE,
L<Data::Identifier>,
L<Data::TagDB::Tag>,
L<Data::URIID::Base>,
or a list of them (as an arrayref) or a L<Data::Identifier::Cloudlet>.

If a L<Data::Identifier::Cloudlet> all entries are used (see L<Data::Identifier::Cloudlet/entries>), not just root entries.

=item C<min_size>

Selects files by their minimum size. This uses the C<size> value of the C<properties> domain.

=item C<max_size>

Selects files by their maximum size. This uses the C<size> value of the C<properties> domain.

=item C<limit>

Limits the number of returned files.
It is undefined what happens if this is used in scalar context.

=item C<offset>

The offset into the list. Often used with C<limit> to implement pagination.
B<Note:>
It is important to also give C<order> when using this, as otherwise the order is not stable.

=item C<order>

The order in which to return the files. One of C<asc> or C<desc>.

=back

=head2 scrub

    $store->scrub;

Cleans up the store, including removing dangling links.

This is normally only needed if files where removed or files got corrupted, or store settings have been altered.
However it is a good idea to call this method once in a while to maintain the store over a long time.

It is typical application to call L</scan> after this call to check and regenerate active symlinks.

B<Note:>
This method may take some time to run. Generally speaking the call takes more time the larger the store is.

=head2 scan

    $store->scan;
    # or:
    $store->scan(%opts);

Scans the store for existing and new files.
As this method checks all files in the store and may do calculations this method might run several seconds.

The following options are supported:

=over

=item C<update>

One of C<all> (default), C<new>, or C<none>.
This determines whether L<File::FStore::File/update> is called on all files, only new ones, or none.

=item C<no_digests>

Passed to L<File::FStore::File/update>.

=item C<on_pre_set>

See L<File::FStore::File/update>. Also called on each file if no update is performed.

=item C<on_post_set>

See L<File::FStore::File/update>. Also called on each file if no update is performed.

=back

=head2 fix

    $store->fix(qw(fixes...));

Runs maintenance/fixes to the store.

Takes the names of the fixes to run as arguments.
The order does not matter, as the method reorders them internally.

On any error this method C<die>s.

Currently the following fixes are supported:

=over

=item C<remove-inode>

Removes the inode properties from the store.
This is useful when transfering the store to another filesystem,
or if the store is managed externally (e.g. via an vcs).

=item C<remove-inodeise>

Removes the inodeise properties from the store.
This is useful when transfering the store to another filesystem,
or if the store is managed externally (e.g. via an vcs).
In contrast to C<remove-inode> this might not be needed, depending on
which schema for inodeise was used.

=item C<remove-mediasubtype>

Removes the mediasubtype properties from the store.
This is useful when you imported invalid mediasubtypes from a bad source.
Adding C<scan> to the list of fixes will add correct values back.

=item C<scan>

Runs L</scan> with default options.

=item C<scrub>

Runs L</scrub>.

=item C<upgrade>

Runs L<File::FStore::Migration/upgrade>.

=back

=head2 new_adder

    my File::FStore::Adder $adder = $store->new_adder;

Create a new L<File::FStore::Adder>.

=head2 migration

    my File::FStore::Migration $migration = $self->migration;

Returns a new L<File::FStore::Migration> object for this store.

=head2 export

    $migration->export_data(...);

(since v0.01, deprecated since v0.05, will be removed in v0.10, may warn).

Deprecated proxy for L<File::FStore::Migration/export_data>.

This proxy will be removed in version v0.10. Future versions of this proxy may C<warn> about it's usage.

=head2 import_data

    $store->import_data(...);

(since v0.01, deprecated since v0.05, will be removed in v0.10, may warn).

Deprecated proxy for L<File::FStore::Migration/import_data>.

This proxy will be removed in version v0.10. Future versions of this proxy may C<warn> about it's usage.

=head2 add_digest

    $store->add_digest($digest);

(experimental since v0.07)

Adds a digest to the store.

Multiple digests can be given by setting C<$digest> to an arrayref or by providing a comma separated list.

If a digest is already used by the store no change is made.

In order to populate the new digest L</scan> should be called (after all new digests have been added).

B<Note:>
Newly added digests may or may not be visible to instances of L<File::FStore::File> or L<File::FStore::Adder> or any other instance of L<File::FStore>
that were created before this function was called.

=head2 attach

    $self->attach(key => $obj, ...);
    # or:
    $self->attach(key => $obj, ..., weak => 1);

(since v0.04, deprecated since v0.07, will be removed in v0.10, may warn).

This is deprecated. See L<Data::Identifier::Interface::Subobjects/so_attach> for a replacement.

Attaches objects of the given type.
Takes the same list of objects as L</new>.

If an object is allready attached for the given key this method C<die>s unless the object is actually the same.

If C<weak> is set to a true value the object reference becomes weak.

=head2 db

    my Data::TagDB $db = $store->db;
    # or:
    my Data::TagDB $db = $store->db(default => $def);

(since v0.01, deprecated since v0.07, will be removed in v0.10, may warn).

This is deprecated. See L<Data::Identifier::Interface::Subobjects/so_get> for a replacement.

Returns the instance of L<Data::TagDB> if any was given via L</new>.

If no value is known returns the value of the option C<default> (if passed) or C<die>s.

=head2 extractor

    my Data::URIID $extractor = $store->extractor;
    # or:
    my Data::URIID $extractor = $store->extractor(default => $def);

(since v0.01, deprecated since v0.07, will be removed in v0.10, may warn).

This is deprecated. See L<Data::Identifier::Interface::Subobjects/so_get> for a replacement.

Returns the instance of L<Data::URIID> if any was given via L</new>.

If no value is known returns the value of the option C<default> (if passed) or C<die>s.

=head2 fii

    my File::Information $fii = $store->fii;

(since v0.01, experimental since v0.07)

Returns the instance of L<File::Information> passed via L</new> or a internally created one if none were given.

B<Note:>
If the option C<default> is passed, it is ignored with no error.

B<Note:>
The semantics of this method are slightly differen than that of L<Data::Identifier::Interface::Subobjects/so_get>.
This method therefore became experimental with version v0.07.
Future versions starting with version v0.10 may change or remove this method.

=head2 known

    my @list = File::FStore->known($class [, %opts ] );
    # or:
    my @list = $store->known($class [, %opts ] );

(since v0.05)

Proxy for L<File::FStore::File/known>.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
